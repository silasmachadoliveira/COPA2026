# 🏆 Copa do Mundo Azure 2026 — FIFA 2026 Tickets

## Informações do Ambiente — 16-Avos-Final (Modernização VM → PaaS)

---

## 🌐 Acesso à Aplicação

| Item | Valor |
|---|---|
| **URL** | https://copaazure2026.silasmachado.cloud |
| **Login Admin** | `admin@fifa2026.com` / `__APP_PASSWORD__` |
| **Certificado** | GeoTrust (App Service Managed Certificate) |
| **DNS Zone** | `silasmachado.cloud` → `rg-prd-dns-001` |
| **CNAME** | `copaazure2026` → `app-prd-tk-fend-cin-sm001.azurewebsites.net` |

---

## ☁️ Recursos Azure

### Resource Group

| Nome | Região |
|---|---|
| `rg-prd-tk-paas-cin-001` | Central India |

### App Service Plan

| Nome | OS | SKU |
|---|---|---|
| `asp-prd-tk-cin-001` | Windows | B1 |

### Web Apps

| Nome | Função | Runtime |
|---|---|---|
| `app-prd-tk-fend-cin-sm001` | Frontend (SPA + ARR proxy) | Node 20 / Windows IIS |
| `app-prd-tk-bend-cin-sm001` | Backend API (Express + iisnode) | Node 20 / Windows IIS |

### Azure SQL

| Nome | Tipo | SKU |
|---|---|---|
| `sql-prd-tk-cin-sm001` | Logical Server | — |
| `FIFA2026Tickets` | Database | Basic |

### Rede

| Nome | Tipo | CIDR |
|---|---|---|
| `vnet-prd-paas-cin-001` | VNet | 10.40.0.0/16 |
| `snet-prd-appsvc-cin-001` | Subnet (VNet Integration) | 10.40.1.0/24 |
| `snet-prd-pe-cin-001` | Subnet (Private Endpoints) | 10.40.2.0/24 |
| `pe-sql-prd-tk-cin-sm001` | Private Endpoint (SQL) | 10.40.2.x |
| `privatelink.database.windows.net` | Private DNS Zone | — |

---

## 🔐 Credenciais

| Recurso | Usuário | Senha |
|---|---|---|
| SQL Server (adminsql) | `adminsql` | `__SQL_PASSWORD__` |
| App Admin | `admin@fifa2026.com` | `__APP_PASSWORD__` |

---

## ⚙️ Configuração do Backend

### App Settings

| Variável | Valor |
|---|---|
| `JWT_SECRET` | `copa2026-tftec-jwt-secret-key-ultra-segura` |
| `JWT_EXPIRES_IN` | `7d` |
| `FRONTEND_URL` | `*` |
| `DB_SERVER` | `sql-prd-tk-cin-sm001.database.windows.net` |
| `DB_PORT` | `1433` |
| `DB_NAME` | `FIFA2026Tickets` |
| `DB_USER` | `adminsql` |
| `DB_PASSWORD` | `__SQL_PASSWORD__` |

### Connection String

| Nome | Tipo | Valor |
|---|---|---|
| `DefaultConnection` | SQLAzure | `Server=tcp:sql-prd-tk-cin-sm001.database.windows.net,1433;Database=FIFA2026Tickets;User Id=adminsql;Password=...;Encrypt=true;TrustServerCertificate=false` |

---

## 🗄️ Banco de Dados

Restaurado via `sqlpackage` a partir do `.bacpac` oficial do evento.

| Tabela | Registros |
|---|---|
| matches | 104 |
| stadiums | 17 |
| teams | 49 |
| users | 10.001 |
| ticket_categories | 312 |
| purchases | 100.001 |

---

## 🏗️ Arquitetura

```
Internet (HTTPS 443)
       │
       ▼
copaazure2026.silasmachado.cloud  (CNAME → Azure DNS)
       │
       ▼
app-prd-tk-fend-cin-sm001  (Web App Frontend)
  - React SPA
  - URL Rewrite + ARR proxy
  - applicationHost.xdt (ARR habilitado)
  - Certificado gerenciado gratuito
       │ /api/* → HTTPS
       ▼
app-prd-tk-bend-cin-sm001  (Web App Backend)
  - Node.js 20 + iisnode + Express
  - VNet Integration → snet-prd-appsvc-cin-001
       │ TCP 1433 (rede privada via Private Endpoint)
       ▼
sql-prd-tk-cin-sm001 / FIFA2026Tickets  (Azure SQL Database)
  - Private Endpoint: pe-sql-prd-tk-cin-sm001
  - Private DNS Zone: privatelink.database.windows.net
  - Banco nunca exposto à Internet
```

---

## 🔄 Fluxo de Deploy

```bash
# Deploy completo (Terraform + zip deploy + DNS + HTTPS)
deploy-modernizacao

# Destroy
destroy-modernizacao
```

### O que o deploy faz:
1. **Terraform** → App Service Plan, Web Apps, Azure SQL, VNet, Private Endpoint, Private DNS Zone
2. **Import bacpac** → `sqlpackage` restaura `FIFA2026Tickets` no Azure SQL
3. **Backend** → zip deploy (sem subpasta), aguarda `/api/health`
4. **Frontend** → zip deploy + `applicationHost.xdt` para `site/` + restart
5. **DNS** → CNAME `copaazure2026` → Web App frontend
6. **HTTPS** → certificado gerenciado + SNI binding

---

## 📊 Comparação VM vs PaaS

| Componente | Fase de Grupos (VMs) | Modernização (PaaS) |
|---|---|---|
| Frontend | vm-fend · IIS + ARR | Web App (iisnode gerenciado) |
| Backend | vm-bend · IIS + Node.js | Web App (iisnode gerenciado) |
| Banco | vm-data · SQL Server 2022 | Azure SQL Database |
| Rede | VNets + Peering + NSGs | VNet Integration + Private Endpoint |
| Certificado | certbot manual (90 dias) | App Service Managed (auto-renovável) |
| Acesso admin | RDP + jump host | Sem VMs para gerenciar |
| Patches OS | Manual | Gerenciado pela plataforma |
| Backup banco | Manual | Automático (PITR 7 dias) |
| Alta disponibilidade | Sem redundância | Nativa no PaaS |

---

## 🛠️ Automação

| Ferramenta | Uso |
|---|---|
| **Terraform** | Provisionar toda a infra PaaS |
| **az webapp deploy** | Zip deploy dos Web Apps |
| **sqlpackage** | Restore do bacpac no Azure SQL |
| **az webapp config ssl** | Certificado gerenciado |
| **Bash** | Orquestração (`deploy_modernizacao.sh`) |

---

## 📁 Repositório

**https://github.com/silasmachadoliveira/COPA2026**

```
terraform/env/modernizacao/   # Infra PaaS
scripts/deploy_modernizacao.sh
scripts/destroy_modernizacao.sh
```

---

## 📜 Tags Azure

```
Evento:   CopaAzure2026
Etapa:    Modernizacao
Trilha:   Tickets
Ambiente: 16-Avos-Final
```

---

*Silas Machado · Cloud & Infrastructure Specialist · Copa do Mundo Azure 2026 · TFTEC Prime*
