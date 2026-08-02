// 16x8 Data Memory with synchronous write and init-write interface
module mem_dmem16x8 (
    input logic clk,
    input logic wr_en,
    input logic [3:0] wr_addr,
    input logic [7:0] wr_data,
    input logic [3:0] rd_addr,
    output logic [7:0] rd_data,

    // init interface (synchronous writes)
    input logic init_wr_en,
    input logic [3:0] init_wr_addr,
    input logic [7:0] init_wr_data
);

    logic [7:0] mem [0:15];

    // synchronous writes (normal operation)
    always_ff @(posedge clk) begin
        if (wr_en) mem[wr_addr] <= wr_data;
        if (init_wr_en) mem[init_wr_addr] <= init_wr_data;
    end

    // combinational read
    always_comb begin
        rd_data = mem[rd_addr];
    end

endmodule
