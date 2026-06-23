#!/bin/bash
# Deploy Modernização: VM → PaaS (App Service + Azure SQL)
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$PROJECT_DIR/terraform/env/modernizacao"
CERTS_DIR="$PROJECT_DIR/certs"
RG="rg-prd-tk-paas-cin-001"
BACPAC_URL="https://stotfteccopaazure.blob.core.windows.net/copa2026/FIFA2026Tickets.bacpac"

echo "=== [1/6] Terraform Apply (App Service + Azure SQL + Private Endpoint) ==="
cd "$TF_DIR"
terraform init -input=false

# Atualizar my_ip automaticamente
MY_IP=$(curl -s ifconfig.me)
if grep -q "^my_ip" terraform.tfvars 2>/dev/null; then
  sed -i "s/^my_ip.*/my_ip              = \"$MY_IP\"/" terraform.tfvars
else
  echo "my_ip              = \"$MY_IP\"" >> terraform.tfvars
fi

terraform apply -auto-approve

BEND_APP="app-prd-tk-bend-cin-sm001"
FEND_APP="app-prd-tk-fend-cin-sm001"
SQL_SERVER="sql-prd-tk-cin-sm001"
SQL_DB="FIFA2026Tickets"
SQL_PASS=$(grep sql_admin_password terraform.tfvars | cut -d'"' -f2)

echo ""
echo "=== [2/6] Importar bacpac no Azure SQL ==="
# Tentar import — se falhar com "contains user objects", banco já existe
BACPAC_FILE="/tmp/FIFA2026Tickets.bacpac"
if [ ! -f "$BACPAC_FILE" ]; then
  curl -sL "$BACPAC_URL" -o "$BACPAC_FILE"
fi
IMPORT_RESULT=$(sqlpackage /Action:Import \
  /TargetServerName:"$SQL_SERVER.database.windows.net" \
  /TargetDatabaseName:"$SQL_DB" \
  /TargetUser:"adminsql" \
  /TargetPassword:"$SQL_PASS" \
  /SourceFile:"$BACPAC_FILE" \
  /TargetTrustServerCertificate:True 2>&1) || true

if echo "$IMPORT_RESULT" | grep -q "Successfully imported"; then
  echo "  Bacpac importado com sucesso."
elif echo "$IMPORT_RESULT" | grep -q "contains one or more user objects"; then
  echo "  DB já contém dados. Pulando import."
else
  echo "  Resultado: $IMPORT_RESULT"
fi

echo ""
echo "=== [3/6] Deploy Backend (zip deploy) ==="
# Verificar se backend já está no ar
HEALTH=$(curl -s "https://$BEND_APP.azurewebsites.net/api/health" 2>/dev/null)
if echo "$HEALTH" | grep -q "ok"; then
  echo "  Backend já está no ar. Pulando deploy."
else
  # Verificar se deploy já está em andamento
  DEPLOY_STATUS=$(curl -s -u "\$${BEND_APP}:$(az webapp deployment list-publishing-credentials -g $RG -n $BEND_APP --query publishingPassword -o tsv)" "https://$BEND_APP.scm.azurewebsites.net/api/deployments/latest" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('complete',''))" 2>/dev/null || echo "")
  
  if [ "$DEPLOY_STATUS" = "False" ]; then
    echo "  Deploy em andamento. Aguardando..."
  elif [ "$DEPLOY_STATUS" = "True" ]; then
    echo "  Deploy anterior completou mas API não responde. Refazendo..."
    API_ZIP="/tmp/fifa2026-api.zip"
    if [ ! -f "$API_ZIP" ]; then
      curl -sL "https://stotfteccopaazure.blob.core.windows.net/copa2026/fifa2026-api.zip" -o "$API_ZIP"
    fi
    API_TEMP=$(mktemp -d)
    unzip -q "$API_ZIP" -d "$API_TEMP"
    if [ -d "$API_TEMP/fifa2026-api" ]; then API_DIR="$API_TEMP/fifa2026-api"; else API_DIR="$API_TEMP"; fi
    cd "$API_DIR" && zip -qr /tmp/fifa2026-api-flat.zip .
    cd "$PROJECT_DIR"
    az webapp deploy -g "$RG" -n "$BEND_APP" --src-path /tmp/fifa2026-api-flat.zip --type zip --timeout 600 || true
    rm -rf "$API_TEMP" /tmp/fifa2026-api-flat.zip
  else
    echo "  Nenhum deploy encontrado. Deployando..."
    API_ZIP="/tmp/fifa2026-api.zip"
    if [ ! -f "$API_ZIP" ]; then
      curl -sL "https://stotfteccopaazure.blob.core.windows.net/copa2026/fifa2026-api.zip" -o "$API_ZIP"
    fi
    API_TEMP=$(mktemp -d)
    unzip -q "$API_ZIP" -d "$API_TEMP"
    if [ -d "$API_TEMP/fifa2026-api" ]; then API_DIR="$API_TEMP/fifa2026-api"; else API_DIR="$API_TEMP"; fi
    cd "$API_DIR" && zip -qr /tmp/fifa2026-api-flat.zip .
    cd "$PROJECT_DIR"
    az webapp deploy -g "$RG" -n "$BEND_APP" --src-path /tmp/fifa2026-api-flat.zip --type zip --timeout 600 || true
    rm -rf "$API_TEMP" /tmp/fifa2026-api-flat.zip
  fi

  echo "  Aguardando backend ficar pronto..."
  for i in $(seq 1 60); do
    sleep 15
    HEALTH=$(curl -s "https://$BEND_APP.azurewebsites.net/api/health" 2>/dev/null)
    if echo "$HEALTH" | grep -q "ok"; then
      echo "  Backend no ar: $HEALTH"
      break
    fi
    if [ $((i % 4)) -eq 0 ]; then echo "  Tentativa $i/60 - aguardando..."; fi
    if [ $i -eq 60 ]; then echo "  TIMEOUT: backend não respondeu em 15min"; exit 1; fi
  done
