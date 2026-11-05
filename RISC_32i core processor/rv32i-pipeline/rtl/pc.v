module pc (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire [31:0] next_pc,
    output reg  [31:0] pc_out
);

always @(posedge clk) begin
    if (rst)
        pc_out <= 32'd0;
    else if (enable)
        pc_out <= next_pc;
end

endmodule
