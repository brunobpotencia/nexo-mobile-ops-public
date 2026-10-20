#!/usr/bin/env bash
set -euo pipefail

# Snapshot de discos para a cap noite (REGRA-VERIFICACAO: falha vira relatório).

REPORT="${HOME}/.meridian/reports/disk-snapshot-$(date +%Y%m%d).log"
SNAP_DIR="${HOME}/.meridian/snapshots"
mkdir -p "$(dirname "$REPORT")" "$SNAP_DIR"

echo "[$(date -Iseconds)] disk-snapshot: iniciando" >> "$REPORT"

if command -v df &>/dev/null; then
  df -h >> "$SNAP_DIR/df-$(date +%Y%m%d).txt" 2>&1
  echo "[$(date -Iseconds)] OK: df capturado" >> "$REPORT"
else
  echo "[$(date -Iseconds)] AUSENTE: comando df não disponível" >> "$REPORT"
fi

if command -v du &>/dev/null; then
  du -sh "${HOME}/.meridian" >> "$SNAP_DIR/du-meridian-$(date +%Y%m%d).txt" 2>&1
  echo "[$(date -Iseconds)] OK: du do Meridian capturado" >> "$REPORT"
else
  echo "[$(date -Iseconds)] AUSENTE: comando du não disponível" >> "$REPORT"
fi

echo "[$(date -Iseconds)] disk-snapshot: concluído" >> "$REPORT"
