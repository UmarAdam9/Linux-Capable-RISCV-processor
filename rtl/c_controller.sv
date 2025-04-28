

module c_controller //import risc_v_core_pkg::*;
(
  input             clk,
  input             reset, 
  input      [31:0] instruction_in,
  input      [31:0] PC_jump_addr, 
  input             PCSrc, 
  input             PCWrite,
 // input  logic      is_atomic,
  input  logic      atomic_,
  input  logic      amo_stall,
  output reg [31:0] instruction_out,
  output reg        pc_disable,
  output reg        compressed,
  output fsm_state  comp_state
);


//=======================================================
//  REG/WIRE declarations
//=======================================================

  reg  [15:0] inst_comp;
  wire [1 :0]  op, op1;
  wire [2 :0] funct3;
  reg  [31:0] instruction_reg;
  wire [2 :0] r_d;
  wire [4 :0] rd;
  wire [9 :0] nzuimm;
  wire [4 :0] x1;
  wire [4 :0] x2;
  wire [2 :0] r_s1;
  wire [4 :0] rs1;
  wire [6 :0] load_imm;
  wire [6 :0] store_imm;
  wire [5 :0] addi_imm;
  wire [4 :0] rs1_ci;
  wire [4 :0] rd_ci;
  wire [11:0] jal_imm;
  wire [9 :0] addi16sp_imm;
  wire [2 :0] r_s2;
  wire [4 :0] rs2;
  wire [8 :0] branch_imm;
  wire [7 :0] lwsp_imm;
  wire [4 :0] rs2_cr;
  wire [7 :0] swsp_imm;
  fsm_state   p_state;
  fsm_state   n_state;
  reg  [1 :0] register; 
  wire [31:0] nop;
  reg  [31:0] PC_jump_addr_reg;
  wire [31:0] jump_addr;
  reg         PCSrc_reg;
  logic       ato_stall;
  logic       ato_stall_reg;
  // logic       is_atomic;
  // logic [31:0]  instruction_out_reg;
  // logic [31:0]  instruction_out;
  // logic         is_atomic_reg;
 // logic  [31:0] inst_out_reg;
 // logic  [31:0] instruction_out;