fi

echo ""
echo "=== [4/6] Deploy Frontend (zip deploy) ==="
# Baixar zip do frontend
WEB_ZIP="/tmp/fifa2026-web.zip"
if [ ! -f "$WEB_ZIP" ]; then
  curl -sL "https://stotfteccopaazure.blob.core.windows.net/copa2026/fifa2026-web.zip" -o "$WEB_ZIP"
fi

# Ajustar web.config do frontend para apontar para o backend Web App
TEMP_DIR=$(mktemp -d)
unzip -q "$WEB_ZIP" -d "$TEMP_DIR"
# Detectar se extraiu em subpasta
if [ -d "$TEMP_DIR/fifa2026-web" ]; then
  FRONT_DIR="$TEMP_DIR/fifa2026-web"
else
  FRONT_DIR="$TEMP_DIR"
fi
sed -i "s|__BACKEND_URL__|https://$BEND_APP.azurewebsites.net|g" "$FRONT_DIR/web.config"
# Criar applicationHost.xdt para habilitar ARR proxy
cat > "$FRONT_DIR/applicationHost.xdt" << 'XDT'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <system.webServer>
    <proxy xdt:Transform="InsertIfMissing" enabled="true" preserveHostHeader="false" reverseRewriteHostInResponseHeaders="false" />
  </system.webServer>
</configuration>
XDT
cp "$FRONT_DIR/applicationHost.xdt" /tmp/applicationHost.xdt
cd "$FRONT_DIR" && zip -qr /tmp/fifa2026-web-paas.zip .
cd "$PROJECT_DIR"

az webapp deploy -g "$RG" -n "$FEND_APP" --src-path /tmp/fifa2026-web-paas.zip --type zip --timeout 300
rm -rf "$TEMP_DIR" /tmp/fifa2026-web-paas.zip

# Upload do applicationHost.xdt para site/ (habilita ARR proxy)
PASS=$(az webapp deployment list-publishing-credentials -g "$RG" -n "$FEND_APP" --query publishingPassword -o tsv)
curl -s -X PUT -u "\$${FEND_APP}:$PASS" \
  --data-binary @/tmp/applicationHost.xdt \
  -H "If-Match: *" \
  "https://$FEND_APP.scm.azurewebsites.net/api/vfs/site/applicationHost.xdt" > /dev/null
az webapp restart -g "$RG" -n "$FEND_APP" --output none
echo "  Frontend deployed"

echo ""
echo "=== [5/6] Atualizar DNS ==="
FEND_IP=$(dig +short "$FEND_APP.azurewebsites.net" | head -1)
az network dns record-set a delete --resource-group rg-prd-dns-001 --zone-name silasmachado.cloud --name "copaazure2026" --yes 2>/dev/null || true
az network dns record-set cname delete --resource-group rg-prd-dns-001 --zone-name silasmachado.cloud --name "copaazure2026" --yes 2>/dev/null || true
az network dns record-set cname create --resource-group rg-prd-dns-001 --zone-name silasmachado.cloud --name "copaazure2026" --ttl 300 --output none
az network dns record-set cname set-record --resource-group rg-prd-dns-001 --zone-name silasmachado.cloud --record-set-name "copaazure2026" --cname "$FEND_APP.azurewebsites.net" --output none
echo "  DNS: copaazure2026.silasmachado.cloud → $FEND_APP.azurewebsites.net"

echo ""
echo "=== [6/6] Configurar domínio customizado + HTTPS ==="
az webapp config hostname add -g "$RG" --webapp-name "$FEND_APP" --hostname "copaazure2026.silasmachado.cloud" --output none 2>/dev/null || true
# Criar certificado gerenciado e fazer binding
THUMBPRINT=$(az webapp config ssl create -g "$RG" -n "$FEND_APP" --hostname "copaazure2026.silasmachado.cloud" --query thumbprint -o tsv 2>/dev/null || echo "")
if [ -n "$THUMBPRINT" ]; then
  az webapp config ssl bind -g "$RG" -n "$FEND_APP" --certificate-thumbprint "$THUMBPRINT" --ssl-type SNI --output none 2>/dev/null || true
  echo "  HTTPS configurado (thumbprint: $THUMBPRINT)"
else
  echo "  AVISO: certificado não foi criado (DNS pode não ter propagado ainda)"
fi

# Ativar VNet Integration (após deploys, para não bloquear SCM)
echo "  Ativando VNet Integration no backend..."
az webapp vnet-integration add -g "$RG" -n "$BEND_APP" --vnet vnet-prd-paas-cin-001 --subnet snet-prd-appsvc-cin-001 --output none 2>/dev/null || true

echo ""
echo "=========================================="
echo "  DEPLOY MODERNIZAÇÃO COMPLETO!"
echo "=========================================="
echo "  App:      https://copaazure2026.silasmachado.cloud"
echo "  Backend:  https://$BEND_APP.azurewebsites.net/api/health"
echo "  Frontend: https://$FEND_APP.azurewebsites.net"
echo "  SQL:      $SQL_SERVER.database.windows.net"
echo ""
echo "  Custo: ~\$18/mês (vs ~\$90/mês em VMs)"
echo "  Sem VMs para gerenciar!"
echo "=========================================="
