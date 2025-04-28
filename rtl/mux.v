//////////////////////////////////////////////////////////////////////////
/// Author (name and email): Qazi Hamid Ullah, qullah.bee20seecs@seecs.edu.pk
/// Date Created: 2/24/2024
///////////////////////////////////////////////////////////////////////////


module mux
#(
	parameter width = 32
)(
	input  [width-1:0] a,
	input  [width-1:0] b,
	input              s, 
	output [width-1:0] c
);

//=======================================================
//  Structural coding
//=======================================================
	assign c = (s) ? b : a ;

endmodule
