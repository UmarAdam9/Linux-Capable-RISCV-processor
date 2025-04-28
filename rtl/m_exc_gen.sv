module	m_exc_gen(


input 		clk,
input       rst, 
input			[31:0]instruction,  //not needed??
input 		[31:0]pc,
input			csr_new_pc_req, //from the forward stall unit
input 		exe_new_pc_req, //from the forward stall unit
input 		wfi_req,        //from the forward stall unit
input 		if_stall,		//from the forward stall unit
input 		i_page_fault,   //from the MMU







output 		   exc_req_o,
output  [3:0]  exc_code_o




);

//local signals
logic		pc_misaligned;
logic		exc_req_ff , exc_req_next;
logic		[3:0]exc_code_ff , exc_code_next;

parameter EXC_CODE_NO_EXCEPTION    = 4'd14;
parameter EXC_CODE_INSTR_MISALIGN  = 4'd0 ;
parameter EXC_CODE_INST_PAGE_FAULT = 4'd12;




assign pc_misaligned = pc[1] | pc[0]; //pc_misaligned request


always_ff @(posedge clk) begin	//update the flip flop states
    if (rst) begin
        exc_req_ff  <= '0; 
        exc_code_ff <= EXC_CODE_NO_EXCEPTION;
    end else begin
        exc_req_ff  <= exc_req_next;
        exc_code_ff <= exc_code_next;
    end
end


always_comb begin
exc_req_next   = exc_req_ff;
exc_code_next  = exc_code_ff;
   
    if (csr_new_pc_req | exe_new_pc_req | wfi_req | (~if_stall & exc_req_ff)) begin    
        exc_req_next  = 1'b0;
        exc_code_next = EXC_CODE_NO_EXCEPTION;
    end else if (pc_misaligned) begin
        exc_req_next  = 1'b1;
        exc_code_next = EXC_CODE_INSTR_MISALIGN; 
    end else if (i_page_fault & ~exc_req_ff) begin
        exc_req_next   = 1'b1;
        exc_code_next  = EXC_CODE_INST_PAGE_FAULT; 
    end 

    // TODO : Deal with instruction access fault as well (EXC_CODE_INSTR_ACCESS_FAULT) for that 
    // purpose need a separate signal from MMU
end


assign exc_req_o  = exc_req_next;
assign exc_code_o = exc_code_next;






endmodule