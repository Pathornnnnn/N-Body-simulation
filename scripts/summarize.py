#!/usr/bin/env python3
"""Summarize results/times.csv -> avg time, speedup (T1/Tp, same workload), efficiency."""
import csv, sys, statistics as st
from collections import defaultdict
path = sys.argv[1] if len(sys.argv) > 1 else "results/times.csv"
d = defaultdict(list)
for r in csv.DictReader(open(path)):
    d[(r["workload"], int(r["threads"]))].append(float(r["time"]))
wl = sorted({k[0] for k in d}, key=lambda s: int(s.rstrip("x")))
th = sorted({k[1] for k in d})
avg = {k: st.mean(v) for k, v in d.items()}
def table(title, f):
    print(f"\n{title}\n| workload | " + " | ".join(f"{t} thr" for t in th) + " |")
    print("|---|" + "---|" * len(th))
    for w in wl:
        print(f"| {w} | " + " | ".join(f(w, t) for t in th) + " |")
table("Avg exec time (s)", lambda w, t: f"{avg[(w,t)]:.3f}" if (w,t) in avg else "-")
table("Std dev (s)", lambda w, t: f"{st.stdev(d[(w,t)]):.3f}" if len(d.get((w,t),[]))>1 else "-")
table("Speedup (T1/Tp)", lambda w, t: f"{avg[(w,1)]/avg[(w,t)]:.2f}" if (w,t) in avg and (w,1) in avg else "-")
table("Efficiency (S/p)", lambda w, t: f"{avg[(w,1)]/avg[(w,t)]/t:.2f}" if (w,t) in avg and (w,1) in avg else "-")
print("\nruns per cell:", {f"{w}/{t}": len(d[(w,t)]) for w in wl for t in th if (w,t) in d})
try:
    import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
    plt.figure()
    for w in wl: plt.plot(th, [avg[(w,1)]/avg[(w,t)] for t in th], "o-", label=w)
    plt.plot(th, th, "k--", label="ideal"); plt.xlabel("threads"); plt.ylabel("speedup"); plt.legend(); plt.grid(True)
    plt.savefig("results/speedup.png", dpi=150); print("saved results/speedup.png")
except ImportError:
    print("(matplotlib not installed: skip plot)")
