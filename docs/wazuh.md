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

## Observações

- O repositório Helm em `https://packages.wazuh.com/4.x/helm/` costuma responder **403** (inacessível). O módulo Terraform usa o chart **morgoved/wazuh-helm** (`https://morgoved.github.io/wazuh-helm/`), com recursos reduzidos para o lab (1 réplica de indexer, 1 master, 1 worker) e `NetworkPolicy` desligada para o Envoy alcançar o dashboard.
- A UI (Kibana/OpenSearch Dashboards) fica no Service `wazuh-dashboard` na porta **5601**; o `HTTPRoute` aponta para essa porta.
- Se o nome do Service ou da porta mudar em versões futuras do chart, ajuste em `infraestructure/modules/helm/wazuh/main.tf`.
