

module ALUControl(
  input       [1:0] ALUOp,
  input       [2:0] funct3,
  input       [6:0] funct7,
  input       [4:0] funct5,
  input       [6:0] OP,
  output reg  [4:0] ALUCtl
);

//=======================================================
//  Structural coding
//=======================================================

  always@(*)
  begin
  ALUCtl = 5'b00000; 
  case(ALUOp)
  2'b00 : ALUCtl = 5'b00010;   //add
  2'b01 : ALUCtl = 5'b00110;   //sub
  2'b10 : if (OP == 7'b0010011)
          begin
          case(funct3)
          3'b000 : ALUCtl = 5'b00010;   //addi
          3'b010 : ALUCtl = 5'b01000;   //slti
          3'b011 : ALUCtl = 5'b00111;   //sltiu
          3'b100 : ALUCtl = 5'b01001;   //xori
          3'b110 : ALUCtl = 5'b00001;   //ori
          3'b111 : ALUCtl = 5'b00000;   //andi
          3'b001 : ALUCtl = 5'b00011;   //slli
          3'b101 : case(funct7)
                   7'b0000000 : ALUCtl = 5'b00100;   //srli
                   7'b0100000 : ALUCtl = 5'b00101;   //srai
                   default    : ALUCtl = 5'b00000;
                   endcase
          default : ALUCtl = 5'b00000;  
          endcase
          end
				
          else 
          begin
          case(funct7)
          7'b0000000 : case(funct3)
                       3'b000 : ALUCtl = 5'b00010;   //add
                       3'b001 : ALUCtl = 5'b00011;   //sll
                       3'b010 : ALUCtl = 5'b01000;   //slt
                       3'b011 : ALUCtl = 5'b00111;   //sltu
                       3'b100 : ALUCtl = 5'b01001;   //xor
                       3'b101 : ALUCtl = 5'b00100;   //srl
                       3'b110 : ALUCtl = 5'b00001;   //or
                       3'b111 : ALUCtl = 5'b00000;   //and
                       default : ALUCtl = 5'b00000;  
                       endcase
          7'b0100000 : case(funct3)
                       3'b000 : ALUCtl = 5'b00110;   //sub
                       3'b101 : ALUCtl = 5'b00101;   //sra
                       default : ALUCtl = 5'b00000;
                       endcase
          7'b0000001 : case(funct3)
                       3'b000 : ALUCtl = 5'd11;      //mul
                       3'b001 : ALUCtl = 5'd12;      //mulh
                       3'b010 : ALUCtl = 5'd13;      //mulsu
                       3'b011 : ALUCtl = 5'd14;      //mulu
                       3'b100 : ALUCtl = 5'd15;      //div
                       3'b101 : ALUCtl = 5'd16;      //divu
                       3'b110 : ALUCtl = 5'd17;      //rem
                       3'b111 : ALUCtl = 5'd18;      //remu
                       default : ALUCtl = 5'b00000;  
                       endcase
          default    : ALUCtl = 5'b00000; 
          endcase
          end
  2'b11 : begin
          //this will generate ALU control signals for atomic instructions 
          case(funct5)
            5'h00, 5'h01, 5'h03, 5'h02:     ALUCtl = 5'b00010;   //add    
            5'h0c:                          ALUCtl = 5'b00000;   //and
            5'h08:                          ALUCtl = 5'b00001;    //or
            5'h04:                          ALUCtl = 5'b01001;    //xor
            5'h14:                          ALUCtl = 5'd19;       //max
            5'h10:                          ALUCtl = 5'd20;       //min
            5'd28:                          ALUCtl = 5'd21;       //maxu
            5'd24:                          ALUCtl = 5'd22;       //minu
            default:                        ALUCtl = 5'b00010;
          endcase

  end
  default : ALUCtl = 5'b00000; 
  endcase				
  end 

endmodule
