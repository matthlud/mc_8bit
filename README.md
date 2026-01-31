# Dependencies

sudo apt update
sudo apt install yosys iverilog gtkwave

# Running the Tests

## RTL

make rtl

## Netlist

make synth    # Creates cpu_synth.v
make netlist  # Simulates the synthesized version

# View Waves

make view
