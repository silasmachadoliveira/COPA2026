#!/bin/bash
# Destroy Modernização (PaaS)
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$PROJECT_DIR/terraform/env/modernizacao"

echo "=== Terraform Destroy (Modernização PaaS) ==="
cd "$TF_DIR"
terraform destroy -auto-approve

echo ""
echo "=== Infra PaaS destruída! ==="
echo "  DNS Zone (rg-prd-dns-001) permanece intacta."
