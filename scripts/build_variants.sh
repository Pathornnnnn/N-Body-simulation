#!/usr/bin/env bash
# Build the original code and the experimental variants into build/.
# Usage: scripts/build_variants.sh   (run from repo root)
set -eu
CC=${CC:-gcc}
EXP=openmp/barnes-hut-exp.c
mkdir -p build
b() { echo "build/bh-$1  <- $2 $3"; $CC -Wall $2 -o build/bh-$1 $3 -lm -fopenmp; }

b orig-O0   "-O0"                          openmp/barnes-hut.c   # same build as results/times.csv
b orig-O3   "-O3"                          openmp/barnes-hut.c   # limitation: -O0 only
b fix-O0    "-O0 -DFIX_COM"                $EXP                  # COM bounds + data race fixed
b dyn-O0    "-O0 -DACC_DYNAMIC"            $EXP                  # dynamic schedule for get_acceleration
b all-O3    "-O3 -DFIX_COM -DACC_DYNAMIC"  $EXP                  # everything together
b phases-O0 "-O0 -DPHASES"                 $EXP                  # per-phase timing
b phases-O3 "-O3 -DPHASES"                 $EXP
