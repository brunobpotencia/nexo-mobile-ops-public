# Checklist — DNS / adblock (estudo → ação só com o dono)

Contexto: dispositivo Android pode usar VPN; bridge pode estar desmontada. Não afirmar estado remoto sem bridge/UI.
Fontes-base: notes `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>`, `<nota>` (AGH reconfirm).

## Antes de qualquer app VPN/DNS no dispositivo Android
- [ ] Confirmar com o dono se VPN no dispositivo Android continua desejável
- [ ] Lembrar: Android = **um VPN por vez** (VPN KB + AdGuard Local VPN)
- [ ] **Não** sugerir AdGuard VPN (nem outro VPN) + VPN sem pedido
- [ ] **Não** sugerir Magisk / `adguardcert` / Portmaster / Pi-hole no telefone sem pedido

## Caminhos sem conflito de VPN (preferíveis)
- [ ] Extensão AdGuard (ou uBO) no browser do PC — só browser
- [ ] **AdGuard Content Blocker** (Play) + Samsung Internet **ou** Yandex — só esses 2 browsers; **sem** Local VPN (manifest) → não XOR VPN — [KB overview](https://adguard.com/kb/adguard-content-blocker/overview/); nota `<nota>`
- [ ] DNS cloud: AdGuard DNS público (Default/Family/Non-filtering) ou Private — só resolver
- [ ] DNS cloud NextDNS (DoH/DoT / Private DNS Android) — só resolver; CLI `nextdns` no router/host só se o dono pedir ([wiki](https://github.com/nextdns/nextdns/wiki))
- [ ] Self-host filtro: **AdGuard Home** (UI), **Blocky** (YAML/Prometheus), **Pi-hole**, **Technitium**, **SmartDNS** (speed+SOA) ou **Gravity**/BeryJu (DNS+DHCP+cluster+Blocky) na **LAN/host** — dispositivos apontando DNS
- [ ] Self-host encrypt upstream: **dnscrypt-proxy** (DoH/DNSCrypt/ODoH) atrás do filtro — [wiki](https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Installation-linux)
- [ ] Self-host recursivo: **Unbound** atrás do filtro (DNSSEC/recurse); filtragem Unbound via **RPZ**, não UI de ads
- [ ] Revisar Private DNS / DoH do Chrome para não furar o DNS da rede sem querer

## Se self-host AdGuard Home (só se o dono pedir)
- [ ] Bind DNS em IP da LAN (evitar `0.0.0.0` / All interfaces sem ACL) — [Running securely](https://adguard-dns.io/kb/adguard-home/running-securely/) + [Configuration](https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration)
- [ ] Preencher Allowed clients (ClientID preferível em instância pública; ou CIDR/IP) — [Running securely](https://adguard-dns.io/kb/adguard-home/running-securely/) / [Clients](https://adguard-dns.io/kb/adguard-home/clients/)
- [ ] Auth na web UI (`users` não vazio); ratelimit plain DNS se houver exposição
- [ ] Encryption DoH/DoT/DoQ: domínio + `fullchain.pem`/`privkey.pem` (LE via Certbot/LEGO); Server name = hostname — [Encryption KB](https://adguard-dns.io/kb/adguard-home/encryption/)
- [ ] LAN-only: Encryption pública costuma ser desnecessária (KB: cifrar DNS “inside your own local network” não é o objetivo anti-ISP)
- [ ] Exposição pública: desligar plain DNS na Encryption **ou** `dns.bind_hosts` só loopback; Allowlist + rate limit — [Running securely](https://adguard-dns.io/kb/adguard-home/running-securely/)
- [ ] ClientID: DoH `https://host/dns-query/<id>`; DoT/DoQ `tls://<id>.host` / `quic://<id>.host` precisa wildcard **um nível** (`*.host` + `host`) — [Clients](https://adguard-dns.io/kb/adguard-home/clients/)
- [ ] Reverse proxy: `trusted_proxies` + `allow_unencrypted_doh` / `http.doh.insecure_enabled`; proxy `Host` + `X-Real-IP`/`X-Forwarded-For` (CF: `CF-Connecting-IP`) — [Encryption KB](https://adguard-dns.io/kb/adguard-home/encryption/)
- [ ] DNSCrypt servidor: só YAML (`port_dnscrypt` + `dnscrypt_config_file`); exige `tls.enabled: true` — [Encryption KB](https://adguard-dns.io/kb/adguard-home/encryption/)
- [ ] Dir/binário AGH: ownership root, sem write para outros; verificar `.sig` GPG `28645AC9776EC4C00BCE2AFC0FE641E7235E2EC6` — [Running securely](https://adguard-dns.io/kb/adguard-home/running-securely/)
- [ ] Regras preferir Adblock-style `||domain^` ([syntax KB](https://adguard-dns.io/kb/general/dns-filtering-syntax/))
- [ ] Upstream: Unbound local **ou** DoT/DoH públicos; bootstrap DNS se hostname
- [ ] Notes: `<nota>` (Encryption) + `<nota>` (Filtering/Clients/Rewrites/Querylog/Access) + **`<nota>`** (bind/Access) + **`<nota>`** (0.107.78/79 security / max_http_size) + **`<nota>`** (edge new UI / 0.108 channels) + **`<nota>`** (Unreleased pré-0.107.80 + KOR) + **`<nota>`** (edge → **1.0.0-a.69**; beta ainda b.90)

## AdGuard Home — bind / Access / rate / UI (estudo AAAA-MM-DD-12)
Fontes: [Running securely](https://adguard-dns.io/kb/adguard-home/running-securely/) · [Configuration](https://adguard-dns.io/kb/adguard-home/configuration/) · [Getting started](https://adguard-dns.io/kb/adguard-home/getting-started/) · [FAQ](https://adguard-dns.io/kb/adguard-home/faq/) (acesso **AAAA-MM-DD**)
- [ ] `dns.bind_hosts`: loopback (só host) / LAN+loopback (rede isolada) / `0.0.0.0` só com Access+rate (público) — Running securely
- [ ] Multi-IP: UI = 1 interface; YAML `bind_hosts` lista — Running securely note
- [ ] Access: Allowed clients = ClientID (preferido) ou IP/CIDR; `disallowed_clients` **ignorado** se allowlist preenchida — Configuration
- [ ] `blocked_hosts` fora de stats/query log (ex. CHAOS version.bind) — Configuration
- [ ] Plain DNS: off na Encryption **ou** `bind_hosts` só loopback; `serve_plain_dns: false` só com DoH/DoT/DoQ on — Running securely + Configuration
- [ ] `ratelimit` default 20; `refuse_any` on se exposto; whitelist de clientes conhecidos — Configuration
- [ ] `http.address` não em `0.0.0.0` sem necessidade; `users: []` = auth **off** — FAQ + Configuration
- [ ] Reverse proxy: `trusted_proxies` + unencrypted DoH só atrás do proxy — FAQ/Encryption
- [ ] Dir/bin `root:root` 755; verify GPG `28645AC9776EC4C00BCE2AFC0FE641E7235E2EC6` — Running securely
- [ ] Port 53 busy (Ubuntu): systemd-resolved stub → FAQ Fix / DNSStubListener=no
- [ ] Sem root: setcap NET_BIND/NET_RAW **ou** `dns.port` >1024 — Getting started
- [ ] LAN AGH + DNS clients = ok com VPN no dispositivo Android; sem Local VPN AdGuard no mesmo aparelho


## AdGuard Home — security residual 0.107.72/78/79 (estudo AAAA-MM-DD-17)
Fontes (acesso **AAAA-MM-DD** ~13:19): [v0.107.78](https://github.com/AdguardTeam/AdGuardHome/releases/tag/v0.107.78) · [v0.107.79](https://github.com/AdguardTeam/AdGuardHome/releases/tag/v0.107.79) · [v0.107.72](https://github.com/AdguardTeam/AdGuardHome/releases/tag/v0.107.72) · [Discussion #8473](https://github.com/AdguardTeam/AdGuardHome/discussions/8473). Nota: `<nota>`. Bind/Access: `<nota>`.
- [ ] Preferir canal **≥0.107.79** se DoQ / exposição / updates de security importam (DoQ exhaustion GHSA-w6v6-f44j-3rj2; Go 1.26.6)
- [ ] ≥0.107.78: DoH/DNSCrypt upstream validate; QUIC unbounded-read; JIGGLE resistance; H2C via HTTP/1.1 upgrade **off** (RFC 9113) — testar reverse proxy pós-upgrade
- [ ] `filtering.max_http_size`: default **256MB** (#8473); se filter update falhar em lista enorme, checar antes de culpar rede; “1 TB” desliga limite (release)
- [ ] Intervalo update filtros YAML: 0–8760 h (0.107.78)
- [ ] `strict_sni_check` **deprecated** (0.107.79) — não depender em config nova
- [ ] ≥0.107.72: TLS cert/key **auto-reload** (#3962); `ignored_enabled` querylog/statistics (schema 33)
- [ ] Sem install sem pedido o dono; LAN AGH ok com VPN no dispositivo Android; sem Local VPN AdGuard no mesmo aparelho


## AdGuard Home — Unreleased pré-0.107.80 (estudo AAAA-MM-DD-01)
Fontes (acesso **AAAA-MM-DD** ~12:43; reconfirm ~13:41 — tag `v0.107.80` ainda ausente, Hostlists max 71): [CHANGELOG master](https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/CHANGELOG.md) · [go.dev release — go1.26.8](https://go.dev/doc/devel/release) · [golang-announce](https://groups.google.com/g/golang-announce/c/QiTRm-HGGtI) · `git ls-remote` tags. Nota: `<nota>`. Security base: `<nota>`.
- [ ] **NOVO** Produção hoje: canal **release ≥0.107.79** — tag **`v0.107.80` ainda ausente** (Unreleased no CHANGELOG)
- [ ] **NOVO** Quando `v0.107.80` sair: preferir ≥ essa linha — Security Go **1.26.8** + fixes `#8565` / `#8572` (CHANGELOG)
- [ ] **NOVO** `#8565`: `log.enabled: false` podia deixar **legacy logger** ativo — revalidar após upgrade se política = logs off
- [ ] **NOVO** `#8572`: DHCP leases uncommitted após `DHCPDISCOVER` — só se AGH = DHCP da LAN
- [ ] **DELTA AAAA-MM-DD ~17:45** `version.json`: release **v0.107.79** · beta **v0.108.0-b.90** · edge **v1.0.0-a.69+27fbabe7** (edge **não** é mais tip 0.108-b) — não migrar edge; sem install sem pedido o dono — nota `<nota>`

## AdGuard Home — update ops / CDN / verify (estudo AAAA-MM-DD-08)
Fontes (acesso **AAAA-MM-DD** ~19:45): [CHANGELOG](https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/CHANGELOG.md) · [Getting started — Updating](https://adguard-dns.io/kb/adguard-home/getting-started/) · [FAQ version.json/manual](https://adguard-dns.io/kb/adguard-home/faq/) · [Running securely](https://adguard-dns.io/kb/adguard-home/running-securely/) · [Platforms](https://adguard-dns.io/kb/adguard-home/platforms/) · `version.json` dual host. Nota: `<nota>`.
- [ ] **NOVO** CHANGELOG v0.107.79: edge **switched** to new UI + versioning — tip `v1.0.0-a.*` esperado; não tratar como regressão
- [ ] **NOVO** Unreleased ainda lista `v0.107.80` approx **AAAA-MM-DD** no comentário HTML — tag **ausente** em AAAA-MM-DD; não afirmar shipped
- [ ] **NOVO** Update UI: *Update now* → exe+config em `backup/` (revert)
- [ ] **NOVO** Update CLI: `./AdGuardHome --update` (sem Web API)
- [ ] **NOVO** Docker / Home Assistant / Snapcraft: auto-update **off** — atualizar imagem/snap
- [ ] **NOVO** `Error: control/version.json` → ISP/servers; `--no-check-update` ou manual (FAQ)
- [ ] **NOVO** CDN: FAQ/Platforms = `static.adguard.com`; probes `version.json` também em `static.adtidy.org` (ambos 200 / v0.107.79) — path do **canal** importa
- [ ] Verify GPG `28645AC9776EC4C00BCE2AFC0FE641E7235E2EC6` + dir/bin `root:root` 755; reproducible builds (`build-release.sh`)
- [ ] Sem install/canal sem pedido o dono

## AdGuard Home — canais release / beta / edge + UI nova 0.108 (estudo AAAA-MM-DD-18)
**Reconfirm canais AAAA-MM-DD ~19:45** (`static.adtidy.org` + `static.adguard.com` + nota `<nota>`): release **v0.107.79**; beta **v0.108.0-b.90**; edge **v1.0.0-a.69+27fbabe7**; tag `v0.107.80` ausente (`git ls-remote`); Hostlists max 71 / count 64 / problematic 49/51/56/70. CHANGELOG v0.107.79 DOC: edge → new UI/versioning. (inalterado vs ~18:38)

**Reconfirm canais AAAA-MM-DD ~23:40** (nota `<nota>` OIDC session): release **v0.107.79**; beta **v0.108.0-b.90**; edge **v1.0.0-a.69+27fbabe7**; tag `v0.107.80` **404**; Hostlists max **71** / count **64** / problematic **49/51/56/70** — inalterado.
Fontes (acesso **AAAA-MM-DD** ~14:12): [Issue #8466](https://github.com/AdguardTeam/AdGuardHome/issues/8466) · [v0.107.79](https://github.com/AdguardTeam/AdGuardHome/releases/tag/v0.107.79) · [v0.108.0-b.90](https://github.com/AdguardTeam/AdGuardHome/releases/tag/v0.108.0-b.90) · [README Test unstable](https://github.com/AdguardTeam/AdGuardHome/blob/master/README.md) · [FAQ update](https://adguard-dns.io/kb/adguard-home/faq/). Nota: `<nota>`. Security: `<nota>`.
- [ ] Produção (só se o dono pedir): canal **release ≥0.107.79** — não migrar para edge só por UI nova
- [ ] `edge` (**AAAA-MM-DD**): `version.json` = **`v1.0.0-a.69+…`** (linha alpha 1.0.0-a); antes era tip `v0.108.0-b.N` — confirmar `static.adtidy.org/.../edge/version.json` antes de tipar; updates diários
- [ ] `beta` (~17:45): ainda **`v0.108.0-b.90`** (UI 0.108); #8466 — confirmar release notes; **não** assumir beta = edge 1.0.0-a
- [ ] Install: `install.sh -c beta` / `-c edge`; Docker `:beta` / `:edge`; Snap channels beta/edge (README)
- [ ] Troca de canal: backup `AdGuardHome.yaml` + `data/` (FAQ manual update); path FAQ `/release/` = **stable**
- [ ] Linha 0.108-b: schema 33 `ignored_enabled`; schema 34 `http.doh.insecure_enabled` (+ routes); durations com `d` (cuidado rollback)
- [ ] Sem install/canal sem pedido o dono; LAN AGH ok com VPN no dispositivo Android; sem Local VPN AdGuard no mesmo aparelho

**Reconfirm canais AAAA-MM-DD ~00:40 BRT** (nota `<nota>` edit/delete GAD session): release **v0.107.79**; beta **v0.108.0-b.90**; edge **v1.0.0-a.69+27fbabe7**; tag `v0.107.80` **ausente** (`git ls-remote`); Hostlists max **71** / count **64** / 49/51/56/70 agressivas Guard (`deprecated: false`) — inalterado. Path CDN = `adguardhome/`.

**Reconfirm canais AAAA-MM-DD ~01:40 BRT** (nota `<nota>` global advisories REST session): release **v0.107.79**; beta **v0.108.0-b.90**; edge **v1.0.0-a.69+27fbabe7**; tag `v0.107.80` **ausente** (`git ls-remote`); Hostlists max **71** / count **64** / 49/51/56/70 agressivas Guard (`deprecated: false`) — inalterado. Path CDN = `adguardhome/`.


## AdGuard Home — Filtering / Clients / Rewrites / Query log (estudo AAAA-MM-DD-11)
- [ ] Filters → DNS blocklists + General “Block domains using filters…”; checar allowlists/rewrites/custom se “não bloqueia” — [FAQ](https://adguard-dns.io/kb/adguard-home/faq/)
- [ ] Preferir Adblock-style `||domain^`; hosts-style em AGH responde com o IP da regra — [syntax KB](https://adguard-dns.io/kb/general/dns-filtering-syntax/)
- [ ] `blocking_mode`: `default` / `null_ip` / `nxdomain` / `refused` / `custom_ip` — [Configuration `filtering`](https://adguard-dns.io/kb/adguard-home/configuration/)
- [ ] `protection_enabled: false` **não** desliga `$dnsrewrite` nem `filtering.rewrites` / hosts SO — [Configuration](https://adguard-dns.io/kb/adguard-home/configuration/)
- [ ] Clientes persistentes: IP / CIDR / MAC (só se AGH=DHCP) / ClientID (DoH/DoT/DoQ) — [Clients](https://adguard-dns.io/kb/adguard-home/clients/)
- [ ] Per-client: filtering/parental/safebrowsing/upstreams/`ignore_querylog`/`ignore_statistics` — [Configuration `clients`](https://adguard-dns.io/kb/adguard-home/configuration/)
- [ ] Custom rules `$client=` usa **nome** persistente (não ClientID string); `$ctag=` com tags device_/os_/user_ — [syntax](https://adguard-dns.io/kb/general/dns-filtering-syntax/) + [Clients](https://adguard-dns.io/kb/adguard-home/clients/)
- [ ] DNS rewrites UI (`filtering.rewrites`: IP/CNAME/`A`/`AAAA`) **e/ou** `$dnsrewrite` (prioridade alta; keywords ALL CAPS) — [Configuration](https://adguard-dns.io/kb/adguard-home/configuration/) + [syntax `$dnsrewrite`](https://adguard-dns.io/kb/general/dns-filtering-syntax/)
- [ ] Query log: `enabled`/`file_enabled`/`interval` (1h–8760h)/`ignored`+`ignored_enabled`; stats espelho — [Configuration `querylog`](https://adguard-dns.io/kb/adguard-home/configuration/)
- [ ] Privacidade log: `dns.anonymize_client_ip`; por cliente ignore log/stats; `blocked_hosts` fora de log/stats — [Configuration](https://adguard-dns.io/kb/adguard-home/configuration/)
- [ ] Query log “Blocked by CNAME or IP” = anti CNAME cloaking (request+response) — [FAQ](https://adguard-dns.io/kb/adguard-home/faq/)
- [ ] Expectativa: DNS não bloqueia ads same-domain (YouTube/Twitch/social sponsored) — [README Known limitations](https://github.com/AdguardTeam/AdGuardHome#known-limitations)
- [ ] Stats FS: se `mmap` falhar, `--work-dir` ou symlink `stats.db`/`sessions.db` — [Getting started Limitations](https://adguard-dns.io/kb/adguard-home/getting-started/)
- [ ] Docker: `--network host` para IP real do cliente (não bridge 172.17) — [Docker KB](https://adguard-dns.io/kb/adguard-home/docker/)
- [ ] Notes: `<nota>`

## Se self-host Blocky (só se o dono pedir)
Nota: `<nota>` (+ overview `<nota>`). Fontes: [configuration](https://0xERR0R.github.io/blocky/latest/configuration/) · [installation](https://0xERR0R.github.io/blocky/latest/installation/) (acesso **AAAA-MM-DD**)
- [ ] Config YAML versionada (`blocky validate` + schema); denylists por `clientGroupsBlock`; listas HaGeZi formato **Asterisk**
- [ ] Porta 53: `NET_BIND_SERVICE` (+p sob bounding restrito) / root / porta ≥1024; Docker UID **100** + mounts graváveis
- [ ] Não expor :53 à WAN (open resolver); um sinkhole na LAN (Blocky **ou** AGH **ou** Pi-hole)
- [ ] **Evitar** `blockType: refused` — stubs/forwarders caem para outro DNS e furam o bloqueio; preferir `zeroIp` / `nxDomain`
- [ ] Manter `specialUseDomains` (default) — DDR `resolver.arpa` evita bypass mobile (RFC 9462)
- [ ] `rebindingProtection` se upstreams públicos; allowlist só split-horizon real (sem wildcards)
- [ ] `rateLimit` ≠ DDoS: allowlist LAN; fail2ban no WARN; firewall/crowdsec à parte
- [ ] `dnssec.validate` só se aceitar SERVFAIL em zonas Bogus + custo de queries; Unbound upstream continua opção
- [ ] VPN no host: `ports.freeBind: true` se bind no IP da rede VPN
- [ ] Env: `BLOCKY_CONFIG_FILE`; imagens `spx01/blocky` / `ghcr.io/0xerr0r/blocky`

## Se o dono pedir AdGuard for Android no dispositivo Android
- [ ] Explicitar trade-off: Local VPN **ou** VPN (não os dois) — Android = um VPN; Integrated mode só AdGuard VPN ([compat](https://adguard.com/kb/adguard-for-android/solving-problems/compatibility-issues/); [VPN 1105](https://vpn.com/kb/1105/other-vpns))
- [ ] Routing: Settings → Filtering → Network → **Local VPN** (único system-wide sem root); Automatic/Manual proxy = root ([settings](https://adguard.com/kb/adguard-for-android/features/settings/))
- [ ] Camadas: DNS protection **e/ou** Ad blocking (recomendação AG: DNS *além* de network, não no lugar) ([DNS filtering](https://adguard-dns.io/kb/general/dns-filtering/))
- [ ] HTTPS filtering: user CA (Android 11+ manual); system store = root — **não** Magisk/`adguardcert` sem pedido ([HTTPS](https://adguard.com/kb/general/https-filtering/what-is-https-filtering/); [rooted](https://adguard.com/kb/adguard-for-android/features/rooted/))
- [ ] Private DNS do SO: Off/Automatic se AdGuard gerencia DNS; strict (hostname) no Q+ pode furar DNS do AdGuard — `$network` só se o dono aceitar ([compat Private DNS](https://adguard.com/kb/adguard-for-android/solving-problems/compatibility-issues/))
- [ ] Low-level: *Filter secure DNS* se Chrome DoH furar ([low-level](https://adguard.com/kb/adguard-for-android/features/low-level-settings/))
- [ ] Always-on VPN no perfil AdGuard; Android: Autostart + Battery **No restrictions** ([background](https://adguard.com/kb/adguard-for-android/solving-problems/background-work/)); **≥4.14** corrige Always-on pós-reboot (#6084) — [releases](https://github.com/AdguardTeam/AdguardForAndroid/releases)
- [ ] Preferir canal **≥4.14.1** se já usar Local VPN (HTTP/2+3 filtering; DNS64; proxy+`system://`) — releases 4.14/4.14.1
- [ ] Integration AdGuard VPN: 4.13+ credentials; **ambos** apps atualizados (nota 4.13.1) — **ainda** XOR VPN
- [ ] Device admin: 4.14 lista AdGuard em Device administration (#5320) — só ativar se o dono pedir (cruzar Restricted settings)
- [ ] Não misturar com AdGuard VPN “só porque integra” se a meta é VPN
- [ ] Notas: `<nota>` + `<nota>` + **`<nota>`** + **`<nota>`** (OCSP KB vs CRLite)

## Browser (uBO / uBOL) — PC, sem VPN no dispositivo Android
- [ ] Preferir **uBlock Origin** full no Firefox (Easy = default) — [Blocking mode](https://github.com/gorhill/uBlock/wiki/Blocking-mode)
- [ ] No Chrome/Chromium MV3: **uBO Lite** (não esperar paridade com Medium/Hard) — [uBOL-home](https://github.com/uBlockOrigin/uBOL-home)
- [ ] Manter auto-update de filter lists; não empilhar listas Custom sem necessidade — [Filter lists](https://github.com/gorhill/uBlock/wiki/Dashboard:-Filter-lists)
- [ ] Advanced user / Medium-Hard só se o dono aceitar unbreak; `allow` dinâmico só excepcional — [Dynamic filtering](https://github.com/gorhill/uBlock/wiki/Dynamic-filtering:-quick-guide)
- [ ] Lembrar: DNS **não** substitui uBO para ads no mesmo domínio (YouTube/Twitch) — [AGH Known limitations](https://github.com/AdguardTeam/AdGuardHome#comparison-limitations)

## Secure DNS / Private DNS (não furar filtro de rede)
- [ ] Chrome: Privacy and security → Security → Use secure DNS — **current provider** ou off se o filtro for o DNS da LAN; custom = sem fallback unencrypted — [Chrome Help](https://support.google.com/chrome/answer/10468685)
- [ ] Android Private DNS: Off/Automatic se DHCP já aponta ao filtro; hostname strict só se for o **mesmo** serviço filtrante — [Android P DoT blog](https://android-developers.googleblog.com/2018/04/dns-over-tls-support-in-android-p.html)
- [ ] Teste: domínio bloqueado no sinkhole ainda resolve no Chrome? → Secure DNS/Private DNS furando


## Se self-host Pi-hole (só se o dono pedir; NÃO no dispositivo Android)
- [ ] IP estático / reserva DHCP no host — [Prerequisites](https://docs.pi-hole.net/main/prerequisites/)
- [ ] `dns.listeningMode` = `LOCAL` (default) ou `SINGLE`+firewall — **nunca** `ALL` sem firewall (open resolver) — [FTL config](https://docs.pi-hole.net/ftldns/configfile/)
- [ ] Docker bridge: `FTLCONF_dns_listeningMode=ALL` **só** com firewall host/LAN — [Docker](https://docs.pi-hole.net/docker/)
- [ ] Upstream: Unbound `127.0.0.1#5335` **ou** DoT/DoH via stub/dnscrypt — [guia Unbound](https://docs.pi-hole.net/guides/dns/unbound/)
- [ ] Antes de Unbound: testar root (`aa` sem `ra`; CHAOS `ATLAS`) — ISP que intercepta :53 quebra recurse
- [ ] Gravity: um Multi HaGeZi (ex. PRO) + opcional TIF; formato Adblock; `pihole -g` — [Gravity](https://docs.pi-hole.net/main/pihole-command/)
- [ ] Manter `mozillaCanary` / `iCloudPrivateRelay` / `designatedResolver` se a meta é forçar o sinkhole
- [ ] Password UI (+ TOTP opcional); `webserver.acl` LAN; **não** expor admin/DNS à WAN
- [ ] Detalhe operacional: secção **Pi-hole v6 FTL / Docker / Gravity** abaixo + nota `<nota>`

## Se self-host Technitium (só se o dono pedir; NÃO no dispositivo Android)
Nota: `<nota>` (+ overview `<nota>`). Fontes: [home](https://technitium.com/dns/) · [help](https://technitium.com/dns/help.html) · [compose](https://raw.githubusercontent.com/TechnitiumSoftware/DnsServer/master/docker-compose.yml) · [AdvancedBlocking](https://raw.githubusercontent.com/TechnitiumSoftware/DnsServer/master/Apps/AdvancedBlockingApp/README.md) · [Rebinding](https://raw.githubusercontent.com/TechnitiumSoftware/DnsServer/master/Apps/DnsRebindingProtectionApp/README.md) (acesso **AAAA-MM-DD**)
- [ ] Trocar senha default `admin`/`admin` (desliga auto-login) — [home Get Started](https://technitium.com/dns/)
- [ ] DNS Server Local End Points = IP LAN (não `0.0.0.0` se rede roteável) + firewall — [help §6](https://technitium.com/dns/help.html)
- [ ] Recursion: `AllowOnlyForPrivateNetworks` ou ACL; **não** `Allow` em VPS público — compose `DNS_SERVER_RECURSION*`
- [ ] Bloqueio: Settings > Blocking **ou** Advanced Blocking App — **um só** (App não lê listas built-in) — AdvancedBlocking README
- [ ] Listas: HaGeZi **Wildcard Domains** (built-in) ou hosts/AdBlock no App; Allowed Zone / `allowed` unbreak
- [ ] Forwarders DoT/DoH/DoQ se não recurse puro; liberar `:53` (systemd-resolved/dnsmasq)
- [ ] Rebinding App: `privateDomains` split-horizon; cuidado Block Page + IP privado — Rebinding README
- [ ] Detalhe operacional: secção **Technitium — recursion / Apps / Docker** abaixo + nota `<nota>`

## Se dnscrypt-proxy (host/LAN; só se o dono pedir)
- [ ] Um processo em :53; liberar concorrentes (`ss -lp 'sport = :domain'`) ([Installation-linux](https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Installation-linux))
- [ ] Testar resolve **antes** de mudar `/etc/resolv.conf`; depois `nameserver 127.0.0.1`
- [ ] Como upstream de Pi-hole/AGH/Blocky/Technitium **ou** sozinho — não segundo VPN no dispositivo Android
- [ ] Opcional: `[blocked_names]` / rebind `blocked-ips` ([Filters](https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Filters))

## Listas DNS (HaGeZi / StevenBlack)
- [ ] Escolher **um** Multi HaGeZi (PRO recomendado pelo autor) + TIF opcional — não empilhar Light+Pro+Ultimate ([hagezi README](https://github.com/hagezi/dns-blocklists))
- [ ] Formato certo: Adblock→Pi-hole/AGH; Wildcard Domains→Technitium/dnscrypt; RPZ→Unbound; Asterisk→Blocky
- [ ] Ultimate / Bypass DoH só com política explícita (quebra apps / Private DNS)
- [ ] StevenBlack hosts: baseline agregador; issues de conteúdo → fonte em `hosts/data/` ([StevenBlack](https://github.com/StevenBlack/hosts))

## Listas DNS — HaGeZi Native Android / Hostlists #60 (estudo AAAA-MM-DD-16)
Fontes: [hagezi README Native](https://github.com/hagezi/dns-blocklists#native); [filters.json #60](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json); [filter_60.txt](https://adguardteam.github.io/HostlistsRegistry/assets/filter_60.txt); [#2437](https://github.com/hagezi/dns-blocklists/issues/2437); [#2580](https://github.com/hagezi/dns-blocklists/issues/2580). Nota: `notes/<nota>.md`.
- [ ] **NOVO** Native Android = add-on OEM (telemetry/ads Android/Android) — **não** substitui Multi; Multi Light→Ultimate já embute native em graus ([README Native](https://github.com/hagezi/dns-blocklists#native))
- [ ] **NOVO** AGH: Hostlists **#60** (`<lista_do_fabricante>`, group Other, `purpose:other`, **sem** `problematic`) ou URL jsDelivr `adblock/native.fabricante.txt` ([filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json))
- [ ] **NOVO** Formato: Adblock→AGH/Pi-hole; Wildcard Domains→Technitium/dnscrypt; Asterisk→Blocky; RPZ→Unbound ([README formats](https://github.com/hagezi/dns-blocklists#formatguide))
- [ ] **NOVO** Se já usa Multi PRO: avaliar overlap antes de ligar #60; ao combinar Multi+native, unbreak pontual se feature quebrar ([README Native](https://github.com/hagezi/dns-blocklists#native))
- [ ] **NOVO** Teste pós-ativação: `<dominio-do-fabricante>` / `<dominio-do-fabricante>` bloqueados; `<dominio-do-fabricante>` / `<dominio-do-fabricante>` **não** na lista atual (snapshot AAAA-MM-DD) — [filter_60](https://adguardteam.github.io/HostlistsRegistry/assets/filter_60.txt)
- [ ] **NOVO** Unbreak histórico: cloud backup ↔ `<dominio-do-fabricante>` ([#2437](https://github.com/hagezi/dns-blocklists/issues/2437)); ROM/apps ↔ `<dominio-do-fabricante>` ([#2580](https://github.com/hagezi/dns-blocklists/issues/2580)); IoT Mi ↔ `ot.io.mi.com` ([#2437](https://github.com/hagezi/dns-blocklists/issues/2437)) — allowlist pontual + [Lookup](https://hagezi-mirror.dnsbunker.org/listseek.php)
- [ ] **NOVO** Contagem ~345 entries (header 11 Sep 2026) — muda a cada build; revalidar header
- [ ] **NOVO** **Não** esperar #60 no AdGuard Android `filters_apps` (só 1/3/5/34/53) — preferir AGH/cloud Private DNS ([filters_apps.json](https://raw.githubusercontent.com/AdguardTeam/HostlistsRegistry/main/assets/filters_apps.json))
- [ ] **NOVO** Cloud: AdGuard DNS Private lista Native Tracker Android ([README Online DNS](https://github.com/hagezi/dns-blocklists#dnsservices))
- [ ] **NOVO** Família Native registry: #60 Android, #61 Samsung, #63 Win/Office, #65 Vivo, #66 OPPO/Realme, #67 Apple — só ligar OEM do aparelho em uso
- [ ] **NOVO** Sem install no dispositivo Android / sem AdGuard VPN+VPN / sem Magisk; sem afirmar lista ligada sem evidência; bridge VPN pode estar down


## Listas DNS — HaGeZi Native Samsung #61 + Apple #67 (estudo AAAA-MM-DD-19)
Fontes: [hagezi README Native](https://github.com/hagezi/dns-blocklists#native); [CHEATSHEET Native](https://github.com/hagezi/dns-blocklists/blob/main/CHEATSHEET.md#cheat_native); [filters.json #61/#67](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json); [filter_61](https://adguardteam.github.io/HostlistsRegistry/assets/filter_61.txt); [filter_67](https://adguardteam.github.io/HostlistsRegistry/assets/filter_67.txt); [#3814](https://github.com/hagezi/dns-blocklists/issues/3814); [#7104](https://github.com/hagezi/dns-blocklists/issues/7104); [#10852](https://github.com/hagezi/dns-blocklists/issues/10852). Nota: `notes/<nota>.md`.
- [ ] **NOVO** Native Samsung/Apple = add-on OEM — **não** substitui Multi; Multi embute native em graus ([README Native](https://github.com/hagezi/dns-blocklists#native) + [CHEATSHEET](https://github.com/hagezi/dns-blocklists/blob/main/CHEATSHEET.md#inclusionmatrix))
- [ ] **NOVO** AGH: Hostlists **#61** Samsung / **#67** Apple (`purpose:other`, **sem** `problematic`) ou URL jsDelivr `adblock/native.samsung.txt` / `native.apple.txt`
- [ ] **NOVO** Contagens snapshot AAAA-MM-DD: Samsung **200** (header 11 Sep); Apple **108** (header 18 Sep) — revalidar header
- [ ] **NOVO** Lag Apple: upstream 18 Sep vs AG `filter_67` compile 1 Sep — preferir `@latest` se precisar fresco
- [ ] **NOVO** Teste Samsung: `nmetrics.samsung.com` / `dc.di.atlas.samsung.com` bloqueados; `account.samsung.com` / `galaxystore.samsung.com` **não** na lista
- [ ] **NOVO** Teste Apple: `xp.apple.com` / `metrics.icloud.com` / `iadsdk.apple.com` bloqueados; `mask.icloud.com` / `appleid.apple.com` / `mesu.apple.com` **não** na lista
- [ ] **NOVO** Unbreak Samsung DQA/acessórios: [#7104](https://github.com/hagezi/dns-blocklists/issues/7104) (`dls-udc.dqa…` marcado FP accessory pelo autor; hosts DQA ainda na lista)
- [ ] **NOVO** Private Relay / Bypass: **não** confundir native Apple com DoH Bypass; [#10852](https://github.com/hagezi/dns-blocklists/issues/10852) `mask.apple-dns.net` ≠ Private Relay
- [ ] **NOVO** **Não** em `filters_apps` (só 1/3/5/34/53) — AGH/cloud Private DNS ([filters_apps.json](https://raw.githubusercontent.com/AdguardTeam/HostlistsRegistry/main/assets/filters_apps.json))
- [ ] **NOVO** Cloud: AdGuard DNS Private Native Tracker Samsung + Apple ([README Online DNS](https://github.com/hagezi/dns-blocklists#dnsservices))
- [ ] **NOVO** dispositivo Android = Android (#60); **não** ligar #61/#67 no DNS do dispositivo Android sem aparelho Samsung/Apple na rede
- [ ] **NOVO** Sem install no dispositivo Android / sem AdGuard VPN+VPN / sem Magisk; bridge VPN pode estar down

## Listas DNS — HaGeZi Native Win/Office #63 + Vivo #65 + OPPO/Realme #66 (estudo AAAA-MM-DD-25)
Fontes: [hagezi README Native](https://github.com/hagezi/dns-blocklists#native); [CHEATSHEET Native](https://github.com/hagezi/dns-blocklists/blob/main/CHEATSHEET.md#cheat_native); [filters.json #63/#65/#66](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json); [filter_63](https://adguardteam.github.io/HostlistsRegistry/assets/filter_63.txt); [filter_65](https://adguardteam.github.io/HostlistsRegistry/assets/filter_65.txt); [filter_66](https://adguardteam.github.io/HostlistsRegistry/assets/filter_66.txt); [share/microsoft.txt](https://raw.githubusercontent.com/hagezi/dns-blocklists/main/share/microsoft.txt); [Edge Feedback and Diagnostics](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-security-endpoints). Nota: `notes/<nota>.md`.
- [ ] **NOVO** Native Win/Office/Vivo/OPPO = add-on OEM — **não** substitui Multi; Multi embute native em graus ([README Native](https://github.com/hagezi/dns-blocklists#native) + [CHEATSHEET](https://github.com/hagezi/dns-blocklists/blob/main/CHEATSHEET.md#inclusionmatrix))
- [ ] **NOVO** AGH: Hostlists **#63** Win/Office / **#65** Vivo / **#66** OPPO&Realme (`purpose:other`, **sem** `problematic`) ou URL jsDelivr `adblock/native.winoffice.txt` / `native.vivo.txt` / `native.oppo-realme.txt`
- [ ] **NOVO** Contagens snapshot AAAA-MM-DD: Win/Office **388** (header 18 Sep); Vivo **234** (18 Sep); OPPO **486** (17 Sep) — AG compile alinhado; revalidar header
- [ ] **NOVO** Teste Win: `telemetry.microsoft.com` / `vortex-win.data.microsoft.com` / `activity.windows.com` / `arc.msn.com` bloqueados; `login.microsoftonline.com` / `windowsupdate.microsoft.com` / `self.events.data.microsoft.com` / `settings-win.data.microsoft.com` **não** na lista #63
- [ ] **NOVO** Unbreak Win: [share/microsoft.txt](https://raw.githubusercontent.com/hagezi/dns-blocklists/main/share/microsoft.txt) — só ~9 hosts do share estão no native; maioria dos FPs (events.data, MDE v10c, settings-win) é de listas **mais agressivas**
- [ ] **NOVO** FP nativos no #63 a observar: `activity.windows.com` (Authenticator backup Android), `js.monitor.azure.com` (Quick Assist/RUM), `arc.msn.com` (Spotlight/Search)
- [ ] **NOVO** Teste Vivo: `adlog.vivo.com.cn` / `asia-adlog.vivoglobal.com` bloqueados; `www.vivo.com` / conta/loja **não** na lista; **sem** `share/vivo.txt`
- [ ] **NOVO** Teste OPPO: `conn1.coloros.com` / `classify-app-sg.allawnos.com` bloqueados; `www.oppo.com` / `account.realme.com` **não** na lista; **sem** `share/oppo*`
- [ ] **NOVO** **Não** esperar #63/#65/#66 no AdGuard Android `filters_apps` — preferir AGH/cloud ([filters_apps.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters_apps.json))
- [ ] **NOVO** Cloud: AdGuard DNS Private Native Tracker Windows/Office + Vivo + OPPO/Realme ([README Online DNS](https://github.com/hagezi/dns-blocklists#dnsservices))
- [ ] **NOVO** dispositivo Android = Android (#60); **não** ligar #65/#66 no DNS do dispositivo Android sem aparelho Vivo/OPPO; #63 só se houver Windows/Office na rede filtrada


## Listas DNS — HaGeZi Native Amazon + Huawei + TikTok + LG webOS + Roku (estudo AAAA-MM-DD-02)
Fontes: [hagezi README Native](https://github.com/hagezi/dns-blocklists#native); [CHEATSHEET Native](https://github.com/hagezi/dns-blocklists/blob/main/CHEATSHEET.md#cheat_native); [README AdGuardDNS](https://github.com/hagezi/dns-blocklists#adguarddns); [FAQ availablelists](https://github.com/hagezi/dns-blocklists/blob/main/FAQ.md#availablelists); [filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json) (live AAAA-MM-DD — **sem** filterId destas listas); jsDelivr `adblock/native.{amazon,huawei,tiktok,tiktok.extended,lgwebos,roku}.txt`. Nota: `notes/<nota>.md`.
- [ ] **NOVO** Native Amazon/Huawei/TikTok/LG/Roku = add-on OEM — **não** substitui Multi; Multi embute native em graus ([README Native](https://github.com/hagezi/dns-blocklists#native) + [CHEATSHEET](https://github.com/hagezi/dns-blocklists/blob/main/CHEATSHEET.md#inclusionmatrix))
- [ ] **NOVO** HostlistsRegistry: **sem** `filterId` (AAAA-MM-DD) — AGH só via **URL custom** jsDelivr/build mirror; **não** esperar id tipo #60
- [ ] **NOVO** Contagens snapshot AAAA-MM-DD: Amazon **371**; Huawei **135**; TikTok **436**; TikTok Extended **613**; LG webOS **221**; Roku **72** — revalidar header
- [ ] **NOVO** TikTok Extended = Aggressive (+179 regras vs normal); preferir `native.tiktok.txt` se admin limitado ([README Native](https://github.com/hagezi/dns-blocklists#native))
- [ ] **NOVO** Teste Amazon: `device-metrics-us.amazon.com` / `*.amazon-adsystem.com` bloqueados; `www.amazon.com` / `alexa.amazon.com` **não** na lista
- [ ] **NOVO** Teste Huawei: `metrics1.data.dbankcloud.cn` / `grs.dbankcloud.com` bloqueados; `oauth-login.cloud.huawei.com` / `push-api.cloud.huawei.com` **não** na lista
- [ ] **NOVO** Teste TikTok: `log.tiktokv.com` / `analytics.tiktok.com` bloqueados; `www.tiktok.com` / `api.tiktokv.com` **não** na lista
- [ ] **NOVO** Teste LG: `lgsmartad.com` / CDN `*-lgsmartad-com.aws-prd.net` bloqueados; `www.lg.com` **não** na lista
- [ ] **NOVO** Teste Roku: `ads.roku.com` / `analytics.roku.com` bloqueados; `www.roku.com` / `api.roku.com` **não** na lista
- [ ] **NOVO** Sem `share/amazon|huawei|tiktok.txt` (404 AAAA-MM-DD) — unbreak via [Lookup](https://hagezi-mirror.dnsbunker.org/listseek.php) + issues
- [ ] **NOVO** Cloud AdGuard DNS Private: Native Tracker **não** inclui Amazon/Huawei/TikTok/LG/Roku (só Apple/OPPO/Samsung/Vivo/Win·Office/Android) — [README AdGuardDNS](https://github.com/hagezi/dns-blocklists#adguarddns)
- [ ] **NOVO** Escopo o dono: dispositivo Android = Android (#60); ligar Amazon/TikTok/LG/Roku **só** se device/app correspondente na rede filtrada; Huawei baixa prioridade sem aparelho Huawei
- [ ] **NOVO** Não empilhar Multi Ultimate + estes natives “por garantia”

## Listas DNS — 1Hosts Lite/Xtra (estudo AAAA-MM-DD-14)
Fontes: [1Hosts README](https://github.com/badmojr/1Hosts); [#2808 Pro EOL](https://github.com/badmojr/1Hosts/issues/2808); [HostlistsRegistry filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json) (#24 Lite, #70 Xtra). Nota: `notes/<nota>.md`.
- [ ] **NOVO** Variantes ativas = **Lite** (baixo FP) **ou** **Xtra** (agressiva/Beta, mais FP) — não empilhar as duas ([README](https://github.com/badmojr/1Hosts))
- [ ] **NOVO** **Pro está EOL** — não usar `/Pro/`; migrar para Lite ou Xtra ([#2808](https://github.com/badmojr/1Hosts/issues/2808); URL Pro = 404)
- [ ] **NOVO** AGH: Hostlists **#24** (`1hosts_lite`) default seguro; **#70** (`1hosts_xtra`) tem tag `problematic` — só com unbreak ([filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json))
- [ ] **NOVO** Formato: `adblock.txt` → AGH/Pi-hole/uBO; `rpz.txt` → Unbound/Bind; `unbound.conf` / `dnsmasq.conf` / `hosts.txt` conforme cliente ([README](https://github.com/badmojr/1Hosts); [releases](https://github.com/badmojr/1Hosts/releases/tag/latest))
- [ ] **NOVO** Migração Pro→Xtra: trocar path `Lite`→`Xtra` no mesmo URL base (ex. `…/Lite/adblock.txt` → `…/Xtra/adblock.txt`) — tip oficial [#2808](https://github.com/badmojr/1Hosts/issues/2808)
- [ ] **NOVO** Não combinar 1Hosts Xtra (#70) + HaGeZi Ultimate (#49) (ambos problematic) — escolher uma base general
- [ ] **NOVO** Cloud opcional (estudo): ControlD `x-1hosts-lite` / NextDNS / AdGuard DNS / RethinkDNS DoT-DoH — quotas free NextDNS/AG DNS 300k/mês ([README](https://github.com/badmojr/1Hosts))
- [ ] **NOVO** Trick Lite@hosts + Xtra@DNS = tip do autor para debug FP; no Android com VPN, hosts via VPN local = conflito potencial — preferir só DNS LAN ([README](https://github.com/badmojr/1Hosts))
- [ ] **NOVO** Contagens no header do ficheiro mudam (snapshot AAAA-MM-DD: Lite ~102k / Xtra ~786k rules) — revalidar antes de dimensionar host
- [ ] **NOVO** Sem install no dispositivo Android / sem AdGuard VPN+VPN / sem Magisk; sem afirmar listas ligadas sem evidência


## Listas DNS — YouTube ads (kboghdady) / limites same-CDN (estudo AAAA-MM-DD-18)
Fontes: [kboghdady README](https://github.com/kboghdady/youTube_ads_4_pi-hole); [youtubelist.txt](https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/refs/heads/master/youtubelist.txt); [AGH Known limitations](https://github.com/AdguardTeam/AdGuardHome#comparison-limitations); [AGH FAQ limitations](https://adguard-dns.io/kb/adguard-home/faq/#limitations); [DNS filtering KB](https://adguard-dns.io/kb/general/dns-filtering/); [Hostlists filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json); [Free vs full YouTube Share](https://adguard.com/kb/adguard-for-android/features/free-vs-full/); [StevenBlack hosts s.youtube](https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts). Nota: `notes/<nota>.md`.
- [ ] **NOVO** Expectativa: DNS **não** elimina ads YouTube/Twitch same-domain — AGH Known limitations + FAQ; kboghdady README “doesn’t block every ad” / SSAI
- [ ] **NOVO** Se self-host (só se o dono pedir): AGH/Pi-hole **Option 1** URL custom `youtubelist.txt` — **não** está no HostlistsRegistry (custom only)
- [ ] **NOVO** Allow `s.youtube.com` se lista base (StevenBlack) o bloquear — README kboghdady + comentário StevenBlack hosts
- [ ] **NOVO** **Não** ligar `crowed_list.txt` / `--crowd` sem plano de unbreak (crowd unfiltered)
- [ ] **NOVO** Option 2 script: default defensivo `--no-share` / `SHARE_LOGS=false` (Google Form share de googlevideo 24h)
- [ ] **NOVO** **Não** usar Hostlists **#37 No Google** como anti-ad YouTube (bloqueia Google/YouTube inteiro)
- [ ] **NOVO** `youtube_safe_search.txt` = parental `$dnsrewrite` restrictmoderate — **≠** lista de ads
- [ ] **NOVO** Camada browser: uBO (ou AdGuard BE); Android opcional Share→AdGuard player (**free**) — Free vs full KB
- [ ] **NOVO** Bypass: apps com DoH/DNS hardcoded furam a lista — README kboghdady; mitigar DNS rede ≠ app filtering
- [ ] **NOVO** Snapshot lista ~15 886 domains (AAAA-MM-DD; maioria `googlevideo.com`) — revalidar `wc -l` antes de dimensionar
- [ ] **NOVO** Sem install no dispositivo Android / sem AdGuard VPN+VPN / sem Magisk; sem afirmar lista ligada sem evidência


## Se self-host SmartDNS (só se o dono pedir; NÃO no dispositivo Android)
Nota: `<nota>` (+ overview `<nota>`). Fontes: [basic](https://pymumu.github.io/smartdns/en/config/basic-config/) · [upstream](https://pymumu.github.io/smartdns/en/config/upstream-dns/) · [ad-block](https://pymumu.github.io/smartdns/en/config/ad-block/) · [dualstack](https://pymumu.github.io/smartdns/en/config/dualstack/) · [FAQ](https://pymumu.github.io/smartdns/en/faq/) (acesso **AAAA-MM-DD**)
- [ ] Papel: speed-check + dual-stack + SOA adblock — **não** UI tipo AGH/Pi-hole; um sinkhole :53 na LAN (SmartDNS **ou** AGH/Blocky/Pi-hole)
- [ ] `bind` em IP/LAN (não WAN aberta); sem `server*` lê `/etc/resolv.conf` (evitar loop)
- [ ] Upstream preferir `server-tls`/`server-https` (+ `-tls-host-verify` / `-host-ip` / `-spki-pin`); **evitar** `-k`
- [ ] **Privacy:** default = fan-out a **todos** os upstreams — usar `-exclude-default-group` + `nameserver /domínio/grupo` para split (FAQ)
- [ ] ~≤10 upstreams (FAQ best practice); DoQ/DoH3 = poucos públicos
- [ ] Adblock: `address /domínio/#` (SOA) ou `domain-set` + `address /domain-set:ad/#`; uma lista comunidade via `conf-file` — não empilhar sem unbreak
- [ ] iOS 14+: se HTTPS RR quebrar block → `force-qtype-SOA 65` (FAQ)
- [ ] Dual-stack: `dualstack-ip-selection yes` (+ threshold); off por bind/domínio se preciso; `force-AAAA-SOA` se quiser matar AAAA
- [ ] Second DNS: `bind :porta -group … -no-rule-addr -no-speed-check` se SmartDNS atrás de outro filtro
- [ ] HaGeZi→SmartDNS conf = **NÃO VALIDADO**; preferir anti-AD/adrules/neodevhost oficiais da doc
- [ ] Sem install no dispositivo Android; sem AdGuard VPN+VPN; testar `dig @<smartdns>`

## Se self-host Gravity / BeryJu (só se o dono pedir; NÃO no dispositivo Android)
Fontes: [install](https://gravity.beryju.io/docs/install/), [zones](https://gravity.beryju.io/docs/dns/zones/), [cluster](https://gravity.beryju.io/docs/install/cluster/), [DHCP](https://gravity.beryju.io/docs/dhcp/), [API](https://gravity.beryju.io/docs/api/). Notas: overview `<nota>` + **`<nota>`**.
- [ ] Docker: `ghcr.io/beryju/gravity:stable`, `network_mode: host`, hostname único, volume `/data` — install
- [ ] Trocar admin (creds no `docker compose logs` / `ADMIN_PASSWORD`); UI `:8008` **não** na WAN
- [ ] Zona `.`: `forward_blocky` (Blocky in-process — sem container Blocky) + `to` upstream — zones + #1336
- [ ] **Não** aceitar defaults empilhados (AdAway+oisd+StevenBlack+Firebog+SDNSFilter); preferir 1 Multi HaGeZi (+TIF) + allowlist
- [ ] Cluster: nós **ímpares**; 2 nós ≠ HA etcd (DNS pode seguir via `memory`/`forward_*`) — cluster
- [ ] DHCP: um por L2; `dns.zone` para A/PTR auto; ou `BOOTSTRAP_ROLES` sem dhcp se router DHCP fica
- [ ] API: Bearer token; sock `/var/run/gravity.sock` **sem auth**; Sentry off
- [ ] Preferir se DNS+DHCP+cluster; se só ads leve → Blocky/Pi-hole/AGH/SmartDNS
- [ ] Detalhe: secção **Gravity BeryJu residual** abaixo + nota `<nota>`

## Se Portmaster no desktop Linux/Windows (só se o dono pedir; NÃO no dispositivo Android)
Fontes: [README](https://github.com/safing/portmaster), [Privacy Filter](https://wiki.safing.io/en/Portmaster/Architecture/PrivacyFilter), [DNS guide](https://docs.safing.io/portmaster/guides/dns-configuration), [Secure DNS](https://docs.safing.io/portmaster/architecture/core-service/secure-dns/), [Feature](https://wiki.safing.io/en/Portmaster/Feature), [Install Linux](https://wiki.safing.io/en/Portmaster/Install/Linux), [VPN compat](https://docs.safing.io/portmaster/install/status/vpn-compatibility), [VPN](https://wiki.safing.io/en/Portmaster/App/Compatibility/Software/VPN), [intel-data sources.yml](https://github.com/safing/intel-data/blob/master/lists/sources.yml), [Download](https://safing.io/download/). Notas: `<nota>` + **`<nota>`**.
- [ ] Confirmar OS: **só** Windows/Linux oficiais — **sem** macOS no [download](https://safing.io/download/) (MacBook o dono = fora)
- [ ] Kernel ≥5.7; install .deb/.rpm/AUR `portmaster-bin`; **não** auto-start pós-install; UI AppIndicator + WebKitGTK 4.1; systemd `Conflicts=firewalld` — [Linux wiki](https://wiki.safing.io/en/Portmaster/Install/Linux)
- [ ] Papel: host firewall+DNS ≠ sinkhole de rede (AGH/Blocky); ≠ uBO browser; ≠ SPN/VPN
- [ ] DNS: `dot://IP:853?verify=...` (IP **obrigatório**; `blockedif=empty|refused|zeroip`) — [DNS guide](https://docs.safing.io/portmaster/guides/dns-configuration)
- [ ] Não dá para desligar Secure DNS; lista vazia = ainda passa pelo Portmaster → DNS do SO — [DNS guide Disabling](https://docs.safing.io/portmaster/guides/dns-configuration)
- [ ] Privacy Filter ordem: special → tipo (inbound/P2P) → escopo → rules → connectivity → bypass → filter lists → heuristics → default — [Privacy Filter](https://wiki.safing.io/en/Portmaster/Architecture/PrivacyFilter)
- [ ] Se VPN no mesmo PC: MagicDNS + nameserver `192.0.2.1`; DNS Portmaster `dns://<VPN_DNS>?search=<suffix>&search-only`; perfil vpn: off Force Block Incoming, Incoming `Allow *`, off Block Secure DNS Bypassing; Split-DNS TS não resolve via PM — [VPN wiki](https://wiki.safing.io/en/Portmaster/App/Compatibility/Software/VPN)
- [ ] Filter lists: defaults Free ok; evitar BIGT/EXPERIMENTS/CRL-OCSP sem pedido; Unbreak se quebrar sites; fontes em [sources.yml](https://github.com/safing/intel-data/blob/master/lists/sources.yml)
- [ ] Bypass prevention bloqueia DoH/DoT externos (lista securedns*) — desligar só se necessário (ex. VPN)
- [ ] Tiers: Free = Filter+DNS+Monitor; Plus = History/Bandwidth; Pro = SPN — [Feature](https://wiki.safing.io/en/Portmaster/Feature); **não** assinar SPN sem o dono pedir
- [ ] VPN DNS-leak tests = falso positivo comum — [VPN Compatibility](https://docs.safing.io/portmaster/install/status/vpn-compatibility)
- [ ] Não instalar no telefone; não AdGuard VPN+VPN; não Magisk sem pedido

## AdGuard FiltersRegistry vs HostlistsRegistry (estudo AAAA-MM-DD-21)
Fontes: [HostlistsRegistry README](https://github.com/AdguardTeam/HostlistsRegistry), [FiltersRegistry README](https://github.com/AdguardTeam/FiltersRegistry), [DNS filtering KB](https://adguard-dns.io/kb/general/dns-filtering/), [DNS syntax KB](https://adguard-dns.io/kb/general/dns-filtering-syntax/), [AdGuard filters KB](https://adguard.com/kb/general/ad-filtering/adguard-filters/), [AdGuardSDNSFilter](https://github.com/AdguardTeam/AdGuardSDNSFilter), [cname-trackers](https://github.com/AdguardTeam/cname-trackers), [AGH Known limitations](https://github.com/AdguardTeam/AdGuardHome#known-limitations). Nota: `notes/<nota>.md`.
- [ ] Separar mentalmente: **FiltersRegistry** = content/browser/apps; **HostlistsRegistry** = DNS (AGH / AdGuard DNS)
- [ ] Índice DNS: [filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json); apps = subset [filters_apps.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters_apps.json) (`includeInApps`)
- [ ] Default DNS: **AdGuard DNS filter** (`AdGuardSDNSFilter`) — [filter.txt](https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt); exige sintaxe adblock básica (não “só hosts”)
- [ ] Preferir listas já no HostlistsRegistry / SDNSFilter; EasyList cru no AGH → modifiers não-DNS fazem a **regra inteira** ser ignorada ([syntax](https://adguard-dns.io/kb/general/dns-filtering-syntax/))
- [ ] `$dnsrewrite` em blocklist do registry só se `trusted`; senão compilador remove — pedir issue no HostlistsRegistry se precisar
- [ ] CNAME: preferir Tracking Protection / EasyPrivacy no content blocker; listas disguised do [cname-trackers](https://github.com/AdguardTeam/cname-trackers) só com cuidado (microsites/clickthroughs podem quebrar)
- [ ] Lembrar limites DNS: YouTube/Twitch/social sponsored no mesmo domínio → [Known limitations](https://github.com/AdguardTeam/AdGuardHome#known-limitations); KB recomenda DNS **além** de network filtering
- [ ] Não empilhar Hostlists enormes no app Android (filters_apps é subset de propósito); AGH/cloud aguenta mais
- [ ] Sem install / sem AdGuard VPN+VPN / sem Magisk sem o dono pedir

## FiltersCompiler trustLevel + Filter Policy (estudo AAAA-MM-DD-24)
Fontes: [Filter Policy](https://adguard.com/kb/general/ad-filtering/filter-policy/), [Trusted filters KB](https://adguard.com/kb/general/ad-filtering/create-own-filters/), [FiltersRegistry README](https://github.com/AdguardTeam/FiltersRegistry), [FiltersCompiler trust-levels](https://github.com/AdguardTeam/FiltersCompiler/tree/master/src/main/utils/trust-levels), [Linux filters --trusted](https://adguard.com/kb/adguard-for-linux/settings/). Nota: `notes/<nota>.md`.
- [ ] Distinguir **compile-time** `trustLevel` (registry) de **runtime Trusted** (custom/user rules no app)
- [ ] Esperar: filtros AdGuard oficiais = `full`; EasyList típico = `low`; Fanboy Annoyances amostrado = `high` (revalidar metadata se for agir)
- [ ] `low` corta scriptlets/`##+js`/`#$#`/`$replace`/`$urltransform`/`#%#`; `high` ainda corta `$replace`/`$urltransform`/`#%#` e scriptlets `trusted-`; `full` não corta (exclusions-full vazio) — [exclusions-*.txt](https://github.com/AdguardTeam/FiltersCompiler/tree/master/src/main/utils/trust-levels)
- [ ] Custom URL com scriptlets/`$hls`: marcar **Trusted** só se fonte auditável; senão regras não aplicam ([KB Trusted](https://adguard.com/kb/general/ad-filtering/create-own-filters/); Linux: `filters install --trusted`)
- [ ] Annoyances/Other: se UX estranha, desligar Other/Annoyances antes de culpar Base ([Policy Annoyances](https://adguard.com/kb/general/ad-filtering/filter-policy/))
- [ ] Paywalls / self-promo deliberada / anti-adblock “suave”: Policy **não** manda bloquear nos filtros de ads — não esperar “sumir paywall”
- [ ] Contestar falso positivo: report tool/GitHub citando **secção** da Policy, não só “discordo”
- [ ] DNS filter ≠ substituto de Base/Tracking (Policy + nota registries)
- [ ] Sem Trusted em lista desconhecida; sem AdGuard VPN+VPN / Magisk sem o dono pedir

## Scriptlets / trusted- / redirects (estudo AAAA-MM-DD-25)
Fontes: [Scriptlets README](https://github.com/AdguardTeam/Scriptlets), [about-trusted-scriptlets](https://github.com/AdguardTeam/Scriptlets/blob/master/wiki/about-trusted-scriptlets.md), [compatibility-table](https://github.com/AdguardTeam/Scriptlets/blob/master/wiki/compatibility-table.md), [KB Trusted filters](https://adguard.com/kb/general/ad-filtering/create-own-filters/#trusted-filters), [BrowserExtension#3522](https://github.com/AdguardTeam/AdguardBrowserExtension/issues/3522), [FiltersCompiler exclusions](https://github.com/AdguardTeam/FiltersCompiler/tree/master/src/main/utils/trust-levels). Nota: `notes/<nota>.md`.
- [ ] Sintaxe: `[domains]#%#//scriptlet('nome'[, args…])`; exceção `#@%#//scriptlet([nome])` — README Scriptlets
- [ ] Distinguir scriptlets **comuns** (compat uBO/ABP) de **`trusted-*`** (só AdGuard; click/DOM/cookie/replace resposta) — wiki trusted
- [ ] Runtime: **todos** os scriptlets exigem fonte Trusted (equipe AG / custom Trusted / user rules) — KB + maintainer #3522 (pode mudar)
- [ ] Compile-time: `low` corta scriptlets; `high` corta só `trusted-`; `full` passa — exclusions-*.txt
- [ ] Custom URL: marcar Trusted **só** após auditar `#%#//scriptlet` / `trusted-` / `$replace`; senão deixar sem Trusted
- [ ] User rules = trusted automático — não colar pacotes opacos de chat
- [ ] `$redirect` ≠ scriptlet; permitido mesmo em trustLevel `low` (comentários exclusions)
- [ ] Superfícies: app AG Android / extensão = sim; Content Blocker Play / DNS-only / AGH = **não** scriptlets — KB Content Blocker + AGH Known limitations
- [ ] dispositivo Android + VPN: não empurrar Local VPN só por scriptlets; sem Magisk/AdGuard VPN+TS sem o dono pedir


## `$redirect` / `$redirect-rule` (estudo AAAA-MM-DD-26)
Fontes: [Scriptlets README Redirects](https://github.com/AdguardTeam/Scriptlets), [about-redirects](https://github.com/AdguardTeam/Scriptlets/blob/master/wiki/about-redirects.md), [compatibility-table redirects](https://github.com/AdguardTeam/Scriptlets/blob/master/wiki/compatibility-table.md), [KB `$redirect` / prioridades](https://adguard.com/kb/general/ad-filtering/create-own-filters/), [exclusions-low Allowed](https://github.com/AdguardTeam/FiltersCompiler/blob/master/src/main/utils/trust-levels/exclusions-low.txt). Nota: `notes/<nota>.md`.
- [ ] Distinguir `$redirect` (recurso local na sub-request) de scriptlet (JS na página) — README + KB
- [ ] Prioridade: `$important` > `@@` > `$redirect` > basic — [KB](https://adguard.com/kb/general/ad-filtering/create-own-filters/)
- [ ] Desligar: `@@…$redirect` / `@@…$redirect=nome` ou `$badfilter`; **não** uBO `redirect=none` — README
- [ ] `$redirect-rule` só se **outra** regra básica já bloqueia o URL — KB; MV3 **não** — KB
- [ ] Compile-time: `$redirect` / `$rewrite:abp-resource` **Allowed** em trustLevel `low` (enquanto scriptlets são cortados) — exclusions-low
- [ ] Catálogo: noop*/VAST/mocks SDK/`click2load.html` — [about-redirects](https://github.com/AdguardTeam/Scriptlets/blob/master/wiki/about-redirects.md); uBO `:prioridade` descartada no AG — KB
- [ ] Superfícies: CoreLibs/extensão = sim; Content Blocker Play / iOS/Safari / DNS-only/AGH = **não** — KB + AGH limitations
- [ ] dispositivo Android + VPN: redirects precisam network filtering (Local VPN XOR VPN); sem AdGuard VPN+TS / Magisk sem o dono pedir


## dnsproxy (AdguardTeam/dnsproxy) — estudo AAAA-MM-DD-02
Fontes: [README](https://github.com/AdguardTeam/dnsproxy/blob/master/README.md), [config.yaml.dist](https://github.com/AdguardTeam/dnsproxy/blob/master/config.yaml.dist), [Releases](https://github.com/AdguardTeam/dnsproxy/releases), [AGH go.mod](https://github.com/AdguardTeam/AdGuardHome/blob/master/go.mod), [KB AGH Configuration](https://adguard-dns.io/kb/adguard-home/configuration/), [blog DoQ standard](https://adguard-dns.io/en/blog/dns-over-quic-official-standard.html). Nota: `notes/<nota>.md`.
- [ ] Distinguir: **dnsproxy** = CLI/lib Go multi-protocolo; **AGH** = self-host (depende de `dnsproxy` no go.mod); **AdGuard DNS** = cloud; **Android apps** = DnsLibs (C++) + Local VPN — não “dnsproxy no telefone” por default — README + blog DoQ + AGH go.mod
- [ ] Protocolos cliente documentados: plain (`udp://`/`tcp://`/IP), `tls://` DoT, `https://` DoH, `quic://` DoQ, `h3://` DoH HTTP/3 forçado, `sdns://` stamps — README Examples
- [ ] Como servidor: `--tls-port` / `--https-port` / `--quic-port` / `--dnscrypt-port` + `--tls-crt`/`--tls-key` (ou `--dnscrypt-config`); `-p 0` desliga plain — README Encrypted DNS server
- [ ] Bootstrap: `-b` / `--bootstrap` para resolver hostnames DoH/DoT (default system); não esquecer trust do bootstrap — README Usage
- [ ] Upstream modes: `--upstream-mode` = `load_balance` (default) | `parallel` | `fastest_addr` — README
- [ ] Higiene listen: preferir `-l 127.0.0.1` ou IP LAN; **não** copiar dist `0.0.0.0:53` + `ratelimit: 0` em host roteável sem firewall — config.yaml.dist + README Simple options
- [ ] Rate limit / cache: `-r` / `--cache` / `--refuse-any` quando servir além de lab — README Additional features
- [ ] **Não** usar `--insecure` (cliente) nem desligar pending-requests sem entender: README liga desligar pending-requests a risco de cache poisoning
- [ ] DoH server com auth: `--https-userinfo=user:pass` (+ `-p 0` se só DoH) — README Basic Auth for DoH
- [ ] Uso defensivo típico (só se o dono pedir): cifrar upstream atrás de filtro LAN **ou** testar DoH/DoT/DoQ em host — **não** no dispositivo Android sem pedido; **não** AdGuard VPN+VPN; **não** Magisk
- [ ] AGH já embute dnsproxy (`github.com/AdguardTeam/dnsproxy` no go.mod) — se a meta é UI+blocklists, preferir estudar/usar AGH, não duplicar proxy sem pedido — go.mod + KB Configuration
- [ ] Sem install/Docker nesta sessão; release observada v0.84.1 / AGH aponta v0.84.2 — revalidar tag antes de pin



## ContentBlocker (AdguardTeam/ContentBlocker) — estudo AAAA-MM-DD-03
Fontes: [KB overview](https://adguard.com/kb/adguard-content-blocker/overview/), [KB installation](https://adguard.com/kb/adguard-content-blocker/installation/), [create-own-filters](https://adguard.com/kb/general/ad-filtering/create-own-filters/), [Privacy Notice](https://adguard.com/privacy/content-blocker.html), [GitHub ContentBlocker](https://github.com/AdguardTeam/ContentBlocker), [AndroidManifest](https://github.com/AdguardTeam/ContentBlocker/blob/master/adguard_cb/src/main/AndroidManifest.xml), [build.gradle](https://github.com/AdguardTeam/ContentBlocker/blob/master/adguard_cb/build.gradle), [Samsung Ad Blockers Guide](https://developer.samsung.com/internet/android/adblockers-guide.html), [Content blockers user docs](https://samsunginternet.github.io/docs/content-blockers), [Yandex API for ad blockers](https://yandex.com/support/browser-mobile-android-tablet/en/useful-features/api-for-ad-blockers), [filters.js](https://filters.adtidy.org/extension/android-content-blocker/filters.js), [content_blocker.txt](https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/BaseFilter/sections/content_blocker.txt), [Releases v2.8](https://github.com/AdguardTeam/ContentBlocker/releases/tag/v2.8). Nota: `notes/<nota>.md`.
- [ ] Distinguir: **Content Blocker (Play, GPL-3.0, v2.8)** ≠ **AdGuard for Android (site/APK, Local VPN)** ≠ **Browser Extension** ≠ **DNS-only** — KB overview + product FAQ
- [ ] Só esperar efeito em **Samsung Internet** e **Yandex Browser** (`<queries>` + KB); Chrome/Firefox = fora deste API
- [ ] Ativar: instalar app → enable no browser (Samsung Extensions → Content blockers, até **5** blockers; Yandex Settings → Content blocking) — KB install + Samsung/Yandex docs
- [ ] Limites API: sem apps nativos, sem filtering log, sem domain-level do app full; sintaxe ≈ ABP (`$domain`/`$third-party`; sem scriptlets/`$redirect`/extended CSS) — KB + content_blocker.txt + notes 25/26
- [ ] Updates: `filters.adtidy.org/extension/android-content-blocker/` (`filters.js` + `{id}_optimized.txt`); inventário vivo **86** filtros (2 deprecated) vs claim KB “35” — preferir contagem viva
- [ ] Filtros tipicos (estudo): Base (#2) + Tracking (#3) + Mobile Ads (#11) + Spanish/Portuguese (#9) se PT/ES; Security (#208/#255) só se aceitar FP
- [ ] Privacidade: update check “no information is sent” (notice 2024-08-07); agregação anônima de usuários ativos
- [ ] Higiene dispositivo Android: CB **não** usa slot VPN (manifest sem BIND_VPN) → compatível com VPN na camada browser; **não** substitui Private DNS; **não** install sem o dono pedir
- [ ] Se meta = ads em apps / Chrome Android → AdGuard for Android (XOR VPN) ou extensão no PC — não CB
- [ ] **Não** `internet://contentblock` (dev mode Samsung); sem Magisk/`adguardcert`; sem AdGuard VPN+VPN; remoto dispositivo Android = NÃO VALIDADO


## BrowserExtension (AdguardTeam/AdguardBrowserExtension) — estudo AAAA-MM-DD-04 + refresh AAAA-MM-DD-01
Fontes: [KB hub](https://adguard.com/kb/adguard-browser-extension/), [KB MV3](https://adguard.com/kb/adguard-browser-extension/mv3-version/), [KB Availability](https://adguard.com/kb/adguard-browser-extension/availability/), [KB Installation](https://adguard.com/kb/adguard-browser-extension/installation/), [KB Compatibility](https://adguard.com/kb/adguard-browser-extension/compatibility/), [KB Comparison](https://adguard.com/kb/adguard-browser-extension/comparison-standalone/), [KB Protected pages](https://adguard.com/kb/adguard-browser-extension/protected-pages/), [KB Filters](https://adguard.com/kb/adguard-browser-extension/features/filters/), [KB Tracking protection](https://adguard.com/kb/adguard-browser-extension/features/stealth-mode/), [Privacy Notice](https://adguard.com/privacy/browser-extension.html) (2025-12-16), [Blog MV3 release](https://adguard.com/en/blog/adguard-browser-extension-mv3-release.html), [Blog MV2 removal AAAA-MM-DD](https://adguard.com/en/blog/adguard-adblocker-manifestv2-removal.html), [GitHub README](https://github.com/AdguardTeam/AdguardBrowserExtension), [CHANGELOG](https://github.com/AdguardTeam/AdguardBrowserExtension/blob/master/CHANGELOG.md), [package.json](https://github.com/AdguardTeam/AdguardBrowserExtension/blob/master/package.json), [constants.ts](https://github.com/AdguardTeam/AdguardBrowserExtension/blob/master/constants.ts), [Chrome DNR](https://developer.chrome.com/docs/extensions/reference/api/declarativeNetRequest), [declarative-converter](https://github.com/AdguardTeam/tsurlfilter/blob/master/packages/tsurlfilter/src/rules/declarative-converter/README.md). Notas: `notes/<nota>.md` · **`<nota>`** · **`<nota>`** · **`<nota>`** (v5.5).
- [ ] Distinguir: **Browser Extension** (1 browser, GPL-3.0) ≠ **Content Blocker** (Samsung/Yandex) ≠ **AdGuard Android/Windows/Mac** (device) ≠ **DNS/AGH** — KB hub + Comparison
- [ ] Desktop: stores Chrome/Firefox/Opera/Edge (README); Chrome release ID `bgnkhhnnamicmpeenaelnjfhikgbkllg` — constants.ts; Safari = Mini for Mac (outra peça)
- [ ] **Chrome CWS:** listing MV2 **removido** (AAAA-MM-DD, Manifest V2 Deprecation); listing principal = MV3; se tinha “AdGuard Ad Blocker MV2” (outro ID) → instalar MV3 **manual** — [blog MV2 removal](https://adguard.com/en/blog/adguard-adblocker-manifestv2-removal.html)
- [ ] Alternativa MV2 pleno: **Firefox**; Brave = MV2 best-effort (sem garantia) — mesmo blog
- [ ] Chrome MV3 min **121** (README + constants); filtros embutidos atualizam com a extensão (auto-publish `dnr-rulesets`); **custom** updates independentes — KB MV3 + KB Filters + CHANGELOG 5.4
- [ ] Phishing MV3: filtros **Security** na aba Filters (não toggle geral) — KB MV3
- [ ] Limites: Chrome DNR 30k static garantidos / 30k safe dynamic (121+) / 5k unsafe; produto AG documenta **5k** converted Allowlist→User→Custom — citar ambos — Chrome DNR + KB MV3
- [ ] Não empilhar extensão full + app desktop → usar **Browser Assistant** — KB Compatibility
- [ ] WebRTC Block = **global** na extensão; `$stealth=webrtc` per-site não aplica — KB Tracking protection
- [ ] Protected pages (chrome://, CWS, addons.mozilla.org, etc.) = buraco oficial — KB Protected pages
- [ ] Store **v5.5** (blog AAAA-MM-DD / versions 5.5.0.5): **RulesEditor** (List+Editor); **Mail Tracking Protection**; Last updated por filtro; `$urltransform` MV3 — [blog v5.5](https://adguard.com/en/blog/adguard-browser-extension-v5-5.html)
- [ ] Mail Tracking = filter **#25** (ativo auto_build) — ligar em Filters se desejado; ≠ Quick Fixes #24 — nota `<nota>` + `<nota>`
- [ ] dispositivo Android: extensão PC ≠ CB ≠ Local VPN; **não** install no telefone sem o dono pedir; sem AdGuard VPN+VPN / Magisk
- [ ] Pin de build: revalidar store (repo pode mostrar 5.5.2+…) antes de citar hash


## BrowserExtension — Quick Fixes / FiltersRegistry auto-publish (estudo AAAA-MM-DD-03)
Fontes: [blog Quick Fixes/Custom](https://adguard.info/en/blog/review-issues-in-chrome-web-store.html) · [KB MV3](https://adguard.com/kb/adguard-browser-extension/mv3-version/) · [KB Filters](https://adguard.com/kb/adguard-browser-extension/features/filters/) · [User Scripts API](https://adguard.com/kb/adguard-browser-extension/user-scripts-api/) · [blog v5.2](https://adguard.com/en/blog/adguard-browser-extension-v5-2.html) · [blog v5.4](https://adguard.com/en/blog/adguard-browser-extension-v5-4.html) · [auto_build.sh](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/scripts/auto_build.sh) · [report-adguard.txt](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/report-adguard.txt) (acesso **AAAA-MM-DD**). Nota: `notes/<nota>.md`.
- [ ] **Quick Fixes (#24)** = Obsolete/DISABLED — **não** assinar URL `…/filters/24.txt`; fora do `ADGUARD_FILTERS` no auto_build (MV3 dynamic rules)
- [ ] Embutidos: update só com update da **extensão** (fast-track DNR + full CWS); sem Auto-update filters na UI MV3 — KB MV3
- [ ] Patches registry: AdGuard **1 h** (`--time=3600`); third-party **4 h** (`14400`) — auto_build.sh
- [ ] Custom filters: v5.2+ via User Scripts; Chrome &lt;138 Developer mode; **138+** Allow user scripts nas Details da extensão — KB User Scripts
- [ ] Custom (v5.4+): updates **independentes** da extensão; validar URL (não aceitar HTML) — blog v5.4 + KB Filters
- [ ] Site quebrado: User rule / Custom / esperar bump extensão — **não** caçar feed Quick Fixes
- [ ] #25 Mail Tracking Protection = ativo no auto_build (≠ Quick Fixes)
- [ ] App Android Local VPN XOR VPN — só se o dono pedir


## CNAME trackers / cloaking (estudo AAAA-MM-DD-05)
Fontes: [cname-trackers README](https://github.com/AdguardTeam/cname-trackers), [combined_original_trackers.txt](https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_original_trackers.txt), script/README + fetch-trackers.js + build.yml (clone AAAA-MM-DD), [blog disguised](https://adguard.com/en/blog/disguised-trackers.html), [blog cname-tracking](https://adguard.com/en/blog/cname-tracking.html), [KB DNS filtering](https://adguard-dns.io/kb/general/dns-filtering/), [FAQ AGH CNAME](https://adguard-dns.io/kb/adguard-home/faq/), [HostlistsRegistry filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json) (0 hits cname), [AGH #2779](https://github.com/AdguardTeam/AdGuardHome/issues/2779). Nota: `notes/<nota>.md`.
- [ ] Definir CNAME cloaking: terceiro disfarçado de first-party via CNAME; cookies first-party podem vazar ao tracker — README + blog cname-tracking
- [ ] Distinguir **original trackers** (só software CNAME-aware) de **disguised** (aliases para blockers sem resolve CNAME) — README The Lists
- [ ] AGH/AdGuard DNS: bloqueio nativo inspeciona CNAME na **resposta** (“Blocked by CNAME or IP”) — FAQ AGH; não exige importar disguised se o filtro já tem o canônico
- [ ] Content blocker Chrome/Safari: preferir **Tracking Protection** ou **EasyPrivacy** (README “safest way”); disguised full = risco de quebrar microsites/clickthroughs
- [ ] HostlistsRegistry **não** publica cname-trackers como filterId (filters.json 64 itens, 0 hits) — caminho ≠ “ligar lista no registry”
- [ ] Formatos: adblock `||domain^`, justdomains, RPZ (`data/combined_disguised_*`) — README; RPZ precisa SOA/NS do operador
- [ ] Pipeline: `cloaked-trackers.json` → API `urlfilter.adtidy.org/v1/findCloaked` → merge/DNS validate → combined; CI cron segundas 11:00 UTC — script + build.yml
- [ ] Listas disguised são **grandes** (centenas de milhares de linhas em trackers/mail no clone AAAA-MM-DD) — não empilhar no app Android; AGH/cloud/LAN só se o dono pedir e com unbreak
- [ ] DNS **não** substitui network/extensão para ads same-origin (YouTube/Twitch/social) — FAQ AGH limitations + KB DNS filtering “além de” network
- [ ] dispositivo Android: sem install; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

## Pós-mudança (quando houver bridge ou UI)
- [ ] Verificar VPN ativa (VPN vs outra)
- [ ] Testar resolução DNS e apps críticos (banco, Play)
- [ ] Anotar o que ficou ligado — sem inventar o que não deu para ver

## AdguardFilters repo + catálogo IDs / Policy (estudo AAAA-MM-DD-07)
Fontes: [AdguardFilters README](https://github.com/AdguardTeam/AdguardFilters), [CONTRIBUTING](https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/CONTRIBUTING.md), [KB filters](https://adguard.com/kb/general/ad-filtering/adguard-filters/), [Filter Policy](https://adguard.com/kb/general/ad-filtering/filter-policy/), [search-ads](https://adguard.com/kb/general/ad-filtering/search-ads/), [filters.json](https://filters.adtidy.org/extension/chromium/filters.json), [create-own-filters](https://adguard.com/kb/general/ad-filtering/create-own-filters/). Nota: `notes/<nota>.md`.
- [ ] Tratar **AdguardFilters** como fonte; **FiltersRegistry**/`filters.adtidy.org` como publicação — CONTRIBUTING
- [ ] Baseline browser (só se o dono pedir): **#2 Base** + **#3 Tracking** + **#9 Spanish/Portuguese** (PT-BR) — filters.json + KB
- [ ] **Não** ligar EasyList (#101) junto com Base (Base já inclui EasyList — CONTRIBUTING/JSON)
- [ ] Annoyances no MV3: preferir **#18–#22** em vez do combo **#14** (`deprecated` + excluído MV3 no JSON)
- [ ] **Não** usar DNS filter **#15** como substituto de Base no browser (Policy; `deprecated` no índice chromium)
- [ ] URL Tracking **#17**: indisponível em iOS / Safari / Android Content Blocker (`platformsExcluded`)
- [ ] Useful ads **#10**: opcional; não é Acceptable Ads pago — [search-ads KB](https://adguard.com/kb/general/ad-filtering/search-ads/)
- [ ] Paywalls / self-promo deliberada / anti-adblock suave: Policy **não** manda “sumir” via filtros de ads
- [ ] Security third-party (#208/#255/#256/#257): `trustLevel` **low** no JSON — consciência (nota trust AAAA-MM-DD-24)
- [ ] Experimental **#5**: tag `problematic` — evitar no dia a dia
- [ ] Sem AdGuard VPN+VPN / Magisk / tip ao dono sem pedido

## AdGuardSDNSFilter / AdGuard DNS filter (estudo AAAA-MM-DD-08)
Fontes: [SDNSFilter README](https://github.com/AdguardTeam/AdGuardSDNSFilter/blob/master/README.md), [package.json](https://github.com/AdguardTeam/AdGuardSDNSFilter/blob/master/package.json), [build.sh](https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/scripts/build.sh), [configuration.json](https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/configuration.json), [filter.txt Pages](https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt), [Hostlists filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json), [filter_1 metadata](https://raw.githubusercontent.com/AdguardTeam/HostlistsRegistry/main/filters/general/filter_1_DnsFilter/metadata.json), [filter_59 metadata](https://raw.githubusercontent.com/AdguardTeam/HostlistsRegistry/main/filters/general/filter_59_DnsPopupsFilter/metadata.json), [DNS syntax KB](https://adguard-dns.io/kb/general/dns-filtering-syntax/), [DNS filtering KB](https://adguard-dns.io/kb/general/dns-filtering/), [AGH Configuration](https://adguard-dns.io/kb/adguard-home/configuration/), [HostlistCompiler README](https://github.com/AdguardTeam/HostlistCompiler/blob/master/README.md). Nota: `notes/<nota>.md`.
- [ ] Tratar **AdGuardSDNSFilter** = artefato DNS composto; Hostlists **filterId 1** (`adguard_dns_filter`) — filters.json + metadata
- [ ] URLs: subscription Pages `…/AdGuardSDNSFilter/Filters/filter.txt`; AGH default download `…/HostlistsRegistry/assets/filter_1.txt` — filters.json
- [ ] Se AGH: confirmar lista **AdGuard DNS filter** enabled (default id 1); update interval default 24h — README + AGH config.go / Configuration KB
- [ ] Checar versão: `! Version` no mirror Hostlists / `! Last modified` no Pages; opcional `sha256sum` do filter.txt — procedimento nota §6.2
- [ ] Exige sintaxe adblock básica — **não** extrair “só hosts” — README
- [ ] **Não** importar EasyList/EasyPrivacy crus no AGH no lugar do #1 (modifiers desconhecidos → regra ignorada) — DNS syntax KB + RemoveModifiers
- [ ] DNS-only: sem scriptlets / `$redirect` / cosmetic; DNS **além** de network/extensão, não no lugar — DNS filtering KB + notes Scriptlets/redirect
- [ ] Distinguir Hostlists **#1** (DNS vivo) de FiltersRegistry/browser **#15** DNS filter (`deprecated` no chromium) — nota #5 + #8
- [ ] Popup Hosts = Hostlists **#59** (mesmo repo); opcional; trusted; não é o default AGH #1 — metadata #59 + README Popup
- [ ] `trusted: true` no #1/#59 → `$dnsrewrite` permitido nessas listas; outras listas sem trusted perdem `$dnsrewrite` — Hostlists README + syntax KB
- [ ] dispositivo Android: sem install; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO (bridge desmontada)


## HostlistsRegistry (estudo AAAA-MM-DD-09)
Fontes: [HostlistsRegistry README](https://raw.githubusercontent.com/AdguardTeam/HostlistsRegistry/master/README.md), [filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json), [filters_apps.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters_apps.json), [services.json](https://adguardteam.github.io/HostlistsRegistry/assets/services.json), [filter_1 metadata](https://raw.githubusercontent.com/AdguardTeam/HostlistsRegistry/main/filters/general/filter_1_DnsFilter/metadata.json), [filter_1 configuration](https://raw.githubusercontent.com/AdguardTeam/HostlistsRegistry/main/filters/general/filter_1_DnsFilter/configuration.json), [PhishingArmy configuration](https://raw.githubusercontent.com/AdguardTeam/HostlistsRegistry/main/filters/security/filter_18_PhishingArmy/configuration.json), [HostlistCompiler README](https://github.com/AdguardTeam/HostlistCompiler/blob/master/README.md), [DNS syntax KB](https://adguard-dns.io/kb/general/dns-filtering-syntax/), [DNS filtering KB](https://adguard-dns.io/kb/general/dns-filtering/), [AGH Configuration](https://adguard-dns.io/kb/adguard-home/configuration/), [AGH config.go](https://github.com/AdguardTeam/AdGuardHome/blob/master/internal/home/config.go), [vetted-filters main.go](https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/vetted-filters/main.go). Nota: `notes/<nota>.md`.
- [ ] Tratar **HostlistsRegistry** como catálogo canônico DNS (AGH + AdGuard DNS + apps subset) — README
- [ ] Distinguir `filters.json` (todas) de `filters_apps.json` (`includeInApps`; apps não lidam bem com listas enormes) — README
- [ ] Se AGH: baseline **filter_1** enabled; `filters_update_interval` default **24h** — config.go + Configuration KB
- [ ] Preferir URLs `…/HostlistsRegistry/assets/filter_N.txt` (re-hospedadas) a dump EasyList/EasyPrivacy crus no AGH — syntax KB (modifiers desconhecidos → regra ignorada) + README
- [ ] `trusted: true` só em #1 e #59 (amostra AAAA-MM-DD): só esses mantêm `$dnsrewrite` no compilado — README `trusted` + syntax KB
- [ ] Security sob demanda: ex. #18 Phishing Army, #11 URLHaus, #44 HaGeZi TIF — **não** ligar as 17 security de uma vez — filters.json
- [ ] Evitar tag `problematic` (Ultimate/Xtra/Abused TLDs…) sem unbreak consciente — filters.json tags
- [ ] Apps AdGuard: só subset apps (IDs 1/3/5/34/53 — reconfirmado AAAA-MM-DD); **não** empilhar HaGeZi Ultimate no telefone — filters_apps.json + README
- [ ] Parental/blocked services: IDs de `services.json` (139 serviços amostrados) via UI AGH/DNS — README + services.json
- [ ] Só `environment: prod` no AdGuard DNS — README metadata
- [ ] dispositivo Android: sem install; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

## Hostlists residual — #68/#69/#71 + KOR alinhado (estudo AAAA-MM-DD-01 · refresh AAAA-MM-DD-01)
Fontes: [filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json); [filters_apps.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters_apps.json); [Hostlists README](https://raw.githubusercontent.com/AdguardTeam/HostlistsRegistry/master/README.md); [AGH filters.ts](https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/client/src/helpers/filters/filters.ts); [FilterListManager README](https://raw.githubusercontent.com/AdguardTeam/FilterListManager/master/README.md); [FiltersRegistry #1225](https://github.com/AdguardTeam/FiltersRegistry/pull/1225). Notas: `<nota>` · **`<nota>`** (acesso **AAAA-MM-DD** ~12:43).

- [ ] Catálogo live **reconfirmado**: **64** listas; max id **71** — **sem** id >71 — filters.json (AAAA-MM-DD)
- [ ] Apps subset **inalterado**: IDs **1 / 3 / 5 / 34 / 53** — **não** esperar #68/#69/#70/#71 em `filters_apps` — filters_apps.json
- [ ] AGH security sob demanda: **#68** URL Shortener · **#71** DNS Rebind Protection — filters.json + filters.ts
- [ ] AGH general opcional: **#69** ShadowWhisperer Tracking — validar FP
- [ ] Tag `problematic` (111): IDs **49, 51, 56, 70** — um de cada vez + unbreak
- [ ] **REFRESH** KOR **#25**: Hostlists **e** AGH `filters.ts` = **filterslists-KO** (`FilteringDev/filterslists-KO`) — lag List-KR **fechado** no master (AAAA-MM-DD); mesmo `filter_25.txt`
- [ ] FilterListManager = lib de updates (Filters + Hostlists); não é catálogo paralelo
- [ ] dispositivo Android: sem install; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

## FiltersRegistry (estudo AAAA-MM-DD-10)
Fontes: [FiltersRegistry README](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/README.md), [DEVELOPMENT.md](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/DEVELOPMENT.md), [chromium filters.json](https://filters.adtidy.org/extension/chromium/filters.json), [chromium-mv3 filters.json](https://filters.adtidy.org/extension/chromium-mv3/filters.json), [android filters.json](https://filters.adtidy.org/android/filters.json), [filter_2 metadata](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_2_Base/metadata.json), [filter_14](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_14_Annoyances/metadata.json), [filter_15](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_15_DnsFilter/metadata.json), [EasyList #101](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/ThirdParty/filter_101_EasyList/metadata.json), [EasyPrivacy #118](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/ThirdParty/filter_118_EasyPrivacy/metadata.json), [groups](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/groups/metadata.json), [trust exclusions](https://github.com/AdguardTeam/FiltersCompiler/tree/master/src/main/utils/trust-levels), [KB AdGuard filters](https://adguard.com/kb/general/ad-filtering/adguard-filters/), [custom_platforms.js](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/scripts/build/custom_platforms.js). Nota: `notes/<nota>.md`.
- [ ] Tratar **FiltersRegistry** / `filters.adtidy.org` como catálogo canônico **browser/content** (≠ HostlistsRegistry DNS) — README
- [ ] Auditar o índice da **plataforma real**: chromium ≠ chromium-mv3 (88 vs 52 em AAAA-MM-DD); android 86 — filters.json
- [ ] Preferir `downloadUrl` re-host AdGuard; `subscriptionUrl` pode ser origem third-party — índice + metadata EasyList
- [ ] Baseline browser (só se o dono pedir): **#2 Base** + **#3 Tracking** + **#9 Spanish/Portuguese** (`languages` es+pt, recommended) — filters.json
- [ ] **Não** empilhar **#101 EasyList** com Base (already included; trust `low`; excluído MV3) — metadata EasyList
- [ ] Ler `trustLevel` antes de esperar scriptlets/`$replace`: AdGuard=`full`, EasyPrivacy=`high`, EasyList=`low` — exclusions-*.txt
- [ ] `deprecated` = ainda buildado (#14, #15); `disabled`+`obsolete` = fora do build (#12, #24) — README + metadata
- [ ] Annoyances: preferir split **#18–22**; evitar monolito **#14** deprecated (também fora do MV3) — KB + metadata + mv3 JSON
- [ ] Browser: **não** usar FiltersRegistry **#15** como DNS; DNS vivo = Hostlists **#1** / SDNSFilter — metadata #15 + notes 08/09
- [ ] Evitar tag `problematic` (#5 Experimental, #15, etc.) no dia a dia — tags no JSON
- [ ] dispositivo Android: sem install; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

## AdGuard Android — Firewall / Stealth / Browsing / App mgmt (estudo AAAA-MM-DD-12)
Fontes: [Protection](https://adguard.com/kb/adguard-for-android/features/protection/), [Firewall](https://adguard.com/kb/adguard-for-android/features/protection/firewall/), [App management](https://adguard.com/kb/adguard-for-android/features/app-management/), [Tracking protection](https://adguard.com/kb/adguard-for-android/features/protection/tracking-protection/) (ex-Stealth), [Browsing security](https://adguard.com/kb/adguard-for-android/features/protection/browsing-security/), [Phishing/malware general](https://adguard.com/kb/general/browsing-security/), [Free vs full](https://adguard.com/kb/adguard-for-android/features/free-vs-full/), [Settings](https://adguard.com/kb/adguard-for-android/features/settings/) (HTTPS/Extensions), [Manual CA Android 11+](https://adguard.com/kb/adguard-for-android/solving-problems/manual-certificate/), [HTTPS filtering](https://adguard.com/kb/general/https-filtering/what-is-https-filtering/), [Rooted](https://adguard.com/kb/adguard-for-android/features/rooted/), [Statistics](https://adguard.com/kb/adguard-for-android/features/statistics/), [DNS protection](https://adguard.com/kb/adguard-for-android/features/protection/dns-protection/), [Low-level](https://adguard.com/kb/adguard-for-android/features/low-level-settings/). Notas: `notes/<nota>.md` (DNS-vs-VPN `<nota>`) · refresh changelog **`<nota>`**.
- [ ] Firewall: Protection → Firewall — Global vs Custom (custom **override** global); Notifications de violação — [Firewall](https://adguard.com/kb/adguard-for-android/features/protection/firewall/)
- [ ] App management: Route / Filter content / HTTPS (apps ≠ browser → system CA) / proxy — [App management](https://adguard.com/kb/adguard-for-android/features/app-management/)
- [ ] Não rotear “todos” os apps: evitar problematic (Download Manager, radio, UID 1000/1001); lista = Low-level → Excluded apps — [App management](https://adguard.com/kb/adguard-for-android/features/app-management/)
- [ ] Tracking protection = ex-Stealth: preferir **Standard** se High/Extreme cookies (180 min) quebrarem login social — [Tracking protection](https://adguard.com/kb/adguard-for-android/features/protection/tracking-protection/)
- [ ] Extreme: WebRTC / Push / Location / Referer / UA — esperar quebra de messengers/streaming — [Tracking protection](https://adguard.com/kb/adguard-for-android/features/protection/tracking-protection/)
- [ ] Browsing security: paid; **não** antivírus; hash prefixes; apps checam páginas + objetos — [Browsing security](https://adguard.com/kb/adguard-for-android/features/protection/browsing-security/) + [general](https://adguard.com/kb/general/browsing-security/)
- [ ] Free vs full paid: ads-in-apps, Tracking, Browsing security, custom filters/user rules, userscripts; YouTube Share player = free — [Free vs full](https://adguard.com/kb/adguard-for-android/features/free-vs-full/)
- [ ] HTTPS Android 11+: install manual CA user store; Android 15: aviso “unknown third party” — [Manual certificate](https://adguard.com/kb/adguard-for-android/solving-problems/manual-certificate/)
- [ ] HTTPS apps modernos: user CA insuficiente (Android 7+); system store = root — **não** Magisk/`adguardcert` sem pedido — [HTTPS](https://adguard.com/kb/general/https-filtering/what-is-https-filtering/) + [Rooted](https://adguard.com/kb/adguard-for-android/features/rooted/)
- [ ] Exclusões HTTPS default: financeiros/sensíveis + EV off; opção Filter EV — [Settings HTTPS](https://adguard.com/kb/adguard-for-android/features/settings/)
- [ ] Extensions: Settings → Filtering → Extensions (AdGuard Extra, Disable AMP); userscripts = paid — [Settings](https://adguard.com/kb/adguard-for-android/features/settings/)
- [ ] Statistics → Recent activity: últimos 10 000; Customize status/origin; rule 1-tap — [Statistics](https://adguard.com/kb/adguard-for-android/features/statistics/)
- [ ] DNS: Add DNS server / private AdGuard DNS do dashboard; AGH = custom DNS (sem Integration AGH dedicada) — [DNS protection](https://adguard.com/kb/adguard-for-android/features/protection/dns-protection/)
- [ ] Low-level HTTPS extras: OCSP / Filter HTTP/3 (Chromium+user CA = sem HTTP/3) / Encrypted Client Hello — [Low-level](https://adguard.com/kb/adguard-for-android/features/low-level-settings/)
- [ ] **4.13+ / revalidado 21-17:** engine adota **CRLite** (Mozilla) — [v4.13](https://github.com/AdguardTeam/AdguardForAndroid/releases/tag/v4.13) / [blog](https://adguard.com/en/blog/adguard-for-android-v4-13.html); KB low-level **ainda** lista toggle **OCSP checking** (HTTPS on; timeout→allow+bg; revoked→block) — [Low-level](https://adguard.com/kb/adguard-for-android/features/low-level-settings/); **não** tipar remoção do toggle nem “OCSP forever off”
- [ ] **NOVO (4.13+):** DnsLibs **post-quantum** (#245) — só no caminho DNS do app, não Private DNS SO
- [ ] **NOVO (4.13+):** Google Backup support (#5879); ColorOS CA instructions (#5827); local proxy auth
- [ ] **NOVO (4.14+):** filtragem HTTP/2+HTTP/3 p/ browser proxy/VPN extensions; encrypted fallback/bootstrap DNS (#5653)
- [ ] dispositivo Android: sem install; sem AdGuard VPN+VPN; sem Magisk; Local VPN XOR VPN; estado remoto = NÃO VALIDADO — nota 12 + `<nota>` + **`<nota>`**

## StevenBlack hosts (estudo AAAA-MM-DD-20)
Fontes: [StevenBlack/hosts README](https://raw.githubusercontent.com/StevenBlack/hosts/master/readme.md), [hosts raw](https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts), [license](https://raw.githubusercontent.com/StevenBlack/hosts/master/license.txt), [Hostlists filters.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters.json), [filter_33.txt](https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt), [metadata #33](https://cdn.jsdelivr.net/gh/AdguardTeam/HostlistsRegistry@main/filters/general/filter_33_StevenBlack/metadata.json), [configuration #33](https://cdn.jsdelivr.net/gh/AdguardTeam/HostlistsRegistry@main/filters/general/filter_33_StevenBlack/configuration.json), [filters_apps.json](https://adguardteam.github.io/HostlistsRegistry/assets/filters_apps.json), [#2043](https://github.com/StevenBlack/hosts/issues/2043), [#2229](https://github.com/StevenBlack/hosts/issues/2229), [#2657](https://github.com/StevenBlack/hosts/issues/2657), [Pi-hole commonly whitelisted](https://discourse.pi-hole.net/t/commonly-whitelisted-domains/212), [Pi-hole basic-install.sh](https://raw.githubusercontent.com/pi-hole/pi-hole/master/automated%20install/basic-install.sh), [DNS filtering KB](https://adguard-dns.io/kb/general/dns-filtering/), [LinkProperties Private DNS](https://developer.android.com/reference/kotlin/android/net/LinkProperties). Nota: `notes/<nota>.md`.
- [ ] Tratar **StevenBlack/hosts** como agregador Unified **adware+malware** (+ extensions fakenews/gambling/porn/social opcionais) — README
- [ ] HostlistsRegistry **filterId 33** (`steven_blacks_list`); General; `purpose:general`; não deprecated — filters.json + metadata
- [ ] URLs: subscription raw `…/StevenBlack/hosts/master/hosts`; AG download `…/filter_33.txt` — filters.json
- [ ] Geração: **`updateHostsFile.py`** + `data/*/update.json`; whitelist parcial local — README
- [ ] Preferir sinkhole **`0.0.0.0`** (não `127.0.0.1`) — README
- [ ] Snapshot tamanho Unified ~**80 169** (17 Sep 2026) — README/header hosts (muda)
- [ ] `s.youtube.com`: no master atual **comentado** (history/Podcasts); se outra lista bloquear → allow pontual; issues #2043/#2657/#2229 — hosts + issues + Pi-hole wiki
- [ ] **Não** esperar #33 em AdGuard apps (`filters_apps` sem #33) — filters_apps.json
- [ ] AGH: hosts/DNS blocklists OK (#33 ou URL); Pi-hole installer oferece Unified — DNS filtering KB + basic-install.sh
- [ ] Private DNS Android = hostname DoT, **não** URL de ficheiro hosts — LinkProperties + note Private DNS
- [ ] Evitar empilhar #33 + Multi Ultimate/native OEM “por garantia” sem gap medido (overlap = hipótese) — nota §7
- [ ] dispositivo Android: sem install Pi-hole/AGH/Portmaster; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

## uBlock Origin / uAssets (estudo AAAA-MM-DD-21)
Fontes: [uAssets README](https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/README.md), [assets.json](https://github.com/gorhill/uBlock/blob/master/assets/assets.json), [Dashboard: Filter lists](https://github.com/gorhill/uBlock/wiki/Dashboard:-Filter-lists), [Deploying configuration](https://github.com/gorhill/uBlock/wiki/Deploying-uBlock-Origin:-configuration), [gorhill/uBlock README](https://raw.githubusercontent.com/gorhill/uBlock/master/README.md), [Chrome MV2 wiki](https://github.com/gorhill/uBlock/wiki/About-Google-Chrome's-%22This-extension-may-soon-no-longer-be-supported%22), [uBOL FAQ](https://github.com/uBlockOrigin/uBOL-home/wiki/Frequently-asked-questions-%28FAQ%29), [AGH Known limitations](https://github.com/AdguardTeam/AdGuardHome#comparison-limitations). Nota: `notes/<nota>.md` (overview camadas em `<nota>`).
- [ ] PC browser: Firefox → **uBO** AMO Easy default; Chromium pós-CWS MV2 → **uBOL** (README: CWS uBO removed AAAA-MM-DD) — README + FAQ
- [ ] Instalar **só** stores/links do README oficial (AMO / Edge / Opera / GitHub Releases / uBOL) — README
- [ ] **Não** usar outro content blocker junto com uBO/uBOL — uAssets README + uBO README + uBOL FAQ
- [ ] Manter seleção **default** Easy (`ublock-*` + EasyList + EasyPrivacy + urlhaus + plowe); auto-update **on** — Deploying filterLists + Filter lists wiki
- [ ] Se remover listas: **manter** “uBlock filters” — Filter lists wiki
- [ ] Mais listas custom = mais breakage; AG/EasyList ok qualidade; outras opt-in à própria conta; report no tracker **da lista** — Filter lists wiki
- [ ] Custom Import: 1 URL/linha; preferir hosts aprovados wiki (easylist.to, github.com, …); **não** bypass de bad lists — Filter lists wiki
- [ ] Issues de filtro stock → **uAssets** (+ Troubleshooting); produto uBO → uBlock-issues; uBOL → uBOL-home — uAssets README
- [ ] uBOL: rulesets no pacote; update de filtros = update da extensão (sem fetch remoto runtime) — uBOL FAQ
- [ ] uBOL: sem esperar dynamic/Medium-Hard; cosmético genérico default off (Complete mode) — uBOL FAQ
- [ ] DNS sinkhole **complementa** (apps/IoT); **não** substitui uBO em ads same-domain — AGH Known limitations + note 14
- [ ] Antes de self-host DNS: checar Chrome Secure DNS + Android Private DNS (não furar) — note 14
- [ ] Annoyances / Experimental / muitas listas AG no uBO = opt-in consciente — assets.json `off` + Filter lists
- [ ] dispositivo Android: sem install VPN/DNS app; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

## Unbound harden + dnscrypt Anonymized (estudo AAAA-MM-DD-22)
Fontes: [Unbound Configuration](https://unbound.docs.nlnetlabs.nl/en/latest/getting-started/configuration.html), [unbound.conf(5)](https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html), [Pi-hole Unbound](https://docs.pi-hole.net/guides/dns/unbound/), [example-dnscrypt-proxy.toml](https://raw.githubusercontent.com/DNSCrypt/dnscrypt-proxy/master/dnscrypt-proxy/example-dnscrypt-proxy.toml), [Anonymized DNS wiki](https://github.com/dnscrypt/dnscrypt-proxy/wiki/Anonymized-DNS), [dnscrypt-proxy README](https://github.com/DNSCrypt/dnscrypt-proxy/). Nota: `notes/<nota>.md` (overviews `<nota>` / `<nota>`).
- [ ] Unbound: `auto-trust-anchor-file` + user write; `qname-minimisation: yes` — Configuration
- [ ] Unbound ACL: default só `127.0.0.0/8` allow; resto refuse; LAN com `access-control: <subnet> allow` — unbound.conf access-control
- [ ] **Não** `interface: 0.0.0.0` sem ACL (open resolver) — Configuration + access-control
- [ ] Manter `harden-dnssec-stripped: yes`; **não** `val-permissive-mode` em defesa — unbound.conf
- [ ] `harden-referral-path` / `harden-algo-downgrade` = experimental / viola RFC — não “ligar por garantia” — unbound.conf
- [ ] `edns-buffer-size: 1232`; `private-address` RFC1918+ (Pi-hole guide) — Pi-hole Unbound + unbound.conf
- [ ] Antes de recurse: dig `@198.41.0.4` NS +norec (`aa` sem `ra`); +tcp; CHAOS `version.bind` → `ATLAS` — Pi-hole Unbound
- [ ] DNSSEC test: `fail01.dnssec.works` SERVFAIL; `dnssec.works` NOERROR+`ad` — Pi-hole Unbound
- [ ] Pi-hole+Unbound: upstream `127.0.0.1#5335`; Debian Bullseye+ desligar unbound-resolvconf — Pi-hole Unbound
- [ ] dnscrypt: `listen_addresses` preferir `127.0.0.1:53` (não 0.0.0.0 sem firewall) — example.toml
- [ ] Sources: Minisign key + URLs oficiais public-resolvers/relays; `refresh_delay` 25–169 — example.toml
- [ ] Filtros: `require_nolog`/`require_nofilter` (não aplicam se `server_names` fixo) — example.toml
- [ ] Anonymized: só DNSCrypt/ODoH; DoH precisa Tor/SOCKS; relays ≠ mesma entidade que server; `skip_incompatible` — wiki Anonymized
- [ ] “incompatible with anonymization” → checar bloqueio de UDP fragments no router — wiki Caveats
- [ ] `block_unqualified`/`block_undelegated` on; bootstrap_resolvers só one-shot listas — example.toml
- [ ] Stack: filtro → **ou** Unbound **ou** dnscrypt (modelos diferentes) — nota 22
- [ ] dispositivo Android: sem install Unbound/dnscrypt/Pi-hole/Portmaster; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

## NextDNS cloud / CLI / NextDNS-Config (estudo AAAA-MM-DD-23)
Fontes: [Which setup](https://help.nextdns.io/t/m1hmv0k/which-setup-type-to-use), [Linked IP](https://help.nextdns.io/t/g9hmvan/what-is-linked-ip), [DoT/DoH/DoQ](https://help.nextdns.io/t/x2hmvas/what-is-dns-over-tls-dot-dns-over-quic-doq-and-dns-over-https-doh-doh3), [Device enrichment](https://help.nextdns.io/t/x2h76ay/device-information-log-enrichment), [Rebinding](https://help.nextdns.io/t/35hmval/what-is-dns-rebinding-protection), [ECS](https://help.nextdns.io/t/m1hmv04/what-is-edns-client-subnet-ecs), [Logs CSV](https://help.nextdns.io/t/q6htmk9/how-to-download-logs), [300k quota](https://help.nextdns.io/t/p8hmvaw/what-happens-after-300k-queries), [Privacy](https://nextdns.io/privacy), [Pricing](https://nextdns.io/pricing), [CLI wiki](https://github.com/nextdns/nextdns/wiki), [CLI Configuration](https://github.com/nextdns/nextdns/wiki/Configuration), [yokoffing README](https://raw.githubusercontent.com/yokoffing/NextDNS-Config/main/README.md). Nota: `notes/<nota>.md` (overview `<nota>`).
- [ ] Preferir **DoH/DoT** (ou CLI/app) sobre IPv4+Linked IP — [Which setup](https://help.nextdns.io/t/m1hmv0k/which-setup-type-to-use)
- [ ] Linked IP **só** Do53/IPv4; DoH/DoT/IPv6 não precisam — [Linked IP](https://help.nextdns.io/t/g9hmvan/what-is-linked-ip)
- [ ] Endpoints: DoH `https://dns.nextdns.io/<PROFILE>`; DoT `<PROFILE>.dns.nextdns.io` — Setup + enrichment
- [ ] Android c/ VPN: **Private DNS** hostname DoT (não app VPN) — nota 23 + Which setup
- [ ] Device name DoT: `Name--With--Spaces-<PROFILE>.dns.nextdns.io` — [enrichment](https://help.nextdns.io/t/x2h76ay/device-information-log-enrichment)
- [ ] Free: **300k** queries/mês (todos os profiles); após = resolve sem filtro/log; e-mail 250k/300k — [Pricing](https://nextdns.io/pricing) + [300k](https://help.nextdns.io/t/p8hmvaw/what-happens-after-300k-queries)
- [ ] Logs: off = sem analytics detalhado (só counter); retenção/jurisdição (US/EU/UK/CH) — Privacy + download logs
- [ ] Anonymized ECS: on = ECS próprio sem IP raw; off = **sem** ECS — [ECS](https://help.nextdns.io/t/m1hmv04/what-is-edns-client-subnet-ecs)
- [ ] DNS Rebinding Protection: off default; ligar se não precisa A→RFC1918 de nomes públicos — [Rebinding](https://help.nextdns.io/t/35hmval/what-is-dns-rebinding-protection)
- [ ] CLI: `config set -profile=…`; **cuidado** `-detect-captive-portals` (pode forçar leak plain DNS) — [Configuration](https://github.com/nextdns/nextdns/wiki/Configuration)
- [ ] CLI router: `-setup-router` + `-report-client-info`; workstation: `-auto-activate` — wiki
- [ ] Guia yokoffing: revisão (Hagezi Multi PRO; Block Page off; Rebinding on) — **não** ordem de install — NextDNS-Config README
- [ ] dispositivo Android: sem install NextDNS CLI/app VPN/Portmaster; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

---

## Scriptlets trusted refresh (AAAA-MM-DD)

**Nota:** `notes/<nota>.md` (+ base `<nota>`)  
Fonte: [about-trusted-scriptlets.md](https://raw.githubusercontent.com/AdguardTeam/Scriptlets/master/wiki/about-trusted-scriptlets.md) (acesso **AAAA-MM-DD**)

- [ ] Tratar lista **Trusted** / `trusted-*` como código privilegiado (clique, cookie, storage, rewrite JSON/rede) — não hide CSS
- [ ] Novos riscos documentados: `trusted-json-set*` (incl. JSONPath), `trusted-prevent-xhr` com body literal
- [ ] FiltersCompiler trust **high** continua a cortar `trusted-*` em compile-time (nota AAAA-MM-DD-24)
- [ ] Não adicionar listas Trusted de origem desconhecida; DNS/AGH **não** roda scriptlets

## Pi-hole v6 — FTL / Docker / Gravity / privacy (estudo AAAA-MM-DD-05)
Fontes: [Overview](https://docs.pi-hole.net/), [Prerequisites](https://docs.pi-hole.net/main/prerequisites/), [Install](https://docs.pi-hole.net/main/basic-install/), [Post-Install](https://docs.pi-hole.net/main/post-install/), [pihole command](https://docs.pi-hole.net/main/pihole-command/), [Docker](https://docs.pi-hole.net/docker/), [Docker configuration](https://docs.pi-hole.net/docker/configuration/), [FTL configfile](https://docs.pi-hole.net/ftldns/configfile/), [Privacy levels](https://docs.pi-hole.net/ftldns/privacylevels/), [Unbound guide](https://docs.pi-hole.net/guides/dns/unbound/). Nota: `notes/<nota>.md`. AGH: `<nota>` / Encryption `<nota>`.
- [ ] Tratar Pi-hole como **DNS sinkhole LAN** (sem cliente) — Overview
- [ ] Portas: 53 DNS; 80/443 UI (fallback 8080/8443); 67/547 DHCP opcional; 123 NTP opcional — Prerequisites
- [ ] Firewall: restringir DNS/UI à LAN; desenho local, não Internet — Prerequisites Firewalls
- [ ] Config: `/etc/pihole/pihole.toml`; Docker `FTLCONF_*` **read-only** enquanto o env existir — FTL configfile + Docker configuration
- [ ] Se `FTLCONF_dns_upstreams` no compose: UI upstreams sobrescritos no restart — Docker configuration
- [ ] `listeningMode=ALL` = open resolver se sem firewall — FTL configfile
- [ ] Blocking mode default `NULL`; `blockTTL` baixo (default 2) — FTL configfile
- [ ] Rate limit default 1000/60s por cliente — FTL configfile
- [ ] specialDomains on: mozillaCanary, iCloudPrivateRelay, designatedResolver — FTL configfile
- [ ] Gravity: `pihole -g` / updateGravity; adlists → gravity.db; semanal auto — pihole command
- [ ] Privacy: nível 0–3 (`misc.privacylevel`); 3 = sem Query Log / long-term DB; subir nível não recupera detalhe oculto — Privacy levels + configfile
- [ ] Auth: password; TOTP opcional; grupo `pihole` + `cli_pw` no host — Post-Install + configfile
- [ ] Rede: preferir DHCP do router → DNS = Pi-hole; DHCP embutido só com router DHCP off — Post-Install
- [ ] Host apontar 127.0.0.1 = risco se FTL cair (repair sem DNS) — Post-Install
- [ ] vs AGH: **um** sinkhole na LAN; AGH tem DoH/DoT/DoQ + `$dnsrewrite`/`$client`; Pi-hole = Gravity + FTL — nota §9
- [ ] Unbound residual: ver secção Unbound + nota `<nota>`
- [ ] dispositivo Android: sem install Pi-hole/AGH/Portmaster; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

## Technitium — recursion / Apps / Docker (estudo AAAA-MM-DD-08)
Fontes: [home v15.5](https://technitium.com/dns/), [help.html](https://technitium.com/dns/help.html), [Ubuntu blog](https://blog.technitium.com/2017/11/running-dns-server-on-ubuntu-linux.html), [docker-compose.yml](https://raw.githubusercontent.com/TechnitiumSoftware/DnsServer/master/docker-compose.yml), [AdvancedBlockingApp README](https://raw.githubusercontent.com/TechnitiumSoftware/DnsServer/master/Apps/AdvancedBlockingApp/README.md), [DnsRebindingProtectionApp README](https://raw.githubusercontent.com/TechnitiumSoftware/DnsServer/master/Apps/DnsRebindingProtectionApp/README.md). Nota: `notes/<nota>.md`. Overview: `<nota>`.
- [ ] Papel: auth + recursive + block + DoT/DoH/DoQ + DHCP + Apps — home Features
- [ ] UI `:5380`; default admin/admin → mudar já — Get Started
- [ ] Docker `technitium/dns-server:latest`; volume `/etc/dns`; healthcheck `/api/dnsClient/healthCheck` — compose
- [ ] Env first-start: `DNS_SERVER_DOMAIN`, admin password, `DNS_SERVER_RECURSION=AllowOnlyForPrivateNetworks`, forwarders/protocol — compose
- [ ] Portas: 53 DNS; 5380 UI; 853/443 DoT/DoH opcional; DHCP 67 precisa host net — blog + compose
- [ ] Conflito `:53`: desligar systemd-resolved/dnsmasq antes do bind — blog Common Issue
- [ ] Local End Points LAN + firewall se roteável — help §6
- [ ] Built-in Blocking **XOR** Advanced Blocking App — AdvancedBlocking warning
- [ ] Advanced: groups via CIDR / endpoint; `blockAsNxDomain` vs `blockingAddresses`; TXT report — AdvancedBlocking
- [ ] HaGeZi: Wildcard Domains (built-in) ou AdBlock/hosts no App; um Multi + TIF opcional
- [ ] Rebinding App: filtra A/AAAA privados em nomes públicos; listar `privateDomains`; authoritative local isento — Rebinding README
- [ ] vs AGH/Pi-hole/Blocky: **um** sinkhole `:53` na LAN; Technitium se auth zones+Apps importam — nota §8
- [ ] dispositivo Android: sem install Technitium/Pi-hole/AGH/Portmaster; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

## Gravity (BeryJu) — DNS+DHCP+cluster+Blocky (estudo AAAA-MM-DD-10)
Fontes: [Welcome](https://gravity.beryju.io/docs/), [Installation](https://gravity.beryju.io/docs/install/), [Clustering](https://gravity.beryju.io/docs/install/cluster/), [DNS](https://gravity.beryju.io/docs/dns/), [Zones](https://gravity.beryju.io/docs/dns/zones/), [DHCP](https://gravity.beryju.io/docs/dhcp/), [Scopes](https://gravity.beryju.io/docs/dhcp/scopes/), [API](https://gravity.beryju.io/docs/api/), [Discussion #1336](https://github.com/BeryJu/gravity/discussions/1336). Nota: `notes/<nota>.md`. Overview: `<nota>`.
- [ ] Papel: DNS+DHCP+TFTP+discovery com **etcd** replication; ads via Blocky **in-process** — Welcome + #1336
- [ ] Compose: `ghcr.io/beryju/gravity:stable`; host net; hostname estático único; volume `/data`; log rotate — install
- [ ] Admin: creds no log ou `ADMIN_PASSWORD`; UI `:8008` só LAN; `ADMIN_TOKEN` opcional first-start — install + API
- [ ] `BOOTSTRAP_ROLES`: default inclui dhcp/tftp/…; cortar o que não precisa — install
- [ ] Handlers: ordem importa; sem fall-through entre zonas; raiz `.` = fallback — DNS + Zones
- [ ] `forward_blocky`: `to` + blocklists/allowlists; `config:` YAML aninhado ≥0.15 (frágil) — Zones
- [ ] Defaults embutidos = 6 listas pesadas (AdAway, oisd, StevenBlack, Firebog×2, SDNSFilter) → **substituir** por curadoria (ex. 1 Multi HaGeZi) — Zones + higiene Guard
- [ ] DHCP scope: longest CIDR / `default`; IPAM `range_*` + `should_ping`; `dns.zone` → A/PTR com TTL do lease — Scopes
- [ ] Sem double-DHCP (router + Gravity no mesmo L2) — estudo
- [ ] Cluster: ímpar; 2 nós = quorum frágil; DNS degrada ok se `memory`/`forward_*` — Clustering
- [ ] API sock sem auth; Bearer na UI; OIDC + `?local`; permissions path/method ≥0.16 — API
- [ ] `SENTRY_ENABLED` default false — install
- [ ] vs AGH/Pi-hole/Blocky/SmartDNS/Technitium: **um** `:53` na LAN; Gravity se DNS+DHCP+HA — nota §1
- [ ] dispositivo Android: sem install Gravity/Pi-hole/AGH/Portmaster; sem AdGuard VPN+VPN; sem Magisk; estado remoto = NÃO VALIDADO

## AdGuard DNS Private — clients / Access / API (estudo AAAA-MM-DD-13)
Fontes (acesso **AAAA-MM-DD**): [Private overview](https://adguard-dns.io/kb/private-dns/overview/) · [Connect devices](https://adguard-dns.io/kb/private-dns/connect-devices/) · [Android](https://adguard-dns.io/kb/private-dns/connect-devices/mobile-and-desktop/android/) · [Linked IP](https://adguard-dns.io/kb/private-dns/connect-devices/other-options/linked-ip/) · [DoH auth](https://adguard-dns.io/kb/private-dns/connect-devices/other-options/doh-authentication/) · [Automatic connection](https://adguard-dns.io/kb/private-dns/connect-devices/other-options/automatic-connection/) · [Server and settings](https://adguard-dns.io/kb/private-dns/server-and-settings/) · [Access](https://adguard-dns.io/kb/private-dns/server-and-settings/access/) · [Advanced](https://adguard-dns.io/kb/private-dns/server-and-settings/advanced/) · [Rate limit](https://adguard-dns.io/kb/private-dns/server-and-settings/rate-limit/) · [API overview](https://adguard-dns.io/kb/private-dns/api/overview/) · [Public JSON API](https://adguard-dns.io/kb/public-dns/overview/). Nota: `notes/<nota>.md`. Overview: `<nota>`.
- [ ] Server = perfil; Device = cliente no Dashboard — [Server and settings](https://adguard-dns.io/kb/private-dns/server-and-settings/)
- [ ] Android sem VPN-slot: Private DNS SO = **só DoT** `{Device_ID}.d.adguard-dns.com` — [Android](https://adguard-dns.io/kb/private-dns/connect-devices/mobile-and-desktop/android/)
- [ ] **Não** AdGuard DNS app / AdGuard Ad Blocker Local VPN / AdGuard VPN + VPN no mesmo aparelho sem pedido (app DNS: “VPN-based protocol” / VPN profile)
- [ ] Linked IP = plain DNS + IP residencial; refresh `linkip.adguard-dns.com/linkip/{ServerID}/{UniqueKey}` ou DDNS — [Linked IP](https://adguard-dns.io/kb/private-dns/connect-devices/other-options/linked-ip/)
- [ ] DoH-auth + Deny other protocols via AdGuard apps/DNS Client (não Private DNS SO) — [DoH auth](https://adguard-dns.io/kb/private-dns/connect-devices/other-options/doh-authentication/)
- [ ] Access: Allowed tem prioridade; allowlist estrita = Disallowed `0.0.0.0/0` + `::/0` **e** Allowed com IPs; allow sozinho não basta — [Access](https://adguard-dns.io/kb/private-dns/server-and-settings/access/) + overview
- [ ] Allowed clients **não** contam no limite de access rules; só disallowed clients/domains — overview
- [ ] Requests negados pelo Access ≠ Query log e gratuitos — Access + overview
- [ ] Não auto-bloquear o próprio IP; se travar, desconectar DNS e corrigir Access — Access
- [ ] Log IP addresses off por default; ligar só se necessário (Advanced) — Access + Advanced
- [ ] Setup ID privado; reset invalida links; auto-connect Advanced — [Advanced](https://adguard-dns.io/kb/private-dns/server-and-settings/advanced/) / [Automatic](https://adguard-dns.io/kb/private-dns/connect-devices/other-options/automatic-connection/)
- [ ] Rate limit DNS: aumento só Team/Enterprise (Account settings → Rate limit) — [Rate limit](https://adguard-dns.io/kb/private-dns/server-and-settings/rate-limit/)
- [ ] User API: `ApiKey` ou Bearer; PKCE recomendado para apps públicos; OpenAPI `api.adguard-dns.io/swagger/openapi.json` — [API overview](https://adguard-dns.io/kb/private-dns/api/overview/)
- [ ] DoH JSON Public (`dns.adguard-dns.com/resolve`) ≠ User REST API de devices — [Public overview](https://adguard-dns.io/kb/public-dns/overview/)
- [ ] Stats/Query log filtráveis por **device** — Private overview
- [ ] dispositivo Android: sem install; sem AdGuard VPN+VPN; estado remoto = NÃO VALIDADO
