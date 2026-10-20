# Checklist — privacidade e dados

**Atualizado:** 2026-09-21 ~10:07 BRT (+ CERT.br Backup + Computadores).
Contexto: dispositivo Android / Android; bridge pode estar desmontada. Não afirmar estado remoto sem UI/bridge. Câmeras Intelbras/Positivo = do Bruno (memória); Tuya OAuth já revogado — reconfirmar na Google se houver suspeita. Private Space no Android = NÃO VALIDADO até checar menu.

## Permissões no telefone (UI) — refresh 2026-09-20 ~18:45
- [ ] Permission manager: Location / Camera / Microphone / Photos and videos / Files / Contacts — sem “All the time” desnecessário (Help 9431959)
- [ ] Health, Wellness, Fitness (Android 15-: pode aparecer **Body Sensors**) — negar sem necessidade vital
- [ ] Location: Approximate; Precise só se necessário (Help 6179507 — ~3 km² vs exact)
- [ ] Apps sensíveis: “Only while using” ou “Ask every time” para cam/mic/location
- [ ] Privacy Dashboard (Android 13+: últimos 7 dias; 12: 24h): Camera / Mic / Location / Photos — revogar usos indevidos (Help 13530434)
- [ ] Apps ociosos: “Pause app activity if unused” ligado
- [ ] Special app access: overlay / All files / Notification access — só o necessário
- [ ] Privacy controls: kill switch global Camera / Microphone (Help 9431959)
- [ ] Contacts: negar se app só convida/compartilha (horizonte Contact Picker Android 17 — Play 14115180; dispositivo Android=15 → NÃO VALIDADO UI picker)
- [ ] **Nearby devices** (Permission manager): Allow só fone/watch/cast/IoT ativo; Deny social/jogos/órfãos (Help 9431959; grupo Android 12+ — toggle all-or-nothing; Developers nearby Wi‑Fi)
- [ ] Bluetooth: Forget órfãos; off quando idle (Help 9417604)
- [ ] Restricted settings / Accessibility: sem “Allow restricted” por pedido de “suporte”; auditar serviços (Help 12623953)

## Photos / mídia — refresh 2026-09-20 ~17:43
**Nota:** `notes/2026-09-20-24-privacidade-photo-picker-partial-contacts.md`
- [ ] Preferir Photo Picker / “Select photos” (Help 13356023: até 100 itens; Browse = só selecionado; Android 13+)
- [ ] Android 14+ Selected Photos: parcial pode expirar (compat ≈ one-time ao background) — Developers partial access
- [ ] Após upgrade de OS: reauditar Permission manager → Photos and videos (full access pode ter sido herdado)
- [ ] App que exige “todas as fotos” sem ser galeria/editor amplo = suspeito (Play Restricted Permissions; compliance May 2025)
- [ ] Locked Folder para mídia sensível; decidir backup on/off (Photos 10694388)
- [ ] Consciente: Photos / MMS carrier sem E2E do screen lock no backup Google (2819582)

## Conta Google (myaccount) — My Activity refresh 2026-09-20 ~18:45
**Nota:** `notes/2026-09-20-25-privacidade-my-activity-nearby-local-network.md`
- [ ] Privacy Checkup percorrido
- [ ] History settings: Web & App / YouTube / Timeline; **Search Services History** se a UI já migrou (Search/Maps/Shopping/Flights/Hotels/Translate/News) — senão ainda via Web & App (Accounts 6139018 Important)
- [ ] Auto-delete **3 / 18 / 36** meses por setting; tip: certos location/IP somem em **30 d** (Accounts 465)
- [ ] Turn off ≠ apagar — usar **Turn off and delete** se quiser zerar (465 / 7028918)
- [ ] Require extra verification em My Activity se device compartilhado (7028918)
- [ ] Atividade estranha → Security Checkup / sessões **antes** de só apagar o item (7028918)
- [ ] Timeline / Other activity / Chrome history local ≠ só o feed My Activity (465)
- [ ] Incognito: signed-in na janela privada ainda pode salvar search na conta (7028918)
- [ ] Takeout só se precisar de cópia; lembrar: export ≠ apagar
- [ ] Access to your Google Account: sem Tuya/outros IoT abandonados

## Nearby / LAN (horizonte Android 17) — 2026-09-20 ~18:45
**Nota:** `notes/2026-09-20-25-…` · Developers local-network-permission
- [ ] Auditar Permission manager → Nearby devices (grupo BT+Wi‑Fi+UWB)
- [ ] Apps IoT/cast: preferir system picker / Output Switcher quando existir; Deny broad LAN se não precisar
- [ ] Consciente: Android **17** `ACCESS_LOCAL_NETWORK` (target 37+) — dispositivo Android=15 → UI local **NÃO VALIDADO**; legacy target < 37 ainda implícito via INTERNET

