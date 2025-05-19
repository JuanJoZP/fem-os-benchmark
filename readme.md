# FEM OS Benchmark

This tool automates the benchmarking of parallel numerical simulations (e.g., FEM simulations using FEniCSx) under different Linux OS and container-level configurations.

## ✅ Basic Usage

To run a benchmark:

```bash
./run_benchmark.sh ./test1.env
```

This runs the benchmark described by the configuration file `test1.env`.

## ⚙️ Configuration File (`.env`)

Each benchmark configuration is defined by a `.env` file. Example:

```env
REPS=2
TRIAL_FILE=trials/volume_taylor.py
CPU_SET="0,1"
MEMORY=4g
SWAP=6g
THP_MODE=always
SWAPPINESS=1
DIRTY_RATIO=10
DIRTY_BG_RATIO=5
SCHED_CHILD_FIRST=1
```

### 🛠 Required Parameters

-   **REPS**: Number of repetitions to execute the benchmark.
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

    -   Execution time
    -   CPU Usage percentage
    -   Maximum set size (max allocated memory to a process)
    -   Context switches (Voluntary and Involuntary)
    -   Page faults
    -   OOM events

-   A **CSV report** of memory usage is also saved.
-   All logs and raw data are saved in the `benchmark_logs/` directory.

## 📁 Example Directory Structure

```
benchmark_logs/
├── trial1/
│   └── 2025-05-16_14-03-12/
│       ├── config_info.txt
│       └── exec_log.txt
│       └── exec_log.csv
│       └── memory_log.csv
```

## 🧩 Notes

-   The container is built and run dynamically from the configuration.
-   No state or container image is preserved unless explicitly saved.
-   If the python script depends on other files they should be loaded into `dependencies` directory and they will be loaded to `/root/shared` in the container

---
