#!/usr/bin/env bash
set -euo pipefail

fail=0

check_url() {
  local name="$1"
  local url="$2"
  local code
  code=$(curl -sSIL -o /dev/null -w "%{http_code}" --connect-timeout 15 --max-time 45 "$url") || code="ERR"
  if [[ "$code" == "200" ]]; then
    printf 'OK  [%s] %s\n' "$code" "$name"
  else
    printf 'BAD [%s] %s (%s)\n' "$code" "$name" "$url"
    fail=1
  fi
}

echo "Checando repositórios Helm (HEAD nos index.yaml, com redirects)..."
check_url "bitnami"           "https://charts.bitnami.com/bitnami/index.yaml"
check_url "external-dns"      "https://kubernetes-sigs.github.io/external-dns/index.yaml"
check_url "external-secrets" "https://charts.external-secrets.io/index.yaml"
check_url "jetstack"          "https://charts.jetstack.io/index.yaml"
check_url "prometheus-community" "https://prometheus-community.github.io/helm-charts/index.yaml"
check_url "headlamp"          "https://kubernetes-sigs.github.io/headlamp/index.yaml"
check_url "sonatype-nexus"    "https://sonatype.github.io/helm3-charts/index.yaml"
check_url "wazuh-morgoved" "https://morgoved.github.io/wazuh-helm/index.yaml"

echo ""
echo "OCI: oci://docker.io/envoyproxy/gateway-helm (helm show chart ...)"

if [[ "$fail" -ne 0 ]]; then
  echo ""
  exit 1
fi

echo ""
