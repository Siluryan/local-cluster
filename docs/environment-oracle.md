# Stack `environment` com Oracle (OKE)

O diretório `infraestructure/environment` está configurado no repositório para **cluster local (kubeconfig)** e **backend Terraform local**. Este documento descreve como usar **Oracle Cloud Infrastructure**: credenciais, backend Object Storage, stacks `bootstrap` e `cluster`, e como reconectar o stack `environment` ao **OKE** remoto.

## Pré-requisitos na OCI

1. **Região**: o tenancy deve estar **inscrito** na região onde você vai criar recursos e onde está o bucket de state (por exemplo `us-ashburn-1`). Em **Governance & Administration → Tenancy Management → Regions**, confirme **Subscribed** para essa região.
2. **Chave API**: em **Identity → Users → seu usuário → API keys**, registre o **fingerprint** e guarde o **par de chaves** (PEM privado localmente; a pública fica no console).
3. **Bucket Object Storage**: um bucket para o estado Terraform (ou use o criado pelo stack `bootstrap`).
4. **Namespace Object Storage**: obtenha com `oci os ns get` na mesma região do bucket (ou na página do bucket no console).

## Credenciais no cliente

Configure `~/.oci/config` (perfil `DEFAULT` ou outro) com `user`, `fingerprint`, `tenancy`, `region`, `key_file`.

Para `terraform init` com backend `oci`, costuma ser necessário um arquivo **partial backend** com API Key explícita (não só `config_file_profile`), para evitar `401 NotAuthenticated`. Copie `infraestructure/_backend-environment.hcl.example` para `infraestructure/backend-environment.hcl` (gitignored no projeto), preencha `namespace`, `region`, `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path` com caminho absoluto recomendado para a chave PEM.

## Ordem dos stacks

1. **`infraestructure/bootstrap`** — cria (ou confirma) o bucket de state, se ainda não existir.
2. **`infraestructure/cluster`** — cria o cluster **OKE** (ou referencia um existente via variáveis do módulo).
3. **`infraestructure/environment`** — instala os Helm charts no cluster.

Os stacks `bootstrap` e `cluster` continuam a usar backend **`oci`** com init do tipo:

```bash
cd infraestructure/bootstrap
terraform init -backend-config=../backend-bootstrap.hcl
```

```bash
cd infraestructure/cluster
terraform init -backend-config=../backend-cluster.hcl
```

(Veja também `infraestructure/_backend-bootstrap.hcl.example` e `_backend-cluster.hcl.example`.)

## Alterar `environment` para OKE em vez de Kind

No estado atual do código, `environment` usa:

- `providers.tf`: apenas `kubernetes` e `helm` com `kubeconfig_path` / `kube_context`;
- `backend.tf`: backend **local**;
- sem `terraform_remote_state` para o stack cluster;
- sem `data "oci_containerengine_cluster_kube_config"`.

Para voltar a usar **OKE**:

1. **Backend remoto**  
   Substitua o bloco `backend "local"` em `infraestructure/environment/backend.tf` por um bloco `backend "oci"` com `bucket`, `namespace`, `key`, `region`, `auth`, alinhado aos outros stacks; ou mantenha um único `backend.tf` mínimo e use sempre init com `-backend-config` apontando para um HCL com os mesmos campos.

2. **Estado remoto do cluster**  
   Volte a declarar `data "terraform_remote_state" "cluster"` com `backend = "oci"` e `config` com bucket, key do state do cluster (`infraestructure/cluster/terraform.tfstate` por padrão), `namespace`, `region`, e credenciais API Key (`tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path` com `pathexpand` no caminho da chave).

3. **Kubeconfig via API OKE**  
   Volte a declarar `data "oci_containerengine_cluster_kube_config"` com `cluster_id`, `endpoint` (`PUBLIC_ENDPOINT` ou `PRIVATE_ENDPOINT`), `token_version`.

4. **`locals.tf`**  
   Calcula `oke_cluster_id` a partir de `var.oke_cluster_id` ou do output `cluster_id` do remote state; deriva `k8s_host` e `k8s_ca_pem` a partir do conteúdo YAML do kube config devolvido pela data source.

5. **Providers**  
   - `provider "oci"` com `ApiKey` (`tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key` ou `private_key_path`, `region`).  
   - `provider "kubernetes"` e `provider "helm"` com `host`, `cluster_ca_certificate`, e bloco `exec` chamando `oci ce cluster create-kubeconfig` com `--cluster-id` e `--kube-endpoint` conforme a variável de endpoint.

6. **Variáveis**  
   Acrescente de novo ao `variables.tf` do environment: identidade OCI, `region`, `oke_cluster_id` (opcional), `oke_kubernetes_endpoint`, e variáveis do backend remoto do state (`terraform_state_bucket`, `terraform_state_region`, `terraform_state_namespace`, opcionalmente `terraform_state_cluster_key`).

7. **`checks.tf`**  
   Garante que existe `oke_cluster_id` explícito ou output `cluster_id` no remote state antes do apply.

8. **`versions.tf`**  
   Readicione o provider `oracle/oci` nas versões exigidas pelo projeto.

9. **`terraform.tfvars`**  
   Inclua os valores OCI e de state; remova ou comente entradas só usadas para Kind (`kubeconfig_path`, `kube_context`) se você deixar de usar kubeconfig local.

Validação rápida antes do apply no cluster remoto:

```bash
oci iam region list --all
```

Quando isso funcionar com a mesma API key e região que o Terraform usa, a camada de API está coerente.

## Referência rápida de políticas e backend

- Bucket de state: permissões de objeto adequadas para o usuário ou grupo que executa Terraform (leitura/escrita do objeto de state).
- Documentação geral de backends e fluxo OCI no repositório: [`infra-terraform.md`](infra-terraform.md) (seções "Aplicar" e "Backend remoto").

Se você precisar dos arquivos exatos como existiam antes da mudança para Kind, use o histórico Git neste repositório sobre `infraestructure/environment/` para recuperar versões anteriores dos arquivos listados acima.
