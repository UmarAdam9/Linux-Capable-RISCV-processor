

module control_unit(
  input       [6:0] Op,
  input       [2:0] funct3,
  input       [6:0] funct7,
  output reg  [1:0] ALUOp, 
  output reg  [1:0] ALUSrcA, 
  output reg  [1:0] ALUSrcB,
  output reg  [5:0] Branch,
  output reg        RegWrite, 
  output reg        MemtoReg, 
  output reg        MemRead, 
  output reg        MemWrite, 
  output reg        jal,
  output reg        jalr, 
  output reg        valid,
  output reg        dmem_addr_sel               //select between alu_out and alu_out_reg
);
   
  //Declaring Parameters
    parameter R_type  = 7'b0110011, I_type = 7'b0010011, Load_type = 7'b0000011;
    parameter St_type = 7'b0100011, B_type = 7'b1100011, J_type    = 7'b1101111;
    parameter lui_type = 7'b0110111, auipc = 7'b0010111, JALR_Type = 7'b1100111;
    parameter Noop = 7'b0000000;

//=======================================================
//  Structural coding
//=======================================================
                               
  always@(*)
  begin
    valid   = 1'b1;
    ALUSrcA = 2'b00;
    ALUSrcB = 2'b00;
    MemtoReg= 1'b0;
    RegWrite= 1'b0;
    MemRead = 1'b0;
    MemWrite= 1'b0;
    Branch  = 6'b000000;
    ALUOp   = 2'b00;
    jal     = 1'b0;
    jalr    = 1'b0;
    dmem_addr_sel = 1'b1;           //alu_out should go to dmem_addr
    case(Op)
      R_type : begin
        ALUSrcA  = 2'b00;
        ALUSrcB  = 2'b00;
        MemtoReg = 1'b0;
        RegWrite = 1'b1;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        Branch   = 6'b000000;
        ALUOp    = 2'b10;
        jal      = 1'b0;
        jalr     = 1'b0;
      end
              
      I_type : begin
        ALUSrcA  = 2'b00;
        ALUSrcB  = 2'b01;
        MemtoReg = 1'b0;
        RegWrite = 1'b1;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        Branch   = 6'b000000;
        ALUOp    = 2'b10;
        jal      = 1'b0;
        jalr     = 1'b0;
      end

      Load_type : begin
        ALUSrcA  = 2'b00;
        ALUSrcB  = 2'b01;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        MemRead  = 1'b1;
        MemWrite = 1'b0;
        Branch   = 6'b000000;
        ALUOp    = 2'b00;
        jal      = 1'b0;
        jalr     = 1'b0;
      end

      St_type : begin
        ALUSrcA  = 2'b00;
        ALUSrcB  = 2'b01; 
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b1;
        Branch   = 6'b000000;
        ALUOp    = 2'b00;
        jal      = 1'b0;
        jalr     = 1'b0;
      end         

      J_type : begin
        ALUSrcA   = 2'b01;
        ALUSrcB   = 2'b10;
        MemtoReg  = 1'b0;
        RegWrite  = 1'b1;
        MemRead   = 1'b0;
        MemWrite  = 1'b0;
        Branch    = 6'b000000;
        ALUOp     = 2'b00;
        jal       = 1'b1;
        jalr      = 1'b0;
      end

      JALR_Type : begin
        ALUSrcA   = 2'b01;
        ALUSrcB   = 2'b10;
        MemtoReg  = 1'b0;
        RegWrite  = 1'b1;
        MemRead   = 1'b0;
        MemWrite  = 1'b0;
        Branch    = 6'b000000;
        ALUOp     = 2'b00;
        jal       = 1'b0;
        jalr      = 1'b1;
      end

      lui_type : begin
        ALUSrcA   = 2'b10;
        ALUSrcB   = 2'b01;
        MemtoReg  = 1'b0;
        RegWrite  = 1'b1;
        MemRead   = 1'b0;
        MemWrite  = 1'b0;
        Branch    = 6'b000000;
        ALUOp     = 2'b00;
        jal       = 1'b0;
        jalr      = 1'b0;
      end

      auipc : begin
        ALUSrcA   = 2'b01;
        ALUSrcB   = 2'b01;
        MemtoReg  = 1'b0;
        RegWrite  = 1'b1;
        MemRead   = 1'b0;
        MemWrite  = 1'b0;
        Branch    = 6'b000000;
        ALUOp     = 2'b00;
        jal       = 1'b0;
        jalr      = 1'b0;
      end

      B_type : begin
              dmem_addr_sel = 1'b1;
        case(funct3)
          3'd0 : begin
            ALUSrcA   = 2'b00;
            ALUSrcB   = 2'b00;
            MemtoReg  = 1'b0;
            RegWrite  = 1'b0;
            MemRead   = 1'b0;
            MemWrite  = 1'b0;
            Branch    = 6'b000001;
            ALUOp     = 2'b01;
            jal       = 1'b0;
            jalr      = 1'b0;
          end

          3'd1 : begin
            ALUSrcA   = 2'b00;
            ALUSrcB   = 2'b00;
            MemtoReg  = 1'b0;
            RegWrite  = 1'b0;
            MemRead   = 1'b0;
            MemWrite  = 1'b0;
            Branch    = 6'b000010;
            ALUOp     = 2'b01;
            jal       = 1'b0;
            jalr      = 1'b0;
          end

          3'd4 : begin
            ALUSrcA   = 2'b00;
            ALUSrcB   = 2'b00;
            MemtoReg  = 1'b0;
            RegWrite  = 1'b0;
            MemRead   = 1'b0;
            MemWrite  = 1'b0;
            Branch    = 6'b000100;
            ALUOp     = 2'b01;
            jal       = 1'b0;
            jalr      = 1'b0;
          end

          3'd5 : begin
            ALUSrcA   = 2'b00;
            ALUSrcB   = 2'b00;
            MemtoReg  = 1'b0;
            RegWrite  = 1'b0;
            MemRead   = 1'b0;
            MemWrite  = 1'b0;
            Branch    = 6'b001000;
            ALUOp     = 2'b01;
            jal       = 1'b0;
            jalr      = 1'b0;
          end

          3'd6 : begin
            ALUSrcA   = 2'b00;
            ALUSrcB   = 2'b00;
            MemtoReg  = 1'b0;
            RegWrite  = 1'b0;
            MemRead   = 1'b0;
            MemWrite  = 1'b0;
            Branch    = 6'b010000;
            ALUOp     = 2'b01;
            jal       = 1'b0;
            jalr      = 1'b0;
          end

          3'd7 : begin
            ALUSrcA   = 2'b00;
            ALUSrcB   = 2'b00;
            MemtoReg  = 1'b0;
            RegWrite  = 1'b0;
            MemRead   = 1'b0;
            MemWrite  = 1'b0;
            Branch    = 6'b100000;
            ALUOp     = 2'b01;
            jal       = 1'b0;
            jalr      = 1'b0;
          end
        endcase
      end

      Noop : begin
        ALUSrcA   = 2'b00;
        ALUSrcB   = 2'b00;
        MemtoReg  = 1'b0;
        RegWrite  = 1'b0;
        MemRead   = 1'b0;
        MemWrite  = 1'b0;
        Branch    = 6'b000000;
        ALUOp     = 2'b00;
        jal       = 1'b0;
        jalr      = 1'b0;
      end

      default : begin
        ALUSrcA = 2'b00; MemtoReg = 1'b0; MemRead = 1'b0; Branch = 6'b000000;
        ALUSrcB = 2'b00; RegWrite = 1'b0; MemWrite= 1'b0; ALUOp  = 2'b00;
        jal = 1'b0;      jalr = 1'b0;     valid = 1'b1; dmem_addr_sel = 1'b1;
      end
      endcase
  end
  
endmodule
