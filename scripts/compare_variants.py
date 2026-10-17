#!/usr/bin/env python3
"""Compare results/variants/<variant>.csv files.

For each workload: mean time per thread count, run-to-run spread (std/mean),
speedup against the variant's own 1-thread time, and time relative to orig-O0
at the same thread count (<1 = faster than the original).
"""
import csv, glob, os, statistics as st, sys
from collections import defaultdict

folder = sys.argv[1] if len(sys.argv) > 1 else "results/variants"
data = {}  # variant -> (workload, threads) -> [times]
for path in sorted(glob.glob(os.path.join(folder, "*.csv"))):
    d = defaultdict(list)
    for r in csv.DictReader(open(path)):
        d[(r["workload"], int(r["threads"]))].append(float(r["time"]))
    data[os.path.basename(path)[:-4]] = d
if not data:
    sys.exit(f"no CSV files in {folder}")

order = ["orig-O0", "orig-O3", "fix-O0", "dyn-O0", "all-O3"]
variants = [v for v in order if v in data] + sorted(v for v in data if v not in order)
keys = {k for d in data.values() for k in d}
workloads = sorted({w for w, _ in keys}, key=lambda s: int(s.rstrip("x")))
threads = sorted({t for _, t in keys})
mean = {v: {k: st.mean(x) for k, x in d.items()} for v, d in data.items()}
spread = {v: {k: (st.stdev(x) / st.mean(x) if len(x) > 1 else 0) for k, x in d.items()}
          for v, d in data.items()}

def table(title, cell):
    print(f"\n### {title}\n")
    print("| variant | workload | " + " | ".join(f"{t} thr" for t in threads) + " |")
    print("|---|---|" + "---|" * len(threads))
    for w in workloads:
        for v in variants:
            print(f"| {v} | {w} | " + " | ".join(cell(v, w, t) for t in threads) + " |")

def fmt(x, spec): return "-" if x is None else format(x, spec)
def get(v, w, t): return mean[v].get((w, t))

table("Mean time (s)", lambda v, w, t: fmt(get(v, w, t), ".3f"))
table("Run-to-run spread (std / mean)", lambda v, w, t:
      fmt(spread[v].get((w, t)) * 100, ".1f") + "%" if (w, t) in spread[v] else "-")
table("Speedup vs own 1 thread", lambda v, w, t:
      fmt(get(v, w, 1) / get(v, w, t), ".2f") if get(v, w, 1) and get(v, w, t) else "-")
if "orig-O0" in data:
    table("Time / orig-O0 time at same threads (< 1 = faster)", lambda v, w, t:
          fmt(get(v, w, t) / get("orig-O0", w, t), ".2f")
          if get(v, w, t) and get("orig-O0", w, t) else "-")
print("\nDifferences smaller than the run-to-run spread are not conclusive.")
