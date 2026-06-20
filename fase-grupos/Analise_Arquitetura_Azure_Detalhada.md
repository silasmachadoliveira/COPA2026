Links Uteis
Git - https://github.com/TFTEC/fifa2026-tickets-dev/blob/main/docs/GUIA-EVENTO-VMS.md

# Análise Detalhada da Arquitetura Azure – Cenário 3 VMs / 2 VNets / 2 Regiões

## Visão Geral

A imagem apresenta uma arquitetura de aplicação multicamada hospedada no Microsoft Azure, distribuída entre duas regiões geográficas:

- Central India
- Australia East

O ambiente é composto por:

- 3 Máquinas Virtuais (VMs)
- 2 VNets
- 2 NSGs
- Global VNet Peering
- IIS com Reverse Proxy (ARR)
- API Node.js
- SQL Server 2022

---

# Objetivo da Arquitetura

Simular uma aplicação web corporativa seguindo o modelo:

Frontend → Backend/API → Banco de Dados

O acesso dos usuários ocorre pela Internet através do Frontend, que encaminha as requisições para o Backend. O Backend consulta o banco SQL Server utilizando conectividade privada entre regiões Azure.

---

# Topologia Geral

```text
Usuário
   |
Internet (80/443)
   |
Frontend (IIS + ARR)
   |
TCP 80
   |
Backend (Node.js API)
   |
TCP 1433
   |
SQL Server 2022
```

---

# Região 1 – Central India

## VNet

Nome:

vnet-prd-inf-cin-001

Espaço de Endereçamento:

10.20.0.0/16

### Subnets

Frontend:

10.20.1.0/24

Backend:

10.20.2.0/24

---

# Camada Frontend

## VM

Nome:

vm-prd-tk-fend-cin-001

Função:

Receber acessos dos usuários e atuar como Reverse Proxy.

### Sistema Operacional

Windows Server 2022

### Componentes Instalados

- IIS
- URL Rewrite
- ARR (Application Request Routing)

### Portas Utilizadas

- TCP 80 (HTTP)
- TCP 443 (HTTPS)

### Função do ARR

O ARR atua como Reverse Proxy:

```text
Cliente
    |
    v
Frontend IIS
    |
    v
Backend API
```

Benefícios:

- Oculta o Backend
- Centraliza autenticação
- Simplifica publicação da aplicação
- Possibilita balanceamento futuro

---

# Camada Backend

## VM

Nome:

vm-prd-tk-bend-cin-001

### Sistema Operacional

Windows Server 2022

### Componentes

- IIS
- iisnode
- Node.js
- API FIFA2026

### Comunicação

Recebe tráfego apenas do Frontend.

Porta:

TCP 80

Fluxo:

```text
Frontend
   |
 TCP 80
   |
Backend
```

---

# Região 2 – Australia East

## VNet

Nome:

vnet-prd-inf-aes-001

Espaço de Endereçamento:

10.30.0.0/16

### Subnet

10.30.1.0/24

---

# Banco de Dados

## VM

Nome:

vm-prd-tk-data-aes-001

### Sistema Operacional

Windows Server

### Banco

SQL Server 2022

### Porta

TCP 1433

### Características

- Autenticação SQL
- Banco FIFA2026Tickets
- Comunicação privada através do Peering

Fluxo:

```text
Backend
   |
 TCP 1433
   |
SQL Server
```

---

# Global VNet Peering

Conecta:

Central India
10.20.0.0/16

com

Australia East
10.30.0.0/16

Objetivo:

Permitir comunicação privada entre as VNets.

Benefícios:

- Sem VPN
- Menor complexidade
- Melhor desempenho
- Menor overhead

Fluxo:

```text
10.20.0.0/16
      |
      |
 Global Peering
      |
      |
10.30.0.0/16
```

---

# Network Security Groups (NSG)

## NSG Frontend

Nome:

nsg-prd-inf-cin-001

### Regras

TCP 80
Origem: Internet

TCP 443
Origem: Internet

TCP 3389
Origem: Meu IP

### Objetivo

- Publicar aplicação
- Restringir administração

---

## NSG Banco

Nome:

nsg-prd-inf-aes-001

### Regras

TCP 1433
Origem: 10.20.0.0/16

TCP 3389
Origem: Meu IP

### Objetivo

Permitir acesso apenas da aplicação.

---

# Fluxo Completo da Aplicação

## Etapa 1

Usuário acessa:

https://aplicacao

## Etapa 2

Frontend recebe a requisição.

## Etapa 3

ARR redireciona para Backend.

## Etapa 4

Backend processa a lógica.

## Etapa 5

Backend consulta SQL Server.

## Etapa 6

Banco retorna dados.

## Etapa 7

Backend responde ao Frontend.

## Etapa 8

