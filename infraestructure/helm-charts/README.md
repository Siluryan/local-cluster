# Charts Helm (cache opcional)

Os pacotes `.tgz` opcionais são gerados por `../../scripts/vendor-helm-charts.sh` na pasta **`.helm/cache/repository/`** na raiz do repositório (cache Helm local, não commitado).

## Por que não versionar todos os charts no Git?

- **Tamanho**: `kube-prometheus-stack` e dependências geram um `.tgz` grande; o repositório vira difícil de clonar e PRs carregam megabytes sem código.
- **Atualizações**: segurança e correções vêm dos repositórios oficiais; cópias fixas no Git exigem bump manual em vários arquivos.
- **OCI**: o Envoy Gateway usa `oci://docker.io/envoyproxy` — não é um `index.yaml` clássico; ainda depende de rede ou de `helm pull`/`helm show`.

## O que o projeto já faz

- **Keycloak**: chart local com `keycloak_chart_archive_path` ou detecção automática se existir `.helm/cache/repository/keycloak-24.7.4.tgz`.
- **Wazuh**: o repositório oficial da Wazuh costuma retornar **403**; o módulo usa um mirror público estável (`morgoved.github.io`).
- **Pré-voo rede**: `./scripts/preflight-helm-repos.sh`.

## Abordagens

| Abordagem | Quando usar |
|-----------|--------------|
| Padrão (remoto no `terraform apply`) | Lab com Internet; menor manutenção. |
| **Cache local** (`.helm/cache/repository/` + script) | Firewall, CI sem acesso sempre ao Helm, reproducibilidade entre runs. |
| **Commit só de charts críticos** | Política interna pede revisão binary de um pacote específico (ex.: apenas Keycloak). |

A árvore **`.helm/cache/`** é ignorada pelo Git. Para isolar ainda mais o Helm neste repo: `HELM_CACHE_HOME=$PWD/.helm/cache`, `HELM_CONFIG_HOME=$PWD/.helm/config`, `HELM_DATA_HOME=$PWD/.helm/data` (as pastas `config/` e `data/` podem ficar vazias até você usar plugins/repos locais).
