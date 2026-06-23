#!/bin/bash
# Deploy completo Fase de Grupos (Aulas 01-08): Terraform + Ansible + DNS + HTTPS + Hardening
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$PROJECT_DIR/terraform/env/fase-grupos"
ANSIBLE_DIR="$PROJECT_DIR/ansible"
CERTS_DIR="$PROJECT_DIR/certs"

# Fix OpenSSL MD4 para NTLM/WinRM
export OPENSSL_CONF=/tmp/openssl-legacy.cnf
cat > "$OPENSSL_CONF" << 'EOF'
openssl_conf = openssl_init
[openssl_init]
providers = provider_sect
[provider_sect]
default = default_sect
legacy = legacy_sect
[default_sect]
activate = 1
[legacy_sect]
activate = 1
EOF

echo "=== [1/7] Aulas 01-02: Terraform Apply (Rede + VMs) ==="
cd "$TF_DIR"

# Atualizar my_ip automaticamente
MY_IP=$(curl -s ifconfig.me)
sed -i "s/^my_ip.*/my_ip              = \"$MY_IP\"/" terraform.tfvars
echo "  IP atual: $MY_IP"

terraform apply -auto-approve

echo ""
echo "=== [2/7] Gerando Inventory ==="
"$PROJECT_DIR/scripts/generate_inventory_fase_grupos.sh"

echo ""
echo "=== [3/7] Aguardando VMs ficarem prontas ==="

FEND_IP=$(terraform output -raw vm_frontend_public_ip)
BEND_IP=$(terraform output -raw vm_backend_public_ip)
DATA_IP=$(terraform output -raw vm_data_public_ip)

for VM_IP in $FEND_IP $BEND_IP $DATA_IP; do
  echo -n "  $VM_IP (WinRM)..."
  for i in $(seq 1 96); do
    if curl -sk --connect-timeout 3 https://"$VM_IP":5986/wsman &>/dev/null; then
      echo " pronta!"
      break
    fi
    if [ $i -eq 96 ]; then echo " TIMEOUT!"; exit 1; fi
    sleep 5
  done
done

echo ""
echo "=== [4/7] Aulas 03-05: Ansible (SQL + API + Frontend) ==="
cd "$ANSIBLE_DIR"
OPENSSL_CONF="$OPENSSL_CONF" ansible-playbook -i inventory/fase-grupos.yml playbooks/fase-grupos/site.yml

echo ""
echo "=== [5/7] Aula 06: Atualizando DNS ==="
unset OPENSSL_CONF
az network dns record-set a delete --resource-group rg-prd-dns-001 --zone-name silasmachado.cloud --name "copaazure2026" --yes 2>/dev/null || true
az network dns record-set a delete --resource-group rg-prd-dns-001 --zone-name silasmachado.cloud --name "@" --yes 2>/dev/null || true
az network dns record-set a delete --resource-group rg-prd-dns-001 --zone-name silasmachado.cloud --name "*" --yes 2>/dev/null || true
az network dns record-set a add-record --resource-group rg-prd-dns-001 --zone-name silasmachado.cloud --record-set-name "copaazure2026" --ipv4-address "$FEND_IP" --output none
az network dns record-set a add-record --resource-group rg-prd-dns-001 --zone-name silasmachado.cloud --record-set-name "@" --ipv4-address "$FEND_IP" --output none
az network dns record-set a add-record --resource-group rg-prd-dns-001 --zone-name silasmachado.cloud --record-set-name "*" --ipv4-address "$FEND_IP" --output none
echo "  DNS: copaazure2026.silasmachado.cloud → $FEND_IP"

echo ""
echo "=== [6/7] Aula 07: Certificado HTTPS ==="

# Verificar se certificado já existe e é válido (>7 dias)
CERT_VALID=false
if [ -f /etc/letsencrypt/live/silasmachado.cloud/fullchain.pem ]; then
  EXPIRY=$(sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/silasmachado.cloud/fullchain.pem | cut -d= -f2)
  EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
  NOW_EPOCH=$(date +%s)
  DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
  if [ "$DAYS_LEFT" -gt 7 ]; then
    echo "  Certificado válido (expira em ${DAYS_LEFT} dias). Reutilizando."
    CERT_VALID=true
  else
    echo "  Certificado expira em ${DAYS_LEFT} dias. Renovando..."
  fi
fi

if [ "$CERT_VALID" = false ]; then
  sudo certbot certonly \
    --authenticator dns-azure \
    --dns-azure-credentials "$CERTS_DIR/azure-dns-credentials.ini" \
    --dns-azure-propagation-seconds 30 \
    -d "*.silasmachado.cloud" \
    -d "silasmachado.cloud" \
    --email silas.machadoliveira@gmail.com \
    --agree-tos \
    --non-interactive
fi

# Converter para PFX (só se não existe ou cert foi renovado)
if [ "$CERT_VALID" = false ] || [ ! -f "$CERTS_DIR/silasmachado.cloud.pfx" ]; then
  sudo openssl pkcs12 -export \
    -out "$CERTS_DIR/silasmachado.cloud.pfx" \
    -inkey /etc/letsencrypt/live/silasmachado.cloud/privkey.pem \
    -in /etc/letsencrypt/live/silasmachado.cloud/fullchain.pem \
    -passout pass:__CERT_PASSWORD__
  sudo chown silas:silas "$CERTS_DIR/silasmachado.cloud.pfx"
  echo "  PFX gerado."
else
  echo "  PFX já existe. Reutilizando."
fi

# Copiar e configurar na vm-fend
export OPENSSL_CONF=/tmp/openssl-legacy.cnf
ansible vm-fend -i inventory/fase-grupos.yml -m win_copy -a "src=$CERTS_DIR/silasmachado.cloud.pfx dest=C:\\silasmachado.cloud.pfx"
ansible vm-fend -i inventory/fase-grupos.yml -m win_shell -a '
$pass = ConvertTo-SecureString -String "__CERT_PASSWORD__" -AsPlainText -Force
$cert = Import-PfxCertificate -FilePath "C:\silasmachado.cloud.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $pass
Import-Module WebAdministration
New-WebBinding -Name "FIFA2026-Web" -Protocol https -Port 443 -IPAddress "*" -ErrorAction SilentlyContinue
$existing = Get-ChildItem IIS:\SslBindings -ErrorAction SilentlyContinue | Where-Object { $_.Port -eq 443 }
if (-not $existing) { New-Item "IIS:\SslBindings\0.0.0.0!443" -Value $cert }
New-NetFirewallRule -DisplayName "HTTPS 443" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue
Write-Host "HTTPS OK"
'
echo "  Certificado instalado"

echo ""
echo "=== [7/7] Aula 08: Hardening ==="
unset OPENSSL_CONF
"$PROJECT_DIR/scripts/hardening_fase_grupos.sh"

echo ""
echo "=========================================="
echo "  DEPLOY FASE DE GRUPOS COMPLETO!"
echo "=========================================="
echo "  App:  https://copaazure2026.silasmachado.cloud"
echo "  RDP:  $FEND_IP (tftecadmin) → jump para 10.20.2.4 / 10.30.1.4"
echo "=========================================="
