# Registry de Imagens no Cluster

Este lab provisiona um Docker Registry (`registry:2`) dentro do cluster com autenticação Basic Auth (htpasswd).

## URL pública

- `https://registry.personaldevopstrainer.online`

## Criar htpasswd (fora do Git)

Exemplo com `htpasswd` (apache-utils):

```bash
htpasswd -Bbn registryuser 'SENHA_FORTE' > registry.htpasswd
```

O arquivo vai conter uma linha `usuario:hash`.  
Use esse conteúdo como `registry_htpasswd` no `terraform.tfvars` (não versionar).

## Exemplo de `terraform.tfvars`

```hcl
registry_htpasswd = "registryuser:$2y$..."
```

## Push e Pull

Login:

```bash
docker login registry.personaldevopstrainer.online
```

Tag e push:

```bash
docker tag crm-api:latest registry.personaldevopstrainer.online/crm-api:latest
docker push registry.personaldevopstrainer.online/crm-api:latest
```

Depois, aponte o chart Helm para:

- `app.image.repository=registry.personaldevopstrainer.online/crm-api`

## Observacoes

- Como a publicação passa pelo Cloudflare Tunnel/HTTP, se notar instabilidade em uploads grandes,
  prefira fazer `push` via rede local (ex.: port-forward) e deixar a URL publica apenas para acesso.

Port-forward:

```bash
kubectl -n registry port-forward svc/registry 5000:5000
docker login localhost:5000
```
