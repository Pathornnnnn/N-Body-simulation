#!/usr/bin/env python3
"""Deeper analysis of results/times.csv: Karp-Flatt, Amdahl fit, scaling with N, plots."""
import csv, statistics as st, math
from collections import defaultdict
d = defaultdict(list)
for r in csv.DictReader(open("results/times.csv")):
    d[(r["workload"], int(r["threads"]))].append(float(r["time"]))
avg = {k: st.mean(v) for k, v in d.items()}
sd = {k: st.stdev(v) for k, v in d.items()}
wl = sorted({k[0] for k in d}, key=lambda s: int(s[:-1])); th = sorted({k[1] for k in d})
N = {"1x": 5000, "2x": 10000, "4x": 20000}
S = lambda w, p: avg[(w, 1)] / avg[(w, p)]
print("CV% (std/mean):", {f"{w}/{p}": round(100*sd[(w,p)]/avg[(w,p)], 1) for w in wl for p in (1, 4, 8)})
print("\nKarp-Flatt serial fraction e = (1/S - 1/p)/(1 - 1/p)")
print("| workload | " + " | ".join(f"{p} thr" for p in th if p > 1) + " |")
print("|---|" + "---|" * (len(th) - 1))
kf = {}
for w in wl:
    kf[w] = [(1/S(w, p) - 1/p) / (1 - 1/p) for p in th if p > 1]
    print(f"| {w} | " + " | ".join(f"{e:.4f}" for e in kf[w]) + " |")
print("\nAmdahl max speedup 1/e (e = mean KF)")
for w in wl: print(f"  {w}: e={st.mean(kf[w]):.4f}  S_max={1/st.mean(kf[w]):.0f}")
print("\nTime vs N at 1 thread (ratio to 1x; O(N log N) would give 2.1 / 4.4)")
for w in wl: print(f"  {w}: N={N[w]}  T={avg[(w,1)]:.1f}s  ratio={avg[(w,1)]/avg[('1x',1)]:.2f}  exponent={math.log(avg[(w,1)]/avg[('1x',1)])/math.log(N[w]/5000) if w!='1x' else 0:.2f}")
print("\nWeak scaling (work grows with threads): T(1x,1) vs T(2x,2) vs T(4x,4); efficiency = T1x1/T")
for w, p in (("1x", 1), ("2x", 2), ("4x", 4)):
    print(f"  {w}@{p}thr: T={avg[(w,p)]:.1f}s  weak-eff={avg[('1x',1)]/avg[(w,p)]:.2f}")
try:
    import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
    f, ax = plt.subplots(1, 3, figsize=(15, 4))
    for w in wl:
        ax[0].plot(th, [S(w, p) for p in th], "o-", label=w)
        ax[1].plot(th, [S(w, p)/p for p in th], "o-", label=w)
        ax[2].plot(th[1:], kf[w], "o-", label=w)
    ax[0].plot(th, th, "k--", label="ideal"); ax[0].set_title("Speedup")
    ax[1].axhline(1, color="k", ls="--"); ax[1].set_title("Efficiency"); ax[1].set_ylim(0.6, 1.1)
    ax[2].set_title("Karp-Flatt serial fraction e")
    for a in ax: a.set_xlabel("threads"); a.legend(); a.grid(True)
    plt.tight_layout(); plt.savefig("results/analysis.png", dpi=150); print("\nsaved results/analysis.png")
except ImportError: print("(no matplotlib)")
