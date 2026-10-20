# Checklist — resposta a incidente caseira (Trilha 7)

**Atualizado:** 2026-09-21 ~11:22 BRT (+ CERT.br Furto de Celular `2026-09-21-15`)

Playbook sob suspeita de takeover / credencial vazada. Higiene contínua: `identidade-conta.md` + `github-scm.md`. Bridge desmontada: sem afirmar estado remoto do dispositivo Android.

## 0. Evidência (antes de reset em massa)
- [ ] Anotar data-hora (America/Sao_Paulo), canal do alerta, device/hora/local **como exibidos**
- [ ] Listar sessões/devices visíveis (google.com/devices; GitHub Sessions) — screenshot se possível
- [ ] Listar mudanças críticas já vistas (recovery, OAuth, filtros Gmail) — **sem** colar senhas/códigos/PAT

## 1. Triagem
- [ ] Responder alerta Google na hora: **No, it wasn’t me** / **No, secure account** se não foi você
- [ ] Recent security events: marcar o que não reconhece
- [ ] Sinais Gmail/Play/Pay/NCSC triados (forwarding, compras, settings alterados)

## 2. Contenção Google (ordem)
- [ ] Devices: Sign out em sessões/devices não reconhecidos (todas as sessões do mesmo rótulo se incerto)
- [ ] Senha Google nova e única; depois senhas **reutilizadas** + Password Checkup
- [ ] Recovery phone + recovery email: só os seus; remover o que o atacante pôs
- [ ] 2SV on; métodos fortes; backup codes novos **offline**; remover 2SV estranho
- [ ] Access to your Google Account / Sign in with Google / Linked: Remove access nos desconhecidos
- [ ] Gmail: forwarding, filtros, delegação, IMAP/POP, labels estranhos removidos
- [ ] Play/Pay/Chrome: métodos de pagamento e compras não reconhecidas tratados
- [ ] Security Checkup percorrido

## 3. Contenção GitHub
- [ ] Senha GitHub trocada
- [ ] Sessions (web + Mobile): Revoke o que não for a sessão necessária
- [ ] SSH keys: Delete desconhecidas; regenerar se privada pode ter vazado
- [ ] PAT fine-grained + classic: revogar suspeitos; recriar só o mínimo + expiração
- [ ] OAuth apps / GitHub Apps: Revoke não usados
- [ ] Security log (90 d): revisar eventos do período; anotar
- [ ] E-mails verificados da conta sob seu controle; 2FA/passkey + recovery codes offline

## 4. Android / device (só se perdido, roubado ou sob terceiro — docs oficiais)
**Nota refresh:** `notes/2026-09-20-26-android-find-hub-theft-protection-refresh.md` (Help 6160491 / 3265955 / 15146908)
- [ ] **Primeiro (rápido):** Remote Lock em android.com/lock — número verificado + CAPTCHA (+ security answer se configurada); máx **2/24h**; unlock só local (15146908)
- [ ] Find Hub (app / android.com/find / Guest Mode): locate / Play sound / **Mark as lost** / Factory reset — device online + Find Hub on + visível no Google Play (6160491)
- [ ] Mark as lost Android **17+** 2SV (PIN+biometria) = horizonte; dispositivo Android=15 → Mark as lost clássico
- [ ] Alternativa conta: Sign out remoto em Your devices + senha Google trocada
- [ ] Se UI física: Settings → accounts → Remove account da conta comprometida
- [ ] IMEI: Find Hub → Settings ou About phone (anotar p/ operadora/BO); lock-screen IMEI toggle Android 12+
- [ ] Complementar furto BR: Celular Seguro + BO (§12) — não substitui Find Hub
- [ ] Sem bridge/UI: **não** marcar itens acima como feitos remotamente

## 5. Comunicação / follow-on
- [ ] Contatos avisados se perfil falso / spam no seu nome (CERT.br)
- [ ] Banco/cartão: contestação por canal oficial se cobrança estranha; Registrato se identidade
- [ ] BO se furto de identidade, prejuízo ou extorsão
- [ ] Ignorar phishing de “recuperação” / sites de “seu dado vazou”

