module test_reset_halt_tb;
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

    logic [7:0] acc_after;
    logic [7:0] pc_after;

    initial begin
        $display("=== TEST: reset_and_halt (RTL mode) ===");

        // Program: LDI 3; HLT
        dut.imem[0] = 8'h53; // LDI 3
        dut.imem[1] = 8'hF0; // HLT

        // Reset: assert and release, check registers cleared
        rst = 1; #5;
        if (pc != 8'h00 || acc != 8'h00) $display("RESET pre-check: regs not zero (pc=%0d acc=%0d)", pc, acc);
        rst = 0; #10;

        // Wait for halt
        fork
            wait(halt == 1);
            #1000 $display("WARNING: Timeout reached for reset_and_halt test");
        join_any
        disable fork;
        #10;

        // After HLT, record acc and pc
        acc_after = acc;
        pc_after = pc;

        // Wait additional cycles to ensure PC holds
        #50;
        if (pc == pc_after) $display("TEST: halt preserves PC PASS");
        else $display("TEST: halt preserves PC FAIL (was %0d now %0d)", pc_after, pc);

        if (acc == acc_after) $display("TEST: halt preserves ACC PASS");
        else $display("TEST: halt preserves ACC FAIL (was %0d now %0d)", acc_after, acc);

        $finish;
    end
endmodule
