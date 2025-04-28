//////////////////////////////////////////////////////////////////////////
/// Author (name and email): Qazi Hamid Ullah, qullah.bee20seecs@seecs.edu.pk
/// Date Created: 2/24/2024
///////////////////////////////////////////////////////////////////////////

module register
#(
  parameter width       = 32,  
  parameter Default_val = 0
)(
  input       clk, 
  input       reset, 
  input       flush,
  input       [width-1:0] d,
  output reg  [width-1:0] q
);

//=======================================================
//  Structural coding
//=======================================================

  always@(posedge clk or negedge reset )
  begin
  	if(!reset)
  		q <= Default_val;
  	else if(flush)
  	 	q <= Default_val;
  	else
  		q <= d;
  end

endmodule