//=======================================================
//  Structural coding
//=======================================================
  
  assign op1           = instruction_in[1:0];
  assign op            = inst_comp[1:0];
  assign funct3        = inst_comp[15:13];
  assign r_d           = inst_comp[4:2];
  assign rd            = r_d + 8;
  assign nzuimm        = {inst_comp[10:7],inst_comp[12:11],inst_comp[5],inst_comp[6],2'b0};
  assign x2            = 5'd2;
  assign x1            = 5'd1;
  assign r_s1          = inst_comp[9:7];
  assign rs1           = r_s1 + 8;
  assign r_s2          = inst_comp[4:2];
  assign rs2           = r_s2 + 8;
  assign load_imm      = {inst_comp[5],inst_comp[12:10],inst_comp[6],2'b0};
  assign store_imm     = {inst_comp[5],inst_comp[12:10],inst_comp[6],2'b0};
  assign addi_imm      = {inst_comp[12],inst_comp[6:2]};
  assign rs1_ci        = inst_comp[11:7];
  assign rd_ci         = inst_comp[11:7];
  assign jal_imm       = {inst_comp[12],inst_comp[8],inst_comp[10:9],inst_comp[6],inst_comp[7],inst_comp[2],inst_comp[11],inst_comp[5:3],1'b0};
  assign addi16sp_imm  = {inst_comp[12],inst_comp[4:3],inst_comp[5],inst_comp[2],inst_comp[6],4'b0};
  assign branch_imm    = {inst_comp[12],inst_comp[6:5],inst_comp[2],inst_comp[11:10],inst_comp[4:3],1'b0};
  assign lwsp_imm      = {inst_comp[3:2],inst_comp[12],inst_comp[6:4],2'b0};
  assign rs2_cr        = inst_comp[6:2];
  assign swsp_imm      = {inst_comp[8:7],inst_comp[12:9],2'b0};
  
	
  assign comp_state    = p_state; 
  assign nop           = {instruction_in[15:0],instruction_reg[31:16]};
  assign jump_addr     = {PC_jump_addr_reg[31:1],1'b0};
  
/////////////////////////////////////////////////////////////////////////////
//////  ATOMIC CASE ONLY ////////////
/////////////////////////////////////
// assign is_atomic = ((instruction_out[6:0] == 7'b0101111) & (instruction_out[14:12] == 3'd2) & (instruction_out[31:27] != 5'd2) & (instruction_out[31:27] != 5'd3)) ? 1:0;
//   always_comb begin
//     if(is_atomic_reg)
//       instruction_out_final = instruction_out_reg;
//     else  
//       instruction_out_final = instruction_out;
//   end
///////////////////////////////////////////////////////////////
//////// ATOMIC CASE END /////////////////////////
////////////////////////////////////////////////////

  always@(posedge clk or negedge reset)
  begin
      if(!reset)
          instruction_reg <= 32'b0;
      else if(!pc_disable & PCWrite & !amo_stall)
          instruction_reg <= instruction_in;
  end


  always@(posedge clk or negedge reset)
  begin
      if(!reset)begin
          PCSrc_reg         <= 1'b0;
          PC_jump_addr_reg  <= 32'd0;
          // instruction_out_reg <= 0;
          // is_atomic_reg   <= 0;
      end
      else begin 
          PCSrc_reg         <=  PCSrc; 
          PC_jump_addr_reg  <= PC_jump_addr;
          // instruction_out_reg <= instruction_out;
          // is_atomic_reg <= is_atomic;
      end
  end

//=======================================================
//    Compression Decoder
//=======================================================
  always@(*)
  begin
    if(!compressed) begin
        if(register==2'd0)
              instruction_out = instruction_in;
        else if(register==2'd1)
              instruction_out = {instruction_in[15:0],instruction_reg[31:16]};
        else if(register==2'd2)
              instruction_out = instruction_reg;
        else if(register==2'd3)
              instruction_out = 32'd0;
    end
    else if (compressed)
        begin
        case(op)
        2'b00  : case(funct3)
                  //c.addi14spn
                  3'b000     : instruction_out = {2'b0, nzuimm, x2, 3'b0, rd, 7'b0010011};
                  //c.lw
                  3'b010     : instruction_out = {5'b0, load_imm, rs1, 3'b010, rd, 7'b0000011};
                  //c.sw
                  3'b110     : instruction_out = {5'b0, store_imm[6:5], rs2, rs1, 3'b010, store_imm[4:0], 7'b0100011}; 
                  default    : instruction_out = 32'bx;
        endcase
        2'b01  : case(funct3)
                  3'b000     :  if(inst_comp[11:7]==5'b0)
                                      instruction_out = 32'b0;  //NOP
                                else  instruction_out = {{6{addi_imm[5]}}, addi_imm, rd_ci, 3'b000, rd_ci, 7'b0010011};  //ADDI  rd==rs1
                  
                  //c.jal
                  3'b001     :  instruction_out = { jal_imm[11], jal_imm[10:1], jal_imm[11], {8{jal_imm[11]}}, x1, 7'b1101111}; 
                  
                  //c.li
                  3'b010     :  instruction_out = {{6{addi_imm[5]}}, addi_imm, 5'b0, 3'b000, rd_ci, 7'b0010011}; //rs1== 0
                  
                  3'b011     :  if(inst_comp[11:7]==5'd2)
                                      instruction_out = {{2{addi16sp_imm[9]}}, addi16sp_imm, x2, 3'b000, x2, 7'b0010011};  //ADDI16sp
                                else  instruction_out = {{14{addi_imm[5]}}, addi_imm, rd_ci, 7'b0110111};  					       //LUI  
                 
                  3'b100     :  if(inst_comp[11:10]==2'b00)
                                      instruction_out = {7'b0, addi_imm[4:0], rs1, 3'b101, rs1, 7'b0010011};  			 //SRLI
                                else if(inst_comp[11:10]==2'b01)
                                       instruction_out = {7'b0100000, addi_imm[4:0], rs1, 3'b101, rs1, 7'b0010011};  //SRAI
                                else if(inst_comp[11:10]==2'b10)
                                       instruction_out = {{6{addi_imm[5]}}, addi_imm, rs1, 3'b111, rs1, 7'b0010011}; //ANDI
                                else if(inst_comp[11:10]==2'b11) begin
                                          if(inst_comp[12]==1'b0 && inst_comp[6:5]==2'b00)
                                              instruction_out = {7'b0100000, rs2, rs1, 3'b000, rs1, 7'b0110011}; 		 //SUB
                                          else if(inst_comp[12]==1'b0 && inst_comp[6:5]==2'b01)
                                              instruction_out = {7'b0000000, rs2, rs1, 3'b100, rs1, 7'b0110011};     //XOR
                                          else if(inst_comp[12]==1'b0 && inst_comp[6:5]==2'b10)
                                              instruction_out = {7'b0000000, rs2, rs1, 3'b110, rs1, 7'b0110011};     //OR
                                          else if(inst_comp[12]==1'b0 && inst_comp[6:5]==2'b11)
                                              instruction_out = {7'b0000000, rs2, rs1, 3'b111, rs1, 7'b0110011};     //AND
                                end
                  //c.j
                  3'b101     :   instruction_out = { jal_imm[11], jal_imm[10:1], jal_imm[11], {8{jal_imm[11]}}, 5'b0, 7'b1101111}; 
                  //c.beqz
                  3'b110     :   instruction_out = {{3{branch_imm[8]}}, branch_imm[8:5], 5'b0, rs1, 3'b000, branch_imm[4:1], branch_imm[8], 7'b1100011}; 
                  //c.bnez
                  3'b111     :   instruction_out = {{3{branch_imm[8]}}, branch_imm[8:5], 5'b0, rs1, 3'b001, branch_imm[4:1], branch_imm[8], 7'b1100011}; 
                  
                  default    :   instruction_out = 32'bx;
        endcase

        2'b10  : case(funct3)
                  //c.slli
                  3'b000     :  instruction_out = {7'b0, addi_imm[4:0], rd_ci, 3'b001, rd_ci, 7'b0010011};
                  //c.lwsp
                  3'b010     :  instruction_out = {4'b0, lwsp_imm, x2, 3'b010, rd_ci, 7'b0000011};				
                  
                  3'b100     :  if(inst_comp[12]==1'b0) begin
                                        if(rs1_ci != 5'b0 && rs2_cr == 5'b0)
                                              instruction_out = {12'b0, rs1_ci, 3'b000, 5'b0, 7'b1100111};  			    //JR
                                        else if(rs1_ci != 5'b0 && rs2_cr != 5'b0)
                                              instruction_out = {7'b0, rs2_cr, 5'b0, 3'b000, rs1_ci, 7'b0110011};     //MV
                                        end
                                else  begin
                                        if(rs1_ci == 5'b0 && rs2_cr == 5'b0)
                                              instruction_out = {11'b0, 1'b1, 5'b0, 3'b0, 5'b0, 7'b1110011};         //EBREAK
                                        else if(rs1_ci != 5'b0 && rs2_cr == 5'b0)
                                              instruction_out = {12'b0, rs1_ci, 3'b000, x1, 7'b1100111};             //JALR
                                        else if(rs1_ci != 5'b0 && rs2_cr != 5'b0)
                                              instruction_out = {7'b0, rs2_cr, rs1_ci, 3'b000, rs1_ci, 7'b0110011};  //ADD
                                      end
                  //c.swsp
                  3'b110     :  instruction_out = {4'b0, swsp_imm[7:5], rs2_cr, x2, 3'b010, swsp_imm[4:0], 7'b0100011}; 
                  default    :  instruction_out = 32'bx;
        endcase
        default:   instruction_out = 32'bx;
        endcase
        end
  end

//=======================================================
//      Compression FSM
//=======================================================

  // Next-state logic
  always @(*)
    begin
    case (p_state)
        STATE0  :   if (op1 == 2'b11 | instruction_in == 32'b0)begin
                        if(PCSrc_reg) begin
                            if(jump_addr % 4 ==0)
                                n_state = STATE0;
                            else 
                                n_state = STATE3;
                        end
                        else n_state    = STATE0;
                    end

                    else if (op1 == 2'b10| op1 == 2'b01| op1 == 2'b00 ) begin
                        if(PCSrc_reg) begin
                            if(jump_addr % 4 ==0)
                                n_state = STATE0;
                            else
                                n_state = STATE3;
                        end
                        else n_state    = STATE1;
                    end
		
        STATE1  :   if (instruction_reg[17:16] == 2'b11 | nop == 32'b0)begin
                        if(PCSrc_reg) begin
                            if(jump_addr % 4 ==0)
                                n_state = STATE0;
                            else 
                                n_state = STATE3;
                        end
                        else n_state    = STATE1;
                    end
                        
                    else begin
                        if(PCSrc_reg) begin
                            if(jump_addr % 4 ==0)
                                n_state = STATE0;
                            else 
                                n_state = STATE3;
                        end
                        else n_state    = STATE2;
                    end
    	     
        STATE2  :   if (instruction_reg[1:0] == 2'b11 | instruction_reg == 32'b0)begin
                        if(PCSrc_reg) begin
                            if(jump_addr % 4 ==0)
                                n_state = STATE0;
                            else
                                n_state = STATE3;
                        end
                        else n_state    = STATE2;
                    end

                    else begin
                        if(PCSrc_reg) begin
                            if(jump_addr % 4 ==0)
                                n_state = STATE0;
                            else
                                n_state = STATE3;
                        end
                        else n_state    = STATE1;
                    end

        STATE3  :   if (instruction_in[17:16] == 2'b11 || instruction_in[31:16] == 16'b0) begin
                    n_state    = STATE1;
                    end
                    
                    else begin
                    n_state    = STATE0;
                    end
                
        default :   begin n_state = STATE0; p_state = STATE0; end
	  endcase
	end

  // Output logic
  always @(*)
    begin
    pc_disable = 1'b0;
    case (p_state)
        STATE0  :   if (op1 == 2'b11 | instruction_in == 32'b0)begin
                    compressed = 1'b0;
                    register   = 2'd0;
                    end

                    else if (op1 == 2'b10| op1 == 2'b01| op1 == 2'b00 ) begin
                    compressed  = 1'b1;
                    register    = 2'd0;
                    inst_comp   = instruction_in[15:0];
                    end
		
        STATE1  :   if (instruction_reg[17:16] == 2'b11 | nop == 32'b0)begin
                    compressed = 1'b0;
                    register   = 2'd1;
                    end
                    else begin
                    compressed = 1'b1;
                    register   = 2'd0;
                    inst_comp  = instruction_reg[31:16];
                    end
    	     
        STATE2  :   if (instruction_reg[1:0] == 2'b11 | instruction_reg == 32'b0)begin
                    compressed  = 1'b0;
                    register    = 2'd2;
                    end

                    else begin
                    compressed = 1'b1;
                    register   = 2'd0;
                    inst_comp  = instruction_reg[15:0];
                    if (PCSrc | PCSrc_reg ) 
                      pc_disable = 1'b0;
                    else
                      pc_disable = 1'b1;
                    end

        STATE3  :   if (instruction_in[17:16] == 2'b11 || instruction_in[31:16] == 16'b0) begin
                    compressed = 1'b0;
                    register   = 2'd3;
                    end
                    
                    else begin
                    compressed = 1'b1;
                    register   = 2'd0;
                    inst_comp  = instruction_in[31:16];
                    end
                
        default :   begin compressed = 1'b0; register = 2'd0; inst_comp = 16'bx; pc_disable = 1'b0; end
	  endcase
	end

  assign ato_stall = (PCSrc_reg)?1'b0:atomic_;
  // state register
  always@(posedge clk or negedge reset)
  begin
      if(!reset)
          p_state <= STATE0;
      else if(ato_stall)
          p_state <= p_state; 
      else if (PCWrite)
          p_state <= n_state;
  end

  always_ff @(posedge clk or negedge reset) begin
    if(!reset) begin 
      ato_stall_reg <= 0;
    end
    else  
      begin 
        ato_stall_reg <= ato_stall;
      end
  end


endmodule


