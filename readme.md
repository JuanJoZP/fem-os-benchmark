# FEM OS Benchmark

This tool automates the benchmarking of parallel numerical simulations (e.g., FEM simulations using FEniCSx) under different Linux OS and container-level configurations.

## ✅ Basic Usage

To run a benchmark:

```bash
./run_benchmark.sh ./configs/test1.env
```

This runs the benchmark described by the configuration file `test1.env`.

## ⚙️ Configuration File (`.env`)

Each benchmark configuration is defined by a `.env` file. Example:

```env
TRIAL_FILE=trials/volume_taylor.py
CPU_SET="0,1"
MEMORY="4g"
SWAP="6g"
THP_MODE=always
SWAPPINESS=1
DIRTY_RATIO=10
DIRTY_BG_RATIO=5
SCHED_CHILD_FIRST=1
```

### 🛠 Required Parameters

-   **TRIAL_FILE**: Path to the Python script to benchmark (e.g., `trials/trial1.py`). This should be a parallel program compatible with MPI (such as a FEniCSx script).
-   **CPU_SET**: IDs of CPUs assigned to the container (e.g., `1,2`)
-   **MEMORY**: Memory limit (e.g., `4g`)
-   **SWAP**: Swap size (e.g., `6g`)

### ⚙️ Optional Parameters

-   **THP_MODE**: Transparent Huge Pages mode  
    Values: `always`, `never`, `madvise`

-   **SWAPPINESS**: Kernel swappiness (integer 0–100)  
    Controls tendency to swap.

-   **DIRTY_RATIO**: Max % of memory filled with dirty pages before flushing to disk.

-   **DIRTY_BG_RATIO**: Background dirty page threshold (%).

-   **SCHED_CHILD_FIRST**: Whether child processes inherit nice/scheduling settings.  
    Values: `0` (default), `1`

## 📊 Output

-   The benchmark runs the trial **5 times** using the configured resources.
-   For each repetition, system metrics are collected, including:

    -   Execution time (`/usr/bin/time`)
    -   Maximum set size (max allocated memory to a process)
    -   Throughput
    -   Page faults (Minor and Major)
    -   Context switches (Voluntary and Involuntary)
    -   Number of swaps
    -   OOM events

-   A **CSV summary** is saved at the end.
-   All logs and raw data are saved in the `benchmark_logs/` directory.

## 📁 Example Directory Structure

```
benchmark_logs/
├── trial1/
│   └── 2025-05-16_14-03-12/
│       ├── log.txt
│       └── summary.csv
```

## 🧩 Notes

-   The container is built and run dynamically from the configuration.
-   No state or container image is preserved unless explicitly saved.

---