Frontend entrega resposta ao usuário.

---

# Decisões de Design Identificadas

## Segmentação por Camadas

Frontend separado do Backend.

Benefícios:

- Segurança
- Organização
- Escalabilidade

## Banco em Região Diferente

Objetivo didático para demonstrar:

- Global Peering
- Comunicação privada inter-região

## Uso de ARR

Evita exposição direta da API.

## Uso de NSGs

Controle granular do tráfego.

---

# Pontos Positivos

## Segurança

- Banco não exposto diretamente à Internet
- NSGs implementados
- Administração restrita por IP

## Arquitetura

- Separação de responsabilidades
- Uso correto de VNets
- Comunicação privada

## Rede

- Peering global funcionando como backbone privado

---

# Riscos Identificados

## Latência Inter-Região

Central India → Australia East

Possíveis impactos:

- Maior tempo de resposta
- Maior latência SQL

## IP Público em Todas as VMs

Riscos:

- Aumento da superfície de ataque
- Tentativas de brute force
- Exposição desnecessária

## Ponto Único de Falha

Existe apenas:

- 1 Frontend
- 1 Backend
- 1 Banco

Falha em qualquer VM interrompe a aplicação.

---

# Melhorias Recomendadas

## Azure Bastion

Remover RDP público.

Benefícios:

- Administração segura
- Sem IP público nas VMs

## Application Gateway

Substituir ARR futuramente.

Benefícios:

- WAF
- Balanceamento
- SSL Offload

## SQL Managed Instance

Substituir SQL em VM.

Benefícios:

- Backups automáticos
- Alta disponibilidade
- Menor esforço operacional

## Alta Disponibilidade

Implementar:

- Availability Zones
- VM Scale Sets
- Balanceadores

## Monitoramento

Adicionar:

- Azure Monitor
- Log Analytics
- Application Insights

---

# Avaliação Well-Architected

## Segurança

7/10

## Confiabilidade

4/10

## Eficiência de Performance

6/10

## Otimização de Custos

7/10

## Excelência Operacional

5/10

---

# Conclusão

A arquitetura demonstra corretamente conceitos fundamentais de Azure:

- VNets
- Subnets
- NSGs
- Global VNet Peering
- Reverse Proxy
- Aplicação multicamada
- SQL Server
- Comunicação privada entre regiões

É uma arquitetura adequada para laboratórios, treinamento e validação de conceitos de rede e aplicação.

Para produção corporativa, recomenda-se eliminar IPs públicos das VMs, adicionar alta disponibilidade, utilizar serviços PaaS quando possível e reduzir dependências entre regiões para minimizar latência.

                    
                                    
   PADRÃO DE TAXONOMIA DE RECURSOS NO AZURE											
                                    
   Guia oficial de nomenclatura • Copa do Mundo Azure 2026 • TFTEC Prime											
                                    
   Convocado(a) para o gramado da nuvem? Antes de criar qualquer recurso, leia este guia.											
                                    
                                    
      O PADRÃO EM UMA LINHA										
      tipo - prd - app - papel - cin - 001										
                                    
                                    
      Exemplo:  vm-prd-tk-fend-cin-001   →   Máquina Virtual • Produção • app Tickets • Frontend • Central India • instância 001										
                                    
                                    
                                    
   ⚽ Por que padronizar?  Nomes consistentes deixam claro o que é cada recurso, quem é o dono, em que ambiente e região ele vive — e evitam confusão na hora de migrar, cobrar custos e dar suporte.											
                                    
   COMO USAR ESTE ARQUIVO											
      1.  Aba "Como Ler o Nome" — a anatomia de cada pedaço do nome.										
      2.  Aba "Códigos" — as tabelas oficiais (tipo de recurso, ambiente, app, papel, região).										
      3.  Aba "Catálogo de Recursos" — o nome exato de cada recurso das 3 trilhas (Tickets, Bolão e VMs).										
      4.  Aba "Regras Especiais" — os casos que fogem da regra (Storage sem hífen, nome de VM ≤ 15...).										
                                    
                                    
Como ler o nome
            
   Como ler o nome de um recurso			
   Cada nome é montado por pedaços separados por hífen. Leia da esquerda para a direita.			
            
   tipo  -  prd  -  app  -  papel  -  cin  -  001			
            