## 6. Pós-incidente
- [ ] Re-checar Security Checkup + GitHub security log
- [ ] Password Checkup sem senhas comprometidas/reutilizadas pendentes
- [ ] OAuth/PAT/SSH = inventário mínimo
- [ ] Nota de lições (o que falhou / o que atualizar no playbook)
- [ ] Janela de vigilância: alertas Google/GitHub + extratos Play/Pay

## 7. Recovery lockout Google (quando NÃO entra)
- [ ] Abrir Account recovery oficial (device/browser/local familiares) — support.google.com/accounts/answer/7682439
- [ ] Digitar senha/códigos **somente** em accounts.google.com (nunca e-mail/SMS/ligação / “suporte recovery” de terceiros)
- [ ] Se security hold: anotar horário BRT; checar avisos no recovery phone/email; negar pedido que não foi você; re-tentar em device já signed-in se existir (answer/9412469)
- [ ] Se mudou recovery info recentemente: esperar até ~7 dias e tentar de novo (answer/7682439)
- [ ] Após recuperar: voltar à seção 2 (contenção Google) — devices, senha, recovery, 2SV, OAuth, Gmail

## 8. Contenção WhatsApp (IR)
- [ ] Primary: Linked devices → LOG OUT em todos não reconhecidos (faq.whatsapp.com/378279804439436 + /834124628020911)
- [ ] Confirmar Two-Step Verification ON + e-mail de recuperação do PIN; PIN ≠ código SMS 6 dígitos (faq.whatsapp.com/506595211487528)
- [ ] Nunca compartilhar registration code nem PIN; ignorar msg pedindo reset/compartilhar PIN
- [ ] Se primary comprometido/perdido e controla o número: re-registrar no aparelho confiável (logout automático dos outros) → religar 2-step (pode haver delay)
- [ ] Avisar contatos se spam/perfil falso / “mudei de número” (CERT.br fascículo golpes)

## 9. Contenção VPN (IR) — bridge pode estar desmontada: não marcar sem UI admin
- [ ] Admin Machines → Remove em nodes não reconhecidos / comprometidos (revoga node key na hora)
- [ ] Keys → Revoke auth keys suspeitas; **lembrar:** Revoke ≠ deauth — ainda Remove o node
- [ ] Host legítimo: `vpn up --force-reauth` só com caminho de rede fora do VPN
- [ ] Não afirmar estado do dispositivo Android/bridge sem console ou bridge ativa
- [ ] Machine key não rotaciona (docs); instalação suspeita → Remove + reinstall/reauth em host limpo

## 10. Denúncia / canais BR
**Refresh:** `notes/2026-09-21-02-certbr-notificacoes-ia-security-checkup.md` · notificações **v1.4** (14/11/2025) · PGP 2026 (acesso **2026-09-21**)
- [ ] Incidente técnico BR: e-mail `<redacted-email>` com evidências + data/hora/**timezone**; preferir notificar abuse da rede de origem com CERT.br em **Cc** — **sem formulário** (cert.br/reportar/)
- [ ] Spam em massa: **só** `<redacted-email>` (cert.br/docs/notificacoes/)
- [ ] Phishing em domínio **malicioso**/lookalike: **não** usar contact WHOIS do domínio (fraudador) — abuse AS/IP + Registrar (notificações §3)
- [ ] Domínio/rede `.gov.br` (APF): incluir também CTIR Gov `<redacted-email>`
- [ ] Formato: texto preferencial; Subject claro; sanitizar PII do alvo; logs completos + TZ
- [ ] Canal cifrado opcional: PGP CERT.br **2026** Key ID `0xDA556E88` FP `E5A8 3E5E 7FB2 F448 F72E 4AC7 62BE 60DC DA55 6E88` (cert.br/contato/; chave anual)
- [ ] Crime DH online: SaferNet Denuncie (new.safernet.org.br/denuncie) — escopo limitado (não cobre falsa identidade/difamação)
- [ ] Fraude financeira: canais oficiais do banco (MED/Pix, cartão); Registrato `registrato.bcb.gov.br` para monitorar relacionamentos; reclamação Meu BC se aplicável
- [ ] BO com evidências se prejuízo / identidade / extorsão (fascículo CERT.br Golpes)

