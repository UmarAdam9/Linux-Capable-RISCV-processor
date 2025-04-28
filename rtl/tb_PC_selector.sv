`timescale 1ns/1ps

module tb_PC_selector;

  // DUT Inputs
  reg csr_new_pc_req;
  reg exe_new_pc_req;
  reg wfi_req;
  reg [31:0] csr_new_pc;
  reg [31:0] pc_plus_4;
  reg [31:0] pc_ff; // Not used in DUT but defined for completeness
  reg [31:0] exe_new_pc;

  // DUT Outputs
  wire [31:0] pc_next;

  // Instantiate the DUT
  m_PC_selector dut (
    .csr_new_pc_req(csr_new_pc_req),
    .exe_new_pc_req(exe_new_pc_req),
    .wfi_req(wfi_req),
    .csr_new_pc(csr_new_pc),
    .pc_plus_4(pc_plus_4),
    .pc_ff(pc_ff), // Doesn't affect pc_next
    .exe_new_pc(exe_new_pc),
    .pc_next(pc_next)
  );

  // Task to reset all inputs
  task reset_inputs;
    begin
      csr_new_pc_req = 0;
      exe_new_pc_req = 0;
      wfi_req = 0;
      csr_new_pc = 32'h00000000;
      pc_plus_4 = 32'h00000000;
      pc_ff = 32'h00000000;
      exe_new_pc = 32'h00000000;
    end
  endtask

  // Simulation Logic
  initial begin
    $dumpfile("tb_PC_selector.vcd");  // For waveform generation
    $dumpvars(0, tb_PC_selector);

    // Initialize Inputs
    reset_inputs;

    // Test Case 1: Default behavior (pc_next = pc_plus_4)
    #10;
    pc_plus_4 = 32'h00000010; // Expected pc_next = 0x00000010
    $display("Test Case 1: Default behavior");
    $display("pc_next = %h (Expected: %h)", pc_next, pc_plus_4);

    // Test Case 2: csr_new_pc_req = 1
    #10;
    csr_new_pc_req = 1;
    csr_new_pc = 32'h00000020; // Expected pc_next = 0x00000020
    $display("Test Case 2: csr_new_pc_req = 1");
    $display("pc_next = %h (Expected: %h)", pc_next, csr_new_pc);

    // Test Case 3: wfi_req = 1
    #10;
    csr_new_pc_req = 0; // Reset previous request
    wfi_req = 1;
    csr_new_pc = 32'h00000030; // Expected pc_next = 0x00000030
    $display("Test Case 3: wfi_req = 1");
    $display("pc_next = %h (Expected: %h)", pc_next, csr_new_pc);

    // Test Case 4: exe_new_pc_req = 1
    #10;
    wfi_req = 0; // Reset previous request
    exe_new_pc_req = 1;
    exe_new_pc = 32'h00000040; // Expected pc_next = 0x00000040
    $display("Test Case 4: exe_new_pc_req = 1");
    $display("pc_next = %h (Expected: %h)", pc_next, exe_new_pc);

    // Test Case 5: Multiple requests (csr_new_pc_req has priority)
    #10;
    csr_new_pc_req = 1;
    exe_new_pc_req = 1; // Both requests are active; csr_new_pc_req should take priority
    csr_new_pc = 32'h00000050;
    exe_new_pc = 32'h00000060;
    $display("Test Case 5: Multiple requests (csr_new_pc_req priority)");
    $display("pc_next = %h (Expected: %h)", pc_next, csr_new_pc);

    // Finish simulation
    #10;
    $display("Simulation completed.");
    $finish;
  end

endmodule
