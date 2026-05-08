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

- O deploy usa o chart oficial do Wazuh.
- A UI é publicada pelo mesmo padrão do lab: Envoy + DNSEndpoint.
- Se o service do dashboard no chart mudar de nome/porta em versões futuras, ajuste no módulo `infraestructure/modules/helm/wazuh/main.tf`.
