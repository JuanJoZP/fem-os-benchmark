#!/bin/bash
set -e

# Verifica permisos
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Este script requiere permisos de root."
    exit 1
fi

# Carga variables de entorno
if [[ -f /root/shared/.env ]]; then
    echo "Cargando variables desde .env..."
    set -a
    source /root/shared/.env
    set +a
fi

# Asigna valores por defecto si alguna variable no está definida
THP_MODE=${THP_MODE:-"madvise"}
SWAPPINESS=${SWAPPINESS:-60}
DIRTY_RATIO=${DIRTY_RATIO:-20}
DIRTY_BG_RATIO=${DIRTY_BG_RATIO:-10}
SCHED_CHILD_FIRST=${SCHED_CHILD_FIRST:-0}

echo
# Transparent Huge Pages (si se puede)
if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
    echo "$THP_MODE" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "THP configurado a '$THP_MODE'."
    else
        echo "No se pudo escribir en /sys/kernel/mm/transparent_hugepage/enabled (¿permiso denegado?)."
    fi
else
    echo "El sistema no soporta THP o el archivo no está disponible en este contenedor."
fi

# Swappiness
sysctl -w vm.swappiness=$SWAPPINESS || true

# Dirty cache ratios
sysctl -w vm.dirty_ratio=$DIRTY_RATIO || true
sysctl -w vm.dirty_background_ratio=$DIRTY_BG_RATIO || true

if [ -f /proc/sys/kernel/sched_child_runs_first ]; then
    sysctl -w kernel.sched_child_runs_first="$SCHED_CHILD_FIRST" || true
else
    echo "kernel.sched_child_runs_first no está disponible en este sistema. Se omite."
fi

echo
echo "Parámetros aplicados."