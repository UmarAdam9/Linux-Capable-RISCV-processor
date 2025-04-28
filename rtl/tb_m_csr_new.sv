`include "interface_defs2.sv"
`timescale 1ns/1ps

module tb_m_csr_new;

  // Clock and reset
  logic clk;
  logic rst;

  // Inputs
  logic [1:0] csr_ops_in;
  logic [2:0] sys_ops_in;
  logic exc_req_in;
  logic irq_req_in;
  logic csr_rd_req_in;
  logic csr_wr_req_in;
  logic fence_i_req_in;
  logic [11:0] csr_addr_in;
  logic [31:0] pc_in;
  logic [31:0] instr_in;
  logic [31:0] csr_wdata_in;
  logic [3:0] exc_code_in;
  logic instr_flushed_in;
  logic pipe_stall_in;
  logic [31:0] timer_val_low_in;
  logic [31:0] timer_val_high_in;
  logic [31:0] csr_mhartid_in;
  logic [1:0] ext_irq_in;
  logic timer_irq_in;
  logic soft_irq_in;
  logic uart_irq_in;
  
  // Custom type inputs (define these properly in your environment)
  type_LSU_to_CSR_ctrl LSU_to_CSR_ctrl_in;
  type_LSU_to_CSR_data LSU_to_CSR_data_in;

  // Outputs
  logic [31:0] csr_rdata_o;
  logic new_pc_req_o;
  logic irq_flush_lsu_o;
  logic wfi_req_o;
  logic csr_read_req_o;
  logic [1:0] priv_mode_o;
  logic [31:0] pc_new_o;
  logic irq_req_o;
  type_CSR_to_LSU_data CSR_to_LSU_data_out;
  logic [`XLEN - 1 : 0] mcause;
  logic [`XLEN - 1 : 0] mepc;
  logic [`XLEN - 1 : 0] mtval;

  // Instantiate the DUT
  m_csr_new dut (
    .rst(rst),
    .clk(clk),
    .out(),  // if you need this, connect it
    .csr_ops_in(csr_ops_in),
    .sys_ops_in(sys_ops_in),
    .exc_req_in(exc_req_in),
    .irq_req_in(irq_req_in),
    .csr_rd_req_in(csr_rd_req_in),
    .csr_wr_req_in(csr_wr_req_in),
    .fence_i_req_in(fence_i_req_in),
    .csr_addr_in(csr_addr_in),
    .pc_in(pc_in),
    .instr_in(instr_in),
    .csr_wdata_in(csr_wdata_in),
    .exc_code_in(exc_code_in),
    .instr_flushed_in(instr_flushed_in),
    .pipe_stall_in(pipe_stall_in),
    .timer_val_low_in(timer_val_low_in),
    .timer_val_high_in(timer_val_high_in),
    .csr_mhartid_in(csr_mhartid_in),
    .ext_irq_in(ext_irq_in),
    .timer_irq_in(timer_irq_in),
    .soft_irq_in(soft_irq_in),
    .uart_irq_in(uart_irq_in),
    .LSU_to_CSR_ctrl_in(LSU_to_CSR_ctrl_in),
    .LSU_to_CSR_data_in(LSU_to_CSR_data_in),
    .csr_rdata_o(csr_rdata_o),
    .new_pc_req_o(new_pc_req_o),
    .irq_flush_lsu_o(irq_flush_lsu_o),
    .wfi_req_o(wfi_req_o),
    .csr_read_req_o(csr_read_req_o),
    .priv_mode_o(priv_mode_o),
    .pc_new_o(pc_new_o),
    .irq_req_o(irq_req_o),
    .CSR_to_LSU_data_out(CSR_to_LSU_data_out),
    .mcause_o(mcause),
	 .mepc_o(mepc),
	 .mtval_o(mtval)
  );

  // Clock generator
  always #5 clk = ~clk;

initial begin
  // === Reset ===
  clk = 0;
  rst = 1;
  #20;
  rst = 0;

  // === Set constant/default inputs ===
  fence_i_req_in      = 0;
  instr_flushed_in    = 0;
  pc_in               = 0;
  instr_in            = 0;
  exc_code_in         = 0;
  pipe_stall_in       = 0;
  timer_val_low_in    = 0;
  timer_val_high_in   = 0;
  csr_mhartid_in      = 0;
  ext_irq_in          = 0;
  timer_irq_in        = 0;
  soft_irq_in         = 0;
  uart_irq_in         = 0;
  LSU_to_CSR_ctrl_in  = '{default: '0};
  LSU_to_CSR_data_in  = '{default: '0};

  // ========== Phase 1: WRITE to CSRs ==========

  // mscratch (0x340)
  csr_ops_in      = 2'b01;
  sys_ops_in      = 3'b000;
  exc_req_in      = 0;
  irq_req_in      = 0;
  csr_rd_req_in   = 0;
  csr_wr_req_in   = 1;
  csr_addr_in     = 12'h340;
  csr_wdata_in    = 32'h11112222;
  #10;

  // mstatus (0x300)
  csr_addr_in     = 12'h300;
  csr_wdata_in    = 32'h00001800;
  #10;

  // mip (0x344) — only SSIP is writable (bit 1)
  csr_addr_in     = 12'h344;
  csr_wdata_in    = 32'h00000002;
  #10;

  // mie (0x304)
  csr_addr_in     = 12'h304;
  csr_wdata_in    = 32'h00000888;
  #10;

  // medeleg (0x302)
  csr_addr_in     = 12'h302;
  csr_wdata_in    = 32'h0000FFFF;
  #10;

  // mtvec (0x305)
  csr_addr_in     = 12'h305;
  csr_wdata_in    = 32'h00002000;
  #10;

  // mtval (0x343)
  csr_addr_in     = 12'h343;
  csr_wdata_in    = 32'hDEADBEEF;
  #10;

  // ========== Phase 2: READ from CSRs ==========

  csr_ops_in      = 2'b00;
  csr_wr_req_in   = 0;
  csr_rd_req_in   = 1;

  csr_addr_in     = 12'h340;  #10; $display("[Time %0t] CSR[mscratch] = %h", $time, csr_rdata_o);
  csr_addr_in     = 12'h300;  #10; $display("[Time %0t] CSR[mstatus]  = %h", $time, csr_rdata_o);
  csr_addr_in     = 12'h344;  #10; $display("[Time %0t] CSR[mip]      = %h", $time, csr_rdata_o);
  csr_addr_in     = 12'h304;  #10; $display("[Time %0t] CSR[mie]      = %h", $time, csr_rdata_o);
  csr_addr_in     = 12'h302;  #10; $display("[Time %0t] CSR[medeleg]  = %h", $time, csr_rdata_o);
  csr_addr_in     = 12'h305;  #10; $display("[Time %0t] CSR[mtvec]    = %h", $time, csr_rdata_o);
  csr_addr_in     = 12'h343;  #10; $display("[Time %0t] CSR[mtval]    = %h", $time, csr_rdata_o);
  
  
   // ========== Phase 3: Trigger an Exception ==========

  // Simulate exception request: instruction access fault (exc_code = 1)
  csr_ops_in      = 2'b00;       // No specific CSR op
  sys_ops_in      = 3'b000;
  exc_req_in      = 1;
  irq_req_in      = 0;
  csr_rd_req_in   = 0;
  csr_wr_req_in   = 0;
  instr_flushed_in = 0;
  exc_code_in     = 4'd12;        // Exception code: instruction page fault
  pc_in           = 32'h0000ABCD; // PC at time of exception
  instr_in        = 32'hDEADC0DE; // Faulting instruction

  #20;

  // ========== Phase 4: Read Exception-Related CSRs ==========

  csr_ops_in      = 2'b00;
  csr_rd_req_in   = 1;
  csr_wr_req_in   = 0;
  exc_req_in      = 0;

  csr_addr_in     = 12'h341;  #10; $display("[Time %0t] CSR[mepc]    = %h", $time, csr_rdata_o);
  csr_addr_in     = 12'h342;  #10; $display("[Time %0t] CSR[mcause]  = %h", $time, csr_rdata_o);
  csr_addr_in     = 12'h343;  #10; $display("[Time %0t] CSR[mtval]   = %h", $time, csr_rdata_o);

  $finish;
end




endmodule
