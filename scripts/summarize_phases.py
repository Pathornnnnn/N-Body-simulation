#!/usr/bin/env python3
"""Mean time per phase (s) and share of the phase sum, from results/phases.csv."""
import csv, sys, statistics as st
from collections import defaultdict
P = ["move", "bbox", "build", "com", "acc"]
d = defaultdict(lambda: defaultdict(list))
for r in csv.DictReader(open(sys.argv[1] if len(sys.argv) > 1 else "results/phases.csv")):
    k = (r["workload"], int(r["threads"]))
    for p in P + ["total"]: d[k][p].append(float(r[p]))
print("| workload | thr | total | " + " | ".join(P) + " | acc % | build % |")
print("|---|---|---|" + "---|" * (len(P) + 2))
for k in sorted(d, key=lambda k: (int(k[0][:-1]), k[1])):
    m = {p: st.mean(d[k][p]) for p in P + ["total"]}
    s = sum(m[p] for p in P)
    print(f"| {k[0]} | {k[1]} | {m['total']:.2f} | " + " | ".join(f"{m[p]:.3f}" for p in P)
          + f" | {100*m['acc']/s:.1f} | {100*m['build']/s:.1f} |")