## 11. Phishing pós-incidente (follow-on)
- [ ] Ignorar e-mails/SMS “sua conta foi recuperada / clique para secure” — abrir domínio oficial digitado (accounts.google.com / faq.whatsapp.com / admin VPN)
- [ ] Checagem de breach só em haveibeenpwned.com digitado (não clones / não links de e-mail)
- [ ] Recusar push 2SV / aprovações que você não iniciou (CERT.br fascículo)
- [ ] NCSC: não usar links de mensagens; contatos avisados; extratos banco/Play

## 12. Celular Seguro / PIN SIM (furto-roubo BR — 2026-09-20; Furto CERT.br 2026-09-21)

**Notas:** `notes/2026-09-20-14-sms-otp-sim-pin-celular-seguro.md` · **`notes/2026-09-21-15-certbr-furto-de-celular.md`**  
Fontes: celularseguro.mj.gov.br · CERT.br Furto de Celular PDF (nov/2024; acesso **2026-09-21**) · android.com/lock · android.com/find

- [ ] Pré: aparelhos + Contato de Confiança cadastrados no Celular Seguro (gov.br)
- [ ] Furto/roubo: emitir alerta (você ou Contato de Confiança); guardar **protocolo**
- [ ] Escolher Modo Recuperação vs Bloqueio Total (IMEI) — **irreversível** após emitir; entender trade-off localização vs bloqueio
- [ ] Registrar **BO** na Polícia Civil / DF — alerta **não** substitui BO; declarar **IMEI + número de série** (CERT.br Furto)
- [ ] Operadora: desativar chip SIM + bloquear IMEI (CERT.br); atendimento presencial se desbloqueio futuro
- [ ] Bancos/parceiros: bloquear app + cartões do aparelho; seguir procedimentos deles (desbloqueio não é pelo Celular Seguro)
- [ ] Complementar Find Hub / Remote Lock (Android) ou Find My (Apple) — `android.com/lock` / `android.com/find/` / `icloud.com/find/`
- [ ] PIN SIM: se aparelho ainda sob seu controle antes do furto, confirmar PIN ativo + PIN padrão alterado (CERT.br); sem UI não marcar
- [ ] Playbook completo pré+pós: ver **§24**

## 13. Contenção GitHub IR profunda (unauthorized / 2FA lockout — 2026-09-20)

**Nota:** `notes/2026-09-20-17-github-unauthorized-access-2fa-recovery.md`  
Fontes: docs.github.com Preventing unauthorized access · Sessions · Updating credentials · Revoking your credentials · REST `/credentials/revoke` · Recovering 2FA · Account Recovery Policy (acesso **2026-09-20**)

### Com acesso (signed-in)
- [ ] Senha GitHub nova e única (Password and authentication / password_reset)
- [ ] 2FA on + passkey; recovery codes offline (`github-recovery-codes.txt`)
- [ ] Settings → Sessions: Revoke web + Mobile não reconhecidos (Mobile revoke = remove 2FA option)
- [ ] SSH keys + deploy keys: Delete estranhos; regenerar se privada pode ter vazado
- [ ] PAT fine-grained + classic: revogar suspeitos; recriar mínimo + expiração
- [ ] Applications: OAuth + GitHub Apps Revoke; opcional Revoke “GitHub iOS/Android” para force Mobile sign-out
- [ ] Verify **all** emails (atacante pode adicionar e-mail para reset)
- [ ] Security log 90 d: repos públicos/transfers, webhooks, collaborators, commits, `personal_access_token.*` / `oauth_*` / `public_key.*`
- [ ] Conta **restricted** pós-suspeita: hygiene acima + secure e-mail + inbox GitHub; se persistir → Support (doc)

### Token vazado
- [ ] `POST https://api.github.com/credentials/revoke` **sem** Authorization (auth → 403); body `credentials[]` ≤1000; rate 60/h
- [ ] Tipos: `ghp_` / `github_pat_` / `gho_` / `ghu_` / `ghr_` — **não** `ghs_` (short-lived App/Actions)
- [ ] Após revoke: gerar novo → atualizar secrets/automations → confirmar log/UI (não reativa)
- [ ] Push protection / leak: público/gist pode já ter auto-revogado PAT/OAuth/App — ainda assim inventariar stores + Security log (nota `2026-09-26-10-…` / auth §O)
- [ ] Privado PAT: *Report leak* no alerta (preview) após rotacionar se downtime preocupa; Close as Revoked manual

