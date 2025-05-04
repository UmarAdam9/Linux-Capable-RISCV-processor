module m_instruction_memory (
    input logic clk,                // Clock signal
    input logic reset,              // Reset signal
    input logic [31:0] addr,        // 32-bit address input
    output logic [31:0] instruction // 32-bit instruction output
);

    // Declare a memory array with a size of 1024 (for example)
    // Each entry in memory holds 32-bit instructions
    logic [31:0] mem [0:1023]; 
    logic [31:0] register; 
	 

    // Initialization block for the memory (optional, for simulation purposes)
    initial begin
        // Load the instructions into memory
        mem[0]  = 32'h80000537;  												// lui x10, 0x80000
        mem[4]  = 32'b0000_0011_0100_0001_01010_001_00000_1110011 ;  // csrw mepc, x10
        mem[8]  = 32'b00010010001101000101_01011_0110111;  				// lui x11, 0x12345
        mem[12] = 32'b011001111000_01011_000_01011_0010011; 			// addi x11, x11, 0x678
        mem[16] = 32'b0000_0011_0100_0011_01011_001_00000_1110011;   // csrw mtval, x11
		  mem[20] = 32'b0000_0011_0100_0010_00101_101_00000_1110011;	//csrrwi x0,mcause,5 
		  mem[24] = 32'b0000_0011_0100_0001_01011_001_01000_1110011;	//csrrw x8,mepc,x11
		  mem[28] = 32'h00FFF1B7;													//lui   x3,0x0FFF
		  mem[32] = 32'h00F00237;													//lui   x4,0x0F00
		  mem[36] = 32'b0000_0011_0100_0011_00011_011_00100_1110011;   //csrrc x4,mtval,x3
		  mem[40] = 32'b0000_0011_0100_0011_00100_010_01011_1110011;	//csrrs x11,mtval,x4	
		  mem[44] = 32'b0000_0011_0100_0011_00000_011_00101_1110011;	//csrrc x0,mtval,x5
		  mem[48] = 32'hFFFFF337;													//lui x6,FFFFF
		  mem[52] = 32'b0000_0011_0100_0011_00110_011_00000_1110011;	//csrrc x0,mtval,x6
		  mem[56] = 32'h00F0F3B7;													//lui x7,0x00F0F
		  mem[60] = 32'b0000_0011_0100_0011_00111_010_00000_1110011;		//csrrs x0,mtval,x7	
		  		  
		  
    end

    // Always block to handle reading from memory
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            register <= 32'b0;  // Reset the instruction output
        else
            register <= mem[addr]; // Fetch instruction based on address (byte to word alignment)
    end
	 assign instruction = register;

endmodule
