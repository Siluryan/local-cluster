# Local Cluster Lab

Ambiente de laboratório Kubernetes para uso pessoal, com serviços de plataforma, identidade, observabilidade e uma aplicação Java de exemplo.

## O que já está no lab

- entrada HTTP com Envoy e publicação por Cloudflare Tunnel
- DNS dinâmico com ExternalDNS + `DNSEndpoint`
- certificados com cert-manager
- Keycloak, Vaultwarden e External Secrets Operator
- Grafana/Prometheus, Nexus e registry de imagens
- CRM Java com Helm chart

## Estrutura do repositório

- `infraestructure/`: Terraform dos módulos do cluster
- `app/`: aplicação CRM e chart Helm
- `docs/`: guias de setup e operação

## Primeiros passos

```bash
cd infraestructure/environment
terraform init
terraform plan
terraform apply
```

Depois de aplicar a infraestrutura, siga os guias em `docs/`.

## URLs principais

- `https://crm.personaldevopstrainer.online` - aplicação CRM
- `https://keycloak.personaldevopstrainer.online` - autenticação e usuários
- `https://grafana.personaldevopstrainer.online` - dashboards e métricas
- `https://prometheus.personaldevopstrainer.online` - consultas de métricas
- `https://wazuh.personaldevopstrainer.online` - segurança (SIEM/XDR)
- `https://headlamp.personaldevopstrainer.online` - painel de administração do cluster
- `https://nexus.personaldevopstrainer.online` - repositório Maven
- `https://registry.personaldevopstrainer.online` - registry de imagens Docker
- `https://vaultwarden.personaldevopstrainer.online` - cofre de segredos/senhas
- `https://vpn.personaldevopstrainer.online` - interface do WireGuard (WG-Easy)
