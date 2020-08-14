#include "Vtb_openMSP430.h"

#include <verilated.h>
#include <verilated_vcd_c.h>
// #include <verilated_fst_c.h>

#include <memory>
#include <vector>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <sys/stat.h>

#include <cstdint>
#include <cassert>

#include <sys/select.h>
#include <sys/time.h>

#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "loguru/loguru.hpp"
#include "cpp-optparse/OptionParser.h"

#define COLOR_CRYPT "\033[1m\033[36m"      /* Bold Cyan */
#define COLOR_RESET "\033[0m"

using namespace std;
using optparse::OptionParser;

const double TIMESCALE       = 1e-9;
const int    CLOCK_FREQUENCY = 20*1e6;
const int    CLOCK_PERIOD    = 1/(CLOCK_FREQUENCY*TIMESCALE);
uint64_t MAX_CYCLES = 1000000000ULL;
vluint64_t mainTime;

enum exit_codes{status_success, status_error, status_timeout, status_program_abort, status_no_input_file, status_sm_violation};

inline bool check_file_exists (const char* filename) {
    struct stat buffer;   
    return (stat (filename, &buffer) == 0); 
}

 class Memory
 {
 public:

    Memory(Vtb_openMSP430& top, const char* memoryFile, string name,
        CData *chip_enable, CData *write_enable, SData *addr, SData *din, SData *dout) 
            : top_{top}, _name{name}, _chip_enable{chip_enable}, _write_enable{write_enable}, _addr{addr}, _din{din}, _dout{dout}
    {
        // We allow null strings as input and then use an empty memory (For RAM)
        if(strcmp(memoryFile, "")){
            auto ifs = std::ifstream{memoryFile, std::ifstream::binary};
            auto memoryBytes =
                std::vector<unsigned char>{std::istreambuf_iterator<char>(ifs), {}};

            CHECK_F((memoryBytes.size() % 2 == 0), "Memory does not contain a multiple of words");

            auto i = std::size_t{0};
            while (i < memoryBytes.size())
            {
                auto b0 = memoryBytes[i++];
                auto b1 = memoryBytes[i++];

                Word word = b0 | (b1 << 8) ; // little endian
                memory_.push_back(word);
            }
            LOG_F(INFO,"Read program memory of %lu bytes.", memoryBytes.size());
        }
    }

    bool eval(bool clockedge)
    {
        bool updated = false;
        if (! *_chip_enable            // chip enable is low active
            && *_write_enable != 0b11  // write enable is low active
            && clockedge)              // only write on rising clockedges
        {
            write(*_addr, *_write_enable, *_din);
        }
        
        if(clockedge) *_dout = read(prev_address, clockedge);
        prev_address = *_addr;

        // For very low-level debugging, the following line might help. But otherwise, 
        // logging at other times than the rising edge is probably not useful.
        // LOG_F(MAX,"[Memory] %s Regs are: cen: %x wen: %x, addr: %2x, in: %2x, out:%2x",_name.c_str(), *_chip_enable, *_write_enable, *_addr, *_din, *_dout);

        return true;
    }

    string print_memory(){
        ostringstream stringStream;
        
        auto i =0;
        vector<Word>::iterator it;
        for(it = memory_.begin(); it != memory_.end(); it++,i++ ) {
            if (i%16 == 0){
                stringStream << endl << "0x" << setfill('0') << setw(4) << right << hex << i*2 << ": ";
            } 
            stringStream << setfill('0') << setw(4) << right << hex<< memory_[i] << " ";
        }
        return stringStream.str();
    }

 private:

    using Address = uint16_t;
    using Word = uint16_t;
    using Mask = uint8_t;

    Word read(Address address, bool clockedge)
    {
        ensureEnoughMemory(address);
        Word memoryValue = memory_[(prev_address)];
        LOG_F(MAX,"[Memory] %s [Read] %x : %x", _name.c_str(), prev_address, memoryValue);

        return memoryValue;
    }

    void write(Address address, Mask mask, Word value)
    {
        ensureEnoughMemory(address);

        auto bitMask = Word{0};
        switch(mask){
        case 0b00: bitMask = 0xffff; break;
        case 0b01: bitMask = 0xff00; break;
        case 0b10: bitMask = 0x00ff; break;
        }

        auto& memoryValue = memory_[(address)];
        memoryValue &= ~bitMask;
        memoryValue |= value & bitMask;

        LOG_F(MAX,"[Memory] %s [Write] %x : %x", _name.c_str(), address, memoryValue);
    }

    void ensureEnoughMemory(Address address)
    {
        if ((address) >= memory_.size())
        {
            memory_.reserve((address) + 1);

            while ((address) >= memory_.size())
                memory_.push_back(null_word);
        }
    }

    Vtb_openMSP430& top_;
    Address prev_address;
    std::vector<Word> memory_;
    Word null_word = Word{0};
    string _name;
    CData *_chip_enable;
    CData *_write_enable;
    SData *_addr;
    SData *_din;
    SData *_dout;
};

