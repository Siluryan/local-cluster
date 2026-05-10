# Kind: OIDC no kube-apiserver (Keycloak + Headlamp)

Para o Headlamp mostrar recursos com login OIDC, o **kube-apiserver** tem de validar o mesmo JWT que o Keycloak emite. No **Kind** isso faz-se com **`kubeadmConfigPatches`** no manifest do cluster, injetando `extraArgs` OIDC no plano de controlo.

Depois disso, é preciso **RBAC** (utilizador ou grupo) e, para grupos, o Keycloak tem de colocar **grupos no token**.

---

## Visão geral dos passos

1. Ajustar **`kind-cluster.yaml`** com `oidc-issuer-url`, `oidc-client-id` e claims (`oidc-username-claim`; opcionalmente `oidc-groups-claim`).
2. **Recriar** o cluster Kind (alterações no apiserver não são aplicáveis “em calor” de forma suportada).
3. **Verificar** se o apiserver arrancou com as flags OIDC.
4. Configurar o **Keycloak** (redirects do client; se for RBAC por **grupo**, mapper de grupos no JWT — ver secção dedicada).
5. Aplicar **ClusterRoleBinding** para o utilizador (`User`) ou grupo (`Group`) que o Kubernetes extrai do token.
6. **Voltar a instalar** o que dependia do cluster (Terraform Helm, manifests), porque um cluster novo começa vazio.

Guia relacionado: comportamento do Headlamp e Terraform — [`headlamp-oauth.md`](./headlamp-oauth.md).

---

## Antes de aplicar

- **`oidc-issuer-url`** tem de ser **igual** ao claim `iss` dos tokens do realm (normalmente `https://keycloak.<domínio>/realms/<realm>`).
- **`oidc-client-id`** tem de ser aceite pelo apiserver em relação ao token (muitas vezes alinhado ao campo **`aud`** no Keycloak; pode ser preciso client ou mapper de audience). Documentação: [OpenID Connect Tokens](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens).
- O **kube-apiserver** (dentro do nó Kind) tem de conseguir **HTTPS** ao URL do Keycloak para obter as chaves JWKS (DNS e certificado TLS válidos costumam funcionar se o Keycloak for público).
- Alterar estes `extraArgs` **obriga a recriar** o cluster Kind.

---

## Passo 1 — Arquivo de cluster Kind (`kind-cluster.yaml`)

Guarde por exemplo `kind-cluster.yaml`. Substitua domínio, nome do cluster, realm e **client-id** pelos seus (o `oidc-client-id` deve ser o mesmo **Client ID** que usa no Headlamp / `headlamp_oauth_client_id` no Terraform).

### Variante mínima (RBAC só por utilizador)

Omite `oidc-groups-claim` se não for usar grupos no token.

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: local-cluster
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: ClusterConfiguration
        apiVersion: kubeadm.k8s.io/v1beta3
        apiServer:
          extraArgs:
            oidc-issuer-url: "https://keycloak.SEU_DOMINIO/realms/master"
            oidc-client-id: "SEU_CLIENT_ID_KEYCLOAK"
            oidc-username-claim: "preferred_username"
  - role: worker
```

### Variante com RBAC por grupo

Acrescente `oidc-groups-claim` com o **nome do claim JSON** onde vêm os grupos (ex.: `groups`). Tem de coincidir com o **Token Claim Name** no mapper do Keycloak (ver [Passo 5 — Keycloak: grupos no JWT](#passo-5--keycloak-grupos-no-jwt)).

Opcional: `oidc-groups-prefix` — consulte a [documentação Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens) se precisar de prefixar nomes de grupo.

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: local-cluster
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: ClusterConfiguration
        apiVersion: kubeadm.k8s.io/v1beta3
        apiServer:
          extraArgs:
            oidc-issuer-url: "https://keycloak.SEU_DOMINIO/realms/master"
            oidc-client-id: "SEU_CLIENT_ID_KEYCLOAK"
            oidc-username-claim: "preferred_username"
            oidc-groups-claim: "groups"
  - role: worker
```

---

## Passo 2 — Recriar o cluster

```bash
kind delete cluster --name local-cluster
kind create cluster --name local-cluster --config kind-cluster.yaml
kubectl config current-context
```

O contexto costuma ser `kind-local-cluster` (depende do nome do cluster no manifest).

---

## Passo 3 — Verificar argumentos OIDC no apiserver

```bash
docker exec -it local-cluster-control-plane kubectl -n kube-system get pod -l component=kube-apiserver -o jsonpath='{.items[0].spec.containers[0].command}' | tr ' ' '\n' | grep oidc
```

Substitua `local-cluster-control-plane` se o nome do container Docker do plano de controlo for outro.

---

## Passo 4 — RBAC no Kubernetes (depois do apiserver aceitar o token)

O `ClusterRoleBinding` do Helm do Headlamp no **ServiceAccount** do pod **não** concede permissões ao seu utilizador OIDC no browser. É preciso ligar o **User** ou **Group** que o apiserver deriva do JWT a um `ClusterRole` (em laboratório, `cluster-admin`).

### 4.1 Por utilizador (`preferred_username`)

O nome no Kubernetes é o valor do claim configurado em `oidc-username-claim` (ex.: `preferred_username`).

