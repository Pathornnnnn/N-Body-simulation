#!/usr/bin/env python3
"""Compare two RESULTS files (lines: id,x,y,z,mass). Prints max abs / mean abs position difference."""
import sys
a, b, label = open(sys.argv[1]), open(sys.argv[2]), sys.argv[3]
n = mx = tot = 0.0; lines = 0; bad = 0
for la, lb in zip(a, b):
    pa, pb = la.split(","), lb.split(",")
    if pa[0] != pb[0]: bad += 1; continue
    for i in (1, 2, 3):
        d = abs(float(pa[i]) - float(pb[i])); mx = max(mx, d); tot += d; n += 1
    lines += 1
extra = sum(1 for _ in a) + sum(1 for _ in b)
print(f"{label}: lines={lines} id_mismatch={bad} line_count_diff={'yes' if extra else 'no'} "
      f"max|dpos|={mx:.3e} mean|dpos|={tot/max(n,1):.3e}")
