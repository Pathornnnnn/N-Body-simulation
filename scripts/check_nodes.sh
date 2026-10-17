#!/usr/bin/env bash
# How much of the NODE_FACTOR * N node array is used (limitation: 5N may not be
# enough when bodies cluster). Prints "Max nodes used: X of Y" per input.
# Usage: scripts/check_nodes.sh   (run from repo root, after scripts/build_variants.sh)
set -u
BIN=${BIN:-build/bh-fix-O0}
END=${END:-0.27}; DT=${DT:-0.01}; T=${T:-8}
INPUTS=${INPUTS:-"inputs/in_5000.csv inputs/in_10000.csv inputs/in_20000.csv tests/10k_bodies_g1.csv tests/50k_bodies.csv"}
for f in $INPUTS; do
  [ -f "$f" ] || { echo "$f: missing (run scripts/run_experiment.sh once to create inputs/)"; continue; }
  res=$("$BIN" "$f" 0 "$END" "$DT" /dev/null "$T" 2>&1) || { echo "$f: FAILED -> $(echo "$res" | tail -1)"; continue; }
  echo "$f: $(echo "$res" | grep 'Max nodes used')"
done
