module rv32i_core (
    input  wire        clk,
    input  wire        rst,

    // Instruction memory interface
    output wire [31:0] instr_addr,
    input  wire [31:0] instr_rdata,

    // Data memory interface
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    output wire        data_read,
    output wire        data_write,
    input  wire [31:0] data_rdata,

    output wire [31:0] debug_pc
);

    // ============================================================
    // IF STAGE
    // ============================================================

    wire [31:0] pc_current;
    wire [31:0] pc_plus4_if;
    wire [31:0] pc_next;

    wire pc_write;
    wire if_id_write;
    wire control_flush;

    wire redirect_ex;
    wire [31:0] redirect_target_ex;

    assign pc_plus4_if = pc_current + 32'd4;
    assign pc_next     = redirect_ex ? redirect_target_ex : pc_plus4_if;

    pc u_pc (
        .clk     (clk),
        .rst     (rst),
        .enable  (pc_write | redirect_ex),
        .next_pc (pc_next),
        .pc_out  (pc_current)
    );

    assign instr_addr = pc_current;
    assign debug_pc   = pc_current;

    // ============================================================
    // IF / ID PIPELINE REGISTER
    // ============================================================

    wire [31:0] if_id_pc;
    wire [31:0] if_id_instr;

    if_id_reg u_if_id (
        .clk       (clk),
        .rst       (rst),
        .enable    (if_id_write),
        .flush     (redirect_ex),

        .pc_in     (pc_current),
        .instr_in  (instr_rdata),

        .pc_out    (if_id_pc),
        .instr_out (if_id_instr)
    );

    // ============================================================
    // ID STAGE
    // ============================================================

    wire [6:0] opcode_id;
    wire [4:0] rs1_id;
    wire [4:0] rs2_id;
    wire [4:0] rd_id;
    wire [2:0] funct3_id;
    wire [6:0] funct7_id;

    assign opcode_id = if_id_instr[6:0];
    assign rd_id     = if_id_instr[11:7];
    assign funct3_id = if_id_instr[14:12];
    assign rs1_id    = if_id_instr[19:15];
    assign rs2_id    = if_id_instr[24:20];
    assign funct7_id = if_id_instr[31:25];

    wire reg_write_id;
    wire mem_read_id;
    wire mem_write_id;
    wire mem_to_reg_id;
    wire alu_src_id;
    wire branch_id;
    wire jump_id;
    wire [1:0] alu_op_id;
    wire [2:0] imm_sel_id;

    control_unit u_control (
        .opcode      (opcode_id),
        .reg_write   (reg_write_id),
        .mem_read    (mem_read_id),
        .mem_write   (mem_write_id),
        .mem_to_reg  (mem_to_reg_id),
        .alu_src     (alu_src_id),
        .branch      (branch_id),
        .jump        (jump_id),
        .alu_op      (alu_op_id),
        .imm_sel     (imm_sel_id)
    );

    wire [31:0] imm_id;

    imm_gen u_imm_gen (
        .instr   (if_id_instr),
        .imm_sel (imm_sel_id),
        .imm     (imm_id)
    );

    // ============================================================
    // WB SIGNALS
    // ============================================================

    wire [4:0]  mem_wb_rd;
    wire        mem_wb_reg_write;
    wire        mem_wb_mem_to_reg;
    wire        mem_wb_jump;

    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_data;
    wire [31:0] mem_wb_pc_plus4;

    wire [31:0] wb_data;

    assign wb_data =
        mem_wb_jump       ? mem_wb_pc_plus4 :
        mem_wb_mem_to_reg ? mem_wb_mem_data :
                            mem_wb_alu_result;

    // ============================================================
    // REGISTER FILE
    // ============================================================

    wire [31:0] rs1_data_id;
    wire [31:0] rs2_data_id;

    regfile u_regfile (
        .clk (clk),
        .we  (mem_wb_reg_write),
        .rs1 (rs1_id),
        .rs2 (rs2_id),
        .rd  (mem_wb_rd),
        .wd  (wb_data),
        .rd1 (rs1_data_id),
        .rd2 (rs2_data_id)
    );

    // ============================================================
    // HAZARD DETECTION
    // ============================================================

    wire       id_ex_mem_read;
    wire [4:0] id_ex_rd;

    hazard_unit u_hazard (
        .id_ex_mem_read (id_ex_mem_read),
        .id_ex_rd       (id_ex_rd),
        .if_id_rs1      (rs1_id),
        .if_id_rs2      (rs2_id),

        .pc_write       (pc_write),
        .if_id_write    (if_id_write),
        .control_flush  (control_flush)
    );

    // ============================================================
    // ID / EX PIPELINE REGISTER
    // ============================================================

    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [31:0] id_ex_imm;

    wire [4:0] id_ex_rs1;
    wire [4:0] id_ex_rs2;

    wire [2:0] id_ex_funct3;
    wire [6:0] id_ex_funct7;

    wire id_ex_reg_write;
    wire id_ex_mem_write;
    wire id_ex_mem_to_reg;
    wire id_ex_alu_src;
    wire id_ex_branch;
    wire id_ex_jump;
    wire [1:0] id_ex_alu_op;

    id_ex_reg u_id_ex (
        .clk            (clk),
        .rst            (rst),
        .flush          (control_flush | redirect_ex),

        .pc_in          (if_id_pc),
        .rs1_data_in    (rs1_data_id),
        .rs2_data_in    (rs2_data_id),
        .imm_in         (imm_id),

        .rs1_in         (rs1_id),
        .rs2_in         (rs2_id),
        .rd_in          (rd_id),

        .funct3_in      (funct3_id),
        .funct7_in      (funct7_id),

        .reg_write_in   (reg_write_id),
        .mem_read_in    (mem_read_id),
        .mem_write_in   (mem_write_id),
        .mem_to_reg_in  (mem_to_reg_id),
        .alu_src_in     (alu_src_id),
        .branch_in      (branch_id),
        .jump_in        (jump_id),
        .alu_op_in      (alu_op_id),

        .pc_out         (id_ex_pc),
        .rs1_data_out   (id_ex_rs1_data),
        .rs2_data_out   (id_ex_rs2_data),
        .imm_out        (id_ex_imm),

        .rs1_out        (id_ex_rs1),
        .rs2_out        (id_ex_rs2),
        .rd_out         (id_ex_rd),

        .funct3_out     (id_ex_funct3),
        .funct7_out     (id_ex_funct7),

        .reg_write_out  (id_ex_reg_write),
        .mem_read_out   (id_ex_mem_read),
        .mem_write_out  (id_ex_mem_write),
        .mem_to_reg_out (id_ex_mem_to_reg),
        .alu_src_out    (id_ex_alu_src),
        .branch_out     (id_ex_branch),
        .jump_out       (id_ex_jump),
        .alu_op_out     (id_ex_alu_op)
    );

    // ============================================================
    // EX STAGE - FORWARDING
    // ============================================================

    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_pc_plus4;
    wire [4:0]  ex_mem_rd;
    wire        ex_mem_reg_write;
    wire        ex_mem_jump;

    wire [1:0] forward_a;
    wire [1:0] forward_b;

    forwarding_unit u_forward (
        .ex_mem_reg_write (ex_mem_reg_write),
        .mem_wb_reg_write (mem_wb_reg_write),

        .ex_mem_rd        (ex_mem_rd),
        .mem_wb_rd        (mem_wb_rd),

        .id_ex_rs1        (id_ex_rs1),
        .id_ex_rs2        (id_ex_rs2),

        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    wire [31:0] ex_mem_forward_value;

    assign ex_mem_forward_value =
        ex_mem_jump ? ex_mem_pc_plus4 : ex_mem_alu_result;

    reg [31:0] forwarded_a;
    reg [31:0] forwarded_b;

    always @(*) begin
        case (forward_a)
            2'b10: forwarded_a = ex_mem_forward_value;
            2'b01: forwarded_a = wb_data;
            default: forwarded_a = id_ex_rs1_data;
        endcase

        case (forward_b)
            2'b10: forwarded_b = ex_mem_forward_value;
            2'b01: forwarded_b = wb_data;
            default: forwarded_b = id_ex_rs2_data;
        endcase
    end

    // ============================================================
    // ALU CONTROL
    // ============================================================

    wire [3:0] alu_ctrl_ex;

    alu_control u_alu_control (
        .alu_op   (id_ex_alu_op),
        .funct3   (id_ex_funct3),
        .funct7   (id_ex_funct7),
        .alu_ctrl (alu_ctrl_ex)
    );

    // ============================================================
    // ALU
    // ============================================================

    wire [31:0] alu_operand_b;
    wire [31:0] alu_result_ex;
    wire        alu_zero_ex;

    assign alu_operand_b =
        id_ex_alu_src ? id_ex_imm : forwarded_b;

    alu u_alu (
        .a        (forwarded_a),
        .b        (alu_operand_b),
        .alu_ctrl (alu_ctrl_ex),
        .result   (alu_result_ex),
        .zero     (alu_zero_ex)
    );

    // ============================================================
    // BRANCH / JUMP
    // ============================================================

    wire branch_condition_ex;

    branch_unit u_branch (
        .a            (forwarded_a),
        .b            (forwarded_b),
        .funct3       (id_ex_funct3),
        .branch_taken (branch_condition_ex)
    );

    wire branch_taken_ex;
    wire [31:0] branch_target_ex;
    wire [31:0] pc_plus4_ex;

    assign branch_taken_ex  = id_ex_branch && branch_condition_ex;
    assign branch_target_ex = id_ex_pc + id_ex_imm;
    assign pc_plus4_ex       = id_ex_pc + 32'd4;

    assign redirect_ex        = branch_taken_ex | id_ex_jump;
    assign redirect_target_ex = branch_target_ex;

    // ============================================================
    // EX / MEM PIPELINE REGISTER
    // ============================================================

    wire [31:0] ex_mem_rs2_data;
    wire [31:0] ex_mem_branch_target;
    wire        ex_mem_branch_taken;
    wire        ex_mem_mem_read;
    wire        ex_mem_mem_write;
    wire        ex_mem_mem_to_reg;

    ex_mem_reg u_ex_mem (
        .clk               (clk),
        .rst               (rst),

        .alu_result_in     (alu_result_ex),
        .rs2_data_in       (forwarded_b),
        .branch_target_in  (branch_target_ex),
        .pc_plus4_in       (pc_plus4_ex),
        .branch_taken_in   (branch_taken_ex),

        .rd_in             (id_ex_rd),

        .reg_write_in      (id_ex_reg_write),
        .mem_read_in       (id_ex_mem_read),
        .mem_write_in      (id_ex_mem_write),
        .mem_to_reg_in     (id_ex_mem_to_reg),
        .jump_in           (id_ex_jump),

        .alu_result_out    (ex_mem_alu_result),
        .rs2_data_out      (ex_mem_rs2_data),
        .branch_target_out (ex_mem_branch_target),
        .pc_plus4_out      (ex_mem_pc_plus4),
        .branch_taken_out  (ex_mem_branch_taken),

        .rd_out            (ex_mem_rd),

        .reg_write_out     (ex_mem_reg_write),
        .mem_read_out      (ex_mem_mem_read),
        .mem_write_out     (ex_mem_mem_write),
        .mem_to_reg_out    (ex_mem_mem_to_reg),
        .jump_out          (ex_mem_jump)
    );

    // ============================================================
    // MEM STAGE
    // ============================================================

    assign data_addr  = ex_mem_alu_result;
    assign data_wdata = ex_mem_rs2_data;
    assign data_read  = ex_mem_mem_read;
    assign data_write = ex_mem_mem_write;

    // ============================================================
    // MEM / WB PIPELINE REGISTER
    // ============================================================

    mem_wb_reg u_mem_wb (
        .clk            (clk),
        .rst            (rst),

        .alu_result_in  (ex_mem_alu_result),
        .mem_data_in    (data_rdata),
        .pc_plus4_in    (ex_mem_pc_plus4),

        .rd_in          (ex_mem_rd),

        .reg_write_in   (ex_mem_reg_write),
        .mem_to_reg_in  (ex_mem_mem_to_reg),
        .jump_in        (ex_mem_jump),

        .alu_result_out (mem_wb_alu_result),
        .mem_data_out   (mem_wb_mem_data),
        .pc_plus4_out   (mem_wb_pc_plus4),

        .rd_out         (mem_wb_rd),

        .reg_write_out  (mem_wb_reg_write),
        .mem_to_reg_out (mem_wb_mem_to_reg),
        .jump_out       (mem_wb_jump)
    );

endmodule