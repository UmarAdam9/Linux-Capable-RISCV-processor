


module dummy_PC import risc_v_core_pkg::*;
(
  input             clk,
  input             reset,
  input             enable,
  input      [31:0] instruction,
  input             PCSrc,
  input             PCWrite,
  input      [31:0] PC_jump_addr,
  input   fsm_state p_state,
  output reg [31:0] dummy_pc
);


//=======================================================
//  REG/WIRE declarations
//=======================================================
  wire [31:0] nop;
  reg  [31:0] pc_next;
  reg  [31:0] instruction_dec;
  reg  [31:0] PC_jump_addr_reg;
  reg  PC_disable;
  reg  PCSrc_reg;


//=======================================================
//  Structural coding
//=======================================================

  always_ff @(posedge clk or negedge reset)
  begin
      if(!reset)begin
          PCSrc_reg         <= 1'b0;
          PC_jump_addr_reg  <= 32'd0;
      end
      else begin
        if(enable) begin
          PCSrc_reg         <= PCSrc; 
          PC_jump_addr_reg  <= PC_jump_addr;
        end
        else begin 
          PCSrc_reg         <= PCSrc_reg;
          PC_jump_addr_reg  <= PC_jump_addr_reg;
        end
      end
  end

  always_ff @( posedge clk or negedge reset) 
  begin 
      if(!reset)
          instruction_dec 	<= 32'd0; 
      else if(enable) begin 
        if(!PC_disable & PCWrite)
          instruction_dec   <= instruction;
        else 
          instruction_dec   <= instruction_dec;
      end
      else 
        instruction_dec   <= instruction_dec;
  end

  assign nop = {instruction[15:0],instruction_dec[31:16]};

  always@(*) begin
    pc_next = dummy_pc;
    PC_disable = 0;
    case (p_state)
        STATE0  :   if (PCSrc_reg) begin
                        pc_next = {PC_jump_addr_reg[31:1],1'b0};
                    end
                      
                    else if (PCWrite == 1'b0) 
                        pc_next = pc_next;

                    else if (instruction[1:0] == 2'b11 | instruction == 32'b0)begin 
                        pc_next = dummy_pc + 4;
                    end

                    else if (instruction[1:0] == 2'b10| instruction[1:0] == 2'b01| instruction[1:0] == 2'b00 ) begin
                        pc_next = dummy_pc + 2;
                    end
    
        STATE1  :   if (PCSrc_reg) begin
                        pc_next = {PC_jump_addr_reg[31:1],1'b0};
                    end

                    else if (PCWrite == 1'b0) 
                        pc_next = pc_next;

                    else if (instruction_dec[17:16] == 2'b11  | nop == 32'b0) begin
                        pc_next = dummy_pc + 4; 
                    end

                    else begin
                        pc_next = dummy_pc + 2;
                    end
        	     
        STATE2  :   if (PCSrc_reg) begin
                        pc_next = {PC_jump_addr_reg[31:1],1'b0};
                    end
                            
                    else if (PCWrite == 1'b0) 
                        pc_next = pc_next;

                    else if (instruction_dec[1:0] == 2'b11  | instruction_dec == 32'b0)begin
                        pc_next = dummy_pc + 4;
                    end
    
                    else begin
                        pc_next = dummy_pc + 2;
                        PC_disable = 1;
                    end
                
        STATE3  :   if (PCSrc_reg) begin
                        pc_next = {PC_jump_addr_reg[31:1],1'b0};
                    end
                    else if (PCWrite == 1'b0) 
                        pc_next = pc_next;

                    else if (instruction[17:16] == 2'b11 | instruction[31:16] == 16'b0)begin 
                        pc_next = pc_next;
                    end

                    else begin
                        pc_next = dummy_pc + 2;
                    end
    
        default :   begin pc_next = dummy_pc; PC_disable = 0; end
	  endcase
  end

  always_ff @( posedge clk or negedge reset)
  begin
      if(!reset)
          dummy_pc <= 32'h80000000;
      else if(enable)
          dummy_pc <= pc_next;
      else 
        dummy_pc   <= dummy_pc;
  end


endmodule
        
