#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${CHART_CACHE_DIR:-$ROOT/infraestructure/helm-charts/cache}"

mkdir -p "$OUT"
cd "$OUT"

pull_http() {
  local repo="$1"
  local chart="$2"
  local ver="$3"
  helm pull "$chart" --repo "$repo" --version "$ver"
}

pull_http "https://charts.jetstack.io" "cert-manager" "v1.14.4"
pull_http "https://kubernetes-sigs.github.io/external-dns/" "external-dns" "1.15.0"
pull_http "https://charts.external-secrets.io" "external-secrets" "0.10.5"
pull_http "https://kubernetes-sigs.github.io/headlamp/" "headlamp" "0.27.0"
pull_http "https://prometheus-community.github.io/helm-charts" "kube-prometheus-stack" "66.2.2"
pull_http "https://sonatype.github.io/helm3-charts/" "nexus-repository-manager" "64.2.0"
pull_http "https://morgoved.github.io/wazuh-helm/" "wazuh" "1.0.23"

helm pull oci://docker.io/envoyproxy/gateway-helm --version "v1.4.0"

helm pull keycloak --repo "https://charts.bitnami.com/bitnami" --version "24.7.4"
