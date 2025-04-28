// RISC V Atomic extension module RV32A 
import risc_v_core_pkg::*;

module amo_control_unit(
		input	  clk,
		input	  reset,
    input   [31:0]  instruction,
    //input   [31:0]  Instruction_reg,
    output logic lr_sc_w_inst,
    output logic is_atomic,
    output logic atomic_,
    output logic lr_w_inst_reg,
    output logic sc_w_inst_reg,
    output logic amo_stall,
    output logic [1:0] ALUSrcA,
    output logic [1:0] ALUSrcB,
    output logic [1:0] ALUOp,
    output logic MemRead,
    output logic MemWrite,
    output logic regfile_rd_addr_sel,
    output logic RegWrite,
    output logic MemtoReg,
    output logic dmem_wr_data_sel,
    output logic dmem_addr_sel,
    output logic [1:0] is_sc_reg_wr
		);
	
	//state types 
	logic   [1:0]	    state;
	logic   [1:0]	    next_state;
  logic             is_atomic_reg;
  logic             is_atomic_reg2;
  logic   [4:0]     amo_inst_for_state_3;
  logic             lr_w_inst;
  logic             sc_w_inst;
  // logic             lr_w_inst_reg;
  //logic             sc_w_inst_reg;
  logic   [31:0]    Instruction_reg; 

	//States
	parameter	idle_state	    =	2'b00;          //no output signals 
	parameter	lr_sc_state	    =	2'b01;          //for lr and sc instruction 
	parameter	amo_ins_state	  =	2'b10;          //for remaining atomic instructions
  parameter amo_ins_state_2 = 2'b11;          //cycle 2 for remaining instructions

  //decoding signals 
  assign lr_w_inst  =   (instruction[6:0] == 7'b0101111 & instruction[14:12] == 3'd2 & instruction[31:27] == 5'd2) ? 1:0;
  assign sc_w_inst  =   (instruction[6:0] == 7'b0101111 & instruction[14:12] == 3'd2 & instruction[31:27] == 5'd3) ? 1:0;
  assign is_atomic  =   ((instruction[6:0] == 7'b0101111) & (instruction[14:12] == 3'd2) & (instruction[31:27] != 5'd2) & (instruction[31:27] != 5'd3)) ? 1:0;
  assign amo_inst   =   instruction[31:27];     //funct5
  assign amo_inst_for_state_3 = Instruction_reg[31:27];   //funct5 for state3
  assign atomic_ = ((Instruction_reg[6:0] == 7'b0101111) & (Instruction_reg[14:12] == 3'd2) & (Instruction_reg[31:27] != 5'd2) & (Instruction_reg[31:27] != 5'd3)) ? 1:0;
  assign lr_sc_w_inst = lr_w_inst | sc_w_inst;
  //declarations of instructions  
  parameter amoswap =  5'd1;
  parameter amoor   =  5'd8;
  parameter amoxor  =  5'd4;
  parameter amoand  =  5'd12; 
  parameter amomax  =  5'd20;
  parameter amomini =  5'd16;
  parameter amoadd  =  5'd0;
  parameter amominu =  5'd24;
  parameter amomaxu =  5'd28;

  //registering signal s
    always_ff @(posedge clk or negedge reset) begin
      if(!reset) begin 
        lr_w_inst_reg   <= 0;
        sc_w_inst_reg   <= 0;
        Instruction_reg <= 0;
      end
      else begin  
        lr_w_inst_reg   <=  lr_w_inst;
        sc_w_inst_reg   <=  sc_w_inst;
        Instruction_reg <=  instruction;
      end
    end


	//FSM for generating atomic control signals
	//next state logic 
	always @ (*) begin 
    case (state)
    idle_state:         begin 
                        if(is_atomic)
                          next_state = amo_ins_state;          //if atomic except lr.w/sc.w comes 
                        else if(lr_w_inst | sc_w_inst)
                          next_state = lr_sc_state;            //if lr.w/sc.w instruction comes 
                        else
                          next_state = idle_state;             //if no atomic then remain idle
                        end
    amo_ins_state:      begin 
                        next_state = amo_ins_state_2;
                        end 

    amo_ins_state_2:    begin 
                        if(is_atomic)
                          next_state = amo_ins_state;        //repeat the same process if consecutive atomic inst comes
                        else if(lr_w_inst | sc_w_inst)
                          next_state = lr_sc_state;          //if lr.w/sc.w comes right after atomic inst
                        else
                          next_state = idle_state;           //remain idle if no consecutive atomic instructions
                        end 
    lr_sc_state:        begin 
                        if(is_atomic)
                          next_state = amo_ins_state;          //if atomic except lr.w/sc.w comes 
                        else if(lr_w_inst | sc_w_inst)
                          next_state = lr_sc_state;            //if lr.w/sc.w instruction comes 
                        else
                          next_state = idle_state;             //if no atomic then remain idle
                        end


    default:            begin 
                        next_state = idle_state;            //remain in idle state
                        end     
    endcase
  end

	//stage register 
		always @ (posedge clk or negedge reset) begin 
			if(!reset) begin 
				state           <= idle_state;
        is_atomic_reg   <= 0;
        is_atomic_reg2  <= 0;
      end
			else begin  
				state           <= next_state;
        is_atomic_reg   <= is_atomic;
        is_atomic_reg2  <= is_atomic_reg;
      end
		end

	//output logic 
    always @ (*)  begin 
      ALUSrcA  = 2'b00;           //select rs1 from mux 
      ALUSrcB = 2'd0;             //selects rs2 
      ALUOp    = 2'b10;           //select add for alu op
      MemRead  = 1'b0;            //data mem read enable
      RegWrite = 1'b0;            //register file write enable
      MemtoReg = 1'b0;            //select dmem_out from wb mux
      is_sc_reg_wr = 2'd0;       //select dmem_out from wb final mux
      regfile_rd_addr_sel = 1'b0; //select rd at input of regfile rd_addr 
      dmem_wr_data_sel = 1'b0;    //select rs2_forwarded to go to data mem write data 
      amo_stall = 1'b0;           //stall -- pc disable
      MemWrite = 1'b0;            //data mem write enable
      dmem_addr_sel = 0;          //alu_out should go to dmem address
      //is_atomic | is_atomic_reg | is_atomic_reg2 | lr_w_inst_reg | sc_w_inst_reg
    if(is_atomic  | atomic_ | lr_w_inst_reg | sc_w_inst_reg) begin 
      case (state)

        idle_state:       begin 
                          if(!lr_sc_w_inst)
                            amo_stall = 1;
                          else 
                            amo_stall = 0;
        end

        lr_sc_state:      begin 
                          //set the control signals according to lr/sc instructions 
                          dmem_addr_sel = 1;          //alu_out should go to dmem address
                          if(next_state == amo_ins_state)
                              amo_stall = 1;
                            else  
                              amo_stall = 0;
                          if(lr_w_inst_reg) begin
                            //control signals for lr.w 
                            ALUSrcA = 2'b00;              //selects rs1 
                            ALUSrcB = 2'd3;               //selects 0 
                            ALUOp = 2'b11;                //selects add
                            MemRead = 1'b1;               //data memory read enable
                            MemWrite  = 1'b0;             //data memory write disable
                            regfile_rd_addr_sel = 1'b0;   //selects rd at regfile input 
                            MemtoReg = 1'b1;              //select dmem_out from wb mux
                            RegWrite = 1'b1;              //register file write enable
                          end
                          else begin
                            //control signals for sc.w 
                            ALUSrcA = 2'b00;              //selects rs1 
                            ALUSrcB = 2'd3;               //selects 0 
                            ALUOp = 2'b11;                //selects add
                            MemRead = 1'b0;               //data memory read enable
                            regfile_rd_addr_sel = 1'b0;   //selects rd at regfile input 
                            RegWrite = 1'b1;              //register file write enable
                            is_sc_reg_wr = 2'd1;       //
                          end
        end

        amo_ins_state:    begin 
                          //amo_stall = 1'b1;           //stall -- pc disable
                          dmem_addr_sel = 1;          //alu_out should go to dmem address
                          case(amo_inst)
                            amoswap:      begin         
                                          ALUSrcA  = 2'b00;           //select rs1 from mux 
                                          ALUSrcB  = 2'd3;             //selects 0 
                                          ALUOp    = 2'b0;           //select add for alu op
                                          MemRead  = 1'b1;            //data mem read enable
                                          RegWrite = 1'b1;            //register file write enable
                                          MemtoReg = 1'b1;            //select dmem_out from wb mux
                                          is_sc_reg_wr = 2'd0;       //select dmem_out from wb final mux
                                          //regfile_rd_addr_sel = 1'b1; //select rs2 at input of regfile rd_addr 
                                          //dmem_wr_data_sel = 1'b1;    //select alu_result to go to data mem write data 
                                          end
                            amoadd:       begin
                                          //these control signals will generate M[rs1]
                                          ALUSrcA  = 2'b00;           //select rs1 from mux
                                          ALUSrcB = 2'd3;             //selects 0 
                                          ALUOp    = 2'b0;           //select add for alu op
                                          MemRead  = 1'b1;            //data mem read enable
                                          MemtoReg = 1'b1;            //select dmem_out from wb mux
                                          is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                          RegWrite = 1'b1;            //register file write enable
                                          end

                            amoor:       begin
                                          //these control signals will generate M[rs1]
                                          ALUSrcA  = 2'b00;           //select rs1 from mux
                                          ALUSrcB = 2'd3;             //selects 0 
                                          ALUOp    = 2'b0;           //select add for alu op
                                          MemRead  = 1'b1;            //data mem read enable
                                          MemtoReg = 1'b1;            //select dmem_out from wb mux
                                          is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                          RegWrite = 1'b1;            //register file write enable
                                          end
                            amoxor:       begin
                                          //these control signals will generate M[rs1]
                                          ALUSrcA  = 2'b00;           //select rs1 from mux
                                          ALUSrcB = 2'd3;             //selects 0 
                                          ALUOp    = 2'b0;           //select add for alu op
                                          MemRead  = 1'b1;            //data mem read enable
                                          MemtoReg = 1'b1;            //select dmem_out from wb mux
                                          is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                          RegWrite = 1'b1;            //register file write enable
                                          end
                            amoand:       begin
                                          //these control signals will generate M[rs1]
                                          ALUSrcA  = 2'b00;           //select rs1 from mux
                                          ALUSrcB = 2'd3;             //selects 0 
                                          ALUOp    = 2'b0;           //select add for alu op
                                          MemRead  = 1'b1;            //data mem read enable
                                          MemtoReg = 1'b1;            //select dmem_out from wb mux
                                          is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                          RegWrite = 1'b1;            //register file write enable
                                          end
                            amomax:       begin
                                          //these control signals will generate M[rs1]
                                          ALUSrcA  = 2'b00;           //select rs1 from mux
                                          ALUSrcB = 2'd3;             //selects 0 
                                          ALUOp    = 2'b0;           //select add for alu op
                                          MemRead  = 1'b1;            //data mem read enable
                                          MemtoReg = 1'b1;            //select dmem_out from wb mux
                                          is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                          RegWrite = 1'b1;            //register file write enable
                                          end

                            amomini:       begin
                                          //these control signals will generate M[rs1]
                                          ALUSrcA  = 2'b00;           //select rs1 from mux
                                          ALUSrcB = 2'd3;             //selects 0 
                                          ALUOp    = 2'b0;           //select add for alu op
                                          MemRead  = 1'b1;            //data mem read enable
                                          MemtoReg = 1'b1;            //select dmem_out from wb mux
                                          is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                          RegWrite = 1'b1;            //register file write enable
                                          end
                            amominu:      begin 
                                           //these control signals will generate M[rs1]
                                          ALUSrcA  = 2'b00;           //select rs1 from mux
                                          ALUSrcB = 2'd3;             //selects 0 
                                          ALUOp    = 2'b0;           //select add for alu op
                                          MemRead  = 1'b1;            //data mem read enable
                                          MemtoReg = 1'b1;            //select dmem_out from wb mux
                                          is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                          RegWrite = 1'b1;            //register file write enable
                            end
                            amomaxu:      begin 
                                          //these control signals will generate M[rs1]
                                          ALUSrcA  = 2'b00;           //select rs1 from mux
                                          ALUSrcB = 2'd3;             //selects 0 
                                          ALUOp    = 2'b0;           //select add for alu op
                                          MemRead  = 1'b1;            //data mem read enable
                                          MemtoReg = 1'b1;            //select dmem_out from wb mux
                                          is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                          RegWrite = 1'b1;            //register file write enable
                            end
                            default:      begin 
                                          ALUSrcA  = 2'b00;           //select rs1 from mux 
                                          ALUSrcB = 2'd0;             //selects rs2 
                                          ALUOp    = 2'b0;           //select add for alu op
                                          MemRead  = 1'b0;            //data mem read enable
                                          RegWrite = 1'b0;            //register file write enable
                                          MemtoReg = 1'b0;            //select dmem_out from wb mux
                                          is_sc_reg_wr = 2'd0;       //select dmem_out from wb final mux
                                          regfile_rd_addr_sel = 1'b0; //select rs2 at input of regfile rd_addr 
                                          dmem_wr_data_sel = 1'b0;    //select rs2_forw to go to data mem write data 
                                          //amo_stall = 1'b0;           //stall -- pc disable
                                          dmem_addr_sel = 0;          //alu_out should go to dmem address
                            end
                          endcase
                          end

        amo_ins_state_2:    begin 
                            dmem_addr_sel = 0;          //alu_out_registered should go to dmem address
                            if(next_state == amo_ins_state)
                              amo_stall = 1;
                            else  
                              amo_stall = 0;
                            case(amo_inst_for_state_3) 
                              amoswap:      begin
                                            ALUSrcA  = 2'd3;            //M[rs1] will go to ALU
                                            ALUSrcB = 2'd3;             //selects 0 
                                            ALUOp    = 2'b11;           //select add for alu op
                                            MemWrite = 1'b1;            //data mem write enable
                                            dmem_wr_data_sel = 1'b0;    //select alu_out to go to data mem write data 
                                            // regfile_rd_addr_sel = 1'b0; //select rd at input of regfile rd_addr
                                            // is_sc_reg_wr = 2'd3;       //select rs2_out from wb final mux
                                            // MemWrite = 1'b1;            //data mem write enable
                                            end
                              amoadd:       begin
                                            //these signals will forward M[rs1] to alu and then find M[rs1] + rs2
                                            ALUSrcA  = 2'd3;            //M[rs1] will go to ALU
                                            ALUSrcB  = 2'b00;           //rs2 come to ALU
                                            ALUOp    = 2'b11;           //select add for alu op
                                            MemWrite = 1'b1;            //data mem write enable
                                            dmem_wr_data_sel = 1'b1;    //select alu_out to go to data mem write data 
                                            // is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                            // MemtoReg  = 1'b0;           //sel alu_out from wb mux
                                            // RegWrite = 1'b1;            //register file write enable
                                            end
                              amoand:       begin
                                            //these signals will forward M[rs1] to alu and then find M[rs1] + rs2
                                            ALUSrcA  = 2'd3;            //M[rs1] will go to ALU
                                            ALUSrcB  = 2'b00;           //rs2 come to ALU
                                            ALUOp    = 2'b11;           //select add for alu op
                                            MemWrite = 1'b1;            //data mem write enable
                                            dmem_wr_data_sel = 1'b1;    //select alu_out to go to data mem write data 
                                            // is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                            // MemtoReg  = 1'b0;           //sel alu_out from wb mux
                                            // RegWrite = 1'b1;            //register file write enable
                                            end
                              amoor:       begin
                                            //these signals will forward M[rs1] to alu and then find M[rs1] + rs2
                                            ALUSrcA  = 2'd3;            //M[rs1] will go to ALU
                                            ALUSrcB  = 2'b00;           //rs2 come to ALU
                                            ALUOp    = 2'b11;           //select add for alu op
                                            MemWrite = 1'b1;            //data mem write enable
                                            dmem_wr_data_sel = 1'b1;    //select alu_out to go to data mem write data 
                                            // is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                            // MemtoReg  = 1'b0;           //sel alu_out from wb mux
                                            // RegWrite = 1'b1;            //register file write enable
                                            end
                              amoxor:       begin
                                            //these signals will forward M[rs1] to alu and then find M[rs1] + rs2
                                            ALUSrcA  = 2'd3;            //M[rs1] will go to ALU
                                            ALUSrcB  = 2'b00;           //rs2 come to ALU
                                            ALUOp    = 2'b11;           //select add for alu op
                                            MemWrite = 1'b1;            //data mem write enable
                                            dmem_wr_data_sel = 1'b1;    //select alu_out to go to data mem write data 
                                            // is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                            // MemtoReg  = 1'b0;           //sel alu_out from wb mux
                                            // RegWrite = 1'b1;            //register file write enable
                                            end

                              amomax:       begin
                                            //these signals will forward M[rs1] to alu and then find M[rs1] + rs2
                                            ALUSrcA  = 2'd3;            //M[rs1] will go to ALU
                                            ALUSrcB  = 2'b00;           //rs2 come to ALU
                                            ALUOp    = 2'b11;           //select add for alu op
                                            MemWrite = 1'b1;            //data mem write enable
                                            dmem_wr_data_sel = 1'b1;    //select alu_out to go to data mem write data 
                                            // is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                            // MemtoReg  = 1'b0;           //sel alu_out from wb mux
                                            // RegWrite = 1'b1;            //register file write enable
                                            end
                              amomini:       begin
                                            //these signals will forward M[rs1] to alu and then find M[rs1] + rs2
                                            ALUSrcA  = 2'd3;            //M[rs1] will go to ALU
                                            ALUSrcB  = 2'b00;           //rs2 come to ALU
                                            ALUOp    = 2'b11;           //select add for alu op
                                            MemWrite = 1'b1;            //data mem write enable
                                            dmem_wr_data_sel = 1'b1;    //select alu_out to go to data mem write data 
                                            // is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                            // MemtoReg  = 1'b0;           //sel alu_out from wb mux
                                            // RegWrite = 1'b1;            //register file write enable
                                            end
                              amominu:      begin 
                                            //these signals will forward M[rs1] to alu and then find M[rs1] + rs2
                                            ALUSrcA  = 2'd3;            //M[rs1] will go to ALU
                                            ALUSrcB  = 2'b00;           //rs2 come to ALU
                                            ALUOp    = 2'b11;           //select add for alu op
                                            MemWrite = 1'b1;            //data mem write enable
                                            dmem_wr_data_sel = 1'b1;    //select alu_out to go to data mem write data 
                                            // is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                            // MemtoReg  = 1'b1;           //sel alu_out from wb mux
                                            // RegWrite = 1'b1;            //register file write enable
                              end
                              amomaxu:      begin 
                                            //these signals will forward M[rs1] to alu and then find M[rs1] + rs2
                                            ALUSrcA  = 2'd3;            //M[rs1] will go to ALU
                                            ALUSrcB  = 2'b00;           //rs2 come to ALU
                                            ALUOp    = 2'b11;           //select add for alu op
                                            MemWrite = 1'b1;            //data mem write enable
                                            dmem_wr_data_sel = 1'b1;    //select alu_out to go to data mem write data 
                                            // is_sc_reg_wr = 2'd0;       //sel alu_out from wb final mux 
                                            // MemtoReg  = 1'b0;           //sel alu_out from wb mux
                                            // RegWrite = 1'b1;            //register file write enable
                              end
                              default:      begin 
                                            ALUSrcA  = 2'b00;           //select rs1 from mux 
                                            ALUSrcB = 2'd0;             //selects rs2 
                                            ALUOp    = 2'b10;           //select add for alu op
                                            MemRead  = 1'b0;            //data mem read enable
                                            RegWrite = 1'b0;            //register file write enable
                                            MemtoReg = 1'b0;            //select dmem_out from wb mux
                                            is_sc_reg_wr = 2'd0;       //select dmem_out from wb final mux
                                            regfile_rd_addr_sel = 1'b0; //select rs2 at input of regfile rd_addr 
                                            dmem_wr_data_sel = 1'b0;    //select alu_result to go to data mem write data 
                                            amo_stall = 1'b0;           //stall -- pc disable
                                            MemWrite = 1'b0;            //data mem write enable
                              end
                            endcase
                            end 

        default:    begin 
                    //default values of the control signals 
                    ALUSrcA  = 2'b00;           //select rs1 from mux 
                    ALUSrcB = 2'd0;             //selects rs2 
                    ALUOp    = 2'b10;           //select add for alu op
                    MemRead  = 1'b0;            //data mem read enable
                    RegWrite = 1'b0;            //register file write enable
                    MemtoReg = 1'b0;            //select dmem_out from wb mux
                    is_sc_reg_wr = 2'd0;       //select dmem_out from wb final mux
                    regfile_rd_addr_sel = 1'b0; //select rd at input of regfile rd_addr 
                    dmem_wr_data_sel = 1'b0;    //select alu_result to go to data mem write data 
                    amo_stall = 1'b0;           //stall -- pc disable
                    MemWrite = 1'b0;            //data mem write enable
                    dmem_addr_sel = 0;          //alu_out should go to dmem address
        end 
      endcase
    end
    end
endmodule 