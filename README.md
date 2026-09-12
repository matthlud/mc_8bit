# 8-bit Microprocessor

[![RTL/netlist CI](https://github.com/matthlud/mc_8bit/actions/workflows/ci.yml/badge.svg)](https://github.com/matthlud/mc_8bit/actions/workflows/ci.yml)
[![SKY130 RTL-to-GDSII](https://github.com/matthlud/mc_8bit/actions/workflows/layout.yml/badge.svg)](https://github.com/matthlud/mc_8bit/actions/workflows/layout.yml)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Top language](https://img.shields.io/github/languages/top/matthlud/mc_8bit)](https://github.com/matthlud/mc_8bit)
[![Last commit](https://img.shields.io/github/last-commit/matthlud/mc_8bit)](https://github.com/matthlud/mc_8bit/commits/main)
[![Repository size](https://img.shields.io/github/repo-size/matthlud/mc_8bit)](https://github.com/matthlud/mc_8bit)

A small accumulator-based 8-bit CPU implemented in SystemVerilog.  It has a
Harvard architecture with separate 16 x 8 instruction and data memories and a
single-cycle instruction path.

The repository contains both a fast RTL/netlist verification flow and a
reproducible SKY130 RTL-to-GDSII flow:

```text
SystemVerilog -> Yosys -> OpenROAD -> KLayout -> GDSII
```

## Dependencies

For simulation and generic synthesis on Debian/Ubuntu:

```bash
sudo apt update
sudo apt install yosys iverilog
```

Docker is required for the physical-design flow.  The flow container includes
Yosys, OpenROAD, the SkyWater SKY130 high-density standard-cell views, and
KLayout, so no local PDK installation is needed for `make gds`.

Optional tools:

```bash
sudo apt install gtkwave latexmk texlive-latex-extra git-lfs
```

## Quick start

Run the RTL smoke test and regression suite:

```bash
make test
```

Create and simulate the technology-independent Yosys netlist:

```bash
make synth
make netlist
make test-netlist
```

The generated generic files are placed in `artifacts/` and are ignored by
Git.  `make rtl` also writes `artifacts/cpu.vcd`; view it with:

```bash
make view
```

Run a compile-only lint pass:

```bash
make lint
```

## SKY130 RTL-to-GDSII

The physical flow is driven by `flow/config.mk` and
`flow/constraint.sdc`.  It uses the `sky130hd` platform from
[OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts),
with Yosys as the synthesis front-end and KLayout for GDS stream-out.
The Docker image is pinned in `flow/run.sh` for reproducibility.

Generate the layout:

```bash
make gds
```

This runs the complete flow (synthesis, floorplanning, placement, clock-tree
synthesis, routing, filling, extraction/reporting, and KLayout stream-out).
The convenient final outputs are:

Generated physical-design deliverables are intentionally ignored by Git; they
remain local after a run and are uploaded only as CI workflow artifacts.

```text
outputs/cpu_sky130hd.gds       # final GDSII
outputs/cpu_sky130hd.def       # final routed DEF
outputs/cpu_sky130hd.v         # final routed Verilog
outputs/cpu_sky130hd.drc.rpt   # detailed-router DRC report
```

The complete, intermediate ORFS results remain under
`build/orfs/results/sky130hd/mc_8bit/base/`.  The flow is intentionally not run
on every pull request because detailed routing can take several minutes; the
manual/tagged GitHub Actions workflow runs it and uploads the GDSII as an
artifact.

To use another Docker image, work directory, or core count:

```bash
ORFS_IMAGE=openroad/orfs:26Q2 ORFS_NUM_CORES=2 make gds
ORFS_WORK_DIR=build/my-orfs make gds
```

### View the GDSII in KLayout

With KLayout installed locally, run:

```bash
klayout outputs/cpu_sky130hd.gds
```

The same file can be opened from the ORFS container (GUI forwarding must be
configured for the host):

```bash
docker run --rm -it --net=host \
  -e DISPLAY="$DISPLAY" -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$PWD":/work openroad/orfs:26Q2 \
  klayout /work/outputs/cpu_sky130hd.gds
```

## CPU interface and instruction set

The CPU's architectural outputs are `pc[7:0]`, `acc[7:0]`, and `halt`.  `rst`
is an asynchronous active-high reset.  The memory initialization ports are
synchronous write ports intended for loading a program in simulation or from a
small integration wrapper:

- `imem_init_wr_en`, `imem_init_wr_addr[3:0]`, `imem_init_wr_data[7:0]`
- `dmem_init_wr_en`, `dmem_init_wr_addr[3:0]`, `dmem_init_wr_data[7:0]`

Each instruction is eight bits: `[7:4]` is the opcode and `[3:0]` is the
operand/address.

| Opcode | Mnemonic | Operation |
|---:|---|---|
| `0x0` | NOP | No operation |
| `0x1` | LDA | `ACC <- DMEM[address]` |
| `0x2` | STA | `DMEM[address] <- ACC` |
| `0x3` | ADD | `ACC <- ACC + DMEM[address]` |
| `0x4` | SUB | `ACC <- ACC - DMEM[address]` |
| `0x5` | LDI | `ACC <- immediate` |
| `0x6` | JMP | `PC <- address` |
| `0xF` | HLT | Assert `halt` and hold `PC` |

Arithmetic wraps modulo 256.  Only the low four PC bits address the internal
16-byte instruction memory.

## Repository layout

- `rtl/` — CPU and 16 x 8 memory RTL
- `verification/` — canonical smoke test and regression testbenches
- `rtl2gds/` — fast, technology-independent Yosys script
- `flow/` — SKY130 OpenROAD-flow-scripts configuration and Docker wrapper
- `artifacts/` — ignored simulation and generic-netlist outputs
- `outputs/` — final layout deliverables
- `docs/` — specification and microarchitecture documentation

## Documentation

Build the specification PDF with:

```bash
make docs
```

## Cleanup

```bash
make clean       # generated build, simulation, and generic netlist files
make clean-all   # also removes the GDSII output directory
```

## License

See [LICENSE](LICENSE).