bool tracer_enabled = false;
bool crypto_noshow  = false;
uint32_t  crypto_cycles = 0;
auto tracer = std::unique_ptr<VerilatedVcdC>{new VerilatedVcdC};
// auto tracer = std::unique_ptr<VerilatedFstC>{new VerilatedFstC};
// VerilatedFstC* tfp = new VerilatedFstC;

FILE *fd_in = NULL, *fd_out = NULL;
int in_char = EOF;

void eval_fileio(unique_ptr<Vtb_openMSP430> &top)
{
    if (mainTime < 50*CLOCK_PERIOD) return;

    /* Handle file I/O writes */
    if (top->fio_dout_rdy)
    {
        if (!fd_out)
        {
            LOG_F(WARNING, "File I/O write detected but no output file provided; ignoring write..");
        }
        else
        {
            LOG_F(1,"[fileio] Write %#x", top->fio_dout);
            if (fputc(top->fio_dout, fd_out) == EOF)
            {
                LOG_F(ERROR, "File I/O: write error");
                exit(status_error);
            }
            fflush(fd_out);
        }
    }

    /* Handle file I/O reads */
    if (fd_in && !top->fio_dready)
    {
        in_char = fgetc(fd_in);
        if (in_char != EOF)
        {
            LOG_F(1,"[fileio] Read %#x", in_char);
            top->fio_din = in_char;
            top->fio_dready = 1;
        }
    }

    if (top->fio_dnxt)
    {
        top->fio_dready = 0;
    }
}

int exit_program(int result){
    printf("\n\n\n");
    LOG_F(INFO, "======================== Simulation ended ========================");
    LOG_F(INFO, "Total/crypto cycles simulated: %lu/%u.", mainTime / CLOCK_PERIOD, crypto_cycles);
    switch(result){
        case status_success:
            LOG_F(INFO,     "================ Simulation succeeded gracefully =================");
            break;
        case status_timeout:
            LOG_F(INFO,     "===== Simulation stopped after timeout of %lu cycles =====", MAX_CYCLES);
            break;
        case status_program_abort:
            LOG_F(INFO,     "============= Simulation stopped after program abort =============");
            break;
        case status_sm_violation:
            LOG_F(INFO,     "============= Simulation stopped after SM Violation occured =============");
            break;
        default:
            LOG_F(INFO,     "============== Simulation failed with unknown error ==============");
            break;
    }

    if(tracer_enabled){
        tracer->close();
    }
    return result;
}

void exit_handler(int s){
    exit_program(status_program_abort);
    exit(status_program_abort); 
}

