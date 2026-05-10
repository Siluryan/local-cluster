# Debug de acesso público (Cloudflare Tunnel, Envoy, apps)

Este guia reúne o processo de diagnóstico quando URLs como `https://wazuh.<domínio>` (ou Grafana, Keycloak, etc.) não abrem, aparecem **502 Bad Gateway** na Cloudflare ou erros no **`cloudflared`**. Vale para qualquer app exposto pelo **mesmo padrão**: tunnel, **Envoy Gateway**, `HTTPRoute`, `Service`.

## 1. Sintomas e leitura rápida

| Sintoma | Causa frequente |
|--------|------------------|
| **502** na página da Cloudflare | Origem inalcançável (tunnel aponta para Service/porta errados), timeout ou Envoy sem rota. |
| **502** com ~3 s na aba Rede | Muitas vezes timeout até o origin (URL interna errada ou sem listener na porta usada). |
| Log `cloudflared`: `dial tcp ...:80 ... no route to host` | O tunnel usa **porta 80** num Service que **não expõe 80** (ex.: `wazuh-dashboard` só tem **5601**). |
| Log `cloudflared`: `Unable to reach the origin service` + IP interno | Resolver confere, mas **porta** ou **firewall/redes** no cluster bloqueiam; ou Service sem endpoints. |
| Pods “OK”, DNS “OK”, URL pública falha | O problema está no **caminho L7**: tunnel, Envoy ou `HTTPRoute` — não só em pods/DNS. |

## 2. Contexto do Kubernetes

Confirme que está no cluster certo:

```bash
kubectl config current-context
kubectl cluster-info
```

Toda verificação abaixo presume este contexto.

## 3. Dois Services “Envoy” — não confundir

Após instalar o Helm `gateway-helm`, existe um **Service** chamado `envoy-gateway` em `envoy-gateway-system` que é o **control plane** (portas como **18000**, **9443**, etc.). **Ele não escuta HTTP na porta 80** para o tráfego das apps.

O tráfego HTTP entra por outro **Service** criado pelo controlador após existirem **GatewayClass** + **Gateway** (nome longo, ex.: `envoy-envoy-gateway-system-envoy-gateway-<hash>`) com **80/TCP**.

**Errado para o tunnel (na maioria dos casos):**

`http://envoy-gateway.envoy-gateway-system.svc.cluster.local:80`

**Certo:** use o nome listado por:

```bash
kubectl get svc -n envoy-gateway-system
```

na linha cuja coluna **PORT(S)** inclui **80** (não copie o hash de outro cluster — cada instalação pode diferir).

Documentação alinhada: [`cloudflare-publicacao.md`](./cloudflare-publicacao.md), [`acesso-urls-publicas.md`](./acesso-urls-publicas.md).

## 4. Gateway API: Gateway + listener para vários namespaces

Se o **HTTPRoute** estiver em outro namespace (ex.: `wazuh`) e o **Gateway** em `envoy-gateway-system`, o listener precisa permitir rotas de outros namespaces:

```yaml
allowedRoutes:
  namespaces:
    from: All
```

Sem isso, o status do `HTTPRoute` pode ficar **Accepted=False**, motivo **NotAllowedByListeners**, e o Envoy responde **404** em rotas que parecem “corretas” no YAML.

Conferência:

```bash
kubectl get gateway envoy-gateway -n envoy-gateway-system -o jsonpath='{.spec.listeners}' ; echo
kubectl describe httproute wazuh-dashboard -n wazuh | sed -n '/Status:/,$p'
```

No Terraform do lab isto está em `infraestructure/modules/helm/envoy/main.tf`. Após importar recursos existentes, rode `terraform apply` para alinhar o manifest.

## 5. HTTPRoute e Terraform (Wazuh)

- O dashboard publica o Service **`wazuh-dashboard`** na porta **5601** (não 443 nem 80).
- O `HTTPRoute` deve referenciar **`port: 5601`** no `backendRef`.
- Os manifests devem ser aplicados pelo Terraform (`kubernetes_manifest`), não só pelo Helm do chart Wazuh.

Se `kubectl get httproute -n wazuh` estiver vazio, aplique o ambiente Terraform ou veja [`wazuh.md`](./wazuh.md).

## 6. Cloudflare Zero Trust — URL de origem (origem do tunnel)

### 6.1 Caminho recomendado: tudo via Envoy

