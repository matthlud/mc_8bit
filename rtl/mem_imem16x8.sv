// 16x8 Instruction Memory with synchronous init-write interface
module mem_imem16x8 (
    input logic clk,
    input logic [3:0] rd_addr,
    output logic [7:0] rd_data,

    // init interface (synchronous writes)
    input logic init_wr_en,
    input logic [3:0] init_wr_addr,
    input logic [7:0] init_wr_data
);

    logic [7:0] mem [0:15];

    // synchronous init writes
    always_ff @(posedge clk) begin
        if (init_wr_en) mem[init_wr_addr] <= init_wr_data;
    end

    // combinational read
    always_comb begin
        rd_data = mem[rd_addr];
    end

endmodule
