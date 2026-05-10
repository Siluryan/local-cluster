# Por que as URLs do projeto não abrem na Internet?

As URLs listadas no `README.md` (ex.: `https://crm.personaldevopstrainer.online`) **não passam a funcionar só porque o Terraform aplicou** ou porque existe um `HTTPRoute` no cluster. O acesso público depende de **DNS na Cloudflare**, do **tunnel ativo** e, para cada serviço, de **Public Hostnames** configurados.

Este documento reúne os mal-entendidos mais comuns e um checklist objetivo.

## O que o projeto assume

1. **Cloudflare Tunnel** (`cloudflared` no cluster, token válido) — ver [`cloudflare-publicacao.md`](./cloudflare-publicacao.md).
2. **Envoy Gateway** como entrada HTTP no cluster; cada app expõe **`HTTPRoute`** com o hostname certo.
3. No painel **Cloudflare Zero Trust**, um **Public Hostname** por subdomínio a expor (ex.: `grafana`, `keycloak`, `crm`).

Sem o passo 3, resolvers públicos **não têm** um nome que aponte para o tunnel — o navegador não resolve ou não chega ao cluster.

## “DNS propagation” com registro tipo A

Ferramentas online que testam só **registro A** (IPv4) para `*.personaldevopstrainer.online` costumam mostrar **falha em vários lugares**, mesmo quando o site funciona.

Motivos:

- Com **Cloudflare Tunnel**, o que aparece no DNS público costuma ser **CNAME** para o hostname do túnel (ex.: `*.cfargotunnel.com`), não um **A** para o IP da rede local.
- Com **proxy laranja** da Cloudflare, o cliente vê IPs da Cloudflare, não o servidor local diretamente.

**Conclusão:** não use só “DNS CHECK” em modo **A** como prova de que o serviço está mal. Prefira:

```bash
dig crm.personaldevopstrainer.online +short
curl -sI "https://crm.personaldevopstrainer.online/api/health"
```

E confira no painel **DNS** / **Zero Trust** da Cloudflare o que está publicado para esse nome.

## BIND + external-dns versus nameservers do domínio

No cluster, o **external-dns** pode atualizar uma zona **RFC2136** no **BIND** (TSIG). Isso só influencia a Internet **se** o domínio estiver **delegado** para esse servidor DNS (NS apontando para o BIND).

Na configuração típica com domínio na Cloudflare:

- Os **NS** oficiais são os da **Cloudflare**.
- As alterações na zona do BIND **não** são o que o mundo consulta para `personaldevopstrainer.online`.

Ou seja: **Terraform + BIND não substituem** a criação de **Public Hostnames** no tunnel para exposição pública através da Cloudflare.

## Cada URL precisa de hostname no Zero Trust

Para cada URL do `README.md`, **precisa existir** no tunnel uma entrada do tipo:

- **Subdomain**: ex. `keycloak`
- **Domain**: `personaldevopstrainer.online`
- **Origin URL** (recomendado): `http://envoy-gateway.envoy-gateway-system.svc.cluster.local:80`

Assim o Envoy encaminha pelo **Host** HTTP para o `HTTPRoute` certo.

Se **faltar** uma entrada (ex.: só criou `grafana` mas não `crm`), **essa URL não resolve ou não chega ao serviço**.

## Tabela para o formulário Cloudflare (Add published application)

Campos que costumam se repetir:

| Campo | Valor |
|--------|--------|
| **Domain** | `personaldevopstrainer.online` |
| **Path** | vazio *(todos os paths)* |

### Caminho A — um único Service URL (recomendado)

Aponta **todas** as rotas públicas para o Envoy; o cluster encaminha pelo header `Host` e pelos `HTTPRoute`.

| Campo | Valor |
|--------|--------|
| **Service URL** | `http://envoy-gateway.envoy-gateway-system.svc.cluster.local:80` |

**Subdomain** — um hostname por linha na Cloudflare:

