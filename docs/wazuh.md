# Wazuh no Lab

O Wazuh foi incluído no cluster via Helm e exposto por URL pública.

## URL

- `https://wazuh.personaldevopstrainer.online`

## Como verificar

```bash
kubectl -n wazuh get pods
kubectl -n wazuh get svc
kubectl -n wazuh get httproute
kubectl -n wazuh get dnsendpoint
```

## Debug (URL pública não abre, 502, logs do cloudflared)

O fluxo completo (Envoy vs Service `wazuh-dashboard`, portas **5601** vs **80**, tunnel Cloudflare, Gateway API) está em **[`debug-acesso-publico.md`](./debug-acesso-publico.md)**.

## Autenticação no dashboard

Este Terraform **não** configura OIDC no Wazuh. O chart pode usar autenticação interna (por exemplo utilizador `wazuh_admin` / `wazuh_user` e palavras-passe definidas pelo Helm); consulte os valores do chart **morgoved/wazuh-helm** e os Secrets gerados no namespace `wazuh`.

## Observações

- O repositório Helm em `https://packages.wazuh.com/4.x/helm/` costuma responder **403** (inacessível). O módulo Terraform usa o chart **morgoved/wazuh-helm** (`https://morgoved.github.io/wazuh-helm/`), com recursos reduzidos para o lab (1 réplica de indexer, 1 master, 1 worker) e `NetworkPolicy` desligada para o Envoy alcançar o dashboard.
- A UI (Kibana/OpenSearch Dashboards) fica no Service `wazuh-dashboard` na porta **5601**; o `HTTPRoute` aponta para essa porta.
- Se o nome do Service ou da porta mudar em versões futuras do chart, ajuste em `infraestructure/modules/helm/wazuh/main.tf`.
