#!/usr/bin/env bash
# Validação mínima do Meridian. Sem dependências externas.
set -euo pipefail

fail() { echo "FAIL: $1"; exit 1; }

# 1. state.fonte existe e tem FONTE_ATUAL
grep -q '^FONTE_ATUAL=' state/state.fonte || fail "state.fonte sem FONTE_ATUAL"

# 2. fontes.md tem pelo menos uma URL https
grep -q 'https://' state/fontes.md || fail "fontes.md sem URL"

# 3. scripts boot executáveis em sh -n
for f in ops/boot/*.sh; do
  [ -f "$f" ] || continue
  bash -n "$f" || fail "sintaxe: $f"
done

# 4. netmon.sh sintaxe
bash -n ops/netmon/netmon.sh || fail "sintaxe: netmon.sh"

# 5. dashboard.py compila
python3 -m py_compile ops/dashboard/dashboard.py || fail "dashboard.py"

echo "OK: validação passou"
