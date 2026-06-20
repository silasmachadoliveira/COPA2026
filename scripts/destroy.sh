#!/bin/bash
# Destroy completo da infra
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$PROJECT_DIR/terraform/env/eliminatorias"

echo "=== Terraform Destroy ==="
cd "$TF_DIR"
terraform destroy -auto-approve

echo ""
echo "=== Infra destruída com sucesso! ==="
