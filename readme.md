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
OVERCOMMIT_MEMORY=1
MIN_FREE_KBYTES=5120
SCHEDULER=rr
SCHED_CFS_BANDWIDTH_SLICE_US=8000
SCHED_RR_TIMESLICE_MS=100
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

-   **SWAPPINESS**: Kernel swappiness. Controls tendency to swap.  
    (integer 0–100)  
    
-   **DIRTY_RATIO**: Max % of memory filled with dirty pages before flushing to disk.  
    (integer 0–100)

-   **DIRTY_BG_RATIO**: Background dirty page threshold (%).  
    (integer 0–100)

-   **OVERCOMMIT_MEMORY**: `0`: heuristic overcommit (default). `1`: always overcommit, never check. `2`: Always check, never overcommit

-   **MIN_FREE_KBYTES**: the minimum amount of RAM that should be kept free for system operations.  
    (integer, bytes)

-   **SCHEDULER**: CPU Scheduler.
    Values: `rr`: Round Robin, `fifo`: First in first out, `cfs`: Completely fair scheduler)

-   **SCHED_CFS_BANDWIDTH_SLICE_US**: Check docs for linux `/proc/sys/kernel/`.  
    (integer, microseconds)

-   **SCHED_RR_TIMESLICE_MS**: Check docs for linux `/proc/sys/kernel/`.  
    (integer, miliseconds)
    
## 📊 Output

-   The benchmark runs the trial for the amount of repetitions requested using the configured resources and OS parameters.
-   For each repetition, the following execution metrics are collected in `benchmark_logs/config/trial/date/exec_log.[txt|csv]`:

    -   Execution time (total, user and kernel)
    -   CPU Usage percentage
    -   Maximum set size (max allocated memory to a process)
    -   Context switches (Voluntary and Involuntary)
    -   Page faults

-   Also the following memory usage metrics are collected in `benchmark_logs/config/trial/date/memory_log.csv` (one entry each half second, during whole execution):

    -   Available memory (kB).
    -   Available swap memory (kB).
    -   Memory used by anonimous pages (kB).
    -   Memory used by the pages table (kB).
    -   Memory used by huge anonimous pages (kB).
    -   Number of anonimous transparent huge pages.
      
-   Mean and variance of execution metrics, and plots of memory metrics evolution in execution time are saved in `benchmark_logs/config/trial/date/stats`

## 🧩 Notes

-   The container is built and run dynamically from the configuration, then destroyed.
-   If the trial script depends on other files they should be loaded into `dependencies` directory and they will be loaded to `/root/shared` in the container.

---