#	Pedaço	Sempre presente?	O que significa	Exemplo
1	tipo	Sim	Que tipo de recurso é (Máquina Virtual, Web App, Banco...). Use os códigos da aba Códigos.	vm, web, sql, st
2	prd	Sim	Ambiente. No evento usamos sempre produção = prd.	prd
3	app	Sim	De qual aplicação o recurso faz parte: Tickets (tk) ou Bolão (bl). Rede compartilhada = inf.	tk, bl, inf
4	papel	Às vezes	A função da peça: frontend, backend, dados, rede. Recursos únicos (RG, SQL Server) não usam.	fend, bend, data
5	cin	Sim	Região do Azure. No evento todos publicam em Central India = cin.	cin
6	instância	Sim	Número que o instrutor te dá (001, 002...). Garante nome único entre alunos e numera recursos repetidos.	001, 002, 003
            
   REGRAS DE OURO			
   •  Tudo em minúsculas. Sem acentos, sem espaços, sem caracteres especiais.			
   •  Separador é sempre o hífen "-" (exceto Storage Account, que não aceita hífen — veja Regras Especiais).			
   •  A sua instância (ex.: 001) é definida pelo instrutor e usada em TODOS os seus recursos.			
   •  Quando precisar de mais de um recurso igual, acrescente número no fim: -01, -02, -03...			
   •  Não invente abreviações: use só os códigos das tabelas oficiais (aba Códigos).			

Códigos

# Tabelas Oficiais de Códigos

> Use SOMENTE estes códigos ao montar os nomes dos recursos.

---

# 1) Tipo de Recurso (1º pedaço)

| Código | Recurso Azure |
|----------|----------|
| rg | Resource Group (grupo de recursos) |
| asp | App Service Plan (plano que hospeda Web Apps) |
| web | Web App / App Service (site ou API) |
| func | Function App (funções serverless) |
| swa | Static Web App (site estático) |
| sql | Azure SQL — servidor lógico |
| sqldb | Azure SQL — banco de dados |
| cosmos | Azure Cosmos DB (banco NoSQL) |
| sigr | Azure SignalR (tempo real) |
| st | Storage Account (armazenamento) |
| appi | Application Insights (monitoramento) |
| kv | Key Vault (cofre de segredos) |
| vnet | Virtual Network (rede virtual) |
| snet | Subnet (sub-rede) |
| nsg | Network Security Group (firewall de rede) |
| pip | Public IP (IP público) |
| nic | Network Interface (placa de rede da VM) |
| vm | Virtual Machine (máquina virtual) |
| disk | Managed Disk (disco da VM) |
| bas | Azure Bastion (acesso seguro às VMs) |

---

# 2) Ambiente (2º pedaço)

| Código | Significado |
|----------|----------|
| prd | Produção — padrão do evento |
| dev | Desenvolvimento (referência) |
| lab | Laboratório/treino (referência) |

---

# 3) Aplicação (3º pedaço)

| Código | Significado |
|----------|----------|
| tk | Aplicação Tickets (bilheteria — SQL) |
| b1 | Aplicação Bolão (palpites — Cosmos) |
| inf | Infra/rede compartilhada |

---

# 4) Papel (4º pedaço — quando aplicável)

| Código | Significado |
|----------|----------|
| fend | Frontend (o que o torcedor vê) |
| bend | Backend / API (regras e dados) |
| data | Camada de dados (banco) |
| net | Rede |
| sec | Segurança |

---

# 5) Região (5º pedaço)

| Código | Região Azure |
|----------|----------|
| cin | Central India — região do evento |
| aes | Australia East — região do evento |

---

# 6) Número da Instância (6º pedaço)

Número de 3 dígitos atribuído ao recurso:

- 001
- 002
- 003
- ...

Observações:

- Use o mesmo número base em todos os recursos relacionados.
- Utilize 002, 003 etc. para recursos repetidos do mesmo tipo.
- O padrão deve permanecer consistente em toda a solução.

---

# Estrutura de Nomenclatura

```text
<tipo>-<ambiente>-<aplicacao>-<papel>-<regiao>-<instancia>
```

## Exemplos

```text
rg-prd-tk-cin-001
vnet-prd-inf-cin-001
snet-prd-inf-fend-cin-001
vm-prd-tk-fend-cin-001
vm-prd-tk-bend-cin-001
vm-prd-tk-data-aes-001
nsg-prd-inf-cin-001
```

Catálago de Recursos

# Catálogo de Recursos por Trilha

> O nome exato de cada recurso. Troque **"001"** pela sua instância.

---

# TRILHA A — VMs (Jornada Inicial: 3 Máquinas Virtuais)

