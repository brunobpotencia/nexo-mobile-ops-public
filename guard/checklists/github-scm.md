# Checklist — GitHub / SCM (`brunobpotencia`)

**Atualizado:** 2026-09-27 ~17:39 BRT (CS alert triage + Autofix)

**Estado verificado da conta (2026-10-05 ~11:40 BRT, UI GitHub, fonte Nexo):** `/home/box/agent-data/nexo-guard/baseline/github-baseline-20261005.md` — 2FA ON (authenticator app; passkey/security key de backup ainda **não**); login via Google, sem senha GitHub; PATs 0; OAuth Apps 0; SSH/GPG 0; vigilant mode off; Authorized Apps Copilot Chat/Cursor/Grok by xAI/Vercel; Installed Cursor/Vercel; `nexo-mobile-ops`: dependency graph + Dependabot alerts + security updates ON, ruleset `protect-main` **não** enforced (private free), secret scanning/push protection indisponíveis. Os checkboxes abaixo são checklist genérico (não marcados por estado).

## Conta e autenticação
- [ ] 2FA ligado; preferir TOTP (não SMS) + passkey; security key / GitHub Mobile como backup
- [ ] SMS 2FA só se TOTP impossível: docs WARNING — interceptável, sem resistência a phishing, deliverability ruim (Configuring/Changing 2FA; nota `2026-09-20-14-…`)
- [ ] Recovery codes baixados e guardados **offline** (não só no mesmo telefone)
- [ ] Passkey registrada (Settings → Password and authentication → Passkeys)
- [ ] Senha forte e única no gerenciador; sem reuso

## PAT e MCP (higiene de escopo)
- [ ] Inventário: Settings → Developer settings → Fine-grained **e** Tokens (classic)
- [ ] Apagar PAT classic com `repo` amplo / sem expiração / órfãos
- [ ] Token do GitHub MCP = fine-grained; resource owner `brunobpotencia`; repos mínimos; permissões só do fluxo
- [ ] MCP **sem** `administration` / `secrets` / `workflows` / `dependabot_secrets` sem necessidade
- [ ] Expiração 30–90 dias; calendário mental de rotação
- [ ] Token só no secret store do Cursor/MCP — **nunca** em repo, `.env` versionado, gist ou chat
- [ ] Preferir SSH ou Git Credential Manager / `gh` para Git no dia a dia (não colar PAT no terminal)

## SSH
- [ ] Chave Ed25519 com passphrase; pública em Settings → SSH and GPG keys; rótulo por máquina (ex. Nexo Linux)
- [ ] Remover chaves de devices perdidos/antigos
- [ ] Chave privada **nunca** no git / cloud / chat
- [ ] Sem bridge dispositivo Android: **não** afirmar chaves no aparelho
- [ ] Audit periódico: Settings → SSH and GPG keys ↔ `ssh-add -l -E sha256`; desconhecida → **Delete** + Support (WARNING oficial)
- [ ] Erro “We're doing an SSH key audit” / lack of use → Approve ou Delete em `github.com/settings/ssh` (não ignorar)
- [ ] Saber: chave SSH **sem uso 1 ano** é apagada automaticamente (Deleted or missing SSH keys)
- [ ] `~/.ssh/config`: **nunca** `ForwardAgent yes` sob `Host *`; só Host nomeado confiável (Using SSH agent forwarding)
- [ ] Preferir deploy key RO / GitHub App no servidor a forward da chave de conta
- [ ] Hardware opcional: `ssh-keygen -t ed25519-sk` (FIDO; OpenSSH ≥8.2); DSA não suportado
- [ ] Nota residual `2026-09-20-27-github-ssh-agent-forwarding-persistent-signing.md`

## Security log e apps
- [ ] Security log (90 d) revisado com filtros de credencial: `personal_access_token.*`, `oauth_authorization.*` / `oauth_access.*`, `public_key.*`, `user.failed_login` / unrecognized device (nota `2026-09-20-03-…`)
- [ ] Security log (90 d) revisado: login estranho, PAT/SSH novos, 2FA/passkey alterados
- [ ] OAuth apps / GitHub Apps: Settings → Applications — revogar o que não usa
- [ ] Após suspeita: revogar credenciais + trocar senha + recriar PAT/SSH necessários

## Supply chain e segredos
- [ ] Dependabot alerts ligados nos repos que importam; alertas abertos triados
- [ ] Em PRs que mexem em lockfile/manifest: olhar dependency review antes de merge
- [ ] `.env`, `*.pem`, `id_*` (privadas), tokens no `.gitignore`
- [ ] Push protection de usuário (público) ativo por padrão — não bypassar “I'll fix it later” sem rotacionar
- [ ] Se token vazar: (1) gerar novo, (2) substituir usos, (3) revogar antigo — **nessa ordem de urgência** (revogar já)

## Anti-phishing
- [ ] Nunca enviar código 2FA, recovery code ou PAT a quem pedir (e-mail/SMS/site clone)
- [ ] Conferir domínio `github.com` (HTTPS) antes de digitar credencial / passkey

## Sessões browser e sudo mode (2026-09-18)
- [ ] Settings → Access → Sessions: revisar Web sessions + GitHub Mobile; revogar desconhecidas (Revoke session / Revoke)
- [ ] Saber que revogar Mobile faz logout do app e remove o device como 2FA
- [ ] Sudo mode: TOTP ou passkey prontos (SMS não autentica sudo; se só SMS → pede senha)


## Passkeys / 2FA checkup / recovery (2026-09-26)

**Nota:** `notes/2026-09-26-07-github-passkeys-2fa-checkup-sudo-recovery.md` · extract `github-credenciais-higiene.md` §5c · `github-auth-errors.md` §M

- [ ] Passkey registrada (Synced preferível); device-bound → ≥2 devices
- [ ] Não confundir security key (2º fator) com passkey (passwordless)
- [ ] Checkup 28 d pós-enable: realizar 2FA; atalho de reconfig no dia 28 se falhar
- [ ] Mudar TOTP/SMS **sem** Disable; Save no GitHub antes de apagar app antiga
- [ ] Recovery codes offline; Generate new invalida anteriores
- [ ] Recovery SSH = tipo authentication; recovery PAT classic = scope `repo` (DOC) — inventariar blast radius
- [ ] Sudo: SMS não autentica; passkey/TOTP prontos; timeout 2 h
- [ ] Login passkey: `https://github.com/login?passkey=true`

## OAuth Apps e GitHub Apps (2026-09-18)
- [ ] Authorized OAuth Apps: Settings → Applications — Revoke apps órfãos / permissões largas (além do item genérico já listado)
- [ ] Authorized GitHub Apps: mesma página — Revoke / Revoke all o que não usa
- [ ] Installed GitHub Apps → Configure: repos mínimos; Suspend ou Uninstall + **também** de-autorizar se quiser matar user-to-server
- [ ] Distinguir instalação (repos/perms) vs autorização (agir em nome do user); prefixos `gho_` / `ghu_` = segredo

## Push protection / secret scanning usuário (2026-09-18 + residual 2026-09-26)
Nota: `notes/2026-09-26-10-github-push-protection-users-mcp-remediation.md` · auth §O · higiene §8

- [ ] Settings → Code security → “Push protection for yourself” **ligado** (default on; não desligar sem motivo)
- [ ] Se push bloqueado: remover segredo do branch (amend/rebase); URL bypass = **mesmo user**; re-push ≤3 h
- [ ] Bypass “fix later” / leak real → **revogar/rotacionar já** (público/gist: auto-revoke possível)
- [ ] REST contents/blob **409** e ações **MCP** em público também cobertos — não embutir PAT no payload
- [ ] Vazamento: revogar no provider **antes** de reescrever histórico (git-filter-repo só se ainda necessário); alerta não fecha sozinho

