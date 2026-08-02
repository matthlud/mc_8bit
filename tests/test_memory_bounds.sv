module test_memory_bounds_tb;
    logic clk;
    logic rst;
    logic [7:0] pc;
    logic [7:0] acc;
    logic halt;

`ifdef USE_NETLIST
    cpu dut (
        .clk(clk), .rst(rst), .pc(pc), .acc(acc), .halt(halt)
    );
`else
    cpu dut (.*);
`endif

    initial begin
        clk = 0; forever #5 clk = ~clk;
    end

    // helper tasks
    task automatic init_imem(input [3:0] addr, input [7:0] data);
    begin
        @(posedge clk);
        dut.imem_inst.init_wr_addr = addr;
        dut.imem_inst.init_wr_data = data;
        dut.imem_inst.init_wr_en = 1;
        @(posedge clk);
        dut.imem_inst.init_wr_en = 0;
    end
    endtask

    task automatic init_dmem(input [3:0] addr, input [7:0] data);
    begin
        @(posedge clk);
        dut.dmem_inst.init_wr_addr = addr;
        dut.dmem_inst.init_wr_data = data;
        dut.dmem_inst.init_wr_en = 1;
        @(posedge clk);
        dut.dmem_inst.init_wr_en = 0;
    end
    endtask

    initial begin
        $display("=== TEST: memory_bounds (RTL mode) ===");

        // Test accesses to edge addresses: 0x0 and 0xF (lower 4 bits used)
        init_imem(4'd0, 8'h51); // LDI 1
        init_imem(4'd1, 8'h20); // STA [0]
        init_imem(4'd2, 8'h5F); // LDI 15
        init_imem(4'd3, 8'h2F); // STA [15]
        init_imem(4'd4, 8'h10); // LDA [0]
        init_imem(4'd5, 8'hF0); // HLT

        // Reset
        rst = 1; #15; rst = 0;

        // Wait for halt
        fork
            wait(halt == 1);
            #1000 $display("WARNING: Timeout reached for memory_bounds test");
        join_any
        disable fork;
        #20;

        if (dut.dmem_inst.mem[0] == 1 && dut.dmem_inst.mem[15] == 15) $display("TEST: memory_bounds PASS");
        else $display("TEST: memory_bounds FAIL (dmem0=%0d dmem15=%0d)", dut.dmem_inst.mem[0], dut.dmem_inst.mem[15]);

        $finish;
    end
endmodule
