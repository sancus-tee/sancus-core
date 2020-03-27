#include "Vtb_openMSP430.h"

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>
#include <vector>
#include <iostream>
#include <iomanip>
#include <fstream>

#include <cstdint>
#include <cassert>

#include <sys/select.h>
#include <sys/time.h>

#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "OptionParser.h"

using namespace std;
using optparse::OptionParser;

const double TIMESCALE       = 1e-9;
const int    CLOCK_FREQUENCY = 20*1e6;
const int    CLOCK_PERIOD    = 1/(CLOCK_FREQUENCY*TIMESCALE);
uint64_t MAX_CYCLES = 1000000000ULL;

enum exit_codes{success, error, timeout, program_abort, no_input_file};

 class Memory
 {
 public:

    Memory(Vtb_openMSP430& top, const char* memoryFile, string name,
        CData *chip_enable, CData *write_enable, SData *addr, SData *din, SData *dout) 
            : top_{top}, _name{name}, _chip_enable{chip_enable}, _write_enable{write_enable}, _addr{addr}, _din{din}, _dout{dout}
    {
        // We allow null strings as input and then use an empty memory
        if(strcmp(memoryFile, "")){
            auto ifs = std::ifstream{memoryFile, std::ifstream::binary};
            auto memoryBytes =
                std::vector<unsigned char>{std::istreambuf_iterator<char>(ifs), {}};

            assert((memoryBytes.size() % 2 == 0) &&
                    "Memory does not contain a multiple of words");

            auto i = std::size_t{0};
            printf("0x0000: ");
            while (i < memoryBytes.size())
            {
                if(i%32 == 0) printf("\n0x%4x: ", i/2);
                auto b0 = memoryBytes[i++];
                auto b1 = memoryBytes[i++];

                Word word = b0 | (b1 << 8) ; // little endian
                // auto word = (b0 << 8) | b1;
                printf("%4x ", word);
                memory_.push_back(word);
            }
            printf("\nRead memory of %u bytes.\n", memoryBytes.size());
        }
    }

    bool eval()
    {
        auto updated = false;

        if (! *_chip_enable) // chip enable is low active
        {
            if (*_write_enable != 0b11) // write enable is low active
            {
                write(*_addr, *_write_enable, *_din);
            }
            // Always write to dout
            *_dout = read(*_addr);

            updated = true;
        }
        printf("[Memory] %s Regs are: cen: %x wen: %x, addr: %2x, in: %2x, out:%2x\n",_name.c_str(), *_chip_enable, *_write_enable, *_addr, *_din, *_dout);

        return false;
    }

    string print_memory(){
        std::ostringstream stringStream;
        // stringStream << "0x0000: ";
        
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

    using Address = std::uint16_t;
    using Word = std::uint16_t;
    using Mask = std::uint8_t;

    Word read(Address address)
    {
        ensureEnoughMemory(address);
        Word memoryValue = memory_[(prev_address)];
        prev_address = address;
        printf("[Memory] %s [Read] %x : %x\n", _name.c_str(), prev_address, memoryValue);
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

        printf("[Memory] %s [Write] %x : %x\n", _name.c_str(), address, memoryValue);
    }

    void ensureEnoughMemory(Address address)
    {
        if ((address) >= memory_.size())
        {
            memory_.reserve((address) + 1);

            while ((address) >= memory_.size())
                memory_.push_back(0xcafe);
        }
    }

    Vtb_openMSP430& top_;
    Address prev_address;
    std::vector<Word> memory_;
    string _name;
    CData *_chip_enable;
    CData *_write_enable;
    SData *_addr;
    SData *_din;
    SData *_dout;
};

auto tracer = std::unique_ptr<VerilatedVcdC>{new VerilatedVcdC};

int exit_program(int result){
    cout << endl << endl << "======================== Simulation ended ========================" << endl;
    switch(result){
        case success:
            cout <<         "================ Simulation succeeded gracefully =================" << endl;
            break;
        case timeout:
            cout <<         "===== Simulation stopped after timeout of " << MAX_CYCLES << " cycles =====" << endl;
            break;
        case program_abort:
            cout <<         "============= Simulation stopped after program abort =============" << endl;
            break;
        default:
            cout <<         "============== Simulation failed with unknown error ==============" << endl;
            break;
    }

    tracer->close();
    return result;
}

void exit_handler(int s){
    exit_program(program_abort);
    
    exit(program_abort); 

}

int main(int argc, char** argv)
{
    // assert(argc >= 2 && "No memory file name given");

    // Set up option parser based on some GitHub library
    OptionParser parser = OptionParser() .description("Sancus Simulator based on Verilator");

    parser.add_option("-f", "--file") .dest("filename")
                    .help("Input file to use") .metavar("FILE");
    parser.add_option("-o", "--out_file") .dest("vcd_filename") .set_default("sim.vcd")
                    .help("Name of the outputted simulation vcd file.") .metavar("OUTFILE");
    parser.add_option("-t", "--type") .dest("type") .set_default("pmem")
                    .help("File type (elf, hex, pmem allowed)") .metavar("TYPE");
    // parser.add_option("-q", "--quiet")
    //                 .action("store_false") .dest("verbose") .set_default("1")
    //                 .help("don't print status messages to stdout");
    parser.add_option("-c", "--cycles") .dest("cycles") .type("long") .set_default(MAX_CYCLES)
                    .help("Maximum of cycles to execute before aborting. Set 0 for no timeout.") .metavar("TYPE");

    optparse::Values options = parser.parse_args(argc, argv);
    vector<string> args = parser.args();


    cout << "======================= Sancus Simulator =======================" << endl;

    // check input filename given
    string mem_file = options["filename"];
    if (mem_file == ""){
        cout << "No input file given. Aborting." << endl;
        exit(no_input_file);
    } else {
        cout << "Using input file " << mem_file << "." << endl;
    }

    // Print simulation output file
    cout << "Using " << options["vcd_filename"] << " as simulation file." << endl;

    // Set up Max cycles and whether we want to abort on timeouts
    MAX_CYCLES = (uint64_t) options.get("cycles");;
    auto check_timeout = true;
    if(MAX_CYCLES == 0){
        cout << "Max cycles set to 0. Not aborting simulation due to timeout..." << endl;
        check_timeout = false;
    } else {
        cout << "Enabled automatic timeout after " << MAX_CYCLES << " cycles." << endl;
    }
    uint64_t MAX_EXECUTION_TIME = MAX_CYCLES*CLOCK_PERIOD;


    // Start verilator
    Verilated::commandArgs(argc, argv);
    auto top = std::unique_ptr<Vtb_openMSP430>{new Vtb_openMSP430};
    top->reset_n = 1;
    top->dco_clk = 1;

    // auto memoryFile = argv[argc - 1];
    // Initialize data memory (ram) as a fresh memory
    auto data_memory = Memory{*top, "", "[DMEM]",
            &top->dmem_cen, &top->dmem_wen, &top->dmem_addr, &top->dmem_din, &top->dmem_dout};
    // Initialize program memory (rom) with the given memory file
    auto program_memory = Memory{*top, mem_file.c_str(), "[ROM ]",
            &top->pmem_cen, &top->pmem_wen, &top->pmem_addr, &top->pmem_din, &top->pmem_dout};

    Verilated::traceEverOn(true);
    top->trace(tracer.get(), 99);
    tracer->open(options["vcd_filename"].c_str());

    vluint64_t mainTime = 0;
    auto isDone = false;
    int result = 0;


    // Register sigabort handler to finish writing vcd file
    struct sigaction sigIntHandler; 
    sigIntHandler.sa_handler = exit_handler;
    sigemptyset(&sigIntHandler.sa_mask);
    sigIntHandler.sa_flags = 0;
    sigaction(SIGINT, &sigIntHandler, NULL);


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

        if (clockEdge && top->dco_clk)
        {   
            // Evaluate both memories and run top eval again if something changed.
            if (data_memory.eval())
                top->eval();

            if (program_memory.eval())
                top->eval();

            if (mainTime >= MAX_EXECUTION_TIME && check_timeout)
            {
                isDone = true;
                result = timeout;
            }

            // Finish simulation if cpuoff marks that processor turned off.
            if (top->cpuoff){
                isDone = true;
                result = success;
            }
        }
        tracer->dump(mainTime);

        mainTime++;
    }

    // printf("\nProgram Memory:\n");
    // printf(program_memory.print_memory().c_str());
    printf("\nData Memory at exit:\n");
    printf(data_memory.print_memory().c_str());
    
    return exit_program(result);

}
