#!/bin/bash

MOUNT_DIR="$(pwd)/config"
REMOTE_DIR="/mnt/config"

echo "монтируем $MOUNT_DIR внутрь Minikube как $REMOTE_DIR..."

# запуск в фоне + вывод в лог
minikube mount "$MOUNT_DIR:$REMOTE_DIR" > .minikube_mount.log 2>&1 &

# сохраняем PID для очистки
MOUNT_PID=$!
echo $MOUNT_PID > .minikube_mount.pid

echo "mount запущен (PID=$MOUNT_PID)"
