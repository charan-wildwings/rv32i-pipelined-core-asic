`timescale 1ns/1ps

module tb_control_unit;

reg [6:0] opcode;

wire reg_write;
wire mem_read;
wire mem_write;
wire mem_to_reg;
wire alu_src;
wire branch;
wire jump;
wire [1:0] alu_op;
wire [2:0] imm_sel;

control_unit uut (
    .opcode(opcode),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .alu_src(alu_src),
    .branch(branch),
    .jump(jump),
    .alu_op(alu_op),
    .imm_sel(imm_sel)
);

initial begin
    $monitor(
        "opcode=%b reg_write=%b mem_read=%b mem_write=%b alu_src=%b branch=%b jump=%b alu_op=%b imm_sel=%b",
        opcode, reg_write, mem_read, mem_write, alu_src,
        branch, jump, alu_op, imm_sel
    );

    opcode = 7'b0110011; #10; // R-type
    opcode = 7'b0010011; #10; // I-type
    opcode = 7'b0000011; #10; // LW
    opcode = 7'b0100011; #10; // SW
    opcode = 7'b1100011; #10; // Branch
    opcode = 7'b0110111; #10; // LUI
    opcode = 7'b1101111; #10; // JAL

    $finish;
end

endmodule
