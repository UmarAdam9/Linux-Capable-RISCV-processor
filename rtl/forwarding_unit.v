//////////////////////////////////////////////////////////////////////////
/// Author (name and email): Qazi Hamid Ullah, qullah.bee20seecs@seecs.edu.pk
/// Date Created: 2/24/2024
///////////////////////////////////////////////////////////////////////////

module forwarding_unit(
  input      [4:0] rs1, 
  input      [4:0] rs2, 
  input      [4:0] EX_MEM_rd, 
  input      [4:0] MEM_WB_rd,
  input            EX_MEM_regwrite, 
  input            MEM_WB_regwrite,
  input            is_atomic,
  input            sc_w_inst_EX_MEM,
  input            sc_w_inst_MEM_WB,
  input            reserved,
  input		 [6:0]instruction_in,
  output reg [2:0] forward_A, 
  output reg [2:0] forward_B
);

//=======================================================
//  Structural coding
//=======================================================

	always@(*)
	begin
		// MUX A
    if(sc_w_inst_EX_MEM && EX_MEM_rd!=5'b0 && EX_MEM_rd==rs1)
      forward_A = 3'b011;      
		
		else if(EX_MEM_regwrite==1'b1 && EX_MEM_rd!=5'b0 && EX_MEM_rd==rs1 && !sc_w_inst_EX_MEM) 
			begin     //checking EX Hazard
				if(instruction_in == 7'b1110011)
					forward_A = 3'b100;
				else
					forward_A = 3'b010;
				
			end
			
			
		else if(MEM_WB_regwrite==1'b1 && MEM_WB_rd!=5'b0 && MEM_WB_rd==rs1 ) //checking MEM Hazard
			forward_A = 3'b001;
			
		else 	forward_A = 3'b000;									                          //no fwding hazard


		// MUX B
    if(sc_w_inst_EX_MEM && EX_MEM_rd!=5'b0 && EX_MEM_rd==rs2)
      forward_A = 3'b011;
		
    else if(EX_MEM_regwrite==1'b1 && EX_MEM_rd!=5'b0 && EX_MEM_rd==rs2 && !is_atomic && !sc_w_inst_EX_MEM) begin     //checking EX Hazard
	 
			if(instruction_in[6:0] == 6'b1110011)
				forward_A = 3'b100;
			else
				forward_B = 3'b010;
			end
			
		else if(MEM_WB_regwrite==1'b1 && MEM_WB_rd!=5'b0 && MEM_WB_rd==rs2 ) //checking MEM Hazard
			forward_B = 3'b001;
			
		else  forward_B = 3'b000;								                            //no fwding hazard

	end

endmodule
