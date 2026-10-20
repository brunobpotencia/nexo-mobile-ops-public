# Checklist — Rede pessoal (VPN / terminal Android sshd / wireless debugging)

Contexto: dispositivo Android; bridge VPN+terminal Android pode estar **desmontada**. Não afirmar estado remoto sem bridge/UI. Só higiene; sem instalar; sem Magisk/root; sem AdGuard VPN + VPN no mesmo aparelho. Sem Funnel/Serve/exit no dispositivo Android sem Bruno pedir.

## VPN — Access controls (quando houver / ao remontar)
- [ ] MFA no IdP da conta VPN
- [ ] Revisar Access controls: **não** deixar allow-all implícito (ausência de `acls`/`grants` = allow all — docs ACLs)
- [ ] Preferir **grants** com least privilege: PC/Mac (ou user) → dispositivo Android/`tag:android`: **tcp:8022** apenas
- [ ] Device approval ligado (novos devices = Needs approval)
- [ ] Key expiry **ligado** no telefone pessoal (default ~180d); tagged devices têm expiry off por default — revisar
- [ ] Lembrar: Android = **um VPN por vez** (VPN KB 1105)
- [ ] Não expor sshd/ADB na WAN; preferir só IP/MagicDNS VPN
- [ ] Se policy customizada: exit node exige `dst` **autogroup:internet** (não o IP do exit) — só se Bruno usar exit

## VPN — Keys / secrets (Keys + Trust credentials pages)
- [ ] Preferir auth key **one-off**; reusable só em secrets manager
- [ ] Preferir auth key **ephemeral** para workloads curtos (auto-remove offline)
- [ ] Nunca `--auth-key=<VPN_AUTHKEY>` literal no shell (history); usar env `TS_AUTH_KEY` / `$(cat)` + unset
- [ ] Revogar `<VPN_AUTHKEY>` / `<VPN_AUTHKEY>` / OAuth clients órfãos; revoke auth key ≠ remove machine
- [ ] Não commit de keys em git; copiar para password manager na geração
- [ ] Prefixo: `<VPN_AUTHKEY>` = auth, `<VPN_AUTHKEY>` = API

## Serve / Funnel (não ativar no dispositivo Android sem pedido)
- [ ] Serve = só rede VPN; Funnel = **internet pública** (portas 443/8443/10000)
- [ ] Backend em **localhost** se usar Serve (anti-spoof de headers VPN-User-*)
- [ ] Confirmar Funnel **off** se não for publicar nada
- [ ] Mesma porta não pode ser Serve e Funnel ao mesmo tempo


## Machine sharing (VPN Sharing — beta)
- [ ] Tratar invite link como **senha**; preferir email single-use; unused expiram ~30 dias
- [ ] Quarantine default: shared machine recebe, não inicia no rede VPN do receptor
- [ ] Evitar `src: ["*"]` em ACL se houver convidados — usar grupos / `autogroup:shared`
- [ ] Share de exit node exige checkbox explícito “Allow use as an exit node”
- [ ] Revogar shares no diálogo Machines → Share

