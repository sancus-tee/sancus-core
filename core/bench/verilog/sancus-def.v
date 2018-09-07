// for simulator testing purposes only

wire        exec_done           = dut.frontend_0.exec_done;
//wire        exec_ras            = dut.frontend_0.exec_ras;
wire [15:0] pc_nxt              = dut.frontend_0.pc_nxt;
wire [15:0] current_inst_pc     = dut.frontend_0.current_inst_pc;
wire        gie                 = dut.frontend_0.gie;
//wire        sm_violation        = dut.frontend_0.sm_irq;
wire [8:0]  inst_so             = dut.frontend_0.inst_so;
wire        inst_irq_rst        = dut.frontend_0.inst_irq_rst;
//wire        sm_executing        = dut.frontend_0.exec_sm;

wire        handling_irq        = dut.execution_unit_0.handling_irq;
wire        crypto_start        = dut.execution_unit_0.crypto.start;
wire        crypto_busy         = dut.execution_unit_0.crypto.busy;

//wire [15:0] stack_guard         = dut.execution_unit_0.register_file_0.stack_guard;
//wire        r2_z                = dut.execution_unit_0.register_file_0.r2_z;

wire [15:0] sm_current_id       = dut.execution_unit_0.spm_control_0.spm_current_id;
wire [15:0] sm_prev_id          = dut.execution_unit_0.spm_control_0.spm_prev_id;
wire [15:0] sm_prev_cycle_id    = dut.execution_unit_0.spm_control_0.prev_cycle_spm_id;

wire [15:0] sm_0_public_start   = dut.execution_unit_0.spm_control_0.omsp_spms[0].public_start;
wire [15:0] sm_1_public_start   = dut.execution_unit_0.spm_control_0.omsp_spms[1].public_start;
wire [15:0] sm_0_secret_end     = dut.execution_unit_0.spm_control_0.omsp_spms[0].secret_end;
wire        sm_0_enabled        = dut.execution_unit_0.spm_control_0.omsp_spms[0].enabled;
wire        sm_1_enabled        = dut.execution_unit_0.spm_control_0.omsp_spms[1].enabled;
wire [15:0] sm_0_id             = dut.execution_unit_0.spm_control_0.omsp_spms[0].id;
wire [15:0] sm_1_id             = dut.execution_unit_0.spm_control_0.omsp_spms[1].id;
wire        sm_0_executing      = dut.execution_unit_0.spm_control_0.omsp_spms[0].executing;
wire        sm_1_executing      = dut.execution_unit_0.spm_control_0.omsp_spms[1].executing;

wire [63:0] cur_tsc             = tsc_0.tsc;

//wire [15:0] vbar_reg            = dut.pic_0.ivt_base;
//
//`ifdef ATOMICITY_MONITOR
//wire [16:0] atom_cnt            = dut.execution_unit_0.atomicity_monitor_0.atom_cnt;
//wire        inst_clix           = dut.execution_unit_0.atomicity_monitor_0.inst_clix;
//`endif