## Private Space (Android 15+ — se existir no aparelho) — refresh 2026-09-20
**Nota:** `notes/2026-09-20-16-android-private-space-vpn-vpn.md` (Help 15341885)
- [ ] Menu Settings → Security & privacy → Private space encontrado? (Android: NÃO VALIDADO)
- [ ] Se usar: Google Account **dedicada** (não signed-in noutro lugar); lock distinto; Hide when locked; auto-lock “Every time device locks”
- [ ] Não colocar apps que precisam de background/notificação com space locked (Help: apps param por completo)
- [ ] **VPN bypass:** apps do space **não** usam VpnService do device (VPN / AdGuard Local VPN) — Help 15341885
- [ ] Apps que precisam de VPN → fora do Private Space
- [ ] Consciente: ADB/logs/apps podem detectar o space; sem Find Hub no space; sem device backup do space
- [ ] Esqueceu lock do space → System → Reset options → Delete private space (tip: opção existe mesmo sem space)

## Smart home / IoT
- [ ] Membros/compartilhamentos do app de câmera revisados; sem link público se não precisar
- [ ] App + firmware atualizados; senha forte (+ 2FA se existir)
- [ ] Guest Wi-Fi / segregação IoT no roteador se disponível (CERT.br)
- [ ] Ao descartar aparelho IoT: factory reset + remover da conta

## Backup / encryption (Help 2819582, 9149304, Auto Backup; note 2026-09-19-17)
- [ ] Backup Google / Google One On; revisar **Backup details** (Settings → Google → Backup)
- [ ] Screen lock = **PIN / padrão / senha** (não swipe nem Smart Lock) — condição Help para E2E de device data (2819582)
- [ ] Consciente: **Photos (Google Photos) e MMS media da operadora NÃO** usam E2E do screen lock (2819582 / 9149304)
- [ ] Locked Folder: decidir **Back up Locked Folder** on/off; sem backup = perda no wipe / clear Photos / transfer (10694388)
- [ ] Storage: device backup (SMS/call/settings/app data) + WhatsApp backups **contam** na quota da conta (9004014)
- [ ] Sabendo: desligar backup **apaga** device backups (Photos já no serviço permanecem); **57 dias** sem usar o device também apaga device backup (9149304)
- [ ] Takeout = export (**não** apaga); archive ≠ delete (3024190)
- [ ] Segredos (códigos 2SV/reserva): gerar + cópia offline segura; revogar se perder/suspeitar (CERT.br fascículo Autenticação)
- [ ] Antes de wipe/venda: backup verificado → factory reset (6088915: conta+senha+lock; esperar 24h se resetou senha Google) → remover dispositivo das contas

## Apple iCloud / Advanced Data Protection (2026-09-20)

**Nota:** `notes/2026-09-20-18-apple-account-compromised-adp-recovery.md` · support.apple.com/102651

- [ ] Standard = default (Apple pode ajudar recovery na maioria dos dados)
- [ ] ADP = E2E em Backup/Photos/Notes/Drive…; recovery contact **ou** recovery key **antes** de ligar
- [ ] Sob ADP: Apple **não** recupera maioria dos dados se perder acesso; iCloud.com web off por default
- [ ] Mail/Contacts/Calendars **não** E2E; estado ADP Bruno = NÃO VALIDADO sem UI

## CERT.br Privacidade (fascículo — 2026-09-21)

