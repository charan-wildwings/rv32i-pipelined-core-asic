`timescale 1ns/1ps

module tb_alu;

reg  [31:0] a;
reg  [31:0] b;
reg  [3:0]  alu_ctrl;

wire [31:0] result;
wire        zero;

alu uut (
    .a(a),
    .b(b),
    .alu_ctrl(alu_ctrl),
    .result(result),
    .zero(zero)
);

initial begin
    $dumpfile("results/alu_waveform.vcd");
    $dumpvars(0, tb_alu);

    // ADD
    a = 32'd10;
    b = 32'd5;
    alu_ctrl = 4'b0000;
    #10;

    // SUB
    alu_ctrl = 4'b0001;
    #10;

    // AND
    a = 32'hFFFF0000;
    b = 32'h0F0F0F0F;
    alu_ctrl = 4'b0010;
    #10;

    // OR
    alu_ctrl = 4'b0011;
    #10;

    // XOR
    alu_ctrl = 4'b0100;
    #10;

    // SLL
    a = 32'd1;
    b = 32'd4;
    alu_ctrl = 4'b0101;
    #10;

    // SRL
    a = 32'd16;
    b = 32'd2;
    alu_ctrl = 4'b0110;
    #10;

    // SLT
    a = 32'd5;
    b = 32'd10;
    alu_ctrl = 4'b0111;
    #10;

    $finish;
end

initial begin
    $monitor(
        "Time=%0t A=%h B=%h CTRL=%b RESULT=%h ZERO=%b",
        $time, a, b, alu_ctrl, result, zero
    );
end

endmodule
