# nexo-mobile-ops

Playbook da ponte entre o dispositivo Android do Bruno e o computador do Nexo. Repositório privado, recriado limpo em 2026-10-04 (o anterior foi apagado e tinha um token exposto no histórico; não restaurar).

## Regras
- Nunca commitar segredos (tokens, senhas, `.cursor/mcp.json`, chaves privadas). Senhas ficam só no computador do Nexo, em arquivo 600.
- Não forkar repos oficiais na conta; só dar star.
- Mudanças no telefone (DNS, revogação, apagar máquina) só com autorização explícita do Bruno.
- Só registrar aqui o que foi verificado ao vivo, com data.

## Conteúdo
- `ops/boot/` — scripts de subida/status da ponte (`nexo-up.sh`, `nexo-status.sh`, `nexo-common.sh`)
- `ops/netmon/` — monitor de rede VPN/AdGuard/dispositivo Android (`netmon.sh`)
- `ops/dashboard/` — dashboard de auditoria (`dashboard.py`, `dashboard.sh`)
- `ops/vpn/` — ACL de exemplo (`acl-exemplo.hujson`)
- `guard/` — ARSENAL e checklists de higiene/segurança (sem baselines, logs ou segredos)

## Caminho escolhido
VPN sempre ligado + terminal Android com `sshd` (porta 8022) + Tasker e terminal Android:Tasker para automação local. USB/Mac só em emergência. Shizuku só se precisar de shell elevado. O dispositivo Android não tem root.

## Estado verificado em 2026-10-04

### Computador do Nexo (`nexo-box`, VPN <VPN_IP_PC>)
- VPN, conta `<EMAIL>`. Sem systemd: nada volta sozinho após reinício.
- Firewall `nexo-ts-guard` (iptables e ip6tables) na interface `vpn0`: libera 53 udp/tcp, 3000 tcp e ICMP; o resto é DROP. Reaplicar com `nexo-ts-guard.sh`.
- AdGuard Home v0.107.79 (sha256 conferido), escutando só em <VPN_IP_PC>:53 e :3000.
- DNS de saída: Cloudflare `1.1.1.1` e `1.0.0.1` (inclusive bootstrap). Quad9 foi trocado porque não respondia dali.
- Testes: `example.com` resolve; `doubleclick.net` volta `0.0.0.0`.

### dispositivo Android (`android-device`, VPN <VPN_IP_ANDROID> quando online)
- terminal Android instalado, `termux-auth` 1.5.0-1 com senha definida.
- SSH: `PasswordAuthentication no`; única chave em `~/.ssh/authorized_keys` é a ed25519 do computador do Nexo (`nexo_box_to_android`).
- Tasker, terminal Android:Tasker e App Launcher ainda não instalados.
- O dispositivo Android não aparece como máquina no Grok Bot; o acesso do Nexo é pelo VPN + SSH.

## Remontar a ponte

### No dispositivo Android
1. terminal Android (F-Droid) + `pkg install openssh termux-services termux-auth`.
2. VPN (Play Store), mesma conta, host `android-device`.
3. Colocar a chave pública do Nexo em `~/.ssh/authorized_keys`; `passwd`; `PasswordAuthentication no` em `$PREFIX/etc/ssh/sshd_config`.
4. `sv-enable sshd` (termux-services) para o `sshd` persistir na porta 8022.
5. Automação: Tasker (5.9.3+) + terminal Android:Tasker; dar ao Tasker a permissão "Run commands in terminal Android environment" e pôr `allow-external-apps=true` em `~/.termux/termux.properties`.

### No computador do Nexo
1. Subir `vpnd` e `vpn up` na mesma conta.
2. Reaplicar `nexo-ts-guard.sh`.
3. Subir o AdGuard Home e conferir os testes de DNS acima.
4. Testar: `ssh -i ~/.ssh/nexo_box_to_android -p 8022 -o BatchMode=yes <VPN_IP_ANDROID> 'echo ok'`.

## Segurança
- `sshd` só atrás da VPN; nunca expor 8022 na internet.
- Não conceder acessibilidade a apps desconhecidos.
- Pendências: `/opt/AdGuardHome` está 0755 (permcheck pede 0700); rotinas do Nexo Guard pausadas.

## Referências oficiais (star)
- https://github.com/termux/termux-app
- https://github.com/termux/termux-tasker
- https://github.com/termux/termux-api
- https://github.com/RikkaApps/Shizuku
- https://github.com/vpn/vpn-android
- https://github.com/OWASP/mastg
- https://github.com/OWASP/masvs
