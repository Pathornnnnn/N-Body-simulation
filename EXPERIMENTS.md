# การทดลองเพิ่มเติม: แก้และทดสอบข้อจำกัด

โค้ดต้นฉบับ `openmp/barnes-hut.c` ไม่ถูกแก้ ส่วนที่ทดลองอยู่ใน `openmp/barnes-hut-exp.c`
ซึ่งเป็นสำเนาที่เปิดปิดการแก้ได้ทีละอย่างด้วย `-D` ตอนคอมไพล์ ถ้าไม่ใส่ `-D` เลยจะได้อัลกอริทึมเดียวกับต้นฉบับ

| ข้อจำกัด (สไลด์ 23) | ทดสอบด้วย | binary |
|---|---|---|
| คอมไพล์ด้วย -O0 ยังไม่ได้ลอง -O3 | โค้ดต้นฉบับ + `-O3` | `bh-orig-O3` |
| `children[++counter]` อ่านเกินถึง `children[8]` และ data race ตอนรอ `mass` | `-DFIX_COM` | `bh-fix-O0` |
| load imbalance ตอนหาแรง | `-DACC_DYNAMIC` (schedule(dynamic, 64)) | `bh-dyn-O0` |
| ทุกอย่างรวมกัน | `-O3 -DFIX_COM -DACC_DYNAMIC` | `bh-all-O3` |
| ไม่ได้จับเวลาแยกแต่ละเฟส | `-DPHASES` | `bh-phases-O0`, `bh-phases-O3` |
| พื้นที่ 5N อาจไม่พอ | ทุก binary ของ exp พิมพ์ `Max nodes used: X of Y` | `scripts/check_nodes.sh` |
| ตรวจความถูกต้องแค่ 1,000 ดวง | `scripts/verify_variants.sh` (เปลี่ยน INPUT ได้) | |

`bh-orig-O0` คือโค้ดต้นฉบับแบบเดียวกับที่ใช้ทำ `results/times.csv` รันซ้ำในรอบเดียวกันเพื่อเป็น baseline ที่เทียบได้ตรง ๆ

## ขั้นตอนบน server (รันจาก root ของ repo)

```bash
scripts/build_variants.sh
scripts/verify_variants.sh
mkdir -p inputs && head -n 5000 tests/100k_bodies.csv > inputs/in_5000.csv
INPUT=inputs/in_5000.csv END=0.1 scripts/verify_variants.sh
tmux new -s bh
scripts/run_variants.sh
scripts/run_phases.sh
BIN=build/bh-phases-O3 OUT=results/phases-O3.csv scripts/run_phases.sh
scripts/check_nodes.sh
```

1. `build_variants.sh` สร้าง binary ทั้งหมดใน `build/`
2. `verify_variants.sh` เทียบตำแหน่งดาวทุก step กับโปรแกรม serial ที่ 1, 4, 8 เธรด ค่า `max|dpos|` ควรเป็น 0 หรือใกล้ 0
   - สองบรรทัดถัดมาสร้าง input 5,000 ดวง (ไฟล์เดียวกับที่ `run_experiment.sh` ใช้) แล้วตรวจซ้ำที่ขนาดนั้น
3. `run_variants.sh` รันใน tmux เพราะใช้เวลานาน ผลอยู่ที่ `results/variants/<variant>.csv` แล้วพิมพ์ตารางเปรียบเทียบท้ายสุด
4. `run_phases.sh` จับเวลาแยกเฟส ผลอยู่ที่ `results/phases.csv` สรุปด้วย `python3 scripts/summarize_phases.py`
5. `check_nodes.sh` ดูว่าใช้พื้นที่ node ไปเท่าไหร่จาก 5N

ค่าเริ่มต้นของ `run_variants.sh`: END=0.27 (27 steps), THREADS="1 2 4 8", RUNS=5, workload 1x/2x/4x
ถ้าจะให้ครบแบบการทดลองหลัก: `RUNS=10 THREADS="1 2 3 4 5 6 7 8" scripts/run_variants.sh`
ถ้าหยุดกลางทาง รันคำสั่งเดิมอีกครั้งได้ variant ที่มี CSV แล้วจะถูกข้าม (ลบ CSV ของ variant ที่ยังรันไม่ครบก่อน)

## เวลาโดยประมาณ (เครื่องเดิม, ค่าเริ่มต้น)

- variant ที่เป็น -O0 (orig-O0, fix-O0, dyn-O0): ประมาณ 45 นาทีต่อ variant
- variant ที่เป็น -O3 (orig-O3, all-O3): น่าจะเร็วกว่า -O0 ราว 2–3 เท่า (วัดบนเครื่อง local ที่ 1,000–2,000 ดวง)
- `run_phases.sh` แบบ -O0, RUNS=3: ประมาณ 20–25 นาที
- รวมทั้งหมดราว 3–3.5 ชั่วโมง

## อ่านผลอย่างไร

`compare_variants.py` พิมพ์ 4 ตาราง: เวลาเฉลี่ย, ความแกว่งระหว่างรอบ (std/mean),
Speedup เทียบ 1 เธรดของตัวเอง และเวลาเทียบกับ orig-O0 ที่จำนวนเธรดเดียวกัน (< 1 คือเร็วกว่าต้นฉบับ)
ความต่างที่เล็กกว่าความแกว่งระหว่างรอบ (ราว 3–6% ในการทดลองหลัก) สรุปไม่ได้

ข้อสังเกต: -O3 ทำให้งานคำนวณเร็วขึ้น แต่ overhead ของ barrier/lock ไม่ได้ลดตาม
Speedup เทียบ 1 เธรดของ -O3 จึงอาจต่ำกว่า -O0 ได้ แม้เวลาจริงจะเร็วกว่า

## รายละเอียดการแก้ใน `-DFIX_COM`

- วนลูกด้วย `j = children[counter]` ที่ต้นลูป จึงไม่อ่าน `children[8]`
- อ่าน `mass` ของลูกด้วย `#pragma omp atomic read seq_cst` และเขียน `mass` ของตัวเองด้วย
  `#pragma omp atomic write seq_cst` หลังเขียน `center` แล้ว จึงไม่มี data race
  และเธรดที่รอจะเห็น `center` ที่เขียนเสร็จแล้วเสมอ
- ยังเป็น spin-wait เหมือนเดิม (ไม่ได้เปลี่ยนวิธีรอ)
