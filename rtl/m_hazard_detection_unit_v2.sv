
module m_hazard_detection_unit_v2(
	input logic clk,
	input logic rst,
	input [4:0] ID_EX_rd, 
	input [4:0] IF_ID_rs1, 
	input [4:0] IF_ID_rs2,
	input       ID_EX_memread,
	input [6:0] opcode,
	
	
	input		exe_pc_req_i,	//PCsrc signal
	input		csr_pc_req_i,
	input 		wfi_req_i,
	
   input       irq_flush,
	
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
	
	output logic  PC_changed
	
);

  parameter Load = 7'b0000011;
  
  logic 	ld_use_hazard;
  logic  lsu_stall_ff, lsu_stall_next;
  logic	lsu_flush;
  logic  serve_exe_pc_req;
//=======================================================
//  Structural coding
//=======================================================

	assign lsu_flush = csr_pc_req_i | wfi_req_i;
	assign ld_use_hazard = ( ID_EX_memread && ( ID_EX_rd==IF_ID_rs1 || (ID_EX_rd==IF_ID_rs2 && opcode!=Load)) );
	assign serve_exe_pc_req = exe_pc_req_i & ~(ld_use_hazard | lsu_stall); //only serve execute pc req on these conditions

	
	assign flush_MEM_WB = irq_flush;
	assign exe_pc_req_o = serve_exe_pc_req;
	assign csr_pc_req_o = csr_pc_req_i;
	assign wfi_req_o 	= wfi_req_i;
	assign PC_changed = serve_exe_pc_req | csr_pc_req_i;
	
	
	
	
	//there's a priority here , is it asked for or not?
	always@(*)
	begin
	
	
	//load_use hazard handling
		if(ld_use_hazard)  begin
	
			hazard_out = 1'b1;//flushes the ID/EXE
			PCWrite    = 1'b0;
			IF_Dwrite  = 1'b0;
			
		end	
		
	//lsu stall
		else if(lsu_stall_next)begin
			
			PCWrite    = 1'b0;//disable pc
			IF_Dwrite  = 1'b0;//stall IF/ID
			ID_EXEwrite= 1'b0;//stall ID/EXE
		end
		
		
	//Branching from execute stage
		else if(serve_exe_pc_req)begin
		
			flush_IF_ID= 1'b1;
			flush_ID_EXE=1'b1;
			
		end
		
	//Branching from csr stage
		else if(csr_pc_req_i)begin
			
			flush_IF_ID= 1'b1;
			flush_ID_EXE=1'b1;
			flush_EXE_MEM=1'b1;
			
		end
	
	//WFI instruction
		else if(wfi_req_i)begin
			flush_IF_ID= 1'b1;
			flush_ID_EXE=1'b1;
		
		end
		
		else begin
		
		//normal execution
		  PCWrite	= 1'b1; 	 //Blocks the pc read 
		  IF_Dwrite = 1'b1;   	//blocks the IF/Dec pipeline
		  ID_EXEwrite = 1'b1;	//stalls the decode/exe pipeline
		  EXE_MEMwrite = 1'b1;	//stalls the exe/mem pipeline
		  hazard_out = 1'b0;	 //sends all zeroes as control signals to the execute stage (NOOP?) (flush?)
		  flush_IF_ID= 1'b0;
		  flush_ID_EXE= 1'b0;
		  flush_EXE_MEM= 1'b0;
		  flush_MEM_WB= 1'b0;
		
		end
		
	

	end
	
	
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
	
	

	
	
	
	
	
	
	
	
	
 

endmodule