Para cada **Public Hostname** (ex.: subdomínio `wazuh`):

- **URL / Service**: `http://<service-com-porta-80>.envoy-gateway-system.svc.cluster.local:80`  
  onde `<service-com-porta-80>` é o nome longo da secção 3.

O navegador envia `Host: wazuh.<domínio>`; o **cloudflared** encaminha para esse cluster IP e porta; o **Envoy** escolhe o backend pelo **hostname** e pelo **HTTPRoute**.

### 6.2 Erro típico (Wazuh)

Apontar o tunnel direto para:

`http://wazuh-dashboard.wazuh.svc.cluster.local:80`

O Service **`wazuh-dashboard` não tem porta 80** — só **5601**. O log do `cloudflared` tende a mostrar tentativa em **:80** no ClusterIP do dashboard e falha (**no route to host** / conexão recusada).

**Correção:** use o Envoy na **:80** (7.1) **ou**, só para teste, origem direta na porta certa:

`http://wazuh-dashboard.wazuh.svc.cluster.local:5601`

### 6.3 Caminho direto por app (sem Envoy)

Se optar por não passar pelo Envoy, cada app precisa da **porta real** do `kubectl get svc` — nunca assuma **:80** sem conferir.

## 7. Testes manuais com `curl` (dentro do cluster)

Substitua `<DATAPLANE>` pelo Service com porta 80 em `envoy-gateway-system`:

```bash
kubectl run -n wazuh curl-diag --rm -it --restart=Never --image=curlimages/curl -- \
  curl -sS -o /dev/null -w '%{http_code}\n' \
  -H 'Host: wazuh.personaldevopstrainer.online' \
  'http://<DATAPLANE>.envoy-gateway-system.svc.cluster.local/'
```

Esperado: **302** ou **200** para o Wazuh dashboard. **404** com rota “bonita” no YAML: rever seções 4–5.

Teste direto no dashboard (valida pods/serviço):

```bash
kubectl run -n wazuh curl-dash --rm -it --restart=Never --image=curlimages/curl -- \
  curl -sS -o /dev/null -w '%{http_code}\n' \
  'http://wazuh-dashboard.wazuh.svc.cluster.local:5601/'
```

## 8. Logs do `cloudflared`

```bash
kubectl logs -n cloudflare-tunnel deploy/cloudflared --tail=100
```

Procure:

- **`originService=`** — confira host, namespace e **porta**.
- **`dial tcp ...:80`** em IP do `wazuh-dashboard` — quase sempre **porta errada** (use **5601** direto ou Envoy **:80**).
- Erros intermitentes — timeout; verifique se o origin responde nos testes da seção 7.

## 9. Terraform: objetos já existentes no cluster

Se `terraform apply` falhar com **Cannot create resource that already exists** para `GatewayClass` ou `Gateway`, importe o estado (ajuste o endereço do módulo se o seu for diferente):

```bash
cd infraestructure/environment

terraform import 'module.helm.module.envoy.kubernetes_manifest.envoy_gateway_class' \
  'apiVersion=gateway.networking.k8s.io/v1,kind=GatewayClass,name=eg'

terraform import 'module.helm.module.envoy.kubernetes_manifest.envoy_gateway_http' \
  'apiVersion=gateway.networking.k8s.io/v1,kind=Gateway,namespace=envoy-gateway-system,name=envoy-gateway'
```

## 10. Checklist final

- [ ] Contexto `kubectl` é o cluster onde rodam Wazuh e Envoy.
- [ ] Existe **Service** com **80/TCP** em `envoy-gateway-system` (dataplane).
- [ ] `Gateway` tem `allowedRoutes.namespaces.from: All` (ou política equivalente para os seus namespaces).
- [ ] `HTTPRoute` do Wazuh com **Accepted=True** e backend **5601**.
- [ ] Tunnel Cloudflare **não** usa `wazuh-dashboard...:80`; usa **Envoy :80** ou **dashboard :5601**.
- [ ] Logs do `cloudflared` sem `dial tcp` para porta errada.

## Referências no repositório

- [`cloudflare-publicacao.md`](./cloudflare-publicacao.md) — publicar hostnames no Zero Trust.
- [`acesso-urls-publicas.md`](./acesso-urls-publicas.md) — mal-entendidos DNS/BIND vs Cloudflare.
- [`wazuh.md`](./wazuh.md) — detalhes do chart e portas do Wazuh.