int main(int argc, char** argv)
{
    // assert(argc >= 2 && "No memory file name given");

    // Set up option parser based on some GitHub library
    OptionParser parser = OptionParser() 
        .description("Sancus Simulator based on Verilator. Expects a .elf file as input.")
        .usage("usage: %prog [OPTIONS] ELF-FILE");

    parser.add_option("-t", "--type") .dest("type") .set_default("elf")
                    .help("File type (default=elf). Override to pass a binary file.") .metavar("TYPE");
    parser.add_option("-d", "--dumpfile") .dest("vcd_filename") .set_default("")
                    .help("Name of the optional outputted simulation vcd file.") .metavar("OUTFILE");
    parser.add_option("-l", "--log") .dest("logfile") .set_default("")
                    .help("Prints all log messages to a debug log file.") .metavar("LOGFILE");
    parser.add_option("--fileio-in") .dest("fio_in") .set_default("")
                    .help("Optional I/O file for simulator input.") .metavar("FILEIO_IN");
    parser.add_option("--fileio-out") .dest("fio_out") .set_default("")
                    .help("Optional I/O file for simulator output.") .metavar("FILEIO_OUT");
    parser.add_option("-c", "--cycles") .dest("cycles") .type("int") .set_default(MAX_CYCLES)
                    .help("Maximum of cycles to execute before aborting. Set to 0 for no timeout.") .metavar("INT");
    parser.add_option("--stop-after-sm-violation") .dest("sm_violation_stopcount") .type("long") .set_default(0)
                    .help("If set to larger than 0, stops the simulation X cycles after a SM Violation occured. Default: 0 (stop directly on violation). Set to -1 to continue after violation.") .metavar("X");
    parser.add_option("--crypto-noshow") .action("store_true") .dest("crypto_noshow") 
                    .help("Disable spinning cursor terminal animation for indicating activity of the CPU's crypto unit (default=on). Passing this flag is recommended when running sancus-sim from a non-interactive terminal.") ;
    // parser.add_option("-v", "--verbose")
    //                 .action("store_true") .dest("verbose") .set_default("0")
    //                 .help("Print debug messages to stdout");

    optparse::Values options = parser.parse_args(argc, argv);
    vector<string> args = parser.args();

    // check input filename given
    const char* in_file;
    if (args.size() == 0 || args[0] == "" || ! check_file_exists(args[0].c_str())){
        parser.print_help();
        exit(status_no_input_file);
    } else {
        in_file = args[0].c_str();
        LOG_F(INFO, "Using input file %s.", in_file);
    }

    // time-stamp the start of the log.
    // also detects verbosity level on command line as -v.
    loguru::g_preamble_thread = false;
    loguru::g_preamble_date   = false;
    loguru::g_preamble_uptime = false;
    loguru::g_preamble_time   = false;
    loguru::g_preamble_file   = false;
    loguru::init(argc, argv);

    // Put every log message in "everything.log":
    const char* log_filename = options["logfile"].c_str();
    if(strlen(log_filename) > 0){
        LOG_F(INFO, "Logging all messages into file %s", log_filename);
        loguru::add_file(log_filename, loguru::Append, loguru::Verbosity_MAX);
    }

    LOG_F(INFO, "======================= Sancus Simulator =======================");

    // Depeding on type option, convert input file from elf to binary in tmp directory
    string mem_file;    
    if(options["type"] == "elf"){
        LOG_SCOPE_F(INFO, "Performing objcopy of elf file");
        LOG_F(INFO, "Generating temporary binary form of given elf file...");
        // Generate temp file
        char tmp_file[] = "/tmp/tmp_sancus_XXXXXX";
        int tmp_filedes = mkstemp(tmp_file);
        CHECK_F(tmp_filedes > -1, "Failed to create temporary file with error code %i.", tmp_filedes);
        
        // Store it in mem_file
        mem_file = string(tmp_file);
        LOG_F(INFO, "Temp file is %s", mem_file.c_str());
        
        // Run objcopy
        string command = "msp430-objcopy -O binary " + string(in_file) + " " + mem_file;
        FILE *fp = popen(command.c_str(), "r");
        if (fp == NULL){
            LOG_F(ERROR, "Failed to generate binary version of elf file!");
        }
        else{
            LOG_F(INFO, string(">> " + command).c_str());
            LOG_F(INFO, "..done!");
        }

        close(tmp_filedes);
        fclose(fp);

    } else {
        // by default assume the input file is of binary form
        mem_file = in_file;
    }

    if(! check_file_exists(mem_file.c_str())){
        LOG_F(ERROR, "Aiming to use file %s as memory dump but this file does not exist. Aborting.", mem_file.c_str());
        exit(status_error);
    }

    // Store simulation output file
    const char* sim_filename = options["vcd_filename"].c_str();
    // Check whether we want to create a dumpfile
    if(strlen(sim_filename) > 0){
        LOG_F(INFO, "Using %s as simulation file.", sim_filename );
        tracer_enabled = true;
    }

    // Set up Max cycles and whether we want to abort on timeouts
    MAX_CYCLES = (uint64_t) options.get("cycles");
    auto check_timeout = true;
    if(MAX_CYCLES == 0){
        LOG_F(INFO, "Max cycles set to 0. Will not abort simulation due to timeout.");
        check_timeout = false;
    } else {
        LOG_F(INFO, "Enabled automatic timeout after %lu cycles.", MAX_CYCLES);
    }
    uint64_t MAX_EXECUTION_TIME = MAX_CYCLES*CLOCK_PERIOD;

    // --stop-after-sm-violation allows to abort simulation X cycles after an sm violation occured
    int sm_violation_stopcount = (int) options.get("sm_violation_stopcount");
    bool stop_on_sm_violation = false;
    bool sm_violation_occured = false;
    if(sm_violation_stopcount >= 0)
    {
        stop_on_sm_violation = true;
        LOG_F(INFO, "Will abort simulation %i cycles after any SM_VIOLATION", sm_violation_stopcount);
    }

    if (options.get("crypto_noshow"))
    {
        crypto_noshow = true;
    }

    const char* in_filename = options["fio_in"].c_str();
    if (strlen(in_filename) > 0)
    {
        LOG_F(INFO, "Opening '%s' as file I/O input file.", in_filename);
        fd_in  = fopen(in_filename, "r");
        if (!fd_in)
        {
            LOG_F(ERROR, "Failed to open '%s' as an input file.", in_filename);
            exit(status_error);
        }
    }

    const char* out_filename = options["fio_out"].c_str();
    if (strlen(out_filename) > 0)
    {
        LOG_F(INFO, "Opening '%s' as file I/O output file.", out_filename);
        fd_out = fopen(out_filename, "w");
        if (!fd_out)
        {
            LOG_F(ERROR, "Failed to open '%s' as an output file.", out_filename);
            exit(status_error);
        }
    }

    // Start verilator
    Verilated::commandArgs(argc, argv);
    auto top = std::unique_ptr<Vtb_openMSP430>{new Vtb_openMSP430};
    top->reset_n = 1;
    top->dco_clk = 1;
    top->fio_din = 0xff;
    top->fio_dready = 0;

    // auto memoryFile = argv[argc - 1];
    // Initialize data memory (ram) as a fresh memory
    auto data_memory = Memory{*top, "", "[DMEM]",
            &top->dmem_cen, &top->dmem_wen, &top->dmem_addr, &top->dmem_din, &top->dmem_dout};
    // Initialize program memory (rom) with the given memory file
    auto program_memory = Memory{*top, mem_file.c_str(), "[ROM ]",
            &top->pmem_cen, &top->pmem_wen, &top->pmem_addr, &top->pmem_din, &top->pmem_dout};

    // Enable verilator tracing if we are dumping
    if(tracer_enabled) {
        Verilated::traceEverOn(true);
        top->trace(tracer.get(), 99);
        tracer->open(sim_filename);
    }

    mainTime = 0;
    auto isDone = false;
    int result = 0;
    int cpuoff_timer = 10; // After CPUOFF, do 10 more cycles for nicer GTKWave outputs.

    // Register sigabort handler to finish writing vcd file
    struct sigaction sigIntHandler; 
    sigIntHandler.sa_handler = exit_handler;
    sigemptyset(&sigIntHandler.sa_mask);
    sigIntHandler.sa_flags = 0;
    sigaction(SIGINT, &sigIntHandler, NULL);

    int spinner_pos = 0;
    auto *crypto_sponge_busy = &(top->tb_openMSP430__DOT__dut__DOT__execution_unit_0__DOT__crypto__DOT__wrap__DOT__sponge__DOT__fsm_instance__DOT__reg_busy);
    auto crypto_sponge_busy_prev = 0;

    while (!isDone)
    {
        auto clockEdge = (mainTime % (CLOCK_PERIOD/2) == 0);

        if (clockEdge){
            top->dco_clk = !top->dco_clk;
        }

        if (mainTime >= 5*CLOCK_PERIOD)
            top->reset_n = 0;
        if (mainTime >= 50*CLOCK_PERIOD)
            top->reset_n = 1;
        

        top->eval();
        data_memory.eval(clockEdge && top->dco_clk);
        program_memory.eval(clockEdge && top->dco_clk);
        // top->eval();

        if (clockEdge && top->dco_clk)
        {   
            eval_fileio(top);

            if (mainTime >= MAX_EXECUTION_TIME && check_timeout)
            {
                isDone = true;
                result = status_timeout;
            }

            // Finish simulation if cpuoff marks that processor turned off.
            if (top->cpuoff && cpuoff_timer-- < 0){
                isDone = true;
                result = status_success;
            }

            // Finish simulation if requested after sm violation
            if (stop_on_sm_violation){
                if (top->sm_violation){
                    sm_violation_occured = true;
                }
                if (sm_violation_occured && sm_violation_stopcount-- <= 0){
                    isDone = true;
                    result = status_sm_violation;
                }
            }
        }
        if(tracer_enabled){
            tracer->dump(mainTime);
        }

        /* Hack to show progress spinner while crypto unit is busy. */
        if (clockEdge && top->dco_clk)
        {
            if (*crypto_sponge_busy)
            {
                crypto_cycles++;
            }

            if (!crypto_noshow)
            {
                if (*crypto_sponge_busy != crypto_sponge_busy_prev)
                {
                    char cursor_spin[4]={'\\', '|', '-', '/'};
                    printf(COLOR_CRYPT "[crypto] %c\b\b\b\b\b\b\b\b\b\b" COLOR_RESET, cursor_spin[spinner_pos]);
                    fflush(stdout);
                    spinner_pos = (spinner_pos+1) % 4;
                }
                crypto_sponge_busy_prev = *crypto_sponge_busy;
            }
        }

        mainTime++;
    }

    LOG_F(MAX, "Program memory at exit was..");
    LOG_F(MAX, program_memory.print_memory().c_str());
    LOG_F(MAX, "Data memory at exit was..");
    LOG_F(MAX, data_memory.print_memory().c_str());
    
    return exit_program(result);
}
