# mc_8bit contributor notes

## Verification commands

Run these from the repository root:

- `make test` — canonical RTL smoke test plus all regression tests.
- `make synth` — generic Yosys netlist at `artifacts/cpu_synth.v`.
- `make netlist` — canonical smoke test against that netlist.
- `make test-netlist` — all regression tests against the netlist.
- `make lint` — compile-only SystemVerilog check.
- `make gds` — SKY130 OpenROAD/KLayout flow in Docker.

The regression runner computes the repository root from its own location, so
`./verification/tests/run_tests.sh` also works when called outside the root.
It fails on compilation, simulation, or missing PASS markers; do not mask
errors with `|| true`.

## Design structure

- `rtl/cpu.sv` is the `cpu` top level.
- `rtl/mem_imem16x8.sv` and `rtl/mem_dmem16x8.sv` implement the 16-byte
  instruction and data memories.
- `verification/cpu_tb_top.sv` is the canonical RTL/netlist smoke test.
- `verification/tests/` contains independent regression testbenches.
- `rtl2gds/synth.ys` is the fast technology-independent Yosys flow.
- `flow/` contains the OpenROAD-flow-scripts `sky130hd` configuration,
  constraints, and Docker runner. Its final deliverable is
  `outputs/cpu_sky130hd.gds`.

Memory initialization is performed through the CPU's synchronous top-level
init ports. Keep those ports connected explicitly in new testbenches; do not
assign synthesized-netlist input wires hierarchically.

The 8-bit instruction format is `[7:4]` opcode and `[3:0]` operand. The CPU
supports NOP, LDA, STA, ADD, SUB, LDI, JMP, and HLT. Memory is 16 x 8 bits and
only `pc[3:0]` is used for instruction addressing.
