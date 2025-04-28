`timescale 1ns/1ps

module tb_control_unit_ZICSR;

  // DUT Inputs
  reg [6:0] Op;
  reg [2:0] funct3;
  reg [6:0] funct7;
  reg [4:0] funct5;
  reg [1:0] priv_mode;
  reg       exc_req_if2id;
  reg       exc_code_if_id;

  // DUT Outputs
  wire [1:0] ALUOp;
  wire [1:0] ALUSrcA;
  wire [1:0] ALUSrcB;
  wire [5:0] Branch;
  wire       RegWrite;
  wire [1:0] MemtoReg;
  wire       MemRead;
  wire       MemWrite;
  wire       jal;
  wire       jalr;
  wire       valid;
  wire       dmem_addr_sel;
  wire [1:0] csr_ops;
  wire [2:0] sys_ops;
  wire       exc_req;
  wire [3:0] exc_code;

  // Instantiate DUT (Device Under Test)
  m_control_unit_ZICSR dut (
    .Op(Op),
    .funct3(funct3),
    .funct7(funct7),
    .funct5(funct5),
    .priv_mode(priv_mode),
    .exc_req_if2id(exc_req_if2id),
    .exc_code_if_id(exc_code_if_id),
    .ALUOp(ALUOp),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .Branch(Branch),
    .RegWrite(RegWrite),
    .MemtoReg(MemtoReg),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .jal(jal),
    .jalr(jalr),
    .valid(valid),
    .dmem_addr_sel(dmem_addr_sel),
    .csr_ops(csr_ops),
    .sys_ops(sys_ops),
    .exc_req(exc_req),
    .exc_code(exc_code)
  );

  // Task to reset inputs
  task reset_inputs;
    begin
      Op = 7'b0;
      funct3 = 3'b0;
      funct7 = 7'b0;
      funct5 = 5'b0;
      priv_mode = 2'b0;
      exc_req_if2id = 1'b0;
      exc_code_if_id = 4'b0;
    end
  endtask

  // Display all control signals
  task display_control_signals(input string test_case_name);
    begin
      $display("\n=== %s ===", test_case_name);
      $display("ALUOp: %b | ALUSrcA: %b | ALUSrcB: %b | Branch: %b", ALUOp, ALUSrcA, ALUSrcB, Branch);
      $display("RegWrite: %b | MemtoReg: %b | MemRead: %b | MemWrite: %b", RegWrite, MemtoReg, MemRead, MemWrite);
      $display("jal: %b | jalr: %b | valid: %b | dmem_addr_sel: %b", jal, jalr, valid, dmem_addr_sel);
      $display("csr_ops: %b | sys_ops: %b | exc_req: %b | exc_code: %b\n", csr_ops, sys_ops, exc_req, exc_code);
    end
  endtask

  // Simulation Logic
  initial begin
    $dumpfile("tb_control_unit_ZICSR.vcd");  // VCD file for waveform generation
    $dumpvars(0, tb_control_unit_ZICSR);

    // Initialize inputs
    reset_inputs;

    // Test Case 1: CSRRW Instruction
    #10;
    Op = 7'b1110011; funct3 = 3'b001; funct7 = 7'b0;
    display_control_signals("Test Case 1: CSRRW Instruction");

    // Test Case 2: CSRRS Instruction
    #10;
    funct3 = 3'b010;
    display_control_signals("Test Case 2: CSRRS Instruction");

    // Test Case 3: CSRRC Instruction
    #10;
    funct3 = 3'b011;
    display_control_signals("Test Case 3: CSRRC Instruction");

    // Test Case 4: CSRIW Instruction
    #10;
    funct3 = 3'b101;
    display_control_signals("Test Case 4: CSRIW Instruction");

    // Test Case 5: ECALL Instruction
    #10;
    funct3 = 3'b000; funct7 = 7'b0000000; funct5 = 5'b00000; priv_mode = 2'b11;
    display_control_signals("Test Case 5: ECALL Instruction");

    // Test Case 6: EBREAK Instruction
    #10;
    funct5 = 5'b00001;
    display_control_signals("Test Case 6: EBREAK Instruction");

    // Test Case 7: SRET Instruction
    #10;
    funct7 = 7'b0001000; funct5 = 5'b00010;
    display_control_signals("Test Case 7: SRET Instruction");

    // Test Case 8: WFI Instruction
    #10;
    funct5 = 5'b00101;
    display_control_signals("Test Case 8: WFI Instruction");

    // Test Case 9: MRET Instruction
    #10;
    funct7 = 7'b0011000;
    display_control_signals("Test Case 9: MRET Instruction");

    // Test Case 10: Illegal Instruction
    #10;
    funct3 = 3'b111; funct7 = 7'b1111111;
    display_control_signals("Test Case 10: Illegal Instruction");

    // Finish Simulation
    #10;
    $display("Simulation Completed.");
    $finish;
  end

endmodule
