//////////////////////////////////////////////////////////////////////////
/// Author (name and email): Qazi Hamid Ullah, qullah.bee20seecs@seecs.edu.pk
/// Date Created: 2/24/2024
///////////////////////////////////////////////////////////////////////////

package risc_v_core_pkg;


typedef enum logic [6:0] { 
    R_type        =   7'b0110011,
    load_type     =   7'b0000011,
    I_type        =   7'b0010011,
    jalr_type     =   7'b1100111,
    S_type        =   7'b0100011,
    B_type        =   7'b1100011,
    lui_type      =   7'b0110111,
    auipc_type    =   7'b0010111,
    J_type        =   7'b1101111,
    E_type        =   7'b1110011,
    //M_type        =   7'b0110011,
    Noop          =   7'b0000000,
    Atomic_type   =   7'b0101111
 }opcode_t ;   // instruction I, R, SB etc

//fsm states for compressed controller
typedef enum logic [1:0] {
    STATE0,
    STATE1,
    STATE2,
    STATE3
} fsm_state;


typedef enum logic [15:0] { 
    // NOP
    NOP,
    
    // R_type 
    ADD,  SUB,  SLL,    SLT,  SLTU,
    XOR,  SRL,  SRA,    OR,   AND,
  
    // I_type
    ADDI, SLTI, SLTIU,  XORI, ORI,
    ANDI, SLLI, SRAI,   SRLI, 

    // load 
    LB,   LH,   LW,     LBU,  LHU,

    // jump and link
    JALR, 
  
    // S_type
    SB,   SH,   SW,     
  
    // B_type 
    BEQ,  BNE,  BLT,    BGE,  BLTU,
    BGEU,
  
    // U_type 
    LUI,  AUIPC,
  
    // J_type 
    JAL,

    // E_type
    ECALL, EBREAK,

    //M type 
    MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU,

    //Atomic type 
    LR_W,   SC_W, AMOSWAP, AMOADD, AMOOR, AMOXOR, AMOAND, AMOMAX, AMOMINI,
    AMOMINU, AMOMAXU,
    //default 
    INVALID

  } instr_name_t;

typedef logic [4:0] rs1_addr_t;
typedef logic [4:0] rs2_addr_t;
typedef logic [4:0] rd_addr_t;

typedef logic [2:0] funct3_t;
typedef logic [4:0] funct5_t;
typedef logic [6:0] funct7_t;

typedef logic [11:0]  imm_I_t;
typedef logic [11:0]  imm_S_t;
typedef logic [12:0]  imm_B_t;
typedef logic [31:0]  imm_U_t;
typedef logic [20:0]  imm_J_t;



typedef struct packed {

  instr_name_t  instr_name;
  opcode_t      opcode    ;
  
  // R type 
  funct3_t      funct3    ;
  funct5_t      funct5    ;
  rs1_addr_t    rs1_addr  ;
  rs2_addr_t    rs2_addr  ;
  rd_addr_t     rd_addr   ;
  funct7_t      funct7    ;

  // I typed 
  imm_I_t       imm_I     ;

  // S typed 
  imm_S_t       imm_S     ;

  // B typed 
  imm_B_t       imm_B     ;

  // B typed 
  imm_U_t       imm_U     ;

  // J typed 
  imm_J_t       imm_J     ;
  
  
} instruction_t;



typedef logic         one_bit_t;
typedef logic [1:0]   two_bit_t;

// structure for atomic control signals 
typedef struct packed {
    one_bit_t amo_stall ;
    two_bit_t ALUSrcA   ;
    two_bit_t ALUSrcB   ;
    two_bit_t ALUOp     ;
    one_bit_t MemRead   ;
    one_bit_t MemWrite  ;
    one_bit_t regfile_rd_addr_sel   ;
    one_bit_t RegWrite  ;
    one_bit_t MemtoReg  ;
    one_bit_t dmem_wr_data_sel      ;
    two_bit_t is_sc_reg_wr         ;
}amo_controls_t;

endpackage
