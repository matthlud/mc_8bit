# Marketing Brief — Simple 8-bit CPU

## Overview

The mc_8bit is a compact accumulator-based 8-bit CPU with separate 16-byte
instruction and data memories. It is intentionally small enough to understand
in a classroom, but its repository also contains a complete reproducible
SKY130 RTL-to-GDSII flow.

## Key points

- Eight simple instructions: NOP, LDA, STA, ADD, SUB, LDI, JMP, and HLT.
- One-cycle instruction execution with an 8-bit accumulator and PC.
- Explicit synchronous memory-loader ports make simulation and wrapper
  integration deterministic without relying on simulator-only memory writes.
- RTL regressions, generic Yosys netlist simulation, and physical design are
  all automated.
- `outputs/cpu_sky130hd.gds` is the final GDSII deliverable produced by
  OpenROAD and KLayout on the SkyWater SKY130 high-density platform.

## Example applications

- Digital design and ASIC-flow teaching
- Small deterministic control tasks
- FPGA soft-core experiments
- A minimal starting point for custom instruction-set exploration

## Implementation flow

```text
SystemVerilog -> Yosys -> OpenROAD -> KLayout -> SKY130 GDSII
```

`flow/config.mk` sets the SKY130HD library, utilization, and timing
constraints. `flow/run.sh` runs the pinned OpenROAD-flow-scripts container and
copies stable deliverables into `outputs/`. The generated area, timing, and
routing reports in `build/orfs/` should be used instead of technology-
independent NAND-equivalent estimates.

This is an educational core, not a complete production chip: the top level
has no pad ring or package integration, and its memory-loader pins are exposed
for integration/testing. A tapeout wrapper must add pad cells, power intent,
clock/reset strategy, and the desired program-loading mechanism.
