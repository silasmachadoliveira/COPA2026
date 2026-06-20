#!/bin/bash
# Gera o inventory do Ansible a partir dos outputs do Terraform
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/env/eliminatorias"
INVENTORY="$SCRIPT_DIR/../ansible/inventory/hosts.yml"

cd "$TF_DIR"

WIN_IP=$(terraform output -raw vm_windows_public_ip)
LIN_IP=$(terraform output -raw vm_linux_public_ip)
ST_NAME=$(terraform output -raw storage_account_name)
ST_KEY=$(terraform output -raw storage_account_key)

cat > "$INVENTORY" <<EOF
all:
  vars:
    ansible_user: admincopauser
    ansible_password: "__VM_PASSWORD__"
    storage_account_name: ${ST_NAME}
    storage_account_key: "${ST_KEY}"
    file_share_name: files-copa

  children:
    windows:
      hosts:
        vm-copa-001:
          ansible_host: "${WIN_IP}"
          ansible_connection: winrm
          ansible_winrm_transport: ntlm
          ansible_winrm_server_cert_validation: ignore
          ansible_port: 5986

    linux:
      hosts:
        vm-copa-002:
          ansible_host: "${LIN_IP}"
          ansible_connection: ssh
          ansible_ssh_common_args: "-o StrictHostKeyChecking=no"
EOF

echo "Inventory gerado: $INVENTORY"
echo "  Windows IP: $WIN_IP"
echo "  Linux IP:   $LIN_IP"
