
//=======================================================
//  module declaration
//=======================================================

module RISCV32IMC   import risc_v_core_pkg::*, tracer_pkg::*;
(
  input                clk_in                ,
  input                rst_in                ,
  mem_ntv_interface_if mem_ntv_interface_imem,
  mem_ntv_interface_if mem_ntv_interface_dmem
);

//=======================================================
//  REG/WIRE declarations
//=======================================================

  //Fetch stage 
    //pc + 4 block 
      wire [31:0] PCout_plus4;
    //pc_mux block
      wire [31:0] mux_outpc;
    //PC Register block
      wire [31:0] PC_out; 
    //Instruction Memory
      wire [31:0] inst_mem_out;
    //Register
      reg  [31:0] PC_out_reg;
    //Instruction Decoder block
      instruction_t   instruction_o;

  //Decode stage 
    //hazard detection unit   
      wire        PCWrite; 
      wire        IF_DWrite; 
      wire        hazard_out;
    //Register
      reg         hazard_out_reg; 
      reg         IF_Dwrite_reg;
      reg         PCSrc_reg;
    //PC Register block
      wire [31:0] PC_out_IF_ID; 
    //Instruction Register block
      wire [31:0] inst_out_IF_ID;
    //Register File unit
      wire [31:0] rs1_out; 
      wire [31:0] rs2_out; 
      wire [31:0] rd_regfile;
    //Immediate Generator Block
      wire [31:0] inst_out_imm; 
    //Control Unit 
      wire        RegWrite; 
      wire        MemtoReg; 
      wire        MemRead; 
      wire        MemWrite; 
      wire        jal; 
      wire        jalr;
      wire [1:0]  ALUOp; 
      wire [1:0]  ALUSrcA; 
      wire [1:0]  ALUSrcB;
      wire [5:0]  Branch;
      wire        valid;
    //control_signals_mux block
      wire [23:0] cntrl_out; 

  //Execute stage 
    //PC Register block
      wire [31:0] PC_out_ID_EX; 
    //Instruction Register block
      wire [31:0] inst_out_ID_EX;
    //Immediate Register block 
      wire [31:0] imm_out_ID_EX;
    //Control Signals Register block 
      wire [23:0] cntrl_out_ID_EX;
    //rs1 Register block
      wire [31:0] rs1_out_ID_EX;
    //rs2 Register block 
      wire [31:0] rs2_out_ID_EX;
    //jump mux block
      wire [31:0] mux_out_jump;
    //Adder block
      wire [31:0] jump_addr;
    //forwarding unit
      wire [1 :0] forwardA; 
      wire [1 :0] forwardB;
    //rs1 mux block
      wire [31:0] rs1_forwarded;
    //rs2 mux block 
      wire [31:0] rs2_forwarded;
    //ALU_input_A mux block
      wire [31:0] alu_input_A;
    //ALU_input_B mux block
      wire [31:0] alu_input_B;
    //ALU control block
      wire [4 :0] alu_contrl;
    //ALU Block
      wire [31:0] alu_result;
      wire zero; 
      wire nzero; 
      wire less; 
      wire greater; 
      wire lessun; 
      wire greaterun;
    //branch signals
      wire a_n_d_1, a_n_d_2, a_n_d_3, a_n_d_4, a_n_d_5, a_n_d_6;
    //jump signal
      wire PCSrc; 
  
  //Memory stage 
    //store unit
      wire [3:0] byte_en;
    //Data memory
      wire [31:0] data_mem_out;
    //control signals Register block
      wire [23:0] cntrl_out_Ex_MEM;
    //ALU Result Register block
      wire [31:0] alu_result_EX_MEM;
    //Instruction Register block
      wire [31:0] inst_out_EX_MEM;
    //data mem write data mux
      wire [31:0] dmem_wr_data;
    //dmem address selection 
    logic         dmem_addr_sel;
    
  //Writeback stage 
    //control signals Register block
      wire [23:0] cntrl_out_MEM_WB;
    //data memory Register block
      wire [31:0] dataout_MEM_WB;
    //ALU Result Register block
      wire [31:0] alu_result_MEM_WB;
    //Instruction Register block
      wire [31:0] inst_out_MEM_WB; 
    //Load Unit
      wire [31:0] load_store_unit_out;
    //Writeback mux block
      wire  [31:0]  regfile_write_data; 
      logic [31:0]  regfile_wr_data_final;
    //Instruction Decoder block
      instruction_t   instruction_WB;
  
  //Compression Extension
    wire [31:0] inst_out_comp;
    wire        pc_disable;
    fsm_state   comp_state;
    wire [31:0] mux_jump_out;
    wire [31:0] dummypc;
    reg  [31:0] dummy_pc_ifid; 
    reg  [31:0] dummy_pc_idex; 
    reg  [31:0] dummy_pc_exmem; 
    reg  [31:0] dummy_pc_memwb;
    reg         compressed; 
    reg         compressed1; 
    reg         compressed2; 
	  
  //atomic extension 
    wire        regfile_rd_addr_sel;
    //wire [1:0]  is_sc_reg_wr;
    wire        dmem_wr_data_sel;
    logic       reserved;
    //amo_controls_t atomic_control_out;
    wire [31:0]   rs2_out_MEM_WB; 
    logic         amo_stall ;
    logic [1:0]   amo_ALUSrcA   ;
    logic [1:0]   amo_ALUSrcB   ;
    logic [1:0]   amo_ALUOp     ;
    logic         amo_MemRead   ;
    logic         amo_MemWrite  ;
    logic         amo_regfile_rd_addr_sel   ;
    logic         amo_RegWrite  ;
    logic         amo_MemtoReg  ;
    logic         amo_dmem_wr_data_sel      ;
    logic [1:0]   amo_is_sc_reg_wr         ;
    logic         is_atomic;
    logic [23:0]  cntrl_out_normal;
    logic         is_atomic_reg;
    logic         is_atomic_reg2;
    logic         is_atomic_reg3;
    logic         amo_stall_reg;
    logic         atomic_;
    logic         lr_w_inst_reg;
    logic         sc_w_inst_reg;
    logic         sc_w_inst_reg2;
    logic         lr_sc_w_inst_reg;
    logic         reserved_reg;
    logic         reserved_reg2;
    logic [31:0]  rs2_forwarded_reg;
    logic         amo_dmem_addr_sel;
    logic         dmem_addr_sel_reg;
    logic         sc_w_inst_EX_MEM;
    logic         sc_w_inst_MEM_WB;
    logic         atomic_stall;
    logic         PCSrc_reg2;
    logic         atomic_stall_2;