## ACL policy language / tags / autoApprovers (nota 2026-09-19-15)
- [ ] Preferir **grants** (não ACL legada) para regras novas; grants+ACLs podem coexistir — migrar gradualmente ([grants-vs-acls](https://vpn.com/docs/reference/grants-vs-acls))
- [ ] Confirmar que policy tem grants/acls **explícitos** (ausência = allow-all)
- [ ] Grant least-privilege: `src` user/PC → `dst` dispositivo Android (user ou tag de serviço) + `ip: ["tcp:8022"]` apenas — **exemplo** na nota; NÃO VALIDADO no console
- [ ] **Não** aplicar tag em telefone/laptop de usuário (warning oficial Tags); tags = servidores/serviço
- [ ] Se usar `tag:*`: definir `tagOwners` mínimo; Owner/Admin/Network-admin implícitos em `[]`
- [ ] Revisar key expiry em devices tagged (default **off** após tag+auth; reabilitar no Machines se fizer sentido)
- [ ] Omitir ou estreitar `autoApprovers`; evitar `exitNode` amplo (`autogroup:member`); lembrar: edit de policy não aprova rotas pendentes retroativamente
- [ ] Evitar `src: ["*"]` se houver sharing; preferir e-mail / `autogroup:member` / grupos
- [ ] Adicionar `tests` no policy file (accept tcp:8022; deny outras portas sensíveis no destino)
- [ ] Device approval **ou** Rede VPN Lock — mutuamente exclusivos ([Rede VPN Lock limitations](https://vpn.com/docs/features/rede VPN-lock)); não ligar Lock sem plano de disablement secrets — **ops detalhada:** secção Rede VPN Lock / posture ops abaixo + nota `2026-09-20-28`
- [ ] Posture opcional: `srcPosture` só no src (ex. `node:tsVersion`); default attrs em todos os planos

## terminal Android sshd (só com bridge / sessão local)
- [ ] Login por chave em `~/.ssh/authorized_keys`; permissões 700/600 (`StrictModes`)
- [ ] Após testar chave: `PasswordAuthentication no` + `PermitEmptyPasswords no` + restart sshd
- [ ] `MaxAuthTries` ≤ 6; `MaxStartups` default ok no telefone
- [ ] Porta 8022 (default terminal Android); sem port-forward no roteador
- [ ] Considerar `AllowUsers` + `AllowTcpForwarding no` se shell basta
- [ ] `ListenAddress` só em IP VPN se validado estável — senão confiar na ACL mesh
- [ ] Não afirmar sshd ativo sem checar; Guard check de pacotes pausado até SSH voltar

### Lições verificadas (2026-10-04, dispositivo Android + laboratório no box)
- [ ] `PasswordAuthentication no` **não** desliga keyboard-interactive: com só essa linha, `sshd -T` dá `kbdinteractiveauthentication yes` (lab no box, OpenSSH 10.0p2 extraído do .deb, 11:24 BRT). Colocar também `KbdInteractiveAuthentication no`. No dispositivo Android (OpenSSH 10.5p1) as duas estão `no` no `sshd -T` (11:22:13 BRT).
- [ ] **Primeira ocorrência vence** no sshd_config: `AllowTcpForwarding no` + depois `yes` → efetivo `no`; `PasswordAuthentication yes` + depois `no` → efetivo `yes` (lab no box, 11:24 BRT). Antes de acrescentar linha no fim, `grep` se a opção já aparece antes (ou no `Include sshd_config.d/*.conf`, que vem na linha 13 do terminal Android).
- [ ] Antes de reiniciar o sshd: backup do sshd_config e do authorized_keys (o Nexo guardou cópia no box em `../nexo/ops/android-backups-20261004/`, sha256 igual ao live das 11:22) e `sshd -t` (lab: opção inválida → exit 255). Conferir efetivo com `sshd -T`.
- [ ] `sshd -t` **não** pega `ListenAddress` com IP ausente: lab com `ListenAddress <VPN_IP_ANDROID>` num host sem esse IP → `sshd -t` exit 0, mas o daemon falha com "Cannot assign requested address / Cannot bind any address". No telefone: só usar `ListenAddress <IP VPN>` com o VPN de pé, e ter sessão local no terminal Android para recuperar.
- [ ] `sshd -T` lê o **arquivo**; o daemon só muda após restart. Às 11:23:53 BRT o arquivo já tinha `AllowTcpForwarding no`, mas o sshd ainda era o PID 31290 do início da auditoria do Nexo. Às 11:25:18 já era o PID 4441 (reiniciado).
- [ ] `from="<VPN_IP_PC>",no-port-forwarding,no-agent-forwarding,no-X11-forwarding` na chave do box: visto no authorized_keys às 11:23:53 BRT (fingerprint SHA256:09Efk5…DBo inalterado). Login do box (<VPN_IP_PC>) **aceito** às 11:25:18, depois do restart. Recusa vindo de outro IP: **NÃO VALIDADO**, não testei.
- [ ] `ListenAddress <VPN_IP_ANDROID>` no dispositivo Android: `sshd -T` mostra só `<VPN_IP_ANDROID>:8022` às 11:25:18 BRT (às 11:23:53 ainda era 0.0.0.0/[::]). O SSH via <VPN_IP_ANDROID> funcionou. Que a 8022 não escuta mais em Wi-Fi/LTE: **NÃO VALIDADO**, porque sem root o Android bloqueia `ss`/`netstat`/`/proc/net`.
- [ ] Monitorar com `../playbooks/android-check.sh` (somente leitura); aceitar mudança só com OK do Bruno (`--accept-baseline`).
- [ ] Box sem systemd (PID 1 `tini`): vpnd/AdGuard não voltam sozinhos; `playbooks/start-vpnd.sh` + `../nexo/ops/nexo-ts-guard.sh`. Shields-up só bloqueia **entrada** no box; SSH de saída box→dispositivo Android funcionou às 11:22 (prefs ShieldsUp=false nesse momento).

## Wireless debugging vs USB
- [ ] Mesma **Wi‑Fi real** (não VPN VPN/Malwarebytes) para pairing
- [ ] Pairing código/QR uma vez; “Always allow on this network” só em Wi‑Fi doméstico de confiança
- [ ] Desligar wireless debugging quando não usar; revogar ADB se PC mudar/perder
- [ ] Sem Wi‑Fi: USB ADB (caminho preferido para auditoria)

## Roteador doméstico (CERT.br)
- [ ] Senha admin + Wi‑Fi fortes; SSID não padrão
- [ ] WPA3 ou WPA2/WPA3 (nunca WEP/WPA)
- [ ] Firmware / firewall; rede guest isolada para visitantes


## VPN DNS / Android client (nota 2026-09-20-21)
- [ ] Cliente: **Use VPN DNS** ligado se MagicDNS/split/Override forem necessários (`--accept-dns`); desligar só se quiser DNS 100% local ([manage-preferences](https://vpn.com/docs/features/client/manage-preferences))
- [ ] Admin: **Override DNS servers** só com nameserver alcançável (grant/ACL); senão telefone sem resolução ([dns-in-vpn](https://vpn.com/docs/reference/dns-in-vpn))
- [ ] Públicos (Cloudflare/Google/Quad9) no console → VPN usa **DoH** automaticamente
- [ ] Exit node: DNS local vira o do exit por default; “Use with exit node” por nameserver se precisar
- [ ] Android: **sem** shields-up / block incoming — superfície de entrada = grants/ACL, não toggle do app
- [ ] Não empilhar **Private DNS DoT** hostname estrito + VPN Override/MagicDNS sem teste (conflito de resolução; issue comunitária #4252 ≠ doc oficial)
- [ ] Continua: um VPN por vez (KB 1105); sem AdGuard VPN + VPN sem pedido

## Wireless debugging / ADB (refresh 2026-09-20-21)
- [ ] Mesma **Wi‑Fi real** (não VPN VPN) para pairing; Android 11+
- [ ] Pairing QR/código **uma vez**; Forget no peer **ou** Revoke adb debugging authorizations (todos os hosts)
- [ ] **Always allow on this network** só em Wi‑Fi doméstico de confiança (trusted network)
- [ ] RSA: unlock + aceite no diálogo antes de ADB
- [ ] Desligar Wireless debugging quando não usar; Quick settings tile ok para toggle
- [ ] dispositivo Android (Android 15): **sem** ADB Wi-Fi 2.0 (exige Android 17) — fluxo clássico
- [ ] Preferir USB para auditoria sensível; Revoke após troca/perda de PC
- [ ] Device mirroring Studio: canal adb no host não cifrado (privacy notice oficial)

## Rede VPN Lock / posture ops (nota 2026-09-20-28)
- [ ] Escolher **um** modelo de admissão: **device approval XOR Rede VPN Lock** (mutuamente exclusivos — docs Rede VPN Lock Limitations)
- [ ] **Não** ativar Rede VPN Lock sem Bruno pedir **e** plano de storage dos disablement secrets (password manager + cópia offline; opcional escrow VPN support)
- [ ] Se Lock: clientes ≥ v1.46.1; ≥2 signing nodes (máx 20); **Android ≠ signing node**
- [ ] Init: `vpn lock init` → guardar **10** secrets (basta 1 p/ disable); secrets só aparecem uma vez — perda sem escrow ⇒ rede VPN irrecuperável
- [ ] Pós-init: `vpn lock status` em cada nó — lista de TLKs idêntica (TOFU check)
- [ ] Novos nós: Sign machine / `vpn lock sign` **ou** pre-sign auth key (`lock sign $AUTH_KEY`) antes do join
- [ ] Compromisso de signer: `lock revoke-keys` multi-cosign — não confundir com `lock remove`
- [ ] Break-glass: `lock local-disable` = só aquele nó ignora Lock; não libera peers unsigned para o resto do rede VPN
- [ ] State dir configurado (evitar TKA só in-memory / re-fetch control plane no boot)
- [ ] Posture pessoal: default attrs (`node:os`/`tsVersion`/`tsReleaseTrack`) ok em todos os planos; geo/MDM/custom = planos pagos
- [ ] Se usar `srcPosture` / `defaultSrcPosture`: lembrar shared nodes + subnet router **bypass** posture
- [ ] `defaultSrcPosture` não é aditivo — grant com `srcPosture` próprio substitui o default
- [ ] Android: sem shields-up; entrada = grants/ACL (já na secção DNS/client)

## Fontes (checklist lastreado)
- notes/2026-09-20-28-vpn-rede VPN-lock-posture-ops.md
- notes/2026-09-16-10-rede-pessoal-vpn-sshd.md
- notes/2026-09-18-19-rede-pessoal-grants-authkeys-serve-exit.md
- notes/2026-09-18-19-rede-pessoal-authkeys-exit-serve-share.md
- https://vpn.com/docs/features/sharing
- https://vpn.com/docs/features/access-control/grants
- https://vpn.com/docs/features/access-control/acls
- https://vpn.com/docs/reference/best-practices/security
- https://vpn.com/docs/features/access-control/auth-keys
- https://vpn.com/docs/features/vpn-serve
- https://vpn.com/docs/features/vpn-funnel
- https://vpn.com/docs/features/exit-nodes
- https://man.openbsd.org/sshd_config
- notes/2026-09-19-15-vpn-acl-grants-tags-autoapprovers.md
- https://vpn.com/docs/features/tags
- https://vpn.com/docs/reference/grants-vs-acls
- https://vpn.com/docs/reference/syntax/policy-file
- https://vpn.com/docs/features/rede VPN-lock
- https://vpn.com/docs/features/device-posture
- https://vpn.com/docs/features/access-control/key-expiry

## CERT.br Redes — casa / Wi‑Fi / roteador (2026-09-21)

**Nota:** `notes/2026-09-21-11-certbr-redes.md`  
Fonte: [Redes](https://cartilha.cert.br/fasciculos/redes/fasciculo-redes.pdf) (ago/2024) · [índice](https://cartilha.cert.br/fasciculos/) (acesso **2026-09-21**)  
Sem alterar ISP/firmware sem Bruno pedir; sem afirmar SSID/modelo.

- [ ] **NOVO** Senha **admin** do roteador ≠ senha Wi‑Fi: trocar ambas vs fábrica; forte; sem PII/marca/MAC
- [ ] **NOVO** Senha Wi‑Fi: trocar se suspeita **ou** após furto de device que conectava
- [ ] **NOVO** SSID único: sem nome/casa/apto; sem marca/modelo/MAC/provedor
- [ ] **NOVO** Criptografia: WPA3 ou WPA2/WPA3 — **não** WEP/WPA
- [ ] **NOVO** Firmware atualizado (auto se possível; ISP pode exigir reboot periódico)
- [ ] **NOVO** Firewall de rede do roteador ativo
- [ ] **NOVO** Guest isolado (sem LAN/peers) + senha diferente para visitas/IoT
- [ ] **NOVO** Não compartilhar Wi‑Fi principal com terceiros; se precisar → guest
- [ ] Segregar segmentos (bridge ISP + regras entre geral/trabalho/IoT/filhos) — só se Bruno autorizar mudança física
- [ ] Controle parental no roteador **e** nos devices das crianças + conversa (Internet Segura)
- [ ] Cruzar VPN: grants ≠ higiene do roteador; guest/IoT preferível fora da rede VPN
- [ ] Continua: sem AdGuard VPN + VPN no mesmo aparelho sem pedido

## Private Space vs VPN/VPN (2026-09-20)
**Nota:** `notes/2026-09-20-16-android-private-space-vpn-vpn.md` · Help 15341885
- [ ] Saber: apps em Private Space **bypass** VpnService do device (VPN / AdGuard Local VPN)
- [ ] Apps que precisam do tunnel VPN → instalar **fora** do Private Space
- [ ] Continua válido: sem AdGuard VPN + VPN no mesmo aparelho sem Bruno pedir
- [ ] Android/dispositivo Android: presença Private Space = NÃO VALIDADO sem UI; bridge wipeada


## CERT.br Trabalho Remoto — rede / device (2026-09-21)

**Nota:** `notes/2026-09-21-13-certbr-trabalho-remoto.md` · fascículo Trabalho Remoto (junho/2023)  
Bruno hoje: estudo no Mac (sem employer tipado) — itens “empresa” só se/quando aplicável.

- [ ] **NOVO** Ideal: Wi‑Fi / segmento separado trabalho × doméstico (cruzar CERT.br Redes)
- [ ] **NOVO** VPN corporativa só com política + pedido; **nunca** empilhar com VPN no mesmo device sem Bruno pedir
- [ ] **NOVO** PC trabalho ≠ pessoal / família; prestador: máquina exclusiva
- [ ] **NOVO** Dados sensíveis: só canais aprovados; cifrar USB; copiar mínimo e apagar após
- [ ] **NOVO** Ambiente: sem call sensível em café; shoulder-surfing ao digitar; assistente de voz off em reunião
- [ ] Sem UI: **não** marcar

