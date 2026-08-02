#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts
FAILED=0
for tb in tests/*.sv; do
  name=$(basename "$tb" .sv)
  echo "--- Running $name ---"
  ARGS=( -g2012 -o artifacts/${name}.vvp )
  if [ "${USE_NETLIST:-0}" = "1" ] && [ -f artifacts/cpu_synth.v ]; then
    echo "Using netlist artifacts/cpu_synth.v"
    iverilog "${ARGS[@]}" -D USE_NETLIST artifacts/cpu_synth.v "$tb" || true
  else
    iverilog "${ARGS[@]}" rtl/cpu.sv "$tb" || true
  fi
  vvp artifacts/${name}.vvp | tee artifacts/${name}.log || true
  if grep -q "PASS" artifacts/${name}.log; then
    echo "[OK] $name"
  else
    echo "[FAIL] $name"
    FAILED=1
  fi
done
if [ "$FAILED" -ne 0 ]; then
  echo "One or more tests failed"
  exit 1
else
  echo "All tests passed"
fi
