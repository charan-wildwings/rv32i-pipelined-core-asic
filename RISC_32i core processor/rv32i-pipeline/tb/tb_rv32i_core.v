`timescale 1ns/1ps

module tb_rv32i_core;

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

    $dumpfile("results/rv32i_core.vcd");
    $dumpvars(0, tb_rv32i_core);

    #1;

    // ADDI x1, x0, 5
    u_imem.memory[0] = 32'h00500093;

    // ADDI x2, x0, 10
    u_imem.memory[1] = 32'h00A00113;

    // ADD x3, x1, x2
    u_imem.memory[2] = 32'h002081B3;

    // SUB x4, x2, x1
    u_imem.memory[3] = 32'h40110233;

    // SW x3, 0(x0)
    u_imem.memory[4] = 32'h00302023;

    // LW x5, 0(x0)
    u_imem.memory[5] = 32'h00002283;

    // ADD x6, x5, x1
    u_imem.memory[6] = 32'h00128333;

    #19;
    rst = 1'b0;

    #300;

    $display("");
    $display("========== FINAL REGISTER VALUES ==========");
    $display("x1 = %0d (expected 5)",  u_core.u_regfile.regs[1]);
    $display("x2 = %0d (expected 10)", u_core.u_regfile.regs[2]);
    $display("x3 = %0d (expected 15)", u_core.u_regfile.regs[3]);
    $display("x4 = %0d (expected 5)",  u_core.u_regfile.regs[4]);
    $display("x5 = %0d (expected 15)", u_core.u_regfile.regs[5]);
    $display("x6 = %0d (expected 20)", u_core.u_regfile.regs[6]);

    $display("");
    $display("Memory[0] = %0d (expected 15)",
             u_dmem.memory[0]);

    $display("===========================================");

    $finish;
end

initial begin
    $monitor(
        "time=%0t PC=%h instr=%h",
        $time,
        debug_pc,
        instr_rdata
    );
end

endmodule
