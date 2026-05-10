# Infra via Terraform

O stack **`infraestructure/environment`** está preparado por padrão para **cluster local** (Kind ou outro): credenciais via **`kubeconfig_path`** / **`kube_context`** em `terraform.tfvars`, e estado Terraform **local** (`backend.tf`). Copie `infraestructure/environment/terraform.tfvars.example` para `terraform.tfvars` (não versionado) e preencha domínios, senhas e tokens.

Para usar **Oracle (OKE, backend Object Storage, remote state do cluster)** no stack `environment`, o código precisa de ser alinhado com essa variante; segue o guia passo a passo em **[`environment-oracle.md`](environment-oracle.md)**.

## Variáveis obrigatórias (modo Kind / kubeconfig local)

Exemplo mínimo em `infraestructure/environment/terraform.tfvars`:

```hcl
kubeconfig_path = "~/.kube/config"
kube_context      = "kind-kind"

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

Para hosts em `*.personaldevopstrainer.online`, use `bind_zone = "personaldevopstrainer.online"`.

## Aplicar (environment em modo local)

```bash
cd infraestructure/environment
terraform init
terraform plan
terraform apply
```

Stacks **`bootstrap`** e **`cluster`** com backend remoto OCI continuam a usar init com partial config, por exemplo:

`terraform init -backend-config=../backend-bootstrap.hcl` ou `terraform init -backend-config=../backend-cluster.hcl`.

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

## Backend remoto (OCI Object Storage)

Os stacks usam backend **`oci`** (Terraform **>= 1.12**); credenciais API típicas via arquivo HCL gitignored — veja a seção "Aplicar". Migração de state:

```bash
cd infraestructure/cluster
terraform init -backend-config=../backend-cluster.hcl -migrate-state
```

Se você já tem backend remoto e só mudou região ou credenciais:

```bash
terraform init -backend-config=../backend-cluster.hcl -reconfigure
```

Políticas IAM na OCI: permissões de objeto no bucket de state (`OBJECT_READ`, `OBJECT_CREATE`, `OBJECT_DELETE`, `OBJECT_INSPECT`, etc.), conforme a documentação do backend `oci`.

## Módulos implantados

- DNS/Certificados: `bind`, `cert-manager`, `external-dns`
- Edge/Publicação: `envoy`, `cloudflare-tunnel`
- Observabilidade: `monitoring`, `glowroot`
- Secrets: `external-secrets`, `vaultwarden`
- Correio (Postfix + SMTP Vaultwarden): [`postfix-mail-vaultwarden.md`](./postfix-mail-vaultwarden.md)
- VPN: `wireguard-ui`
- Plataforma: `keycloak`, `nexus`, `registry`, `headlamp` (OIDC via chart; ver [`headlamp-oauth.md`](./headlamp-oauth.md)), `wazuh`

## Verificação básica

```bash
kubectl get pods -A
kubectl get httproute -A
kubectl get dnsendpoint -A
```

Se URLs públicas falharem apesar dos pods ok, use **[`debug-acesso-publico.md`](./debug-acesso-publico.md)** (tunnel Cloudflare, Envoy, portas corretas).

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
