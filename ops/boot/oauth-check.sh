#!/usr/bin/env bash
# Checagem de OAuth — roda no pico. Lista apps autorizados não documentados.
# Usa endpoint estável: GET /user/installations (apps instalados) e
# GET /applications (requer escopo admin:public_key). Sem escopo, sai limpo.
set -euo pipefail

if ! command -v gh &>/dev/null; then
  echo "gh não instalado"
  exit 0
fi

echo "=== GitHub installations ==="
gh api user/installations --jq '.installations[].app_slug' 2>/dev/null || echo "sem permissão"

echo "=== GitHub OAuth authorizations (admin) ==="
gh api authorizations --jq '.[].app.name' 2>/dev/null || echo "sem escopo admin"

echo "=== Google authorized apps (manual) ==="
echo "myaccount.google.com/permissions"