| Recurso Azure | Nome-Modelo | Tipo | Observação |
|---------------|-------------|------|------------|
| Resource Group | `rg-prd-tk-cin-001` | rg | Caixa que agrupa tudo da trilha Tickets. |
| Virtual Network | `vnet-prd-inf-cin-001` | vnet | Rede que conecta as 3 VMs. |
| Subnet — frontend | `snet-prd-inf-fend-cin-001` | snet | Sub-rede pública do frontend. |
| Subnet — backend | `snet-prd-inf-bend-cin-001` | snet | Sub-rede privada do backend. |
| Subnet — dados | `snet-prd-inf-data-aes-001` | snet | Sub-rede privada do banco. |
| NSG — app | `nsg-prd-inf-cin-001` | nsg | Libera portas 80/443 da Internet. |
| NSG — dados | `nsg-prd-inf-aes-001` | nsg | Libera porta 1433 apenas vinda do backend. |
| Public IP (front) | `pip-prd-tk-fend-aes-001` | pip | Único IP público; apenas o frontend possui acesso externo. |
| VM — Frontend | `vm-prd-tk-fend-cin-001` | vm | Hostname Windows ≤ 15 caracteres. Veja regras especiais. |
| VM — Backend | `vm-prd-tk-bend-cin-001` | vm | Hostname Windows ≤ 15 caracteres. |
| VM — Banco (SQL) | `vm-prd-tk-data-aes-001` | vm | Hostname Windows ≤ 15 caracteres. |

---

# Resumo da Trilha

## Recursos de Rede

```text
vnet-prd-inf-cin-001
snet-prd-inf-fend-cin-001
snet-prd-inf-bend-cin-001
snet-prd-inf-data-aes-001
nsg-prd-inf-cin-001
nsg-prd-inf-aes-001
```

## Recursos de Computação

```text
vm-prd-tk-fend-cin-001
vm-prd-tk-bend-cin-001
vm-prd-tk-data-aes-001
```

## Recursos de Conectividade

```text
pip-prd-tk-fend-aes-001
```

## Resource Group

```text
rg-prd-tk-cin-001
```

---

# Observações Importantes

## IP Público

Somente o frontend possui IP público.

Objetivo:

- Receber tráfego HTTP (80)
- Receber tráfego HTTPS (443)
- Ocultar backend e banco da Internet

---

## Backend

O backend não deve ser acessado diretamente da Internet.

Função:

- Hospedar API
- Processar regras de negócio
- Consultar banco SQL

---

## Banco de Dados

O SQL Server recebe conexões apenas da camada backend.

Porta utilizada:

```text
TCP 1433
```

---

## Hostnames Windows

O Windows possui limite de:

```text
15 caracteres
```

Portanto, o hostname da VM pode ser diferente do nome completo do recurso Azure.

Exemplo:

```text
Nome Azure:
vm-prd-tk-fend-cin-001

Hostname:
TKFEND001
```

---

# Arquitetura Resultante

```text
Internet
    |
    v
vm-prd-tk-fend-cin-001
    |
    v
vm-prd-tk-bend-cin-001
    |
    v
vm-prd-tk-data-aes-001
```

# Regras Especiais de Nomeação e Limites no Azure (Decore estas!)

Alguns recursos do Azure têm limites próprios e exigem atenção redobrada durante o provisionamento.

---

## 1. Tabela de Recursos, Limites e Diretrizes

| Recurso | Limite | O que fazer |
| :--- | :--- | :--- |
| **Nomes GLOBAIS**<br>*(web, st, sql, cosmos, func, swa, sigr)* | únicos no mundo | Cada aluno recebe uma instância única (`001`, `002`...) do instrutor — assim os nomes não colidem entre turmas. |
| **Storage Account** | 3–24 chars,<br>só letras+números,<br>**MINÚSCULAS** | **NÃO aceita hífen.** Junte tudo: `strdtkcin001`. Precisa ser único no mundo. |
| **Nome da VM (Windows)** | ≤ 15 caracteres<br>*(computer name)* | O nome do recurso pode ser longo, mas o HOSTNAME do Windows é ≤ 15. Use um curto, ex.: `vmtkfend01`. |
| **Azure SQL — servidor** | 1–63, minúsculas,<br>global único | `sql-prd-tk-cin-001`. Não pode começar/terminar com hífen. |
| **Cosmos DB (conta)** | 3–44, minúsculas,<br>global único | `cosmos-prd-bl-cin-001`. Sem caractere especial além de hífen. |
| **Web App / Function** | 2–60, global único | Vira uma URL: `https://web-prd-tk-fend-cin-001.azurewebsites.net` |
| **Resource Group** | 1–90 | Aceita hífen e é o mais flexível. Um por trilha. |
| **Número da instância** | 3 dígitos (`001`...) | Atribuído pelo instrutor. Use `002`, `003` p/ recursos repetidos. |

---

## 2. Boas Práticas Extras

* **Use tags além do nome:**
  * `Evento=CopaAzure2026`
  * `Aluno=<sufixo>`
  * `Trilha=Tickets/Bolão/VM`
* **Alerta de Orçamento:** Crie um alerta de orçamento no *Resource Group* para não levar susto na fatura.
* **Número de Instância:** Anote o seu número de instância — ele aparece em **TODOS** os recursos.
* **Economia de Créditos:** Apague os recursos ao terminar o laboratório para economizar créditos.

