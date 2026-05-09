# Infra via Terraform

## Variáveis obrigatórias

Crie um arquivo local `infraestructure/environment/terraform.tfvars` (não versionar):

```hcl
cluster_domain              = "personaldevopstrainer.online"
acme_email                  = "EMAIL_PARA_ACME@personaldevopstrainer.online"

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

> Para hosts em `*.personaldevopstrainer.online`, use `bind_zone = "personaldevopstrainer.online"`.

## Aplicar

```bash
cd infraestructure/environment
terraform init
terraform plan
terraform apply
```

## Helm, imagens e rede (qualquer cluster)

Quem rodar este Terraform no próprio cluster passa pelos **mesmos requisitos** de rede e de ferramentas. O `plan`/`apply` precisam alcançar, via HTTPS, os repositórios Helm listados abaixo e, depois, os registros de imagem usados pelos charts (por exemplo **Docker Hub** para várias imagens, inclusive Keycloak `bitnamilegacy/*`). Firewall corporativo, proxy mal configurado ou CDN devolvendo **403** em algum índice causam falhas iguais para todos — não é algo específico da sua máquina.

| Origem | Uso no projeto |
|--------|----------------|
| `charts.bitnami.com` | Chart Keycloak (ou `.tgz` local via `keycloak_chart_archive_path`) |
| `kubernetes-sigs.github.io` | external-dns, Headlamp |
| `charts.external-secrets.io` | External Secrets Operator |
| `charts.jetstack.io` | cert-manager |
| `prometheus-community.github.io` | kube-prometheus-stack |
| `sonatype.github.io` | Nexus |
| `morgoved.github.io` | Wazuh (o índice em `packages.wazuh.com` costuma retornar **403**) |
| `oci://docker.io/envoyproxy` | Envoy Gateway — exige Helm com suporte a **OCI** |

**Mitigações já previstas no código/docs**

- Keycloak: chart opcional em arquivo local (`keycloak_chart_archive_path`) e imagens legacy documentadas em [`keycloak-troubleshooting.md`](keycloak-troubleshooting.md).
- Wazuh: repositório alternativo acessível (GitHub Pages), não o pacotes.wazuh.com.

**Checagem rápida antes do `terraform plan`**

```bash
./scripts/preflight-helm-repos.sh
```

Isso só valida os índices HTTP dos repos; **não** testa OCI do Envoy nem pull de imagem. Para OCI: `helm show chart oci://docker.io/envoyproxy/gateway-helm` (versão alinhada ao `infraestructure/modules/helm/envoy/main.tf`).

### Colocar todos os charts dentro do Git?

Em geral **não é o melhor padrão**: o pack `kube-prometheus-stack` sozinho é pesado; subir N versões `.tgz` no repositório dificulta clone/PR e ainda obriga a **atualizar blobs** a cada bump de versão no Terraform. **Pull de imagens** (Docker Hub, etc.) continuaria necessário de qualquer forma.

O meio-termo costuma ser:

- manter o **default** apontando para repositórios remotos;
- usar **chart local só onde quebra** (já existe para Keycloak via `keycloak_chart_archive_path`);
- em rede fechada, gerar um **cache local** (não commitado, pasta `.helm/cache/repository/`) com `./scripts/vendor-helm-charts.sh` — detalhes em [`infraestructure/helm-charts/README.md`](../infraestructure/helm-charts/README.md). Integrar o Terraform a *só* usar `.tgz` locais exigiria estender cada módulo `helm_release` (`repository = null` + caminho absoluto do arquivo); hoje o script serve para **arquivar/copiar** pacotes, não para trocar o apply automaticamente.

## Backend remoto (S3)

Para manter o state compartilhado e seguro, use backend S3 com lock nativo do próprio S3 (`use_lockfile = true`), sem depender de DynamoDB.

Pré-requisitos:

- Bucket S3 existente (ex.: `tfstate-local-cluster`)
- Credenciais AWS configuradas no ambiente (`aws configure`, profile ou variaveis `AWS_*`)
- Terraform `>= 1.10` (recomendado `>= 1.11`) para lock nativo S3

Inicialização/migração do state local para S3:

```bash
cd infraestructure/environment
terraform init -migrate-state \
  -backend-config="bucket=tfstate-local-cluster" \
  -backend-config="key=local-cluster/environment/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true"
```

Depois da migração, use normalmente:

```bash
terraform plan
terraform apply
```

Opcional (usar profile específico):

```bash
terraform init -reconfigure \
  -backend-config="bucket=tfstate-local-cluster" \
  -backend-config="key=local-cluster/environment/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="profile=default"
```

Permissões IAM mínimas para lock nativo S3 (arquivo `.tflock`):

- `s3:GetObject`
- `s3:PutObject`
- `s3:DeleteObject`

## Módulos implantados

- DNS/Certificados: `bind`, `cert-manager`, `external-dns`
- Edge/Publicação: `envoy`, `cloudflare-tunnel`
- Observabilidade: `monitoring`, `glowroot`
- Secrets: `external-secrets`, `vaultwarden`
- VPN: `wireguard-ui`
- Plataforma: `keycloak`, `nexus`, `registry`, `headlamp`, `wazuh`

## Verificação básica

```bash
kubectl get pods -A
kubectl get httproute -A
kubectl get dnsendpoint -A
```

## Troubleshooting: external-dns (RFC2136)

Se o `external-dns` entrar em `CrashLoopBackOff` com mensagens como:

- `dns: bad authentication`
- `not authoritative for update zone (NOTAUTH)`
- `bad return code: SERVFAIL`

valide os pontos abaixo:

1. O `bind_zone` deve ser o mesmo domínio dos registros criados (ex.: `personaldevopstrainer.online`).
2. O `bind_tsig_secret` deve ser identico no BIND e no external-dns.
3. A release deve estar usando zona RFC2136 sem fallback para `.` (root).
4. O BIND precisa de zona em volume gravável para updates dinâmicos (`.jnl`).

Comandos úteis:

```bash
kubectl logs -n external-dns deploy/external-dns --tail=120
kubectl logs -n bind deploy/bind9 --tail=200
```

Reaplique somente o necessário:

```bash
cd infraestructure/environment
terraform apply -target=module.helm.module.bind -target=module.helm.module.external_dns
kubectl rollout restart deploy/bind9 -n bind
kubectl rollout restart deploy/external-dns -n external-dns
```

## Troubleshooting: apply unico (one-shot)

### PVC preso em `WaitForFirstConsumer`

Sintoma durante `terraform apply`:

- PVCs em `Still creating...` por muito tempo
- `kubectl describe pvc` com evento: `waiting for first consumer to be created before binding`

Causa:

- A StorageClass (`standard`) usa `VolumeBindingMode: WaitForFirstConsumer`
- Se o provider Terraform esperar `Bound` no PVC, o apply pode entrar em deadlock antes de criar o Deployment consumidor.

Correção adotada nos módulos (`registry`, `vaultwarden`, `wireguard-ui`):

```hcl
wait_until_bound = false
```

Validação:

```bash
kubectl get sc
kubectl describe sc standard
kubectl get pvc -A
kubectl get deploy -A
```

### Erro `already exists` (recurso existe no cluster e não no state)

Sintoma:

- `namespaces "nexus" already exists`
- `persistentvolumeclaims "...-data" already exists`

Causa:

- Recurso foi criado anteriormente no cluster, mas não está no `terraform.tfstate` atual.

Correção:

```bash
cd infraestructure/environment
terraform import module.helm.module.nexus.kubernetes_namespace.nexus nexus
terraform import module.helm.module.registry.kubernetes_persistent_volume_claim.registry registry/registry-data
terraform import module.helm.module.vaultwarden.kubernetes_persistent_volume_claim.vaultwarden_data vaultwarden/vaultwarden-data
terraform import module.helm.module.wireguard_ui.kubernetes_persistent_volume_claim.wireguard_data wireguard/wireguard-data
terraform apply
```

### Keycloak (Bitnami)

Erros específicos do Keycloak (Helm, imagens, `KC_CACHE`, HTTPS, Quarkus `EOFException`, `ErrImagePull`, state/import) estão documentados em [`docs/keycloak-troubleshooting.md`](keycloak-troubleshooting.md).
