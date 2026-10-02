#!/usr/bin/env bash
# Per-phase timing. Build first:
#   gcc -DPHASES -o build/barnes-hut-omp-phases openmp/barnes-hut.c -lm -fopenmp
# Usage: END=0.27 scripts/run_phases.sh      (RUNS default 3)
set -u
BIN=${BIN:-build/barnes-hut-omp-phases}
END=${END:-0.27}; DT=${DT:-0.01}; RUNS=${RUNS:-3}
THREADS=${THREADS:-"1 2 4 8"}
WORKLOADS=${WORKLOADS:-"1x:5000 2x:10000 4x:20000"}
OUT=${OUT:-results/phases.csv}
export OMP_PROC_BIND=close OMP_PLACES=cores
mkdir -p inputs results
echo "workload,threads,run,total,move,bbox,build,com,acc" > "$OUT"
for r in $(seq 1 "$RUNS"); do
  for w in $WORKLOADS; do for t in $THREADS; do
    n=${w#*:}
    [ -f inputs/in_$n.csv ] || head -n "$n" tests/100k_bodies.csv > inputs/in_$n.csv
    res=$("$BIN" inputs/in_$n.csv 0 "$END" "$DT" /dev/null "$t") || { echo "FAILED ${w%%:*} t=$t"; continue; }
    tot=$(echo "$res" | grep "Elapsed" | awk '{print $4}')
    ph=$(echo "$res" | grep PHASES | sed -E 's/PHASES //; s/[a-z]+=//g; s/ /,/g')
    echo "${w%%:*},$t,$r,$tot,$ph" >> "$OUT"
    echo "run $r ${w%%:*} t=$t total=$tot phases=$ph"
  done; done
done
