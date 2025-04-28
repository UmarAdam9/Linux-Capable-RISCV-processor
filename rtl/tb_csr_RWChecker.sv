`timescale 1ns/1ps

module tb_csr_RWChecker;

  // Inputs
  reg [31:0] instruction;
  reg [31:0] immediate; // Not used in the current logic
  reg [1:0] csr_ops;
  reg       RegWrite_id2exe;

  // Outputs
  wire csr_rd_req;
  wire csr_wr_req;
  wire RegWrite;

  // Instantiate the DUT (Device Under Test)
  m_csr_RWChecker dut (
    .instruction(instruction),
    .immediate(immediate),
    .csr_ops(csr_ops),
    .RegWrite_id2exe(RegWrite_id2exe),
    .csr_rd_req(csr_rd_req),
    .csr_wr_req(csr_wr_req),
    .RegWrite(RegWrite)
  );

  // Task to reset inputs
  task reset_inputs;
    begin
      instruction = 32'h0;
      immediate = 32'h0;
      csr_ops = 2'b00;
      RegWrite_id2exe = 1'b0;
    end
  endtask

  // Simulation logic
  initial begin
    $dumpfile("tb_csr_RWChecker.vcd"); // For waveform generation
    $dumpvars(0, tb_csr_RWChecker);

    // Reset all inputs
    reset_inputs;

    // Test Case 1: CSR_OPS_WRITE, valid rd
    #10;
    csr_ops = 2'b01; // CSR_OPS_WRITE
    instruction = 32'h00100093; // rd = x1 (valid), rs1 = x0
    #1; // Allow outputs to settle
    $display("Test Case 1: CSR_OPS_WRITE with valid rd");
    $display("csr_rd_req = %b, csr_wr_req = %b, RegWrite = %b (Expected: csr_rd_req = 1, csr_wr_req = 1, RegWrite = 1)", csr_rd_req, csr_wr_req, RegWrite);

    // Test Case 2: CSR_OPS_WRITE, rd = 0
    #10;
    instruction = 32'h00000093; // rd = x0, rs1 = x0
    #1;
    $display("Test Case 2: CSR_OPS_WRITE with rd = 0");
    $display("csr_rd_req = %b, csr_wr_req = %b, RegWrite = %b (Expected: csr_rd_req = 0, csr_wr_req = 1, RegWrite = 0)", csr_rd_req, csr_wr_req, RegWrite);

    // Test Case 3: CSR_OPS_SET, valid rs1
    #10;
    csr_ops = 2'b10; // CSR_OPS_SET
    instruction = 32'h00028093; // rs1 = x5 (valid), rd = x1 (valid)
    #1;
    $display("Test Case 3: CSR_OPS_SET with valid rs1");
    $display("csr_rd_req = %b, csr_wr_req = %b, RegWrite = %b (Expected: csr_rd_req = 1, csr_wr_req = 1, RegWrite = 1)", csr_rd_req, csr_wr_req, RegWrite);

    // Test Case 4: CSR_OPS_SET, rs1 = 0
    #10;
    instruction = 32'h00008093; // rs1 = x0, rd = x1
    #1;
    $display("Test Case 4: CSR_OPS_SET with rs1 = 0");
    $display("csr_rd_req = %b, csr_wr_req = %b, RegWrite = %b (Expected: csr_rd_req = 1, csr_wr_req = 0, RegWrite = 1)", csr_rd_req, csr_wr_req, RegWrite);

    // Test Case 5: CSR_OPS_SET, rd = 0
    #10;
    instruction = 32'h00020013; // rs1 = x5 (valid), rd = x0
    #1;
    $display("Test Case 5: CSR_OPS_SET with rd = 0");
    $display("csr_rd_req = %b, csr_wr_req = %b, RegWrite = %b (Expected: csr_rd_req = 1, csr_wr_req = 1, RegWrite = 0)", csr_rd_req, csr_wr_req, RegWrite);

    // Test Case 6: CSR_OPS_CLEAR, rs1 = 0, rd = valid
    #10;
    csr_ops = 2'b11; // CSR_OPS_CLEAR
    instruction = 32'h00008093; // rs1 = x0, rd = x1
    #1;
    $display("Test Case 6: CSR_OPS_CLEAR with rs1 = 0, rd valid");
    $display("csr_rd_req = %b, csr_wr_req = %b, RegWrite = %b (Expected: csr_rd_req = 1, csr_wr_req = 0, RegWrite = 1)", csr_rd_req, csr_wr_req, RegWrite);

    // Test Case 7: CSR_OPS_NONE
    #10;
    csr_ops = 2'b00; // CSR_OPS_NONE
    RegWrite_id2exe = 1'b1; // Pass-through
    #1;
    $display("Test Case 7: CSR_OPS_NONE");
    $display("csr_rd_req = %b, csr_wr_req = %b, RegWrite = %b (Expected: csr_rd_req = 0, csr_wr_req = 0, RegWrite = 1)", csr_rd_req, csr_wr_req, RegWrite);

    // Finish simulation
    #10;
    $display("Simulation completed.");
    $finish;
  end

endmodule
