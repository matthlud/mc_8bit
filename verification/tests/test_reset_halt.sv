module test_reset_halt_tb;
    logic clk;
    logic rst;
    logic [7:0] pc;
    logic [7:0] acc;
    logic halt;

`ifdef USE_NETLIST
    // Top-level init signals for netlist-mode (drive these from tests)
    logic imem_init_wr_en;
    logic [3:0] imem_init_wr_addr;
    logic [7:0] imem_init_wr_data;

    logic dmem_init_wr_en;
    logic [3:0] dmem_init_wr_addr;
    logic [7:0] dmem_init_wr_data;

    cpu dut (
        .clk(clk), .rst(rst), .pc(pc), .acc(acc), .halt(halt),
        .imem_init_wr_en(imem_init_wr_en), .imem_init_wr_addr(imem_init_wr_addr), .imem_init_wr_data(imem_init_wr_data),
        .dmem_init_wr_en(dmem_init_wr_en), .dmem_init_wr_addr(dmem_init_wr_addr), .dmem_init_wr_data(dmem_init_wr_data)
    );
`else
    cpu dut (
        .clk(clk), .rst(rst), .pc(pc), .acc(acc), .halt(halt),
        .imem_init_wr_en(1'b0), .imem_init_wr_addr(4'h0), .imem_init_wr_data(8'h00),
        .dmem_init_wr_en(1'b0), .dmem_init_wr_addr(4'h0), .dmem_init_wr_data(8'h00)
    );
`endif

    initial begin
        clk = 0; forever #5 clk = ~clk;
    end

    logic [7:0] acc_after;
    logic [7:0] pc_after;

    // helper task
    task automatic init_imem(input [3:0] addr, input [7:0] data);
    begin
`ifdef USE_NETLIST
        @(posedge clk);
        imem_init_wr_addr = addr;
        imem_init_wr_data = data;
        imem_init_wr_en = 1;
        @(posedge clk);
        imem_init_wr_en = 0;
`else
        @(posedge clk);
        dut.imem_inst.init_wr_addr = addr;
        dut.imem_inst.init_wr_data = data;
        dut.imem_inst.init_wr_en = 1;
        @(posedge clk);
        dut.imem_inst.init_wr_en = 0;
`endif
    end
    endtask

    initial begin
        $display("=== TEST: reset_and_halt (RTL mode) ===");

        // Program: LDI 3; HLT
        init_imem(4'd0, 8'h53); // LDI 3
        init_imem(4'd1, 8'hF0); // HLT

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
