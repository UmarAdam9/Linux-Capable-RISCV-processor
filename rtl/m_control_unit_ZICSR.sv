

module m_control_unit_ZICSR(
  input       [6:0] Op,
  input       [2:0] funct3,
  input       [6:0] funct7,
  input 	  [4:0] funct5,
  input 	  [1:0] priv_mode,
  output reg  [1:0] ALUOp, 
  output reg  [1:0] ALUSrcA, 
  output reg  [1:0] ALUSrcB,
  output reg  [5:0] Branch,
  output reg        RegWrite, 
  output reg  [1:0] MemtoReg, 
  output reg        MemRead, 
  output reg        MemWrite, 
  output reg        jal,
  output reg        jalr, 
  output reg        valid,
  output logic      dmem_addr_sel,               //select between alu_out and alu_out_reg
  
  input 	   			exc_req_if2id,				/**Umar Adam : extra signals for zicsr extension**/
  input					exc_code_if_id,
  
  output reg [1:0]	csr_ops,
  output reg [2:0] 	sys_ops,
  
  output reg		 	exc_req,
  output reg [3:0]	exc_code
 
);
   
  //Declaring Parameters
    parameter R_type  = 7'b0110011, I_type = 7'b0010011, Load_type = 7'b0000011;
    parameter St_type = 7'b0100011, B_type = 7'b1100011, J_type    = 7'b1101111;
    parameter lui_type = 7'b0110111, auipc = 7'b0010111, JALR_Type = 7'b1100111;
    parameter Noop = 7'b0000000;
	
	//=========Umar Adam: zicsr extension parameters============
	
	parameter system = 7'b1110011; 
	
	parameter csr_ops_none  = 2'b00;
	parameter csr_ops_write = 2'b01;
	parameter csr_ops_set	= 2'b10;
	parameter csr_ops_clear = 2'b11;
	
	parameter SYS_OPS_NONE = 3'b000;
	parameter SYS_OPS_SRET = 3'b001;
	parameter SYS_OPS_WFI =  3'b010;
	parameter SYS_OPS_MRET = 3'b011;
	parameter SYS_OPS_SFENCE_VMA = 3'b100;
	
	
	parameter  EXC_CODE_ECALL_UMODE = 4'd8;     // Ecall from user mode
   parameter  EXC_CODE_ECALL_SMODE = 4'd9;     // Ecall from supervisor mode
   parameter  EXC_CODE_ECALL_MMODE = 4'd11;    // Ecall from machine mode
	parameter  EXC_CODE_BREAKPOINT  = 4'd3;     // Exception from decode module 

	
	parameter  EXC_CODE_ILLEGAL_INSTR = 4'd2;     // Exception from CSR or decode module 
	
	
	
	parameter PRIV_MODE_M = 2'b11;
   parameter PRIV_MODE_S = 2'b01;
   parameter PRIV_MODE_U = 2'b00;


	
	
	logic illegal_instr;	//Umar Adam: local signals for exception generation
	
