# Charts Helm (cache opcional)

Este diretório existe para **opcionalmente** guardar pacotes `.tgz` baixados com o script `../../scripts/vendor-helm-charts.sh`.

## Por que não versionar todos os charts no Git?

- **Tamanho**: `kube-prometheus-stack` e dependências geram um `.tgz` grande; o repositório vira difícil de clonar e PRs carregam megabytes sem código.
- **Atualizações**: segurança e correções vêm dos repositórios oficiais; cópias fixas no Git exigem bump manual em vários arquivos.
- **OCI**: o Envoy Gateway usa `oci://docker.io/envoyproxy` — não é um `index.yaml` clássico; ainda depende de rede ou de `helm pull`/`helm show`.

## O que o projeto já faz

- **Keycloak**: dá para usar chart local com `keycloak_chart_archive_path` (e detecção de `.helmcache` nos `locals`).
- **Wazuh**: o repositório oficial da Wazuh costuma retornar **403**; o módulo usa um mirror público estável (`morgoved.github.io`).
- **Pré-voo rede**: `./scripts/preflight-helm-repos.sh`.

## Abordagens

| Abordagem | Quando usar |
|-----------|--------------|
| Padrão (remoto no `terraform apply`) | Lab com Internet; menor manutenção. |
| **Cache local** (`cache/` + script) | Firewall, CI sem acesso sempre ao Helm, reproducibilidade entre runs. |
| **Commit só de charts críticos** | Política interna pede revisão binary de um pacote específico (ex.: apenas Keycloak). |

A pasta **`cache/`** é ignorada pelo Git — rode o vendor onde for aplicar o Terraform ou em pipeline e copie o diretório para o ambiente fechado, se precisar.
