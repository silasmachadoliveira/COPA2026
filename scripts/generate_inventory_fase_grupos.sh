#!/bin/bash
# Gera inventory Ansible a partir dos outputs do Terraform (fase-grupos)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/env/fase-grupos"
INVENTORY="$SCRIPT_DIR/../ansible/inventory/fase-grupos.yml"

cd "$TF_DIR"

FEND_IP=$(terraform output -raw vm_frontend_public_ip)
BEND_IP=$(terraform output -raw vm_backend_public_ip)
DATA_IP=$(terraform output -raw vm_data_public_ip)

# Get private IPs via az cli
RG="rg-prd-tk-cin-001"
IP_BACK=$(az vm show -g "$RG" -n vm-prd-tk-bend-cin-001 --show-details --query privateIps -o tsv)
IP_DB=$(az vm show -g "$RG" -n vm-prd-tk-data-aes-001 --show-details --query privateIps -o tsv)

cat > "$INVENTORY" <<EOF
all:
  vars:
    sql_admin_password: "__SQL_PASSWORD__"
    ip_back: "${IP_BACK}"
    ip_db: "${IP_DB}"

  children:
    frontend:
      hosts:
        vm-fend:
          ansible_host: "${FEND_IP}"
          ansible_user: tftecadmin
          ansible_password: "__VM_PASSWORD__"
          ansible_connection: winrm
          ansible_winrm_transport: ntlm
          ansible_winrm_server_cert_validation: ignore
          ansible_port: 5986

    backend:
      hosts:
        vm-bend:
          ansible_host: "${BEND_IP}"
          ansible_user: tftecadmin
          ansible_password: "__VM_PASSWORD__"
          ansible_connection: winrm
          ansible_winrm_transport: ntlm
          ansible_winrm_server_cert_validation: ignore
          ansible_port: 5986

    data:
      hosts:
        vm-data:
          ansible_host: "${DATA_IP}"
          ansible_user: adminsql
          ansible_password: "__SQL_PASSWORD__"
          ansible_connection: winrm
          ansible_winrm_transport: ntlm
          ansible_winrm_server_cert_validation: ignore
          ansible_port: 5986
EOF

echo "Inventory gerado: $INVENTORY"
echo "  Frontend IP: $FEND_IP"
echo "  Backend IP:  $BEND_IP (private: $IP_BACK)"
echo "  Data IP:     $DATA_IP (private: $IP_DB)"
