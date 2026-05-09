# Aplicação CRM (Java + Postgres + Helm)

## Build da aplicação

```bash
cd app
mvn clean package
docker build -t registry.personaldevopstrainer.online/crm-api:latest .
docker push registry.personaldevopstrainer.online/crm-api:latest
```

## Deploy via Helm

```bash
cd app
helm upgrade --install crm ./helm/crm \
  --namespace apps \
  --create-namespace \
  --set publicHost=crm.personaldevopstrainer.online \
  --set app.image.repository=registry.personaldevopstrainer.online/crm-api \
  --set app.image.tag=latest \
  --set postgres.existingSecret=crm-db-secret
```

## Endpoints

- `GET /api/health`
- `GET /api/customers`
- `POST /api/customers`
- `GET /api/customers/{id}`
- `PUT /api/customers/{id}`
- `DELETE /api/customers/{id}`

## Smoke test

```bash
curl -i https://crm.personaldevopstrainer.online/api/health
```
