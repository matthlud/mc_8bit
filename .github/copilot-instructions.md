# Copilot instructions for mc_8bit

Purpose
- Help Copilot sessions quickly understand how to build, run, test, and reason about this repo (8-bit SystemVerilog CPU).

Quick build / test / lint commands
- Full RTL simulation (recommended):
  - make rtl
- Single-test (compile and run the testbench only):
  - iverilog -g2012 -o ./artifacts/sim_rtl.vvp ./rtl/cpu.sv ./verification/cpu_tb_top.sv && vvp ./artifacts/sim_rtl.vvp
- Netlist simulation (requires synthesized netlist; note: currently commented/non-functional):
  - make synth
  - iverilog -g2012 -DUSE_NETLIST -o ./artifacts/sim_netlist.vvp ./artifacts/cpu_synth.v ./verification/cpu_tb_top.sv /usr/share/yosys/simcells.v && vvp ./artifacts/sim_netlist.vvp
- Synthesis (Yosys):
  - make synth  (or: yosys -s ./rtl2gds/synth.ys)
- View waveform:
  - make view  (or: gtkwave ./artifacts/cpu.vcd)
- Clean generated artifacts:
  - make clean

Notes on single-test runs
- The "Single-test" command compiles the RTL and the top-level testbench directly and runs it; useful for quick iterations.
- To force netlist mode, compile with -DUSE_NETLIST and ensure artifacts/cpu_synth.v exists.
- VSCode Verilog linting is configured to use iverilog with flags "-g2012 -I rtl" (see .vscode/settings.json).

High-level architecture (big picture)
- cpu.sv: single-file SystemVerilog implementation of a tiny 8-bit CPU. Exposes ports: clk, rst, pc[7:0], acc[7:0], halt.
- Instruction/data memories: imem[0:15] and dmem[0:15] (16 bytes each). Testbench initializes these directly using hierarchical reference (dut.imem / dut.dmem).
- Instruction format: 8 bits where bits[7:4] = opcode, bits[3:0] = operand/address.
- Core opcodes (defined in cpu.sv): NOP, LDA, STA, ADD, SUB, LDI, JMP, HLT (HLT = 4'hF).
- Control flow: always_ff for state registers (pc, acc, halt); always_comb for combinational next-state and memory write signals.
- verification/cpu_tb_top.sv: top-level testbench used for both RTL and netlist (select via `-DUSE_NETLIST`). It generates the clock, initializes memories, runs until halt or timeout, dumps a VCD, and prints pass/fail checks.
- artifacts/: output sink for vcd, vvp, netlist (cpu_synth.v), logs, graphs (cpu.dot).
- docs/src/specification.tex: LaTeX source for a textual specification; build with pdflatex/latexmk if needed.

Key conventions and repository-specific patterns
- File layout:
  - rtl/: SystemVerilog source (cpu.sv)
  - verification/: testbench(s), cpu_tb_top.sv is canonical test harness
  - rtl2gds/: synthesis scripts for Yosys (synth.ys)
  - artifacts/: generated outputs (keep ignored in VCS)
- Testbench initialization uses hierarchical reference to DUT instance named "dut". When editing or adding tests, use the same instance name or adjust cpu_tb_top accordingly.
- USE_NETLIST compile switch: cpu_tb_top.sv toggles between RTL and synthesized netlist via `ifdef USE_NETLIST. Add -DUSE_NETLIST to iverilog to exercise netlist path.
- Memory widths and addressing are intentionally small (16 bytes, 4-bit addresses). Keep any memory initialization or fixtures within these bounds unless intentionally expanding the design.
- Yosys synthesis script generates ./artifacts/cpu_synth.v. Netlist simulation historically had issues around memory initialization; update testbench or add explicit memory init for netlist runs.
- Linting: project expects iverilog as linter and uses SystemVerilog 2012 (-g2012). VSCode settings include: "verilog.linting.linter": "iverilog" and "verilog.linting.iverilog.arguments": "-g2012 -I rtl".

Other AI-assistant / automation files checked
- No CLAUDE.md, .cursorrules, AGENTS.md, .windsurfrules, CONVENTIONS.md, AIDER_CONVENTIONS.md, .clinerules were detected in the repo root. If present, consider merging key instructions into this file.

If you edit or extend
- If adding more modules, update cpu_tb_top or add separate testbench files; keep artifacts output path consistent.
- If raising memory size, update imem/dmem declarations and testbenches consistently.

Created by Copilot CLI: concise guide to build, run, and reason about this repo. Update this file when workflows or top-level scripts change.
