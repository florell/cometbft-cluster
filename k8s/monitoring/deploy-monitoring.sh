#!/bin/bash

set -e

NAMESPACE="monitoring"

# Delete if exists
echo "🔥 Удаление предыдущего мониторинга..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found=true

# Wait for deletion
while kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; do
  echo "⏳ Ожидание удаления пространства имён '$NAMESPACE'..."
  sleep 5
done

# Add Helm repo and update
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update

# Deploy kube-prometheus-stack
echo "🚀 Установка kube-prometheus-stack..."
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace "$NAMESPACE" --create-namespace \
  -f monitoring/values.yaml

# Apply ServiceMonitor for Tendermint
echo "📡 Применяем ServiceMonitor..."
kubectl apply -f monitoring/service-monitor.yaml

# Apply Tendermint dashboard configmap
echo "📊 Настройка Tendermint dashboard..."
helm template tendermint-dashboard monitoring/tendermint-dashboard \
  --namespace "$NAMESPACE" > monitoring/tendermint-dashboard-rendered.yaml

kubectl apply -f monitoring/tendermint-dashboard-provider.yaml
kubectl apply -f monitoring/tendermint-dashboard-rendered.yaml

# Restart Grafana to reload dashboards
echo "♻️ Перезапуск Grafana pod..."
kubectl delete pod -l app.kubernetes.io/name=grafana -n "$NAMESPACE" --wait=true

# Port-forward info
echo -e "\n👉 Чтобы зайти в Grafana запусти:"
echo "kubectl port-forward svc/monitoring-grafana -n $NAMESPACE 3000:80"
echo "Логин: admin  Пароль: prom-operator"
