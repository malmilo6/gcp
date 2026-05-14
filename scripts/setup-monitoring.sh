#!/bin/bash

# Install Prometheus
kubectl create namespace monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --set server.persistentVolume.size=10Gi \
  --set alertmanager.enabled=false

# Install Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set persistence.enabled=true \
  --set persistence.size=5Gi \
  --set adminPassword=admin123

# Install Loki for centralized logging
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=true \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi

# Install Prometheus Adapter for HPA
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus-adapter prometheus-community/prometheus-adapter \
  --namespace monitoring \
  --set prometheus.url=http://prometheus-server.monitoring.svc.cluster.local

# Expose Grafana
kubectl expose deployment grafana --type=LoadBalancer --name=grafana-lb -n monitoring

echo "Monitoring setup complete!"
echo "Grafana admin password: admin123"
echo "Get Grafana URL: kubectl get svc grafana-lb -n monitoring"