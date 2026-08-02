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
    // Helper tasks to init memories via synchronous init ports
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
        $display("=== Running in %s mode ===", `ifdef USE_NETLIST "NETLIST" `else "RTL" `endif);

        // Initialize instruction memory with a simple program
        // Program: Load 5, Add 3, Store result, Halt
        init_imem(4'd0, 8'h55);  // LDI 5 (Load immediate 5)
        init_imem(4'd1, 8'h31);  // ADD [1] (Add value at dmem[1])
        init_imem(4'd2, 8'h22);  // STA [2] (Store to dmem[2])
        init_imem(4'd3, 8'h13);  // LDA [3] (Load from dmem[3])
        init_imem(4'd4, 8'h42);  // SUB [2] (Subtract dmem[2])
        init_imem(4'd5, 8'h24);  // STA [4] (Store to dmem[4])
        init_imem(4'd6, 8'hF0);  // HLT (Halt)

        // Initialize data memory
        init_dmem(4'd1, 8'h03);  // Value 3
        init_dmem(4'd3, 8'h0A);  // Value 10

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
        $display("dmem[2] (5+3): %0d", dut.dmem_inst.mem[2]);
        $display("dmem[4] (10-8): %0d", dut.dmem_inst.mem[4]);

        // Verify results
        if (dut.dmem_inst.mem[2] == 8) $display("✓ Addition test passed");
        else $display("✗ Addition test failed");

        if (dut.dmem_inst.mem[4] == 2) $display("✓ Subtraction test passed");
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
        $monitor("Time=%0t PC=%0d ACC=%0d Halt=%b | dmem[1]=%0d dmem[2]=%0d dmem[3]=%0d dmem[4]=%0d",
                 $time, pc, acc, halt, dut.dmem[1], dut.dmem[2], dut.dmem[3], dut.dmem[4]);
    end

endmodule
