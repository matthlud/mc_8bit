# OpenROAD-flow-scripts design configuration for mc_8bit.
# The platform is SkyWater SKY130 high-density standard cells.

PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)

export DESIGN_NAME = cpu
export DESIGN_NICKNAME = mc_8bit
export PLATFORM = sky130hd

export VERILOG_FILES = \
    $(PROJECT_ROOT)/rtl/cpu.sv \
    $(PROJECT_ROOT)/rtl/mem_dmem16x8.sv \
    $(PROJECT_ROOT)/rtl/mem_imem16x8.sv
export SDC_FILE = $(PROJECT_ROOT)/flow/constraint.sdc

# Conservative values for a small educational core.  The init ports are
# intentional top-level ports so a fabricated wrapper can load a program.
export CORE_UTILIZATION = 35
export PLACE_DENSITY = 0.55
export TNS_END_PERCENT = 100

# Keep the arithmetic-wrapper mode used by the ORFS SKY130 examples.  ORFS
# requires the hierarchical hand-off when this option is enabled, even though
# this design has no hard macros.
export SWAP_ARITH_OPERATORS = 1
export OPENROAD_HIERARCHICAL = 1

# The pinned ORFS 26Q2 image has no CTS timing-repair requirement for this
# design: placement reports no setup/hold violations.  Disabling this optional
# repair step avoids a known tool crash in some container/CPU combinations.
export SKIP_CTS_REPAIR_TIMING = 1
