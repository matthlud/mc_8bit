// Testbench with RTL/Netlist switch
module cpu_tb_top;
    logic clk;
    logic rst;
    logic [7:0] pc;
    logic [7:0] acc;
    logic halt;

    // Switch between RTL and Netlist simulation
`ifdef USE_NETLIST
    // Instantiate synthesized netlist
    cpu dut (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .acc(acc),
        .halt(halt)
    );
`else
    // Instantiate RTL
    cpu dut (.*);
`endif

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test program
    initial begin
        $display("=== Running in %s mode ===", `ifdef USE_NETLIST "NETLIST" `else "RTL" `endif);

        // Initialize instruction memory with a simple program
        // Program: Load 5, Add 3, Store result, Halt

        dut.imem[0] = 8'h51;  // LDI 5 (Load immediate 5)
        dut.imem[1] = 8'h31;  // ADD [1] (Add value at dmem[1])
        dut.imem[2] = 8'h22;  // STA [2] (Store to dmem[2])
        dut.imem[3] = 8'h13;  // LDA [3] (Load from dmem[3])
        dut.imem[4] = 8'h42;  // SUB [2] (Subtract dmem[2])
        dut.imem[5] = 8'h24;  // STA [4] (Store to dmem[4])
        dut.imem[6] = 8'hF0;  // HLT (Halt)

        // Initialize data memory
        dut.dmem[1] = 8'h03;  // Value 3
        dut.dmem[3] = 8'h0A;  // Value 10

        // Reset sequence
        rst = 1;
        #15;
        rst = 0;

        // Run until halt or timeout
        fork
            wait(halt == 1);
            #1000 $display("WARNING: Timeout reached");
        join_any
        disable fork;
        #20;

        // Display results
        $display("=== Test Results ===");
        $display("Final PC: %0d", pc);
        $display("Final ACC: %0d", acc);
        $display("dmem[2] (5+3): %0d", dut.dmem[2]);
        $display("dmem[4] (10-8): %0d", dut.dmem[4]);

        // Verify results
        if (dut.dmem[2] == 8) $display("✓ Addition test passed");
        else $display("✗ Addition test failed");

        if (dut.dmem[4] == 2) $display("✓ Subtraction test passed");
        else $display("✗ Subtraction test failed");

        $finish;
    end

    // Waveform dump (for viewing in simulator)
    initial begin
        $dumpfile("./artifacts/cpu.vcd");
        $dumpvars(0, cpu_tb_top);
    end

    // Monitor
    initial begin
        $monitor("Time=%0t PC=%0d ACC=%0d Halt=%b",
                 $time, pc, acc, halt);
    end

endmodule
