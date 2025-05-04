module m_instruction_fetcher(

//from pc
input logic[31:0]  pc_addr_in,
//from hzd unit
input logic 		 if_stall_in,
input logic			 csr_pc_req_in,
input logic			 exe_pc_req_in,

//from mmu 
input logic[31:0]	 i_paddr,

//TO mmu AND hazd unit
output logic		 i_req,
//To mmu
output logic[31:0] i_vaddr,
output logic 		 i_kill,

//To decode stage
output logic[31:0] instruction_o




);



assign i_req = !if_stall_in;
assign instruction_o=i_paddr;
assign i_kill = csr_pc_req_in | exe_pc_req_in;

always_comb begin

if(!if_stall_in)
	i_vaddr = pc_addr_in;
else
	i_vaddr = '0;


end



endmodule