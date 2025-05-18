#!/bin/bash

set -e

REMOTE_DIR="/mnt/config"

# сборка образа
eval $(minikube docker-env)

# деплой днс резольвера и кластера
minikube kubectl -- apply -f ./k8s/headless_service.yaml
minikube kubectl -- apply -f ./k8s/statefulset.yaml

kubectl apply -f ./k8s/cometbft_rpc_gateway.yaml

# деплой rpc-интерфейса для нод кластера
minikube kubectl -- apply -f k8s/access_service.yaml

