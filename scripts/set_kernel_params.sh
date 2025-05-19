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
OVERCOMMIT_MEMORY=${OVERCOMMIT_MEMORY:-1}
MIN_FREE_KBYTES=${MIN_FREE_KBYTES:-163230}

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


sysctl -w vm.swappiness=$SWAPPINESS || true
sysctl -w vm.dirty_ratio=$DIRTY_RATIO || true
sysctl -w vm.dirty_background_ratio=$DIRTY_BG_RATIO || true
sysctl -w vm.overcommit_memory=$OVERCOMMIT_MEMORY || true
sysctl -w vm.min_free_kbytes=$MIN_FREE_KBYTES || true

echo
echo "Parámetros aplicados."