### Bulk Danger zone (Credentials)
- [ ] **Revoke all** SSO = enterprise; **Delete all** keys/tokens = EMU only — conta Free/Pro pessoal: preferir inventário manual (§ acima)
- [ ] Ações bulk irreversíveis — automations quebram

### Lockout 2FA / sem password
- [ ] Recovery code → passkey → security key → (legado SMS fallback) → Begin account or email recovery (device / SSH / PAT; até **3 business days**)
- [ ] password_reset link vale **3 hours**; só primary/backup emails
- [ ] Support **não** restaura 2FA se perdeu credenciais e recovery methods (Account Recovery Policy)
- [ ] Sem recovery = perda permanente; unlink e-mail para nova/outra conta; conteúdo privado locked ≠ recuperável por Support
- [ ] Ignorar “serviços recovery” / social engineering pedindo ID — política explícita

## 14. Contenção Apple Account / iPhone (IR — 2026-09-20)

**Nota:** `notes/2026-09-20-18-apple-account-compromised-adp-recovery.md`  
Fontes: support.apple.com/102560 · 118574 · 102568 · 122621 · 102651 (acesso **2026-09-20**)

- [ ] Sinais: notificação Apple, 2FA não pedido, devices/trusted/purchases estranhos, senha falha, Lost Mode por terceiro
- [ ] Change/reset senha Apple Account; `account.apple.com` corrigir info; **Devices** remove estranhos
- [ ] Controlar e-mail + telefone; operadora: checar SMS forwarding
- [ ] Sem reset: `iforgot.apple.com` account recovery (dias; Support não encurta; outros devices signed-in cancelam wait)
- [ ] Pós: 2FA; Security Keys; passcode + Stolen Device Protection; ≥2 trusted phones/devices
- [ ] Apple **nunca** pede senha/código/passcode nem desligar 2FA/SDP (102568)
- [ ] ADP: trade-off E2E vs recovery; recovery contact/key **antes** de ligar; estado ADP Bruno = NÃO VALIDADO sem UI
- [ ] Furto físico BR: Celular Seguro + BO (§12) **e** Find My se aplicável — não substituem um ao outro
- [ ] Sem UI Apple: **não** marcar itens acima como feitos

## 15. Contenção Google — passkeys / at-risk / recovery residual (2026-09-20)

**Nota:** `notes/2026-09-20-19-google-passkeys-at-risk-recovery.md`  
Fontes: support.google.com/accounts 13548313 · 17137073 · 183723 · 7682439 · 6294825 (acesso **2026-09-20**)

### Com acesso
- [ ] Passkeys and security keys: Remove de device perdido/compartilhado / não reconhecido
- [ ] Your devices: Sign out em sessões/rótulos duvidosos (auto-passkey Android some com Sign out)
- [ ] Recent security activity: at-risk → Remove se não for você; Re-enable só com trusted passkey/key se for você
- [ ] Recovery phone/email: sob seu controle; **não** Google Voice; contacts não reconhecidos → Delete
- [ ] Skip password: decidir consciente (passkey-first vs senha-first) após incidente
- [ ] Hygiene base §2 (senha, 2SV, OAuth, Gmail settings) se hijack

### Sem acesso (lockout)
- [ ] Account recovery oficial (`accounts.google.com` recovery flow) — sem limite de tentativas erradas (doc)
- [ ] Se recovery info mudou recentemente: esperar até **7 d** e tentar de novo
- [ ] **Não** ligar “Google support” / **não** pagar serviço recovery / **não** enviar senha ou códigos
- [ ] Sem UI: não marcar itens como feitos

## 16. Contenção conta gov.br (IR — 2026-09-20)

**Nota:** `notes/2026-09-20-23-cisc-govbr-whatsapp-2fa-ir.md`  
Fontes: MJ Invadiram Gov.br · gov.br Segurança da conta / Ativar 2FA / Recuperar 2FA (acesso **2026-09-20**)

