#!/bin/bash

# Verifica argumento
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <carpeta>"
    exit 1
fi

FOLDER="$1"
EXEC_FILE="$FOLDER/exec_log.csv"
MEMORY_FILE="$FOLDER/memory_log.csv"
STATS_FILE="$FOLDER/stats/exec_stats.txt"
mkdir "$FOLDER/stats"

# ======== 1. Procesar exec_log.csv ========
if [ -f "$EXEC_FILE" ]; then
    echo "Procesando $EXEC_FILE..."

    {
        echo -e "variable\tpromedio\tvarianza"
        awk -F',' '
        NR==1 {
            # guardamos nombres de columnas
            for (i=1; i<=NF; i++) header[i]=$i
            next
        }
        {
            nrows++
            for (i=1; i<=NF; i++) {
                sum[i]   += $i
                sumsq[i] += ($i)^2
            }
        }
        END {
            for (i=1; i<=NF; i++) {
                mean = sum[i] / nrows
                var  = (sumsq[i] / nrows) - (mean^2)
                printf("%s\t%.6f\t%.6f\n", header[i], mean, var)
            }
        }' "$EXEC_FILE"
    } > "$STATS_FILE"

    echo "Archivo de estadísticas generado: $STATS_FILE"
else
    echo "No se encontró $EXEC_FILE"
fi

# ======== 2. Procesar memory_log.csv y generar gráficos ========
if [ -f "$MEMORY_FILE" ]; then
    echo "Procesando $MEMORY_FILE..."

    IFS=',' read -r -a HEADERS < "$MEMORY_FILE"
    num_cols=${#HEADERS[@]}

    for ((i=1; i<num_cols; i++)); do
        var_name="${HEADERS[i]}"
        output_img="$FOLDER/stats/${var_name}.png"

        gnuplot -persist <<-EOF
            set terminal png size 800,600
            set output "${output_img}"
            set title "Uso de memoria: ${var_name}"
            set xlabel "time"
            set ylabel "${var_name}"
            set datafile separator ","
            plot "${MEMORY_FILE}" using 1:$(($i+1)) with lines title "${var_name}" lw 2
EOF

        echo "Imagen generada: $output_img"
    done
else
    echo "No se encontró $MEMORY_FILE"
fi
