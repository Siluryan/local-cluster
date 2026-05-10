# Estimativa de custos na Oracle Cloud Infrastructure (OCI)

Este documento descreve a **configuração orientada a Always Free** em `infraestructure/cluster/main.tf` e uma **estimativa de custo** para o que ainda possa ser cobrado. Os valores **não são garantidos**: a OCI cobra por uso real, região, moeda e contrato (pay-as-you-go, créditos universais, etc.).

**Referências:** [Calculadora de Custos OCI](https://www.oracle.com/cloud/costestimator.html) e [lista de preços](https://www.oracle.com/cloud/pricing/).

---

## 1. Configuração atual do cluster (otimizada para Always Free)

O arquivo `infraestructure/cluster/main.tf` foi ajustado para usar **exclusivamente `VM.Standard.A1.Flex` (Ampere)** nos três computes criados pelo módulo, somando **4 OCPUs** e **24 GB** de RAM — alinhado ao limite típico **Always Free** da OCI para Ampere na conta (confirmar na documentação oficial da época; cotas podem mudar).

| Componente | Shape | Recursos | Função |
|------------|--------|----------|--------|
| Worker (pool `np1`) | VM.Standard.A1.Flex | **2 OCPU**, **12 GB** RAM, boot **50 GB** | Único nó do Kubernetes |
| Bastion | VM.Standard.A1.Flex | **1 OCPU**, **6 GB** RAM, boot **50 GB** | Salto SSH até o operator (exigido pelo módulo Oracle) |
| Operator | VM.Standard.A1.Flex | **1 OCPU**, **6 GB** RAM, boot **50 GB** | Execução remota de `kubectl`/Helm pelo Terraform |

Outras escolhas para reduzir custo e complexidade:

- **`worker_is_public = true`** — workers com IP público (menos dependência de NAT para tráfego dos nós; **atenção à superfície de ataque**, use NSGs e políticas adequadas).
- **`control_plane_is_public`** + **`assign_public_ip_to_control_plane`** — API do cluster acessível sem VPN (cenário típico de laboratório).
- **`load_balancers = "public"`** — apenas subnets para LB público (sem subnet interna de LB).

**Total de boot volumes:** ~150 GB (3 × 50 GB). O tier gratuito costuma incluir um volume de bloco agregado — validar se o total permanece dentro da cota gratuita da sua conta.

---

## 2. O que ainda pode gerar custo (mesmo no Always Free)

| Item | Motivo |
|------|--------|
| **NAT Gateway** | Com **`create_operator = true`**, o módulo Oracle tende a **criar NAT** para subnets privadas (operator). O NAT Gateway tem **custo por hora** na maior parte das regiões. Eliminar o NAT sem alterar o módulo não é trivial; envolveria `operator` ausente ou redes personalizadas e pode **quebrar** `terraform apply`. |
| **Load Balancers** | Criados quando expões `Service` tipo `LoadBalancer` (ex.: no stack `environment`). |
| **Egress** | Tráfego de saída para a Internet ou entre regiões. |
| **Object Storage** | Bucket de state (`bootstrap`) — armazenamento e requisições; tipicamente **baixo** para arquivos de state. |
| **Imagens de containers** | Workloads **amd64** podem precisar de emulação ou rebuild para **ARM** nos nodes A1; não é custo direto da OCI, mas pode exigir mais recursos ou troubleshooting. |

---

## 3. Faixa de custo mensal esperada (após otimização)

Se as cotas **Ampere Always Free** cobrirem integralmente os **três** computes A1 e os **boot volumes** couberem na cota gratuita de armazenamento:

- **Compute (A1):** tendência a **US$ 0** nas condições acima.

Custos residuais típicos:

- **NAT Gateway:** frequentemente na ordem de **dezenas de USD/mês** por região/lista de preços (calcular na calculadora).
- **Object Storage / LB / egress:** conforme uso.

Sem NAT e só com storage mínimo, a fatura pode aproximar-se de **zero**; na prática, **NAT + pequenos extras** costuma ficar numa faixa **aproximada de US$ 15–50/mês** (ordem de grandeza; validar sempre na calculadora).

---

## 4. Custos variáveis no stack `environment`

Helm, `LoadBalancer`, PVCs, registros externos e túneis podem acrescentar custos **independentes** do `cluster/main.tf`. Consulte a seção de workloads na calculadora.

---

## 5. Boas práticas

1. Ativar **budgets** e alertas no console OCI.  
2. Rever periodicamente **Cost Analysis** e serviços esquecidos (LB órfãos, volumes não ligados).  
3. Se já consumiste Ampere A1 **fora** deste projeto na mesma conta, o `apply` pode falhar por quota — reduza OCPU/memória nos maps ou libere instâncias antigas.  
4. Para cargas de produção, reveja **segurança** de endpoints e nodes públicos.

---

## 6. Isenção de responsabilidade

Esta estimativa é **orientativa**. Preços e cotas **Always Free** mudam; impostos e câmbio (BRL) aplicam-se à conta. Confirme sempre na Oracle antes de assumir **custo zero**.

**Última revisão alinhada ao repositório:** otimização Ampere em `infraestructure/cluster/main.tf`.
