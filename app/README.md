# CRM App (Java + Postgres + Helm)

Aplicacao CRM simples em Spring Boot com persistencia em PostgreSQL.

## Funcionalidades

- API REST para clientes (`/api/customers`)
- CRUD basico de clientes (nome, email, empresa, status)
- Healthcheck (`/api/health`)
- Deploy via Helm no cluster
- Exposicao via Envoy Gateway (`HTTPRoute`)
- Registro DNS via `DNSEndpoint` (ExternalDNS)

## Build da imagem

```bash
cd app
mvn clean package
docker build -t crm-api:latest .
```

Publique a imagem em um registry acessivel pelo cluster e ajuste `app.image.repository`/`app.image.tag` no `values.yaml`.

## Deploy Helm

```bash
helm upgrade --install crm ./helm/crm \
  --namespace apps \
  --create-namespace \
  --set publicHost=crm.personaldevopstrainer.online \
  --set app.image.repository=registry.personaldevopstrainer.online/crm-api \
  --set app.image.tag=latest \
  --set postgres.password=SENHA_FORTE
```

Ou, preferencialmente, crie um Secret fora do Git e referencie no chart:

```bash
kubectl -n apps create secret generic crm-db-secret \
  --from-literal=POSTGRES_DB=crm \
  --from-literal=POSTGRES_USER=crm \
  --from-literal=POSTGRES_PASSWORD='SENHA_FORTE'

helm upgrade --install crm ./helm/crm \
  --namespace apps \
  --create-namespace \
  --set publicHost=crm.personaldevopstrainer.online \
  --set app.image.repository=registry.personaldevopstrainer.online/crm-api \
  --set app.image.tag=latest \
  --set postgres.existingSecret=crm-db-secret
```

## Usando ESO para preencher secrets

Com o ESO instalado no lab, voce pode habilitar no chart:

```bash
helm upgrade --install crm ./helm/crm \
  --namespace apps \
  --create-namespace \
  --set externalSecrets.enabled=true \
  --set postgres.existingSecret=crm-postgres-secret
```

Nesse modo, o `ExternalSecret` cria o secret de banco a partir do `ClusterSecretStore` configurado.

## Endpoints

- `GET /api/health`
- `GET /api/customers`
- `POST /api/customers`
- `GET /api/customers/{id}`
- `PUT /api/customers/{id}`
- `DELETE /api/customers/{id}`

### Exemplo de create

```bash
curl -X POST "https://crm.personaldevopstrainer.online/api/customers" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Luke Skywalker",
    "email":"luke@rebellion.org",
    "company":"Rebellion",
    "status":"lead"
  }'
```
