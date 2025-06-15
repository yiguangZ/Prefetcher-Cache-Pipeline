🧠 RISC-V Processor with Branch Predictor and Instruction Cache (UCSB ECE 154B)
This project implements a 5-stage pipelined RISC-V processor enhanced with:

Dynamic Branch Prediction (BTB + GHR-based)

4-Way Set-Associative Instruction Cache (Random Replacement)

Critical-Word-First Cache Fetching

Hardware Prefetcher for Improved Miss Penalty

Miss Rate Instrumentation and Performance Analysis

Designed and tested for the ECE 154B: Advanced Computer Architecture course at UC Santa Barbara.

🚀 Features
✅ Pipeline Architecture
Standard 5-stage RISC-V pipeline: Fetch → Decode → Execute → Memory → Writeback

Data hazard detection and stall/forwarding logic

Dual-issue support to improve instruction throughput (optional)

✅ Instruction Cache (L1)
4-way set-associative cache with random replacement policy (RRP)

Parameterized sets and block size (default: 8 sets × 4 words per block = 512B total)

Synchronous read/write interface (for efficient synthesis as BRAM)

✅ Advanced Cache Controller
Critical-word-first + early restart mechanism:

Fetches only the needed word first to reduce stall time

Streams the rest of the block afterward while resuming execution

✅ Hardware Prefetcher
Automatically prefetches the next block (A+1) upon a cache miss at address A

One-block prefetch buffer checked in parallel with L1 cache

Prefetched blocks written into L1 cache on use; buffer updated dynamically

✅ Branch Prediction
Combined BTB (Branch Target Buffer) and GHR (Global History Register) mechanism

2-bit saturating counters used to make dynamic predictions

Integrated into fetch stage for pipeline hazard reduction

📊 Performance Metrics
Miss rate and CPI are instrumented and evaluated across three configurations:

Baseline Cache: full-block fetch, no optimization

Advanced Cache: critical-word-first fetch

Advanced + Prefetcher: critical-word-first with 1-block prefetching

 Results (for provided test programs):
Configuration	Cache Miss Rate
Baseline	          2.749%
Advanced	          2.4% ↓
Advanced + Prefetch	1.77% ↓

(Update the X/Y values with your actual results if desired)

🧩 Files
ucsbece154b_imem.v – Instruction cache

ucsbece154b_cache.v – Instruction cache controller

ucsbece154b_controller.v – Pipeline control logic

ucsbece154b_datapath.v – Top-level RISC-V datapath

ucsbece154b_top_tb.v – Testbench with miss/cycle counters

ucsbece154b_branchpredictor.v Branch predictor module

README.md – This file

🛠️ Tools & Technologies
Verilog HDL

ModelSim / Vivado for simulation and waveform analysis

Custom cycle-level testbench for performance evaluation

🧠 Lessons Learned
Designing realistic memory hierarchies with performance trade-offs

Implementing and testing non-blocking cache fetch mechanisms

Integrating speculative execution via branch prediction

Balancing complexity vs performance in hardware design

📚 References
UCSB ECE 154B Lab Docs

Rocket Core Memory Hierarchy Insights

Caches and Prefetching in Computer Architecture (Hennessy & Patterson)

