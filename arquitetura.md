Resource Group
rg-copa-001
região India Central
Tag: Etapa – Eliminatorias

Vnet
vnet-copa-001
10.1.0.0/16
snet-copa-001
10.1.1.0/24
snet-copa-001
10.1.2.0/24
Tag: Etapa – Eliminatorias

NSG
Com acesso as duas subnets com acesso a RDP e SSH



Virtual Machine
vm-copa-001 – windows server 2025 datacenter – Standard B2als v2 - snet-copa-001 - IP Public – vm-copa-001-ip – disk Standard SSD 50 GB - Tag: Etapa – Eliminatorias (Como é ambiente de teste precisa desabilitar o firewall do windows)
vm-copa-001 – Ubuntu server 24.04 LTS - Standard B2als v2 - snet-copa-002 - IP Public – vm-copa-002-ip - disk Standard SSD 30 GB - Tag: Etapa – Eliminatorias


Storage Account
stcopaazuretftec26 – LRS – (Allow anabling anonymous access on individual containers) - Tag: Etapa – Eliminatorias
Criar dentro da Storage Account um container blob com o nome imagens
Criar dentro da Storage Account um fileshare smb com o nome files-copa, desmarcar o enable backup
Fazer o mount nas duas VMs
