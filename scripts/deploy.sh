#!/bin/bash

set -e

REMOTE_DIR="/mnt/config"

# сборка образа
eval $(minikube docker-env)
docker build -t tendermint:local -f docker/DOCKERFILE docker/

# деплой днс резольвера и кластера
minikube kubectl -- apply -f ./k8s/headless_service.yaml
minikube kubectl -- apply -f ./k8s/statefulset.yaml

# деплой rpc-интерфейса для нод кластера
minikube kubectl -- apply -f k8s/access_service.yaml

