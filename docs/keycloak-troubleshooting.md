# Keycloak (Bitnami): erros e correções

Este doc reúne os problemas encontrados ao implantar o Keycloak via Helm chart Bitnami (`keycloak` **24.7.4**) no módulo Terraform `infraestructure/modules/helm/keycloak`.

Stack de referência:

- Chart: `bitnami/keycloak` **24.7.4**
- Imagem Keycloak alinhada ao chart: tag **`26.2.5-debian-12-r3`** (repositório `bitnamilegacy/keycloak` quando `docker.io/bitnami/*` falha no pull)
- Postgres embutido do chart: `bitnamilegacy/postgresql` com `global.security.allowInsecureImages`

---

## 1. Helm: imagens não reconhecidas (`bitnamilegacy/*`)

**Sintoma no `terraform apply` / `helm upgrade`:**

- `ERROR: Original containers have been substituted for unrecognized ones`
- Menção a `bitnamilegacy/postgresql` ou Keycloak legacy

**Causa:** validação do chart Bitnami que bloqueia imagens fora da lista padrão.

**Correção no values:**

```hcl
global = {
  security = {
    allowInsecureImages = true
  }
}
```

---

## 2. Upgrade falha: `.Values.cache.enabled` / tipo errado em `cache`

**Sintoma:**

- `can't evaluate field enabled in type interface {}`
- Template em `configmap-env-vars.yaml` ao usar `cache` como string

**Causa:** no chart, `cache` é um **objeto** (`cache.enabled`, `cache.stack`, ...), não uma string como `"local"`.

**Correção:** usar bloco, por exemplo cache distribuído desligado para réplica única:

```hcl
cache = {
  enabled = false
}
```

Combinar com `KC_CACHE=local` em `extraEnvVars` quando fizer sentido para um único pod.

---

## 3. Runtime: `Invalid value for option 'KC_CACHE'`

**Sintoma nos logs do container:**

- `Invalid value for option 'KC_CACHE': . Expected values are: ispn, local`

**Causa:** variável `KC_CACHE` vazia ou inconsistente com o modo de cache configurado no chart.

**Correção:** definir explicitamente em `extraEnvVars`:

```hcl
{
  name  = "KC_CACHE"
  value = "local"
}
```

E manter o bloco `cache` do chart coerente (ver seção 2).

---

## 4. Runtime: HTTPS sem material de certificado

**Sintoma nos logs:**

- `Key material not provided to setup HTTPS`
- Às vezes `CrashLoopBackOff`

**Causa:** modo que exige TLS no Keycloak sem certificados configurados no chart; terminação TLS costuma ser no Envoy/gateway.

**Correção:** habilitar HTTP na aplicação (terminação TLS na borda):

```hcl
{
  name  = "KC_HTTP_ENABLED"
  value = "true"
}
```

Ajustar `production` conforme o chart (em ambiente de lab costuma ser `false` com proxy `edge`).

---

## 5. Runtime: `java.io.EOFException` em `SerializedApplication.read` / Quarkus

**Sintoma:**

- Stack trace em `io.quarkus.bootstrap.runner.SerializedApplication.read`
- `Caused by: java.io.EOFException`

**Causas comuns:**

- **Tag de imagem** muito diferente da testada pelo chart (ex.: Keycloak `26.3.x` com chart pensado para `26.2.5`)
- **Memória insuficiente** durante o build/bootstrap no `emptyDir`
- Arquivos truncados após falha de escrita/OOM

**Correções adotadas:**

- Alinhar imagem à tag **padrão do chart** (`helm show values` no mesmo `version` do chart)
- Definir `resources` com limites de memória adequados (ex.: request ~1Gi, limit ~2Gi conforme o cluster)
- Preferir `production = false` em lab até TLS e recursos estarem definidos de forma explícita

---

## 6. Pod: `Init:ErrImagePull` / `ErrImagePull`

**Sintoma:**

- `kubectl get pods -n keycloak` com `Init:ErrImagePull` ou `ImagePullBackOff`
- Eventos com `Failed to pull image`, `429`, `pull access denied`, `not found`

**Causas comuns:**

- Rate limit do Docker Hub em pulls anônimos
- Tag inexistente no repositório (`bitnami/*` vs `bitnamilegacy/*`)
- Rede do cluster sem acesso ao registry

**Correções:**

- Usar a **mesma tag** que o chart declara, trocando apenas o repositório para `bitnamilegacy/keycloak` se `bitnami/keycloak` falhar
- Manter `global.security.allowInsecureImages = true` quando usar legacy
- Validar com `kubectl describe pod keycloak-0 -n keycloak` (seção Events)

---

## 7. Terraform / Helm: `cannot re-use a name that is still in use`

**Sintoma:** erro no `helm_release.keycloak` ao aplicar.

**Causa:** release Helm `keycloak` já existe no namespace, mas **não está** no state Terraform atual.

**Correção:**

```bash
terraform import module.helm.module.keycloak.helm_release.keycloak keycloak/keycloak
```

Formato: `namespace/release_name`.

---

## 8. Terraform: plano quer **criar tudo de novo** (dezenas de `add`)

**Sintoma:** `Plan: N to add, 0 to change, 0 to destroy` com N grande, embora o cluster já tenha recursos.

**Causas:**

- **Objeto S3 errado:** `-backend-config key=` aponta para outro arquivo de state (state vazio ou antigo)
- **Workspace** Terraform diferente
- State local vs remoto sem migração correta

**Correção:** garantir o mesmo `bucket` + `key` + `region` sempre; conferir no console S3 qual objeto contém o state real; usar `terraform workspace show` e `terraform state list`.

**Não confirme** um `apply` às cegas se o cluster já está provisionado e o plano mostra apenas creates — risco de conflito com recursos existentes.

---

## 9. CLI Terraform: `Backend initialization required` ao alternar comandos

**Sintoma:** `terraform state list` funciona com um binário e `terraform apply` falha pedindo `init` de novo.

**Causa:** uso de **dois executáveis** diferentes (ex.: `terraform1152` vs `terraform`), cada um com metadata em `.terraform/` inconsistente.

**Correção:** usar **sempre o mesmo binário** para `init`, `plan`, `apply`, `state`.

---

## 10. `terraform init`: `-migrate-state` e `-reconfigure` juntos

**Sintoma:**

- `The -migrate-state and -reconfigure options are mutually-exclusive`

**Correção:**

- Primeira subida do state local para S3: `terraform init -migrate-state ...`
- Backend já remoto e só mudou a configuração: `terraform init -reconfigure ...`

---

## Comandos úteis

```bash
kubectl get pods -n keycloak
kubectl logs keycloak-0 -n keycloak --tail=120
kubectl describe pod keycloak-0 -n keycloak
kubectl get cm keycloak-env-vars -n keycloak -o yaml
helm list -n keycloak
helm get values keycloak -n keycloak
```

Para inspecionar valores padrão do chart:

```bash
helm show values --repo https://charts.bitnami.com/bitnami keycloak --version 24.7.4
```
