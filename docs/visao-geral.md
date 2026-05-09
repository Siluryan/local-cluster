# Visão Geral

Este repositório provisiona um cluster pessoal com:

- exposição de apps via Envoy Gateway
- DNS dinâmico com ExternalDNS + `DNSEndpoint`
- certificados com cert-manager
- observabilidade com Prometheus/Grafana
- gestão de segredos com ESO + Vaultwarden
- acesso remoto com WireGuard (WG-Easy)
- publicação HTTP com Cloudflare Tunnel

## Estrutura do repositório

- `infraestructure/environment`: raiz Terraform para aplicar tudo
- `infraestructure/modules/helm`: módulos de cada componente do cluster
- `app`: aplicação CRM (Java + Postgres + Helm chart)
- `docs`: guias de uso do lab

## Componentes principais

- `bind`: DNS autoritativo interno para o lab
- `cert-manager`: emissão de certificado ACME via RFC2136 (BIND)
- `external-dns`: cria/atualiza registros DNS automaticamente
- `envoy`: gateway de entrada HTTP
- `monitoring`: kube-prometheus-stack
- `cloudflare-tunnel`: publica HTTP sem NAT
- `external-secrets`: sincronização de segredos
- `vaultwarden`: cofre com interface web
- `wireguard-ui`: VPN WireGuard com painel web
- `headlamp`: painel web de administração do cluster
- `wazuh`: SIEM/XDR para monitoramento de segurança