- [ ] BO (presencial ou delegacia virtual) + evidências (prints, data/hora) — MJ passo 1
- [ ] Senha nova no portal oficial de recuperação (**digitado**); “Esqueci minha senha” se bloqueado; suporte gov.br se falhar
- [ ] App gov.br **só** Play Store / App Store — nunca APK de mensagem
- [ ] Subir nível Prata ou Ouro (Ouro: facial; Prata: também via banco — doc oficial de nível)
- [ ] Ativar verificação em duas etapas no app; cadastrar e-mail de recuperação no app
- [ ] Dispositivos autorizados: Excluir todos se houver dúvida; revisar histórico
- [ ] Métodos de acesso/recuperação atualizados (só os seus)
- [ ] Se pagou PIX/boleto do golpe: canal do banco + MED se Pix (checklist phishing); não novo Pix “para corrigir”
- [ ] Código 2FA gov.br pedido por SMS/WhatsApp = golpe (código real só no app)
- [ ] Sem UI: **não** marcar itens como feitos no dispositivo Android

## 17. CERT.br IA / agentes + Security Checkup residual (2026-09-21)

**Nota:** `notes/2026-09-21-02-certbr-notificacoes-ia-security-checkup.md`  
Fontes: cartilha.cert.br Fascículo IA · support.google.com/accounts 12629482 · 46526 (acesso **2026-09-21**)

### Agentes / IA (fascículo CERT.br)
- [ ] Permissão mínima: sem escrita se a tarefa é só leitura; sem senhas/cartão/docs no prompt ou histórico do agente
- [ ] Aprovação humana antes de mutações (apagar e-mail, enviar msg, comprar, delete)
- [ ] Tratar deepfake/áudio/vídeo pedindo dinheiro e comprovante Pix/encomenda gerado por IA como suspeito até canal oficial
- [ ] Resposta de LLM = rascunho: validar fontes; instruir “se não souber, diga que não sabe”

### Security Checkup (Google)
- [ ] Abrir Security Checkup / Recommended actions (perfil → Recommended actions)
- [ ] Triagem por cor: azul=tip · amarelo=importante · vermelho=urgente · shield verde=saudável
- [ ] Recovery phone/email sob controle; passkey; 2SV forte (keys/prompts > SMS); Remove access em apps arriscados
- [ ] Password Checkup + Password Alert (Chrome); remover apps/extensões desnecessárias
- [ ] Sem myaccount UI: **não** marcar itens como feitos

## 18. Pós-golpe CERT.br (trilogia Golpes — 2026-09-21)
**Nota:** `notes/2026-09-21-05-certbr-golpes-trilogia.md` · fascículo Caiu? (mai/2026)

- [ ] Cortar contato: bloquear; sem negociar; sem mais dinheiro/dados
- [ ] Senhas em todas as contas reutilizadas; 2SV; recusar push não iniciado; encerrar sessões
- [ ] Pix: contestar MED no app/canal oficial (quanto antes)
- [ ] Cartão: contestar compras (incl. faturas anteriores); bloquear virtual e/ou físico; desativar compras online no físico
- [ ] Evidências: links, msgs, perfis, telefones, prints, comprovantes, protocolos
- [ ] BO (online se disponível) com evidências
- [ ] Denunciar perfil/msg/anúncio na plataforma; incentivar outras vítimas
- [ ] Avisar contatos se takeover / perfil falso / “mudei de número” / pedido Pix; senha familiar
- [ ] Celular: factory reset se instalou app do golpista; restaurar só de backup confiável (sem bridge: não afirmar)
- [ ] PC: AV completo; remover apps do golpista; reinstalar SO se malware persistir
- [ ] Ajuda: reclamação BC · Procon · advogado se empréstimo/dívida/negativação
- [ ] Monitorar: alertas, extratos, sessões, score, Registrato (`registrato.bcb.gov.br`)


## 19. Vazamento de Dados (terceiro / CERT.br — 2026-09-21)
**Nota:** `notes/2026-09-21-06-…` · `notes/2026-09-21-07-…` (Proteção de Dados / LGPD) · fascículos Vazamento + Proteção (jan/2024, ANPD)

