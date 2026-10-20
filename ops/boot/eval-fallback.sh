#!/usr/bin/env bash
set -euo pipefail

# Fallback quando a leitura de destilados e priorities falha (REGRA-VERIFICACAO).

DEST_DIR="${HOME}/.meridian/destilados"
REPORT="${HOME}/.meridian/reports/eval-fallback-$(date +%Y%m%d).log"
mkdir -p "$(dirname "$REPORT")" "$(dirname "$DEST_DIR")"

echo "[$(date -Iseconds)] eval-fallback: iniciando" >> "$REPORT"

if [[ ! -d "$DEST_DIR" || -z "$(ls -A "$DEST_DIR" 2>/dev/null)" ]]; then
  echo "[$(date -Iseconds)] AUSENTE: pasta de destilados vazia ou inexistente" >> "$REPORT"
  echo "[$(date -Iseconds)] AÇÃO: criar pasta e aguardar primeiro ciclo do pico" >> "$REPORT"
  exit 0
fi

count=$(find "$DEST_DIR" -maxdepth 1 -type f | wc -l)
echo "[$(date -Iseconds)] OK: $count destilados encontrados" >> "$REPORT"

if [[ ! -f "${HOME}/.meridian/nexo-mobile-ops/priorities.md" && ! -f "${HOME}/.meridian/nexo-mobile-ops/state/priorities.md" ]]; then
  echo "[$(date -Iseconds)] AUSENTE: priorities.md não encontrado" >> "$REPORT"
fi

echo "[$(date -Iseconds)] eval-fallback: concluído" >> "$REPORT"
