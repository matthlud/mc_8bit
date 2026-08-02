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

    initial begin
        $display("=== TEST: memory_bounds (RTL mode) ===");

        // Test accesses to edge addresses: 0x0 and 0xF (lower 4 bits used)
        dut.imem[0] = 8'h51; // LDI 1
        dut.imem[1] = 8'h20; // STA [0]
        dut.imem[2] = 8'h5F; // LDI 15
        dut.imem[3] = 8'h2F; // STA [15]
        dut.imem[4] = 8'h10; // LDA [0]
        dut.imem[5] = 8'hF0; // HLT

        // Reset
        rst = 1; #15; rst = 0;

        // Wait for halt
        fork
            wait(halt == 1);
            #1000 $display("WARNING: Timeout reached for memory_bounds test");
        join_any
        disable fork;
        #20;

        if (dut.dmem[0] == 1 && dut.dmem[15] == 15) $display("TEST: memory_bounds PASS");
        else $display("TEST: memory_bounds FAIL (dmem0=%0d dmem15=%0d)", dut.dmem[0], dut.dmem[15]);

        $finish;
    end
endmodule
