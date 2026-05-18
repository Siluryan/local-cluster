#!/usr/bin/env bash
set -euo pipefail

BACKSTAGE_DIR="${BACKSTAGE_DIR:-$HOME/Documentos/backstage-app}"
KIND_CLUSTER="${KIND_CLUSTER:-local-cluster}"
IMAGE="${BACKSTAGE_IMAGE:-backstage:latest}"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 22 >/dev/null
corepack enable >/dev/null

echo "==> Build Backstage em ${BACKSTAGE_DIR}"
cd "$BACKSTAGE_DIR"
yarn install --immutable
yarn tsc
yarn build:backend
yarn build-image

if [[ "$IMAGE" != "backstage" && "$IMAGE" != "backstage:latest" ]]; then
  docker tag backstage "$IMAGE"
fi

echo "==> Carregando ${IMAGE} no Kind (${KIND_CLUSTER})"
kind load docker-image "$IMAGE" --name "$KIND_CLUSTER"

echo "OK. Imagem disponível no cluster. Rode terraform apply e depois:"
echo "  kubectl -n backstage port-forward svc/backstage 7007:80"
