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

IMAGE_NAME=benchmark_img_tmp

echo "Construyendo imagen Docker"
docker build -q --build-arg TRIAL_FILE="$TRIAL_FILE" -t $IMAGE_NAME .
echo

CONTAINER_NAME=benchmark_temp
HOST_LOG_DIR=./benchmark_logs

echo "Ejecutando contenedor"
echo
docker run --privileged --name "$CONTAINER_NAME" \
  --cpuset-cpus=$CPU_SET \
  --memory=$MEMORY \
  --memory-swap=$SWAP \
  $IMAGE_NAME

docker cp "$CONTAINER_NAME":/root/shared/benchmark_logs /tmp/container_logs > /dev/null
mkdir -p "$HOST_LOG_DIR"
rsync -av --ignore-existing /tmp/container_logs/ "$HOST_LOG_DIR/" > /dev/null
rm -rf /tmp/container_logs

docker rm "$CONTAINER_NAME" > /dev/null
docker image rm $IMAGE_NAME --force  > /dev/null
rm .env