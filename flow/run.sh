#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE=${ORFS_IMAGE:-openroad/orfs@sha256:7832ae885e62933fcbfc486fbd9133f8c3bd1206d15c96e93bfad97432947b61}
WORK_REL=${ORFS_WORK_DIR:-build/orfs}
NUM_CORES=${ORFS_NUM_CORES:-1}
TARGET=${ORFS_TARGET:-finish}

if [[ "$WORK_REL" = /* || "$WORK_REL" == *..* ]]; then
    echo "ORFS_WORK_DIR must be a relative path below the repository" >&2
    exit 2
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required for the SKY130 OpenROAD flow." >&2
    exit 127
fi

mkdir -p "$ROOT/$WORK_REL" "$ROOT/outputs"

echo "Running $TARGET with $IMAGE"
docker run --rm \
    --user "$(id -u):$(id -g)" \
    --mount "type=bind,src=$ROOT,dst=/work" \
    --workdir /OpenROAD-flow-scripts \
    --env DESIGN_CONFIG=/work/flow/config.mk \
    --env WORK_HOME="/work/$WORK_REL" \
    --env NUM_CORES="$NUM_CORES" \
    --env FLOW_TARGET="$TARGET" \
    "$IMAGE" \
    bash -lc 'make -f flow/Makefile DESIGN_CONFIG="$DESIGN_CONFIG" WORK_HOME="$WORK_HOME" NUM_CORES="$NUM_CORES" "$FLOW_TARGET"'

RESULT_DIR="$ROOT/$WORK_REL/results/sky130hd/mc_8bit/base"
GDS="$RESULT_DIR/6_final.gds"
if [[ ! -s "$GDS" ]]; then
    echo "OpenROAD completed without producing $GDS" >&2
    exit 1
fi

# Keep convenient, stable paths in addition to the complete ORFS work tree.
cp "$GDS" "$ROOT/outputs/cpu_sky130hd.gds"
[[ -f "$RESULT_DIR/6_final.def" ]] && cp "$RESULT_DIR/6_final.def" "$ROOT/outputs/cpu_sky130hd.def"
[[ -f "$RESULT_DIR/6_final.v" ]] && cp "$RESULT_DIR/6_final.v" "$ROOT/outputs/cpu_sky130hd.v"
[[ -f "$ROOT/$WORK_REL/reports/sky130hd/mc_8bit/base/5_route_drc.rpt" ]] && \
    cp "$ROOT/$WORK_REL/reports/sky130hd/mc_8bit/base/5_route_drc.rpt" "$ROOT/outputs/cpu_sky130hd.drc.rpt"

printf 'GDSII: %s (%s bytes)\n' "$ROOT/outputs/cpu_sky130hd.gds" "$(stat -c '%s' "$ROOT/outputs/cpu_sky130hd.gds")"
