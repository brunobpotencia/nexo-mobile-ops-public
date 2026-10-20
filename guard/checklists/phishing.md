# Checklist — phishing e engenharia social

- [ ] Parar se houver pressa, ameaça, segredo, “dinheiro fácil” ou autoridade duvidosa (CERT.br)
- [ ] Link suspeito: **não** abrir; digitar URL oficial ou abrir o **app da loja** no aparelho
- [ ] Gmail: remetente real + hover no link; ⋯ → **Report phishing**; Google nunca pede senha/2SV por e-mail/SMS/ligação
- [ ] Após link pedindo senha Google: **não** digitar; ir a `myaccount.google.com` / `myaccount.google.com/notifications` **digitado**
- [ ] Alerta “Google / banco / gov”: validar em myaccount / app oficial **digitado** — nunca no link da mensagem
- [ ] Passkey Google (`myaccount.google.com/signinoptions/passkeys`): só aparelhos pessoais + screen lock; remover se aparelho perdido
- [ ] Enhanced Safe Browsing **na conta** (Security) + Enhanced no Chrome se aceitar telemetria de segurança
- [ ] Password Alert (Chrome, opcional): avisa senha Google em site não-Google
- [ ] WhatsApp: 2-step verification; bloquear/reportar; nunca código/senha; desconfiar “suporte” por telefone (não há nº público geral Meta/WhatsApp)
- [ ] WhatsApp: revisar links marcados / lookalike (Unicode) antes de abrir
- [ ] Apps sensíveis (banco, gov.br, Meu INSS): só Play Store / App Store; Play Protect ligado; nunca APK de WhatsApp/SMS/“Play” no browser
- [ ] Pix “por engano”: devolver **só** à conta de origem pelo app do banco — não novo Pix para outra chave
- [ ] BC PROTEGE+ (gov.br Prata/Ouro + 2SV): ativar em `bcb.gov.br/meubc`; desativar só na janela de abertura de conta (até 30 dias); ver histórico de consultas; só URL oficial digitada
- [ ] Pós-golpe: cortar contato → senhas → 2SV/passkey → sessões → remover app → scan → contestar Pix/cartão → denunciar; sem ADB/bridge não afirmar infecção no dispositivo Android
- [ ] APP (Advanced Protection): só se risco direcionado + aceitar apps de terceiros limitados; senão passkey+2SV basta
- [ ] WhatsApp Linked devices: revisar e remover o que não for seu (takeover hygiene); só app oficial da loja
- [ ] Golpe “governo” no WhatsApp: órgãos não cobram por chat; sites `.gov.br` digitados (alerta CISC — ver nota 18h)
- [ ] Gmail “This message could be a scam” de contato: não clicar; Report; avisar o amigo fora do e-mail

## SMS / OTP / PIN SIM / Apple / Celular Seguro (2026-09-20)

**Nota:** `notes/2026-09-20-14-sms-otp-sim-pin-celular-seguro.md`  
Fontes: CERT.br Autenticação + Celulares/Furto; Google answer/185839 + 7026266; GitHub Configuring/Changing 2FA; Apple 102568/120569/102560; Celular Seguro MJSP (acesso **2026-09-20**)

- [ ] Nunca enviar código SMS/OTP/2FA a ninguém (CERT.br Autenticação; Google; Apple; GitHub)
- [ ] Google 2SV: preferir passkey → prompts / Authenticator; SMS só último recurso (SMS vulnerável a phone-number / SIM swap — answer/185839)
- [ ] GitHub 2FA: TOTP (+ security key / GitHub Mobile); SMS **não** como primário — interceptável e sem resistência a phishing (docs Configuring/Changing 2FA)
- [ ] PIN do chip SIM ativo + PIN padrão da operadora alterado (CERT.br Celulares / Furto) — UI local; sem bridge não afirmar
- [ ] Apple: SMS/ligação “suporte” → desligar; nunca senha/código/Allow/desligar 2FA ou Stolen Device Protection; reportar SMS a `<redacted-email>` (102568 / 120569)
- [ ] Apple Account: checar se controla e-mail e número (SMS forwarding indevido) se suspeita (102560); trusted phone extra se iPhone único (122621)
- [ ] Celular Seguro (`celularseguro.mj.gov.br` / gov.br): cadastrar aparelhos + Contato de Confiança **antes** do incidente
- [ ] Furto/roubo: alerta Celular Seguro (protocolo) **e** BO — alerta não substitui BO; escolha Recuperação vs Bloqueio Total IMEI é irreversível após emitir
- [ ] **NOVO** Pré-furto (CERT.br Furto `2026-09-21-15`): limites Pix/TED baixos; senhas só em gerenciador (não notas/fotos); pós = IR §24

