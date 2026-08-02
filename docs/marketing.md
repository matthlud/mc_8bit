# Marketing Brief — Simple 8-bit CPU

Overview
- Tiny, single-cycle 8-bit accumulator CPU with 16-byte instruction and data memories.
- Simple instruction set: NOP, LDA, STA, ADD, SUB, LDI, JMP, HLT.
- Public repository includes RTL (SystemVerilog), verification harness and Yosys synthesis script.

Key selling points
- Extremely small resource footprint: ~790 NAND2-equivalent cells (Yosys RTL cell count).
- Low barrier to integration: single-file core (rtl/cpu.sv), small memories, easy to instantiate.
- Deterministic behavior and easy verification: tests provided for arithmetic, control, memory edges; netlist-friendly memory init ports included.

Exemplary target applications
- Embedded control in simple appliances: thermostats, smart sensors, and utility controllers where minimal instruction throughput and deterministic timing suffice.
- Educational/teaching platform: hardware design and digital logic labs for students learning CPU microarchitecture, RTL design, synthesis and verification.
- IoT edge nodes with extremely constrained logic budgets: simple sensor aggregation and control loops where minimal area/low-power are primary goals.
- FPGA soft-CPU for small tasks: glue logic, boot-time configuration, or sidecar processors in larger designs.

Microarchitecture summary
- Single-cycle, accumulator-based datapath. Key components: PC (8-bit), IMEM (16x8), IR (8-bit), Decoder/Control logic, ACC (8-bit), ALU (add/sub), DMEM (16x8).
- No pipelining. On each rising edge PC/ACC/halt update. Instruction decode is combinational.

Frequency & silicon area (conservative estimates)
- Source: Yosys RTL synthesis summary (artifacts/cpu_synth.v generation) — gate/cell count: 790 cells.
- Conservative f_max estimate (technology dependent): 200–800 MHz (broad range; depends on target process, P&R results and standard-cell library).
- Area (approx NAND2-equivalents): 790 NAND2 cells. Example area mapping (very approximate):
  - 65 nm: ~790 µm² (0.00079 mm²) assuming 1 µm² per NAND2-equivalent.
  - 28 nm: ~197.5 µm² (0.00020 mm²) assuming 0.25 µm² per NAND2-equivalent.

Assumptions and notes
- Frequency and area are conservative, back-of-envelope estimates. For production use, run technology mapping, place-and-route, and timing analysis with your chosen standard-cell library or FPGA toolchain.
- Memory initialization in verification uses top-level init ports to remain compatible with synthesized netlist.

Sales pitch (short)
- "This design is a lightweight, verifiable CPU core ideal for teaching, prototyping, and ultra-constrained embedded tasks. It provides a complete RTL implementation, verification harness, and synthesis flow so you can integrate, test, and prototype quickly."

Contact & next steps
- For integration support, technology-specific mapping, or area/timing sign-off, supply the target process/library or FPGA family and the team can run place-and-route to provide accurate f_max and area numbers.

