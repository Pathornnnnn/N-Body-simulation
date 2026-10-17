#!/usr/bin/env bash
# Correctness check for the experimental variants: serial Barnes-Hut vs each
# variant (all built with -DRESULTS, which writes every body's position each step).
# Usage: scripts/verify_variants.sh   (run from repo root)
#   INPUT=inputs/in_5000.csv END=0.1 scripts/verify_variants.sh   for a bigger check
set -eu
INPUT=${INPUT:-tests/1k_bodies.csv}; END=${END:-0.2}; DT=${DT:-0.01}
THREADS=${THREADS:-"1 4 8"}
EXP=openmp/barnes-hut-exp.c
V=verify/variants/$(basename "$INPUT" .csv)
mkdir -p build $V
gcc -DRESULTS -Wall -o build/bh-serial-res serial/barnes-hut.c -lm
gcc -DRESULTS -O0 -o build/bh-orig-O0-res openmp/barnes-hut.c -lm -fopenmp
gcc -DRESULTS -O3 -o build/bh-orig-O3-res openmp/barnes-hut.c -lm -fopenmp
gcc -DRESULTS -O0 -DFIX_COM -o build/bh-fix-O0-res $EXP -lm -fopenmp
gcc -DRESULTS -O0 -DACC_DYNAMIC -o build/bh-dyn-O0-res $EXP -lm -fopenmp
gcc -DRESULTS -O3 -DFIX_COM -DACC_DYNAMIC -o build/bh-all-O3-res $EXP -lm -fopenmp
./build/bh-serial-res "$INPUT" 0 "$END" "$DT" $V/serial.csv | grep -E "time steps"
for v in orig-O0 orig-O3 fix-O0 dyn-O0 all-O3; do
  for t in $THREADS; do
    ./build/bh-$v-res "$INPUT" 0 "$END" "$DT" $V/$v-$t.csv "$t" >/dev/null
    python3 scripts/compare.py $V/serial.csv $V/$v-$t.csv "$v $t threads"
  done
done
