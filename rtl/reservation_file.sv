//////////////////////////////////////////////////////////////////////////
/// Author (name and email): Qazi Hamid Ullah, qullah.bee20seecs@seecs.edu.pk
/// Date Created: 2/10/2024
/// Description: <reservation set with combinational read but writes at a clock>
///////////////////////////////////////////////////////////////////////////

module reservation_file
#(
	parameter DATA_WIDTH=6, 
	parameter ADDR_WIDTH=2
)(
	input                           clk,
	input                           rst,
  input   [31:0]                  instruction,   
  output  logic                   reserved          

);

//=======================================================
//  REG/WIRE declarations
//=======================================================
 
	reg      [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0]; // Declare the RAM variable
	integer  i;                                       // variable of for loop

  logic         we;
  logic [4:0]   comp_addr;
  logic [5:0]   compare_data;
  logic [5:0]   write_data;


//=======================================================
//  Structural coding
//=======================================================

    //if valid bit = 0 then we can write on it otherwise we cannot write on it
    //initially we can consider 4 reservation registers 
    //compare data = {1'b1,rs1_addr}

  //signals assignments 
  //when lr_w comes 
  assign we         =   (instruction[6:0] == 7'b0101111 & instruction[14:12] == 3'd2 & instruction[31:27] == 5'd2) ? 1:0;               //when lr.w 
  //when sc_w comes (instruction[6:0] == 7'b0101111 & instruction[14:12] == 3'd2 & instruction[31:27] == 5'd3) ? 1:0;
  assign read_en1   =   (instruction[6:0] == 7'b0101111 & instruction[14:12] == 3'd2 & instruction[31:27] == 5'd3) ? 1:0;         //when sc.w
  assign comp_addr  =   instruction[19:15];
  //when simple store instructions comes 
  assign read_en2   =   (instruction[6:0] ==  7'b0100011) ? 1:0;  
  //final read signal in case of any store instructions 
  assign read_en    =   read_en1 | read_en2;

  //this will be used to search in case of sc_w 
  assign compare_data = {1'b1,comp_addr};
  //this will be written to the reservation file in case of lr_w. the first bit is valid 
  assign write_data   = {1'b1,comp_addr};                   


  //Read
  always @ (*) begin 
    reserved = 0;
    if(read_en) begin 
      if(ram[0] == compare_data) begin 
        reserved  = 1;
        // read_data = ram[0];
      end
      else if(ram[1] == compare_data) begin
        //read_data = ram[1];
        reserved  = 1;
      end
      else if(ram[2] == compare_data) begin
        //read_data = ram[2];
        reserved  = 1;
      end
      else if(ram[3] == compare_data) begin
       // read_data = ram[3];
        reserved  = 1;
      end
      else 
        reserved = 0;
    end
  end
  // Write
  always @ (posedge clk, negedge rst)
	begin
		if(~rst) begin                      //reset the reservation file
		  for (i=0; i< 2**ADDR_WIDTH; i=i+1)
		    ram[i] <= 6'd0;
		end
    else if(read_en) begin              //clear the reservation after the atomic is complete or sc.w comes  
      if(ram[0] == compare_data)
        ram[0] <= 6'd0;
      else if(ram[1] == compare_data)
        ram[1] <= 6'd0;
      else if(ram[2] == compare_data)
        ram[2] <= 6'd0;
      else if(ram[2] == compare_data)
        ram[3] <= 6'd0;
      else
        ram <= ram; 
    end
		else if (we) begin 
      if(ram[0][DATA_WIDTH-1] == 0 )          //check whether the data present in it is valid or not 
		    ram[0] <= write_data;
      else if (ram[1][DATA_WIDTH-1] == 0) 
        ram[1] <= write_data;
      else if (ram[2][DATA_WIDTH-1] == 0) 
        ram[2] <= write_data;
      else
        ram[3] <= write_data;      //if all the locations above are not available then write in the end location 
    end
	end

endmodule