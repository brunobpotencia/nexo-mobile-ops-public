#!/usr/bin/env bash
# dashboard.sh — gera o painel de segurança (PNG + JSON) do dono. Somente leitura.
# Uso: dashboard.sh            (coleta tudo e grava out/dashboard-latest.{png,json,html})
#      DASH_NO_ANDROID=1 dashboard.sh   (pula SSH no dispositivo Android)
# Nunca imprime segredos. Nunca roda netmon --rebaseline nem reaplica o firewall.
set -u -o pipefail
umask 022
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PYTHONIOENCODING=utf-8
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HERE/out"
exec 8>"$HERE/out/.lock"
if ! flock -w 300 8; then echo "[ERRO] outra geração do dashboard está rodando; abortado."; exit 1; fi
exec python3 "$HERE/dashboard.py" "$@"
