# Checklist — higiene Android (dispositivo Android / Android)

Fontes sustentam cada bloco (notas `2026-09-14-android-consumer-security.md` + `2026-09-18-17-android-private-dns-find-hub-theft.md` + **`2026-09-20-26-android-find-hub-theft-protection-refresh.md`** + **`2026-09-18-20b-android-restricted-settings-admin-overlay.md`** + **`2026-09-18-27-hyperos-autostart-battery-powerkeeper.md`** + **`2026-09-20-20-android-play-protect-developer-verification.md`** + **`2026-09-20-22-android-advanced-protection-accessibility.md`**). Sem bridge/ADB: itens de UI = só inspeção humana; Nexo Guard não afirma estado remoto.
**Atualizado:** 2026-09-21 ~11:22 BRT (+ CERT.br Furto de Celular `2026-09-21-15`).

## Play Protect / apps
- [ ] Play Protect ativo e sem alertas; se houver sideload, “Improve harmful app detection” ligado (support.google.com/googleplay/answer/2812853)
- [ ] Scan manual sob demanda em Play Store → Play Protect quando houver dúvida (client-protections: on-demand + daily)
- [ ] Play Store → Settings → About → Play Protect certification = certified (quando aplicável)
- [ ] Erro “Device is not certified” → Fix device issue no About; **não** desligar Scan apps with Play Protect (Help 2812853 — certificação ≠ scan)
- [ ] Tratar aviso Play Protect de app **unverified** + permissões sensíveis (fraude financeira) como bloqueio — não forçar install (Help 2812853)
- [ ] Privacy alert / Unwanted Software Policy: preferir Uninstall; não “re-enable” PHA disabled sem causa clara
- [ ] Apps só de Play Store / F-Droid conhecidos; sideload justificado + scan Play Protect (+ code-level se Play Protect recomendar)
- [ ] “Instalar apps desconhecidos”: só origens necessárias (ex. F-Droid); revogar após uso pontual

## Permissões de alto impacto (UI)
- [ ] Sem apps desconhecidos com acessibilidade / sobreposição / admin (revisão na UI — sem ADB não dá para afirmar remotamente)
- [ ] Contas Google no aparelho = só as esperadas (UI / myaccount.google.com)
- [ ] App Lock (Settings → Apps → App lock) em bancos / e-mail / apps sensíveis

## Restricted settings / Special access (Android 13+ / Android) — note 2026-09-18-20b
- [ ] Não usar **Allow restricted settings** (Settings → Apps → [app] → More) salvo app confiável com necessidade clara (ex. acessibilidade legítima) — support.google.com/android/answer/12623953
- [ ] Se sideload pedir Allow restricted settings + accessibility / notification access sob pressão → tratar como scam (sinais na mesma Help)
- [ ] Android: Settings → Privacy protection → Special permissions → revisar quais apps têm cada permissão especial (FAQ mi.com KA-497648; caminho pode variar no A5)
- [ ] Settings → Apps → Special app access → **Display over other apps**: só apps necessários; revogar desconhecidos (developer.android.com/training/permissions/requesting-special; support.google.com/googlepay/answer/10728104 — risco overlay em pagamento)
- [ ] Special app access → **Notification access**: só companions/leitores conhecidos; revogar o resto (support.google.com/messages/answer/10252674 — tip OTP autofill)
- [ ] Security → (advanced) **Device admin apps** / equivalente Android: desativar admin não reconhecido **antes** de desinstalar (support.google.com/pixelphone/answer/2824802 Pixel; developer.android.com/work/device-admin — unregister primeiro)
- [ ] Distinguir mentalmente Device Admin legado vs Device Owner/Profile Owner enterprise; Owner inesperado = incidente (DevicePolicyManager docs) — sem UI não afirmar presença

