# Pre-requisitos

## Ferramentas locais

- `terraform` >= 1.6
- `kubectl`
- `helm`
- `docker` (para build da aplicacao)
- `java 21` + `maven` (para build do CRM)

## Cluster Kubernetes

O cluster precisa estar funcional e acessivel via `~/.kube/config`.

Validacoes rapidas:

```bash
kubectl cluster-info
kubectl get nodes
helm version
terraform version
```

## DNS e dominio

- Um dominio/base DNS para o lab (ex.: `personaldevopstrainer.online`)
- Cloudflare Tunnel configurado (token pronto)
- Zona interna para BIND (ex.: `lab.local`), se for usar DNS interno de laboratorio

## Secrets que voce precisa preparar

- `bind_tsig_secret` (TSIG para RFC2136)
- `grafana_admin_password`
- `cloudflare_tunnel_token`
- `vaultwarden_admin_token`
- `wireguard_admin_password_hash` (bcrypt do WG-Easy)
