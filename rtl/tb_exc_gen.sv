`timescale 1ns/1ps

module tb_exc_gen;

  // Inputs
  reg clk;
  reg rst;
  reg [31:0] instruction;
  reg [31:0] pc;
  reg csr_new_pc_req;
  reg exe_new_pc_req;
  reg wfi_req;
  reg if_stall;
  reg i_page_fault;

  // Outputs
  wire exc_req_o;
  wire [3:0] exc_code_o;

  // Instantiate the DUT (Device Under Test)
  m_exc_gen dut (
    .clk(clk),
    .rst(rst),
    .instruction(instruction),
    .pc(pc),
    .csr_new_pc_req(csr_new_pc_req),
    .exe_new_pc_req(exe_new_pc_req),
    .wfi_req(wfi_req),
    .if_stall(if_stall),
    .i_page_fault(i_page_fault),
    .exc_req_o(exc_req_o),
    .exc_code_o(exc_code_o)
  );

  // Clock generation
  always #5 clk = ~clk; // 10ns clock period

  // Simulation logic
  initial begin
    $dumpfile("tb_exc_gen.vcd"); // For waveform generation
    $dumpvars(0, tb_exc_gen);

    // Initialize clock and reset
    clk = 0;
    rst = 1;

    // Apply reset for the first clock cycle
    #10;
    rst = 0;

    // Let the simulation run for a few clock cycles
    #100;
    $display("Simulation completed.");
    $finish;
  end

  // Input changing logic on every positive clock edge
  always @(posedge clk) begin
    if (rst) begin
      // Reset all inputs during reset
      instruction <= 32'h0;
      pc <= 32'h0;
      csr_new_pc_req <= 1'b0;
      exe_new_pc_req <= 1'b0;
      wfi_req <= 1'b0;
      if_stall <= 1'b0;
      i_page_fault <= 1'b0;
    end else begin
      // Change inputs dynamically with each clock edge
      instruction <= instruction + 1;      // Increment instruction address (mock behavior)
      pc <= pc + 1;                        // Increment PC by 4 (standard step size)

      case (pc[3:0])                       // Simulate varying conditions based on PC
        4'h0: begin
          csr_new_pc_req <= 1'b0;
          exe_new_pc_req <= 1'b0;
          wfi_req <= 1'b0;
          if_stall <= 1'b0;
          i_page_fault <= 1'b0;            // No exception
        end
        4'h4: begin
          csr_new_pc_req <= 1'b1;          // CSR new PC request
          exe_new_pc_req <= 1'b0;
          wfi_req <= 1'b0;
          if_stall <= 1'b0;
          i_page_fault <= 1'b0;
        end
        4'h8: begin
          csr_new_pc_req <= 1'b0;
          exe_new_pc_req <= 1'b1;          // Execution new PC request
          wfi_req <= 1'b0;
          if_stall <= 1'b0;
          i_page_fault <= 1'b0;
        end
        4'hC: begin
          csr_new_pc_req <= 1'b0;
          exe_new_pc_req <= 1'b0;
          wfi_req <= 1'b1;                 // WFI request
          if_stall <= 1'b0;
          i_page_fault <= 1'b0;
        end
        4'hF: begin
          csr_new_pc_req <= 1'b0;
          exe_new_pc_req <= 1'b0;
          wfi_req <= 1'b0;
          if_stall <= 1'b1;                // Stall condition
          i_page_fault <= 1'b0;
        end
        default: begin
          csr_new_pc_req <= 1'b0;
          exe_new_pc_req <= 1'b0;
          wfi_req <= 1'b0;
          if_stall <= 1'b0;
          i_page_fault <= 1'b1;            // Instruction page fault
        end
      endcase
    end
  end

  // Display outputs on every positive clock edge
  always @(posedge clk) begin
    if (!rst) begin
      $display("Time: %t | pc = 0x%h | exc_req_o = %b | exc_code_o = %d | csr_new_pc_req = %b | exe_new_pc_req = %b | wfi_req = %b | if_stall = %b | i_page_fault = %b",
        $time, pc, exc_req_o, exc_code_o, csr_new_pc_req, exe_new_pc_req, wfi_req, if_stall, i_page_fault);
    end
  end

endmodule
