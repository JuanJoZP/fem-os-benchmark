#!/bin/bash
set -e

echo "Aplicando parámetros del kernel..."
/root/shared/set_kernel_params.sh || (echo "No se pudieron aplicar algunos parámetros (¿tienes permisos suficientes?)"; exit)

# num CPUs asignados por Docker
QUOTA=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
PERIOD=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)

if [ "$QUOTA" -gt 0 ]; then
    CPUS=$(( (QUOTA + PERIOD - 1) / PERIOD ))
else
    CPUS=$(nproc) 
fi

export OMP_NUM_THREADS=$CPUS
export MKL_NUM_THREADS=$CPUS
export OPENBLAS_NUM_THREADS=$CPUS

REPS=5
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
METRICS_FILE="/root/shared/${TIMESTAMP}/log.txt"
CSV_FILE="/root/shared/${TIMESTAMP}/log.csv"
echo "repetition,real_time_sec,max_resident_kb,minor_faults,major_faults,vol_ctx_switches,invol_ctx_switches,cpu_percent,swaps" > "$CSV_FILE"
INFO_FILE="/root/shared/${TIMESTAMP}/info.txt"
/root/shared/get_os_info.sh >> "$INFO_FILE" 2>&1
echo ""

BENCHMARK_CMD="mpirun -n ${OMP_NUM_THREADS} python3 /root/shared/main.py"

for i in $(seq 1 $REPS)
do
    echo "==============================" | tee -a "$METRICS_FILE"
    echo "Repetición $i" | tee -a "$METRICS_FILE"

    if [ -w /proc/sys/vm/drop_caches ]; then
        sync
        echo 3 > /proc/sys/vm/drop_caches
        echo "Caches limpiadas" | tee -a "$METRICS_FILE"
    else
        echo "No se pueden limpiar caches (necesita permisos root)" | tee -a "$METRICS_FILE"
    fi

    echo ""
    echo ">>> Ejecutando benchmark..."

    echo "[Repetición $i]" >> "$METRICS_FILE"
    /usr/bin/time --output="$METRICS_FILE" --append -v $BENCHMARK_CMD

    echo ""
    echo ">>> Métricas más importantes:"
    awk "/\\[Repetición $i\\]/, /\\[Repetición $(($i + 1))\\]/" "$METRICS_FILE" 2>/dev/null |
    grep -E "Elapsed|Maximum resident|page faults|Context|CPU|swaps" |
    sed 's/^/  /'

    REAL_TIME=$(awk "/\\[Repetición $i\\]/, /\\[Repetición $(($i + 1))\\]/" "$METRICS_FILE" 2>/dev/null | grep "Elapsed (wall clock)" | awk '{print $8}')
    if [[ "$REAL_TIME" =~ ^([0-9]+):([0-9.]+)$ ]]; then
        MIN=${BASH_REMATCH[1]}
        SEC=${BASH_REMATCH[2]}
        REAL_SEC=$(echo "$MIN * 60 + $SEC" | bc)
    else
        REAL_SEC=$REAL_TIME
    fi
    echo "  Throughput estimado: $(echo "scale=2; 1 / $REAL_SEC" | bc) iteraciones/seg"
    echo ""
    
    if [ -n "$OOM_MSG" ]; then
        echo "Posible evento OOM detectado (ver log.txt)."
        echo "Último mensaje OOM del kernel:" >> $METRICS_FILE
        echo "$OOM_MSG" >> $METRICS_FILE
    fi

    echo ""

done

for i in $(seq 1 $REPS); do
    block=$(awk "/\\[Repetición $i\\]/, /\\[Repetición $(($i + 1))\\]/" "$METRICS_FILE" 2>/dev/null)

    elapsed=$(echo "$block" | grep "Elapsed (wall clock)" | awk '{print $8}')
    max_res=$(echo "$block" | grep "Maximum resident" | awk '{print $6}')
    minor=$(echo "$block" | grep "Minor" | awk '{print $7}')
    major=$(echo "$block" | grep "Major" | awk '{print $6}')
    volctx=$(echo "$block" | grep "Voluntary context" | awk '{print $4}')
    involctx=$(echo "$block" | grep "Involuntary context" | awk '{print $4}')
    cpu=$(echo "$block" | grep "Percent of CPU" | awk '{print $7}' | tr -d '%')
    swaps=$(echo "$block" | grep "Swaps" | awk '{print $2}')

    echo "$i,$elapsed,$max_res,$minor,$major,$volctx,$involctx,$cpu,$swaps" >> "$CSV_FILE"
done

echo "Benchmark completado. Resultados resumidos en $CSV_FILE"