//=======================================================
//  Structural Code
//=======================================================

//========================================================================================================
//                                             Fetch Stage
//========================================================================================================
  //(PC + 4) block
    adder pc_adder(
      .a(PC_out     ),
      .b(32'd4      ),
      .c(PCout_plus4)
    );

  //mux to select (PC + 4) or jump address 
    mux mux_pc(
      .a(PCout_plus4), 
      .b(jump_addr  ),             
      .s(PCSrc      ), 
      .c(mux_outpc  )
    );

  //PC Register
    register_en   
    #(
      .Default_val(32'h80000000)
    )  PC (  
        .clk  (clk_in                ), 
        .reset(rst_in                ),
        .en   (PCWrite & ~pc_disable & !atomic_stall ),
        .d    ({mux_outpc[31:1],1'b0}),
        .q    (PC_out                )
    );

  //assigning values to Instruction Memory (FETCH stage)
    assign mem_ntv_interface_imem.addr     = PC_out;
    assign mem_ntv_interface_imem.r_en     = PCWrite & ~pc_disable & !atomic_stall ;  
    assign inst_mem_out                    = mem_ntv_interface_imem.rdata;


  //for synchronisation of PC with Instruction(PC_out-4)
    always@(posedge clk_in or negedge rst_in)
    begin
      if (!rst_in)
          PC_out_reg <= 32'b0;
      else PC_out_reg <= PC_out;        
    end

  //compression unit that converts 16 bit compressed inst into 32 bit inst
    c_controller		compr(					
      .clk            (clk_in         ),
      .reset          (rst_in         ),
      .instruction_in (inst_mem_out   ),
      .PCWrite        (PCWrite        ),
      //.is_atomic      (is_atomic_reg  ),
      .atomic_        (is_atomic        ),
      .amo_stall      (atomic_stall),
      .instruction_out(inst_out_comp  ),
      .pc_disable     (pc_disable     ),
      .compressed     (compressed     ),
      .PCSrc          (PCSrc          ),
      .PC_jump_addr   (jump_addr      ),
      .comp_state     (comp_state     )
	  );
  
  //Dummy_PC Unit (used for compression extension)
    dummy_PC dummy_PC_inst(
      .clk          (clk_in           ),
      .reset        (rst_in           ),
      .enable       (!atomic_stall),      //!amo_stall
      .instruction  (inst_mem_out     ), 
      .PCWrite      (PCWrite          ),
      .PCSrc        (PCSrc            ),
      .PC_jump_addr (jump_addr        ),
      .p_state      (comp_state       ),        
      .dummy_pc     (dummypc          )
				  
	);
  assign atomic_stall = (PCSrc_reg) ? 0 : amo_stall;

	//registering dummy pc to be used in further stages
    always@(posedge clk_in or negedge rst_in)
    begin
      if(!rst_in)begin 
        dummy_pc_ifid  <= 32'd0;
        dummy_pc_idex  <= 32'd0;
        dummy_pc_exmem <= 32'd0;
        dummy_pc_memwb <= 32'd0;
        end
      else begin
        dummy_pc_ifid  <= dummypc;
        dummy_pc_idex  <= dummy_pc_ifid;
        dummy_pc_exmem <= dummy_pc_idex;
        dummy_pc_memwb <= dummy_pc_exmem;
        end
    end

  //converting instruction bits into enum for wave display
    Instruction_reg inst_decoder(
      .instruction    (inst_out_comp), 
      .instruction_o  (instruction_o)
    );

  //register PCSrc (jump indication will be used for flush in later stage)
    always@(posedge clk_in or negedge rst_in)
    begin
      if (!rst_in)
           PCSrc_reg <= 1'b0;
      else PCSrc_reg <= PCSrc;
    end

//========================================================================================================
//                                            Decode Stage
//========================================================================================================

  //hazard detection (stall of one cycle if hazard detected)
    hazard_detection_unit hazard_unit(
      .ID_EX_rd     (inst_out_IF_ID[11:7]), 
      .IF_ID_rs1    (inst_out_comp[19:15]),  
      .IF_ID_rs2    (inst_out_comp[24:20]),  
      .ID_EX_memread(MemRead | (amo_MemRead && lr_w_inst_reg)), 
      .opcode       (inst_out_comp[6:0]  ),
      .PCWrite      (PCWrite             ), // signal used to disable PC     
      .IF_Dwrite    (IF_Dwrite           ), // signal used to disable IF_ID Registers  
      .hazard_out   (hazard_out          )  // signal used to select 0 as control signals
  );
  
  //registering Hazard out and IF_D write 
    always@(posedge clk_in or negedge rst_in)
    begin
      if (!rst_in) begin
          hazard_out_reg <= 1'b0;
          IF_Dwrite_reg  <= 1'b0;
          PCSrc_reg2     <= 0;
      end
      else begin
        hazard_out_reg <= hazard_out;
        IF_Dwrite_reg  <= IF_Dwrite;
        PCSrc_reg2     <= PCSrc_reg;
      end
    end

  //Registering PC For Decode Stage
    register_en IF_ID_pcout(
      .clk   (clk_in            ), 
      .reset (rst_in            ),
      .flush (PCSrc | PCSrc_reg ), //generate flush for two cycle
      .en    (IF_Dwrite_reg     ), 
      .d     (PC_out_reg        ),
      .q     (PC_out_IF_ID      )
    );

  //Registering Instruction For Decode Stage
    register_en IF_ID_instout(
      .clk   (clk_in            ), 
      .reset (rst_in            ), 
      .flush (PCSrc | PCSrc_reg ), //generate flush for two cycle
      .en    (IF_Dwrite_reg  & atomic_stall_2  ),  
      .d     (inst_out_comp     ),
      .q     (inst_out_IF_ID    )
    );
    assign atomic_stall_2 = (PCSrc_reg2) ? 1:!amo_stall_reg;
  //mux at input of rd of regfile to select between rd and rs2_out for amo swap instruction
    mux mux_rd_regfile(
      .a(inst_out_MEM_WB[11:7]),    //rd
      .b(inst_out_MEM_WB[24:20]),   //rs2
      .s(cntrl_out_MEM_WB[22]),    //regfile_rd_addr_sel
      .c(rd_regfile)
    );
  //Register File
    register_file reg_file(
      .write_data (regfile_wr_data_final ), 
      .rs1        (inst_out_IF_ID[19:15] ),  
      .rs2        (inst_out_IF_ID[24:20] ),   
      .rd         (inst_out_MEM_WB[11:7] ),     
      .we         (cntrl_out_MEM_WB[1]   ),   //regwrite
      .clk        (clk_in                ), 
      .rst        (rst_in                ),
      .read_data1 (rs1_out               ), 
      .read_data2 (rs2_out               )
  );

  //Immediate Generator
    Imm_Gen imm_gen(
      .Inst_In    (inst_out_IF_ID        ),      
      .Imm_Out    (inst_out_imm          )
  );

  //Generate control Signals
    control_unit control_unit(
      .Op         (inst_out_IF_ID[6:0]   ),              
      .funct3     (inst_out_IF_ID[14:12] ),        
      .funct7     (inst_out_IF_ID[31:25] ),
      .ALUOp      (ALUOp                 ), 
      .ALUSrcA    (ALUSrcA               ), 
      .ALUSrcB    (ALUSrcB               ),
      .Branch     (Branch                ),
      .RegWrite   (RegWrite              ), 
      .MemtoReg   (MemtoReg              ), 
      .MemRead    (MemRead               ), 
      .MemWrite   (MemWrite              ),
      .jal        (jal                   ), 
      .jalr       (jalr                  ),
      .valid      (valid                 ),
      .dmem_addr_sel(dmem_addr_sel)
  );
    
  //atomic instructions control unit
    amo_control_unit amo_control_unit_inst(
        .clk(clk_in),
        .reset(rst_in),
        .instruction(inst_out_comp),  //instruction will come from fetch stage 
        //.Instruction_reg(inst_out_IF_ID),
        .lr_sc_w_inst(lr_sc_w_inst),
        .is_atomic(is_atomic),
        .atomic_(atomic_),
        .lr_w_inst_reg(lr_w_inst_reg),
        .sc_w_inst_reg(sc_w_inst_reg),
        .amo_stall(amo_stall),
        .ALUSrcA(amo_ALUSrcA),
        .ALUSrcB(amo_ALUSrcB),  
        .ALUOp(amo_ALUOp),   
        .MemRead(amo_MemRead),
        .MemWrite(amo_MemWrite),
        .regfile_rd_addr_sel(amo_regfile_rd_addr_sel),  
        .RegWrite(amo_RegWrite),
        .MemtoReg(amo_MemtoReg),
        .dmem_wr_data_sel(amo_dmem_wr_data_sel),  
        .dmem_addr_sel(amo_dmem_addr_sel),  
        .is_sc_reg_wr(amo_is_sc_reg_wr)

    );


  //mux to select control signals (18'b0 if there is a stall or flush)
    mux #(24) control_signals(
      .a({dmem_addr_sel,amo_regfile_rd_addr_sel,amo_stall,amo_is_sc_reg_wr[1:0],amo_dmem_wr_data_sel,ALUOp[1:0], ALUSrcA[1:0], ALUSrcB[1:0], jalr, Branch[5:0], jal, MemRead, MemWrite, RegWrite, MemtoReg}), 
      .b(24'd0), 
      .s(hazard_out_reg | PCSrc), 
      .c(cntrl_out_normal)
  );

  //registering stall signals 
    always_ff @(posedge clk_in or negedge rst_in) begin
      if(!rst_in) begin
        is_atomic_reg <= 0;
        lr_sc_w_inst_reg  <= 0;
        amo_stall_reg <= 0;
        dmem_addr_sel_reg <= 0;
        is_atomic_reg2    <= 0;
        is_atomic_reg3    <= 0;
      end
      else begin 
        is_atomic_reg <= is_atomic;
        amo_stall_reg <= amo_stall;
        lr_sc_w_inst_reg <= lr_sc_w_inst;
        dmem_addr_sel_reg <=  dmem_addr_sel;
        is_atomic_reg2  <= is_atomic_reg;
        is_atomic_reg3    <= is_atomic_reg2;
      end 
    end
  //selecting control signals between atomic controls and normal controls
    mux #(24) final_controls(
      .a(cntrl_out_normal),
      .b({amo_dmem_addr_sel,amo_regfile_rd_addr_sel,amo_stall,amo_is_sc_reg_wr[1:0],amo_dmem_wr_data_sel,amo_ALUOp[1:0], amo_ALUSrcA[1:0],amo_ALUSrcB[1:0],jalr,Branch[5:0],jal,amo_MemRead,amo_MemWrite,amo_RegWrite,amo_MemtoReg}),
      .s(is_atomic_reg | cntrl_out_ID_EX[21] | lr_sc_w_inst_reg),
      .c(cntrl_out)
    );

    //amo_memtoreg = cntrl_out[0]
    //amo_regwrite = cntrl_out[1]
    //amo_memwrite = cntrl_out[2]
    //amo_memread = cntrl_out[3]
    //jal = cntrl_out[4]
    //branch[5:0] = cntrl_out[10:5]
    //jalr = cntrl_out[11]
    //alusrc_b[1:0] = cntrl_out[13:12]
    //alusrc_a[1:0] = cntrl_out[15:14]
    //alu_op[1:0] = cntrl_out[17:16]
    //dmem_wr_dta_sel = cntrl_out[18]
    //is_sc_reg_wr_sel = cntrl_out[20:19]
    //amo_stall = cntrl_out[21]
    //amo_regfile_rd_addr_sel = cntrl_out[22]
    //amo_dmem_addr_sel       = cntrl_out[23]

//========================================================================================================
//                                          Execute Stage
//========================================================================================================

  //Registering PC For Execute Stage
    register ID_EX_pcout(
      .clk   (clk_in                ), 
      .reset (rst_in                ),
      .flush (PCSrc |hazard_out_reg ),    
      .d     (PC_out_IF_ID          ), 
      .q     (PC_out_ID_EX          )
    );

  //Registering Instruction For Execute Stage
    register ID_EX_instout(
      .clk   (clk_in                ), 
      .reset (rst_in                ), 
      .flush (PCSrc |hazard_out_reg ),         
      .d     (inst_out_IF_ID        ),   
      .q     (inst_out_ID_EX        )
    );

  //Registering Immediate For Execute Stage
    register ID_EX_imm(
      .clk   (clk_in                ), 
      .reset (rst_in                ), 
      .flush (PCSrc                 ), 
      .d     (inst_out_imm          ), 
      .q     (imm_out_ID_EX         )
    );

  //Registering Controls Signals For Execute Stage
    register #(24) ID_EX_controls(
      .clk   (clk_in                ), 
      .reset (rst_in                ), 
      .flush (PCSrc                 ), 
      .d     (cntrl_out             ),
      .q     (cntrl_out_ID_EX       )
    );

  //Registering Rs1_out For Execute Stage
    register ID_EX_rs1out(
      .clk   (clk_in                ), 
      .reset (rst_in                ), 
      .flush (PCSrc                 ), 
      .d     (rs1_out               ), 
      .q     (rs1_out_ID_EX         )
    );

  //Registering Rs2_out For Execute Stage
    register ID_EX_rs2out(
      .clk   (clk_in                ), 
      .reset (rst_in                ), 
      .flush (PCSrc                 ), 
      .d     (rs2_out               ), 
      .q     (rs2_out_ID_EX         )
    );

  //mux that selects rs1 for Jalr or PC for other jumps
    mux jump(
      .a     (dummy_pc_idex         ), 
      .b     (rs1_forwarded         ),   
      .s     (cntrl_out_ID_EX[11]   ), //JALR 
      .c     (mux_out_jump          )
    );

  //adder to calculate jump address for PC
    adder ADDJump_imm(
      .a     (mux_out_jump          ),
      .b     (imm_out_ID_EX         ),
      .c     (jump_addr             )
    );

  //Generate Select lines for mux A and mux B from where to forward data(of rs1 and rs2)
    forwarding_unit forwarding_unit(
      .rs1            (inst_out_ID_EX[19:15]), 
      .rs2            (inst_out_ID_EX[24:20]), 
      .EX_MEM_rd      (inst_out_EX_MEM[11:7]), 
      .MEM_WB_rd      (inst_out_MEM_WB[11:7]),
      .EX_MEM_regwrite(cntrl_out_Ex_MEM[1]  ),  //regwrite
      .MEM_WB_regwrite(cntrl_out_MEM_WB[1]  ),  //regwrite
      .is_atomic      (is_atomic_reg3       ),
      .sc_w_inst_EX_MEM(sc_w_inst_EX_MEM    ),
      .sc_w_inst_MEM_WB(sc_w_inst_MEM_WB    ),
      .reserved       (reserved             ),
      .forward_A      (forwardA             ), 
      .forward_B      (forwardB             )
    );

  //mux to select latest rs1 data using forwarding 
    mux_4x1 mux_rs1(
      .a     (rs1_out_ID_EX         ),  
      .b     (regfile_write_data    ), //mem hazard   
      .c     (alu_result_EX_MEM     ), //execute hazard
      .d     ((reserved_reg) ? 0:1  ),  //when sc.w hazard occurs this will go 
      .s     (forwardA              ), 
      .q     (rs1_forwarded         )
    );

  //mux to select latest rs2 data using forwarding 
    mux_4x1 mux_rs2(
      .a     (rs2_out_ID_EX         ),  
      .b     (regfile_write_data    ), //mem hazard  
      .c     (alu_result_EX_MEM     ), //execute hazard
      .d     ((reserved_reg) ? 0:1  ),
      .s     (forwardB              ),  
      .q     (rs2_forwarded         )
    );

  //registering compressed signal from fetch stage to be used in execute
	  always@(posedge clk_in or negedge rst_in)			
	  begin
      if(!rst_in)begin 
          compressed1       <= 1'b0;
          compressed2       <= 1'b0;
          sc_w_inst_reg2    <= 0;  
          sc_w_inst_EX_MEM  <= 0;    
          sc_w_inst_MEM_WB  <= 0;
      end
      else begin
          compressed1       <= compressed;
          compressed2       <= compressed1;
          sc_w_inst_reg2    <= sc_w_inst_reg;      //this is in execute stage now
          sc_w_inst_EX_MEM  <= sc_w_inst_reg2;   //this is in memory stage now
          sc_w_inst_MEM_WB  <= sc_w_inst_EX_MEM; //this is in write back stage now
      end
	  end

  //mux to select "2" (rd=pc+2) when there is compressed instruction
	  mux comp_jump (
      .a	(32'd4          ),
      .b	(32'd2          ), 
      .s	(compressed2    ), 
      .c	(mux_jump_out   )
	  );

  //mux to select input For ALU First(A) input
    mux_4x1 mux_ALU_A(
      .a     (rs1_forwarded         ), 
      .b     (dummy_pc_idex         ), 
      .c     (32'd0                 ),
      .d     (data_mem_out          ),  //comes directly from main memory 
      .s     (cntrl_out_ID_EX[15:14]),  //ALUSrcA
      .q     (alu_input_A           )
    );
  
  //mux to select input For ALU Second(B) input
    mux_4x1 mux_ALU_B(
      .a     (rs2_forwarded         ), 
      .b     (imm_out_ID_EX         ), 
      .c     (mux_jump_out          ),
      .d     (32'd0                 ),    //for atomic rs1+0 to get M[rs1]         
      .s     (cntrl_out_ID_EX[13:12]),  //ALUSrcB
      .q     (alu_input_B           )
    );

  //Generate control lines for ALU 
    ALUControl alu_control(
      .ALUOp          (cntrl_out_ID_EX[17:16]), 
      .funct3         (inst_out_ID_EX[14:12] ), 
      .funct7         (inst_out_ID_EX[31:25] ),
      .funct5         (inst_out_ID_EX[31:27] ),   
      .OP             (inst_out_ID_EX[6:0]   ),
      .ALUCtl         (alu_contrl            )
    );

  //ALU Unit
    ALU alu (
      .ALUctl         (alu_contrl            ), 
      .A              (alu_input_A           ), 
      .B              (alu_input_B           ), 
      .ALUOut         (alu_result            ), 
      .Zero           (zero                  ),
      .n_zero         (nzero                 ),
      .less_than      (less                  ),
      .greater_than   (greater               ),
      .less_than_u    (lessun                ),
      .greater_than_u (greaterun             )
    );

  //Checking different Branch Conditions
    assign a_n_d_1 = zero       & cntrl_out_ID_EX[5]; //BEQ
    assign a_n_d_2 = nzero      & cntrl_out_ID_EX[6]; //BNE
    assign a_n_d_3 = less       & cntrl_out_ID_EX[7]; //BLT
    assign a_n_d_4 = greater    & cntrl_out_ID_EX[8]; //BGE
    assign a_n_d_5 = lessun     & cntrl_out_ID_EX[9]; //BLTU
    assign a_n_d_6 = greaterun  & cntrl_out_ID_EX[10];//BGEU

  //PCSRC is 1 if any of Jump condition is true (Branch , Jalr or Jal)
    assign PCSrc = a_n_d_1 | a_n_d_2 |a_n_d_3 |a_n_d_4 |a_n_d_5 |a_n_d_6 | cntrl_out_ID_EX[11] | cntrl_out_ID_EX[4];


//========================================================================================================
//                                         Memory Stage
//========================================================================================================

  // Generate byte_enable for data memory
    store_unit store_unit(
      .func3       (inst_out_ID_EX[14:12] ),
      .dmem_address(alu_result[1:0]       ), 
      .byte_en     (byte_en               )
    );

  //registering rs2 forwarded
  always_ff @(posedge clk_in or negedge rst_in) begin
    if(!rst_in)
      rs2_forwarded_reg <= 0;
    else  
      rs2_forwarded_reg <= rs2_forwarded;
  end
  //mux that selects the data to be written in data memory 
    mux dmem_wr_mux(
      .a(rs2_forwarded), //rs2_forwarded_reg
      .b(alu_result),
      .s(cntrl_out_ID_EX[18]),  //amo_dmem_wr_data_sel
      .c(dmem_wr_data)
    );
  // Assigning values to Data Memory
  // Sending unregistered values(execute stage) to Data Memory because our memory is input registered
    assign mem_ntv_interface_dmem.addr        = (cntrl_out_ID_EX[23]) ? alu_result : alu_result_EX_MEM;   //amo_dmem_addr_sel      
    assign mem_ntv_interface_dmem.wdata       = dmem_wr_data;             
    assign mem_ntv_interface_dmem.w_en        = reserved | cntrl_out_ID_EX[2];   
    assign mem_ntv_interface_dmem.r_en        = cntrl_out_ID_EX[3];   
    assign mem_ntv_interface_dmem.byteenable  = byte_en;
    assign data_mem_out                       = mem_ntv_interface_dmem.rdata;

  //atomic reservation file for lr.w/sc.w instructions 
    reservation_file  reserve_file(
          .clk(clk_in),
          .rst(rst_in),
          .instruction(inst_out_ID_EX),
          .reserved(reserved)
    );


  //Registering Controls Signals For Memory Stage
    register #(23) EX_MEM_controls(
      .clk   (clk_in               ), 
      .reset (rst_in               ), 
      .d     (cntrl_out_ID_EX ),
      .q     (cntrl_out_Ex_MEM     )
    );

  //Registering ALU Result For Memory Stage
    register EX_MEM_ALU(
      .clk   (clk_in               ), 
      .reset (rst_in               ), 
      .d     (alu_result           ), 
      .q     (alu_result_EX_MEM    )
    );

  //Registering Instruction For Memory Stage
    register EX_MEM_instout(
      .clk   (clk_in               ), 
      .reset (rst_in               ), 
      .d     (inst_out_ID_EX       ), 
      .q     (inst_out_EX_MEM      )
    );


//========================================================================================================
//                                         Writeback Stage
//========================================================================================================

  //Registering Controls Signals For Writeback Stage
    register #(23) MEM_WB_controls(
      .clk   (clk_in               ), 
      .reset (rst_in               ), 
      .d     (cntrl_out_Ex_MEM),
      .q     (cntrl_out_MEM_WB     )
    );

  //Registering Datamemory Out For Writeback Stage
    register MEM_WB_datamem(
      .clk   (clk_in               ), 
      .reset (rst_in               ), 
      .d     (data_mem_out         ), 
      .q     (dataout_MEM_WB       )
    );
  
  //Registering ALU Result for Writeback Stage
    register MEM_WB_ALU(
      .clk   (clk_in               ), 
      .reset (rst_in               ), 
      .d     (alu_result_EX_MEM    ), 
      .q     (alu_result_MEM_WB    )
    );

  //Registering Instruction for Writeback Stage
    register MEM_WB_instout(
      .clk   (clk_in               ), 
      .reset (rst_in               ), 
      .d     (inst_out_EX_MEM      ), 
      .q     (inst_out_MEM_WB      )
    );
  
  //Generates data to be loaded in Register file for load instruction
    load_unit load_unit(
      .data_in_load (dataout_MEM_WB        ), 
      .func3        (inst_out_MEM_WB[14:12]),  
      .addr         (alu_result_MEM_WB[1:0]),  
      .data_out_load(load_store_unit_out   )
    );

  //Selects data to be written in register file (load_unit_out or Alu_result)
    mux write_back(
      .a     (alu_result_MEM_WB    ),  
      .b     (load_store_unit_out  ),  
      .s     (cntrl_out_MEM_WB[0]  ), //memtoreg
      .c     (regfile_write_data   )
    );

  //registering reserved signal
    always_ff @(posedge clk_in or negedge rst_in) begin
      if(!rst_in) begin 
        reserved_reg <= 0;
        reserved_reg2 <= 0;
        end
      else begin 
        reserved_reg <= reserved; 
        reserved_reg2 <= reserved_reg;
        end
      end

    //final selection for data to be written in register file 
    mux_4x1 final_write_back(
      .a(regfile_write_data),       //in case of no sc.w instruction
      .b((reserved_reg2) ? 32'd0: 32'd1),                    //in case of sc.w success
      .c(32'd1),                    //in case of sc.w failure
      .d(rs2_out_MEM_WB),
      .s(cntrl_out_MEM_WB[20:19]), // is_sc_reg_write
      .q(regfile_wr_data_final)                          //mux out
    );
  //converting instruction bits into enum for wave display
    Instruction_reg inst_decoder_WB(
      .instruction    (inst_out_MEM_WB ), 
      .instruction_o  (instruction_WB)
    );

  //Stops simulation when there is ecall instruction
    always@(*) begin
      if (instruction_WB.opcode==E_type &&  inst_out_MEM_WB[31:7]==25'b0)begin
        $finish();
      end
    end

//========================================================================================================
//                                         Tracer Work
//========================================================================================================
  
//=======================================================
//  REG/WIRE declarations
//=======================================================
  wire [31:0] rs1_out_EX_MEM; 
  wire [31:0] rs2_out_EX_MEM;  
  wire [31:0] rs1_out_MEM_WB; 
  
  wire [31:0] PC_out_EX_MEM;
  wire [31:0] PC_out_MEM_WB;

  reg valid_ie;
  reg valid_dmem;
  reg valid_wback;

//=======================================================
//  Structural coding
//=======================================================

  register EX_MEM_rs1out(
    .clk  (clk_in        ), 
    .reset(rst_in        ), 
    .d    (rs1_out_ID_EX ), 
    .q    (rs1_out_EX_MEM)
  );

  register EX_MEM_rs2out(
    .clk  (clk_in        ), 
    .reset(rst_in        ), 
    .d    (rs2_out_ID_EX ), 
    .q    (rs2_out_EX_MEM)
  );

  register MEM_WB_rs1out(
    .clk  (clk_in        ), 
    .reset(rst_in        ),  
    .d    (rs1_out_EX_MEM), 
    .q    (rs1_out_MEM_WB)
  );

  register MEM_WB_rs2out(
    .clk  (clk_in        ), 
    .reset(rst_in        ),  
    .d    (rs2_out_EX_MEM),
    .q    (rs2_out_MEM_WB)
  );

  register EX_MEM_pcout(
    .clk  (clk_in        ), 
    .reset(rst_in        ), 
    .d    (PC_out_ID_EX  ), 
    .q    (PC_out_EX_MEM )
  );

  register MEM_WB_pcout(
    .clk  (clk_in        ), 
    .reset(rst_in        ), 
    .d    (PC_out_EX_MEM ), 
    .q    (PC_out_MEM_WB )
  );

  always @ (posedge clk_in , negedge rst_in)
  begin
    if (!rst_in)
    begin
      valid_ie<=0;
      valid_dmem<=0;
      valid_wback<=0;
    end
    else
    begin
      valid_ie<=valid;
      valid_dmem<=valid_ie;
      valid_wback<=valid_dmem;
    end
  end

  //tracer instantiated 
    tracer tracer_inst(
      .clk_i              (clk_in                ),
      .rst_ni             (rst_in                ),
      .hart_id_i          (0                     ),
      .rvfi_valid         (valid_wback & cntrl_out_MEM_WB[1]),
      .rvfi_insn_t        (inst_out_MEM_WB       ),
      .rvfi_rs1_addr_t    (inst_out_MEM_WB[19:15]),
      .rvfi_rs2_addr_t    (inst_out_MEM_WB[24:20]),
      .rvfi_rs3_addr_t    (                      ),
      .rvfi_rs1_rdata_t   (rs1_out_MEM_WB        ),
      .rvfi_rs2_rdata_t   (rs2_out_MEM_WB        ),
      .rvfi_rs3_rdata_t   (                      ),
      .rvfi_rd_addr_t     (inst_out_MEM_WB[11:7] ),
      .rvfi_rd_wdata_t    (regfile_wr_data_final ),
      .rvfi_pc_rdata_t    (dummy_pc_memwb        ),
      .rvfi_pc_wdata_t    (dummypc               ),
      .rvfi_mem_addr      (alu_result_MEM_WB     ),
      .rvfi_mem_rmask     (                      ),
      .rvfi_mem_wmask     (                      ),
      .rvfi_mem_rdata     (dataout_MEM_WB        ),
      .rvfi_mem_wdata     (rs2_out_MEM_WB        )
    );

endmodule
