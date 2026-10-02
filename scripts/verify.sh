#!/usr/bin/env bash
# Correctness check: serial Barnes-Hut vs OpenMP Barnes-Hut (both built with -DRESULTS,
# which writes every body's position at every step). Run from repo root.
set -eu
INPUT=${INPUT:-tests/1k_bodies.csv}; END=${END:-0.2}; DT=${DT:-0.01}
mkdir -p build verify
gcc -DRESULTS -Wall -o build/barnes-hut-debug     serial/barnes-hut.c -lm
gcc -DRESULTS -Wall -o build/barnes-hut-omp-debug openmp/barnes-hut.c -lm -fopenmp
./build/barnes-hut-debug "$INPUT" 0 "$END" "$DT" verify/serial.csv | grep -E "time steps"
for t in 1 2 4; do
  ./build/barnes-hut-omp-debug "$INPUT" 0 "$END" "$DT" verify/omp_$t.csv $t >/dev/null
  python3 scripts/compare.py verify/serial.csv verify/omp_$t.csv "omp $t threads"
done
