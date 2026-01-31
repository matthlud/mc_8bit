// Simple 8-bit Microprocessor
module cpu (
    input logic clk,
    input logic rst,
    output logic [7:0] pc,      // Program counter
    output logic [7:0] acc,     // Accumulator
    output logic halt           // Halt signal
);

    // Instruction memory (16 bytes)
    logic [7:0] imem [0:15];

    // Data memory (16 bytes)
    logic [7:0] dmem [0:15];

    // Internal registers
    logic [7:0] ir;             // Instruction register
    logic [7:0] next_pc;
    logic [7:0] next_acc;
    logic next_halt;

    // Instruction format: [3:0] = opcode, [7:4] = operand/address
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
        // Default values
        next_pc = pc + 1;
        next_acc = acc;
        next_halt = halt;

        if (!halt) begin
            ir = imem[pc];

            case (ir[3:0])
                NOP: begin
                    // Do nothing
                end

                LDA: begin
                    next_acc = dmem[ir[7:4]];
                end

                STA: begin
                    dmem[ir[7:4]] = acc;
                end

                ADD: begin
                    next_acc = acc + dmem[ir[7:4]];
                end

                SUB: begin
                    next_acc = acc - dmem[ir[7:4]];
                end

                LDI: begin
                    next_acc = ir[7:4];
                end

                JMP: begin
                    next_pc = ir[7:4];
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
