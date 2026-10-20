# Boot do Nexo no box (sem systemd)

O PID 1 do box é `/tini` + `/pod-daemon`. **Não há systemd, cron rodando, nem rc.local.**
Nada sobe sozinho depois de um reboot. Estes scripts são o mecanismo oficial: **rodar à mão**.

## Scripts

| Script | Função |
|---|---|
| `nexo-up.sh` | Sobe (idempotente) na ordem: guard → vpnd → AdGuard → guard de novo |
| `nexo-up.sh --dry-run` | Mostra o que faria, sem mudar nada |
| `nexo-status.sh` | Status só-leitura dos 3 serviços + teste DNS (exit 0 = OK) |
| `nexo-common.sh` | Funções compartilhadas (não rodar direto) |
| `../nexo-ts-guard.sh` | Firewall: só 53/tcp+udp, 3000/tcp e ICMP na `vpn0` |

## Como usar após reboot do box

```bash
/home/box/agent-data/nexo/ops/boot/nexo-up.sh
/home/box/agent-data/nexo/ops/boot/nexo-status.sh
```

## Autostart — o que NÃO existe (verificado 2026-10-05)

- `pgrep -a cron` → vazio (o binário `/usr/bin/crontab` existe, mas o daemon cron **não roda** e ninguém inicia os `rc*.d` sob tini).
- `crontab -l` (box e root) → vazio. `@reboot` **não funcionaria** sem o daemon.
- Sem hook em `~/.bashrc` / `~/.profile` (bashrc só roda em shells interativas; as shells das ferramentas costumam ser não-interativas e retornam no início).
- Sem `/etc/rc.local`, sem unit systemd, sem supervisord nosso.

**Conclusão:** estes scripts **não** auto-rodam. Depois de qualquer reboot do box, alguém (Bruno ou um agente) precisa executar `nexo-up.sh`. Mentir que há autostart seria falso.

## O que o nexo-up sobe

1. `nexo-ts-guard` (pré-arma o firewall; a regra por nome de interface vale mesmo sem `vpn0`)
2. `vpnd --statedir=/var/lib/vpn --socket=/home/box/.local/run/vpnd.sock --tun=vpn0`
3. `/opt/AdGuardHome/AdGuardHome --pidfile /run/adguardhome.pid` (bind em `<VPN_IP_PC>`)
4. `nexo-ts-guard` de novo (o vpnd recria `ts-input` e pode empurrar o salto dele no topo)

## Como testar

```bash
/home/box/agent-data/nexo/ops/boot/nexo-status.sh
# Esperado: RESULTADO: OK nos 3 blocos; google.com resolve; doubleclick.net → 0.0.0.0
/home/box/agent-data/nexo/ops/boot/nexo-up.sh --dry-run
# Com tudo UP: só "já rodando" / "OK"; sem linhas [dry-run] de start
```

## Como reverter (scripts)

Apagar ou renomear esta pasta. Os scripts não alteram nada persistente além do que já está no kernel (iptables) e dos processos que eles sobem. Para derrubar os serviços:

```bash
sudo pkill -x AdGuardHome
sudo pkill -x vpnd
# firewall some no reboot; para limpar agora:
sudo iptables  -D INPUT -i vpn0 -j nexo-ts-guard; sudo iptables  -F nexo-ts-guard; sudo iptables  -X nexo-ts-guard
sudo ip6tables -D INPUT -i vpn0 -j nexo-ts-guard; sudo ip6tables -F nexo-ts-guard; sudo ip6tables -X nexo-ts-guard
```

## ShieldsUp — NÃO aplicado (2026-10-05)

Pedido original: `vpn set --shields-up=true`.

**Não foi ligado.** Motivos:

1. Auditoria geral (`2026-10-04-auditoria-geral.md` §): `ShieldsUp=false` — **"necessário para o AdGuard; não religar"**.
2. Docs VPN (KB 1072): shields-up bloqueia **todas** as conexões *inbound via VPN* (incluindo DNS 53 e UI 3000 do dispositivo Android). A descrição "bloqueia inbound não-VPN" está **incorreta**.
3. A ACL da rede VPN libera dispositivo Android → box nas portas 53/3000; com ShieldsUp=true essa ACL deixa de ter efeito no host (o cliente recusa o inbound).
4. sshd do terminal Android está down (Connection refused em 8022), então não dá para validar o impacto no dispositivo Android antes de ligar.

Backup das prefs atuais (ShieldsUp=false, CorpDNS=false):
`boot/backups/vpn-prefs.bak-*-antes-shields.json`

Se no futuro Bruno quiser ligar **mesmo assim**:

```bash
vpn --socket=/home/box/.local/run/vpnd.sock set --shields-up=true
vpn --socket=/home/box/.local/run/vpnd.sock debug prefs | python3 -c 'import json,sys;print(json.load(sys.stdin)["ShieldsUp"])'
# Reverter:
vpn --socket=/home/box/.local/run/vpnd.sock set --shields-up=false
```

**Atenção:** com ShieldsUp=true o dispositivo Android perde o DNS do AdGuard (Override DNS da rede VPN aponta para <VPN_IP_PC>) até reverter.

## NÃO aplicar ainda (pedido explícito)

- terminal Android DNS → <VPN_DNS>
- `accept-dns=true` no box

## Receitas aplicadas 2026-10-05 (~09:54 BRT)

### 1) nexo-status: DNS 198.18.0.0/15 = FALHA

Qualquer A-record de `google.com` em `198.18.*` / `198.19.*` conta como **DNS interceptado/falso**.

- Backup: `nexo-status.sh.bak-20261005-antes-198check`
- Função: `is_intercepted_dns`
- Teste real: RESULTADO OK com IP público
- Teste simulado: mock `198.18.0.1` → FALHA com mensagem clara
- `nexo-up.sh --dry-run` continua OK

### 2) AdGuard DNSSEC

- Preferir API: `POST /control/dns_config` com `{"dnssec_enabled":true}` (nesta versão o campo `enable_dnssec` no POST **não** altera; GET devolve `dnssec_enabled`)
- YAML passa a `enable_dnssec: true`
- Backups: `ops/adguard/AdGuardHome.yaml.bak-20261005-antes-dnssec` e `dns_info.bak-20261005-antes-dnssec.json`
- Teste: google/youtube/github/cloudflare → IPs reais; doubleclick → 0.0.0.0; `dnssec-failed.org` → SERVFAIL

### 3) termux-boot (dispositivo Android) — pendente no celular se SSH offline

- terminal Android instalado: **F-Droid** (`TERMUX_APK_RELEASE=F_DROID`, auditoria 04/10)
- terminal Android:Boot APK separado (`com.termux.boot`) — mesma fonte F-Droid; abrir uma vez
- Script oficial (README termux-boot): `~/.termux/boot/start-sshd` com `termux-wake-lock` + `sshd`
- `termux-wake-lock` é do terminal Android principal (termux-tools); **não** exige terminal Android:API
- Fonte: https://github.com/termux/termux-boot/blob/master/README.md

