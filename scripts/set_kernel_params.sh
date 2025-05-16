#!/bin/bash
set -e

echo "Aplicando parámetros del kernel desde variables de entorno"

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

# Transparent Huge Pages (si se puede)
if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
    echo "$THP_MODE" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "  THP configurado a '$THP_MODE'."
    else
        echo "No se pudo escribir en /sys/kernel/mm/transparent_hugepage/enabled (¿permiso denegado?)."
    fi
else
    echo "El sistema no soporta THP o el archivo no está disponible en este contenedor."
fi

# Swappiness
sysctl -w vm.swappiness=$SWAPPINESS || true
echo "  Swappiness: $SWAPPINESS"

# Dirty cache ratios
sysctl -w vm.dirty_ratio=$DIRTY_RATIO || true
sysctl -w vm.dirty_background_ratio=$DIRTY_BG_RATIO || true
echo "  Dirty ratio: $DIRTY_RATIO"
echo "  Dirty background ratio: $DIRTY_BG_RATIO"

# Scheduler child runs first
sysctl -w kernel.sched_child_runs_first=$SCHED_CHILD_FIRST || true
echo "  Scheduler child first: $SCHED_CHILD_FIRST"

echo "Parámetros aplicados."