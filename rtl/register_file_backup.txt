//////////////////////////////////////////////////////////////////////////
/// Author (name and email): Qazi Hamid Ullah, qullah.bee20seecs@seecs.edu.pk
/// Date Created: 2/24/2024
///////////////////////////////////////////////////////////////////////////

module register_file
#(
	parameter DATA_WIDTH=32, 
	parameter ADDR_WIDTH=5
)(
	input                     we, 
	input                     clk,
	input                     rst,
	input [(DATA_WIDTH-1):0]  write_data,
	input [(ADDR_WIDTH-1):0]  rs1,
	input [(ADDR_WIDTH-1):0]  rs2,
	input [(ADDR_WIDTH-1):0]  rd,
	
	output [(DATA_WIDTH-1):0] read_data1, 
	output [(DATA_WIDTH-1):0] read_data2
);

//=======================================================
//  REG/WIRE declarations
//=======================================================

	reg      [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0]; // Declare the RAM variable
	integer  i;                                       // variable of for loop

//=======================================================
//  Structural coding
//=======================================================
  
  //Read
  assign read_data1 = (we && rd==rs1 && rd!=0) ? write_data: ram[rs1];
  assign read_data2 = (we && rd==rs2 && rd!=0) ? write_data: ram[rs2];
	

  // Write
  always @ (posedge clk, negedge rst)
	begin
		if(~rst) begin
		  for (i=0; i< 2**ADDR_WIDTH; i=i+1)
		    ram[i] <= 32'd0;
		end
		else if (we & rd!=0)
		  ram[rd] <= write_data;
	end

endmodule
