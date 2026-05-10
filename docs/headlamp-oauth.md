# Headlamp com OIDC (Keycloak)

Autenticação atual: **OIDC nativo do chart Headlamp** (`config.oidc` em `helm_release`), sem oauth2-proxy à frente do serviço. O login usa o fluxo do próprio Headlamp; o callback público é **`https://headlamp.<domínio>/oidc-callback`**.

## Comportamento no Terraform

- Chart **Headlamp** `0.27.0`, namespace `headlamp`.
- `config.oidc`: `issuerURL` = `https://keycloak.<cluster_domain>/realms/<realm>`, `clientID`, `clientSecret`, secret Kubernetes `oidc` criado pelo chart; **`scopes`** fixos no código: `openid profile email`.
- **HTTPRoute** do Envoy com backend **Service `headlamp`**, porta **80**.

Ficheiro: `infraestructure/modules/helm/headlamp/main.tf`.

## Variáveis em `terraform.tfvars`

Exemplo: `infraestructure/environment/terraform.tfvars.example`.

| Variável | Função |
|----------|--------|
| `headlamp_oauth_client_id` | Client ID no Keycloak (igual ao *Client ID* do client). |
| `headlamp_oauth_client_secret` | Client secret (client confidencial). |
| `headlamp_oauth_keycloak_realm` | Realm no issuer (valor por defeito no Terraform: `master`). |

Issuer efetivo:

`https://keycloak.<cluster_domain>/realms/<headlamp_oauth_keycloak_realm>`

## Keycloak

No client OIDC correspondente:

- **Valid redirect URIs**: incluir `https://headlamp.<domínio>/oidc-callback` (podes manter outras URIs no mesmo client).
- **Client authentication**: ligado (client confidencial), para existir **Client secret**.
- **Web origins** (se o Keycloak pedir para CORS): `https://headlamp.<domínio>` ou `+` conforme a tua política.

Os nomes das variáveis Terraform mantêm o prefixo `headlamp_oauth_*` por compatibilidade; o fluxo exposto ao utilizador é OIDC no Headlamp, não oauth2-proxy.

## Aplicar

```bash
cd infraestructure/environment
terraform apply
```

Depois de aplicar, convém limpar cookies do hostname `headlamp.<domínio>` se testares login outra vez.

### Migração antiga (oauth2-proxy)

Se ainda existir um release Helm `headlamp-oauth`, remove-o após o apply (`helm uninstall headlamp-oauth -n headlamp`). O redirect `/oauth2/callback` do proxy é opcional no Keycloak; o Headlamp precisa do **`/oidc-callback`**.

## JWT e kube-apiserver

Login no Headlamp não garante que o **kube-apiserver** aceite o mesmo JWT; isso depende de OIDC/RBAC no cluster. Ver [autenticação OIDC na Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens).

## Ligações úteis

- Headlamp OIDC: [Accessing using OpenID Connect](https://www.headlamp.dev/docs/latest/installation/in-cluster/oidc)
- Keycloak no lab: [`keycloak.md`](./keycloak.md)
- URLs públicas: [`acesso-urls-publicas.md`](./acesso-urls-publicas.md)
