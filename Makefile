# Makefile for synthesizing and simulating the CPU

# File names
RTL_FILE = ./rtl/cpu.sv
TB_FILE = ./verification/cpu_tb_top.sv
NETLIST_FILE = ./artifacts/cpu_synth.v
YOSYS_SCRIPT = ./rtl2gds/synth.ys

# Tools
YOSYS = yosys
IVERILOG = iverilog
VVP = vvp

# Targets
# TODO add netlist simulation target
.PHONY: all rtl synth clean view

all: rtl

# Synthesize with Yosys
synth: $(NETLIST_FILE)

$(NETLIST_FILE): $(RTL_FILE) $(YOSYS_SCRIPT)
	@echo "=== Synthesizing with Yosys ==="
	$(YOSYS) -s $(YOSYS_SCRIPT)
	@echo "=== Synthesis complete: $(NETLIST_FILE) ==="

# Simulate RTL
rtl: $(RTL_FILE) $(TB_FILE)
	@echo "=== Simulating RTL ==="
	$(IVERILOG) -g2012 -o ./artifacts/sim_rtl.vvp $(RTL_FILE) $(TB_FILE)
	$(VVP) ./artifacts/sim_rtl.vvp
	@echo "=== RTL simulation complete ==="

# Currently, the netlist simulation target is commented out.
# It is non-functional due to isseus with the memory initialization
# in the synthesized netlist. This needs to be resolved before use.
# Details: We need to find a way to properly initialize memory in the
# synthesized netlist simulation, possibly by modifying the testbench
# or using memory abstraction.
#
# # Simulate Netlist
# netlist: $(NETLIST_FILE)
# 	@echo "=== Simulating Netlist ==="
# 	$(IVERILOG) -g2012 -DUSE_NETLIST -o ./artifacts/sim_netlist.vvp \
# 		$(NETLIST_FILE) $(TB_FILE) \
# 		/usr/share/yosys/simcells.v
# 	$(VVP) ./artifacts/sim_netlist.vvp
# 	@echo "=== Netlist simulation complete ==="

# View waveform
view:
	@if [ -f ./artifacts/cpu.vcd ]; then \
		gtkwave ./artifacts/cpu.vcd; \
	else \
		echo "No VCD file found. Run 'make rtl' or 'make netlist' first."; \
	fi

# Clean generated files
clean:
	rm -f ./artifacts/*.vvp ./artifacts/*.vcd $(NETLIST_FILE) ./artifacts/*.log

# Help
help:
	@echo "Makefile targets:"
	@echo "  make rtl      - Simulate RTL design"
	@echo "  make synth    - Synthesize with Yosys"
	@echo "  make netlist  - Simulate synthesized netlist"
	@echo "  make view     - View waveform with GTKWave"
	@echo "  make clean    - Remove generated files"
	@echo "  make help     - Show this help message"
