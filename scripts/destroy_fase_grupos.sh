#!/bin/bash
# Destroy Fase de Grupos
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$PROJECT_DIR/terraform/env/fase-grupos"

echo "=== Terraform Destroy (Fase de Grupos) ==="
cd "$TF_DIR"
terraform destroy -auto-approve

echo ""
echo "=== Infra Fase de Grupos destruída! ==="
