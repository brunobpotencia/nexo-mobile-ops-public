#!/bin/bash
# nexo-common.sh — funções compartilhadas por nexo-up.sh e nexo-status.sh. Só leitura aqui.
OPS=${NEXO_OPS:-$HOME/nexo/ops}
SOCK=$HOME/.local/run/vpnd.sock
TS_STATEDIR=/var/lib/vpn
TS_TUN=vpn0
TS_LOG=$HOME/.local/log/vpnd.log
AGH_DIR=/opt/AdGuardHome
AGH_LOG=/var/log/adguardhome.log
AGH_PID=/run/adguardhome.pid
TS_IP=${VPN_IP_PC:-<VPN_IP_PC>}          # IP VPN do servidor (AdGuard faz bind nele)
GUARD_SCRIPT=$OPS/nexo-ts-guard.sh
GUARD_JUMP="-A INPUT -i vpn0 -j nexo-ts-guard"

ts() { vpn --socket="$SOCK" "$@"; }

ts_running()   { pgrep -x vpnd >/dev/null; }
ts_backend()   { ts status --json 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin).get("BackendState","?"))' 2>/dev/null || echo "sem-resposta"; }
ts_has_ip()    { ip -4 addr show "$TS_TUN" 2>/dev/null | grep -q "inet $TS_IP/"; }
agh_running()  { pgrep -x AdGuardHome >/dev/null; }
agh_listening(){ sudo ss -Hulpn 2>/dev/null | grep -q "$TS_IP:53 .*AdGuardHome"; }

# Regras esperadas da chain (formato iptables -S), por família.
guard_expected() {
  local icmp=icmp; [ "$1" = ip6tables ] && icmp=ipv6-icmp
  printf '%s\n' \
    "-N nexo-ts-guard" \
    "-A nexo-ts-guard -m conntrack --ctstate RELATED,ESTABLISHED -j RETURN" \
    "-A nexo-ts-guard -p udp -m udp --dport 53 -j RETURN" \
    "-A nexo-ts-guard -p tcp -m tcp --dport 53 -j RETURN" \
    "-A nexo-ts-guard -p tcp -m tcp --dport 3000 -j RETURN" \
    "-A nexo-ts-guard -p $icmp -j RETURN" \
    "-A nexo-ts-guard -j DROP"
}
guard_current()  { sudo "$1" -S nexo-ts-guard 2>/dev/null | grep -v '^#'; }
guard_rules_ok() { [ "$(guard_current "$1")" = "$(guard_expected "$1")" ]; }
input_first()    { sudo "$1" -S INPUT 2>/dev/null | grep '^-A' | head -1; }
guard_first_ok() { [ "$(input_first "$1")" = "$GUARD_JUMP" ]; }
guard_ok()       { guard_rules_ok "$1" && guard_first_ok "$1"; }
