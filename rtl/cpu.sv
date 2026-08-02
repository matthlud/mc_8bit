// Simple 8-bit Microprocessor
module cpu (
    input logic clk,
    input logic rst,
    output logic [7:0] pc,      // Program counter
    output logic [7:0] acc,     // Accumulator
    output logic halt           // Halt signal
);

    // Replace internal memories with memory module instances
    // Internal registers
    logic [7:0] ir;             // Instruction register
    logic [7:0] next_pc;
    logic [7:0] next_acc;
    logic next_halt;
    logic mem_wr_en;            // Memory write enable
    logic [3:0] mem_wr_addr;    // Memory write address
    logic [7:0] mem_wr_data;    // Memory write data

    // Memory module interfaces
    logic [7:0] imem_rd_data;
    logic imem_init_wr_en;
    logic [3:0] imem_init_wr_addr;
    logic [7:0] imem_init_wr_data;

    logic [7:0] dmem_rd_data;
    logic [3:0] dmem_rd_addr;
    logic dmem_init_wr_en;
    logic [3:0] dmem_init_wr_addr;
    logic [7:0] dmem_init_wr_data;

    // Instantiate memories
    mem_imem16x8 imem_inst (
        .clk(clk),
        .rd_addr(pc[3:0]),
        .rd_data(imem_rd_data),
        .init_wr_en(imem_init_wr_en),
        .init_wr_addr(imem_init_wr_addr),
        .init_wr_data(imem_init_wr_data)
    );

    mem_dmem16x8 dmem_inst (
        .clk(clk),
        .wr_en(mem_wr_en),
        .wr_addr(mem_wr_addr),
        .wr_data(mem_wr_data),
        .rd_addr(dmem_rd_addr),
        .rd_data(dmem_rd_data),
        .init_wr_en(dmem_init_wr_en),
        .init_wr_addr(dmem_init_wr_addr),
        .init_wr_data(dmem_init_wr_data)
    );

    // Instruction format: [7:4] = opcode, [3:0] = operand/address
    localparam [3:0] NOP  = 4'h0;  // No operation
    localparam [3:0] LDA  = 4'h1;  // Load from memory to accumulator
    localparam [3:0] STA  = 4'h2;  // Store accumulator to memory
    localparam [3:0] ADD  = 4'h3;  // Add memory to accumulator
    localparam [3:0] SUB  = 4'h4;  // Subtract memory from accumulator
    localparam [3:0] LDI  = 4'h5;  // Load immediate to accumulator
    localparam [3:0] JMP  = 4'h6;  // Jump to address
    localparam [3:0] HLT  = 4'hF;  // Halt

    // Sequential logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 8'h0;
            acc <= 8'h0;
            halt <= 1'b0;
        end else begin
            pc <= next_pc;
            acc <= next_acc;
            halt <= next_halt;

        end
    end

    // Combinational logic for instruction execution
    always_comb begin
        // Extract instruction fields
        logic [3:0] opcode;
        logic [3:0] operand;

        // Default values
        next_pc = pc + 1;
        next_acc = acc;
        next_halt = halt;

        mem_wr_en = 1'b0;
        mem_wr_addr = 4'h0;
        mem_wr_data = 8'h0;

        ir = imem_rd_data;
        opcode = ir[7:4];
        operand = ir[3:0];
        // set data memory read address
        dmem_rd_addr = operand;

        if (!halt) begin
            case (opcode)
                NOP: begin
                    // Do nothing
                end

                LDA: begin
                    next_acc = dmem_rd_data;
                end

                STA: begin
                    mem_wr_en = 1'b1;
                    mem_wr_addr = operand;
                    mem_wr_data = acc;
                end

                ADD: begin
                    next_acc = acc + dmem_rd_data;
                end

                SUB: begin
                    next_acc = acc - dmem_rd_data;
                end

                LDI: begin
                    next_acc = operand;
                end

                JMP: begin
                    next_pc = {4'h0, operand};
                end

                HLT: begin
                    next_halt = 1'b1;
                    next_pc = pc;  // Stop incrementing PC
                end

                default: begin
                    // Treat unknown opcodes as NOP
                end
            endcase
        end else begin
            next_pc = pc;  // Hold PC when halted
        end
    end

endmodule
