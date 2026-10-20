# Checklist — identidade e conta Google

## Base (overview AAAA-MM-DD)

- [ ] Security Checkup feito (myaccount.google.com → Security / security-checkup) — [12629482](https://support.google.com/accounts/answer/12629482)
- [ ] 2SV ligado; segundo fator preferencial: passkey / security key / Google Prompt / Authenticator (evitar SMS se possível) — [185839](https://support.google.com/accounts/answer/185839); CERT.br fascículo Autenticação
- [ ] Códigos de backup gerados e guardados offline; Refresh se suspeita de vazamento
- [ ] Recovery phone e recovery email preenchidos e sob seu controle — sinais se alterados sem você: [140921](https://support.google.com/accounts/answer/140921)
- [ ] Devices: só os esperados; Sign out no resto — [google.com/devices](https://google.com/devices) / [3067630](https://support.google.com/accounts/answer/3067630)
- [ ] Apps com Access to your Google Account auditados; remover o que não usa; escopos mínimos — [13533235](https://support.google.com/accounts/answer/13533235)
- [ ] Sign in with Google / Linked accounts revisados (parar SSO de apps abandonados) — [13533235](https://support.google.com/accounts/answer/13533235)
- [ ] Alertas de segurança respondidos na hora (Yes / No, secure account) — [2590353](https://support.google.com/accounts/answer/2590353)
- [ ] Nunca compartilhar código 2SV, backup code ou senha (Google não liga pedindo) — CERT.br; [6063333](https://support.google.com/accounts/answer/6063333)
- [ ] Pós-alerta: senha nova + sessões encerradas + OAuth revisado + senhas reutilizadas trocadas — [6294825](https://support.google.com/accounts/answer/6294825)
- [ ] Gmail: sem forwarding/filtros/delegação/IMAP-POP/scheduled/vacation desconhecidos (UI Gmail settings) — [6294825](https://support.google.com/accounts/answer/6294825)
- [ ] Play / Pay: métodos de pagamento e compras reconhecidos — [6294825](https://support.google.com/accounts/answer/6294825)
- [ ] Sem ADB / sem bridge: não afirmar estado de contas no aparelho nem 2SV “no telefone” — só via myaccount / UI

## NOVOS (aprofundamento AAAA-MM-DD-15 — fontes oficiais)

- [ ] **NOVO** Ao auditar devices: tratar **sessões** separadas (browser novo, reauth, OAuth grant, incognito) como normais no mesmo aparelho; se dúvida no mesmo nome → Sign out em **todas** as sessões — [3067630](https://support.google.com/accounts/answer/3067630)
- [ ] **NOVO** Não alarmar só pelo horário “recente”: timestamp = última **comunicação** (inclui sync background) — [3067630](https://support.google.com/accounts/answer/3067630)
- [ ] **NOVO** Device perdido: Security → Your devices → Sign out (Account Access); se senha ficou em device alheio → mudar senha + sign-out — [7177579](https://support.google.com/accounts/answer/7177579); [54490](https://support.google.com/accounts/answer/54490)
- [ ] **NOVO** Recent security events → Review security events após alerta “suspicious sign-in prevented”; ir a myaccount direto (desconfiar de e-mail clone) — [6063333](https://support.google.com/accounts/answer/6063333)
- [ ] **NOVO** Distinguir na UI: **Stop using Sign in with Google** (SSO; não apaga dados no app) vs **Remove access** (OAuth; para tokens futuros; dados já retidos podem ficar no desenvolvedor) vs **Delete link** (Linked account) — [13533235](https://support.google.com/accounts/answer/13533235); [14012355](https://support.google.com/accounts/answer/14012355)
- [ ] **NOVO** Passkeys: criar só em devices pessoais; se device perdido → Remove passkey / Sign out do device — [13548313](https://support.google.com/accounts/answer/13548313)
- [ ] **NOVO** App passwords: preferir não usar; se existirem, revogar os de apps/devices abandonados; saber que **password change revoga todos** — [185833](https://support.google.com/accounts/answer/185833)
- [ ] **NOVO** Pós-suspeita: checklist Gmail settings completo (delegation, forwarding, filters, labels, IMAP/POP, scheduled, vacation, blocked, “sent” estranho) — [6294825](https://support.google.com/accounts/answer/6294825); [140921](https://support.google.com/accounts/answer/140921)
- [ ] **NOVO** Notificação Android “Did you just sign in?”: No → sign-out em outros devices — [7305876](https://support.google.com/accounts/answer/7305876)


## NOVOS (aprofundamento AAAA-MM-DD-13 — APP / 2SV keys / prompts / Authenticator / backup codes)

- [ ] **NOVO** Distinguir 2SV “forte” (prompt/Authenticator/key/passkey) de **Advanced Protection Program** (obriga passkey/security key + restringe apps sensíveis + download checks + recovery apertado) — [7519408](https://support.google.com/accounts/answer/7519408); [7539956](https://support.google.com/accounts/answer/7539956)
- [ ] **NOVO** Antes de considerar APP: recovery phone+email sob seu controle; 2SV on; backup passkey/key; listar apps que leem Gmail/Drive (podem quebrar) — [7539956](https://support.google.com/accounts/answer/7539956)
- [ ] **NOVO** Sob APP: app passwords revogados/bloqueados; **não** dá para download de backup codes; e-mail via Gmail / verified clients — [7539956](https://support.google.com/accounts/answer/7539956); [1187538](https://support.google.com/accounts/answer/1187538)
- [ ] **NOVO** Android com APP: Play Protect auto; sideload limitado a Play / ADB / preinstalled stores; apps fora da Play já instalados permanecem; warnings “not approved”; unenroll ou remover conta + force-stop Play Store (até 24h) — [9764949](https://support.google.com/accounts/answer/9764949)
- [ ] **NOVO** Hierarquia sem APP: passkey/security key > Google prompts > Authenticator > SMS/voice; CERT.br: chave física ou app > SMS — [185839](https://support.google.com/accounts/answer/185839); [7026266](https://support.google.com/accounts/answer/7026266); [cartilha Autenticação](https://cartilha.cert.br/fasciculos/autenticacao/fasciculo-autenticacao.pdf)
- [ ] **NOVO** Security key: FIDO1/FIDO2 como 2º passo; passkey-on-key exige FIDO2; esperar até 7d (ou speed-up); suspicious key → confirmar em 30d; lost → outro 2º passo ou recovery 3–5 dias úteis — [6103523](https://support.google.com/accounts/answer/6103523); [9153624](https://support.google.com/accounts/answer/9153624)
- [ ] **NOVO** Prompt “Trying to sign in?” sem você: tap **No**; phone perdido → Sign out do device — [7026266](https://support.google.com/accounts/answer/7026266)
- [ ] **NOVO** Authenticator: preferir sync + Privacy Screen; delay até 7d; device lost → remote erase / remove device se sync — [1066447](https://support.google.com/accounts/answer/1066447)
- [ ] **NOVO** Backup codes: set de 10×8 dígitos offline; Refresh se vazamento (old set inactive); Google só pede no sign-in — [1187538](https://support.google.com/accounts/answer/1187538)
- [ ] **NOVO** iPhone+iCloud+APP: restore de backup pode re-assinar Google Account — Google recomenda security keys na conta iCloud — [7539956](https://support.google.com/accounts/answer/7539956)
- [ ] **NOVO** Nest/Home: se APP, Google recomenda APP em todos home members (blast radius de members) — [7539956](https://support.google.com/accounts/answer/7539956)
- [ ] **NOVO** Unenroll APP: Security → Advanced Protection Program → Unenroll (device já signed in) — [7539956](https://support.google.com/accounts/answer/7539956)
- [ ] **NOVO** Sem bridge/ADB: não afirmar se APP/2SV/keys estão ativos nas contas ou no dispositivo Android — só myaccount / UI


## NOVOS (aprofundamento AAAA-MM-DD-19 — passkeys operacionais / at-risk / recovery)

**Nota:** `notes/<nota>.md`  
Fontes: [13548313](https://support.google.com/accounts/answer/13548313) · [17137073](https://support.google.com/accounts/answer/17137073) · [183723](https://support.google.com/accounts/answer/183723) · [7682439](https://support.google.com/accounts/answer/7682439) (acesso **AAAA-MM-DD**)

- [ ] **NOVO** Passkeys só em devices pessoais; shared device = quem unlock acessa a conta — [13548313](https://support.google.com/accounts/answer/13548313)
- [ ] **NOVO** Inventário `myaccount.google.com/signinoptions/passkeys`; Remove em perdido/compartilhado; auto-passkey Android → Sign out do device se preciso — [13548313](https://support.google.com/accounts/answer/13548313)
- [ ] **NOVO** Skip password when possible: ligado = passkey-first; desligar se preferir senha primeiro (passkey ainda como 2º passo com 2SV) — [13548313](https://support.google.com/accounts/answer/13548313)
- [ ] **NOVO** Manter ≥1 **trusted** passkey ou security key (Re-enable at-risk + speed-up de métodos novos) — [17137073](https://support.google.com/accounts/answer/17137073)
- [ ] **NOVO** Alerta at-risk / suspicious method: Re-enable só se for você (exige trusted key); senão Remove + senha + hygiene; sem ação → auto-remove **30 d** — [17137073](https://support.google.com/accounts/answer/17137073)
- [ ] **NOVO** Métodos novos (passkey/phone/Authenticator/recovery phone): até **7 d** para valer; Approve/speed-up só com trusted passkey/key — [17137073](https://support.google.com/accounts/answer/17137073); [183723](https://support.google.com/accounts/answer/183723)
- [ ] **NOVO** Recovery phone **≠** Google Voice; recovery email ≠ sign-in; contacts só confiança (request 7d + wait 7d pós-aceite) — [183723](https://support.google.com/accounts/answer/183723)
- [ ] **NOVO** Selfie recovery: indisponível sob APP / Workspace / Child — [183723](https://support.google.com/accounts/answer/183723)
- [ ] **NOVO** Lockout: account recovery oficial; Google **não** liga/ajuda por telefone; recusar “serviços recovery” de terceiros — [7682439](https://support.google.com/accounts/answer/7682439)
- [ ] **NOVO** Sem myaccount UI: não afirmar se passkeys/Skip/at-risk/recovery estão configurados nas contas do dono


## NOVOS (aprofundamento AAAA-MM-DD-02 — Security Checkup / Recommended actions)

**Nota:** `notes/<nota>.md`  
Fontes: [12629482](https://support.google.com/accounts/answer/12629482) · [46526](https://support.google.com/accounts/answer/46526) (acesso **AAAA-MM-DD**)

- [ ] **NOVO** Security Checkup regularmente; entrada perfil → Recommended actions (ou Security & sign-in) — [12629482](https://support.google.com/accounts/answer/12629482); [46526](https://support.google.com/accounts/answer/46526)
- [ ] **NOVO** Cores Recommended actions: azul=tips · amarelo=importante · vermelho=urgente; shield verde+check = saudável — [46526](https://support.google.com/accounts/answer/46526)
- [ ] **NOVO** Checkup Step 1 cobre: recovery · passkey · 2SV (keys/prompts > SMS) · APP se alvo · Remove risky app access · screen locks — [46526](https://support.google.com/accounts/answer/46526)
- [ ] **NOVO** Password Checkup + Password Alert no Chrome; Google nunca pede senha por e-mail/ligação/mensagem — [46526](https://support.google.com/accounts/answer/46526)
- [ ] **NOVO** Sem myaccount: não afirmar se Checkup/cores estão limpos nas contas do dono


## NOVOS (aprofundamento AAAA-MM-DD-09 — CERT.br Autenticação fascículo)

**Nota:** `notes/<nota>.md`  
**Fonte:** [fascículo Autenticação](https://cartilha.cert.br/fasciculos/autenticacao/fasciculo-autenticacao.pdf) (nov/2022; pdftotext `_src/autenticacao.pdf`; acesso **AAAA-MM-DD**)

- [ ] **NOVO** 2SV on em contas críticas; hierarquia CERT.br: chave física U2F/FIDO/FIDO2 (ou celular como chave) > app TOTP > SMS/voz **só** se não houver outra opção
- [ ] **NOVO** Sem 2SV no serviço: reforçar senha única + forte + armazenamento seguro (não relaxar)
- [ ] **NOVO** Negar **toda** autorização/push de login que você não iniciou
- [ ] **NOVO** Backup codes gerados + offline; se perder/suspeitar acesso → **revogar e regenerar**
- [ ] **NOVO** Senha **única** por conta; reusada vazada → trocar **em todos** os serviços onde era usada
- [ ] **NOVO** Senha forte: longa (ex. 3 palavras aleatórias) + charset misto; sem sequência de teclado; sem PII de redes sociais
- [ ] **NOVO** Armazenar: gerenciador **ou** papel em local seguro **ou** arquivo criptografado
- [ ] **NOVO** Contas valiosas (banco / e-mail / ID sistema): **não** salvar no browser; **sem** login automático
- [ ] **NOVO** Nunca repassar senha ou código 2SV por mensagem, e-mail ou ligação
- [ ] **NOVO** Perguntas/dicas de segurança difíceis de adivinhar; dicas vagas p/ terceiros e claras p/ você; recovery e-mail que você acessa regularmente
- [ ] **NOVO** Login social (IdP): restringir escopos; eliminar acessos órfãos/suspeitos (blast radius em cascata)
- [ ] **NOVO** Alertas de login: checar onde/quando; indevido → URL **digitada** → senha nova → 2SV → sessões (sem clicar link do alerta)
- [ ] **NOVO** Não comprometer senha: links/QR só de fonte confiável; apps atualizados; sem digitar em equipamento de terceiros; HTTPS; shoulder-surfing/câmeras
- [ ] **NOVO** Contatos 2SV atualizados + e-mail/telefone **alternativos** para códigos
- [ ] **NOVO** Trusted device perdido/trocado → excluir nos serviços; chave física segura (perda → avisar serviço)
- [ ] **NOVO** Sem myaccount/UI: não afirmar se 2SV/backup/IdP/alertas estão configurados nas contas do dono


## CERT.br Computadores / Trabalho Remoto — deltas conta (AAAA-MM-DD)

**Notas:** `<nota>` · `<nota>`

- [ ] **NOVO** Lock PC: senha/biometria; exigir auth em screensaver/repouso; timeout mínimo
- [ ] **NOVO** Conta diária ≠ admin; 2SV na conta ID do sistema (Apple/Microsoft)
- [ ] **NOVO** Trabalho Remoto: **não** salvar senhas no browser; gerenciador ou arquivo cifrado
- [ ] **NOVO** 2SV obrigatório em VPN / webmail / nuvem quando existirem
- [ ] Data/hora automática + NTP (ntp.br) — TOTP/2SV dependem disso
- [ ] Sem UI: **não** marcar