**Nota:** `notes/2026-09-21-06-certbr-boatos-vazamento-privacidade.md`  
Fonte: [Privacidade](https://cartilha.cert.br/fasciculos/privacidade/fasciculo-privacidade.pdf) (ago/2023) · acesso **2026-09-21**

- [ ] **NOVO** Antes de postar: tratar como público permanente (“uma vez postado, sempre postado”)
- [ ] **NOVO** Intimidade: evitar compartilhar; se enviar, temporizador + sem rosto/marcas identificáveis; apagar antes de assistência técnica
- [ ] **NOVO** Crianças: sem fotos com pouca roupa; sem expor rotina; respeitar idade mínima de redes/jogos; galeria com lock
- [ ] Ajustar configs de privacidade (padrão costuma ser permissivo); permissões de app só compatíveis com a finalidade
- [ ] **NOVO** Cookies: bloquear terceiros; nos banners, só essenciais; modo anônimo quando fizer sentido
- [ ] Formulários/cadastros: fornecer só o necessário; recusar pedidos abusivos
- [ ] Redes: conta privada se possível; verificar identidade antes de aceitar; bloquear falsos
- [ ] Criptografia: https; criptografia de disco/mídia; preferir mensagens E2E
- [ ] Não compartilhar senha (“prova de amor”); device compartilhado = perfil separado / pin app / parental
- [ ] **NOVO** Descarte/troca de aparelho: desconectar ID → factory reset → remover SIM/SD → tirar de dispositivos confiáveis das contas
- [ ] IoT: reputação + patches do fabricante; assistente não always-listen se evitável; cobrir câmeras ociosas
- [ ] **NOVO** Cadastro/CPF por desconto: pesar uso/compartilhamento dos dados + risco de vazamento/golpe antes de autorizar
- [ ] LGPD/direitos: ver secção **Proteção de Dados** abaixo (fascículo jan/2024)

## CERT.br Proteção de Dados / LGPD preventiva (2026-09-21)

**Nota:** `notes/2026-09-21-07-certbr-protecao-de-dados-celulares-tablets.md`  
Fonte: [Proteção de Dados](https://cartilha.cert.br/fasciculos/protecao-de-dados/fasciculo-protecao-de-dados.pdf) (jan/2024, contrib. ANPD) · acesso **2026-09-21**

- [ ] **NOVO** Antes de cadastro: ler política (quais dados / finalidade / compartilhamento) + termos de consentimento; discordar = não usar o serviço
- [ ] **NOVO** Glossário: Titular · Controlador · Operador · Encarregado · dados pessoais (incl. hábitos) · dados sensíveis · anonimizado · ANPD
- [ ] **NOVO** LGPD cobre tratamento por orgs (públicas/privadas/terceiros) para fins econômicos — **não** uso puramente particular
- [ ] Abuso de tratamento: canal oficial do Controlador / Encarregado → se falhar: petição de Titular **ou** denúncia ANPD ([canais titular](https://gov.br/anpd/pt-br/canais_atendimento/cidadao-titular-de-dados/))
- [ ] **NOVO** Preferir serviços com https + 2SV; mensagens com E2E
- [ ] **NOVO** Sensíveis em repouso: criptografia nativa do SO; arquivos sensíveis criptografados **antes** de nuvem
- [ ] **NOVO** ≥1 backup offline; evitar confidenciais na nuvem quando possível (cruzar secção Backup)
- [ ] **NOVO** Mídias externas: conectar só no uso; guardar seguro
- [ ] Cookies terceiros / cadastro mínimo / CPF-desconto: já na secção Privacidade acima — manter

## CERT.br Redes Sociais — perfil / apps / reputação (2026-09-21)

**Nota:** `notes/2026-09-21-08-certbr-redes-sociais.md`  
Fonte: [Redes Sociais](https://cartilha.cert.br/fasciculos/redes-sociais/fasciculo-redes-sociais.pdf) (fev/2023) · acesso **2026-09-21**

- [ ] **NOVO** “Uma vez postado, sempre postado” — tratar rede como local público (cruzar § Privacidade)
- [ ] Conta privada + seletividade de contatos (já § Privacidade — manter; detalhe operacional na nota 21-08)
- [ ] **NOVO** Sem telefone/PII no perfil público; ajustar público-alvo das infos do perfil
- [ ] **NOVO** Listas de contatos / público diferenciado por post
- [ ] **NOVO** Inventário de apps/sites com OAuth na conta; revogar órfãos (jogos/testes/editores)
- [ ] **NOVO** Configurar revisão de marcações; pedir remoção se desconfortável
- [ ] **NOVO** Autorização antes de postar foto de terceiros ou republicar post alheio
- [ ] **NOVO** Separar redes/listas pessoal × profissional; respeitar política empresa/escola
- [ ] **NOVO** Não curtir/compartilhar violência, calúnia/difamação, discriminação

## CERT.br Backup (2026-09-21)

**Nota:** `notes/2026-09-21-14-certbr-backup.md` · fascículo Backup (maio/2023)  
Cruzar Google One E2E: `notes/2026-09-19-17-privacidade-backup-encryption-screenlock.md`

- [ ] **NOVO** ≥2 cópias em **locais diferentes** (ex. nuvem + pendrive/HD); “quem tem 1 não tem nenhum”
- [ ] **NOVO** Automático na frequência útil + **manual** antes de viagem / update SO / manutenção / troca de device
- [ ] **NOVO** Selecionar o que entra (excluir lixo; desligar backup de apps desnecessários)
- [ ] **NOVO** 2SV forte no provedor de nuvem de backup (chave > TOTP > SMS)
- [ ] **NOVO** Criptografar backup em nuvem **e** mídia; HTTPS no provedor
- [ ] **NOVO** Mídia offline: **não** deixar sempre conectada (ransomware apaga backup online)
- [ ] **NOVO** Monitorar notificações / espaço; smoke-test de restore de tempos em tempos; trocar mídia defeituosa
- [ ] Celular: backup nativo (Wi‑Fi only se plano limitado) + alternativa sync/PC
- [ ] Sem UI: **não** marcar itens como feitos

## CERT.br Computadores — disco / descarte PC (2026-09-21)

**Nota:** `notes/2026-09-21-12-certbr-computadores.md` · fascículo Computadores (abril/2024)

- [ ] **NOVO** Criptografia de disco nativa: FileVault (macOS) / BitLocker (Windows); cifrar externos/pendrives
- [ ] **NOVO** Descarte/venda PC: restore fábrica com wipe/overwrite; se impossível → sobrescrever ou ferramenta; disco pré-cifrado mitiga
- [ ] **NOVO** Compartilhamento de arquivos/discos: off se não usa; se usa → senha/perms + tempo mínimo; sem estranhos
- [ ] Sem UI Mac: **não** marcar FileVault/Find My como feitos

