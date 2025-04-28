//////////////////////////////////////////////////////////////////////////
/// Author (name and email): Qazi Hamid Ullah, qullah.bee20seecs@seecs.edu.pk
/// Date Created: 2/24/2024
///////////////////////////////////////////////////////////////////////////

module hazard_detection_unit(
	input [4:0] ID_EX_rd, 
	input [4:0] IF_ID_rs1, 
	input [4:0] IF_ID_rs2,
	input       ID_EX_memread,
	input [6:0] opcode,
	output reg  PCWrite, 
	output reg  IF_Dwrite, 
	output reg  hazard_out
);

  parameter Load = 7'b0000011;

//=======================================================
//  Structural coding
//=======================================================
	always@(*)
	begin
		if(ID_EX_memread && ( ID_EX_rd==IF_ID_rs1 || (ID_EX_rd==IF_ID_rs2 && opcode!=Load)))  begin
			//stall the pipeline
			hazard_out = 1'b1;
			PCWrite    = 1'b0;
			IF_Dwrite  = 1'b0;
		end
		else begin
			//no need to stall the pipeline
			hazard_out = 1'b0;
			PCWrite    = 1'b1;
			IF_Dwrite  = 1'b1;
		end

	end

endmodule
