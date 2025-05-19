#!/bin/bash
set -e

echo "===== INFORMACIÓN DEL CONTENEDOR ====="
echo

echo "Información de la CPU:"
echo -n "Nucleos disponibles dentro del contenedor: "
lscpu | grep -E 'Model name|Socket|Core|Thread|CPU\(s\)' | grep -v -E 'BIOS|On-line|NUMA'
nproc
echo

echo -n "Memoria asignada al contenedor: "
grep -i 'memtotal' /proc/meminfo | awk '{print $2 $3}'
echo

echo -n "Área de swap asignada al contenedor: "
grep -i 'swaptotal' /proc/meminfo | awk '{print $2 $3}'
echo

echo "Scheduler actual del proceso (pid 1):"
ps -o policy,cmd -p 1 --no-headers
echo

echo "Política de planificación del sistema:"
cat /sys/block/*/queue/scheduler 2>/dev/null | head -1 || echo "No se pudo detectar"
echo

echo "Transparent Huge Pages (THP):"
cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || echo "No disponible"
echo

echo "Algoritmo de reemplazo de páginas:"
grep . /sys/kernel/mm/kswapd/* 2>/dev/null | grep -i reclaim || echo "No se puede determinar directamente (por defecto: LRU)"
echo

echo "Parámetros de Completely Fair Scheduler (CFS):"
for param in /proc/sys/kernel/sched_*; do
  printf "  %-40s = %s\n" "$(basename "$param")" "$(cat "$param")"
done
echo


echo "Parámetros de Virtual Memory Manager:"
for param in overcommit_memory dirty_ratio dirty_background_ratio swappiness min_free_kbytes; do
  printf "  %-30s = %s\n" "$param" "$(cat /proc/sys/vm/$param 2>/dev/null)"
done