`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif
`ifdef ATOMICITY_MONITOR

module omsp_atomicity_monitor (
  input  wire                    mclk,
  input  wire                    puc_rst,
  input  wire                    inst_clix,
  input  wire                    sm_executing,
  input  wire                    priv_mode,
  input  wire             [15:0] r15,
  input  wire                    irq_detect,
  input  wire                    enter_sm,
  input  wire                    r2_gie,      // access control in omsp_register_file
  
  output wire                    gie,
  output wire                    atom_violation
);


// TRACK LENGTH OF ATOMIC SECTIONS
//-----------------------------------------
parameter ATOM_CNT_WIDTH                    = $clog2(`ATOM_BOUND)+1;
parameter ATOM_ENTRY_WIDTH                  = $clog2(`SM_ENTRY_ATOM_PERIOD)+1;

// limit the length of atomic code sections; initiated via clix instruction
wire [ATOM_CNT_WIDTH-1:0]   atom_clix_input     = r15[ATOM_CNT_WIDTH-1:0];
reg  [ATOM_CNT_WIDTH-1:0]   atom_clix_cnt;
reg [ATOM_ENTRY_WIDTH-1:0]  atom_entry_cnt;   // Counter for hard-coded atomic period after SM entries

reg                         inside_clix;      // Flags whether we are inside a clix section
reg                         inside_clix_prev;
reg                         inside_entry;     // Flag whether we are inside an SM entry atomic section
reg                         inside_entry_prev;

// clix is stopped when atom_clix_cnt reaches zero or r2 has gie set. 
// This is assumed to be a request to end the clix and allows to early-out
wire                        clix_finished  = (inside_clix  & ((atom_clix_cnt  == 0) | r2_gie));
// SM entry section is completed after expiring or on entering a clix instruction
wire                        entry_finished = (inside_entry & ((atom_entry_cnt == 0) | inst_clix)); 


always @(posedge mclk or posedge puc_rst)
begin
    inside_clix_prev  <= inside_clix;
    inside_entry_prev <= inside_entry;
    if (puc_rst)                                     // On System reset, reset monitor too
    begin
            inside_clix      <= 0;
            atom_clix_cnt    <= 0;
            inside_entry     <= 0;
            atom_entry_cnt   <= 0;
    end 
    else if(inside_clix)                             // If inside a clix, decrement counter or complete clix
    begin
      if   (clix_finished)
      begin
            inside_clix      <= 0;
            atom_clix_cnt    <= 0;
      end
      else  atom_clix_cnt    <= atom_clix_cnt - 1;
    end
    else if (inst_clix)                              // If executing a new valid clix, start off from clix input 
    begin
            inside_clix      <= 1;
            atom_clix_cnt    <= atom_clix_input;
    end
    `ifdef SANCUS_RESTRICT_GIE
    else if (enter_sm & priv_mode )  // With restrictions on GIE, abort existing clix and disable interrupts on entry of SM ID 1
    begin
            inside_clix      <= 0;
            atom_clix_cnt    <= 0;
    end
    `endif
    if (~puc_rst & enter_sm)             // Always enter period without interrupts when entering an SM
    begin
        `ifdef SANCUS_RESTRICT_GIE
        if (priv_mode)                  // If entering special ID 1, we disable the atomic period
        begin
            inside_entry <= 0;
            atom_entry_cnt <= 0;
        end
        else 
        `endif
        if(inside_entry_prev)
        begin                         // entering an sm while inside an entry is forbidden
            inside_entry <= 0;    //  and will be caught below when throwing an atom_violation
            atom_entry_cnt <= 0;      //  this if just makes sure that the atom period ends
        end
        else
        begin
            inside_entry   <= 1;
            atom_entry_cnt <= `SM_ENTRY_ATOM_PERIOD;
        end
    end
    else if (~puc_rst & inside_entry)
    begin
        if (entry_finished)
        begin
              inside_entry     <= 0;
              atom_entry_cnt   <= 0;
        end
        else  atom_entry_cnt   <= atom_entry_cnt - 1;
    end

end

assign gie = r2_gie
`ifdef SANCUS_RESTRICT_GIE
            // Disable interrupts in SM ID 1 if GIE is restricted
             & ~(priv_mode & sm_executing)
`endif
             & ~inst_clix
             & (~inside_clix | clix_finished)
             & ~inside_entry
             & ~enter_sm;

// nesting of atomic sections (clix or sm entry) is not allowed + do not exceed max bound
assign atom_violation   = (inst_clix & ( inside_clix_prev | (atom_clix_input > `ATOM_BOUND)))
                        // we also can't enter another sm if we are already in an atomic entry section
                        | (enter_sm 
                            & inside_entry_prev
                            `ifdef SANCUS_RESTRICT_GIE
                              // (but we can enter the SM with ID 1 if GIE is restricted)
                              & ~priv_mode 
                            `endif
                        );

// DEBUG OUTPUT
//-----------------------------------------

//`ifdef __SANCUS_SIMULATOR
initial
begin
    $display("=== Atomicity parameters  ===");
    $display("Atom bound:    %3d", `ATOM_BOUND);
    $display("=============================");
end

always @(posedge mclk)
begin
  if (atom_violation)
  begin
    $write("atom violation: ");
    if (~gie)   $display("nesting is not allowed");
    else        $display("%d > %d", atom_clix_input, `ATOM_BOUND);
  end
end
//`endif

endmodule
`endif