## Private DNS (DoT)
- [ ] Settings → Network & internet → Private DNS: modo consciente (Off / Automatic / hostname)
- [ ] Se hostname: servidor conhecido (ex. `dns.google` per developers.google.com/speed/public-dns/docs/using); testar conectividade; strict fail = sem internet
- [ ] Lembrar: Private DNS ≠ VPN; não substitui VPN; apps com DNS próprio podem bypass (blog Android P)
- [ ] Com VPN ligado + MagicDNS/Override: preferir Private DNS Off/Automatic; hostname DoT estrito pode quebrar resolução (nota `2026-09-20-21`; conflito comunitário #4252 ≠ doc oficial)

## Find Hub (antes de perder o aparelho) — refresh `2026-09-20-26`
- [ ] Location on; Security → Find Hub → “Allow device to be located” on (support.google.com/android/answer/3265955)
- [ ] Device listado em android.com/find (sign-in conta do **perfil principal**)
- [ ] play.google.com/library/devices → “Show In Menus” (esconder remove do Find Hub)
- [ ] Offline finding: Off / Without network / Busy places / Everywhere — trade-off privacidade; rede exige screen lock (3265955)
- [ ] 2SV: backup codes (ou security key) gerados — necessário se o telefone era 2º fator (3265955 Step 8)
- [ ] IMEI anotado offline (About phone **ou** Find Hub → Settings) para operadora/BO (6160491)
- [ ] Android 12+: decidir IMEI no lock screen — Security & Privacy → Lost Device Protection / Theft Protection (default on se Personal Safety sharing; Android path NÃO VALIDADO)
- [ ] App Find Hub: Guest Mode = ajudar amigo; próprio device = Continue as [name] (6160491)
- [ ] Mark as lost 2SV (PIN+biometria, Android **17+**) = horizonte; dispositivo Android=15 → Mark as lost clássico (só screen lock)

## Theft Protection / Remote Lock — refresh `2026-09-20-26`
- [ ] Settings → Google → All services → Theft protection: revisar o que o modelo oferece (cinza = não suportado; Go/tablet/wearable = fora)
- [ ] Remote Lock on + número verificado; saber usar android.com/lock (máx. **2 locks/24h** — Offline Device Lock compartilha teto)
- [ ] Security question opcional: resposta errada = lock **falha**; esperar minutos após Set (15146908)
- [ ] Não disparar lock de “teste” sem necessidade
- [ ] Theft Detection Lock: se não cinza — saber que **não** dispara com tela já locked; pode falhar com Wi‑Fi/BT estáveis ou locks repetidos
- [ ] Offline Device Lock: phone unlocked ao perder net; short period offline → lock
- [ ] Failed Authentication Lock / protect sensitive settings: Help diz on by default com lock screen (Android 15+ em parte) — presença Android NÃO VALIDADO
- [ ] Identity Check: só se listado; fora de trusted places biometria obrigatória p/ desligar Find Hub / factory reset / Developer options / recovery — A5 NÃO VALIDADO
- [ ] Pós-perda ordem: android.com/lock → Find Hub (locate / Mark as lost / erase) → conta Google → Celular Seguro se furto BR


## Autostart / bateria / hibernação (Android + stock) — note 2026-09-18-27
- [ ] Settings → Apps → Permissions → **Background autostart**: só apps com necessidade clara (notificação/boot); desconhecidos/sideload = OFF (mi.com KA-507608; default off — dev.mi.com pId=1624)
- [ ] Manage apps → [app] → Battery saver / Settings → Battery → [app]: **No restrictions** só para apps legítimos que precisam de rede/background contínuo; não em massa (KA-538010; Powerkeeper 无限制 — dev.mi.com pId=1628)
- [ ] App info → Unused apps: **Pause app activity if unused** OFF só em apps raros-mas-críticos; resto pode hibernar (support.google.com/android/answer/13627979; developer.android.com/topic/performance/app-hibernation)
- [ ] Apps → Unused apps: revisar o que o SO já hibernou (permissões revogadas / sem push)
- [ ] Battery → Current mode: evitar **Battery saver** global se depender de sync/VPN/notificação — congela apps em background (KA-501093 dispositivo Android 13C FAQ; caminho pode variar no A5)
- [ ] Entender camadas distintas: Autostart Android ≠ No restrictions Powerkeeper ≠ isenção Doze stock (`isIgnoringBatteryOptimizations`) — Doze/App Standby: developer.android.com/training/monitoring-device-state/doze-standby
- [ ] Se usar AdGuard Local VPN (só se Bruno pedir): receita KB Autostart + No restrictions + Pause unused OFF — adguard.com/kb/.../background-work/ § Android 13+/Android; **não** + VPN no mesmo aparelho sem pedido
- [ ] Sinal incidente: Autostart ON + overlay + accessibility + device admin em app não assistivo (cruzar Restricted settings — note 20b)

## Conta Google (ver também identidade-conta.md)
- [ ] 2SV Google ligado; sessões web revisadas
- [ ] Devices em google.com/devices = só esperados; Sign out no resto
- [ ] OAuth / linked apps auditados; Remove access no que não usa
- [ ] Alertas de segurança tratados; nunca enviar código 2SV a terceiros

## Rede / terminal Android / firmware (contexto Bruno)
- [ ] Smart home / câmeras: só apps intencionais; Tuya/OAuth revistos
- [ ] terminal Android: sshd só quando monitorar; chave ed25519; porta 8022 (quando bridge existir)
- [ ] VPN: só dispositivos conhecidos na rede VPN (quando bridge existir); Android sem shields-up — grants no console
- [ ] Wireless debugging: off quando idle; Forget/Revoke pares ADB; Always allow só Wi‑Fi casa; USB p/ auditoria (nota `2026-09-20-21`)
- [ ] ADB Wi-Fi 2.0 (Android 17) **não** aplicar mentalmente ao dispositivo Android (15)
- [ ] Sem Magisk / unlock bootloader (boot verde)
- [ ] Baseline de pacotes: existe desde 2026-10-04 11:22 BRT em `../baseline/android/` (32 terceiros, 292 total, patch 2026-08-01). Checar com `../playbooks/android-check.sh`; após instalar/remover app de propósito, Bruno confirma → `--accept-baseline`
- [ ] Sem root, pelo terminal Android: **funciona** `getprop`, `pm list packages -3 -i`, `pm list packages` (11:22 BRT). **Negado** (auditoria do Nexo 11:11–11:25, não retestado por mim): `settings get`, `dumpsys`, `appops`, `device_policy` → acessibilidade/notificações/ADB/Play Protect/DNS privado só pela UI
- [ ] Instalador ≠ Play/F-Droid hoje é esperado: loja do fabricante (`<LOJA_DO_FABRICANTE>`: RAR, Meu gov.br, Wallpaper Carousel), APK manual (terminal Android, F-Droid), `null` (Calendar/Calculator Go, Celular Legal). App novo com instalador fora de Play/F-Droid = perguntar ao Bruno
- [ ] `pm`/`cmd` via SSH comem o stdin: usar `</dev/null` e `ssh -n`
- [ ] IMEI anotado offline (About phone / Find Hub) para operadora/boletim

## Pós-perda (ordem mental)
- [ ] Remote Lock (android.com/lock; security answer se configurada) → Find Hub (locate / Mark as lost / erase) → myaccount (sessões/senha) → Celular Seguro se furto BR — ver resposta-incidente.md §4 + §12 + nota `2026-09-20-26`

## Developer verification / advanced flow (BR — nota 2026-09-20-20)
- [ ] Saber: a partir de **2026-09-30** (BR/ID/SG/TH) installs/updates nas lojas participantes (Play, GetApps/Android, Galaxy, OPPO, Honor, vivo, Transsion) em devices **certificados** exigem app registrado por desenvolvedor verificado — guides + Help 17065026. **Não afirmar** se já ativo no dispositivo Android sem UI.
- [ ] Verification = **identidade** do desenvolvedor, **não** review do APK (Console Help 16561738). App “verificado” ≠ app seguro.
- [ ] Sept 2026 = **só** lojas da lista; sideload direto / lojas fora da lista ainda sem enforcement nessa data (FAQ July 2026) — preparação para expansão **2027**.
- [ ] Serviço `com.google.android.verifier` (Android Developer Verifier) — Help 17065026; presença/versão = NÃO VALIDADO sem UI.
- [ ] Bloqueio “unverified developer”: preferir pedir ao desenvolvedor completar verification; **não** aceitar coaching por telefone/WhatsApp para bypass.
- [ ] Advanced flow (só se Bruno decidir sozinho): Developer Options → anti-coaching → restart → espera **24 h** → reauth PIN/biometria → **7 days** (preferível a indefinite) → ainda “Install anyway” (FAQ). Depois: desligar Developer Options se apps bancários exigirem; revogar Install unknown apps.
- [ ] Com advanced flow **off**: updates de apps unregistered **falham** (salvo ADB) — FAQ. Não ligar ADB só para pular a espera.
- [ ] ADB isento do waiting period — superfície própria; **não** remount/wireless debugging nesta higiene sem pedido.
- [ ] Android: caminho GetApps / rótulos “Apps from unverified developers” = **NÃO VALIDADO** no A5 sem UI.

## Advanced Protection / Accessibility (2026-09-20 — nota 22)

**Nota:** `notes/2026-09-20-22-android-advanced-protection-accessibility.md`  
Fontes: Help Android 16339980 + 12623953; Play Console 10964491; Developers accessibility service + AAPM (acesso **2026-09-20**)

- [ ] Accessibility: só serviços assistivos esperados (TalkBack / Switch Access / Voice Access etc.); desligar o resto (UI — sem bridge não afirmar)
- [ ] Pedido de acessibilidade por app **não** assistivo conhecido (banco “segurança”, cleaner, “otimizador”, APK de mensagem) → recusar; tratar como scam até prova contrária
- [ ] Não usar **Allow restricted settings** salvo app confiável com necessidade clara (Help 12623953) — sideload + pressão = incidente
- [ ] Play policy: `isAccessibilityTool` só deficiência; antivirus / automation / password managers / launchers **não** são tools (10964491)
- [ ] Se menu **Advanced Protection → Device protection** existir: saber trade-off — restringe accessibility a verified tools; bloqueia unknown apps; Play Protect não desliga; USB/theft/Scam Detection (Help 16339980)
- [ ] AAPM / Device protection: docs Developers = Android **16**; dispositivo Android = 15 → **presença no Android = NÃO VALIDADO** sem UI; não ligar “por notícia”
- [ ] “Apps that checked for Device protection” = Android **16** only (Help) — ignorar no A5
- [ ] Com Device protection on: automation / password managers que dependem de accessibility podem quebrar — decisão consciente, não tip automático

## Private Space (Android 15+ — 2026-09-20)
- [ ] Se menu existir: conta Google dedicada; lock distinto; Hide when locked (Help 15341885; nota `2026-09-20-16-…`) — Android NÃO VALIDADO
- [ ] Apps no Private Space **bypass VPN** do device (VPN/AdGuard Local VPN) — não meter terminal Android/VPN “dentro” esperando tunnel
- [ ] Sem Find Hub no private space; sem backup do space no device backup

## PIN do SIM (2026-09-20)
- [ ] SIM PIN ativo + PIN padrão da operadora alterado (CERT.br Celulares/Furto; nota `2026-09-20-14-…`) — só UI local; sem bridge não afirmar

## CERT.br Celulares e Tablets (2026-09-21)

**Nota:** `notes/2026-09-21-07-certbr-protecao-de-dados-celulares-tablets.md`  
Fonte: [Celulares e Tablets](https://cartilha.cert.br/fasciculos/celulares-e-tablets/fasciculo-celulares-e-tablets.pdf) (out/2022) · acesso **2026-09-21**  
Sem bridge: itens de UI = inspeção humana; não afirmar estado remoto.

- [ ] **NOVO** Apps só de loja oficial (Play / fabricante); nunca APK de mensagem; confirmar **nome + desenvolvedor** antes de instalar
- [ ] Updates: SO + apps + wearables/fones; auto-update quando possível; desinstalar o que não usa
- [ ] **NOVO** Lock screen: senha longa (preferir alfanumérica); evitar padrão curto/simples; auto-lock no **menor** tempo
- [ ] **NOVO** Lock screen: desligar preview de mensagens/notif e atalhos rápidos de settings
- [ ] SIM PIN ativo + PIN padrão da operadora alterado (já em PIN do SIM / nota 20-14)
- [ ] **NOVO** Empréstimo: perfil convidado **ou** Fixação de Tela (Android) / Acesso Guiado (iOS); parental se criança
- [ ] Wi‑Fi público: confirmar SSID com estabelecimento; https; finanças só em rede confiável; VPN **só** se Bruno pedir e **sem** VPN no mesmo aparelho
- [ ] **NOVO** Proximidade: BT/NFC pareamento só acessórios próprios; NFC pagamento **com** autenticação; Nearby Share só quando necessário; BT off quando idle
- [ ] Find Hub / IMEI / furto: ver secções Find Hub + Theft + IR §4/§12 (já cobertos)
- [ ] **NOVO** Compra usado: desvinculado da conta anterior; IMEI em [Anatel Celular Legal](https://www.gov.br/anatel/pt-br/assuntos/celular-legal/); factory reset **antes** de usar
- [ ] Compra novo: preferir modelo com prazo de updates conhecido + recursos de segurança alinhados ao uso
- [ ] **NOVO** Descarte/repasse: Remover conta → factory reset (apagar tudo) → tirar de dispositivos confiáveis → revogar acessos do aparelho nas contas de apps → desparear acessórios BT


## CERT.br Furto de Celular — preparação (2026-09-21)

**Nota:** `notes/2026-09-21-15-certbr-furto-de-celular.md` · fascículo Furto (nov/2024)  
Pós-furto: `resposta-incidente.md` §12 + **§24**. Sem bridge: UI = inspeção humana.

- [ ] **NOVO** Lock screen: sem preview de mensagens; sem atalhos rápidos de settings (CERT.br Furto)
- [ ] **NOVO** App Lock / biometria em bancos, e-mail, notas sensíveis; ocultar (Private Space / Pasta Segura) só se aceitar silêncio de notif
- [ ] **NOVO** Fixação de Tela on + usar em via pública (GPS / transporte / chat com tela aberta)
- [ ] SIM PIN + IMEI offline (`*#06#` / About / Find Hub) — já em secções PIN/Find Hub; reconfirmar
- [ ] Theft Protection: detecção / off-line / Remote Lock conforme modelo (já em Theft; A5 = só UI)
- [ ] **NOVO** Limites Pix/TED do app do banco reduzidos preventivamente (cruzar phishing / IR §24)
- [ ] Celular Seguro + Contato de Confiança cadastrados **antes** (IR §12)
- [ ] Códigos 2SV offline + número recovery alternativo (cruzar identidade)

## Lock screen — delta CERT.br Autenticação (2026-09-21)

**Nota:** `notes/2026-09-21-09-certbr-autenticacao.md` · fascículo Autenticação (nov/2022)  
Complementa itens de lock em Celulares/Tablets (`2026-09-21-07`) e Furto.

- [ ] **NOVO** Bloquear tela **antes** de sair de perto do aparelho (não só auto-lock)
- [ ] **NOVO** Reconhecimento facial: exigir **atenção** (anti-desbloqueio passivo) se a UI oferecer
- [ ] **NOVO** Padrão de desbloqueio: evitar poucos pontos / desenhos simples (letras); configurar **rastro invisível**
- [ ] **NOVO** Preferir PIN/senha longa a padrão quando possível (já em Celulares; reforço CERT.br)
- [ ] Sem UI local: não afirmar estado de lock/face/padrão no dispositivo Android/Tab


## CERT.br Códigos Maliciosos / Redes — deltas Android (2026-09-21)

**Notas:** `2026-09-21-10-…` · `2026-09-21-11-…`

- [ ] **NOVO** Loja oficial + confirmar desenvolvedor; nunca APK de mensagem (já Play Protect — reforço CERT.br)
- [ ] **NOVO** Scareware popup → não instalar AV oferecido
- [ ] **NOVO** Suspeita malware: AV/scan → reboot → factory reset se sintomas → trocar senhas usadas no device (IR §22)
- [ ] **NOVO** Device furtado que estava no Wi‑Fi de casa → trocar senha Wi‑Fi (e admin do roteador se compartilhada)
- [ ] Guest Wi‑Fi para visitas/IoT; principal só confiança — sem afirmar se guest existe no roteador do ISP sem UI


## CERT.br Backup — celular (2026-09-21)

**Nota:** `notes/2026-09-21-14-certbr-backup.md` · cruzar Google One `2026-09-19-17`

- [ ] **NOVO** Backup nativo habilitado; Wi‑Fi only se plano de dados limitado
- [ ] **NOVO** Alternativa: sync/PC ou mídia; ≥1 cópia fora da nuvem quando possível
- [ ] **NOVO** Manual antes de troca/manutenção/viagem (“Backup agora”)
- [ ] Sem bridge/UI: **não** afirmar estado do backup no dispositivo Android

