#!/bin/bash
# Aula 08 - Hardening: remove IP público de vm-bend e vm-data
set -e

echo "=== Aula 08: Hardening - Removendo IPs públicos ==="

RG="rg-prd-tk-cin-001"

# Dissociar IP público da vm-bend
echo "  Removendo IP público da vm-bend..."
az network nic ip-config update \
  --resource-group "$RG" \
  --nic-name vm-prd-tk-bend-cin-001-nic \
  --name internal \
  --remove publicIpAddress \
  --output none 2>/dev/null

# Dissociar IP público da vm-data
echo "  Removendo IP público da vm-data..."
az network nic ip-config update \
  --resource-group "$RG" \
  --nic-name vm-prd-tk-data-aes-001-nic \
  --name internal \
  --remove publicIpAddress \
  --output none 2>/dev/null

# Deletar os IPs públicos órfãos
echo "  Deletando IPs públicos órfãos..."
az network public-ip delete --resource-group "$RG" --name pip-prd-tk-bend-cin-001 --output none 2>/dev/null
az network public-ip delete --resource-group "$RG" --name pip-prd-tk-data-aes-001 --output none 2>/dev/null

# Ajustar NSG - RDP do backend só aceita da subnet do front
echo "  Ajustando NSG (jump host)..."
az network nsg rule create \
  --resource-group "$RG" \
  --nsg-name nsg-prd-inf-cin-001 \
  --name allow-rdp-jump \
  --priority 115 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "10.20.1.0/24" \
  --destination-port-ranges 3389 \
  --output none

# Ajustar NSG banco - RDP só da VNet do app
az network nsg rule update \
  --resource-group "$RG" \
  --nsg-name nsg-prd-inf-aes-001 \
  --name allow-rdp \
  --source-address-prefixes "10.20.0.0/16" \
  --output none

echo ""
echo "=== Hardening completo! ==="
echo "  vm-bend e vm-data: sem IP público"
echo "  Acesso RDP: via jump host (vm-fend → IP privado)"
echo "  App continua acessível em: http://silasmachado.cloud"
