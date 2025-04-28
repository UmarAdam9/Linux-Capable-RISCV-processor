module m_PC_selector(

input	csr_new_pc_req,
input	exe_new_pc_req,
input	wfi_req,

input[31:0]	csr_new_pc,
input[31:0]	pc_plus_4,
input[31:0]	pc_ff,      //doesnt get used??
input[31:0]	exe_new_pc,


output reg[31:0] pc_next





);

always_comb begin
    pc_next = (pc_plus_4);

    case (1'b1)
        csr_new_pc_req : begin
            pc_next = csr_new_pc;
        end
        wfi_req        : begin
            pc_next = csr_new_pc;  
        end
        exe_new_pc_req : begin
            pc_next = exe_new_pc;  
        end
        
        default        : begin       end
    endcase
end	









endmodule