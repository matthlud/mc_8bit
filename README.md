# 8-bit Microprocessor

A simple 8-bit CPU implementation in SystemVerilog with synthesis and simulation support.

## Dependencies

Install the required tools:

```bash
sudo apt update
sudo apt install yosys iverilog gtkwave
```

## Clone the Repo

```bash
git clone git@github.com:matthlud/mc_8bit.git
```

## Getting Started

### RTL Simulation

Simulate the design at the RTL (Register Transfer Level):

```bash
make rtl
```

This compiles and simulates the SystemVerilog design, generating a VCD waveform file.

### Synthesis & Netlist Simulation

Generate a synthesized netlist and simulate it:

```bash
make synth     # Synthesize RTL to gates, creates artifacts/cpu_synth.v
make netlist   # Simulate the synthesized netlist
```

### View Waveforms

Open the generated VCD waveform in GTKWave:

```bash
make view
```

## Project Structure

- `rtl/` - SystemVerilog source files (cpu.sv)
- `verification/` - Testbench files (cpu_tb_top.sv)
- `rtl2gds/` - Synthesis script (synth.ys)
- `artifacts/` - Generated files (netlists, simulations)