```bash
kubectl create clusterrolebinding keycloak-user-admin \
  --clusterrole=cluster-admin \
  --user=SEU_LOGIN_NO_KEYCLOAK
```

Equivalente em YAML:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: keycloak-user-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: SEU_LOGIN_NO_KEYCLOAK
```

### 4.2 Por grupo

O token tem de conter um claim (por exemplo `groups`) com uma **lista de strings**. O nome em `subjects` tem de ser **exactamente** um dos valores dessa lista (respeitando maiúsculas e *paths* se usou “Full group path” no Keycloak).

```bash
kubectl create clusterrolebinding keycloak-group-admin \
  --clusterrole=cluster-admin \
  --group=NOME_DO_GRUPO_NO_TOKEN
```

Exemplo YAML com um grupo:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: keycloak-group-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: Group
    name: k8s-admins
```

---

## Passo 5 — Keycloak: grupos no JWT

Esta secção é necessária se configurou **`oidc-groups-claim`** no Kind e RBAC por **Group**. O Kubernetes espera um claim (ex.: `groups`) cujo valor seja uma **lista JSON de strings**, tipicamente no **access token**.

### 5.1 Grupos e utilizadores no realm

1. **Realm** → **Groups** → **Create group** (ex.: `k8s-admins`).
2. **Users** → utilizador → **Groups** → **Join group** e associe ao grupo.

### 5.2 Mapper “Group Membership” no client do Headlamp

Use o **mesmo client** cujo Client ID está em `oidc-client-id` / Headlamp.

1. **Clients** → client OIDC do Headlamp.
2. Consoante a versão do Keycloak:
   - **Client scopes** → scope **dedicated** do client → **Add mapper** → **By configuration** → **Group membership**, ou
   - **Mappers** no client → **Create** → **Group membership**.

Sugestão de campos:

| Campo | Valor sugerido |
|--------|----------------|
| **Token Claim Name** | `groups` — deve coincidir com `oidc-groups-claim` no Kind |
| **Full group path** | **Off** para nomes simples (`k8s-admins`); **On** se quiser caminhos hierárquicos |
| **Add to access token** | **On** (o apiserver usa em geral o bearer token de acesso) |
| **Add to ID token** | On (útil para depuração) |

### 5.3 Confirmar o token

No client → **Client scopes** → **Evaluate** (ou ferramenta equivalente na sua versão), gere o preview com um utilizador que pertença ao grupo. No **access token** (pode decodificar em [jwt.io](https://jwt.io)), verifique algo como:

```json
"groups": ["k8s-admins"]
```

Se o claim tiver outro nome, altere o **Token Claim Name** no mapper **ou** `oidc-groups-claim` no Kind — têm de ser consistentes.

### 5.4 Problemas frequentes (grupos)

- **Grupos só no ID token**: ligue **Add to access token** no mapper.
- **Nome do grupo no RBAC ≠ token**: o `ClusterRoleBinding` `subjects[].name` tem de ser igual ao string no array `groups`.
- **Formato errado**: o claim deve ser lista de strings; um único string pode não funcionar como esperado para `Group`.
- **Scope `groups`**: em alguns realms é preciso associar um client scope **groups** ao client como **Default**. Se os grupos não aparecerem, avalie o token outra vez depois de adicionar o scope.
- **Audience (`aud`)**: independente dos grupos; alinhe client-id entre Kind, Keycloak e Headlamp se o login ou a API falharem antes do RBAC.

### 5.5 Headlamp: scopes OAuth

No repositório, os scopes do chart estão fixos em `openid profile email` (`infraestructure/modules/helm/headlamp/main.tf`). Se o realm **exigir** um scope explícito para emitir grupos, alargue `config.oidc.scopes` nesse módulo e faça `terraform apply`.

---

## Passo 6 — Reinstalar aplicações no cluster novo

Um cluster Kind recriado **não** contém releases anteriores. Volte a aplicar o ambiente (por exemplo `terraform apply` em `infraestructure/environment`) ou os manifests que usar para Envoy, Headlamp, Keycloak (se correr no mesmo Kind), etc.

---

## Resolução de problemas (geral)

| Sintoma | O que verificar |
|--------|-------------------|
| Dashboard Headlamp vazio / “sem permissão” | Apiserver sem OIDC alinhado ao Keycloak; ou falta `ClusterRoleBinding` para User/Group; ver [`headlamp-oauth.md`](./headlamp-oauth.md). |
| JWKS / rede | O apiserver dentro do Docker Kind tem de resolver e confiar no TLS do Keycloak. |
| Grupos não aplicados | Claim no access token; nome exacto no binding; `oidc-groups-claim` igual ao nome do claim. |

Referência Headlamp: [issue #4618](https://github.com/kubernetes-sigs/headlamp/issues/4618).

---

## Links

- Headlamp + OIDC (Terraform, redirects, dashboard vazio): [`headlamp-oauth.md`](./headlamp-oauth.md)
- Cluster Kind: [kind.sigs.k8s.io](https://kind.sigs.k8s.io/docs/user/configuration/)
- Autenticação OIDC no Kubernetes: [OpenID Connect Tokens](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens)
