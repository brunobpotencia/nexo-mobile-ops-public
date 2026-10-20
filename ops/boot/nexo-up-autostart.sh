#!/bin/sh
# Autostart do nexo-up. Por padrao nao instala nada.
# Nao altera DNS, ACL, ShieldsUp, sshd, chaves nem resolv.conf.
# Nao reinicia a maquina.
set -eu
umask 077

NEXO_UP=/home/box/agent-data/nexo/ops/boot/nexo-up.sh
UNIT_NAME=nexo-up.service
UNIT_PATH=/etc/systemd/system/${UNIT_NAME}
STAMP=$(date +%Y%m%d-%H%M%S)

if [ "${1:-}" != "APPLY" ]; then
  echo "PARAR: sem APPLY. Nada instalado."
  echo "Uso: NEXO_RUN_USER=<usuario do box> sh $0 APPLY"
  exit 0
fi

if [ -z "${NEXO_RUN_USER:-}" ]; then
  echo "PARAR: NEXO_RUN_USER vazio. Unit de sistema rodaria como root. Nada instalado."
  exit 1
fi

if [ ! -f "$NEXO_UP" ]; then
  echo "PARAR: $NEXO_UP ausente. Nada instalado."
  exit 1
fi

if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
  if [ -f "$UNIT_PATH" ]; then
    cp -a "$UNIT_PATH" "${UNIT_PATH}.bak-${STAMP}"
    echo "backup: ${UNIT_PATH}.bak-${STAMP}"
  fi
  cat > "$UNIT_PATH" <<EOF
[Unit]
Description=Nexo up (AdGuard e nexo-ts-guard)
After=network-online.target vpnd.service
Wants=network-online.target

[Service]
Type=oneshot
User=${NEXO_RUN_USER}
ExecStart=${NEXO_UP}
RemainAfterExit=yes
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
EOF
  chmod 644 "$UNIT_PATH"
  systemctl daemon-reload
  systemctl enable "$UNIT_NAME"
  echo "systemd: enabled ${UNIT_NAME} como ${NEXO_RUN_USER}. Nao reiniciei. Nao dei start."
  exit 0
fi

if command -v crontab >/dev/null 2>&1; then
  BAK="${HOME:-/home/box}/crontab.bak-${STAMP}"
  crontab -l > "$BAK" 2>/dev/null || true
  chmod 600 "$BAK" 2>/dev/null || true
  echo "backup: $BAK"
  if crontab -l 2>/dev/null | grep -F "$NEXO_UP" >/dev/null 2>&1; then
    echo "cron: linha ja existe. Nao dupliquei."
    exit 0
  fi
  { crontab -l 2>/dev/null || true; echo "@reboot ${NEXO_UP}"; } | crontab -
  echo "cron: @reboot instalado no crontab do usuario atual. Nao reiniciei."
  exit 0
fi

echo "PARAR: sem systemd ativo e sem crontab. Nada instalado."
exit 2
