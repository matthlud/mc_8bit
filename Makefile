SHELL := /usr/bin/env bash

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
RTL_SOURCES := $(sort $(wildcard $(ROOT)/rtl/*.sv))
TB_TOP := $(ROOT)/verification/cpu_tb_top.sv
TEST_RUNNER := $(ROOT)/verification/tests/run_tests.sh
YOSYS_SCRIPT := $(ROOT)/rtl2gds/synth.ys
ARTIFACT_DIR := $(ROOT)/artifacts
NETLIST_FILE := $(ARTIFACT_DIR)/cpu_synth.v
RTL_SIM := $(ARTIFACT_DIR)/sim_rtl.vvp
NETLIST_SIM := $(ARTIFACT_DIR)/sim_netlist.vvp
YOSYS ?= yosys
IVERILOG ?= iverilog
VVP ?= vvp
SIMCELLS ?= /usr/share/yosys/simcells.v

.PHONY: all rtl synth netlist test test-netlist lint gds docs view clean clean-all help

all: test

$(ARTIFACT_DIR):
	@mkdir -p "$@"

# Run the canonical smoke test against the RTL.
rtl: $(RTL_SOURCES) $(TB_TOP) | $(ARTIFACT_DIR)
	@echo "=== Simulating RTL ==="
	@cd "$(ROOT)" && $(IVERILOG) -g2012 -Wall -s cpu_tb_top -o "$(RTL_SIM)" $(RTL_SOURCES) "$(TB_TOP)"
	@$(VVP) "$(RTL_SIM)"
	@echo "=== RTL simulation complete ==="

# Generic Yosys netlist.  The SkyWater-130 physical flow is in flow/ and is
# deliberately kept separate from this fast, technology-independent target.
synth: $(NETLIST_FILE)

$(NETLIST_FILE): $(RTL_SOURCES) $(YOSYS_SCRIPT) | $(ARTIFACT_DIR)
	@echo "=== Synthesizing with Yosys ==="
	@cd "$(ROOT)" && $(YOSYS) -s "$(YOSYS_SCRIPT)"
	@test -s "$@"
	@echo "=== Synthesis complete: $@ ==="

# Simulate the actual synthesized netlist.  Do not hide compiler or simulator
# failures: a failed netlist test must fail CI.
netlist: $(NETLIST_FILE) $(TB_TOP) | $(ARTIFACT_DIR)
	@echo "=== Simulating synthesized netlist ==="
	@cd "$(ROOT)" && $(IVERILOG) -g2012 -Wall -s cpu_tb_top -D USE_NETLIST \
		-o "$(NETLIST_SIM)" "$(NETLIST_FILE)" "$(TB_TOP)" "$(SIMCELLS)"
	@$(VVP) "$(NETLIST_SIM)"
	@echo "=== Netlist simulation complete ==="

# Regression tests, first at RTL and then against the generic synthesized
# netlist.  The test runner resolves paths relative to the repository root.
test: rtl
	@echo "=== Running RTL regression tests ==="
	@"$(TEST_RUNNER)"
	@echo "=== RTL tests complete ==="

test-netlist: synth
	@echo "=== Running synthesized-netlist regression tests ==="
	@USE_NETLIST=1 "$(TEST_RUNNER)"
	@echo "=== Synthesized-netlist tests complete ==="

lint: $(RTL_SOURCES)
	@mkdir -p "$(ARTIFACT_DIR)"
	@cd "$(ROOT)" && $(IVERILOG) -g2012 -Wall -t null $(RTL_SOURCES)

# Full RTL-to-GDSII flow: Yosys synthesis, OpenROAD place-and-route and
# KLayout stream-out using the SkyWater SKY130 standard-cell platform.
gds:
	@"$(ROOT)/flow/run.sh"

# Build the specification PDF when a LaTeX toolchain is installed.
docs:
	@mkdir -p "$(ROOT)/docs/pdf"
	@cd "$(ROOT)/docs/src" && latexmk -pdf -interaction=nonstopmode -halt-on-error specification.tex
	@cp "$(ROOT)/docs/src/specification.pdf" "$(ROOT)/docs/pdf/specification.pdf"

view:
	@if [[ -s "$(ROOT)/artifacts/cpu.vcd" ]]; then \
		gtkwave "$(ROOT)/artifacts/cpu.vcd"; \
	else \
		echo "No VCD found; run 'make rtl' first."; exit 1; \
	fi

clean:
	@find "$(ARTIFACT_DIR)" -type f ! -name .gitkeep -delete
	@rm -rf "$(ROOT)/build/orfs"

clean-all: clean
	@rm -rf "$(ROOT)/outputs"

help:
	@echo "Targets:"
	@echo "  make test          RTL smoke test and RTL regression"
	@echo "  make synth         Generic Yosys netlist in artifacts/cpu_synth.v"
	@echo "  make netlist       Simulate the generic synthesized netlist"
	@echo "  make test-netlist  Run regression tests against that netlist"
	@echo "  make lint          Compile RTL without running a testbench"
	@echo "  make gds           Run the SKY130 OpenROAD/KLayout flow in Docker"
	@echo "  make docs          Build docs/pdf/specification.pdf"
	@echo "  make view          Open the RTL VCD in GTKWave"
	@echo "  make clean         Remove generated simulation/synthesis/flow files"
