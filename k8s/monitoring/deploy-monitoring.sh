#!/bin/bash

set -e

NAMESPACE="monitoring"

echo "удаление предыдущего мониторинга..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found=true

while kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; do
  echo "...ожидание удаления пространства имён '$NAMESPACE'..."
  sleep 5
done

# добавляем репозиторий и обновляем
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update

# kube-prometheus-stack
echo "установка kube-prometheus-stack..."
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace "$NAMESPACE" --create-namespace \
  -f monitoring/values.yaml

echo "применяем ServiceMonitor..."
kubectl apply -f monitoring/service-monitor.yaml

echo "настройка cometbft дешборда..."
helm template cometbft-dashboard monitoring/cometbft-dashboard \
  --namespace "$NAMESPACE" > monitoring/cometbft-dashboard-rendered.yaml

kubectl apply -f monitoring/cometbft-dashboard-provider.yaml
kubectl apply -f monitoring/cometbft-dashboard-rendered.yaml

# для презапуска дешбордов
echo "перезапуск Grafana pod..."
kubectl delete pod -l app.kubernetes.io/name=grafana -n "$NAMESPACE" --wait=true

echo "kubectl port-forward svc/monitoring-grafana -n $NAMESPACE 3000:80"
echo "admin: prom-operator"
