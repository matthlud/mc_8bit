// Testbench with RTL/Netlist switch
module cpu_tb_top;
    logic clk;
    logic rst;
    logic [7:0] pc;
    logic [7:0] acc;
    logic halt;

    // Switch between RTL and Netlist simulation
// Top-level cpu instantiation
`ifdef USE_NETLIST
    // Instantiate synthesized netlist and expose top-level debug init/read ports
    logic [3:0] imem_debug_rd_addr;
    logic [7:0] imem_debug_rd_data;
    logic [3:0] dmem_debug_rd_addr;
    logic [7:0] dmem_debug_rd_data;

    cpu dut (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .acc(acc),
        .halt(halt),
        .imem_init_wr_en(1'b0), .imem_init_wr_addr(4'h0), .imem_init_wr_data(8'h00),
        .dmem_init_wr_en(1'b0), .dmem_init_wr_addr(4'h0), .dmem_init_wr_data(8'h00),
        .imem_debug_rd_addr(imem_debug_rd_addr), .imem_debug_rd_data(imem_debug_rd_data),
        .dmem_debug_rd_addr(dmem_debug_rd_addr), .dmem_debug_rd_data(dmem_debug_rd_data)
    );
`else
    // Instantiate RTL with hierarchical mem access allowed
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
`ifdef USE_NETLIST
        // Drive top-level cpu init ports in netlist mode
        dut.imem_init_wr_addr = addr;
        dut.imem_init_wr_data = data;
        dut.imem_init_wr_en = 1;
        @(posedge clk);
        dut.imem_init_wr_en = 0;
`else
        // Hierarchical init for RTL
        @(posedge clk);
        dut.imem_inst.init_wr_addr = addr;
        dut.imem_inst.init_wr_data = data;
        dut.imem_inst.init_wr_en = 1;
        @(posedge clk);
        dut.imem_inst.init_wr_en = 0;
`endif
    end
    endtask

    task automatic init_dmem(input [3:0] addr, input [7:0] data);
    begin
        @(posedge clk);
`ifdef USE_NETLIST
        // Drive top-level cpu init ports in netlist mode
        dut.dmem_init_wr_addr = addr;
        dut.dmem_init_wr_data = data;
        dut.dmem_init_wr_en = 1;
        @(posedge clk);
        dut.dmem_init_wr_en = 0;
`else
        // Hierarchical init for RTL
        @(posedge clk);
        dut.dmem_inst.init_wr_addr = addr;
        dut.dmem_inst.init_wr_data = data;
        dut.dmem_inst.init_wr_en = 1;
        @(posedge clk);
        dut.dmem_inst.init_wr_en = 0;
`endif
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
`ifdef USE_NETLIST
        // Read results via top-level debug ports in netlist mode
        dmem_debug_rd_addr = 4'd2; #1;
        $display("dmem[2] (5+3): %0d", dmem_debug_rd_data);
        dmem_debug_rd_addr = 4'd4; #1;
        $display("dmem[4] (10-8): %0d", dmem_debug_rd_data);

        // Verify results
        if (dmem_debug_rd_data == 2 && dmem_debug_rd_addr == 4'd4) begin
            // second read checked above, also check first read separately
            dmem_debug_rd_addr = 4'd2; #1;
            if (dmem_debug_rd_data == 8) $display("✓ Addition test passed");
            else $display("✗ Addition test failed");
        end else begin
            $display("✗ Subtraction test failed (read value mismatch)");
        end
`else
        $display("dmem[2] (5+3): %0d", dut.dmem_inst.mem[2]);
        $display("dmem[4] (10-8): %0d", dut.dmem_inst.mem[4]);

        // Verify results
        if (dut.dmem_inst.mem[2] == 8) $display("✓ Addition test passed");
        else $display("✗ Addition test failed");

        if (dut.dmem_inst.mem[4] == 2) $display("✓ Subtraction test passed");
        else $display("✗ Subtraction test failed");

`endif

        $finish;
    end

    // Waveform dump (for viewing in simulator)
    initial begin
        $dumpfile("./artifacts/cpu.vcd");
        $dumpvars(0, cpu_tb_top);
    end

    // Monitor
    initial begin
`ifdef USE_NETLIST
        $monitor("Time=%0t PC=%0d ACC=%0d Halt=%b | dmem[1]=%0d dmem[2]=%0d dmem[3]=%0d dmem[4]=%0d",
                 $time, pc, acc, halt, dmem_debug_rd_data, dmem_debug_rd_data, dmem_debug_rd_data, dmem_debug_rd_data);
`else
        $monitor("Time=%0t PC=%0d ACC=%0d Halt=%b | dmem[1]=%0d dmem[2]=%0d dmem[3]=%0d dmem[4]=%0d",
                 $time, pc, acc, halt, dut.dmem[1], dut.dmem[2], dut.dmem[3], dut.dmem[4]);
`endif
    end

endmodule
