`include "interface_defs2.sv"

module m_csr_new (

input logic rst,
input logic clk,



//inputs from other units ===========================

//EXECUTE unit <---> CSR  
input [1:0]							csr_ops_in,			//check the width
input [2:0]							sys_ops_in,			//check the width
input									exc_req_in,
input									irq_req_in,
input                         csr_rd_req_in,
input                         csr_wr_req_in,
input                         fence_i_req_in,

input [11:0]						csr_addr_in,		//check the length
input [31:0] 						pc_in,
input [31:0]						instr_in,
input [31:0]						csr_wdata_in,
input [3:0]							exc_code_in,		//check the length
input								   instr_flushed_in,






//HZD <---> CSR unit 
input									 pipe_stall_in,


//CLINT <---> CSR 
input [31:0]                timer_val_low_in, 
input [31:0]                timer_val_high_in,  


//SOC <---> CSR  
input [31:0]                	 csr_mhartid_in,                           
input [1:0]                      ext_irq_in,  
input                            timer_irq_in,  
input                            soft_irq_in,
input                            uart_irq_in,   




//LSU <---> CSR 
input [31:0]							dbus_addr_in,
input logic								ld_page_fault_in,
input logic								st_page_fault_in,
input logic[31:0]						pc_next_in,		//why is this coming from the lsu
input logic 							dcache_flush_ack_in,




//outputs to other units===========================

//CSR <---> WRITE_BACK  
output reg [`XLEN-1:0]                	csr_rdata_o,  


//CSR <---> HZD
output logic                          new_pc_req_o, 
output logic                          irq_flush_lsu_o,
output logic                          wfi_req_o,
output                                csr_read_req_o,
	

//CSR <---> DECODE unit feedback 
output logic[1:0]						priv_mode_o,

//CSR <---> FETCH unit feedback
output logic [31:0]                pc_new_o,
//output logic                       irq_req_o,
output logic							  icache_flush_o,
		



//CSR <---> LSU unit
output logic  			satp_ppn,
output logic		   en_vaddr,
output logic			mxr,
output logic  			tlb_flush,

output logic  			en_ld_st_vaddr,
output logic  			dcache_flush,
output logic	 		sum,
output logic[1:0]  	priv_mode_to_lsu, //length??
output logic 			lsu_flush,		//useless? yup its being handled in the hazard unit



//debug
output logic [`XLEN -1 : 0]						mcause_o,
output logic [`XLEN -1 : 0]						mepc_o,
output logic [`XLEN -1 : 0]						mtval_o

 
);





















//==========================//README//========================================//

// Step 0: create structs for input and output from various modules

// Step 1: CSR read operation
				//simple enough

//	Step 2: CSR write operation
				//meat of the module

// Step 3: output to FETCH module through feedback

		//pc_new 		-> the new pc value to the fetch module to jump to
		
		//icache_flush -> flush the icache
		//						QUESTION:what does it do?
		//						ANSWER  :FETCH module sends this signal to the icache directly 
		
		//irq_req 		-> FETCH module uses this and sets its own irq_req_next signal to one if its own irq_req_ff is currently 0
		//				 		QUESTION: why would FETCH module need irq_req signal?
		//				 		ANSWER  : to set the instruction word to No_OP 
						 

//	Step 4: output to DECODE module through feedback

		//priv_mode		->based on priv_mode ECALL instruction will cause the DECODE module to generate one of three exception codes
		//					  EXC_CODE_ECALL_MMODE ,EXC_CODE_ECALL_SMODE ,EXC_CODE_ECALL_UMODE




// Step 5: output to HZD module
		//new_pc_req	
		
		//irq_flush_lsu
		
		//wfi_req
		
		//csr_read_req	->To resolve hazards (need to investigate exactly how )

// Step 6: output to LSU module

// Step 7: output to WB module

		//csr_rdata    ->simple enough no complications needed




//==========================//README END//====================================//







		//signals for reading CSRs

		logic [`XLEN-1:0]                csr_rdata; 		//read value will be stored here
		logic                            csr_rd_exc_req; //is there an exception request on reading the csr?


		//CSR  definitions  */the bitfields and the types are defined in the interface_defs file/*

		// Privilge mode definition 
		logic[1:0]                 priv_mode_ff, priv_mode_next; //EDITED
		logic[1:0]                 trap_priv_mode; //EDITED

		// CSR cycle, instruction retire and other counter register definitions
		logic [`XLEN-1:0]                csr_mcycle_ff,  csr_mcycle_next;
		logic [`XLEN-1:0]                csr_mcycleh_ff,  csr_mcycleh_next;
		logic [`XLEN-1:0]                csr_minstret_ff,  csr_minstret_next;
		logic [`XLEN-1:0]                csr_minstreth_ff,  csr_minstreth_next;
		logic [`XLEN-1:0]                csr_mcounteren_ff,  csr_mcounteren_next;
		type_mcountinhibit_reg_s         csr_mcountinhibit_ff,  csr_mcountinhibit_next; 

		// Machine mode CSRs for trap setup
		type_status_reg_s                csr_mstatus_ff,  csr_mstatus_next;
		logic [`XLEN-1:0]                csr_medeleg_ff,  csr_medeleg_next;
		logic [`XLEN-1:0]                csr_mideleg_ff,  csr_mideleg_next;
		type_mie_reg_s                   csr_mie_ff,      csr_mie_next;
		type_tvec_reg_s                  csr_mtvec_ff,    csr_mtvec_next;

		// Machine mode CSRs for trap handling
		logic [`XLEN-1:0]                csr_mscratch_ff, csr_mscratch_next;
		logic [`XLEN-1:0]                csr_mepc_ff,     csr_mepc_next;
		logic [`XLEN-1:0]                csr_mcause_ff,   csr_mcause_next;
		logic [`XLEN-1:0]                csr_mtval_ff,    csr_mtval_next;
		type_mip_reg_s                   csr_mip_ff,      csr_mip_next;

		// Supervisor mode CSRs for trap setup and handling 
		type_tvec_reg_s                  csr_stvec_ff,    csr_stvec_next; 
		logic [`XLEN-1:0]                csr_sscratch_ff, csr_sscratch_next;
		logic [`XLEN-1:0]                csr_sepc_ff,     csr_sepc_next;
		logic [`XLEN-1:0]                csr_scause_ff,   csr_scause_next;
		logic [`XLEN-1:0]                csr_stval_ff,    csr_stval_next;
		type_satp_reg_s                  csr_satp_ff,     csr_satp_next;
		logic [`XLEN-1:0]                csr_scounteren_ff,  csr_scounteren_next;