| Subdomain | Hostname público |
|-----------|------------------|
| `crm` | `crm.personaldevopstrainer.online` |
| `keycloak` | `keycloak.personaldevopstrainer.online` |
| `grafana` | `grafana.personaldevopstrainer.online` |
| `prometheus` | `prometheus.personaldevopstrainer.online` |
| `wazuh` | `wazuh.personaldevopstrainer.online` |
| `headlamp` | `headlamp.personaldevopstrainer.online` |
| `nexus` | `nexus.personaldevopstrainer.online` |
| `registry` | `registry.personaldevopstrainer.online` |
| `vaultwarden` | `vaultwarden.personaldevopstrainer.online` |
| `vpn` | `vpn.personaldevopstrainer.online` *(só UI WG-Easy)* |

### Caminho B — um Service URL por aplicação

Use quando quiser ir direto ao `Service` Kubernetes (sem passar pelo Envoy). Os nomes assumem os releases/namespaces do lab; confira no cluster se alterou a instalação.

| Subdomain | Hostname público | Service URL |
|-----------|------------------|-------------|
| *(todas via Envoy)* | *(qualquer)* | `http://envoy-gateway.envoy-gateway-system.svc.cluster.local:80` |
| `crm` | `crm.personaldevopstrainer.online` | `http://crm-crm-api.apps.svc.cluster.local:8080` *(`release` `crm`, namespace `apps`; ajuste se for diferente)* |
| `keycloak` | `keycloak.personaldevopstrainer.online` | `http://keycloak.keycloak.svc.cluster.local:80` |
| `grafana` | `grafana.personaldevopstrainer.online` | `http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local:80` |
| `prometheus` | `prometheus.personaldevopstrainer.online` | `http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090` |
| `wazuh` | `wazuh.personaldevopstrainer.online` | `https://wazuh-dashboard.wazuh.svc.cluster.local:443` *(com Wazuh instalado; confira com `kubectl get svc -n wazuh`)* |
| `headlamp` | `headlamp.personaldevopstrainer.online` | `http://headlamp.headlamp.svc.cluster.local:80` *(Envoy → `HTTPRoute` → Headlamp; OIDC Keycloak: [`headlamp-oauth.md`](./headlamp-oauth.md))* |
| `nexus` | `nexus.personaldevopstrainer.online` | `http://nexus-nexus-repository-manager.nexus.svc.cluster.local:8081` |
| `registry` | `registry.personaldevopstrainer.online` | `http://registry.registry.svc.cluster.local:5000` |
| `vaultwarden` | `vaultwarden.personaldevopstrainer.online` | `http://vaultwarden.vaultwarden.svc.cluster.local:80` |
| `vpn` | `vpn.personaldevopstrainer.online` | `http://wireguard-ui.wireguard.svc.cluster.local:80` |

Para conferir nomes e portas reais:

```bash
kubectl get svc -A | egrep 'envoy|keycloak|grafana|prometheus|headlamp|nexus|registry|vaultwarden|wireguard|crm|wazuh'
```

## CRM é um caso especial

O **CRM** (`https://crm.personaldevopstrainer.online`) está documentado em [`app-crm.md`](./app-crm.md): deploy com Helm em `app/helm/crm`, **fora** do módulo Terraform central da infra.

Mesmo com infra + tunnel corretos:

- É preciso **instalar** o release do CRM no cluster.
- O chart define `HTTPRoute` e `DNSEndpoint`; o acesso público continua dependendo do **Public Hostname** `crm` no Cloudflare.

## Checklist rápido

| Passo | O que verificar |
|--------|------------------|
| Tunnel | `kubectl -n cloudflare-tunnel get pods` — pods `Running` |
| Token | Variável `cloudflare_tunnel_token` correta no Terraform / segredo no cluster |
| Envoy | `kubectl get gateway -A`, `kubectl get httproute -A` — rotas com o hostname esperado |
| Cloudflare | Zero Trust → Tunnels → **Public Hostnames** — existe entrada para **cada** subdomínio a publicar |
| Origem | Origin URL apontando para o Envoy (`http://envoy-gateway.envoy-gateway-system.svc.cluster.local:80`) ou Service correto |
| CRM | Chart do CRM instalado e saudável se precisar dessa URL |

## Onde ler mais

- Fluxo completo Cloudflare: [`cloudflare-publicacao.md`](./cloudflare-publicacao.md)
- Terraform / ordem geral: [`infra-terraform.md`](./infra-terraform.md)
- CRM: [`app-crm.md`](./app-crm.md)
