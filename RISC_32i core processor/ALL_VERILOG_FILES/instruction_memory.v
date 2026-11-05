module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instr
);

reg [31:0] memory [0:255];

assign instr = memory[addr[9:2]];

integer i;

initial begin
    for (i = 0; i < 256; i = i + 1)
        memory[i] = 32'h00000013; // NOP = ADDI x0,x0,0
end

endmodule
