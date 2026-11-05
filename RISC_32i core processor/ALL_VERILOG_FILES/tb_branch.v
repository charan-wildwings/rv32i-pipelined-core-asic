`timescale 1ns/1ps

module tb_branch;

reg clk;
reg rst;

wire [31:0] instr_addr;
wire [31:0] instr_rdata;

wire [31:0] data_addr;
wire [31:0] data_wdata;
wire        data_read;
wire        data_write;
wire [31:0] data_rdata;

wire [31:0] debug_pc;

rv32i_core u_core (
    .clk         (clk),
    .rst         (rst),
    .instr_addr  (instr_addr),
    .instr_rdata (instr_rdata),
    .data_addr   (data_addr),
    .data_wdata  (data_wdata),
    .data_read   (data_read),
    .data_write  (data_write),
    .data_rdata  (data_rdata),
    .debug_pc    (debug_pc)
);

instruction_memory u_imem (
    .addr  (instr_addr),
    .instr (instr_rdata)
);

data_memory u_dmem (
    .clk        (clk),
    .mem_read   (data_read),
    .mem_write  (data_write),
    .addr       (data_addr),
    .write_data (data_wdata),
    .read_data  (data_rdata)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1'b1;

    $dumpfile("results/branch_test.vcd");
    $dumpvars(0, tb_branch);

    #1;

    // ADDI x1, x0, 5
    u_imem.memory[0] = 32'h00500093;

    // ADDI x2, x0, 5
    u_imem.memory[1] = 32'h00500113;

    // BEQ x1, x2, +8
    u_imem.memory[2] = 32'h00208463;

    // Wrong-path instruction - should be flushed
    // ADDI x3, x0, 99
    u_imem.memory[3] = 32'h06300193;

    // Branch target
    // ADDI x3, x0, 20
    u_imem.memory[4] = 32'h01400193;

    #19;
    rst = 1'b0;

    #200;

    $display("");
    $display("========== BRANCH TEST ==========");
    $display("x1 = %0d (expected 5)",  u_core.u_regfile.regs[1]);
    $display("x2 = %0d (expected 5)",  u_core.u_regfile.regs[2]);
    $display("x3 = %0d (expected 20)", u_core.u_regfile.regs[3]);

    if (u_core.u_regfile.regs[3] === 32'd20)
        $display("BRANCH TEST: PASS");
    else
        $display("BRANCH TEST: FAIL");

    $display("=================================");
    $finish;
end

endmodule
