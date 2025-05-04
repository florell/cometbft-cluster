#!/bin/bash

minikube kubectl -- delete service tendermint
minikube kubectl -- delete statefulset tendermint
minikube kubectl -- delete pod -l app=tendermint --ignore-not-found
minikube kubectl -- delete service tendermint-rpc
kill $(cat .minikube_mount.pid)

rm -rf config
rm -f k8s/_statefulset_generated.yaml
rm -f .minikube_mount.pid