//=========================== Set exception and interrupt signals depending upon the inputs to CSR=======================//



		//all the Interrupt  related signals======================

		type_irq_code_e             irq_code;  //the current interrupt code

		logic 		is_m_irq_req;				//machine interrupt request , it is set based on meip OR mtip OR msip
		logic		meip_irq_req,	mtip_irq_req ,msip_irq_req; //the meip , mtip and msip signals

		//logic 		irq_req;					//set if irq_req is coming from execute unit(originally from the fetch stage that the csr feeds back to it)  OR if there is a supervisor interrupt request
													//why is this exluding machine mode interrupt request?
													
		logic 		m_mode_global_ie; 	//global interrupt enable bit 

		logic 		irq_req_sync;			//this is set if there is a machine interrupt request AND m_mode_global_ie is ON
													//I dont know what the "sync" means exactly, i guess it can be called irq_req_confirmed??

		logic 		irq_delegated_req;	//checks the mideleg csr to see if interrupts can be handled in supervisor mode
											
		logic			serve_m_irq_req;   	//serve_m_irq_req request
													//enabled when there is irq_req AND irq is NOT delegated AND serve_m_irq_req is ON


		logic 		is_s_irq_req;				//supervisor interrupt request , it is set based on seip OR stip OR ssip 		
		logic 		seip_irq_req,	stip_irq_req ,ssip_irq_req;//the seip , stip and ssip signals

		logic			s_mode_global_ie;

		logic 	   serve_s_irq_req;

		logic		   ext_irq0_ff;
		logic		   ext_irq1_ff;
		logic			timer_irq_ff;


									
