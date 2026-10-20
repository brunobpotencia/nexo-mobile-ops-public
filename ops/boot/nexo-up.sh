#!/bin/bash
# nexo-up.sh — sobe, em ordem, o que NÃO volta sozinho após reboot do box (sem systemd, PID1 tini):
#   0) nexo-ts-guard (pré-arma o firewall; regra por nome de interface vale mesmo antes do vpn0 existir)
#   1) vpnd  2) AdGuardHome  3) nexo-ts-guard de novo, garantindo a regra em 1º lugar no INPUT
# Idempotente: o que já está OK é pulado (não reflasha a chain se ela já está correta).
# Uso: nexo-up.sh            -> aplica
#      nexo-up.sh --dry-run  -> só mostra o que faria (não muda nada)
set -u
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/nexo-common.sh"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
LOG=$DIR/logs/nexo-up.log
log() { local m="[$(date '+%F %T %Z')] $*"; echo "$m"; [ $DRY = 1 ] || echo "$m" >> "$LOG"; }
run() { if [ $DRY = 1 ]; then echo "  [dry-run] $*"; else log "  exec: $*"; "$@"; fi; }

exec 9>/tmp/nexo-up.lock
flock -n 9 || { echo "outro nexo-up.sh já está rodando"; exit 1; }
[ $DRY = 1 ] && log "=== nexo-up.sh DRY-RUN ===" || log "=== nexo-up.sh inicio ==="

ensure_guard() {   # $1 = etapa
  for T in iptables ip6tables; do
    if guard_rules_ok "$T"; then log "[$1] $T: chain nexo-ts-guard OK"
    else log "[$1] $T: chain ausente/divergente -> aplicar $GUARD_SCRIPT"; run sudo "$GUARD_SCRIPT"; break; fi
  done
  for T in iptables ip6tables; do
    if guard_first_ok "$T"; then log "[$1] $T: salto nexo-ts-guard é a 1ª regra do INPUT"; continue; fi
    log "[$1] $T: salto nexo-ts-guard NÃO está em 1º (1ª atual: '$(input_first "$T")') -> mover para o topo"
    # insere no topo ANTES de remover duplicatas (sem janela sem proteção)
    run sudo "$T" -I INPUT 1 -i "$TS_TUN" -j nexo-ts-guard
    if [ $DRY = 0 ]; then
      while :; do
        n=$(sudo "$T" -S INPUT | grep '^-A' | grep -n -x -- "$GUARD_JUMP" | sed -n 2p | cut -d: -f1)
        [ -n "$n" ] || break; run sudo "$T" -D INPUT "$n"
      done
    fi
  done
}

# 0) pré-armar firewall
ensure_guard "0-guard-pre"

# 1) vpnd
if ts_running && ts status >/dev/null 2>&1; then
  log "[1-vpnd] já rodando (BackendState=$(ts_backend))"
else
  [ -x /usr/sbin/vpnd ] || { log "[1-vpnd] ERRO: /usr/sbin/vpnd não existe"; exit 2; }
  sudo test -f "$TS_STATEDIR/vpnd.state" || log "[1-vpnd] AVISO: $TS_STATEDIR/vpnd.state ausente — vai exigir 'vpn up' com login"
  run mkdir -p "$(dirname "$SOCK")" "$(dirname "$TS_LOG")"
  run sudo setsid sh -c "nohup /usr/sbin/vpnd --statedir=$TS_STATEDIR --socket=$SOCK --tun=$TS_TUN >>$TS_LOG 2>&1 &"
  if [ $DRY = 0 ]; then
    for i in $(seq 1 40); do ts status >/dev/null 2>&1 && break; sleep 0.5; done
    log "[1-vpnd] BackendState=$(ts_backend)"
  fi
fi
if [ $DRY = 0 ]; then
  for i in $(seq 1 60); do ts_has_ip && break; sleep 0.5; done
  ts_has_ip && log "[1-vpnd] $TS_TUN tem $TS_IP" || log "[1-vpnd] AVISO: $TS_TUN sem $TS_IP após 30s (AdGuard não vai conseguir bind)"
fi

# 2) AdGuardHome
if agh_running; then
  log "[2-adguard] já rodando (pid $(pgrep -x AdGuardHome | tr '\n' ' '))"
else
  sudo test -x "$AGH_DIR/AdGuardHome" || { log "[2-adguard] ERRO: $AGH_DIR/AdGuardHome não existe"; exit 3; }
  run sudo setsid sh -c "cd $AGH_DIR && nohup ./AdGuardHome --pidfile $AGH_PID >>$AGH_LOG 2>&1 &"
  if [ $DRY = 0 ]; then
    for i in $(seq 1 40); do agh_listening && break; sleep 0.5; done
    agh_listening && log "[2-adguard] escutando em $TS_IP:53" || log "[2-adguard] AVISO: não escuta $TS_IP:53 após 20s (ver $AGH_LOG)"
  fi
fi

# 3) firewall de novo (vpnd recria ts-input e pode inserir o salto dele no topo)
ensure_guard "3-guard-post"

[ $DRY = 1 ] && log "=== DRY-RUN fim (nada alterado) ===" || log "=== nexo-up.sh fim ==="
[ $DRY = 1 ] || "$DIR/nexo-status.sh"
