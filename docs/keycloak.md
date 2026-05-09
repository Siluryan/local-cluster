# Keycloak (usuários e OIDC)

## Acesso

- URL: `https://keycloak.personaldevopstrainer.online`

## Configuração mínima recomendada

1. Criar Realm `crm`
2. Criar Client (OIDC) `crm-api`
3. Criar roles/scopes:
   - `crm.read`
   - `crm.admin`
4. Criar usuários e atribuir roles

## CRM como Resource Server

O CRM valida JWT pelo `issuer-uri` configurado.

No chart Helm (`app/helm/crm/values.yaml`):

- `auth.enabled=true`
- `auth.issuerUrl=https://keycloak.personaldevopstrainer.online/realms/crm`

Permissões:

- `GET /api/customers`: requer `crm.read` ou `crm.admin`
- `POST/PUT/DELETE /api/customers`: requer `crm.admin`

## Obtendo token (exemplo)

Use o endpoint de token do realm:

- `POST https://keycloak.personaldevopstrainer.online/realms/crm/protocol/openid-connect/token`

Depois chame a API com:

- `Authorization: Bearer <token>`
