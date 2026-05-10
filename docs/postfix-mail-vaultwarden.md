# Postfix, Vaultwarden e e-mail no lab

Este documento descreve o fluxo de correio quando usas **Postfix em cluster** (`boky/postfix`) à frente do **Vaultwarden**, relay para fora (geralmente **Gmail**), TLS, `config.json`, links nos e-mails e o *patch* automático com Terraform.

## Arquitetura

```
Vaultwarden (namespace vaultwarden)
    SMTP STARTTLS :587  →  postfix.mail.svc.cluster.local (namespace mail, imagem boky/postfix)
                              RELAYHOST smarthost :587  →  Gmail (ou outro)
```

- **Submissão interna (587):** o Vaultwarden autentica-se no Postfix com `SMTPD_SASL_USERS` (`vaultwarden_smtp_username` / `vaultwarden_smtp_password`; formato `utilizador@domínio`).
- **Saída para a Internet:** o Postfix reencaminha para `RELAYHOST` com `RELAYHOST_USERNAME` / `RELAYHOST_PASSWORD` (ex.: Gmail `[smtp.gmail.com]:587` e senha de **app**, **sem espaços**).
- **Domínios permitidos no envelope:** `ALLOWED_SENDER_DOMAINS` junta o domínio extraído de `vaultwarden_smtp_from` e `postfix_extra_allowed_sender_domains`.

## Onde está no Terraform

| Local | Conteúdo |
|-------|-----------|
| `infraestructure/modules/helm/postfix/` | Namespace `mail`, Secret `postfix-env`, Deployment/SERVICE Postfix (porta 587). |
| `infraestructure/modules/helm/main.tf` | `module.postfix`, *locals* para domínios permitidos e host SMTP efetivo do Vaultwarden. |
| `infraestructure/modules/helm/vaultwarden/` | Secret `vaultwarden-env`: `DOMAIN`, variáveis SMTP, `SMTP_ACCEPT_INVALID_CERTS` quando aplicável. |
| `infraestructure/environment/` | Variáveis expostas ao utilizador; `vaultwarden_config_patch.tf` (*null_resource* com `kubectl`). |

### Variáveis principais (`environment`)

| Variável | Função |
|----------|--------|
| `postfix_enabled` | Se `true`, cria o Postfix e o Vaultwarden usa `postfix.mail.svc.cluster.local`; ignora `vaultwarden_smtp_host` para o destino interno. |
| `postfix_relayhost`, `postfix_relay_username`, `postfix_relay_password` | Relay de saída (ex.: Gmail). |
| `postfix_extra_allowed_sender_domains` | Domínios extra para `ALLOWED_SENDER_DOMAINS` (separados por espaço). |
| `vaultwarden_smtp_*` | Porta, segurança, utilizador/palavra-passe SASL até ao Postfix, remetente `From`. |
| `vaultwarden_smtp_accept_invalid_certs` | Manual se não usares Postfix no módulo mas precisares de aceitar TLS inválido. |
| `vaultwarden_config_patch_invalid_certs` | Se `true`, após o `apply` corre um script que ajusta `/data/config.json` (ver abaixo). |
| `vaultwarden_config_patch_run_id` | Alterar este valor força o patch a voltar a correr sem mudar o Secret. |

Com `postfix_enabled = true`, o Terraform trata `SMTP_ACCEPT_INVALID_CERTS` no Secret como verdadeiro para o salto interno; com Gmail direto (`postfix_enabled = false` e `vaultwarden_smtp_host = smtp.gmail.com`) não é necessário aceitar certificado inválido no relay público.

## Imagem e variáveis do Postfix (boky)

A imagem predefinida é `boky/postfix:v5.0.0`. O Secret injeta, entre outras:

- `ALLOWED_SENDER_DOMAINS`
- `SMTPD_SASL_USERS`
- `RELAYHOST`, `RELAYHOST_USERNAME`, `RELAYHOST_PASSWORD` (quando configurados)
- `POSTFIX_myhostname`

Documentação upstream: [docker-postfix](https://github.com/bokysan/docker-postfix).

## TLS entre Vaultwarden e Postfix

O serviço interno usa frequentemente certificado **autoassinado**. O Vaultwarden valida o certificado em STARTTLS.

1. O Secret pode definir `SMTP_ACCEPT_INVALID_CERTS=true`.
2. O ficheiro **`/data/config.json`** no PVC do Vaultwarden **sobrepõe-se** a várias variáveis de ambiente (incluindo `smtp_accept_invalid_certs`). Por isso o estado real pode continuar `false` mesmo com o Secret correto.

Para corrigir de forma repetível no Terraform existe o recurso **`null_resource`** em `environment/vaultwarden_config_patch.tf`: corre `kubectl`, põe `smtp_accept_invalid_certs` e `smtp_accept_invalid_hostnames` a `true` em `config.json` e faz `rollout restart` do Deployment. Exige **`kubectl`** disponível na máquina onde corres `terraform apply` e o mesmo `kubeconfig`/`kube_context` que o provider Kubernetes.

Para desativar este passo (por exemplo em CI sem `kubectl`): `vaultwarden_config_patch_invalid_certs = false`.

## Links nos e-mails (`localhost`)

Os convites e URLs gerados usam o **`DOMAIN`** público. No módulo está definido como `https://vaultwarden.<cluster_domain>`. O campo `domain` em `config.json` deve coincidir com o URL real no browser; caso contrário os links aparecem como `http://localhost`. Depois de mudar o domínio, volta a enviar convites antigos.

## Operação útil

```bash
kubectl rollout restart deployment/vaultwarden -n vaultwarden
kubectl rollout restart deployment/postfix -n mail
```

Depois de alterar apenas Secrets com `env_from`, os pods podem precisar de *restart* para ver valores novos.

## Referências cruzadas

- Lista de URLs públicas: [`acesso-urls-publicas.md`](./acesso-urls-publicas.md)
- Terraform geral: [`infra-terraform.md`](./infra-terraform.md)
- ESO e Vaultwarden (segredos): [`secrets-eso-vaultwarden.md`](./secrets-eso-vaultwarden.md)
