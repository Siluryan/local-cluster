# Headlamp com OIDC (Keycloak)

Autenticação atual: **OIDC nativo do chart Headlamp** (`config.oidc` em `helm_release`), sem oauth2-proxy à frente do serviço. O login usa o fluxo do próprio Headlamp; o callback público é **`https://headlamp.<domínio>/oidc-callback`**.

## Comportamento no Terraform

- Chart **Headlamp** `0.27.0`, namespace `headlamp`.
- `config.oidc`: `issuerURL` = `https://keycloak.<cluster_domain>/realms/<realm>`, `clientID`, `clientSecret`, secret Kubernetes `oidc` criado pelo chart; **`scopes`** fixos no código: `openid profile email`.
- **HTTPRoute** do Envoy com backend **Service `headlamp`**, porta **80**.
- **`clusterRoleBinding`** para o ServiceAccount do Headlamp com papel **`cluster-admin`** (credenciais do próprio pod); não confere, por si só, permissões ao **usuário** OIDC nas chamadas ao apiserver.

Arquivo: `infraestructure/modules/helm/headlamp/main.tf`.

## Variáveis em `terraform.tfvars`

Exemplo: `infraestructure/environment/terraform.tfvars.example`.

| Variável | Função |
|----------|--------|
| `headlamp_oauth_client_id` | Client ID no Keycloak (igual ao *Client ID* do client). |
| `headlamp_oauth_client_secret` | Client secret (client confidencial). |
| `headlamp_oauth_keycloak_realm` | Realm no issuer (valor padrão no Terraform: `master`). |

Issuer efetivo:

`https://keycloak.<cluster_domain>/realms/<headlamp_oauth_keycloak_realm>`

## Keycloak

No client OIDC correspondente:

- **Valid redirect URIs**: incluir `https://headlamp.<domínio>/oidc-callback` (você pode manter outras URIs no mesmo client).
- **Client authentication**: ligado (client confidencial), para existir **Client secret**.
- **Web origins** (se o Keycloak pedir para CORS): `https://headlamp.<domínio>` ou `+` conforme sua política.

Os nomes das variáveis Terraform mantêm o prefixo `headlamp_oauth_*` por compatibilidade; o fluxo exposto ao usuário é OIDC no Headlamp, não oauth2-proxy.

### RBAC por grupo no Kubernetes

Se usar **Kind** e quiser permissões por **grupo** (em vez de utilizador), o apiserver precisa de `oidc-groups-claim` e o Keycloak de emitir o claim de grupos no **access token** (mapper *Group membership*, grupos no realm, etc.). Guia completo passo a passo: [`kind-oidc-apiserver.md`](./kind-oidc-apiserver.md) (secções *Passo 1*, *4.2* e *Passo 5 — Keycloak: grupos no JWT*).

Se o realm só emitir grupos com um **scope** OAuth extra, pode ser necessário alargar `config.oidc.scopes` no módulo Helm do Headlamp (hoje: `openid profile email`).

## Aplicar

```bash
cd infraestructure/environment
terraform apply
```

Depois de aplicar, convém limpar cookies do hostname `headlamp.<domínio>` se testar o login de novo.

### Migração antiga (oauth2-proxy)

Se ainda existir um release Helm `headlamp-oauth`, remova-o após o apply (`helm uninstall headlamp-oauth -n headlamp`). O redirect `/oauth2/callback` do proxy é opcional no Keycloak; o Headlamp precisa do **`/oidc-callback`**.

## Dashboard vazio ou “sem permissão” depois do login OIDC

Com OIDC ligado, o Headlamp envia o **JWT do Keycloak** ao **kube-apiserver**. Se o servidor de API **não** estiver configurado para confiar nesse issuer/cliente, o usuário é tratado como **`system:anonymous`** (ou equivalente sem RBAC) e **não aparecem Pods, Nodes, etc.** Isso é independente do `ClusterRoleBinding` do **ServiceAccount** do Headlamp (que só cobre o modo “in-cluster” sem identidade OIDC reconhecida pelo apiserver).

O que costuma faltar:

1. **Flags OIDC no kube-apiserver** alinhadas ao `iss` do token e ao client/audience esperado.
2. **RBAC**: `ClusterRoleBinding` para o **User** ou **Group** que o apiserver extrai do JWT (não basta o binding do ServiceAccount do pod Headlamp).

Em clusters **Kind**, o passo a passo completo (ficheiro `kind-cluster.yaml`, recriar cluster, verificação, RBAC por utilizador ou por grupo, Keycloak com grupos no JWT, reinstalar workloads) está em **[`kind-oidc-apiserver.md`](./kind-oidc-apiserver.md)**.

Documentação geral: [OpenID Connect Tokens](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens).

Referência Headlamp: [issue #4618](https://github.com/kubernetes-sigs/headlamp/issues/4618).

## Links úteis

- Headlamp OIDC: [Accessing using OpenID Connect](https://www.headlamp.dev/docs/latest/installation/in-cluster/oidc)
- Keycloak no lab: [`keycloak.md`](./keycloak.md)
- Kind + apiserver OIDC + RBAC + Keycloak (guia longo): [`kind-oidc-apiserver.md`](./kind-oidc-apiserver.md)
- URLs públicas: [`acesso-urls-publicas.md`](./acesso-urls-publicas.md)
