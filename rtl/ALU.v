

module ALU (
  input      [4:0] ALUctl,
  input      [31:0] A,
  input      [31:0] B,
  output reg [31:0] ALUOut,
  output            Zero,
  output            n_zero,
  output            less_than,
  output            greater_than,
  output            less_than_u,
  output            greater_than_u
);

//=======================================================
//  REG/WIRE declarations
//=======================================================

wire [4:0]shamt; 
wire [63:0] muls;
wire [63:0] mulsu;
wire [63:0] mulu;

wire [63:0] C,D;

//=======================================================
//  Structural coding
//=======================================================

  assign Zero           = (ALUOut==0); //Zero is true if ALUOut is 0
  assign n_zero         = (ALUOut!=0)  ? 1 : 0; //n_Zero is true if ALUOut is not 0
  assign less_than      = ($signed(A) < $signed(B)) ? 1 : 0; //less_than is true if A is less than B
  assign greater_than   = ($signed(A)>$signed(B) | $signed(A)==$signed(B)) ? 1 : 0; //greater_than is true if A is greater than B
  assign less_than_u    = (A < B)      ? 1 : 0; //less_than is true if A is less than B (Unsigned)
  assign greater_than_u = (A>B | A==B) ? 1 : 0; //greater_than is true if A is greater than B (Unsigned)

  assign C = $signed(A);
  assign D = $signed(B);

  assign shamt = B[4:0]; 
  assign muls  = C * D;
  assign mulsu = C * $unsigned(B);
  assign mulu  = $unsigned(A) * $unsigned(B);

  always @(*) 
  begin
    ALUOut = 32'd0; 
    case (ALUctl)
    0: ALUOut  = A & B;
    1: ALUOut  = A | B;
    2: ALUOut  = A + B;
    6: ALUOut  = A - B;
    7: ALUOut  = (A < B) ? 1 : 0; // sltu
    10: ALUOut = ~(A | B); // result is nor 

    9: ALUOut  = A ^ B; // result is xor 

    3: ALUOut  = A << shamt; // sll,slli
    4: ALUOut  = A >> shamt; // srl,srli
    5: ALUOut  = $signed(A) >>> shamt; // sra,srai
        
    8: ALUOut  = $signed(A) < $signed(B) ? 1 : 0; // slt
        
    //MULTIPLY EXTENSION
    11: ALUOut = muls[31:0];   // mul
    12: ALUOut = muls[63:32];  // mulh
    13: ALUOut = mulsu[63:32]; // mulsu
    14: ALUOut = mulu[63:32];  // mulu
        
    15: begin       // div
        if(D == 0)
                ALUOut = 32'hffffffff;  //quoteient
        else if(C == 64'hffffffff80000000 && D == 64'hffffffffffffffff)
                ALUOut = C;
        else ALUOut = $signed(C) / $signed(D); 
        end   
          
    16: begin       //divu
        if(B == 0)
                ALUOut = 32'hffffffff;  //quoteient
        else ALUOut = A / B; 
        end 

    17: begin       // rem
        if(D == 64'b0)
                ALUOut = C;             //dividend
        else if(C == 64'hffffffff80000000 && D == 64'hffffffffffffffff)
                ALUOut = 0;
        else ALUOut = $signed(C) % $signed(D);
        end 
            
    18: begin       //remu
        if(B == 0)
                ALUOut = A; 
        else ALUOut = A % B; 
        end 

  //atomic extension 
    19: ALUOut = ($signed(A) < $signed(B)) ? $signed(B): $signed(A);      //max function            
    20: ALUOut = ($signed(A) < $signed(B)) ? $signed(A): $signed(B);      //min function 
    21: ALUOut = (A < B) ? B: A;                                          //maxu function
    22: ALUOut = (A < B) ? A: B;                                          //minu function
    

       
    default: ALUOut = 0; //default to 0. should not happen;
    endcase
  end
endmodule
