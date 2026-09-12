module test_memory_bounds_tb;
    logic clk;
    logic rst;
    logic [7:0] pc;
    logic [7:0] acc;
    logic halt;

    logic imem_init_wr_en;
    logic [3:0] imem_init_wr_addr;
    logic [7:0] imem_init_wr_data;
    logic dmem_init_wr_en;
    logic [3:0] dmem_init_wr_addr;
    logic [7:0] dmem_init_wr_data;

    cpu dut (
        .clk(clk), .rst(rst), .pc(pc), .acc(acc), .halt(halt),
        .imem_init_wr_en(imem_init_wr_en),
        .imem_init_wr_addr(imem_init_wr_addr),
        .imem_init_wr_data(imem_init_wr_data),
        .dmem_init_wr_en(dmem_init_wr_en),
        .dmem_init_wr_addr(dmem_init_wr_addr),
        .dmem_init_wr_data(dmem_init_wr_data)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic init_imem(input logic [3:0] addr, input logic [7:0] data);
        @(negedge clk);
        imem_init_wr_addr = addr;
        imem_init_wr_data = data;
        imem_init_wr_en = 1'b1;
        @(negedge clk);
        imem_init_wr_en = 1'b0;
    endtask

    task automatic wait_for_halt;
        integer cycle;
        logic halted_seen;
        begin
            halted_seen = 1'b0;
            begin : wait_loop
                for (cycle = 0; cycle < 200; cycle = cycle + 1) begin
                    @(posedge clk);
                    #1;
                    if (halt === 1'b1) begin
                        halted_seen = 1'b1;
                        disable wait_loop;
                    end
                end
            end
            if (!halted_seen)
                $fatal(1, "memory_bounds program timed out");
        end
    endtask

    initial begin
        rst = 1'b0;
        imem_init_wr_en = 1'b0;
        imem_init_wr_addr = 4'h0;
        imem_init_wr_data = 8'h00;
        dmem_init_wr_en = 1'b0;
        dmem_init_wr_addr = 4'h0;
        dmem_init_wr_data = 8'h00;

        $display("=== TEST: memory_bounds ===");

        // Test both edge addresses of the 16-byte data memory.
        init_imem(4'd0, 8'h51); // LDI 1
        init_imem(4'd1, 8'h20); // STA [0]
        init_imem(4'd2, 8'h5F); // LDI 15
        init_imem(4'd3, 8'h2F); // STA [15]
        init_imem(4'd4, 8'h10); // LDA [0]
        init_imem(4'd5, 8'hF0); // HLT

        rst = 1'b1;
        #1;
        if (pc !== 8'h00 || acc !== 8'h00 || halt !== 1'b0)
            $fatal(1, "reset failed: pc=%0d acc=%0d halt=%b", pc, acc, halt);
        @(negedge clk);
        rst = 1'b0;

        wait_for_halt();
        @(negedge clk);

        if (dut.dmem_inst.mem[0] !== 8'd1 || dut.dmem_inst.mem[15] !== 8'd15)
            $fatal(1, "edge memory values wrong: dmem[0]=%0d dmem[15]=%0d",
                   dut.dmem_inst.mem[0], dut.dmem_inst.mem[15]);

        $display("TEST: memory_bounds PASS");
        $finish;
    end
endmodule
