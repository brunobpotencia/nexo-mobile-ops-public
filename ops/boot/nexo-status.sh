#!/bin/bash
# nexo-status.sh — status somente-leitura dos 3 serviços. Exit 0 = tudo OK, 1 = algo fora.
set -u
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/nexo-common.sh"
BAD=0
ok()  { echo "  OK    $*"; }
bad() { echo "  FALHA $*"; BAD=1; }

# 198.18.0.0/15 = faixa usada por interceptação DNS falsa (ex.: 198.18.0.1)
is_intercepted_dns() {
  case "$1" in
    198.18.*|198.19.*) return 0 ;;
    *) return 1 ;;
  esac
}

echo "nexo-status $(date '+%F %T %Z')"
echo "[1] vpnd"
ts_running && ok "processo (pid $(pgrep -x vpnd | tr '\n' ' '))" || bad "processo vpnd não roda"
B=$(ts_backend); [ "$B" = Running ] && ok "BackendState=$B" || bad "BackendState=$B"
ts_has_ip && ok "$TS_TUN com $TS_IP" || bad "$TS_TUN sem $TS_IP"
SU=$(ts debug prefs 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin).get("ShieldsUp"))' 2>/dev/null)
echo "  info  ShieldsUp=$SU (precisa ser False: com True o dispositivo Android perde o DNS do AdGuard)"
echo "[2] AdGuardHome"
agh_running && ok "processo (pid $(pgrep -x AdGuardHome | tr '\n' ' '))" || bad "processo AdGuardHome não roda"
agh_listening && ok "escuta $TS_IP:53" || bad "não escuta $TS_IP:53"
G=$(dig @"$TS_IP" google.com +short +time=3 +tries=1 2>/dev/null | grep -E '^[0-9.]+$' | grep -v '^0\.0\.0\.0$' | head -1)
if [ -z "$G" ]; then
  bad "não resolve google.com"
elif is_intercepted_dns "$G"; then
  bad "DNS interceptado/falso: google.com -> $G (faixa 198.18.0.0/15)"
else
  ok "resolve google.com -> $G"
fi
D=$(dig @"$TS_IP" doubleclick.net +short +time=3 +tries=1 2>/dev/null | head -1)
[ "$D" = "0.0.0.0" ] && ok "bloqueia doubleclick.net -> 0.0.0.0" || bad "doubleclick.net -> '${D:-sem resposta}' (esperado 0.0.0.0)"
echo "[3] nexo-ts-guard"
for T in iptables ip6tables; do
  guard_rules_ok "$T" && ok "$T chain nexo-ts-guard com as 7 regras esperadas" || bad "$T chain nexo-ts-guard ausente/divergente"
  guard_first_ok "$T" && ok "$T 1ª regra do INPUT = salto nexo-ts-guard" || bad "$T 1ª regra do INPUT = '$(input_first "$T")'"
done
[ $BAD = 0 ] && echo "RESULTADO: OK" || echo "RESULTADO: FALHA (rodar $DIR/nexo-up.sh)"
exit $BAD
