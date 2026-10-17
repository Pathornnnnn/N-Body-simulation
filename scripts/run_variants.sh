#!/usr/bin/env bash
# Run scripts/run_experiment.sh once per variant, one CSV per variant.
# Usage: scripts/run_variants.sh   (run from repo root, after scripts/build_variants.sh)
# Defaults are shorter than the main experiment; override e.g.
#   RUNS=10 THREADS="1 2 3 4 5 6 7 8" scripts/run_variants.sh
# A variant whose CSV already exists is skipped, so you can stop and resume.
set -u
VARIANTS=${VARIANTS:-"orig-O0 orig-O3 fix-O0 dyn-O0 all-O3"}
export END=${END:-0.27} DT=${DT:-0.01}
export RUNS=${RUNS:-5}
export THREADS=${THREADS:-"1 2 4 8"}
export WORKLOADS=${WORKLOADS:-"1x:5000 2x:10000 4x:20000"}
OUTDIR=${OUTDIR:-results/variants}
mkdir -p "$OUTDIR"
for v in $VARIANTS; do
  out=$OUTDIR/$v.csv
  if [ -f "$out" ]; then echo "== $v: $out exists, skip"; continue; fi
  [ -x build/bh-$v ] || [ -x build/bh-$v.exe ] || { echo "== $v: build/bh-$v missing (run scripts/build_variants.sh)"; continue; }
  echo "== $v"
  BIN=build/bh-$v OUT=$out scripts/run_experiment.sh
done
python3 scripts/compare_variants.py "$OUTDIR"
