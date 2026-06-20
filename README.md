# 🏆 Copa do Mundo Azure 2026 — Infrastructure as Code

Automação completa de infraestrutura Azure usando **Terraform + Ansible** para o evento Copa do Mundo Azure 2026 (TFTEC).

## 🏗️ Arquitetura

Duas fases implementadas com módulos reutilizáveis:

### Eliminatórias
- 1 VNet, 2 Subnets, 1 NSG
- VM Windows Server 2025 + VM Ubuntu 24.04
- Storage Account (Blob + File Share SMB)
- Mount automático via Ansible

### Fase de Grupos (FIFA 2026 Tickets — 3 camadas)
- 2 VNets em 2 regiões (Central India + Australia East)
- Global VNet Peering
- 3 VMs Windows Server 2022 (Frontend + Backend + SQL Server)
- IIS + ARR (Reverse Proxy) + Node.js + iisnode
- SQL Server 2022 Developer (imagem Marketplace)
- Certificado HTTPS wildcard (Let's Encrypt + certbot + Azure DNS)
- Hardening: remoção de IPs públicos + jump host

```
Internet (HTTPS)
       │
       ▼
vm-fend (IIS + ARR)     ← Central India
       │ proxy :80
       ▼
vm-bend (Node.js API)   ← Central India
       │ TCP 1433 (peering)
       ▼
vm-data (SQL Server)    ← Australia East
```

## 📁 Estrutura do Projeto

```
COPA2026/
├── terraform/
│   ├── modules/
│   │   ├── network/      # VNet + Subnets + NSG (genérico)
│   │   ├── compute/      # VM Windows/Linux + SQL IaaS
│   │   ├── storage/      # Storage Account + Containers + Shares
│   │   └── peering/      # Global VNet Peering
│   └── env/
│       ├── eliminatorias/
│       └── fase-grupos/
├── ansible/
│   ├── inventory/
│   └── playbooks/
│       ├── eliminatorias/
│       └── fase-grupos/
│           ├── configure_sql.yml       # Restore bacpac
│           ├── configure_backend.yml   # IIS + Node + API
│           └── configure_frontend.yml  # IIS + ARR + Web
└── scripts/
    ├── deploy.sh                  # Eliminatórias (one-click)
    ├── destroy.sh
    ├── deploy_fase_grupos.sh      # Fase Grupos (aulas 01-08)
    ├── destroy_fase_grupos.sh
    └── hardening_fase_grupos.sh   # Aula 08
```

## 🚀 Quick Start

### Pré-requisitos
- Azure CLI (`az login`)
- Terraform >= 1.5
- Ansible + pywinrm
- Certbot (snap) + certbot-dns-azure

### Deploy Fase de Grupos

```bash
# 1. Copiar e preencher variáveis
cp terraform/env/fase-grupos/terraform.tfvars.example terraform/env/fase-grupos/terraform.tfvars

# 2. Deploy completo (Terraform + Ansible + DNS + HTTPS + Hardening)
./scripts/deploy_fase_grupos.sh

# 3. Destroy
./scripts/destroy_fase_grupos.sh
```

## 🛠️ Tecnologias

| Ferramenta | Uso |
|---|---|
| Terraform | Provisionar infra (VMs, VNets, NSGs, Peering, SQL IaaS) |
| Ansible | Configurar VMs (IIS, Node, SQL restore, mount) |
| Azure CLI | DNS, NSG updates, provider registration |
| Certbot | Certificado HTTPS wildcard via Azure DNS |
| Bash | Orquestração (deploy/destroy scripts) |

## 📜 Certificações do Autor

- AWS Solutions Architect Associate
- AWS Developer Associate
- AWS Cloud Practitioner
- Microsoft AZ-104 (Azure Administrator)
- Microsoft AZ-900
- Microsoft SC-900

## 📝 Notas

- A DNS Zone (`rg-prd-dns-001`) é permanente e não é destruída no ciclo destroy/deploy
- O `my_ip` é atualizado automaticamente a cada deploy
- Os inventários Ansible são gerados automaticamente via Terraform outputs
- WinRM requer OpenSSL legacy provider para NTLM (MD4) — configurado nos scripts

## 📄 Licença

Projeto educacional — Copa do Mundo Azure 2026 (TFTEC Prime).
