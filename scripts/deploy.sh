#!/bin/bash
# Deploy completo: Terraform + Ansible
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$PROJECT_DIR/terraform/env/eliminatorias"
ANSIBLE_DIR="$PROJECT_DIR/ansible"

echo "=== [1/4] Terraform Apply ==="
cd "$TF_DIR"
terraform apply -auto-approve

echo ""
echo "=== [2/4] Gerando Inventory ==="
"$PROJECT_DIR/scripts/generate_inventory.sh"

echo ""
echo "=== [3/4] Aguardando VMs ficarem prontas ==="

WIN_IP=$(terraform output -raw vm_windows_public_ip)
LIN_IP=$(terraform output -raw vm_linux_public_ip)

# Espera SSH na Linux (timeout 5min)
echo -n "  Linux (SSH)..."
for i in $(seq 1 60); do
  if sshpass -p '__VM_PASSWORD__' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 admincopauser@"$LIN_IP" "echo ok" &>/dev/null; then
    echo " pronta!"
    break
  fi
  sleep 5
done

# Espera WinRM na Windows (timeout 8min)
echo -n "  Windows (WinRM)..."
for i in $(seq 1 96); do
  if curl -sk --connect-timeout 3 https://"$WIN_IP":5986/wsman &>/dev/null; then
    echo " pronta!"
    break
  fi
  sleep 5
done

echo ""
echo "=== [4/4] Ansible Playbook ==="
cd "$ANSIBLE_DIR"
ansible-playbook playbooks/site.yml

echo ""
echo "=== Deploy completo! ==="
echo "  Windows RDP: $WIN_IP:3389"
echo "  Linux SSH:   ssh admincopauser@$LIN_IP"
