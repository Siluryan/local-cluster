# Publicar URLs via Cloudflare Tunnel

Este lab publica serviços HTTP por **Cloudflare Tunnel**, sem necessidade de abrir portas no roteador.

## Pré-requisitos

- Domínio no Cloudflare: `personaldevopstrainer.online`
- Um Tunnel criado no Cloudflare Zero Trust (token gerado)
- No cluster, o `cloudflared` rodando (módulo `cloudflare-tunnel`)

## Como funciona (visão rápida)

1. O `cloudflared` no cluster conecta no Cloudflare usando o `TUNNEL_TOKEN`
2. No Zero Trust, crie **Public Hostnames** (ex.: `grafana.personaldevopstrainer.online`)
3. Cada hostname aponta para um **Service interno** do Kubernetes (URL local do cluster)
4. O Envoy Gateway roteia para a app via `HTTPRoute`

## Hostnames recomendados

- `crm.personaldevopstrainer.online`
- `grafana.personaldevopstrainer.online`
- `prometheus.personaldevopstrainer.online`
- `keycloak.personaldevopstrainer.online`
- `vaultwarden.personaldevopstrainer.online`
- `headlamp.personaldevopstrainer.online`
- `nexus.personaldevopstrainer.online`
- `vpn.personaldevopstrainer.online` (apenas UI do WG-Easy; WireGuard UDP não passa pelo Tunnel)

## Configurar no Cloudflare Zero Trust

No painel do Cloudflare:

1. Acesse **Zero Trust**, **Networks**, **Tunnels**
2. Abra o tunnel, **Public Hostnames**, **Add a public hostname**
3. Preencha:
   - **Subdomain**: por exemplo `grafana`
   - **Domain**: `personaldevopstrainer.online`
   - **Type**: `HTTP`
   - **URL** (origem): aponte para um endpoint interno do cluster

### Qual URL interna usar

Há dois caminhos.

#### Caminho A (recomendado): apontar tudo para o Envoy

Crie todos os hostnames no Cloudflare apontando para o **proxy HTTP** gerenciado pelo Envoy Gateway (o Service na porta **80**).

**Importante:** o Service criado pelo Helm com nome `envoy-gateway` é o **control plane** (portas como 18000/9443), **não** escuta na porta 80. Depois que existem `GatewayClass` `eg` e `Gateway` `envoy-gateway` (criados pelo Terraform neste repositório), o controlador cria **outro** `Service` com nome longo (ex.: `envoy-envoy-gateway-system-envoy-gateway-...`) que expõe **80/TCP**. É esse nome que deve aparecer na URL de origem do tunnel.

Descubra o nome atual:

```bash
kubectl get svc -n envoy-gateway-system -o json \
  | jq -r '.items[] | select(.spec.ports[]?.port == 80) | .metadata.name'
```

Use na Cloudflare (substitua `<nome>` pelo resultado):

- **URL**: `http://<nome>.envoy-gateway-system.svc.cluster.local:80`

Vantagem: um único endpoint HTTP no cluster; o roteamento por hostname continua nos `HTTPRoute`.

#### Caminho B: apontar direto para cada Service

Use o Service interno de cada app. Exemplos comuns:

- Grafana: `http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local:80`
- Prometheus: `http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090`
- Vaultwarden: `http://vaultwarden.vaultwarden.svc.cluster.local:80`
- WG-Easy UI: `http://wireguard-ui.wireguard.svc.cluster.local:80`
- Nexus: `http://nexus-nexus-repository-manager.nexus.svc.cluster.local:8081`
- Keycloak: `http://keycloak.keycloak.svc.cluster.local:80`
- Headlamp: `http://headlamp.headlamp.svc.cluster.local:80` — OIDC descrito em [`headlamp-oauth.md`](./headlamp-oauth.md)

## TLS / HTTPS

- O HTTPS público pode ser terminado pelo Cloudflare automaticamente.
- Se quiser TLS end-to-end dentro do cluster, use `cert-manager` + `HTTPRoute`/Gateway com TLS (depende do setup do gateway).

## Validação

No cluster:

```bash
kubectl -n cloudflare-tunnel get pods
kubectl get httproute -A
```

Externamente:

```bash
curl -I https://grafana.personaldevopstrainer.online
curl -I https://crm.personaldevopstrainer.online/api/health
```

## Importante (WireGuard)

O Tunnel da Cloudflare não encapsula WireGuard UDP/51820.

- Publicavel pelo Tunnel: **apenas a UI** (`https://vpn.personaldevopstrainer.online`)
- Para a VPN funcionar fora de casa: é necessário expor UDP 51820 (NodePort/LoadBalancer + NAT no roteador)

## Se o tunnel não alcança o serviço (502, erro no cloudflared)

Veja o roteiro completo em **[`debug-acesso-publico.md`](./debug-acesso-publico.md)** (Service interno correto na porta **80** do **proxy Envoy**, não confundir com o Service `envoy-gateway` do Helm; exemplos com Wazuh e porta **5601**).

