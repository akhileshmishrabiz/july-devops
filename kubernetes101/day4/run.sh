#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="scaling"

install_lab() {
  kubectl apply -f "$ROOT_DIR/namespace.yaml"

  helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ --force-update
  helm repo add fairwinds-stable https://charts.fairwinds.com/stable --force-update
  helm repo update

  helm upgrade --install metrics-server metrics-server/metrics-server \
    --namespace kube-system \
    --version 3.14.0 \
    --values "$ROOT_DIR/metrics-server-values.yaml" \
    --wait \
    --timeout 5m

  helm upgrade --install vpa fairwinds-stable/vpa \
    --namespace "$NAMESPACE" \
    --version 5.1.0 \
    --values "$ROOT_DIR/vpa-values.yaml" \
    --wait \
    --timeout 5m

  kubectl apply -f "$ROOT_DIR/apps.yaml"
  kubectl apply -f "$ROOT_DIR/load-generators.yaml"
  kubectl apply -f "$ROOT_DIR/hpa.yaml"
  kubectl apply -f "$ROOT_DIR/vpa.yaml"

  kubectl rollout status deployment/hpa-app -n "$NAMESPACE" --timeout=180s
  kubectl rollout status deployment/vpa-app -n "$NAMESPACE" --timeout=180s
  kubectl wait --for=condition=Available \
    apiservice/v1beta1.metrics.k8s.io \
    --timeout=180s

  echo
  echo "Scaling lab installed."
  echo "Start HPA traffic: $0 hpa"
  echo "Start VPA traffic: $0 vpa"
  echo "Watch scaling: $0 watch"
}

start_hpa_load() {
  kubectl scale deployment/hpa-load -n "$NAMESPACE" --replicas=2
  echo "HPA traffic started."
}

start_vpa_load() {
  kubectl scale deployment/vpa-load -n "$NAMESPACE" --replicas=1
  echo "VPA traffic started."
}

stop_hpa_load() {
  kubectl scale deployment/hpa-load -n "$NAMESPACE" --replicas=0
  echo "HPA traffic stopped."
}

stop_vpa_load() {
  kubectl scale deployment/vpa-load -n "$NAMESPACE" --replicas=0
  echo "VPA traffic stopped."
}

stop_all_load() {
  stop_hpa_load
  stop_vpa_load
}

show_status() {
  kubectl get deployment,pod,hpa,vpa -n "$NAMESPACE"
  echo
  kubectl top pods -n "$NAMESPACE" || true
  echo
  kubectl describe vpa vpa-app -n "$NAMESPACE" |
    awk '/Recommendation:/,/Conditions:/' || true
}

watch_lab() {
  while true; do
    clear
    date
    show_status
    sleep 3
  done
}

cleanup_lab() {
  helm uninstall vpa --namespace "$NAMESPACE" || true
  helm uninstall metrics-server --namespace kube-system || true
  kubectl delete namespace "$NAMESPACE" --ignore-not-found
}

usage() {
  cat <<EOF
Usage: $0 <command>

Commands:
  apps         Install Metrics Server, VPA, apps, and autoscalers (default)
  hpa          Start traffic only for the HPA app
  vpa          Start traffic only for the VPA app
  stop-hpa     Stop HPA traffic
  stop-vpa     Stop VPA traffic
  stop         Stop all generated traffic
  status       Show workloads, metrics, HPA, and VPA recommendations
  watch        Continuously display scaling status
  cleanup      Remove the complete lab
EOF
}

case "${1:-apps}" in
  apps|install)
    install_lab
    ;;
  hpa)
    start_hpa_load
    ;;
  vpa)
    start_vpa_load
    ;;
  stop-hpa)
    stop_hpa_load
    ;;
  stop-vpa)
    stop_vpa_load
    ;;
  stop)
    stop_all_load
    ;;
  status)
    show_status
    ;;
  watch)
    watch_lab
    ;;
  cleanup)
    cleanup_lab
    ;;
  *)
    usage
    exit 1
    ;;
esac
