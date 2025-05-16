#!/bin/bash
set -e

if [[ $# -ne 1 ]]; then
    echo "Uso: $0 <archivo_env>"
    exit 1
fi

ENV_FILE="$1"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Archivo '$ENV_FILE' no encontrado."
    exit 1
fi

cp "$ENV_FILE" .env

# Exportar variables de entorno desde .env
set -a
source .env
set +a


echo "Construyendo imagen Docker"
docker build -t $IMAGE_NAME .

echo "Ejecutando contenedor"
docker run --rm --privileged \
  --cpus="$CPUS" \
  --memory="$MEMORY" \
  --memory-swap="$SWAP" \
  $IMAGE_NAME

docker image rm $IMAGE_NAME --force
rm .env