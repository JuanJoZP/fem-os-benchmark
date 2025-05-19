#!/bin/bash
set -e

echo "Aplicando parámetros del kernel..."
/root/shared/set_kernel_params.sh || (echo "No se pudieron aplicar algunos parámetros (¿tienes permisos suficientes?)"; exit)


CPUS=$(nproc)
export OMP_NUM_THREADS=$CPUS
export MKL_NUM_THREADS=$CPUS
export OPENBLAS_NUM_THREADS=$CPUS

REPS=$(grep '^REPS=' /root/shared/.env | cut -d '=' -f2-)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TRIAL_FILE=$(grep '^TRIAL_FILE=' /root/shared/.env | cut -d '=' -f2-)
TRIAL_NAME=$(basename "$TRIAL_FILE" .py)

INFO_FILE="/root/shared/benchmark_logs/${TRIAL_NAME}/${TIMESTAMP}/config_info.txt"
METRICS_FILE="/root/shared/benchmark_logs/${TRIAL_NAME}/${TIMESTAMP}/exec_log.txt"
CSV_FILE="/root/shared/benchmark_logs/${TRIAL_NAME}/${TIMESTAMP}/exec_log.csv"
MEMORY_LOG_FILE="/root/shared/benchmark_logs/${TRIAL_NAME}/${TIMESTAMP}/memory_log.csv"
mkdir -p "$(dirname "$CSV_FILE")"

echo "repetition,real_time_sec,cpu_percent,max_resident_kb,vol_ctx_switches,invol_ctx_switches,page_faults" > "$CSV_FILE"
echo "time,MemTotal,MemAvailable,SwapTotal,SwapFree,AnonPages,PageTables,AnonHugePages,nr_anon_transparent_hugepages" > "$MEMORY_LOG_FILE"
/root/shared/get_os_info.sh >> "$INFO_FILE" 2>&1

BENCHMARK_CMD="mpirun -n ${OMP_NUM_THREADS} python3 /root/shared/main.py"

echo ""
for i in $(seq 1 $REPS)
do
    echo "==============================" | tee -a "$METRICS_FILE"
    echo "Repetición $i"

    if [ -w /proc/sys/vm/drop_caches ]; then
        sync
        echo 3 > /proc/sys/vm/drop_caches
        echo "Caches limpiadas"
    else
        echo "No se puedieron limpiar caches (necesita permisos root)" | tee -a "$METRICS_FILE"
    fi

    echo ""
    echo ">>> Ejecutando benchmark..."

    # monitoreo de memoria en segundo plano
    {
        while true; do
            MemTotal=$(grep -i 'MemTotal' /proc/meminfo | awk '{print $2}')
            MemAvailable=$(grep -i 'MemAvailable' /proc/meminfo | awk '{print $2}')
            SwapTotal=$(grep -i 'SwapTotal' /proc/meminfo | awk '{print $2}')
            SwapFree=$(grep -i 'SwapFree' /proc/meminfo | awk '{print $2}')
            AnonPages=$(grep -i 'AnonPages' /proc/meminfo | awk '{print $2}')
            PageTables=$(grep -i 'PageTables' /proc/meminfo | grep -i -v 'SecPageTables' | awk '{print $2}')
            AnonHugePages=$(grep -i 'AnonHugePages' /proc/meminfo | awk '{print $2}')
            nr_anon_transparent_hugepages=$(grep -i 'nr_anon_transparent_hugepages' /proc/vmstat | awk '{print $2}')

            echo "$(date '+%s'),$MemTotal,$MemAvailable,$SwapTotal,$SwapFree,$AnonPages,$PageTables,$AnonHugePages,$nr_anon_transparent_hugepages" >> "$MEMORY_LOG_FILE"
            sleep 0.5
        done
    } &

    MONITOR_PID=$!

    echo "[Repetición $i]" >> "$METRICS_FILE"
    format="Tiempo total (segundos): %e\nTiempo de CPU en modo usuario (segundos): %U\nTiempo de CPU en modo kernel (segundos): %S\nPorcentaje de CPU utilizado: %P%%\nMemoria residente máxima: %M KB\nContext switches voluntarios: %w\nContext switches involuntarios: %c\nPage faults: %F\n"
    /usr/bin/time --output="$METRICS_FILE" --append --format="$format" $BENCHMARK_CMD


    kill $MONITOR_PID # detiene el monitoreo de memoria

    echo
    echo ">>> Métricas más importantes:"
    awk "/\\[Repetición $i\\]/, /\\[Repetición $(($i + 1))\\]/" "$METRICS_FILE" 2>/dev/null | grep -i -v 'repetición' | sed 's/^/  /'
    
    if [ -n "$OOM_MSG" ]; then
        echo "Posible evento OOM detectado (ver log.txt)."
        echo "Último mensaje OOM del kernel:" >> $METRICS_FILE
        echo "$OOM_MSG" >> $METRICS_FILE
    fi

    echo
done

for i in $(seq 1 $REPS); do
    block=$(awk -v i="$i" '
        $0 ~ "\\[Repetición " i "\\]" {capture=1}
        $0 ~ "\\[Repetición " (i+1) "\\]" {capture=0}
        capture {print}
    ' "$METRICS_FILE")

    elapsed=$(echo "$block" | grep "Tiempo total" | awk '{print $4}')
    cpu=$(echo "$block" | grep "Porcentaje" | awk '{print $5}' | tr -d '%%')
    max_res=$(echo "$block" | grep "Memoria" | awk '{print $4}')
    volctx=$(echo "$block" | grep " voluntarios" | awk '{print $4}')
    involctx=$(echo "$block" | grep "involuntarios" | awk '{print $4}')
    page_faults=$(echo "$block" | grep "faults" | awk '{print $3}')

    echo "$i,$elapsed,$cpu,$max_res,$volctx,$involctx,$page_faults" >> "$CSV_FILE"
done

echo "Benchmark completado"