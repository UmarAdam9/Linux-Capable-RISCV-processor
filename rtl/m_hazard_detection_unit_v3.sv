
module m_hazard_detection_unit_v3(
	input logic clk,
	input logic rst,
	input [4:0] ID_EX_rd, 
	input [4:0] IF_ID_rs1, 
	input [4:0] IF_ID_rs2,
	input       ID_EX_memread,
	input [6:0] opcode,
	
	
	input		exe_pc_req_i,	//PCsrc signal
	input		csr_pc_req_i,
	input 	wfi_req_i,
   input    irq_flush_i,
	
	//from lsu
	input logic lsu_req,
	inout logic lsu_ack,
	

	output		exe_pc_req_o,
	output		csr_pc_req_o,
	output		wfi_req_o,
		
	output reg  	PCWrite, 	 //Blocks the pc read 
	output reg  	IF_Dwrite,   	//blocks the IF/Dec pipeline
	output logic 	ID_EXEwrite,	//stalls the decode/exe pipeline
	output logic 	EXE_MEMwrite,	//stalls the exe/mem pipeline
	
	output reg  	hazard_out,	 //sends all zeroes as control signals to the execute stage (NOOP?) (flush?)
	
	
	output logic  flush_IF_ID,
	output logic  flush_ID_EXE,
	output logic  flush_EXE_MEM,
	output logic  flush_MEM_WB,
	
	output logic  PC_changed,
	output logic  lsu_flush_o
	
);

  parameter Load = 7'b0000011;
  
  logic 	ld_use_hazard;
  logic  lsu_stall_ff, lsu_stall_next;
  logic	lsu_flush;
  logic  serve_exe_pc_req;
//=======================================================
//  Structural coding
//=======================================================

	assign lsu_flush = csr_pc_req_i | wfi_req_i; //has to be sent to the lsu for pipeline flushing
	assign ld_use_hazard = ( ID_EX_memread && ( ID_EX_rd==IF_ID_rs1 || (ID_EX_rd==IF_ID_rs2 && opcode!=Load)) ) & ~(lsu_req); //OR'ed with csr_read, csr read cannot have ld_use hzd violation?
	assign serve_exe_pc_req = exe_pc_req_i & ~(ld_use_hazard | lsu_stall_next); //only serve execute pc req on these conditions

	
	
	assign exe_pc_req_o = serve_exe_pc_req;
	assign csr_pc_req_o = csr_pc_req_i;
	assign wfi_req_o 	= wfi_req_i;
	assign PC_changed = serve_exe_pc_req | csr_pc_req_i;	//should it have wfi?? 	
	
	
	// Stall and write-enable control logic
		assign PCWrite      = ~(ld_use_hazard | lsu_stall_next);
		assign IF_Dwrite    = ~(ld_use_hazard | lsu_stall_next);
		assign ID_EXEwrite  = ~lsu_stall_next;
		assign EXE_MEMwrite = ~lsu_stall_next;  			   // Assuming EXE_MEMwrite is not stalled in these cases
		assign hazard_out   = ld_use_hazard;  // Only true when there's a load-use hazard

		// Flush signals (assuming you've handled prioritization elsewhere)
		assign flush_IF_ID   = serve_exe_pc_req | csr_pc_req_i | wfi_req_i;
		assign flush_ID_EXE  = serve_exe_pc_req | csr_pc_req_i | wfi_req_i;
		assign flush_EXE_MEM = lsu_flush;  // | ld_use_hazard  not applicable because in UET core he checks it in exe_mem stage YAAAR WHYYYY SOO CONFUSINGGGGG
		assign flush_MEM_WB  =  irq_flush_i;  // flush when there are interrupts , why not on ld_misalign and st_misalign exception??? well it is being handled in the csr unit

	
	
	//the lsu_stall register
	
	always_ff @(posedge clk)
	begin
		    if (rst | lsu_flush) begin
				  lsu_stall_ff <= '0;
			 end else begin
				  lsu_stall_ff <= lsu_stall_next;
			 end

	end
	
	//next state logic
	always_comb 
	
	begin
			 lsu_stall_next = lsu_stall_ff; 

			 if (lsu_ack) begin
				  lsu_stall_next = 1'b0;
			 end else if (lsu_req) begin                         
				  lsu_stall_next = 1'b1; 
			 end   
	
	end
	
	

	assign lsu_flush_o= lsu_flush;
	
	
	
	
	
	
	
	
 

endmodule
