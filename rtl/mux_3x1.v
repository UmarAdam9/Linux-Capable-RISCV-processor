//////////////////////////////////////////////////////////////////////////
/// Author (name and email): Qazi Hamid Ullah, qullah.bee20seecs@seecs.edu.pk
/// Date Created: 2/24/2024
///////////////////////////////////////////////////////////////////////////

module mux_3x1
#(
  parameter width = 32
)(
  input      [width-1:0] a,
  input      [width-1:0] b,
  input      [width-1:0] c,
  input      [      1:0] s,
  output reg [width-1:0] q 
);

//=======================================================
//  Structural coding
//=======================================================
  always@(*)
  begin
  	case(s)
  	2'b00: q = a;
  	2'b01: q = b;
  	2'b10: q = c;
  	default: q = {width{1'b0}};
  	endcase
  end

endmodule


module mux_4x1
#(
  parameter width = 32
)(
  input      [width-1:0] a,
  input      [width-1:0] b,
  input      [width-1:0] c,
  input      [width-1:0] d,
  input      [      1:0] s,
  output reg [width-1:0] q 
);

//=======================================================
//  Structural coding
//=======================================================
  always@(*)
  begin
  	case(s)
  	2'b00: q = a;
  	2'b01: q = b;
  	2'b10: q = c;
    2'b11: q = d;
  	default: q = {width{1'b0}};
  	endcase
  end

endmodule
