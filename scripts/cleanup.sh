#!/bin/bash

minikube kubectl -- delete service cometbft
minikube kubectl -- delete statefulset cometbft
minikube kubectl -- delete pod -l app=cometbft --ignore-not-found --grace-period=0 --force
minikube kubectl -- delete service cometbft-rpc

minikube kubectl -- delete service cometbft-rpc-gateway
minikube kubectl -- delete deployment cometbft-rpc-gateway
minikube kubectl -- delete  configmap cometbft-rpc-gateway-conf
kill $(cat .minikube_mount.pid)

rm -rf config
rm -f k8s/_statefulset_generated.yaml
rm -f .minikube_mount.pid