## Assinatura de commits (2026-09-18 + residual 2026-09-20)
- [ ] Git ≥ 2.34 se for assinar com SSH; `gpg.format ssh` + `user.signingkey` apontando ao `.pub`
- [ ] Settings → SSH and GPG keys: chave tipo **Signing** (mesmo material de auth exige **segundo** upload)
- [ ] Vigilant mode só se todos os commits locais forem assinados + e-mail committer verificado
- [ ] Persistent verification: após Verified no push, badge **permanece** mesmo se chave for revogada/expirada depois (`verified_at`) — revogar ≠ “unverify” histórico
- [ ] Evitar **Rebase and Merge** na UI PR se política exige assinatura (commits reescritos sem chave); preferir merge/rebase local assinado
- [ ] Commits na web UI já vêm GPG-signed por GitHub (`web-flow.gpg`) — Verified
- [ ] Nota `2026-09-20-27-…` (persistent signing + agent forwarding)

## Deploy keys vs conta (2026-09-18)
- [ ] Inventariar Deploy Keys nos repos sensíveis; preferir read-only; write = privilégio alto
- [ ] Não usar SSH de conta pessoal em CI/server compartilhado; multi-repo → GitHub App / installation token

## GITHUB_TOKEN / Actions (2026-09-18 + residual 2026-09-26)

**Nota:** `notes/2026-09-26-11-github-actions-github-token-permissions-forks.md` · auth §P · higiene §9

- [ ] Repo → Settings → Actions → General → Workflow permissions: default **restricted** (contents+packages read)
- [ ] Desmarcar “Allow GitHub Actions to create and approve pull requests” se não precisar (default off em conta pessoal)
- [ ] Workflows: `permissions:` explícito mínimo (escopos não listados → `none`); actions leem `github.token` mesmo sem pass
- [ ] Preferir `GITHUB_TOKEN` a PAT no CI do mesmo repo; cross-repo → App installation token (Managing PATs)
- [ ] Expire: fim do job; hosted ≤6 h; self-hosted refresh ≤24 h
- [ ] Fork PR: writes→read salvo *Send write tokens*; *Send secrets* em privado = alto risco
- [ ] Evitar `pull_request_target` + checkout do head do PR com token privilegiado (DOC: write mesmo de fork público) — detalhe pwn request / checkout v7: nota `2026-09-27-03-…` · §T
- [ ] Dependabot PR = read-only + sem secrets Actions (store Dependabot)
- [ ] Eventos do token não re-disparam workflows (exceto dispatch; PR open/sync/reopen → approval-required)

## GitHub App vs PAT (2026-09-20)
Nota: `notes/2026-09-20-11-github-app-vs-pat-automation.md` — [Deciding when to build a GitHub App](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/deciding-when-to-build-a-github-app)

- [ ] Long-lived / org / multi-repo → App; PAT = teste/scripts curtos
- [ ] Preferir App a OAuth app (perms finas, repos selecionáveis, tokens curtos)
- [ ] Actions: `GITHUB_TOKEN` primeiro; cross-repo → installation token da App
- [ ] Cap 50 FG → App; não classic `repo` como atalho permanente

## Fine-grained PAT / classic PAT / higiene de tokens (2026-09-19)
Fonte: notes `2026-09-19-01-github-fine-grained-pat-higiene.md` (docs.github.com Managing PATs, Token expiration, Permissions FG, SSO, Org policy, Rate limits — acesso 2026-09-18/19)

- [ ] Preferir **fine-grained** (`github_pat_`) a classic (`ghp_`); classic só se gap oficial (Packages, multi-org, outside collaborator, write em público alheio, user Projects); **Checks write = App** (não classic) — nota `2026-09-26-09-…` / auth §N
- [ ] Inventário: Developer settings → **Fine-grained tokens** e **Tokens (classic)** — apagar órfãos / classic com `repo` / sem expiração
- [ ] Fine-grained: resource owner **único**; Repository access = **Only select repositories** (mínimo); permissions mínimas
- [ ] Não conceder sem necessidade: Administration, Secrets (Actions/Dependabot/…), Workflows write, Contents write em All repositories
- [ ] Expiração **30–90 dias** (ou ≤ política org; default política org FG = 366 d max); evitar No expiration
- [ ] Cap **50** fine-grained — acima disso planejar GitHub App (não acumular tokens mortos)
- [ ] Classic: se inevitável, scopes mínimos; lembrar que `repo` = blast radius em **todos** os repos acessíveis
- [ ] Org SAML: classic → **Configure SSO → Authorize**; fine-grained autoriza na criação; re-autorizar se editar scopes/regenerar classic
- [ ] Se owner de org: revisar Restrict PAT / max lifetime / Require approval (FG); classic **não** passa por approval FG
- [ ] Token expirado/revogado/deletado **não restaura** — criar novo; se PAT deletado criou deploy key, deploy key também some
- [ ] Vazamento: revogar na UI (e/ou credential revocation API para `ghp_`/`github_pat_`); confirmar no Security log (`personal_access_token` / `oauth_authorization.destroy`)
- [ ] Prefixos `github_pat_` / `ghp_` / `gho_` / `ghu_` / `ghr_` = segredo — nunca no git/gist/chat (cruzamento push protection)
- [ ] CLI diária: SSH ou `gh` / Git Credential Manager — não colar PAT no terminal
- [ ] Rate limit: orçamento REST **5 000/h** compartilhado (PAT + OAuth + user-to-server); preferir webhooks / conditional requests a polling
- [ ] MCP GitHub: fine-grained dedicado, repos/perms mínimos, só secret store Cursor — **não** classic com `repo`

## OIDC / `id-token` cloud (2026-09-26)

**Nota:** `notes/2026-09-26-12-github-actions-oidc-id-token-cloud-anti-pat.md` · `github-auth-errors.md` §Q

- [ ] Cloud deploy: OIDC short-lived **antes** de AWS/GCP/Azure key em Actions secrets
- [ ] `permissions: id-token: write` (só JWT); issuer `token.actions.githubusercontent.com`
- [ ] Trust cloud: pin `sub` (environment/branch/tag); ≥1 condição; pós-2026-07-15 checar formato imutável `@ID`
- [ ] Environment + protection rules em deploy sensível (Free pessoal: só repo público)
- [ ] Dependabot OIDC: `event_name=dynamic`; pin trust se filtrar event_name
- [ ] Reusable: `job_workflow_ref` no cloud; caller externo com `id-token: write`

## Auth errors / secret injection (2026-09-20)

Diagnóstico **401 vs 403 vs 404 vs 429**, classic `ghp_` vs fine-grained `github_pat_`, e higiene de Bot secret-request: ver checklist dedicado [`github-auth-errors.md`](github-auth-errors.md) + nota `notes/2026-09-20-01-github-pat-oauth-secret-injection.md`. Não duplicar aqui.

## IR / 2FA lockout (2026-09-20)

**Nota:** `notes/2026-09-20-17-github-unauthorized-access-2fa-recovery.md` · checklist `resposta-incidente.md` §13

- [ ] Recovery codes offline + passkey (Support **não** restaura 2FA sem recovery methods)
- [ ] Sessions web+Mobile revogáveis; Mobile revoke remove 2FA option
- [ ] Token vazado → `POST /credentials/revoke` sem auth (`ghp_`/`github_pat_`/`gho_`/`ghu_`/`ghr_`; não `ghs_`)
- [ ] Conta restricted: senha + hygiene + e-mail GitHub; Support se persistir
- [ ] Verify all emails (prevenir reset por e-mail do atacante)