//=======================================================
//  Structural coding
//=======================================================
                               
  always@(*)
  begin
    valid   = 1'b1;
    ALUSrcA = 2'b00;
    ALUSrcB = 2'b00;
    MemtoReg= 2'b00;
    RegWrite= 1'b0;
    MemRead = 1'b0;
    MemWrite= 1'b0;
    Branch  = 6'b000000;
    ALUOp   = 2'b00;
    jal     = 1'b0;
    jalr    = 1'b0;
    dmem_addr_sel = 1'b1;           //alu_out should go to dmem_addr
	
	/**Umar Adam : initializing  the zicsr extension control signals **/
	csr_ops = 2'b00;
	sys_ops = '0;
	exc_req =  0;
	exc_code ='0;
	
	illegal_instr=0;//UA : local signal initialization
	
    case(Op)
      R_type : begin
        ALUSrcA  = 2'b00;
        ALUSrcB  = 2'b00;
        MemtoReg = 2'b00;
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
        MemtoReg = 2'b00;
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
        MemtoReg = 2'b01;
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
        MemtoReg = 2'b00;
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
        MemtoReg  = 2'b00;
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
        MemtoReg  = 2'b00;
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
        MemtoReg  = 2'b00;
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
        MemtoReg  = 2'b00;
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
            MemtoReg  = 2'b00;
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
            MemtoReg  = 2'b00;
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
            MemtoReg  = 2'b00;
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
            MemtoReg  = 2'b00;
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
            MemtoReg  = 2'b00;
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
            MemtoReg  = 2'b00;
            RegWrite  = 1'b0;
            MemRead   = 1'b0;
            MemWrite  = 1'b0;
            Branch    = 6'b100000;
            ALUOp     = 2'b01;
            jal       = 1'b0;
            jalr      = 1'b0;
          end
			 default:begin 
			 end
        endcase
      end

      Noop : begin
        ALUSrcA   = 2'b00;
        ALUSrcB   = 2'b00;
        MemtoReg  = 2'b00;
        RegWrite  = 1'b0;
        MemRead   = 1'b0;
        MemWrite  = 1'b0;
        Branch    = 6'b000000;
        ALUOp     = 2'b00;
        jal       = 1'b0;
        jalr      = 1'b0;
      end
	  
	  
	  system: begin    //Umar Adam: zicsr extension 
	  
		
		case(funct3)
			3'b001 : begin              // CSRRW
				ALUSrcA   = 2'b00; //reg1
				ALUSrcB   = 2'b11; //zero
				RegWrite  = 1'b1;
				ALUOp     = 2'b00;
				csr_ops	  = csr_ops_write;   
				MemtoReg  = 2'b10; //select csr output at the WB mux 				
            end
			3'b010 : begin              // CSRRS
				ALUSrcA   = 2'b00; //reg1
				ALUSrcB   = 2'b11; //zero 
				RegWrite  = 1'b1;
				ALUOp     = 2'b00;
				csr_ops	  = csr_ops_set;   
				MemtoReg  = 2'b10; //select csr output at the WB mux (to be extended)
                       
			end
			3'b011 : begin             // CSRRC
				ALUSrcA   = 2'b00; //reg1
				ALUSrcB   = 2'b11; //zero 
				RegWrite  = 1'b1;
				ALUOp     = 2'b00;
				csr_ops	  = csr_ops_clear;   
				MemtoReg  = 2'b10; //select csr output at the WB mux (to be extended)
                        
			end
			3'b101 : begin             // CSRIW
				ALUSrcA   = 2'b10; //zero
				ALUSrcB   = 2'b01; //immediate
				RegWrite  = 1'b1;
				ALUOp     = 2'b00;
				csr_ops	  = csr_ops_write;   
				MemtoReg  = 2'b10; //select csr output at the WB mux (to be extended)
                        
			end
			3'b110 : begin             // CSRIS
				ALUSrcA   = 2'b10; //zero
				ALUSrcB   = 2'b01; //immediate
				RegWrite  = 1'b1;
				ALUOp     = 2'b00;
				csr_ops	  = csr_ops_set;   
				MemtoReg  = 2'b10; //select csr output at the WB mux (to be extended)
                        
			end
			3'b111 : begin             // CSRIC
				ALUSrcA   = 2'b10; //zero
				ALUSrcB   = 2'b01; //immediate
				RegWrite  = 1'b1;
				ALUOp     = 2'b00;
				csr_ops	  = csr_ops_clear;   
				MemtoReg  = 2'b10; //select csr output at the WB mux (to be extended)
                       
			end	
			3'b000 : begin
			
				case(funct7)
					7'b0000000: begin
						case(funct5)
							5'b00000 : begin  // ECALL  
								exc_req  = 1'b1;
                                exc_code = EXC_CODE_ECALL_MMODE;
								 case (priv_mode)
												PRIV_MODE_M: exc_code = EXC_CODE_ECALL_MMODE;
                                    PRIV_MODE_S: exc_code = EXC_CODE_ECALL_SMODE;
                                    PRIV_MODE_U: exc_code = EXC_CODE_ECALL_UMODE;
												default: 	;//shouldnt happen											  
                                  endcase
							
							end
							
							5'b00001 : begin  // EBREAK
                                exc_req  = 1'b1;
                                exc_code = EXC_CODE_BREAKPOINT;
                            end
							
                            default : illegal_instr  =  1'b1;
							
						endcase
						

					end
					7'b0001000: begin
						case (funct5)
						
                            5'b00010 : begin  // SRET                     
                                sys_ops    = SYS_OPS_SRET;
                            end
							
                            5'b00101 : begin  // WFI
                                sys_ops    = SYS_OPS_WFI;  
                            end
							
                            default : illegal_instr  =  1'b1; 
							
                        endcase // funct5_opcode     

					end
					7'b0011000: begin
						sys_ops    = SYS_OPS_MRET;  //MRET
					end
					7'b0001001: begin
						sys_ops    = SYS_OPS_SFENCE_VMA; //SFENCE_VMA
					end
					default: illegal_instr = 1'b1;
				endcase //funct 7
			
			end
			
			default: illegal_instr = 1'b1;
		endcase //func3
	
	  end //system end

      default : begin
        ALUSrcA = 2'b00; MemtoReg = 1'b0; MemRead = 1'b0; Branch = 6'b000000;
        ALUSrcB = 2'b00; RegWrite = 1'b0; MemWrite= 1'b0; ALUOp  = 2'b00;
        jal = 1'b0;      jalr = 1'b0;     valid = 1'b1; dmem_addr_sel = 1'b1;
      end
      endcase
	  
	  // Handle the illegal instruction
	   if(illegal_instr | exc_req_if2id)  begin
		
		//set all the control signals of Noop
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
		
		//set the output exception req signal
		exc_req     = 1'b1;
		 
		 
		 if (exc_req_if2id) begin 	//if exception occured in the fetch stage then propogate that exception
			 exc_code = exc_code_if_id; 
		 end else begin
			 exc_code    = EXC_CODE_ILLEGAL_INSTR;
		 end
	   end
	  
	  
	  
	  
	  
  end
  
  
  
  
  
  
endmodule
