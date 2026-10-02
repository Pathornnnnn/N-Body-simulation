#!/usr/bin/env bash
# Usage: scripts/run_experiment.sh   (run from repo root)
# Override for a quick test:  RUNS=2 END=0.1 scripts/run_experiment.sh
set -u
BIN=${BIN:-build/barnes-hut-omp}
BIG=${BIG:-tests/100k_bodies.csv}
END=${END:-0.85}          # 0.85/0.01 -> 85 steps
DT=${DT:-0.01}
RUNS=${RUNS:-10}
THREADS=${THREADS:-"1 2 3 4 5 6 7 8"}
WORKLOADS=${WORKLOADS:-"1x:5000 2x:10000 4x:20000"}
OUT=${OUT:-results/times.csv}
TMPOUT=$(mktemp)

export OMP_PROC_BIND=close OMP_PLACES=cores
mkdir -p inputs results
lscpu > results/lscpu.txt 2>&1
getconf LEVEL1_DCACHE_LINESIZE > results/cacheline.txt 2>&1

for w in $WORKLOADS; do
  n=${w#*:}
  [ -f inputs/in_$n.csv ] || head -n "$n" "$BIG" > inputs/in_$n.csv
done
[ -f "$OUT" ] || echo "workload,threads,run,time" > "$OUT"

run_one() {  # name n threads -> prints time or fails
  local res
  res=$("$BIN" inputs/in_$2.csv 0 "$END" "$DT" "$TMPOUT" "$3" 2>&1) || { echo "FAILED: $res" >&2; return 1; }
  echo "$res" | grep -E "time steps" | sed -E 's/.*time steps: ([0-9]+).*/steps=\1/' >&2
  echo "$res" | grep "Elapsed wall time" | awk '{print $4}'
}

echo "== warm-up (not recorded) =="
for w in $WORKLOADS; do for t in $THREADS; do
  run_one ${w%%:*} ${w#*:} $t >/dev/null
done; done

echo "== measured runs =="
for r in $(seq 1 "$RUNS"); do
  for w in $WORKLOADS; do for t in $THREADS; do
    name=${w%%:*}; n=${w#*:}
    tm=$(run_one $name $n $t 2>/dev/null) || { echo "run $r $name t=$t FAILED"; continue; }
    echo "$name,$t,$r,$tm" >> "$OUT"
    echo "run $r  $name N=$n threads=$t  $tm s"
  done; done
done
rm -f "$TMPOUT"
echo "done -> $OUT"
