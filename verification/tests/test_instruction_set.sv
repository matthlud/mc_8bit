module test_instruction_set_tb;
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

    task automatic init_dmem(input logic [3:0] addr, input logic [7:0] data);
        @(negedge clk);
        dmem_init_wr_addr = addr;
        dmem_init_wr_data = data;
        dmem_init_wr_en = 1'b1;
        @(negedge clk);
        dmem_init_wr_en = 1'b0;
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
                $fatal(1, "instruction-set program timed out");
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

        $display("=== TEST: instruction_set ===");

        // JMP skips address 1, then exercise LDI, ADD, SUB, STA and HLT.
        init_imem(4'd0, 8'h62); // JMP 2
        init_imem(4'd1, 8'h5F); // skipped LDI 15
        init_imem(4'd2, 8'h55); // LDI 5
        init_imem(4'd3, 8'h31); // ADD [1] -> 8
        init_imem(4'd4, 8'h41); // SUB [1] -> 5
        init_imem(4'd5, 8'h23); // STA [3]
        init_imem(4'd6, 8'h00); // NOP
        init_imem(4'd7, 8'hF0); // HLT
        init_dmem(4'd1, 8'h03);

        rst = 1'b1;
        #1;
        if (pc !== 8'h00 || acc !== 8'h00 || halt !== 1'b0)
            $fatal(1, "reset failed: pc=%0d acc=%0d halt=%b", pc, acc, halt);
        @(negedge clk);
        rst = 1'b0;

        wait_for_halt();
        @(negedge clk);

        if (acc !== 8'd5 || dut.dmem_inst.mem[3] !== 8'd5)
            $fatal(1, "instruction result wrong: acc=%0d dmem[3]=%0d",
                   acc, dut.dmem_inst.mem[3]);
        if (pc !== 8'd7)
            $fatal(1, "JMP/HLT left unexpected PC: %0d", pc);

        $display("TEST: instruction_set PASS");
        $finish;
    end
endmodule
