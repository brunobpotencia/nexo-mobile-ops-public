#!/usr/bin/env bash
set -euo pipefail

# Fallback quando a leitura via API do GitHub falha (REGRA-VERIFICACAO).
# Tenta clonar o repo localmente e ler state.fonte, fontes.md, priorities.md.

REPO_DIR="${HOME}/.meridian/nexo-mobile-ops"
REPORT="${HOME}/.meridian/reports/pico-fallback-$(date +%Y%m%d).log"
mkdir -p "$(dirname "$REPORT")"

echo "[$(date -Iseconds)] pico-fallback: iniciando" >> "$REPORT"

if [[ -d "$REPO_DIR/.git" ]]; then
  git -C "$REPO_DIR" pull --ff-only >> "$REPORT" 2>&1 || true
else
  git clone --depth 1 https://github.com/<OWNER>/<REPO>.git "$REPO_DIR" >> "$REPORT" 2>&1 || {
    echo "[$(date -Iseconds)] FALHA: clone local impossível" >> "$REPORT"
    exit 1
  }
fi

for f in state.fonte fontes.md priorities.md; do
  if [[ -f "$REPO_DIR/$f" || -f "$REPO_DIR/state/$f" ]]; then
    echo "[$(date -Iseconds)] OK: $f legível localmente" >> "$REPORT"
  else
    echo "[$(date -Iseconds)] AUSENTE: $f não encontrado no clone" >> "$REPORT"
  fi
done

echo "[$(date -Iseconds)] pico-fallback: concluído" >> "$REPORT"
