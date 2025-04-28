
module m_hazard_detection_unit(
	input [4:0] ID_EX_rd, 
	input [4:0] IF_ID_rs1, 
	input [4:0] IF_ID_rs2,
	input       ID_EX_memread,
	input [6:0] opcode,
	
	
	input		exe_pc_req_i,	//PCsrc signal
	input		csr_pc_req_i,
	input 		wfi_req_i,
	
	//  input       irq_flush_mem2wb,
	


	output		exe_pc_req_o,
	output		csr_pc_req_o,
	output		wfi_req_o,
		
	output reg  PCWrite, 	 //Blocks the pc read 
	output reg  IF_Dwrite,   //blocks the IF/Dec pipeline
	output reg  hazard_out	 //sends all zeroes as control signals to the execute stage (NOOP?)
);

  parameter Load = 7'b0000011;
  
  logic 	ld_use_hazard;

//=======================================================
//  Structural coding
//=======================================================
	always@(*)
	begin
		if(( ID_EX_memread && ( ID_EX_rd==IF_ID_rs1 || (ID_EX_rd==IF_ID_rs2 && opcode!=Load)) ) | wfi_req_i)  begin
			//stall the pipeline
			hazard_out = 1'b1;
			PCWrite    = 1'b0;
			IF_Dwrite  = 1'b0;
			ld_use_hazard = 1'b1;
		end	
		else begin
			//no need to stall the pipeline
			hazard_out = 1'b0;
			PCWrite    = 1'b1;
			IF_Dwrite  = 1'b1;
			ld_use_hazard = 1'b0;
		end

	end
	
	
	
	assign exe_pc_req_o = exe_pc_req_i & ~(ld_use_hazard); //lsu_stall signal to be added
	assign csr_pc_req_o = csr_pc_req_i;
	assign wfi_req_o 	= wfi_req_i;
 

endmodule
