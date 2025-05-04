module m_lsu(

//from store unit (not needed??) (SHOULD BE INTEGRATED SOMEHOW) edit: INTEGRATED!



//from execute stage
input logic[31:0] alu_result,
input logic[31:0] write_data,
input logic mem_rd,
input logic mem_wr,
input logic[3:0] byte_enable_in,


//from csr module (check lengths!!)
input logic [21:0] satp_ppn,
input logic	 en_vaddr,
input logic	 mxr,
input logic  tlb_flush,

input logic  en_ld_st_vaddr,
input logic  dcache_flush,
input logic	 sum,
input logic[1:0]  priv_mode, //length??

//from dbus
input logic[31:0] dbus_rdata,
input logic	dbus_ack,


//from mmu
input logic ld_page_fault,
input logic st_page_fault,
input logic[31:0] d_paddr,
input logic d_hit,

//from hzd unit
input logic  hzd2lsu_lsu_flush,


//to csr module
output logic[31:0] lsu2csr_dbus_addr,
output logic lsu2csr_ld_page_fault,
output logic lsu2csr_st_page_fault,
output logic lsu2csr_dcache_flush_or_ack,

//to hzd
output logic lsu_req,
output logic lsu_ack,

//to wb stage
output logic[31:0] r_data,


//to mmu
output logic  		lsu2mmu_satp_ppn,
output logic  		lsu2mmu_en_vaddr,
output logic  		lsu2mmu_mxr,
output logic  		lsu2mmu_tlb_flush,
output logic  		lsu2mmu_lsu_flush,
output logic  		lsu2mmu_en_ld_st_vaddr,
output logic  		lsu2mmu_dcache_flush,
output logic  		lsu2mmu_sum,
output logic[1:0] lsu2mmu_priv_mode, //length??
output logic[31:0] lsu2mmu_d_vaddr,
output logic      lsu2mmu_d_req,
output logic      lsu2mmu_st_req,

 

//to data bus
output logic[31:0] dbus_addr,				//length
output logic 		 lsu2dbus_ld_req,
output logic[3:0]	 lsu2dbus_byte_enable,
output logic 		 lsu2dbus_st_req,
output logic[31:0] lsu2dbus_W_data		//length
//also need to forward store_ops to dbus hmmmmm [DONE]


);

logic dcache_flush_req;




//use the load unit inside th lsu to sign extend the data and also produce the load ops?



//to csr
assign lsu2csr_dbus_addr = alu_result;   //alu_result is input from execute stage
assign lsu2csr_ld_page_fault = ld_page_fault;	//from mmu
assign lsu2csr_st_page_fault = st_page_fault;	//from mmu
assign lsu2csr_dcache_flush_or_ack = dbus_ack;  //from dbus
//send load_ops and st_ops to csr

//to mmu		(first 5 signals from csr)
assign  lsu2mmu_satp_ppn		= satp_ppn;
assign  lsu2mmu_en_vaddr		= en_vaddr;
assign  lsu2mmu_mxr				= mxr;
assign  lsu2mmu_tlb_flush		= tlb_flush; 
assign  lsu2mmu_en_ld_st_vaddr=en_ld_st_vaddr; 

assign  lsu2mmu_dcache_flush 	= dcache_flush;//not going to mmu in UET core?
assign  lsu2mmu_sum 				= sum;	   //Umar Ali asked from csr
assign  lsu2mmu_priv_mode		= priv_mode;// Umar Ali asked from csr

assign  lsu2mmu_lsu_flush		= hzd2lsu_lsu_flush;	//hzd unit sends the flush signal
assign  lsu2mmu_d_vaddr 		= alu_result; //from execute unit
assign  lsu2mmu_d_req         = mem_rd | mem_wr;//from execute stage
assign  lsu2mmu_st_req        = mem_wr;	//from execute stage

//local signal assignment
assign dcache_flush_req = dcache_flush; //dcache_flush | fence_req (dcache flush comes from csr module)

//to hazard unit
assign  lsu_req = mem_wr|mem_rd|dcache_flush_req;
assign  lsu_ack = dbus_ack;

//to data bus
assign lsu2dbus_W_data  = write_data; 		//write data is input from execute stage
assign dbus_addr 			= d_paddr;			//d_paddr is input from mmu
assign lsu2dbus_ld_req  = mem_rd & d_hit; //d_hit is input from mmu
assign lsu2dbus_st_req  = mem_wr & d_hit; //d_hit is input from mmu
assign lsu2dbus_byte_enable = byte_enable_in;
//send the store ops to the dbus edit: SENT edit:how exactly did I send it previously??

//to writeback stage
assign r_data = dbus_rdata;



endmodule