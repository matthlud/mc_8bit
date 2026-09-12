#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
ARTIFACT_DIR="$ROOT/artifacts"
mkdir -p "$ARTIFACT_DIR"

USE_NETLIST=${USE_NETLIST:-0}
IVERILOG=${IVERILOG:-iverilog}
VVP=${VVP:-vvp}
SIMCELLS=${SIMCELLS:-/usr/share/yosys/simcells.v}

if [[ "$USE_NETLIST" == "1" ]]; then
    NETLIST="$ARTIFACT_DIR/cpu_synth.v"
    if [[ ! -s "$NETLIST" ]]; then
        echo "ERROR: $NETLIST is missing; run 'make synth' first." >&2
        exit 1
    fi
    SIM_SOURCES=("$NETLIST" "$SIMCELLS")
    MODE="synthesized netlist"
else
    mapfile -t SIM_SOURCES < <(find "$ROOT/rtl" -maxdepth 1 -type f -name '*.sv' -print | sort)
    MODE="RTL"
fi

mapfile -t TESTBENCHES < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name 'test_*.sv' -print | sort)
if [[ ${#TESTBENCHES[@]} -eq 0 ]]; then
    echo "ERROR: no testbenches found in $SCRIPT_DIR" >&2
    exit 1
fi

failed=0
suffix=""
if [[ "$USE_NETLIST" == "1" ]]; then
    suffix="_netlist"
fi
for tb in "${TESTBENCHES[@]}"; do
    name=$(basename "$tb" .sv)
    top="${name}_tb"
    vvp_file="$ARTIFACT_DIR/${name}${suffix}.vvp"
    log_file="$ARTIFACT_DIR/${name}${suffix}.log"

    echo "--- Running $name ($MODE) ---"
    if ! "$IVERILOG" -g2012 -Wall -s "$top" -o "$vvp_file" "${SIM_SOURCES[@]}" "$tb"; then
        echo "[FAIL] $name: compilation failed"
        failed=1
        continue
    fi

    if ! "$VVP" "$vvp_file" | tee "$log_file"; then
        echo "[FAIL] $name: simulation failed"
        failed=1
        continue
    fi

    if grep -q '^TEST: .* PASS$' "$log_file"; then
        echo "[OK] $name"
    else
        echo "[FAIL] $name: PASS marker not found"
        failed=1
    fi
done

if (( failed != 0 )); then
    echo "One or more tests failed" >&2
    exit 1
fi

echo "All $MODE tests passed"
