module m_csr_RWChecker(

input		[31:0]instruction, 	//check
input		[31:0]immediate, 		//check lol
input		[1:0]csr_ops,
input       RegWrite_id2exe,

output reg	csr_rd_req,
output reg	csr_wr_req,
output reg	RegWrite 		//Register this RegWrite signal for the next pipeline stage 

);
parameter CSR_OPS_NONE  = 2'b00;
parameter CSR_OPS_WRITE = 2'b01;
parameter CSR_OPS_SET	= 2'b10;
parameter CSR_OPS_CLEAR = 2'b11;

//=====local signals====

logic	[4:0]rd_addr ;
logic	[4:0]rs1_addr;



assign  rd_addr  = instruction[11:7] ;
assign  rs1_addr = instruction[19:15];

always_comb begin

    case (csr_ops)
        CSR_OPS_WRITE  : begin
            csr_rd_req = |rd_addr;
            csr_wr_req = 1'b1;
        end
        CSR_OPS_SET,
        CSR_OPS_CLEAR  : begin
            csr_rd_req = 1'b1;
            csr_wr_req = |rs1_addr;
        end
        default : begin
            csr_rd_req = 1'b0;
            csr_wr_req = 1'b0;
        end
    endcase
  
end


assign RegWrite  = (|csr_ops) ? (|rd_addr) : RegWrite_id2exe;  //did I do it right tho??




endmodule