# Kind: OIDC no kube-apiserver (Keycloak + Headlamp)

Para o Headlamp mostrar recursos com login OIDC, o **kube-apiserver** tem de validar o mesmo JWT que o Keycloak emite. No **Kind** isso faz-se com **`kubeadmConfigPatches`** no manifest do cluster, injetando `extraArgs` OIDC no plano de controlo.

## Antes de aplicar

- O valor de **`oidc-issuer-url`** tem de ser **igual** ao claim `iss` dos tokens do realm (normalmente `https://keycloak.<domínio>/realms/<realm>`).
- O **`oidc-client-id`** tem de ser compatível com o que o apiserver espera no token (muitas vezes o campo `aud` no Keycloak — pode ser preciso um client dedicado ou *mapper* de audience; veja a [documentação Kubernetes sobre OIDC](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens)).
- O **container** do apiserver tem de conseguir fazer **HTTPS** ao URL do Keycloak para obter as chaves JWKS (DNS e certificados válidos costumam funcionar se o Keycloak for público com TLS normal).

Alterar estes `extraArgs` **obriga a recriar** o cluster Kind (não dá para “patch” live estável no apiserver como num patch operacional normal).

## Arquivo de cluster (exemplo)

Salve por exemplo `kind-cluster.yaml` (ajuste domínio, realm e client-id aos seus valores; alinha `oidc-client-id` com o client Keycloak que você usa no Headlamp ou com um client criado só para o Kubernetes, conforme sua estratégia de `aud`):

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: local-cluster
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: ClusterConfiguration
        apiServer:
          extraArgs:
            oidc-issuer-url: "https://keycloak.personaldevopstrainer.online/realms/master"
            oidc-client-id: "headlamp_oauth_client_id"
            oidc-username-claim: "preferred_username"
            oidc-groups-claim: "groups"
  - role: worker
```

Se você não usar grupos no token, pode omitir `oidc-groups-claim`. Para RBAC por grupo, o Keycloak tem de emitir o claim `groups` e normalmente você precisa do scope/mapper correspondente.

## Recriar o cluster

```bash
kind delete cluster --name local-cluster
kind create cluster --name local-cluster --config kind-cluster.yaml
```

Confirme que o kubeconfig aponta para o novo cluster (`kubectl config current-context`).

## Verificar os argumentos do apiserver

```bash
docker exec -it local-cluster-control-plane kubectl -n kube-system get pod -l component=kube-apiserver -o jsonpath='{.items[0].spec.containers[0].command}' | tr ' ' '\n' | grep oidc
```

(Substitua o nome do container se o seu Kind usar outro nome de cluster.)

## RBAC para o seu usuário OIDC

Depois do apiserver aceitar o token, você ainda precisa de permissões. Exemplo para dar role de admin ao usuário que o apiserver identifica pelo `preferred_username` (ajuste o nome):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: keycloak-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: o-seu-usuario-keycloak
```

O `name` tem de coincidir com o usuário que o apiserver deriva do token (depende de `oidc-username-claim` e do conteúdo do JWT). Para grupos, use `kind: Group` e o nome do grupo como vem no claim.

## Links

- Headlamp + OIDC no cluster: [`headlamp-oauth.md`](./headlamp-oauth.md)
- Cluster Kind em geral: [kind.sigs.k8s.io](https://kind.sigs.k8s.io/docs/user/configuration/)