- [ ] **NOVO** Comunicado de vazamento: confirmar só por **canal oficial digitado** (e-mail/SMS com link = possível golpe paralelo)
- [ ] Entender: quais dados, quando, mitigações da empresa; executar mitigações oficiais
- [ ] **NOVO** Senha exposta: trocar em **todos** os serviços onde foi reutilizada; 2SV; auditar logins; recovery se conta tomada
- [ ] Bancos/cartões: informar; revisar extratos; contestar; bloquear/substituir cartões
- [ ] **NOVO** Monitorar: alertas · extratos · [Registrato](https://registrato.bcb.gov.br/) · score · [Cadastro Pré-Pago](https://cadastropre.com.br/) (linha no CPF)
- [ ] Pós-vazamento: alerta a phishing/extorsão/perfil falso; avisar contatos se perfil falso
- [ ] BO se furto de identidade / prejuízo financeiro / extorsão
- [ ] Sem resposta do Controlador (ou Controlador desconhecido): ANPD — **petição de Titular** (exercer direitos) **ou** **denúncia** (infração LGPD quando petição não couber) ([canais titular](https://gov.br/anpd/pt-br/canais_atendimento/cidadao-titular-de-dados/)); ver também nota `2026-09-21-07-…` (Proteção de Dados)
- [ ] **NOVO** Nunca comprar dados vazados; nunca abrir site/arquivo duvidoso que “confirma se vazou”
- [ ] Furto fino (já §12): pin screen (Fixação/Acesso Guiado) em via pública; desabilitar atalhos/leitura na lock screen; limites Pix/TED reduzidos preventivamente

## 20. Takeover / clone de rede social (CERT.br — 2026-09-21)

**Nota:** `notes/2026-09-21-08-certbr-redes-sociais.md` · fascículo Redes Sociais (fev/2023)

- [ ] **NOVO** Trocar senha imediatamente no site/app **oficial** (digitado / loja); ativar ou reforçar 2SV
- [ ] **NOVO** Seguir fluxo oficial de recuperação se sem acesso (e-mail/telefone de recovery sob seu controle)
- [ ] **NOVO** Encerrar sessões / dispositivos ativos; revogar apps de terceiros com acesso
- [ ] **NOVO** Revisar login social: contas que usavam esta rede como IdP — senha/2SV nelas também
- [ ] **NOVO** Denunciar perfil clone na plataforma; bloquear; **avisar contatos** (pedido Pix / “mudei de número” / link)
- [ ] Cruzar §18 (pós-golpe) se houve prejuízo financeiro; §19 se dados vazaram via o takeover
- [ ] Sem UI: **não** marcar itens como feitos


## 21. Perda de 2º fator / alerta de login indevido (CERT.br Autenticação — 2026-09-21)

**Nota:** `notes/2026-09-21-09-certbr-autenticacao.md` · fascículo Autenticação (nov/2022)

- [ ] **NOVO** Alerta de login indevido: acessar conta pela URL **digitada** (nunca link do alerta) → alterar senha → ativar/reforçar 2SV → encerrar sessões
- [ ] **NOVO** Negar push/autorização 2SV que você não iniciou; tratar como tentativa ativa
- [ ] **NOVO** Trusted device perdido/trocado: **excluir** nos serviços onde estava cadastrado
- [ ] **NOVO** Chave física perdida: avisar imediatamente cada serviço onde era usada; registrar nova chave
- [ ] **NOVO** Backup codes perdidos ou suspeitos: **revogar e regenerar**; guardar novo set offline
- [ ] **NOVO** Telefone/e-mail de verificação indisponível: atualizar dados + cadastrar **alternativos** (antes do próximo incidente)
- [ ] Cruzar §2 / §15 (Google) · §13 (GitHub) · §14 (Apple) · §20 (rede social) conforme a conta
- [ ] Sem UI: **não** marcar itens como feitos


## 22. Suspeita de malware / Códigos Maliciosos (CERT.br — 2026-09-21)

**Nota:** `notes/2026-09-21-10-certbr-codigos-maliciosos.md` · fascículo Códigos Maliciosos (jul/2023)  
Cruzar §18 se o vetor foi golpe/app indicado.

- [ ] **NOVO** AV local ou online no device suspeito; anotar sintomas (lentidão, popups, cifragem, spam outbound)
- [ ] **NOVO** Reiniciar — suficiente se malware só em RAM (IoT/roteador citado pelo CERT.br)
- [ ] **NOVO** Se não remove ou sintomas persistem: reinstalar SO **ou** factory reset (soluções mais recomendáveis)
- [ ] **NOVO** Trocar senhas de **todos** os serviços usados a partir do device infectado; 2SV; encerrar sessões
- [ ] Scareware: não instalar o “antivírus” do popup; limpar com AV conhecido
- [ ] Stalkerware: evidência + reset + senhas; considerar ajuda externa se risco pessoal
- [ ] Ransomware: **não** tipar pagamento; backups offline; evidência/BO se prejuízo
- [ ] Roteador/ISP estranho após reboot: ver higiene CERT.br Redes (`2026-09-21-11`) + trocar admin/Wi‑Fi
- [ ] Sem bridge/UI: **não** afirmar infecção no dispositivo Android


## 23. PC/Mac — malware / furto / manutenção (CERT.br Computadores — 2026-09-21)

**Nota:** `notes/2026-09-21-12-certbr-computadores.md` · fascículo Computadores (abril/2024)  
Cruzar §22 (malware geral) · Backup `2026-09-21-14` · Trabalho Remoto `2026-09-21-13`

- [ ] **NOVO** Suspeita no PC: AV nativo/preferido → se persiste: reinstalar SO → trocar senhas em **outro device seguro** (ou só após limpeza)
- [ ] **NOVO** Furto/perda PC: Find My / account.microsoft.com/devices → bloquear/apagar remoto → BO
- [ ] **NOVO** Manutenção: backup antes; SO original; disco antigo apagar ou reter (cifrado = ok deixar); pós: updates/AV/firewall ativos
- [ ] **NOVO** Ransomware: backups **offline desconectados**; não tipar pagamento; cruzar §22
- [ ] Trabalho Remoto (se employer): notificar canais oficiais de suporte/segurança da empresa (`2026-09-21-13`)
- [ ] Sem UI Mac: **não** afirmar infecção/estado FileVault

## 24. Furto de celular — playbook CERT.br (pré + pós — 2026-09-21)

**Nota:** `notes/2026-09-21-15-certbr-furto-de-celular.md` · fascículo Furto de Celular (nov/2024)  
Cruzar §4 (Find Hub) · §12 (Celular Seguro) · `android-higiene.md` (pré)

### Pré (reduzir dano)
- [ ] **NOVO** Lock forte + auto-lock mínimo; lock screen **sem** preview de mensagens nem atalhos de settings
- [ ] **NOVO** App Lock / biometria em bancos, e-mail, notas; ocultar apps sensíveis só se aceitar **sem** notif/ligação
- [ ] **NOVO** Via pública com tela aberta: Fixação de Tela (Android) / Acesso Guiado (iOS)
- [ ] SIM PIN on + PIN padrão da operadora alterado; IMEI offline (Settings / `*#06#` / caixa / NF)
- [ ] Find Hub / Buscar on; Theft Protection (Android) ou Stolen Device Protection (iOS — preferir atraso **sempre**)
- [ ] Celular Seguro + Contato de Confiança; limites Pix/TED reduzidos; códigos 2SV offline; backup
- [ ] Sem fotos de documentos/cartões/senhas desprotegidas; senhas só em gerenciador (não notas/e-mail/fotos)

### Pós (ordem CERT.br)
- [ ] **NOVO** Bancos/fintechs: bloquear app + cartões do aparelho
- [ ] Celular Seguro: emitir alerta (você ou Contato de Confiança) — §12
- [ ] Operadora: desativar SIM + bloquear IMEI
- [ ] **NOVO** BO com IMEI **e** número de série
- [ ] Remoto: `android.com/lock` e/ou Find Hub erase (`android.com/find/`) — iOS `icloud.com/find/`
- [ ] **NOVO** Logout sessões do aparelho; trocar senhas: e-mail · login social · bancos · Google/Apple ID
- [ ] Extratos + contestar fraudes; reclamação BC se necessário
- [ ] **NOVO** Se usou device emprestado na urgência: redefinir senhas nele em device confiável
- [ ] Sem UI: **não** marcar itens como feitos
