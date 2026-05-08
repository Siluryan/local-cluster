# Secrets com ESO e Vaultwarden

## Estado atual do lab

- O ESO esta instalado e pronto para consumir `SecretStore`/`ClusterSecretStore`
- O Vaultwarden esta disponivel com interface web
- O chart do CRM ja suporta `ExternalSecret`

## Limitação atual

O ESO nao possui provider nativo para Vaultwarden.  
Para fluxo de producao no lab, use um backend suportado pelo ESO (ex.: Kubernetes, Vault, AWS/GCP) ou implemente um sync job.

## Exemplo rápido com backend Kubernetes (ClusterSecretStore)

1) Criar secret de origem:

```bash
kubectl -n external-secrets create secret generic crm-source \
  --from-literal=POSTGRES_DB=crm \
  --from-literal=POSTGRES_USER=crm \
  --from-literal=POSTGRES_PASSWORD='SENHA_FORTE'
```

2) Criar um `ClusterSecretStore` apontando para o provider Kubernetes.

3) No deploy do CRM, habilitar:

```bash
--set externalSecrets.enabled=true
--set postgres.existingSecret=crm-postgres-secret
```

## Vaultwarden

- URL esperada: `https://vaultwarden.personaldevopstrainer.online`
- Defina `vaultwarden_admin_token` forte
- Use MFA para contas administrativas
