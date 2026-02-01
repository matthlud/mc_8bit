# 8-bit Microprocessor

A simple 8-bit CPU implementation in SystemVerilog with synthesis and simulation support.

## Dependencies

Install the required tools:

```bash
sudo apt update
sudo apt install yosys iverilog gtkwave                 # Synthesis and simulation
sudo apt install texlive texlive-latex-extra latexmk    # LaTeX
sudo apt install git-lfs
```

## Clone the Repo

```bash
git clone git@github.com:matthlud/mc_8bit.git
```

## Install git lsf

```bash
git lfs install
```

## Getting Started

### RTL Simulation

Simulate the design at the RTL (Register Transfer Level):

```bash
make rtl
```

This compiles and simulates the SystemVerilog design, generating a VCD waveform file.

### Synthesis & Netlist Simulation

Generate a synthesized netlist and simulate (currently, the simulation is not functional) it:

```bash
make synth          # Synthesize RTL to gates, creates artifacts/cpu_synth.v
# make netlist      # Simulate the synthesized netlist
```

### View Waveforms

Open the generated VCD waveform in GTKWave:

```bash
make view
```

## Generate Documentation

## Specification

```bash
pdflatex docs/src/specification.tex
```


## Project Structure

- `rtl/` - SystemVerilog source files (cpu.sv)
- `verification/` - Testbench files (cpu_tb_top.sv)
- `rtl2gds/` - Synthesis script (synth.ys)
- `artifacts/` - Generated files (netlists, simulations)
