module mux_5x1
#(
  parameter width = 32
)(
  input      [width-1:0] a,
  input      [width-1:0] b,
  input      [width-1:0] c,
  input      [width-1:0] d,
  input      [width-1:0] e,
  input      [      2:0] s,
  output reg [width-1:0] q 
);

//=======================================================
//  Structural coding
//=======================================================
  always@(*)
  begin
  	case(s)
  	3'b000: q = a;
  	3'b001: q = b;
  	3'b010: q = c;
   3'b011: q = d;
   3'b100: q = e;
	
  	default: q = {width{1'b0}};
  	endcase
  end

endmodule