## Secrets encrypted: Actions × Codespaces × Dependabot (2026-09-20)

**Nota:** `notes/2026-09-20-29-github-actions-codespaces-dependabot-secrets.md`  
Fontes: [Secret types](https://docs.github.com/en/code-security/reference/secret-security/secret-types) · [Codespaces account secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces) · [Using secrets in Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions) · [Dependabot private registries](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/configuring-access-to-private-registries-for-dependabot) (acesso **2026-09-20**)

- [ ] Tratar **três stores** separados: Actions · Codespaces · Dependabot — **não** se enxergam entre si
- [ ] Inventário: Settings → Codespaces (user) **e** em cada repo Secrets and variables → Actions / Codespaces / Dependabot — apagar órfãos
- [ ] Workflow disparado por Dependabot: secrets necessários no store **Dependabot** (Actions secrets **não** disponíveis)
- [ ] Codespaces: secret novo exige **stop/restart**; não disponível em Dockerfile/build nem em **features**
- [ ] Nomes: `[A-Za-z0-9_]`; sem prefixo `GITHUB_`; sem começar com dígito; case-insensitive
- [ ] Limites: Codespaces/repo/env ~**100** × **48 KB**; Actions org até **1000**; user Codespaces **100**
- [ ] Precedência mesmo nome: nível **mais baixo** ganha (environment > repo > org)
- [ ] Secrets **não** passam a forks; Actions: não auto para reusable workflows
- [ ] PAT de script: Codespaces secret (dev) **ou** Actions secret (CI) — Managing PATs; FG **sem** `secrets` / `codespaces_secrets` / `dependabot_secrets` write sem necessidade
- [ ] GitHub Packages p/ Dependabot: preferir “Manage Actions access” + `GITHUB_TOKEN` a PAT em `dependabot.yml`
- [ ] Preferir OIDC (Actions/Dependabot) a credencial cloud long-lived quando o provider couber
- [ ] Org Free: org-level Actions secrets **não** em private repos Free (doc Using secrets)

## Environment secrets / protection rules (2026-09-27)

**Nota:** `notes/2026-09-27-01-github-environment-secrets-protection-rules.md` · extract `github-credenciais-higiene.md` §11 · `github-auth-errors.md` §R  
Fontes: [Managing environments](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment) · [Deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments) · [Secrets reference](https://docs.github.com/en/actions/reference/security/secrets) · [Control deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments) (acesso **2026-09-27** ~00:39)

- [ ] Prod / deploy secrets → **environment** + protection; repo secret = blast radius a quem tem write
- [ ] Precedência: environment > repository > organization; org/repo no queue, env no start do job
- [ ] Reviewers ≤6 (1 basta; Prevent self-review) · wait ≤30 d · Selected branches/tags · deny admin bypass
- [ ] Free: environments efetivos só em **público**; privado Free ignora rules/secrets
- [ ] Env criado por YAML sem Pages → **sem** rules; só admin configura
- [ ] `deployment: false` = secrets gated sem history; incompatível com custom App protection
- [ ] Self-hosted: tratar env secrets como repo/org (sem isolamento)
- [ ] Cruzar com OIDC (`2026-09-26-12`) e stores (`2026-09-20-29`)

## Actions variables vs secrets + reusable inherit (2026-09-27)

**Nota:** `notes/2026-09-27-02-github-actions-variables-vs-secrets-inherit.md` · extract `github-credenciais-higiene.md` §12 · `github-auth-errors.md` §S  
Fontes: [Variables](https://docs.github.com/en/actions/concepts/workflows-and-actions/variables) · [Variables reference](https://docs.github.com/en/actions/reference/variables-reference) · [Reuse workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows) · [Secrets](https://docs.github.com/en/actions/concepts/security/secrets) (acesso **2026-09-27** ~01:37)

- [ ] Variables = config não sensível (unmasked); Secrets = tokens/keys (redacted)
- [ ] Precedência vars: env > repo > org; limites repo 500 / org 1000 / env 100 · 256 KB org+repo
- [ ] Reusable: secrets nomeados > `inherit`; env secrets no job called com `environment:`
- [ ] Nested A→B→C: secrets só hop direto; pin SHA em reusable externo
- [ ] Cruzar com environment secrets (`2026-09-27-01`) e stores (`2026-09-20-29`)

## Script injection / pwn request / checkout (2026-09-27)

**Nota:** `notes/2026-09-27-03-github-actions-script-injection-pwn-request-checkout.md` · extract `github-credenciais-higiene.md` §13 · `github-auth-errors.md` §T  
Fontes: [Script injections](https://docs.github.com/en/actions/concepts/security/script-injections) · [Secure use](https://docs.github.com/en/actions/reference/security/secure-use) · [Securely using pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target) · [actions/checkout](https://github.com/actions/checkout/blob/main/README.md) (acesso **2026-09-27** ~02:46)

- [ ] Nunca `${{ github.event.*.title|body|… }}` / branch / email direto em `run:` — action `with:` ou `env:` + `"$VAR"`
- [ ] Preferir `pull_request` a `pull_request_target` quando não precisa secrets em fork
- [ ] Proibido pwn request: PRT + checkout head/merge + build/test (ou `git fetch` / artifact de fork)
- [ ] Público: default policy PRT em **evaluate**; enforce **2026-11-02** — revisar policy insights
- [ ] `persist-credentials: false` se o job não precisa git autenticado
- [ ] Checkout v7: `allow-unsafe-pr-checkout` só inspeção-só; pin actions em **SHA completo**
- [ ] Cruzar com `GITHUB_TOKEN` (§P), OIDC (§Q), env secrets (§R), variables (§S)


## Artifact attestations + compromised runners (2026-09-27)

**Nota:** `notes/2026-09-27-04-github-actions-artifact-attestations-compromised-runners.md` · extract `github-credenciais-higiene.md` §14 · `github-auth-errors.md` §U  
Fontes: [Artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations) · [Using attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations) · [Compromised runners](https://docs.github.com/en/actions/concepts/security/compromised-runners) · [Secure use](https://docs.github.com/en/actions/reference/security/secure-use) · [Self-hosted runners](https://docs.github.com/en/actions/reference/runners/self-hosted-runners) (acesso **2026-09-27** ~03:43)

- [ ] Release/binário/imagem: gerar provenance com `actions/attest` (`id-token`+`attestations`; imagem + `packages`)
- [ ] SLSA L2 = attest; L3 = attest + reusable (perms nos dois lados)
- [ ] Consumo: `gh attestation verify` (`-R` / `oci://` / `--signer-workflow`); delete attestation invalida trust
- [ ] Cross-repo: `GITHUB_TOKEN` → deploy key → App → FG org; **proibido** classic / SSH pessoal no workflow
- [ ] Self-hosted público ≈ não; preferir hosted ou efêmero/JIT + groups; environment não isola
- [ ] Runner comprometido → tratar secrets/`GITHUB_TOKEN` como vazados (cruzar IR / higiene §6)
- [ ] Cruzar com script injection (§T), `GITHUB_TOKEN` (§P), OIDC (§Q), env secrets (§R)


## Immutable releases + release attestations (2026-09-27)

**Nota:** `notes/2026-09-27-05-github-immutable-releases-release-attestations.md` · extract `github-credenciais-higiene.md` §15 · `github-auth-errors.md` §V  
Fontes: [Immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) · [Prevent release changes](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/establish-provenance-and-integrity/prevent-release-changes) · [Verify release integrity](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/verify-release-integrity) · [REST Orgs](https://docs.github.com/en/rest/orgs/orgs) (acesso **2026-09-27** ~04:41)

- [ ] Enable imutabilidade (repo/org) — só releases **futuros**; draft→assets→publish
- [ ] Tag+assets travados; notes/title/latest editáveis; tag name não reutilizável pós-delete; resurrection blocked
- [ ] Release attestation automática ≠ artifact attestation (§U) — combinar em release consumível
- [ ] Verify: `gh release verify` / `verify-asset` (não source zip sob demanda) · UI Immutable
- [ ] Org API `admin:org` / FG Organization write — preferir UI; CI com `GITHUB_TOKEN`
- [ ] Cruzar com attestations (§U), `GITHUB_TOKEN` (§P), script injection (§T)


## Dependabot malware alerts + dependency review (2026-09-27)

**Nota:** `notes/2026-09-27-06-github-dependabot-malware-dependency-review.md` · extract `github-credenciais-higiene.md` §16 · `github-auth-errors.md` §W  
Fontes: [Malware alerts](https://docs.github.com/en/code-security/concepts/supply-chain-security/malware-alerts) · [Configure malware](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-malware-alerts) · [Manage malware](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-dependabot-alerts/manage-malware-alerts) · [Auto-triage](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-auto-triage-rules) · [Advisory Database](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/github-advisory-database) · [Dependency review](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-dependency-review) · [Configure action](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configure-dependency-review-action) (acesso **2026-09-27** ~05:45)

- [ ] Repos com manifests: Dependabot alerts **+** malware alerts (UI Advanced Security)
- [ ] Malware ≠ CVE: remover pacote; sem fix version; sem PR automático Dependabot
- [ ] FP interno/homônimo → preset Dismiss package malware alerts (off por default; risco de dismissar malware real)
- [ ] Dependency review no PR + action required (`contents: read`, pin SHA)
- [ ] Cruzar com secrets Dependabot store, script injection (§T), attest/immutable (§U/§V)

## Dependabot security updates + grouped PRs (2026-09-27)

**Nota:** `notes/2026-09-27-07-github-dependabot-security-updates-grouped.md` · extract `github-credenciais-higiene.md` §17 · `github-auth-errors.md` §X  
Fontes: [Security updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-security-updates) · [Configure](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-security-updates) · [Private registries](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configure-access-to-private-registries) · [Dependabot on Actions](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-on-actions) (acesso **2026-09-27** ~06:43)

- [ ] Repos com CVE: Enable **Dependabot security updates** (UI; após graph+alerts)
- [ ] Muitos PRs: Enable **Grouped security updates** (UI) e/ou `groups` + `applies-to: security-updates`
- [ ] Só security (sem version): `open-pull-requests-limit: 0`; sem `target-branch` no YAML
- [ ] Packages: Manage Actions access Read + `GITHUB_TOKEN` > PAT
- [ ] Registry privado / CI Dependabot: store **Dependabot** secrets ou OIDC
- [ ] Cruzar com malware/DR (§W), stores (`2026-09-20-29`), `GITHUB_TOKEN` (§P), script injection (§T)

## Dependabot version updates + schedule/cooldown (2026-09-27)

**Nota:** `notes/2026-09-27-08-github-dependabot-version-updates-schedule-hygiene.md` · extract `github-credenciais-higiene.md` §18 · `github-auth-errors.md` §Y  
Fontes: [Version updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates) · [Configure](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-version-updates) · [Options](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) · [Optimizing PRs](https://docs.github.com/en/code-security/tutorials/secure-your-dependencies/optimizing-pr-creation-version-updates) · [Auto-update Actions](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/auto-update-actions) (acesso **2026-09-27** ~07:47)

- [ ] Repos que querem latest (não só CVE): `dependabot.yml` com schedule + cooldown
- [ ] Higiene: `weekly` + groups minor/patch; majors manuais via `ignore` update-types
- [ ] Actions: ecosystem `github-actions` + `directory: "/"`
- [ ] Fork: Enable explícito; `open-pull-requests-limit: 0` se só security
- [ ] Cruzar com security/grouped (§X), malware/DR (§W), stores (`2026-09-20-29`), script injection (§T)

## Dependabot auto-triage + multi-ecosystem updates (2026-09-27)

**Nota:** `notes/2026-09-27-09-github-dependabot-auto-triage-multi-ecosystem.md` · extract `github-credenciais-higiene.md` §19 · `github-auth-errors.md` §Z  
Fontes: [Auto-triage](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-auto-triage-rules) · [Presets](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/prioritize-with-preset-rules) · [Custom](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/auto-triage-dependabot-alerts) · [Auto-dismissed](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-dependabot-alerts/managing-automatically-dismissed-alerts) · [CWE criteria](https://docs.github.com/en/code-security/reference/supply-chain-security/criteria-for-preset-rules) · [Multi-ecosystem](https://docs.github.com/en/code-security/concepts/supply-chain-security/multi-ecosystem-updates) · [Configure multi](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configuring-multi-ecosystem-updates) · [Options](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) (acesso **2026-09-27** ~08:44)

- [ ] Ruído npm-dev: preset low-impact (private Enable); malware FP: preset dismiss (cuidado all-versions)
- [ ] PRs seletivos: security updates **off** + custom open-PR; PRs em massa: security **on** (§X)
- [ ] Org: enforced vs enabled; dismissal before open-PR; audit `resolution:auto-dismiss`
- [ ] Multi-tech version: `multi-ecosystem-groups` + `patterns` obrigatório; verify Insights→Dependabot
- [ ] Cruzar com security/grouped (§X), version (§Y), malware/DR (§W), stores (`2026-09-20-29`)

## Actions Runner Controller / scale sets (2026-09-27)

**Nota:** `notes/2026-09-27-10-github-arc-scale-sets-auth-ops.md` · extract `github-credenciais-higiene.md` §20 · `github-auth-errors.md` §AA  
Fontes: [About ARC](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller) · [Authenticate](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/authenticating-to-the-github-api) · [Deploy](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/deploying-runner-scale-sets-with-actions-runner-controller) · [Workflow](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/using-actions-runner-controller-runners-in-a-workflow) (acesso **2026-09-27 ~09:43**)

- [ ] Self-hosted autoscaling: ARC scale sets (JIT efêmero) > runner VM persistente
- [ ] Auth: App (org/repo) > FG > classic; enterprise = classic só
- [ ] Secret K8s ref; namespaces runners ≠ operator; runner groups
- [ ] DinD privileged; k8s mode manter require job container
- [ ] `runs-on` = scale set name / labels; público → hosted (§U)
- [ ] Cruzar com compromised runners (§U), `GITHUB_TOKEN` (§P), App/`ghs_` (`2026-09-20-15`)

## Dependabot org Global (runner / private access) + ruleset DR + group-by (2026-09-27)

**Nota:** `notes/2026-09-27-11-github-dependabot-org-global-runner-private-access.md` · extract `github-credenciais-higiene.md` §21 · `github-auth-errors.md` §AB  
Fontes: [Global settings](https://docs.github.com/en/code-security/securing-your-organization/enabling-security-features-in-your-organization/configuring-global-security-settings-for-your-organization) · [Self-hosted Dependabot](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configure-on-self-hosted-runners) · [Enforce DR](https://docs.github.com/en/code-security/how-tos/secure-at-scale/configure-organization-security/configure-specific-tools/enforce-dependency-review) (acesso **2026-09-27 ~10:38**)

- [ ] Org: Global settings Dependabot (runner type / private grant / Actions runners) pela UI
- [ ] Self-hosted: label `dependabot` (ou custom) **antes** do Enable; públicos ficam hosted
- [ ] Grant private: documentar blast (todos users org via Dependabot)
- [ ] Enforce DR: org Rulesets → Require workflows to pass → workflow DR
- [ ] Monorepo version: `group-by: dependency-name` quando muitos dirs mesmo ecosystem

## Security configurations + custom patterns (2026-09-27)

**Nota:** `notes/2026-09-27-12-github-security-configurations-custom-patterns.md` · extract `github-credenciais-higiene.md` §22 · `github-auth-errors.md` §AC  
Fontes: [At scale](https://docs.github.com/en/code-security/concepts/security-at-scale/organization-security) · [Create configuration](https://docs.github.com/en/code-security/how-tos/secure-at-scale/configure-organization-security/establish-complete-coverage/create-custom-configuration) · [Custom patterns](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/customize-leak-detection/define-custom-patterns) · [REST](https://docs.github.com/en/rest/code-security/configurations) (acesso **2026-09-27 ~11:44**)

- [ ] Org: Configurations (repo enablement) + Global settings (custom patterns / org policies) pela UI
- [ ] Custom pattern: dry run → publish → PP opcional (só onde SS push protection on)
- [ ] Default = novos; transferidos manuais; Enforce bloqueia override set
- [ ] API: `write:org`; enterprise-enforced ≠ FG/App
- [ ] Cruzar Global Dependabot (§AB), push protection (§O), malware/DR (§W)

## Validity checks (partner) + configuration statuses / enforcement (2026-09-27)

**Nota:** `notes/2026-09-27-13-github-validity-checks-config-statuses-enforcement.md` · extract `github-credenciais-higiene.md` §23 · `github-auth-errors.md` §AD  
Fontes: [Validity checks](https://docs.github.com/en/code-security/concepts/secret-security/validity-checks) · [Enable validity](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/customize-leak-detection/enable-validity-checks) · [Statuses](https://docs.github.com/en/code-security/reference/security-at-scale/configuration-statuses) · [Enforcement](https://docs.github.com/en/code-security/reference/security-at-scale/configuration-enforcement) (acesso **2026-09-27 ~12:39**)

- [ ] Partner validity via Secret Protection UI / security configuration (escala) — sem PAT
- [ ] Após Apply: monitorar `attached`/`failed`/`removed`/`enforced`; `failed` não herda updates
- [ ] Enforce: quebra se Actions off / actions required ausentes / languages default setup
- [ ] REST sob Enforce pode parecer sucesso sem mudar — reler UI/GET
- [ ] Cruzar §AC configs, §O push protection, IR GitHub

## Secret scanning alert triage — REST / webhooks / monitor (2026-09-27)

**Nota:** `notes/2026-09-27-14-github-secret-scanning-alert-triage-rest-webhooks.md` · extract `github-credenciais-higiene.md` §24 · `github-auth-errors.md` §AE  
Fontes: [Resolving](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-secret-scanning-alerts/resolving-alerts) · [REST SS](https://docs.github.com/en/rest/secret-scanning/secret-scanning) · [Webhooks](https://docs.github.com/en/webhooks/webhook-events-and-payloads#secret_scanning_alert) · [Monitoring](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-secret-scanning-alerts/monitoring-alerts) (acesso **2026-09-27 ~13:39**)

- Avaliar validity/labels (§AD) → **revogar** → Close as manual (`revoked`/`false_positive`/`wont_fix`/`used_in_tests`)
- Report leak privado = PAT preview; rotacionar antes se downtime
- REST: FG Secret scanning alerts; classic `security_events`/`repo`; `hide_secret`; plaintext `secret` = não logar
- Webhooks: `secret_scanning_alert` (`created`/`resolved`/`validated`/`publicly_leaked`/…) + location + scan; filtrar PP bypass
- Notificações: incremental (author sempre) ≠ historical (sem author)
- Cruzar push protection §O · validity §AD · IR GitHub

## CodeQL default setup — language matrix / runners / auth (2026-09-27)

**Nota:** `notes/2026-09-27-15-github-codeql-default-setup-language-matrix.md` · extract `github-credenciais-higiene.md` §25 · `github-auth-errors.md` §AF  
Fontes: [Configuring default setup](https://docs.github.com/en/code-security/code-scanning/enabling-code-scanning/configuring-default-setup-for-code-scanning) · [About CodeQL](https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning-with-codeql) · [Query suites](https://docs.github.com/en/code-security/concepts/code-scanning/codeql/codeql-query-suites) · [REST](https://docs.github.com/en/rest/code-scanning/code-scanning) (acesso **2026-09-27 ~14:39**)

- [ ] Enable: UI Default (Actions on + público/Code Security) ou security configuration — sem PAT
- [ ] Languages: matriz CodeQL (incl. Rust/Actions); REST enum default-setup **sem** `rust`
- [ ] Suite default vs extended; threat model preview Java/Kotlin+C#; idle 6m → weekly off
- [ ] Runners: label `code-scanning` / labeled; pós-enable → re-enable ou edit
- [ ] Auth: FG Administration (setup) · FG Code scanning alerts (triage/SARIF) · classic último
- [ ] Cruzar §AC configs · §AA runners · §AE SS (produto diferente)

## CodeQL advanced setup — custom queries / packs / config / auth (2026-09-27)

**Nota:** `notes/2026-09-27-16-github-codeql-advanced-setup-custom-queries.md` · extract `github-credenciais-higiene.md` §26 · `github-auth-errors.md` §AG  
Fontes: [Configuring advanced setup](https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/configuring-advanced-setup-for-code-scanning) · [Workflow options](https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/customizing-your-advanced-setup-for-code-scanning) · [At scale](https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/configuring-advanced-setup-for-code-scanning-with-codeql-at-scale) (acesso **2026-09-27 ~15:44**)

- [ ] Preferir default (§AF) se não precisar custom; enable advanced = UI + workflow — sem PAT
- [ ] Languages/`init` incluem **`rust`** (DELTA vs REST default-setup); matrix 1 lang; Swift≠ARC
- [ ] Suites/packs/config-file/`threat-models`/`query-filters`; não `github/codeql@main`
- [ ] Secrets: `external-repository-token` (FG Contents); GHES registries = classic `read:packages` (gap Packages)
- [ ] At-scale: App + scripts; Cruzar §AF default · §AC configs · §AA runners

## CodeQL compiled languages — build modes none/autobuild/manual (2026-09-27)

**Nota:** `notes/2026-09-27-17-github-codeql-compiled-languages-build-modes.md` · extract `github-credenciais-higiene.md` §27 · `github-auth-errors.md` §AH  
Fontes: [Concepts](https://docs.github.com/en/code-security/concepts/code-scanning/codeql/codeql-for-compiled-languages) · [How-to](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/codeql-for-compiled-languages) · [Build options](https://docs.github.com/en/code-security/reference/code-scanning/codeql/build-options-for-compiled-languages) (acesso **2026-09-27 ~16:43**)

- [ ] `none` / `autobuild` / `manual` — default usa `none` (C/C++·C#·Java·Rust) ou `autobuild` (Go·Swift·Kotlin)
- [ ] Kotlin força `autobuild`; Rust só `none`; Swift macOS ≠ ARC
- [ ] Autobuild fail → advanced `manual`; matrix por linguagem
- [ ] Dependency caching: default on hosted; advanced `dependency-caching`; Java·Go·C#
- [ ] Auth: sem PAT para build-mode; private registries org; cruzar §AF/§AG/§AA

## Code scanning alert triage + Copilot Autofix / agentic (2026-09-27)

**Nota:** `notes/2026-09-27-18-github-code-scanning-alert-triage-autofix.md` · extract `github-credenciais-higiene.md` §28 · `github-auth-errors.md` §AI  
Fontes: [Resolving](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/resolve-alerts) · [Triage PRs](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/triage-alerts-in-pull-requests) · [Autofix](https://docs.github.com/en/code-security/concepts/code-scanning/autofix-for-code-scanning) · [REST](https://docs.github.com/en/rest/code-scanning/code-scanning) (acesso **2026-09-27 ~17:39**)

- [ ] UI Security: Generate fix → Create PR with fix; PR annotations + Show paths (write)
- [ ] Dismiss reasons: `false positive` · `won't fix` · `used in tests` · `mitigated` + comment
- [ ] Autofix on com CodeQL (sem Copilot sub); agentic = assign Copilot (credits; preview)
- [ ] Auth: FG Code scanning alerts; classic `security_events`/`repo`; commit autofix API = `repo`
- [ ] Merge protection + delegated dismissal: ver secção abaixo / §AJ
- [ ] Cruzar §AF/§AG/§AH setup · §AE SS (separar)

## Code scanning merge protection + delegated dismissal (2026-09-27)

**Nota:** `notes/2026-09-27-19-github-code-scanning-merge-protection-delegated-dismissal.md` · extract `github-credenciais-higiene.md` §29 · `github-auth-errors.md` §AJ  
Fontes: [Set merge protection](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/set-merge-protection) · [Available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets) · [REST rules](https://docs.github.com/en/rest/repos/rules) · [Delegated dismissal](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/enable-delegated-alert-dismissal) · [Review requests](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/review-alert-dismissal-requests) · [REST dismissal-requests](https://docs.github.com/en/rest/code-scanning/alert-dismissal-requests) (acesso **2026-09-27 ~18:42**)

- [ ] Ruleset: Require code scanning results + tool + Alerts/Security thresholds; bloqueia alert≥threshold · scan pending · tool missing
- [ ] REST `code_scanning` + `alerts_threshold` / `security_alerts_threshold` enums
- [ ] Prevent direct alert dismissals: repo Advanced Security ou security configuration Enforce
- [ ] Request: PATCH alert `create_request`; Review: UI Requests ou PATCH dismissal-requests approve/deny
- [ ] Auth: UI first · FG Administration (rulesets) · FG Code scanning alerts (request) · classic `security_events` (review REST)
- [ ] Cruzar §AI triage · §AF/§AG setup · §AC configs · §AE SS (separar)

## SARIF upload / third-party tooling / CI externo (2026-09-27)

**Nota:** `notes/2026-09-27-20-github-sarif-upload-third-party-ci.md` · extract `github-credenciais-higiene.md` §30 · `github-auth-errors.md` §AK  
Fontes: [Upload SARIF](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/integrate-with-existing-tools/upload-sarif-file) · [Existing CI](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/integrate-with-existing-tools/use-with-existing-ci-system) · [REST](https://docs.github.com/en/rest/code-scanning/code-scanning) · [Troubleshoot](https://docs.github.com/en/code-security/reference/code-scanning/sarif-files/troubleshoot-sarif-uploads) (acesso **2026-09-27 ~19:39**)

- [ ] CodeQL Actions = upload automático; third-party = `upload-sarif@v4` + `security-events: write`
- [ ] Category / `runAutomationDetails.id` se multi-upload no mesmo commit
- [ ] CI externo: App → FG Code scanning alerts → classic `security_events`; gzip+Base64 no REST
- [ ] Limites: 10 MB gzip; 1000 uploads/h REST; default setup bloqueia só SARIF CodeQL
- [ ] Auth: GITHUB_TOKEN first · FG Code scanning alerts · App · classic último
- [ ] Cruzar §AF/§AG setup · §AI triage · §AJ merge gate

## Security campaigns + alert tracking with Issues (2026-09-27)

**Nota:** `notes/2026-09-27-21-github-security-campaigns-alert-tracking-issues.md` · extract `github-credenciais-higiene.md` §31 · `github-auth-errors.md` §AL  
Fontes: [About campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns) · [Creating/managing](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/creating-managing-security-campaigns) · [Tracking](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/tracking-security-campaigns) · [Alert↔issues](https://docs.github.com/en/code-security/concepts/code-scanning/alert-tracking-with-issues) · [REST campaigns](https://docs.github.com/en/rest/campaigns/campaigns) (acesso **2026-09-27 ~20:50**)

- [ ] Campaign = burn-down focado; configurations (§AC) = enablement — não misturar
- [ ] UI primeiro (owner/SM); ≤1000 alerts; ≤10 active; draft→publish; due + managers
- [ ] Code: Autofix on publish; opcional campaign issues por repo; Assign Copilot ≤25
- [ ] Alert↔Issues (CS preview): 1:1 alert→issue; issue≤50; **sem** auto-sync close
- [ ] REST: `security_events` classic; FG Code scanning alerts read; drafts fora da API

## Code Quality thresholds + tool status + SARIF residual (2026-09-27)

**Nota:** `notes/2026-09-27-22-github-code-quality-thresholds-tool-status-sarif.md` · extract `github-credenciais-higiene.md` §32 · `github-auth-errors.md` §AM  
Fontes: [Set PR thresholds](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/set-pr-thresholds) · [Enable Code Quality](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/enable-code-quality) · [Restrict coverage](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/restrict-code-coverage) · [Set up coverage](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/set-up-code-coverage) · [Tool status](https://docs.github.com/en/code-security/concepts/code-scanning/tool-status-page) · [Use tool status](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/use-the-tools-status-page-for-code-scanning) (acesso **2026-09-27 ~21:48**)

- [ ] Code Quality gate ≠ CS merge protection (§AJ); AI findings fora do threshold
- [ ] Enable UI (enterprise Allow + Actions); confirmar check "CodeQL - Code Quality" antes de Active
- [ ] Require code quality results: Errors / Warnings+ / Notes+ / All; Evaluate→Active
- [ ] Restrict code coverage: min line % · max drop; Cobertura via `upload-code-coverage@v1` + `code-quality: write`
- [ ] Tool status: repo default branch; working/attention/not working; file coverage %; delete config só default
- [ ] SARIF residual: cruzar §AK (10 MB / invalid / default-setup CodeQL block / fingerprints)
- [ ] Auth: UI first · GITHUB_TOKEN coverage · FG Administration ruleset · classic último

## Private vulnerability reporting + repository advisories + security managers (2026-09-27)

**Nota:** `notes/2026-09-27-23-github-private-vulnerability-reporting-repository-advisories.md` · extract `github-credenciais-higiene.md` §33 · `github-auth-errors.md` §AN  
Fontes: [Coordinated disclosure](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/coordinated-disclosure) · [Repository advisories](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/repository-security-advisories) · [Configure PVR](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository) · [Report privately](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately) · [Manage reports](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/manage-vulnerability-reports) · [Create](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/create-repository-advisory) · [Publish](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/publish-repository-advisory) · [Security managers](https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/managing-security-managers-in-your-organization) · [REST](https://docs.github.com/en/rest/security-advisories/repository-advisories) (acesso **2026-09-27 ~22:46**)

- [ ] PVR ≠ SECURITY.md; enable UI Advanced Security; org → security configuration (§AC)
- [ ] Triage: Accept as draft · private fork · Close; publish com fix version; CVE request ≠ publish
- [ ] Security manager: least privilege org security (read all repos + alerts + config)
- [ ] Auth: UI first · FG Repository security advisories · App · classic `repository_advisories`/`repo` último

## Temporary private fork + writing advisories best practices (2026-09-27)

**Nota:** `notes/2026-09-27-24-github-advisory-private-fork-write-best-practices.md` · extract `github-credenciais-higiene.md` §34 · `github-auth-errors.md` §AO  
Fontes: [Collaborate in a fork](https://docs.github.com/en/code-security/tutorials/fix-reported-vulnerabilities/collaborate-in-a-fork) · [Write security advisories](https://docs.github.com/en/code-security/tutorials/fix-reported-vulnerabilities/write-security-advisories) · [Permissions](https://docs.github.com/en/code-security/reference/permissions/repository-security-advisory) · [REST](https://docs.github.com/en/rest/security-advisories/repository-advisories) (acesso **2026-09-27 ~23:47 BRT**)

- [ ] Fork privado temporário: CI/integrations blocked; status checks off; merge em lote na advisory (admin)
- [ ] ≤1 PR → main do fork; publish apaga fork; nome `repo-ghsa-…`
- [ ] VVR sintaxe GAD/OSV; 1 range/campo; package name cedo; prereleases/branches com cuidado
- [ ] Auth: UI first · FG Repository security advisories write · App · classic último

## Edit/delete repository advisories + Improve global GAD (2026-09-28)

**Nota:** `notes/2026-09-28-01-github-edit-delete-advisory-global-gad.md` · extract `github-credenciais-higiene.md` §35 · `github-auth-errors.md` §AP  
Fontes: [Edit](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/edit-repository-advisories) · [Delete](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/delete-repository-advisories) · [Edit GAD](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/edit-advisory-database) · [About GAD](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/about-the-github-advisory-database) · [Browse](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/browse-advisory-database) · [Permissions](https://docs.github.com/en/code-security/reference/permissions/repository-security-advisory) · [REST](https://docs.github.com/en/rest/security-advisories/repository-advisories) (acesso **2026-09-28 ~00:40 BRT**)

- [ ] Corrigir advisory do repo: UI Edit advisory (admin); credits precisam accept
- [ ] Delete published: Support only; close draft ≠ delete
- [ ] Melhorar record global: Suggest improvements / PR `advisory-database` (1/PR); **não** muda página do repo
- [ ] Auth: UI/Support first · FG Repository security advisories write · App · classic último

## Global advisories REST + Dependabot from GAD (2026-09-28)

**Nota:** `notes/2026-09-28-02-github-global-advisories-rest-dependabot-from-gad.md` · extract `github-credenciais-higiene.md` §36 · `github-auth-errors.md` §AQ  
Fontes: [REST global](https://docs.github.com/en/rest/security-advisories/global-advisories) · [Browse](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/browse-advisory-database) · [Dependabot alerts](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-dependabot-alerts) · [REST alerts](https://docs.github.com/en/rest/dependabot/alerts) (acesso **2026-09-28 ~01:40 BRT**)

- [ ] Ler GAD: UI `github.com/advisories` ou `GET /advisories` (default reviewed; malware = `type=malware`)
- [ ] Unauth 60/h — não mintar classic só por rate limit
- [ ] Repos afetados: botão Dependabot alerts no advisory (precisa acesso alerts)
- [ ] Auth alerts: UI first · FG Dependabot alerts · App · classic `security_events` último

## GraphQL GAD + Dependabot assign / AI agents (2026-09-28)

**Nota:** `notes/2026-09-28-03-github-graphql-gad-dependabot-assign-agent.md` · extract `github-credenciais-higiene.md` §37 · `github-auth-errors.md` §AR  
Fontes: [GraphQL security advisories](https://docs.github.com/en/graphql/reference/security-advisories) · [Forming calls](https://docs.github.com/en/graphql/guides/forming-calls-with-graphql) · [GraphQL rate limits](https://docs.github.com/en/graphql/overview/rate-limits-and-node-limits-for-the-graphql-api) · [About Dependabot alerts](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-dependabot-alerts) · [Viewing/updating](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-dependabot-alerts/viewing-and-updating-dependabot-alerts) · [REST alerts](https://docs.github.com/en/rest/dependabot/alerts) (acesso **2026-09-28 ~02:42 BRT**)

- [ ] Ler GAD: UI primeiro; GraphQL só se automação precisar (`securityAdvisories` / `securityAdvisory` / `securityVulnerabilities`)
- [ ] `cvssSeverities` + `notificationsPermalink`; classification `GENERAL`/`MALWARE`
- [ ] Assign: write+ user/team/agent; agent → draft PR + View Session; org overview sem assignments
- [ ] Auth: UI · FG Dependabot alerts write · App · classic `security_events` último; agent só com autorização

## Security overview (org) + Dependabot alert webhooks (2026-09-28)

**Nota:** `notes/2026-09-28-04-github-security-overview-dependabot-webhooks.md` · extract `github-credenciais-higiene.md` §38 · `github-auth-errors.md` §AS  
Fontes: [Security overview](https://docs.github.com/en/code-security/concepts/security-at-scale/security-overview) · [Permissions](https://docs.github.com/en/code-security/reference/permissions/security-overview) · [Filtering](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/filtering-alerts-in-security-overview) · [Dashboard metrics](https://docs.github.com/en/code-security/reference/security-at-scale/overview-dashboard-metrics) · [Export](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/exporting-data-from-security-overview) · [Dependabot metrics](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/viewing-metrics-for-dependabot-alerts) · [Webhooks](https://docs.github.com/en/webhooks/webhook-events-and-payloads#dependabot_alert) (acesso **2026-09-28 ~03:49 BRT**)

- [ ] Org Security and quality: Overview/Risk/Coverage/Assessments/Campaigns/Enablement/Dependabot dashboard
- [ ] Team free secret risk assessment; GHAS Code Security / Secret Protection para insights extras
- [ ] Owner/SM vs write vs alert-access; Assessments owners/SM; members cap 3000 repos
- [ ] Dashboard: Detection/Remediation/Prevention; severidade security-only; audit log p/ compliance
- [ ] Funnel Dependabot default has:patch + critical/high + EPSS≥0.01
- [ ] Webhook `dependabot_alert` (não `repository_vulnerability_alert`); App Dependabot alerts read
- [ ] Auth: UI · webhook App · FG Dependabot alerts · classic último

## GraphQL securityVulnerabilities package monitor + overview filters (2026-09-28)

**Nota:** `notes/2026-09-28-05-github-securityvulnerabilities-package-monitor-overview-filters.md` · extract `github-credenciais-higiene.md` §39 · `github-auth-errors.md` §AT  
Fontes: [GraphQL security advisories](https://docs.github.com/en/graphql/reference/security-advisories) · [About GAD](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/about-the-github-advisory-database) · [Available filters](https://docs.github.com/en/code-security/reference/security-at-scale/available-filters-for-security-overview) · [Filtering](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/filtering-alerts-in-security-overview) · [Forming calls](https://docs.github.com/en/graphql/guides/forming-calls-with-graphql) (acesso **2026-09-28 ~04:42 BRT**)

- [ ] Package monitor: `securityVulnerabilities(ecosystem, package, severities, classifications)` — ranges + firstPatchedVersion
- [ ] Advisory list/EPSS/CVE: `securityAdvisories` / REST `/advisories` (§AQ/§AR)
- [ ] Malware = classification MALWARE / UI `type:malware` — remover, não bump
- [ ] Overview filters reference: AND/OR/NOT; Dependabot `package`/`ecosystem`/`epss-percentage`/`assignee`; SS validity/bypassed
- [ ] Auth: UI · GraphQL App/FG curto · webhook Dependabot · FG alerts · classic último

## Secret scanning PP metrics / delegated bypass (2026-09-28)

**Nota:** `notes/2026-09-28-06-github-secret-scanning-push-protection-metrics-delegated-bypass.md` · `github-auth-errors.md` §AU · higiene §40  
- Insights **Secret scanning** (PP metrics, public preview) + Detection bypassed/blocked — UI; date = bypass date.  
- Delegated bypass: list / Exempt / 7d review; owners+SM always; custom role “Review and manage secret scanning bypass requests”.  
- REST bypass-requests (list/get/PATCH approve|reject/DELETE dismiss); classic `security_events` último.  
- Residual: Insights **CodeQL pull requests** (merged→default only; CSV; Autofix se enabled).  
- Cruzar §O PP users · §AE triage · §AS overview · §AT filters.


## CodeQL PR metrics + Autofix MTTR / Prevention (2026-09-28)

**Nota:** `notes/2026-09-28-07-github-codeql-pr-metrics-autofix-mttr.md` · `github-auth-errors.md` §AV · higiene §41  
Fontes: [View PR metrics](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/viewing-metrics-for-pull-request-alerts) · [PR alert metrics](https://docs.github.com/en/code-security/concepts/code-scanning/pull-request-alert-metrics) · [Dashboard metrics](https://docs.github.com/en/code-security/reference/security-at-scale/overview-dashboard-metrics) · [Export](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/export-data) · [Autofix](https://docs.github.com/en/code-security/concepts/code-scanning/autofix-for-code-scanning) (acesso **2026-09-28 ~06:42 BRT**)

- [ ] Insights **CodeQL pull requests**: write (org) / owners+SM (enterprise); Code Security required
- [ ] Só merged → default; date = alert creation; CSV com filtros; enterprise `owner:`
- [ ] Autofix graphs: accepted fraction · remediation rates · **MTTR** with/without; só se Autofix on
- [ ] Prevention: Prevented (fix date) vs Introduced (risk accepted / unresolved at merge); fixed PRs CodeQL|SS
- [ ] Autofix on com CodeQL (sem Copilot sub); agentic = assign + credits (preview)
- [ ] Auth: UI metrics/CSV · App/FG CS alerts p/ automação · classic último

## Production context / linked artifacts / custom props (2026-09-28)

**Nota:** `notes/2026-09-28-08-github-production-context-linked-artifacts-props-filters.md` · extract `github-credenciais-higiene.md` §42 · `github-auth-errors.md` §AW  
Fontes: [Prioritize production](https://docs.github.com/en/code-security/tutorials/secure-your-organization/prioritize-alerts-in-production-code) · [Linked artifacts](https://docs.github.com/en/code-security/concepts/supply-chain-security/linked-artifacts) · [Upload](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/establish-provenance-and-integrity/upload-linked-artifacts) · [Filters](https://docs.github.com/en/code-security/reference/security-at-scale/overview-dashboard-filters) · [Custom properties](https://docs.github.com/en/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization) · [REST artifact-metadata](https://docs.github.com/en/rest/orgs/artifact-metadata) (acesso **2026-09-28 ~07:38 BRT**)

- [ ] Storage → registry filters; Deployment → `has:deployment` / `runtime-risk` (enum DOC)
- [ ] Paths: attest+JFrog+REST (storage) · Dynatrace+MDC+REST (deployment); MDC preview
- [ ] `props.NAME:value` Overview (+ Dependabot/SS); rulesets targeting
- [ ] Auth: UI · integração · `GITHUB_TOKEN`/`artifact-metadata: write` · FG read · classic último


## Rulesets deployable/deployed + remove linked artifacts (2026-09-28)

**Nota:** `notes/2026-09-28-09-github-rulesets-deployable-deployed-remove-artifacts.md` · extract `github-credenciais-higiene.md` §43 · `github-auth-errors.md` §AX  
Fontes: [Changelog GA](https://github.blog/changelog/2026-04-14-deployment-context-in-repository-properties-and-alerts/) · [Creating org rulesets](https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization) · [Search repos](https://docs.github.com/en/search-github/searching-on-github/searching-for-repositories) · [Remove linked artifacts](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/establish-provenance-and-integrity/remove-linked-artifacts) · [REST org rules](https://docs.github.com/en/rest/orgs/rules) (acesso **2026-09-28 ~08:38 BRT**)

- [ ] System props: `deployable` (storage ativo) · `deployed` (deployment ativo)
- [ ] Search/ruleset filters: `deployable:true` · `deployed:true`
- [ ] REST `repository_property` + `source: system`; FG Org Administration write
- [ ] Remove: status `deleted`/`eol`/`decommissioned` — sem delete UI
- [ ] `required_deployments` (Actions env) ≠ linked-artifacts `deployed`
- [ ] Auth: UI · App/`GITHUB_TOKEN` metadata · App/FG Admin rulesets · classic último


## Push rulesets + bypass actors + enforcement (2026-09-28)

**Nota:** `notes/2026-09-28-10-github-push-rulesets-bypass-actors-enforcement.md` · extract `github-credenciais-higiene.md` §44 · `github-auth-errors.md` §AY  
Fontes: [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets) · [Creating rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository) · [Available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets) · [REST repos rules](https://docs.github.com/en/rest/repos/rules) · [FG permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens) (acesso **2026-09-28 ~09:49 BRT**)

- [ ] Caps 75/repo · 75/org; push = private/internal + fork network
- [ ] Protections: path / path-length / extension / size (≠ LFS); exceptions path+size
- [ ] Bypass: UI roles/teams/Apps/Dependabot · REST + DeployKey/User · modes always/PR/exempt
- [ ] Enforcement Active/Disabled/`evaluate` (Enterprise); layering = mais restritivo
- [ ] Auth: UI · Metadata read · Administration write · App · classic último

## Ruleset recipes / JSON import-export + Rule Insights (2026-09-28)

**Nota:** `notes/2026-09-28-11-github-ruleset-recipes-json-import-rule-insights.md` · extract `github-credenciais-higiene.md` §45 · `github-auth-errors.md` §AZ  
Fontes: [Managing rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository) · [GHEC managing](https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository) · [Org managing](https://docs.github.com/en/organizations/managing-organization-settings/managing-rulesets-for-repositories-in-your-organization) · [REST rule-suites](https://docs.github.com/en/rest/repos/rule-suites) · [github/ruleset-recipes](https://github.com/github/ruleset-recipes) (acesso **2026-09-28 ~10:55 BRT**)

- [ ] Import UI (New → Import a ruleset); export/history Download exclui bypass list (GHEC DOC; 180d)
- [ ] Recipes oficiais: branch best practices / PRs+commits / org one-rule / tag prevent-delete / org tag defaults
- [ ] Evaluate (GHEC) + Insights before Active; dashboard Team+; org Dashboard CSV
- [ ] REST suites: `pass`/`fail`/`bypass` + `evaluate_status`
- [ ] Auth: UI · Metadata read · Admin read (repo suites) · Admin write (mutate/org suites) · App · classic último
- [ ] Delegated bypass push GHEC (Bypass Requests, 7d) ≠ SS PP delegated
