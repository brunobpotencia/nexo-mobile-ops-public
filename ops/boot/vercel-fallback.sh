#!/usr/bin/env bash
set -euo pipefail

# Fallback quando o conector Vercel não provisiona tools.
# Usa a CLI da Vercel se instalada; senão reporta e sai.

REPORT="${HOME}/.meridian/reports/vercel-fallback-$(date +%Y%m%d).log"
mkdir -p "$(dirname "$REPORT")"

echo "[$(date -Iseconds)] vercel-fallback: iniciando" >> "$REPORT"

if command -v vercel &>/dev/null; then
  vercel ls >> "$REPORT" 2>&1 || echo "[$(date -Iseconds)] FALHA: vercel ls retornou erro" >> "$REPORT"
else
  echo "[$(date -Iseconds)] AUSENTE: CLI vercel não instalada" >> "$REPORT"
  echo "[$(date -Iseconds)] AÇÃO: instalar com npm i -g vercel e autenticar" >> "$REPORT"
fi

echo "[$(date -Iseconds)] vercel-fallback: concluído" >> "$REPORT"