## Apple Account (IR / phishing — 2026-09-20)

**Nota:** `notes/2026-09-20-18-apple-account-compromised-adp-recovery.md` · Apple 102568 / 102560

- [ ] Apple **nunca** pede senha, passcode, código 2FA, nem desligar 2FA / Stolen Device Protection
- [ ] Código 2FA não pedido → possível tentativa; não digitar em site/ligação
- [ ] <redacted-email> para SMS/e-mail falso (também nota SMS 14)


## Pix MED / Recuperação de Valores (refresh 2026-09-20)

**Notas:** `2026-09-18-18-phishing-whatsapp-passkeys-med.md` · Guia BCB MED v4.3 (fetch 2026-09-20; v4.4 citada com vigências futuras 01/09 e 26/10/2026 — operacional consumidor ainda ancorado em 4.3)  
Fonte: [Guia_MED.pdf](https://www.bcb.gov.br/content/estabilidadefinanceira/pix/Guia_MED.pdf)

- [ ] Golpe/fraude Pix: contestar **no app** (autoatendimento no ambiente Pix) ou canal do banco — **já**; PSP deve abrir Recuperação de Valores sem exigir BO para iniciar
- [ ] Prazo: transação raiz ≤ **80 dias**; contestação de **devolução** ≤ **30 dias**
- [ ] Tipos típicos (DICT): scam / account_takeover / fraudulent_access / coercion — incluir se o usuário autorizou sob golpe
- [ ] Fora do MED: desacordo comercial; terceiro de boa-fé; Pix errado “por engano” (só devolução à **origem** no app — nunca novo Pix)
- [ ] MED ≠ chargeback de cartão; devolução depende de saldo no recebedor + confirmação de fraude pelos PSPs
- [ ] Se banco falhar: reclamar no RDR do BC (Manual Resolução de Disputas) — URL digitada

## CISC / gov.br WhatsApp + 2FA operacional (refresh 2026-09-20)

**Nota:** `notes/2026-09-20-23-cisc-govbr-whatsapp-2fa-ir.md`  
Fontes: CISC alerta WhatsApp governo (13/02/2026, mod. 08/04/2026) · CTIR Rec. 01/2025 · gov.br Segurança da conta / Ativar 2FA / Recuperar 2FA e-mail · MJ Invadiram Gov.br (acesso **2026-09-20**)

- [ ] Órgão **nunca** cobra / oferece benefício / ameaça bloqueio de CPF via WhatsApp (CISC)
- [ ] Dados pessoais reais na mensagem (nome/CPF/endereço/familiares) **não** provam legitimidade
- [ ] Pretextos típicos: Dívida Ativa, CPF/Receita, Correios — urgência + link + boleto/PIX = golpe
- [ ] Só confiar em domínio **`.gov.br` digitado** (`gov.br`, `regularize.pgfn.gov.br`, `e-cac.receita.fazenda.gov.br`) — não clicar link de chat
- [ ] Não pagar boleto/PIX recebido por mensagem “do governo”
- [ ] Bloquear + reportar spam no WhatsApp; compartilhar alerta CISC com família se útil
- [ ] gov.br 2FA: só app oficial (Play/App Store); código **só** no app — **não** SMS; Authy/Google Authenticator **não** geram
- [ ] 2FA exige conta **Prata ou Ouro**; ativar no app; data/hora automática; 1 device vinculado
- [ ] Cadastrar **e-mail de recuperação no app** (≠ e-mail da conta) **antes** de trocar/perder celular
- [ ] Dispositivos autorizados: revisar; na dúvida **Excluir todos**; desativar 2FA limpa a lista
- [ ] Não remover app / trocar celular com 2FA on sem plano de recuperação (e-mail+facial ou formulário)
- [ ] CTIR sinais: urgência, clone de site, PIX por serviço gratuito do governo, tema IR/Receita/Correios/Serasa

## NOVOS (CERT.br IA / deepfake — 2026-09-21)

**Nota:** `notes/2026-09-21-02-certbr-notificacoes-ia-security-checkup.md` · [Fascículo IA](https://cartilha.cert.br/fasciculos/ia/fasciculo-ia.pdf) (acesso **2026-09-21**)

- [ ] **NOVO** Deepfake áudio/vídeo pedindo dinheiro / urgência = suspeito até confirmar por canal oficial separado
- [ ] **NOVO** Comprovante Pix / encomenda “gerado” = pode ser imagem IA; validar no app do banco / rastreio oficial digitado
- [ ] **NOVO** Não colar senhas/códigos/PAT em prompts de IA ou agentes (assumir público)

## CERT.br Banco + Comércio via Internet (2026-09-21)

**Nota:** `notes/2026-09-21-04-certbr-banco-comercio-internet.md`  
Fontes: [Fascículo Banco](https://cartilha.cert.br/fasciculos/banco-via-internet/fasciculo-banco-via-internet.pdf) (abr/2023) · [Fascículo Comércio](https://cartilha.cert.br/fasciculos/comercio-via-internet/fasciculo-comercio-via-internet.pdf) (nov/2023, IDV) · [índice](https://cartilha.cert.br/fasciculos/) (acesso **2026-09-21**)

- [ ] **NOVO** Banco/instituição **não** pede senha, código, token, QR ou dados de cartão por ligação/WhatsApp/e-mail outbound — encerrar e usar canal oficial digitado
- [ ] **NOVO** Limites PIX/TED/DOC/transferência reduzidos; rever crédito pré-aprovado
- [ ] **NOVO** Compras não presenciais: cartão **virtual** (+ limite baixo); wallet com autenticação obrigatória
- [ ] **NOVO** E-mail dedicado só para bancos; **não** deixar logado no celular
- [ ] **NOVO** Boletos: preferir **DDA** no app; se PDF/mensagem — conferir beneficiário/CNPJ, banco emissor (prefixo) e valor (sufixo)
- [ ] **NOVO** Open Finance só participantes oficiais (`openfinancebrasil.org.br`)
- [ ] **NOVO** Marketplace: reputação do **vendedor**; pagamento **dentro** da plataforma; fora = golpe
- [ ] **NOVO** Vender com Pix: só entregar após crédito na conta; comprar: conferir destinatário antes de confirmar
- [ ] **NOVO** Disputa comércio: plataforma → Procon → BO (fascículo); fraude Pix → também MED (`§` Pix acima)

## CERT.br trilogia Golpes (2026-09-21)

**Nota:** `notes/2026-09-21-05-certbr-golpes-trilogia.md`  
Fontes: [Não se Deixe Enganar](https://cartilha.cert.br/fasciculos/golpes/fasciculo-golpes.pdf) (mar/2026) · [Evite Fraudes](https://cartilha.cert.br/fasciculos/golpes-evite-fraudes/fasciculo-golpes-evite-fraudes.pdf) (mar/2026) · [Caiu?](https://cartilha.cert.br/fasciculos/golpes-o-que-fazer/fasciculo-golpes-o-que-fazer.pdf) (mai/2026) · [índice](https://cartilha.cert.br/fasciculos/) (acesso **2026-09-21**)

### Identificar (Não se Deixe Enganar)
- [ ] **NOVO** Triagem: conhecido/org? dinheiro/vantagem/dados? urgência sem pensar? → alerta
- [ ] **NOVO** Default: se envolve dinheiro/dados/vantagem, assumir golpe até prova contrária
- [ ] **NOVO** Buscar ≥2 fontes oficiais + relatos (ex. scam.org); não agir só com a mensagem
- [ ] **NOVO** Temas cotidianos suspeitos: CPF cancelado, encomenda, emprego, pagamento, token, pontos, “atualize o app”
- [ ] **NOVO** Temas em destaque (eleições, Black Friday, tragédias, eventos, impostos): só canais oficiais digitados
- [ ] Deepfake áudio/vídeo pedindo dinheiro: confirmar por contato já conhecido + “senha” familiar (também § IA)

### Prevenir (Evite Fraudes)
- [ ] **NOVO** QR em local público: checar adesivo/substituição (mesa, parquímetro, ATM, transporte); na dúvida não ler
- [ ] **NOVO** Antes de pagar QR/Pix/boleto: valor + nome/CNPJ do recebedor; preferir app/site oficial; ignorar QR de mensagem
- [ ] **NOVO** “Mudei de número” + foto conhecida: confirmar pelo número antigo antes de salvar/transferir
- [ ] Pix “por engano”: só devolução no app à **conta de origem** — nunca novo Pix (risco MED + perda dupla)
- [ ] **NOVO** Ativar Proteção do CPF no [Redesim](https://www.gov.br/empresas-e-negocios/pt-br/redesim/) (bloqueia abertura de empresas com seu CPF)
- [ ] BC PROTEGE+ já em § Pix/Banco acima — manter ativo; desativar só com reagendamento

### Pós-golpe (Caiu?) — ver também `resposta-incidente.md` §18
- [ ] **NOVO** Cortar contato imediatamente (sem negociar / sem mais dinheiro)
- [ ] Contestar Pix (MED) e compras no cartão pelos canais oficiais; bloquear cartão virtual/físico
- [ ] Guardar evidências + BO + denunciar na plataforma + avisar contatos
- [ ] **NOVO** Se instalou app indicado pelo golpista: factory reset celular + backup confiável; PC: AV + remover + reinstalar SO se precisar
- [ ] Monitorar Registrato + score + sessões após o incidente


## CERT.br Boatos + golpes via desinformação (2026-09-21)

**Nota:** `notes/2026-09-21-06-certbr-boatos-vazamento-privacidade.md`  
Fontes: [Boatos](https://cartilha.cert.br/fasciculos/boatos/fasciculo-boatos.pdf) (jul/2024) · [índice](https://cartilha.cert.br/fasciculos/) (acesso **2026-09-21**)

- [ ] **NOVO** Antes de crer/repassar: título alarmista + “compartilhe” + fonte omitida/desconhecida + data ausente/antiga = cara de boato
- [ ] **NOVO** Ir à fonte original (site/perfil oficial digitado); ler na origem; procurar desmentido/comunicado
- [ ] **NOVO** Checar fato em ≥2 fontes conhecidas; usar agências de checagem quando disponíveis; na dúvida **não** compartilhar
- [ ] **NOVO** Clickbait: buscar palavras do título antes de clicar — link pode ser phishing
- [ ] Deepfake imagem/vídeo/áudio em viral: sinais de edição; confirmar por canal já conhecido (cruzar § IA / Golpes)
- [ ] **NOVO** Pix/doação motivada por boato/viral: só dados oficiais da campanha — nunca chave/número da mensagem
- [ ] Denunciar contas falsas/bots; não aceitar amizade/seguir perfil duvidoso (ajuda a legitimá-lo)
- [ ] Contas usadas para repasse (e-mail/redes): 2SV + alertas de login; senhas não reutilizadas

## CERT.br Redes Sociais (2026-09-21)

**Nota:** `notes/2026-09-21-08-certbr-redes-sociais.md`  
Fonte: [Redes Sociais](https://cartilha.cert.br/fasciculos/redes-sociais/fasciculo-redes-sociais.pdf) (fev/2023) · [índice](https://cartilha.cert.br/fasciculos/) (acesso **2026-09-21**)

- [ ] **NOVO** Conta privada quando a plataforma permitir; verificar identidade antes de aceitar seguidor/amigo; bloquear falsos
- [ ] **NOVO** Perfil: não publicar telefone/PII; ajustar público-alvo das infos do perfil
- [ ] **NOVO** Posts: listas personalizadas / público por post quando existir
- [ ] **NOVO** 2SV + alertas de tentativa de login; atenção extra a **login social** (abre outras contas)
- [ ] **NOVO** Apps de terceiros (jogos/testes/editores): ler termos; inventário periódico; **revogar** acessos órfãos/suspeitos
- [ ] **NOVO** Links mesmo de conhecidos + anúncios patrocinados + chats = canais de golpe — buscar outras fontes (cruzar § Boatos / Golpes)
- [ ] **NOVO** Denunciar + bloquear conteúdo/perfil malicioso; avisar contatos se clone se passando por eles
- [ ] Takeover: ver `resposta-incidente.md` §20


## CERT.br Códigos Maliciosos (2026-09-21)

**Nota:** `notes/2026-09-21-10-certbr-codigos-maliciosos.md`  
Fonte: [Códigos Maliciosos](https://cartilha.cert.br/fasciculos/codigos-maliciosos/fasciculo-codigos-maliciosos.pdf) (jul/2023) · [índice](https://cartilha.cert.br/fasciculos/) (acesso **2026-09-21**)

- [ ] **NOVO** Links: contexto + detalhes; dúvida = não clicar; “conhecido” → confirmar por outro canal
- [ ] **NOVO** Anexos: scan AV antes; dúvida = não abrir
- [ ] Apps: só loja oficial; nunca APK de msg/link; confirmar nome + desenvolvedor (cruzar Play Protect)
- [ ] **NOVO** Scareware (popup “infectado — instale este AV”): fechar; **não** instalar o oferecido; verificar com AV conhecido da loja
- [ ] Stalkerware / spyware íntimo: tratar como IR (reset + senhas + evidência) — ver `resposta-incidente.md` §22
- [ ] Pós-golpe com app do golpista: já em § Golpes / IR §18 (factory reset)


## CERT.br Trabalho Remoto — e-mail / canais (2026-09-21)

**Nota:** `notes/2026-09-21-13-certbr-trabalho-remoto.md`

- [ ] **NOVO** Links/anexos: ignorar se fora do trabalho / ameaça / oferta / fora do procedimento usual
- [ ] **NOVO** Na dúvida: confirmar autor por **outro canal**; pedir ajuda ao security da org (se houver)
- [ ] **NOVO** Assuntos de trabalho só em apps/contas corporativas autorizadas (não e-mail/msg pessoal)
- [ ] Cruzar trilogia Golpes / Códigos Maliciosos se o vetor for scareware/anexo

