module memory ();

integer index_mem_dbg;

initial
begin
	$dumpfile(`DUMPFILE);
	`ifdef SHOW_PMEM_WAVES
	 for (index_mem_dbg= (`PMEM_SIZE-512)/2; i < (`PMEM_SIZE-512)/2+128; i=i+1)
	 $dumpvars(0, tb_openMSP430.pmem_0.mem[index_mem_dbg]);//show the memory content into the waveform! (Sergio) 
	 `endif
	`ifdef SHOW_DMEM_WAVES
	 for (index_mem_dbg= (`DMEM_SIZE-256)/2; i < (`DMEM_SIZE-256)/2+128; i=i+1)
	 $dumpvars(0, tb_openMSP430.dmem_0.mem[index_mem_dbg]);//show the memory content into the waveform! (Sergio) 
	`endif 
end
endmodule
