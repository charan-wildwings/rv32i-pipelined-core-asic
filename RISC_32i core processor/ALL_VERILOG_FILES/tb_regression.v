`timescale 1ns/1ps

module tb_regression;

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

integer errors;

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

task check_reg;
    input [4:0] reg_num;
    input [31:0] expected;
    begin
        if (u_core.u_regfile.regs[reg_num] !== expected) begin
            $display(
                "FAIL: x%0d = %0d, expected %0d",
                reg_num,
                u_core.u_regfile.regs[reg_num],
                expected
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS: x%0d = %0d",
                reg_num,
                u_core.u_regfile.regs[reg_num]
            );
        end
    end
endtask

initial begin

    errors = 0;
    rst = 1'b1;

    $dumpfile("results/regression.vcd");
    $dumpvars(0, tb_regression);

    #1;

    // ------------------------------------------------------------
    // Program
    // ------------------------------------------------------------

    // ADDI x1, x0, 5
    u_imem.memory[0] = 32'h00500093;

    // ADDI x2, x0, 10
    u_imem.memory[1] = 32'h00A00113;

    // ADD x3, x1, x2 = 15
    u_imem.memory[2] = 32'h002081B3;

    // SUB x4, x2, x1 = 5
    u_imem.memory[3] = 32'h40110233;

    // SW x3, 0(x0)
    u_imem.memory[4] = 32'h00302023;

    // LW x5, 0(x0)
    u_imem.memory[5] = 32'h00002283;

    // ADD x6, x5, x1 = 20
    // Tests load-use hazard
    u_imem.memory[6] = 32'h00128333;

    // BEQ x1, x4, +8
    u_imem.memory[7] = 32'h00408463;

    // Wrong-path: ADDI x7, x0, 99
    u_imem.memory[8] = 32'h06300393;

    // Branch target: ADDI x7, x0, 25
    u_imem.memory[9] = 32'h01900393;

    // JAL x8, +8
    u_imem.memory[10] = 32'h0080046F;

    // Wrong-path: ADDI x9, x0, 99
    u_imem.memory[11] = 32'h06300493;

    // Jump target: ADDI x9, x0, 30
    u_imem.memory[12] = 32'h01E00493;

    #19;
    rst = 1'b0;

    #500;

    $display("");
    $display("========================================");
    $display("       RV32I REGRESSION RESULTS");
    $display("========================================");

    check_reg(1,  32'd5);
    check_reg(2,  32'd10);
    check_reg(3,  32'd15);
    check_reg(4,  32'd5);
    check_reg(5,  32'd15);
    check_reg(6,  32'd20);
    check_reg(7,  32'd25);
    check_reg(9,  32'd30);

    // JAL at PC = 40, therefore link = PC+4 = 44
    check_reg(8,  32'd44);

    if (u_dmem.memory[0] !== 32'd15) begin
        $display(
            "FAIL: Memory[0] = %0d, expected 15",
            u_dmem.memory[0]
        );
        errors = errors + 1;
    end
    else begin
        $display("PASS: Memory[0] = 15");
    end

    $display("----------------------------------------");

    if (errors == 0)
        $display("FINAL RESULT: ALL TESTS PASSED");
    else
        $display("FINAL RESULT: %0d TEST(S) FAILED", errors);

    $display("========================================");
    $finish;
end

endmodule
