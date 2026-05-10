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

Resumo do que falta normalmente:

1. **Flags OIDC no kube-apiserver** (`oidc-issuer-url`, `oidc-client-id`, e opcionalmente `oidc-username-claim`, `oidc-groups-claim`), alinhadas ao **`iss`** do token do Keycloak e ao **audience** esperado. Documentação: [OpenID Connect Tokens](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens).
2. **RBAC**: pelo menos um `ClusterRoleBinding` que associe o **usuário** ou **grupo** OIDC (como o apiserver os expõe após validar o token) a um `ClusterRole` (por exemplo `cluster-admin` para laboratório).

Em clusters **Kind**, costuma-se injetar isso via `kubeadmConfigPatches` no arquivo do cluster (recriar o cluster depois de alterar). Exemplo mínimo (substitua issuer e client-id pelos seus; o issuer deve coincidir com o URL do realm no Keycloak):

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: ClusterConfiguration
        apiServer:
          extraArgs:
            oidc-issuer-url: "https://keycloak.EXEMPLO/realms/master"
            oidc-client-id: "o-seu-client-id-do-keycloak"
            oidc-username-claim: "preferred_username"
```

Para permissões por **grupo**, o token tem de trazer o claim de grupos e o apiserver precisa de `oidc-groups-claim`; no Keycloak é comum acrescentar o scope/mapper `groups` e alargar os scopes do Headlamp no Terraform se você for por esse caminho.

Referência Headlamp sobre o mesmo tema: [issue #4618](https://github.com/kubernetes-sigs/headlamp/issues/4618).

Guia passo a passo para **Kind** (arquivo de cluster, recriar cluster, verificar): [`kind-oidc-apiserver.md`](./kind-oidc-apiserver.md).

## Links úteis

- Headlamp OIDC: [Accessing using OpenID Connect](https://www.headlamp.dev/docs/latest/installation/in-cluster/oidc)
- Keycloak no lab: [`keycloak.md`](./keycloak.md)
- URLs públicas: [`acesso-urls-publicas.md`](./acesso-urls-publicas.md)