//all the Exception related signals=========================================
									
		//logic 	csr_rd_exc_req is already initialized
		logic[3:0] 					exc_code;			
		logic 						ld_pf_exc_req;
		logic							st_pf_exc_req;
		
		logic						i_pf_exc_req ;
		
		logic						csr_exc_req;
		logic  					csr_wr_exc_req;
		logic						csr_satp_exc_req;
		 
		 
		logic						ld_misalign_exc_req;		//implement this!
		logic						st_misalign_exc_req;		//implement this!!
		
		logic						exc_req;
		
		logic						serve_m_exc_req;
		logic						serve_s_exc_req;
		
		logic						exc_delegated_req;
	

		//all the system instructions variables


		//CSR PC to store the pc value that updates mepc
		//logic [`XLEN-1:0]                csr_pc_ff, csr_pc_next; 


		//the pc is set depending upon the system operation (SRET , MRET , WFI and SFENCE_VMA)
													//do I even need these variables? or are they just cluttering the code?

		logic 		sret_req;
		logic 		mret_req;
		logic			wfi_req;
		logic			sfence_vma_req;
		logic 		fence_i_req;		//implement thisssss!!!!



		logic			serve_mret_pc_req;  //	UA : will eventually do away with this cluttering
		logic 		serve_sret_pc_req;  

		logic [`XLEN-1:0]  		m_mode_new_pc;			//will contain the pc to jump to after checking what kind of m_mode "request" is set (mret_req, m_exc_req or m_irq_req)
		logic [`XLEN-1:0] 		s_mode_new_pc;


		logic       serve_m_mode_pc_req;	// determines if the fetch module should use m_mode_new_pc or not 
		logic       serve_s_mode_pc_req;


		logic			icache_flush_req; //icache is flushed when there is a fence instruction and there is data_cache_flush_ack from lsu
		logic 		csr_vaddr_iflush_req;// if satp is written (page table is updated or icache is flushed, then jump to the next_pc which came from the FETCH unit)


		logic       wfi_ff , wfi_next;	//the wfi flip flop and next stage logic that keeps track of wfi instruction
												//the wfi_next will be used in the logic that will be sent to Hazard unit to stall the pipeline


		
		
	
		logic [`XLEN-1:0]     csr_wdata; 		//the data that will be written into the csr 
														//after some modification (SET,CLEAR OR WRITE)





		//the write flag initializations
		// Machine mode CSR write update flags for cycle and performance counter registers 
		logic                            csr_mcycle_wr_flag;
		logic                            csr_mcycleh_wr_flag;
		logic                            csr_minstret_wr_flag;
		logic                            csr_minstreth_wr_flag;
		logic                            csr_mcounteren_wr_flag;
		logic                            csr_mcountinhibit_wr_flag;

		// Machine mode CSR write update flags for trap setup and handling registers
		logic                            csr_mstatus_wr_flag;
		logic                            csr_medeleg_wr_flag;
		logic                            csr_mideleg_wr_flag;
		logic                            csr_mie_wr_flag;
		logic                            csr_mtvec_wr_flag;
		logic                            csr_mscratch_wr_flag;
		logic                            csr_mepc_wr_flag;
		logic                            csr_mcause_wr_flag;
		logic                            csr_mtval_wr_flag;
		logic                            csr_mip_wr_flag;

		// Supervisor mode CSR write update flags for trap setup and handling registers
		logic                            csr_sstatus_wr_flag;
		logic                            csr_sscratch_wr_flag;
		logic                            csr_sie_wr_flag;
		logic                            csr_stvec_wr_flag;
		logic                            csr_sepc_wr_flag;
		logic                            csr_scause_wr_flag;
		logic                            csr_stval_wr_flag;
		logic                            csr_sip_wr_flag;
		logic                            csr_satp_wr_flag;
		logic                            csr_scounteren_wr_flag;	
		
	
	
		logic is_not_ecall;
		logic is_not_ebreak;
		logic csr_minstret_inc;
		logic pipe_stall_flush;  //incase the pipeline is flushed or stalled
	
	
		logic en_ld_st_vaddr_ff , en_ld_st_vaddr_next; // how does this work?
		
		logic[31:0]							ld_st_addr;
		logic [6:0] 						opcode;
		
		
		
		


	
		assign ld_st_addr = dbus_addr_in;
		
		//check if its a load instruction and generate ld_misalign req
		//check if its a store instruction and generate st_misalign req
		
	always_comb begin
		  ld_misalign_exc_req = 1'b0;
		  st_misalign_exc_req = 1'b0;

		  
		  opcode = instr_in[6:0];   // RISC-V opcode is bits [6:0]

		  case (opcode)
			 7'b0000011: begin  // Load instructions
				case (instr_in[14:12])  // funct3 field
				  3'b000: ; // LB — no alignment needed
				  3'b001: begin // LH
					 if (ld_st_addr[0] != 1'b0)
						ld_misalign_exc_req = 1'b1;
				  end
				  3'b010: begin // LW
					 if (ld_st_addr[1:0] != 2'b00)
						ld_misalign_exc_req = 1'b1;
				  end
				  3'b100: ; // LBU — no alignment needed
				  3'b101: begin // LHU
					 if (ld_st_addr[0] != 1'b0)
						ld_misalign_exc_req = 1'b1;
				  end
				  default: ;
				endcase
			 end

			 7'b0100011: begin  // Store instructions
				case (instr_in[14:12])  // funct3 field
				  3'b000: ; // SB — no alignment needed
				  3'b001: begin // SH
					 if (ld_st_addr[0] != 1'b0)
						st_misalign_exc_req = 1'b1;
				  end
				  3'b010: begin // SW
					 if (ld_st_addr[1:0] != 2'b00)
						st_misalign_exc_req = 1'b1;
				  end
				  default: ;
				endcase
			 end

			 default: ;
  endcase
end

	

	
	
	
	
	
	
	
	
	
	
	
	


	
	assign icache_flush_req    =  fence_i_req & dcache_flush_ack_in;	//ask Umer Ali about dcache_flush_ack_in
	assign csr_vaddr_iflush_req =  csr_satp_wr_flag | icache_flush_req; // | sfence_vma_req	ask Umer Ali about this as well
	
	assign icache_flush_o = icache_flush_req;
	
	
	
	
	
	
	
	
	
//================================== CSR read operation ==================================//
always_comb begin

	csr_rdata = {`XLEN{1'b1}};
	csr_rd_exc_req = 1'b0;
	
	if(csr_rd_req_in  | csr_wr_req_in  ) begin  
													//if there is a read request then assign the value of csr to csr_rdata that corresponds to the csr_addr
													//the reason for also checking write request is because during a csr update
													//the current value of the csr has to be read  for SET and CLEAR operations
		case(csr_addr_in)
		
			// Machine information registers (read-only)
			
			CSR_ADDR_MVENDORID: begin
			
				if(priv_mode_ff !== PRIV_MODE_M)
					begin
						csr_rd_exc_req  = 1'b1; 
					end
				else	
					begin
						csr_rdata =	`NUST_MVENDORID;
					
					end
				
			
										end
			
			CSR_ADDR_MARCHID:	  begin
			
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	`CORE_MARCHID;
						
						end
			
			
									  end
									  
			CSR_ADDR_MHARTID:	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	'0;
						
						end
			
			
										end

		
		
		
		
		
		
			
			
			 // Read machine mode trap setup registers
			 CSR_ADDR_MSTATUS:	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_mstatus_ff;
						
						end
			
			
										end
										
			 CSR_ADDR_MISA:	     begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	`CSR_MISA;
						
						end
			
			
										end
										
					
			 CSR_ADDR_MEDELEG:	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_medeleg_ff;
						
						end
			
			
										end
				
				
			 CSR_ADDR_MIDELEG:	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_mideleg_ff;
						
						end
			
			
										end
										
			 CSR_ADDR_MIE:	  		  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_mie_ff;
						
						end
			
			
										end
										
			
			 CSR_ADDR_MTVEC:	 	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_mtvec_ff;
						
						end
			
			
										end
										
				


			 CSR_ADDR_MSCRATCH:	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_mscratch_ff;
						
						end
			
			
										end
										
		    CSR_ADDR_MEPC:	  	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_mepc_ff;
						
						end
			
			
										end
										
										
			 CSR_ADDR_MCAUSE:	  	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_mcause_ff;
						
						end
			
			
										end
			
			 CSR_ADDR_MTVAL:	     begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_mtval_ff;
						
						end
			
			
										end
										
			 CSR_ADDR_MIP:	  		  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M)
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_mip_ff;
						
						end
			
			
										end
										
			
			  // Read supervisor mode trap setup and handling registers
			  CSR_ADDR_SSTATUS:	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M && priv_mode_ff !== PRIV_MODE_S )
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	(csr_mstatus_ff & SSTATUS_READ_MASK);
						
						end
			
			
										end
										
			  CSR_ADDR_SIE:	  	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M && priv_mode_ff !== PRIV_MODE_S )
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_mie_ff & SIE_MASK;
						
						end
			
			
										end
										
										
			  CSR_ADDR_SSCRATCH:	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M && priv_mode_ff !== PRIV_MODE_S )
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_sscratch_ff;
						
						end
			
			
										end
										
										
			  CSR_ADDR_STVEC:	  	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M && priv_mode_ff !== PRIV_MODE_S )
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_stvec_ff;
						
						end
			
			
										end
								
			
			  CSR_ADDR_SCAUSE:	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M && priv_mode_ff !== PRIV_MODE_S )
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_scause_ff;
						
						end
			
			
										end
										
		     CSR_ADDR_STVAL:	  	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M && priv_mode_ff !== PRIV_MODE_S )
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_stval_ff;
						
						end
			
			
										end
										
			

			  CSR_ADDR_SEPC:	  	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M && priv_mode_ff !== PRIV_MODE_S )
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =	csr_sepc_ff;
						
						end
			
			
										end
										
										
			  CSR_ADDR_SIP:	  	  begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M && priv_mode_ff !== PRIV_MODE_S )
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =csr_mip_ff & SIP_MASK;
						
						end
			
			
										end
										
										
										
			  CSR_ADDR_SCOUNTEREN: begin
			
					
				if(priv_mode_ff !== PRIV_MODE_M && priv_mode_ff !== PRIV_MODE_S )
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =csr_scounteren_ff;
						
						end
			
			
										end
										
										
			  CSR_ADDR_SATP:	  	  begin
			
					
				if( ( (priv_mode_ff == PRIV_MODE_S) && csr_mstatus_ff.tvm ) || (priv_mode_ff == PRIV_MODE_U) )
						begin
							csr_rd_exc_req  = 1'b1; 
						end
					else	
						begin
							csr_rdata =csr_satp_ff;
						
						end
			
			
										end
										
										
				//BROOOOOOOOOOOOOOOOOOOOOOOOOOOO countersss walay to daal doooooooo
										
										
				
							
			
			  default :				  
			  begin
			   csr_rd_exc_req  = 1'b1; 
				csr_rdata = '0;
				end
		
		endcase
	
	end //if(EXE_to_CSR_ctrl_in.csr_rd_req | EXE_to_CSR_ctrl_in.csr_wr_req)
	
	

end
//================================== CSR read operations -END ==================================//





















		

//The interrupt Flow

/**
1.	First the meip, msip or the mtip bits are set due to external interrupts
2.	iF ANY of them are active it means we have a machine interrupt request
3.	set the irq_code based on a priority
4.	Then we check if machine mode global interrupt enable is active
5.	Then check if the interrupt is delegated or not
6.	Lastly if interrupt is not delegated and we have machine interrupt request AND the global bit is enabled, then serve_m_irq_req is ACTIVE	
	
**/


// Timer interrupt enablement
always_ff @(posedge rst, posedge clk) begin
    if (rst) begin
        ext_irq0_ff  <= 1'b0;
        ext_irq1_ff  <= 1'b0; 
        timer_irq_ff <= 1'b0; 
    end else begin
        ext_irq0_ff  <= ext_irq_in[0];
        ext_irq1_ff  <= ext_irq_in[1];
        timer_irq_ff <= timer_irq_in;
    end
end



//================update the signals from the csrs========

assign meip_irq_req  = csr_mie_ff.meie && csr_mip_next.meip; 		
assign mtip_irq_req  = csr_mip_next.mtip & csr_mie_ff.mtie;
assign msip_irq_req  = csr_mip_next.msip & csr_mie_ff.msie;

assign seip_irq_req = csr_mip_ff.seip & csr_mie_ff.seie;
assign stip_irq_req = csr_mip_ff.stip & csr_mie_ff.stie;
assign ssip_irq_req = csr_mip_ff.ssip & csr_mie_ff.ssie;// why flip flops used now???



												// there is also a uart bit in the mip register (find out if it is custom addition or there in the specification)

												/**
													csr_mip_next is used instead of the csr_mip_ff flip flop value 
													because interrupts do not depend on clock..? (my guess)
													Chat gpt says that to avoid interrupt handling latency
													this could have been done..lets carry on ig  
												**/


//====================Update the irq_code ======

always_comb begin
    irq_code = type_irq_code_e'(IRQ_CODE_NONE);
    case (1'b1)
        meip_irq_req: irq_code = type_irq_code_e'(IRQ_CODE_M_EXTERNAL);
        msip_irq_req: irq_code = type_irq_code_e'(IRQ_CODE_M_SOFTWARE);
        mtip_irq_req: irq_code = type_irq_code_e'(IRQ_CODE_M_TIMER);
        seip_irq_req: irq_code = type_irq_code_e'(IRQ_CODE_S_EXTERNAL);
        ssip_irq_req: irq_code = type_irq_code_e'(IRQ_CODE_S_SOFTWARE);
        stip_irq_req: irq_code = type_irq_code_e'(IRQ_CODE_S_TIMER);
    endcase
end


//===========Machine Interrupt handling=============



assign is_m_irq_req = meip_irq_req | mtip_irq_req | msip_irq_req;

assign is_s_irq_req = seip_irq_req | stip_irq_req | ssip_irq_req;

assign m_mode_global_ie = ((priv_mode_ff == PRIV_MODE_M) & csr_mstatus_ff.mie) | (priv_mode_ff != PRIV_MODE_M);
 
												/**
													Interrupts for higher privilege modes, y>x, are always globally enabled 
													regardless of the setting of the global yIE bit for the
													higher-privilege mode.
													this is from riscV official documentation
												**/
												
												
												/**
													By default, all traps at any privilege level are handled in machine mode, though a machine-mode
													handler can redirect traps back to the appropriate level with the MRET instruction (Section 3.3.2). To
													increase performance, implementations can provide individual read/write bits within medeleg and
													mideleg to indicate that certain exceptions and interrupts should be processed directly by a lower
													privilege level								
												**/
									
									
									
									

assign irq_delegated_req = csr_mideleg_ff[irq_code]; 
									/**
										*******in UET core , this is ANDed with is_s_irq_req BECAUSE IT ONLY DELEGATES S-MODE
										INTERRUPTS and NOT m-mode bruh

									**/
									/**
										Delegated interrupts result in the interrupt being masked at the delegator privilege level. For example,
										if the supervisor timer interrupt (STI) is delegated to S-mode by setting mideleg[5], STIs will not be
										taken when executing in M-mode. By contrast, if mideleg[5] is clear, STIs can be taken in any mode
										and regardless of current mode will transfer control to M-mode
										this is from riscV official documentation
									**/
									
									/**
										DOES mideleg have bits to delegate machine interrupts????
										Assuming NO for now
										Hardwiring them to 0 for now i guess
									
									**/

assign serve_m_irq_req = (is_m_irq_req | is_s_irq_req)  & m_mode_global_ie & ~irq_delegated_req;






//===========Supervisor Interrupt handling=============


assign s_mode_global_ie = ((priv_mode_ff == PRIV_MODE_S) & csr_mstatus_ff.sie) | (priv_mode_ff == PRIV_MODE_U);


assign serve_s_irq_req   =  is_s_irq_req & s_mode_global_ie & irq_delegated_req;

									/** 
									only serve interrupt is S mode if,
									1) the interrupt is delegated 
									2) You ARE in S mode
									3) S mode Global interrupt enable is ON
									4) doesnt matter if its s_mode interrupt request or m_mode interrupt req
									
									**/

assign irq_flush_lsu_o = serve_m_irq_req | serve_s_irq_req;
									
									
//=================================The Exception Flow=======================

/**
1.	Exception requests from any source including CSR and earlier stages
2.	Set the exception code based on priority
3. m_mode_exc_req if there is ANY exception request AND it has NOT been delegated 
		OR 
	if there is ANY exception request AND it HAS been delegated BUT the current privilege level is M mode
4. s_mode_exc_req  if there is ANY exception request AND it HAS been delegated AND the mode is S mode 

**/					
								

						

	
	
//=====Exception requests from different modules==========================



assign csr_exc_req     = csr_rd_exc_req | csr_wr_exc_req | csr_satp_exc_req;  
assign ld_pf_exc_req   = ld_page_fault_in;
assign st_pf_exc_req   = st_page_fault_in;  
assign i_pf_exc_req    = exc_req_in & (exc_code_in == EXC_CODE_INST_PAGE_FAULT); //why isolating this exception in particular??

assign exc_req         = exc_req_in | csr_exc_req | ld_pf_exc_req | st_pf_exc_req | ld_misalign_exc_req  | st_misalign_exc_req;

//assign ld_misalign_exc_req = 
//assign st_misalign_exc_req =
	
	//UA: complete these assignments!!!!!
	
	//UA: add break exception request AND ecall exception request









	
// Exception code corresponding to selected exception============================
	
always_comb begin
    exc_code = EXC_CODE_NO_EXCEPTION;
    case (1'b1)
        exc_req_in 					  : exc_code = exc_code_in;
        csr_exc_req          		  : exc_code = EXC_CODE_ILLEGAL_INSTR;
        ld_pf_exc_req        		  : exc_code = EXC_CODE_LD_PAGE_FAULT;
        st_pf_exc_req        		  : exc_code = EXC_CODE_ST_PAGE_FAULT;
        ld_misalign_exc_req        : exc_code = EXC_CODE_LD_ADDR_MISALIGN;
        st_misalign_exc_req        : exc_code = EXC_CODE_ST_ADDR_MISALIGN;
    endcase
end
	
				
									
									
				
									

// Is the exception to be handled by M mode?=========

//is it delegated?
assign exc_delegated_req =  csr_medeleg_ff[exc_code];

assign serve_m_exc_req   = (exc_req && ~exc_delegated_req) || (exc_req && exc_delegated_req && (priv_mode_ff == PRIV_MODE_M));




//Is the exception to be handled by S Mode?==========

assign serve_s_exc_req   = (exc_req & exc_delegated_req) && (priv_mode_ff != PRIV_MODE_M); //(break_exc_req | pf_exc_req | u_mode_ecall_req) & 
																														 //what are these comments??
							
									
//Trap privilege mode combinational block

always_comb
	begin
	
		trap_priv_mode = PRIV_MODE_M;
		
		if( (irq_delegated_req && ~serve_m_irq_req) || (exc_delegated_req && ~serve_m_exc_req) )
			begin
			
				trap_priv_mode = (priv_mode_ff == PRIV_MODE_M) ? PRIV_MODE_M : PRIV_MODE_S;

			
			end

	end



//=========================== Set exception and interrupt signals depending upon the inputs to CSR  - END=======================//

















//================================== CSR PC value preperation stuff(for jumping in case of exceptions or interrupts) ==================================//





	//	serve_mret_pc_req and serve_sret_pc_req variables 
	//these are used because even though we might have a mret or sret req,
	//if there is an exception request coming at the same time ,
	//then we will serve the exception request
	



//set the system operation depending upon the input obtained from the execute stage
always_comb begin
		//initialize the system operations to 0
		
		sret_req       = 1'b0;
		mret_req       = 1'b0;
		wfi_req        = 1'b0;
		sfence_vma_req = 1'b0;
		
		
		case(sys_ops_in)
		
		SYS_OPS_SRET       : sret_req       = 1'b1;
        SYS_OPS_MRET       : mret_req       = 1'b1;
        SYS_OPS_WFI        : wfi_req        = 1'b1;
        SYS_OPS_SFENCE_VMA : sfence_vma_req = 1'b1;
        default            : begin  end 
		
		endcase

	
	end

	
	
	
	

//should m_mode_pc be served?
assign serve_mret_pc_req = mret_req & ~serve_m_exc_req & ~serve_m_irq_req;
assign serve_m_mode_pc_req = serve_mret_pc_req || serve_m_exc_req || serve_m_irq_req;


	
//combinational logic to set m_mode_new_pc

always_comb begin
	
	if(serve_mret_pc_req)
		begin
			m_mode_new_pc = csr_mepc_ff;	//incase of mret, the m_mode_new_pc gets the value of mepc
		end

	else
		begin
		
			if(csr_mtvec_ff.mode[0])
				begin
					case(1'b1)
						serve_m_exc_req:	m_mode_new_pc = {csr_mtvec_ff.base , 2'd0};
						serve_m_irq_req:	m_mode_new_pc = {csr_mtvec_ff.base[(TVEC_BASE_WIDTH-1):IRQ_CODE_WIDTH],irq_code,2'd0};
						default			:	m_mode_new_pc = {csr_mtvec_ff.base , 2'd0};
				
					endcase
				end
				
			else
				begin
					m_mode_new_pc =  {csr_mtvec_ff.base , 2'd0};
				end
		end





	end


	
//should s_mode_pc be served?
assign serve_sret_pc_req = sret_req & ~serve_s_exc_req & ~serve_s_irq_req;
assign serve_s_mode_pc_req = serve_sret_pc_req || serve_s_exc_req || serve_s_irq_req;



//combinational logic to set s_mode_new_pc

always_comb begin
	
	if(serve_sret_pc_req)
		begin
			s_mode_new_pc = csr_sepc_ff;	//incase of mret, the m_mode_new_pc gets the value of mepc
		end

	else
		begin
		
			if(csr_stvec_ff.mode[0])
				begin
					case(1'b1)
						serve_s_exc_req:	s_mode_new_pc = {csr_stvec_ff.base , 2'd0};
						serve_s_irq_req:	s_mode_new_pc = {csr_stvec_ff.base[(TVEC_BASE_WIDTH-1):IRQ_CODE_WIDTH],irq_code,2'd0};
						default			:	s_mode_new_pc = {csr_stvec_ff.base , 2'd0};
				
					endcase
				end
				
			else
				begin
					s_mode_new_pc =  {csr_stvec_ff.base , 2'd0};
				end
		end





	end









	
//update the wfi flip flop
always_ff @ (posedge rst , posedge clk)
	begin
	
		if(rst)begin
			wfi_ff<= 1'b0;
		end
		
		else begin
			wfi_ff<= wfi_next;	
			
		end
	
	end



//combinational logic for the wfi next stage logic
	
always_comb 
	begin
		wfi_next = wfi_ff;
		
		if(serve_m_irq_req || serve_s_irq_req)
			begin
				wfi_next = 1'b0;
			end
			
		else if(wfi_req)
			begin
				wfi_next = 1'b1;
			end
	

	
	end
	
	
	
	
	






//================================== PC value preperation stuff - END==================================//













//================================== CSR write operation PREPARATION ==================================//


//combinational block to set flags based upon the address from execute unit
always_comb 
	begin
		 csr_wr_exc_req             = 1'b0;
		
					 // initialize the flags to zero
						 csr_mcycle_wr_flag         = 1'b0;
						 csr_mcycleh_wr_flag        = 1'b0;
						 csr_minstret_wr_flag       = 1'b0;
						 csr_minstreth_wr_flag      = 1'b0;
						 csr_mcounteren_wr_flag     = 1'b0;
						 csr_mcountinhibit_wr_flag  = 1'b0;


						 csr_mstatus_wr_flag        = 1'b0;
						 csr_medeleg_wr_flag        = 1'b0;
						 csr_mideleg_wr_flag        = 1'b0; 
						 csr_mie_wr_flag            = 1'b0;
						 csr_mtvec_wr_flag          = 1'b0;
						 csr_mscratch_wr_flag       = 1'b0;
						 csr_mepc_wr_flag           = 1'b0;
						 csr_mcause_wr_flag         = 1'b0;
						 csr_mtval_wr_flag          = 1'b0;
						 csr_mip_wr_flag            = 1'b0;

						 csr_sscratch_wr_flag       = 1'b0;
						 csr_sstatus_wr_flag        = 1'b0;
						 csr_sie_wr_flag            = 1'b0;
						 csr_stvec_wr_flag          = 1'b0;
						 csr_sepc_wr_flag           = 1'b0;
						 csr_scause_wr_flag         = 1'b0;
						 csr_stval_wr_flag          = 1'b0;
						 csr_sip_wr_flag            = 1'b0;
						 csr_satp_wr_flag           = 1'b0;
						 csr_scounteren_wr_flag     = 1'b0;
							
		
		
		
		
		
		
		
		if(csr_wr_req_in)	//update the write flags
		
			begin
				case(csr_addr_in)
				
					 // Machine mode cycle and performance counter registers
						CSR_ADDR_MCYCLE         : csr_mcycle_wr_flag         = 1'b1;
						CSR_ADDR_MCYCLEH        : csr_mcycleh_wr_flag        = 1'b1;
						CSR_ADDR_MINSTRET       : csr_minstret_wr_flag       = 1'b1;
						CSR_ADDR_MINSTRETH      : csr_minstreth_wr_flag      = 1'b1;
						CSR_ADDR_MCOUNTEREN     : csr_mcounteren_wr_flag     = 1'b1;
						CSR_ADDR_MCOUNTINHIBIT  : csr_mcountinhibit_wr_flag  = 1'b1;
						
						
					 // Machine mode flags for trap setup and handling registers write operation
						CSR_ADDR_MSTATUS        : csr_mstatus_wr_flag  = 1'b1;
						CSR_ADDR_MEDELEG        : csr_medeleg_wr_flag  = 1'b1;
						CSR_ADDR_MIDELEG        : csr_mideleg_wr_flag  = 1'b1; 
						CSR_ADDR_MIE            : csr_mie_wr_flag      = 1'b1;
						CSR_ADDR_MTVEC          : csr_mtvec_wr_flag    = 1'b1;
						
						CSR_ADDR_MSCRATCH       : csr_mscratch_wr_flag = 1'b1;
						CSR_ADDR_MEPC           : csr_mepc_wr_flag     = 1'b1;
						CSR_ADDR_MCAUSE         : csr_mcause_wr_flag   = 1'b1;
						CSR_ADDR_MTVAL          : csr_mtval_wr_flag    = 1'b1;
						CSR_ADDR_MIP            : csr_mip_wr_flag      = 1'b1;  	
			
						 // Supervisor mode flags for trap setup and handling registers write operation
						CSR_ADDR_SSTATUS        : csr_sstatus_wr_flag    = 1'b1;
						CSR_ADDR_SSCRATCH       : csr_sscratch_wr_flag   = 1'b1;
						CSR_ADDR_SIE            : csr_sie_wr_flag        = 1'b1;
						CSR_ADDR_STVEC          : csr_stvec_wr_flag      = 1'b1; 
						CSR_ADDR_SEPC           : csr_sepc_wr_flag       = 1'b1;
						CSR_ADDR_STVAL          : csr_stval_wr_flag      = 1'b1;
						CSR_ADDR_SIP            : csr_sip_wr_flag        = 1'b1;
						CSR_ADDR_SATP           : csr_satp_wr_flag       = 1'b1; 
						CSR_ADDR_SCOUNTEREN     : csr_scounteren_wr_flag = 1'b1;
					
					
						default:
							begin
								csr_wr_exc_req  = 1'b1;  
							end
					
					
					
				endcase
			
			
			end
		
	
	
	end



	
//Decode CSR operations(WRITE, SET , CLEAR)
always_comb begin
    case (csr_ops_in)
        CSR_OPS_WRITE  : csr_wdata =  csr_wdata_in;
        CSR_OPS_SET    : csr_wdata =  csr_wdata_in | csr_rdata;
        CSR_OPS_CLEAR  : csr_wdata = ~csr_wdata_in & csr_rdata;
        default        : csr_wdata = '0;
    endcase
end


//Decode System operations(SRET,MRET,WFI,SFENCE_VMA)  ****ALREADY DONE****


//==============Update the CSRs==========//






//==============Update the trap setup CSRs==========//


		// Update mstatus/sstatus (machine/supervisor status) CSR and privilege mode
		// -------------------------------------------------------------------------
			always_ff @(posedge rst, posedge clk) 
				begin
					if (rst) 
						begin
						  csr_mstatus_ff <= {`XLEN{1'b0}}; 
						  priv_mode_ff   <= PRIV_MODE_M;
						end 
					else 
						begin
						  csr_mstatus_ff <= csr_mstatus_next;
						  priv_mode_ff   <= priv_mode_next;
						end
				end
				
				
			always_comb
				begin
				
					csr_mstatus_next = csr_mstatus_ff;
					priv_mode_next   = priv_mode_ff;
					
					case(1'b1)
					
						serve_m_exc_req, serve_m_irq_req :
							begin
								csr_mstatus_next.mie  = 1'b0;     				 // Disable the interrupts
								csr_mstatus_next.mpie = csr_mstatus_ff.mie;   // Preserve the previous interrupt enable state
								csr_mstatus_next.mpp  = priv_mode_ff;         // Save the privilege mode before trap 
								priv_mode_next        = trap_priv_mode;
							
							end
							
						serve_s_exc_req, serve_s_irq_req :
							begin
								csr_mstatus_next.sie  = 1'b0;     				 // Disable the interrupts
								csr_mstatus_next.spie = csr_mstatus_ff.sie;   // Preserve the previous interrupt enable state
								csr_mstatus_next.spp  = priv_mode_ff[0];         // Save the privilege mode before trap 
								priv_mode_next        = trap_priv_mode;
							
							end
					
						mret_req:
							begin
								csr_mstatus_next.mie  = csr_mstatus_ff.mpie; // Restore to previous interrupt enable state
								priv_mode_next        = csr_mstatus_ff.mpp;  // Restore the privilege mode
								csr_mstatus_next.mpie = 1'b0;                //UA : some doubts here , gpt says to clear it but in UET core it is enabled
								csr_mstatus_next.mpp  = PRIV_MODE_U;			/**FROM GPT
																							The MPP field in mstatus is cleared
																							(set to 00), which corresponds to User mode. 
																							This ensures that subsequent traps do not mistakenly 
																							use an old value of MPP to incorrectly restore privilege 
																							levels. **/ 
							
							end
							
						sret_req:
							begin
								csr_mstatus_next.sie  = csr_mstatus_ff.spie; // Restore to previous interrupt enable state
								priv_mode_next        = {1'b0, csr_mstatus_ff.spp};  // Restore the privilege mode
								csr_mstatus_next.spie = 1'b0;                //UA : some doubts here , gpt says to clear it but in UET core it is enabled
								csr_mstatus_next.spp  = 1'b0;			
							
							end
							
							
							
							
						csr_mstatus_wr_flag:
							begin
								 csr_mstatus_next = csr_wdata;
							end
					
						
						csr_sstatus_wr_flag:
							begin
								csr_mstatus_next = (csr_mstatus_ff & ~{SSTATUS_WRITE_MASK}) | {(csr_wdata & SSTATUS_WRITE_MASK)};
							end
					
					
					
					
					
					
					
					
					
					
					endcase
								
				
				end
				

		// Update the medeleg (machine exception delegation) CSR 
		// -----------------------------------------------------
			always_ff @(posedge rst, posedge clk) 
				begin
					 if (rst) begin
						  csr_medeleg_ff <= '0;
					 end else begin
						  csr_medeleg_ff <= csr_medeleg_next;
					 end
				end
				
				
			always_comb
				begin
					csr_medeleg_next = csr_medeleg_ff;
					
					if (csr_medeleg_wr_flag) 
						begin
							csr_medeleg_next = csr_wdata; 
						end  
				
				end

				
		// Update the mideleg (machine interrupt delegation) CSR 
		// -----------------------------------------------------
			always_ff @(posedge rst, posedge clk) 
				begin
					 if (rst) begin
						  csr_mideleg_ff <= '0;
					 end else begin
						  csr_mideleg_ff <= csr_mideleg_next;
					 end
				end


			always_comb 
				begin 
					csr_mideleg_next = csr_mideleg_ff;

					if (csr_mideleg_wr_flag) 
						begin
							csr_mideleg_next = csr_wdata; 
						end        
				end
				
				
			// Update the mie/sie (machine/supervisor interrupt enable) CSR 
			// ------------------------------------------------------------
			always_ff @(posedge rst, posedge clk) 
				begin
					 if (rst) begin
						  csr_mie_ff <= '0;
					 end else begin
						  csr_mie_ff <= csr_mie_next;
					 end
				end
				

			
			always_comb // Apply a mask to ensure that only writeable bits are updated.
				begin   
					 csr_mie_next = csr_mie_ff;

					 if (csr_mie_wr_flag) begin
						  csr_mie_next = (csr_wdata & MIE_MASK);  // | (csr_mie_ff & ~MIE_MASK) -- (do we need this)
					 end else if (csr_sie_wr_flag) begin
						  csr_mie_next = (csr_wdata & csr_mideleg_ff) | (csr_mie_ff & ~csr_mideleg_ff);  
					 end 
				end



				
				// Update the mtvec (machine trap vector) CSR 
				// ------------------------------------------
			always_ff @(posedge rst, posedge clk) 
				begin
					if (rst)
						begin
					  csr_mtvec_ff <= '0;
						end 
					else 
						begin
						  csr_mtvec_ff <= csr_mtvec_next;
						end
				end
				
				
				
			 always_comb
				begin
					csr_mtvec_next = csr_mtvec_ff;
					
					if(csr_mtvec_wr_flag)
						begin
						
							if(csr_wdata[MODE_BIT])//	UA:alignment needs to be ensured here, but how it is being aligned is something I have to study further
								begin
									csr_mtvec_next = {csr_wdata[(`XLEN-1):CSR_MTVEC_BASE_ALIGN_VECTOR],
															{(CSR_MTVEC_BASE_ALIGN_VECTOR-1){1'b0}},
															csr_wdata[MODE_BIT]};
								end
							
							else
								begin
									csr_mtvec_next = {csr_wdata[(`XLEN-1):CSR_MTVEC_BASE_ALIGN_DIRECT], 
															{(CSR_MTVEC_BASE_ALIGN_DIRECT-1){1'b0}}, 
															 csr_wdata[MODE_BIT]}; 
								
								
								
								end

						end

					
					
					
					
					
				end

		
			 // Update the stvec (supervisor trap vector) CSR 
				// ---------------------------------------------

				
				

//=========Update trap handling CSRs ===============================//

		// Update the mcause (machine (exception/interrupt) cause) CSR 
		// -----------------------------------------------------------
		
			always_ff @(posedge rst, posedge clk) 
				begin
					if (rst)
						begin
					  csr_mcause_ff <= {`XLEN{1'b0}};
						end 
					else 
						begin
						  csr_mcause_ff <= csr_mcause_next;
						end
				end


				always_comb
					begin
						csr_mcause_next = csr_mcause_ff;
						
						case(1'b1)
							serve_m_exc_req:
								begin
									csr_mcause_next = {1'b0 ,{`XLEN - EXC_CODE_WIDTH-1{1'b0}} ,exc_code};
								end
							serve_m_irq_req:
								begin
									csr_mcause_next = {1'b1 ,{`XLEN - EXC_CODE_WIDTH-1{1'b0}} ,irq_code};
								end
							csr_mcause_wr_flag:
								begin
									csr_mcause_next = {csr_wdata[`XLEN-1], {`XLEN-EXC_CODE_WIDTH-1{1'b0}}, csr_wdata[EXC_CODE_WIDTH-1:0]}; //okay ig
								end
							default:
								begin
								
								
								end
						
						
						
						endcase
						
					
					
					end



					
					
		// Update the mepc (machine exception pc) CSR 
		// ----------------------------------------------
		
			always_ff @(posedge rst, posedge clk) 
				begin
					if (rst)
						begin
					  csr_mepc_ff <= {`XLEN{1'b0}};
						end 
					else 
						begin
						  csr_mepc_ff <= csr_mepc_next;
						end
				end		
				
				
				
			always_comb
				begin
					csr_mepc_next = csr_mepc_ff;
					
					case(1'b1)
						serve_m_irq_req:
							begin
								csr_mepc_next = pc_in; //UA : BIG iffi here
							end
						serve_m_exc_req:
							begin
								csr_mepc_next = pc_in;	//UA : BIG iffi here
							end
						csr_mepc_wr_flag:
							begin						
								csr_mepc_next = {csr_wdata[`XLEN-1:2], 2'b00};
							end
							
						default:
							begin
							
							end
	
					endcase
				end
		
		
		// Update the mip (machine interrupt pending) CSR 
		// ----------------------------------------------
		
		logic[`XLEN-1:0]   sip_mask;
		
			always_ff @(posedge rst, posedge clk) 
				begin
					if (rst)
						begin
					  csr_mip_ff <= {`XLEN{1'b0}};
						end 
					else 
						begin
						  csr_mip_ff <= csr_mip_next;
						end
				end	
				
				
			always_comb
				begin
					csr_mip_next = csr_mip_ff;
					csr_mip_next.meip = ext_irq0_ff;
					csr_mip_next.seip = ext_irq1_ff;
					csr_mip_next.mtip = timer_irq_ff;
					csr_mip_next.msip = '0; // pipe2csr.soft_irq; (UA: what???)
					
					
					if(csr_mip_wr_flag)
						begin
							csr_mip_next = (csr_wdata & MIP_MASK) | (csr_mip_ff & ~MIP_MASK); //UA: in UET core it's SIP_MASK (surely a mistake?) OYE there is a problem only SSIP should be writable
						end
				
					else if(csr_sip_wr_flag)
						begin
							sip_mask     = SIP_MASK & csr_mideleg_ff;  //UA : confirm this
							csr_mip_next = (csr_wdata & SIP_MASK) | (csr_mip_ff & ~SIP_MASK);
						end
				
				
				
				
				end
				
				
		// Update the mscratch (machine scratch) CSR 
		// -----------------------------------------
			always_ff @(posedge rst, posedge clk)  //yaar this reset logic faulty????
				begin
					if (rst)
						begin
					  csr_mscratch_ff <= {`XLEN{1'b0}};
						end 
					else 
						begin
						  csr_mscratch_ff <= csr_mscratch_next;
						end
				end	

		
		
			always_comb
				begin
				
				if (csr_mscratch_wr_flag) 
					begin
						csr_mscratch_next = csr_wdata;
					end 
				else 
					begin
						csr_mscratch_next = csr_mscratch_ff;
					end
						
				end
		
		
		
		// Update the mtval (machine trap value) CSR 
		// -----------------------------------------
			always_ff @(posedge rst, posedge clk) 
					begin
						if (rst)
							begin
						  csr_mtval_ff <= {`XLEN{1'b0}};
							end 
						else 
							begin
							  csr_mtval_ff <= csr_mtval_next;
							end
					end	
				
				
		always_comb				//UA: the instruction page fault exception should write 0 no? why does it write the current pc value??
				begin
					case(1'b1)
						(serve_m_exc_req & (ld_misalign_exc_req | st_misalign_exc_req)): //m_mode_misalign_exception request
							begin
								csr_mtval_next = dbus_addr_in; //memory address of the page fault
							end
					
						(serve_m_exc_req & csr_exc_req):		//illegal_instruction_exception request
							begin
								csr_mtval_next = instr_in; //the instruction itself
							end
							
						(serve_m_exc_req & (ld_pf_exc_req | st_pf_exc_req)):	//load_store_page_fault_exception request
							begin
								csr_mtval_next = dbus_addr_in; //memory address of the page fault
							end
							
						(serve_m_exc_req & i_pf_exc_req):	//instruction_page_fault_exception request		
							begin
								csr_mtval_next = pc_in;	//UA:iffi here
							end
						(serve_m_irq_req):						//UA: add break and ecall 		
							begin
								csr_mtval_next = '0;
							end
						(csr_mtval_wr_flag):						//write flag
							begin
								csr_mtval_next = csr_wdata;
							end
						default:										//retain the previous value
							begin
								csr_mtval_next = csr_mtval_ff;
							end
					
						
					
					
					
					endcase
				end
		
		
		
		
//=======Update cycle and performance counter registers===//



		// Update the mcycle (machine cycle counter) CSR 
		// ---------------------------------------------
			always_ff @(posedge rst, posedge clk) 
					begin
						if (rst)
							begin
								csr_mcycle_ff <= {`XLEN{1'b0}};
							end 
						else 
							begin
							   csr_mcycle_ff <= csr_mcycle_next;
							end
					end
					
			
			
			
			
			
			
			always_comb
					begin
					
					if(csr_mcycle_wr_flag)
						begin
							csr_mcycle_next = csr_wdata; 
						end
						
					else if(~csr_mcountinhibit_ff.cy)
						begin
							csr_mcycle_next = csr_mcycle_ff + 1'b1;
						end
					
					else
						begin
							csr_mcycle_next = csr_mcycle_ff;
						end
					
					end
				
				
				
				
		// Update the mcycleh (machine cycle high counter) CSR 
		// ---------------------------------------------------
			always_ff @(posedge rst, posedge clk) 
				begin
					if (rst)
						begin
							csr_mcycleh_ff <= {`XLEN{1'b0}};
						end 
					else 
						begin
							csr_mcycleh_ff <= csr_mcycleh_next;
						end
				end
					
					
			always_comb
				begin
					
					if(csr_mcycleh_wr_flag)
						begin
							csr_mcycleh_next = csr_wdata; 
						end
					else if((&csr_mcycle_ff) & (~csr_mcountinhibit_ff.cy))
						begin
						   csr_mcycleh_next = csr_mcycleh_ff + 1'b1;  						
						end
					else
						begin
							 csr_mcycleh_next = csr_mcycleh_ff;
						end
				
				end
				
				
				
				
		// Update the minstret (machine instruction retire counter) CSR 
		// ------------------------------------------------------------
		
		
		
			
			assign pipe_stall_flush = instr_flushed_in | pipe_stall_in;	//UA: figure out where does instruction flush come from


			always_ff @(posedge rst, posedge clk) 
				begin
					if (rst)
						begin
							csr_minstret_ff <= {`XLEN{1'b0}};
						end 
					else 
						begin
							csr_minstret_ff <= csr_minstret_next;
						end
				end
			

			always_comb
				begin
				
					is_not_ecall  =  ~(exc_code_in[3] & ~exc_code_in[2]); //1000 OR 1001 OR 1011 UA : Okayyyy
					is_not_ebreak = (exc_code_in != EXC_CODE_BREAKPOINT);
					
					csr_minstret_inc = (~csr_mcountinhibit_ff.ir) & (~(pipe_stall_flush | (exc_req & is_not_ecall & is_not_ebreak)));
					
					
					 if (csr_minstret_wr_flag) 
						 begin
							csr_minstret_next = csr_wdata; 
						 end

					 else if(csr_minstret_inc)
						 begin
							csr_minstret_next = csr_minstret_ff + 1'b1; 
						 end
						 
					 else
						 begin
							csr_minstret_next = csr_minstret_ff;
						 end
					
				end
				
				
			// Update the minstreth (machine instruction retire high counter) CSR 
			// ------------------------------------------------------------------

				
				always_ff @(posedge rst, posedge clk) 
					begin
						if (rst)
							begin
								csr_minstreth_ff <= {`XLEN{1'b0}};
							end 
						else 
							begin
								csr_minstreth_ff <= csr_minstreth_next;
							end
					end
					
					
					
					
					
				always_comb
					begin
						if (csr_minstreth_wr_flag) 
							begin
								csr_minstreth_next = csr_wdata; 
						   end
						
						else if((&csr_minstret_ff) & csr_minstret_inc)
							begin
								csr_minstreth_next = csr_minstreth_ff + 1'b1;  
							end
					
						else
							begin
								csr_minstreth_next = csr_minstreth_ff;
							end
					
					end
					
			
			// Update the mcounteren (machine counter enable) CSR 
			// --------------------------------------------------
				always_ff @(posedge rst, posedge clk) 
					begin
						 if (rst) 
							begin
							  csr_mcounteren_ff <= '0;
							end 
						 
						 else 
							begin
							  csr_mcounteren_ff <= csr_mcounteren_next;
							end
					end
					
					
					
				always_comb 
					begin 
					 csr_mcounteren_next = csr_mcounteren_ff; 

					 if (csr_mcounteren_wr_flag) 
						begin
						  csr_mcounteren_next = csr_wdata; 
						end      
						
					end
									
					
				// Update the mcountinhibit (machine counter inhibit) CSR 
				// ------------------------------------------------------
					always_ff @(posedge rst, posedge clk) 
						begin
							 if (rst) 
								begin
								  csr_mcountinhibit_ff <= '0;
								end 
								
							 else 
								begin
								  csr_mcountinhibit_ff <= csr_mcountinhibit_next;
							 end
						end
						
						
						
					always_comb 
						begin 
							 csr_mcountinhibit_next = csr_mcountinhibit_ff; 

							 if (csr_mcountinhibit_wr_flag) 
								begin
								  csr_mcountinhibit_next = csr_wdata; 
								end      
						end
				
		
		

		



//==============Update the CSRs -END=====//



//================================== CSR write operation PREPARATION -END ==================================//













//======================assign the outputs===================================//






//fetch-stage assignments
assign pc_new_o = serve_m_mode_pc_req ? m_mode_new_pc:
												serve_s_mode_pc_req ? s_mode_new_pc:
												csr_vaddr_iflush_req? pc_next_in:
												32'hFFFFFFFF;
												
//decode stage assignments	
assign priv_mode_o = priv_mode_ff;	


//Hazard unit assignments
assign new_pc_req_o = serve_m_mode_pc_req || serve_s_mode_pc_req || csr_vaddr_iflush_req;//UA: change name to serve_csr_vaddr_iflush_req.
assign wfi_req_o 	= wfi_next ; //this signal is ANDed with ~(serve_s_mode_pc_req || serve_m_mode_pc_req )??? dont think that is necessary
assign csr_read_req_o = csr_rd_req_in;

//LSU assignments
assign satp_ppn = csr_satp_next.ppn;
assign en_vaddr = ((csr_satp_next.mode == MODE_SV32) && (priv_mode_next != PRIV_MODE_M))? 1'b1 : 1'b0; //v_addr disabled in m_mode?? EDIT: YUP!
assign mxr = csr_mstatus_ff.mxr;
assign tlb_flush = sfence_vma_req;
assign en_ld_st_vaddr = en_ld_st_vaddr_next;
assign dcache_flush   = fence_i_req;
assign lsu_flush= new_pc_req_o | wfi_req_o;		//how is this working?? this isnt even going anywhere!!!!!
assign sum = csr_mstatus_ff.sum;
assign priv_mode_to_lsu = priv_mode_ff;





//writeback stage assignments
assign csr_rdata_o = csr_rd_req_in? csr_rdata : '0;


	
//debugging

assign mcause_o = csr_mcause_ff;
assign mtval_o = csr_mtval_ff;
assign mepc_o = csr_mepc_ff;






//======================assign the outputs-END ===================================//






endmodule