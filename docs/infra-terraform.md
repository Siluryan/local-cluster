# Infra via Terraform

## Variaveis obrigatorias

Crie um arquivo local `infraestructure/environment/terraform.tfvars` (não versionar):

```hcl
cluster_domain              = "personaldevopstrainer.online"
acme_email                  = "voce@personaldevopstrainer.online"

bind_zone                   = "lab.local"
bind_tsig_key_name          = "externaldns-key"
bind_tsig_secret            = "BASE64_TSIG_SECRET"
bind_tsig_algorithm         = "hmac-sha256"

grafana_admin_password        = "SENHA_FORTE"
cloudflare_tunnel_token       = "TOKEN_DO_TUNNEL"
vaultwarden_admin_token       = "TOKEN_ADMIN_VAULTWARDEN"
wireguard_admin_password_hash = "$2b$12$..."
wireguard_public_host         = "vpn.personaldevopstrainer.online"
```

## Aplicar

```bash
cd infraestructure/environment
terraform init
terraform plan
terraform apply
```

## Modulos implantados

- DNS/Certificados: `bind`, `cert-manager`, `external-dns`
- Edge/Publicacao: `envoy`, `cloudflare-tunnel`
- Observabilidade: `monitoring`, `glowroot`
- Secrets: `external-secrets`, `vaultwarden`
- VPN: `wireguard-ui`
- Plataforma: `keycloak`, `nexus`, `registry`, `headlamp`

## Verificacao basica

```bash
kubectl get pods -A
kubectl get httproute -A
kubectl get dnsendpoint -A
```
