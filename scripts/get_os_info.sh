#!/bin/bash
set -e

echo "===== INFORMACIÓN DEL CONTENEDOR ====="
echo

echo "Información de la CPU:"
echo -n "Nucleos disponibles dentro del contenedor: "
nproc
lscpu | grep -E 'Model name|Socket|Core|Thread|CPU\(s\)' | grep -v -E 'BIOS|On-line|NUMA'
echo


echo -n "Memoria asignada al contenedor (bytes): "
cat /sys/fs/cgroup/memory.max

echo -n "Área de swap asignada al contenedor (bytes): "
cat /sys/fs/cgroup/memory.swap.max
echo

echo "Transparent Huge Pages (THP):"
cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || echo "No disponible"
echo

SCHEDULER=$(grep '^SCHEDULER=' /root/shared/.env | cut -d '=' -f2-)
echo -n "CPU Scheduler: "
echo $SCHEDULER
echo

echo "Parámetros de los schedulers:"
for param in sched_rr_timeslice_ms sched_cfs_bandwidth_slice_us; do
  printf "  %-40s = %s\n" "$(basename "/proc/sys/kernel/$param")" "$(cat "/proc/sys/kernel/$param")"
done
echo


echo "Parámetros de Virtual Memory Manager:"
for param in swappiness dirty_ratio dirty_background_ratio overcommit_memory min_free_kbytes; do
  printf "  %-30s = %s\n" "$param" "$(cat /proc/sys/vm/$param 2>/dev/null)"
done