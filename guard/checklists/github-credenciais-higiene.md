# Checklist — higiene de credenciais GitHub (extract operacional)

**Estado ao vivo 2026-10-05 ~11:40 BRT (UI GitHub, fonte Nexo):** baseline viva `/home/box/agent-data/nexo-guard/baseline/github-baseline-20261005.md` — 2FA **ON** (authenticator app); login Google sem senha/passkey; PATs classic/FG 0; OAuth Apps 0; SSH/GPG 0; Authorized Apps Copilot Chat/Cursor/Grok/Vercel; Installed Cursor/Vercel; `nexo-mobile-ops` Dependabot alerts+security updates ON, ruleset protect-main sem enforce (private free).  
**Estado anterior (~11:22 BRT):** ver baseline `notes/2026-10-05-github-seguranca-baseline.md` e `nexo/ops/2026-10-05-github-seguranca-baseline.md`. Conta sem PAT classic/FG na UI; OAuth Apps vazio; `box-secrets` sem GITHUB_*; env ainda pode listar nomes GITHUB_* via injecção da plataforma mas valores estão **401 mortos** (não recriar classic amplo).


**Atualizado:** 2026-09-28 ~03:49 BRT (Security overview + Dependabot webhooks; nota `2026-09-28-04-github-security-overview-dependabot-webhooks.md`)
**Notas:** **`2026-09-27-14-…`** · **`2026-09-27-13-…`** · **`2026-09-27-12-…`** · **`2026-09-27-09-…`** · **`2026-09-27-08-…`** · **`2026-09-27-07-…`** · **`2026-09-27-06-…`** · **`2026-09-27-05-…`** · **`2026-09-27-04-…`** · **`2026-09-27-03-…`** · **`2026-09-27-02-…`** · **`2026-09-27-01-…`** · `2026-09-20-01-…` · `2026-09-20-03-…` · `2026-09-20-06-…` · `2026-09-20-11-…` · `2026-09-20-15-…` · **`2026-09-20-17-…`** · **`2026-09-20-27-…`** · **`2026-09-20-29-…`** · **`2026-09-26-02-…`** · **`2026-09-26-03-…`** · **`2026-09-26-04-github-org-pat-policy-privileged-oauth-ssh-survive.md`** · **`2026-09-26-05-…`** · **`2026-09-26-06-github-gcm-cache-sso-ssh-fg-agent-perms-agh-edge-1a.md`** · **`2026-09-26-07-github-passkeys-2fa-checkup-sudo-recovery.md`** · **`2026-09-26-08-…`** · **`2026-09-26-09-…`** · **`2026-09-26-10-…`** · **`2026-09-26-11-…`**  
**Erros HTTP / anti-loop:** `checklists/github-auth-errors.md` (árvore + §A–Z · §AA–§AE; §E OAuth … §W malware/DR + §X–§Z + §AB Global + §AC configs/patterns + §AD validity/statuses + §AE SS triage · … · §AS overview/webhooks)  
**Lab:** `nexo/ops/2026-09-20-github-auth-lab.md`

Citações (acesso **2026-09-27** ~00:39): [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) · [Org PAT policy](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization) · [Reviewing/revoking FG in org](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/reviewing-and-revoking-personal-access-tokens-in-your-organization) · [Privileged OAuth apps](https://docs.github.com/en/apps/oauth-apps/using-oauth-apps/privileged-oauth-apps) · [SSO authorize PAT](https://docs.github.com/en/authentication/authenticating-with-saml-single-sign-on/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on) · [Authorizing OAuth apps](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps) · [Token expiration](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation)

Itens **LAB** = observação Nexo/Guard; não doc oficial.

## 1. Escolher o instrumento

- [ ] Command line Git: preferir **GitHub CLI** (`gh auth login`, HTTPS + autenticar Git **Y**) ou **GCM** (OAuth/2FA — sem mintar PAT) — *Caching credentials* / Managing PATs; nota `2026-09-26-06-…`
- [ ] Script/teste pessoal curto → **fine-grained** PAT (`github_pat_`)
- [ ] Long-lived / multi-repo / org / bot → **GitHub App** (installation token ~1 h)
- [ ] CI mesmo repo → `GITHUB_TOKEN`; cross-repo Actions → App
- [ ] Classic `ghp_` só se gap oficial FG (Packages, multi-org, outside collaborator, write em público alheio, Projects de user) — WARNING blast radius; **Checks write ≠ classic** (só App — ver §7 / auth §N)
- [ ] Cap **50** FG → planejar App; não acumular órfãos
- [ ] OAuth app (MCP incluso): ≤**10** tokens por user/app/scope; 11º revoga outro; **10 creates/h** → re-auth prompt — sem force_reauth em loop (Token expiration; nota `2026-09-26-02-…`)
- [ ] OAuth expirável: access **8 h**; refresh `ghr_` **6 meses sem uso**; refresh rota o par; scope **`offline_access`** = opt-in runtime (Authorizing OAuth apps; nota `2026-09-26-03-…`)
- [ ] CLI headless: device flow (sem `client_secret`; códigos 900 s; `slow_down`/+5 s; ≤50 submits/h) — preferir a mintar PAT

## 2. Criar / restringir PAT

- [ ] FG: um resource owner; **Only select repositories**; permissões mínimas; expiração 30–90 d (evitar `none` salvo política)
- [ ] FG: mesmo com Only select, token **sempre** tem read-only a **todos** os repositórios **públicos** no GitHub (Managing PATs; nota `2026-09-26-05-…`)
- [ ] Org que bloqueou FG **não aparece** em Resource owner; justification se approval exigido
- [ ] FG/classic ficam **inactive** se o user **perde acesso** ao recurso (não só expire/revoke)
- [ ] Create-repo `POST /user/repos`: FG = **Administration write** (Permissions FG; docs também listam sob heading “Repository creation” — mesmo endpoint); classic = `public_repo`/`repo`; falha → `X-Accepted-GitHub-Permissions`
- [ ] Classic inevitável: scope mínimo; lembrar acesso a **todos** os repos do dono
- [ ] Classic **sem scopes** = só informação pública (ainda é credencial — não “morto”)
- [ ] Git CLI: Password = PAT; **username não autentica** (obrigatório no prompt; vazio → inválido); PAT **só HTTPS** — remote SSH ≠ PAT (nota `2026-09-26-05-…`)
- [ ] Sem prompt Git → cache (Keychain/GCM/Credential Manager); Windows: apagar entrada GitHub no Credential Manager; macOS Keychain; Git for Windows ≥2.29; limpar **após** Security log (nota `2026-09-26-06-…`)
- [ ] EMU re-prompt eterno → `git config --global credential.gitHubAccountFiltering "false"`
- [ ] Prefixo = tipo: `ghp_` / `github_pat_` / `gho_` / `ghu_` / `ghs_` / `ghr_` — tratar como segredo
- [ ] Template URL FG opcional (`/settings/personal-access-tokens/new?…`) para perms mínimas — ainda inventariar órfãos

## 3. Tokens opacos (incl. `ghs_` 2026)

- [ ] **Nunca** validar token por length fixo (40) nem regex `ghs_[A-Za-z0-9]{36}`
- [ ] Installation / Actions `GITHUB_TOKEN` pode ser opaco curto **ou** `ghs_APPID_JWT` (~520 chars, 2 dots) — Changelog 2026-04-24 / 2026-05-15
- [ ] Storage ≥520 chars se guardar `ghs_`
- [ ] Não parsear JWT de `ghs_`; header teste `X-GitHub-Stateless-S2S-Token` é temporário
- [ ] Fingerprint LAB (prefix+len) só faz sentido estável em PAT; `ghs_` length varia

## 4. Canal Bot / MCP (**LAB**)

- [ ] Um canal: MCP OAuth **ou** PAT env — não misturar
- [ ] PAT inevitável em script: **Actions secret** (CI) ou **Codespaces secret** (dev) — Managing PATs; ver nota `2026-09-20-29-…` (stores não se cruzam)
- [ ] Secret-request só nomes em `CLOUD_AGENT_INJECTED_SECRET_NAMES` (observado: `GITHUB_PERSONAL_ACCESS_TOKEN`)
- [ ] Validar em Shell **novo**; nunca ecoar; sem `unset` sticky de `GITHUB_TOKEN`
- [ ] Probe `GET /user`: 401 → fingerprint; **2º idêntico → STOP**; 403/429 rate → esperar, **sem** force_reauth

## 5. Inventário periódico

- [ ] Developer settings → Fine-grained **e** Tokens (classic): apagar órfãos / classic amplo / sem expiração
- [ ] **Antes** de deletar PAT: checar se criou deploy key — deletar o PAT **remove** a deploy key (Managing PATs; nota `2026-09-26-02-…`)
- [ ] SSH and GPG keys; Applications → Authorized OAuth / GitHub Apps (OAuth: olhar rajadas / órfãos se houve loop de reauth)
- [ ] **Antes** de revogar **todas** as permissões de uma OAuth app: inventariar SSH/deploy keys — revoke-all **apaga** keys geradas pela app incl. deploy keys (Authorizing OAuth apps WARNING; nota `2026-09-26-03-…`)
- [ ] Security log 90 d: `personal_access_token.*` · `oauth_*` · `public_key.*` (ver `github-auth-errors.md` §G)
- [ ] `personal_access_token.credential_revoked` → tratar como vazamento até prova contrária
- [ ] Push protection usuário ligado


## 5b. Org policy / privileged OAuth / SSH que sobrevive

- [ ] Org Restrict PAT (FG ou classic): bloqueia recursos **owned** pela org — **SSH keys criadas por PATs continuam**; públicos da org ainda acessíveis a PATs (Org PAT policy; nota `2026-09-26-04-…`)
- [ ] Org Revoke FG (*Active tokens*): e-mail ao user; **SSH do token continua**; token **ainda lê públicos**; UI **não** lista classic (Reviewing/revoking FG in org)
- [ ] API org review/revoke FG = **só GitHub Apps** (não PAT/OAuth)
- [ ] FG approval: Require admin (**default**); `pending` → só públicos até approve; owners auto-approve; classic **fora** do approval
- [ ] Max lifetime FG default org **366 d**; classic sem requirement por default; non-compliant **não** auto-revoga — falha API na org
- [ ] SSO: classic = Configure SSO pós-criação; FG = durante criação; **linked identity** exige authorize mesmo se SSO não enforced
- [ ] SSO: regenerar/editar scopes classic → re-Authorize; expire também cai authorize
- [ ] SSH SSO: org **revoga** authorize → **criar key nova** (mesma key não reautoriza); certs CA da org sem authorize; `internal` enterprise precisa SSO auth (nota `2026-09-26-06-…`)
- [ ] Privileged OAuth (GitHub-owned: GCM, CLI, Desktop, Copilot CLI, VS Code, …): podem acessar org mesmo com restrict OAuth; algumas auto-incluídas **não** aparecem em Authorized OAuth; security log user ≠ audit log org
- [ ] Template FG: não mintar `copilot_requests=write` sem intenção — conta no allowance / overage
- [ ] IR: Restrict/Revoke FG **não** substitui Delete de SSH/deploy keys suspeitas (cruzar delete-PAT→deploy-key e revoke-all OAuth→SSH)


## 5c. Passkeys / 2FA checkup / sudo / recovery

- [ ] Preferir **passkey** (password+2FA) + TOTP backup; security key sozinha ≠ passwordless
- [ ] Add passkey só depois de TOTP/SMS; synced label vs device-bound (≥2 devices se device-bound)
- [ ] Upgrade security key → passkey; falha platform → delete+re-register; login `?passkey=true`
- [ ] Checkup **28 d** pós-enable 2FA — completar 2FA; dia 28 = reconfig se falhar
- [ ] Edit/Add 2FA **sem** Disable (mantém codes + org membership); Save no GitHub **antes** de apagar TOTP antigo
- [ ] Recovery codes: Generate new **invalida** velhos; reconfig sem disable **não** muda; Download/Print/Copy offline
- [ ] Recovery DOC: SSH **authentication**; PAT classic **`repo`**; verified devices (cruzar inventário — blast radius)
- [ ] Sudo: 2 h; SMS não autentica; passkey/TOTP/Mobile/security key/senha; regenerar recovery codes exige sudo
- [ ] IR Preventing unauthorized: inventário SSH/deploy/OAuth/Apps + Security log + e-mails + webhooks + collaborators
- [ ] Nota `2026-09-26-07-…` · `github-auth-errors.md` §M · `github-scm.md`

## 6. Revogação / incidente

- [ ] Expirado/revogado/deletado **não restaura** — criar novo
- [ ] Expire/revoke de PAT/OAuth/App token pode gerar `oauth_authorization.destroy` no Security log (Token expiration NOTE; não só OAuth app)
- [ ] Deletar PAT que criou deploy key → deploy key também some (inventariar repos antes)
- [ ] Push de token válido a repo/gist público → revogação automática (docs)
- [ ] Unused classic/OAuth/PAT: revogação automática após **1 ano** sem uso
- [ ] OAuth excess: 11º token mesmo user/app/scope revoga outro; hourly create 10 → prompt (não loop)
- [ ] OAuth revoke-all perms → SSH/deploy keys da app somem (cruzar inventário)
- [ ] Org Restrict PAT / Revoke FG → SSH criada pelo PAT/token **não** some — apagar keys à parte (nota `2026-09-26-04-…`)
- [ ] Refresh morto (`bad_refresh_token`) → novo web/device flow; não milking refresh
- [ ] Suspeita: revogar UI → Sessions → confirmar Security log → só então limpar `gh auth`/caches
- [ ] Credential revocation API: `POST /credentials/revoke` **unauthenticated** (auth → 403); ≤1000 tokens; 60 req/h; `ghp_` / `github_pat_` / `gho_` / `ghu_` / `ghr_` — **não** `ghs_`
- [ ] **NOVO** Remediation plan DOC (*Keeping API credentials secure*): (1) gerar novo · (2) substituir em **todos** os stores · (3) deletar comprometido — nota `2026-09-26-08-…`
- [ ] Gaps FG reconfirmados inalterados (public/outside/multi-org/Packages/Checks/user Projects); cap **50** (~00:39)
- [ ] IR profunda (restricted account, 2FA lockout, Support policy): nota `2026-09-20-17-…` + `resposta-incidente.md` §13
- [ ] Bulk Credentials Danger zone: **Revoke all SSO** (enterprise — não apaga credenciais) / **Delete all** keys+tokens (**só EMU**) — irreversible; ≠ playbook Free/Pro — inventário manual (Revoking your credentials; nota `2026-09-26-05-…`)


## 7. Gaps FG — Checks ≠ Statuses / Packages (operacional)

- [ ] Checks **create/update** = **GitHub App** only; OAuth/user/classic = view; não mintar classic “por causa do gap Checks”
- [ ] Status CI simples: FG **Commit statuses** (`statuses`) → `POST .../statuses/{sha}`; classic `repo:status` se inevitável
- [ ] Packages: **classic** `read:packages` / `write:packages` / `delete:packages` — FG não autentica Packages (DOC)
- [ ] Packages + Actions: `GITHUB_TOKEN` + Manage Actions access antes de classic
- [ ] Template: evitar Models / Knowledge bases / Private registries / Artifact metadata / Code quality / API Insights / Campaigns sem intenção
- [ ] Nota `2026-09-26-09-…` · `github-auth-errors.md` §N

## 8. Push protection / MCP / remediação de leak

- [ ] Settings → Code security → **Push protection for yourself** = ON (default; públicos)
- [ ] Não embutir PAT/OAuth/refresh/SSH key em commits, UI, REST contents/blob, ou **ações MCP** em público
- [ ] Bloqueio push: remover secret (amend/rebase) antes de bypass; URL bypass = mesmo user; ≤3 h
- [ ] Leak público/gist → auto-revoke; mint novo; substituir **todos** stores (Actions/Codespaces/Bot inject); Security log
- [ ] Leak privado PAT → revogar → *Report leak* (preview) → Close as Revoked
- [ ] Ordem: revoke provider **antes** de reescrever histórico; apagar linha ≠ remediar
- [ ] Padrões com PP: PAT · OAuth · App install · Refresh · SSH key (`github_test_token` sem PP)
- [ ] Nota `2026-09-26-10-…` · `github-auth-errors.md` §O

## 9. `GITHUB_TOKEN` em Actions (antes de mintar PAT)

- [ ] Mesmo repo no CI → **`GITHUB_TOKEN`** + `permissions:` mínimo; não mintar classic/`repo` “porque o job falhou”
- [ ] Settings → Actions → General: Workflow permissions **restricted**; create/approve PRs **off** se não precisar
- [ ] Action pode ler `github.token` sem pass — sempre limitar `permissions`
- [ ] Expire: fim do job / hosted ≤6 h / self-hosted refresh ≤24 h
- [ ] Fork / Dependabot: assume read-only + sem secrets Actions; `pull_request_target` = write mesmo de fork público (cuidado)
- [ ] Cross-repo → App installation token; PAT em Actions secret = último recurso (stores separados — nota 29)
- [ ] `checks: write` no embutido OK; secret scanning alerts ≠ `security-events`
- [ ] Nota `2026-09-26-11-…` · `github-auth-errors.md` §P · `github-scm.md`

## 10. OIDC / cloud deploy (antes de mintar key)

- [ ] Cloud no CI → federated OIDC no provider **antes** de Actions secret com key long-lived
- [ ] `permissions: id-token: write` + action oficial; `id-token: write` ≠ write no GitHub
- [ ] Trust com `sub` pinado (preferir `environment:prod`) e ≥1 condição
- [ ] Repo pós-2026-07-15: conferir `sub` imutável `@ID`
- [ ] Dependabot registry: OIDC se couber; senão store Dependabot (não Actions)
- [ ] Nota `2026-09-26-12-…` · `github-auth-errors.md` §Q · `github-scm.md`

## 11. Environment secrets / protection (produção)

- [ ] Credencial de **prod** no CI → environment secret **atrás** de protection (não secret de repo “porque é privado”)
- [ ] Preferir OIDC (§10); se secret inevitável: `environment: production` + reviewers + Selected branches + deny admin bypass
- [ ] Free pessoal privado: environments **não** aplicam — não depender do gate
- [ ] Precedência: env > repo > org (mesmo nome)
- [ ] YAML só referencia env → nasce **sem** gate; admin configura depois
- [ ] Write no repo = lê secrets de repo (Secure use) — least privilege na *credencial* dentro do secret
- [ ] Self-hosted: env secrets ≠ isolamento
- [ ] Delete env = wipe; inventariar antes
- [ ] Nota `notes/2026-09-27-01-github-environment-secrets-protection-rules.md` · `github-auth-errors.md` §R · `github-scm.md`

## 12. Variables vs secrets + reusable inherit

- [ ] Nunca guardar PAT/key em Actions **Variables** (unmasked by default) — só Secrets
- [ ] Config não sensível → `vars`/`env`; credencial → Secrets (preferir environment §11)
- [ ] Reusable: `secrets:` nomeados; `secrets: inherit` só se precisar de **todos** (mesma org/enterprise)
- [ ] Env secrets não viajam no `workflow_call` — declarar `environment:` no job do reusable
- [ ] Cadeia nested: passar secrets hop a hop
- [ ] Sensitive gerado no job → `::add-mask::` antes de log
- [ ] Nota `notes/2026-09-27-02-github-actions-variables-vs-secrets-inherit.md` · `github-auth-errors.md` §S · `github-scm.md`

## 13. Script injection / pwn request / checkout (CI YAML)

- [ ] Nunca `${{ github.event.*.title|body|… }}` direto em `run:` — action `with:` ou `env:` + `"$VAR"`
- [ ] Branch name / email também untrusted (DOC Script injections)
- [ ] Preferir `pull_request` a `pull_request_target` quando não precisa de secrets em fork
- [ ] Proibido: PRT + checkout head + `npm`/`make`/build (pwn request = rouba secrets/`GITHUB_TOKEN`)
- [ ] `persist-credentials: false` se não precisa git auth no job
- [ ] Checkout v7: não setar `allow-unsafe-pr-checkout` sem inspeção-só documentada
- [ ] Pin actions em **SHA completo**; CODEOWNERS em workflows
- [ ] Público: revisar policy insights PRT antes do enforce **2026-11-02**
- [ ] Nota `notes/2026-09-27-03-github-actions-script-injection-pwn-request-checkout.md` · `github-auth-errors.md` §T · `github-scm.md`


## 14. Artifact attestations + compromised runners

- [ ] Release consumível → attest (`id-token`+`attestations`[+`packages`]; pin SHA em `actions/attest`)
- [ ] Verificar com `gh attestation verify` antes de confiar no binário/imagem
- [ ] L3: build em reusable + `--signer-workflow` na verify
- [ ] Workflow: **nunca** classic PAT / SSH pessoal; ordem `GITHUB_TOKEN` → deploy key → App → FG org
- [ ] Self-hosted: não em público; efêmero/JIT + groups; env secrets ≠ isolamento
- [ ] Compromisso do runner = assume secrets/`GITHUB_TOKEN` vazados → revoke/rotate (§6 / IR)
- [ ] Nota `notes/2026-09-27-04-github-actions-artifact-attestations-compromised-runners.md` · `github-auth-errors.md` §U · `github-scm.md`

## 15. Immutable releases + release attestations

- [ ] Repo/org com release binário: Enable release immutability **antes** do próximo publish (só futuros)
- [ ] Fluxo: draft → assets → publish (não editar assets pós-publish)
- [ ] Consumir: `gh release verify` / `verify-asset` + badge Immutable (CLI com esses subcomandos)
- [ ] Release attestation (auto) ≠ build provenance `actions/attest` — preferir **ambos**
- [ ] Política org via API = `admin:org` / Organization write — preferir UI; sem classic amplo
- [ ] CI publish: `GITHUB_TOKEN`; nunca classic/SSH pessoal
- [ ] Nota `notes/2026-09-27-05-github-immutable-releases-release-attestations.md` · `github-auth-errors.md` §V · `github-scm.md`

## 16. Dependabot malware + dependency review (credenciais)

- [ ] Ligar malware alerts / Dependabot / security configuration pela **UI** — sem classic PAT
- [ ] Malware alert → remover dep (não esperar patch/PR Dependabot)
- [ ] Registry privado homônimo: avaliar preset Dismiss package malware alerts com revisão de Closed
- [ ] `dependency-review-action`: só `contents: read`; pin SHA; sem `ghp_` no YAML
- [ ] Config-file externo privado → secret FG/App mínimo, não classic commitado
- [ ] CVE security updates: secrets no store **Dependabot** se o workflow for do Dependabot (§ secrets 2026-09-20-29)
- [ ] Nota `notes/2026-09-27-06-github-dependabot-malware-dependency-review.md` · `github-auth-errors.md` §W · `github-scm.md`

## 17. Dependabot security updates + grouped (credenciais)

- [ ] Ligar security updates (+ grouped) pela **UI** — sem classic PAT
- [ ] Packages GitHub: Manage Actions access Read — **remover** PAT de `registries:` no YAML
- [ ] Terceiros: secret no store **Dependabot** `${{secrets…}}` ou OIDC — nunca literal no git
- [ ] CI em PR Dependabot: secrets no store Dependabot; `GITHUB_TOKEN` read-only default
- [ ] Só CVE: `open-pull-requests-limit: 0` + `applies-to: security-updates`
- [ ] Malware ≠ security update — remover pacote (§16 / §W)
- [ ] Nota `notes/2026-09-27-07-github-dependabot-security-updates-grouped.md` · `github-auth-errors.md` §X · `github-scm.md`

## 18. Dependabot version updates + schedule (credenciais)

- [ ] Ligar version updates via **`dependabot.yml`** (ou Enable UI) — sem classic PAT
- [ ] Schedule: preferir `weekly` + timezone; cooldown default 3 d (só version)
- [ ] `open-pull-requests-limit: 0` = sem version (security continua) — decidir explícito
- [ ] Actions: bloco `github-actions` / `directory: "/"`
- [ ] Packages / registries: igual §17 (Manage Actions access / Dependabot secrets / OIDC)
- [ ] Fork: Enable UI além do YAML herdado
- [ ] Nota `notes/2026-09-27-08-github-dependabot-version-updates-schedule-hygiene.md` · `github-auth-errors.md` §Y · `github-scm.md`

## 19. Dependabot auto-triage + multi-ecosystem (credenciais)

- [ ] Ligar presets / custom rules pela **UI** Advanced Security — sem classic PAT
- [ ] Filtrar PRs CVE: security updates **off** + custom "open PR" — ou security **on** (§17) sem custom open-PR
- [ ] Preset malware dismiss: só com FP interno documentado; revisar Closed (§16)
- [ ] Multi-ecosystem: YAML `multi-ecosystem-groups` + `patterns`; schedule no group
- [ ] Registries / Packages: igual §17/§18 (Dependabot secrets / OIDC / Manage Actions access)
- [ ] Nota `notes/2026-09-27-09-github-dependabot-auto-triage-multi-ecosystem.md` · `github-auth-errors.md` §Z · `github-scm.md`

## 20. ARC / scale sets (credenciais)

- [ ] Org/repo self-hosted K8s: **GitHub App** + Secret K8s — sem classic no Helm CLI
- [ ] Enterprise runners: DOC exige classic — expiração curta + inventário (§5)
- [ ] FG só se App inviável: Administration / Self-hosted runners mínimos
- [ ] Nunca commit App `.pem` / PAT em `values.yaml` ou git
- [ ] Vault AKV: string `githubConfigSecret` + cert nos dois pods (controller+listener)
- [ ] Público: **não** ARC — hosted; privado: runner groups + NS isolados
- [ ] Compromisso runner/ARC: revoke App/PAT + rotate (§6 / §14 / IR)
- [ ] Nota `notes/2026-09-27-10-github-arc-scale-sets-auth-ops.md` · `github-auth-errors.md` §AA · `github-scm.md`

## 21. Dependabot org Global / self-hosted / grant privado / ruleset DR

- [ ] Global settings / runner type / private grant / auto-triage = **UI** — sem classic PAT
- [ ] Self-hosted Dependabot: label pronto antes do Enable; públicos = hosted; Linux+Docker
- [ ] Grant private repo = blast radius org inteira via Dependabot — decidir explícito
- [ ] Registries: Dependabot secrets / OIDC / Packages `GITHUB_TOKEN` — nunca classic no YAML
- [ ] Enforce DR: ruleset Require workflows + action pinada (§16 / §W)
- [ ] Monorepo: `group-by: dependency-name` (version, mesmo ecosystem)
- [ ] Infra ARC: label/group alinhados (§20 / §AA); compromisso → revoke
- [ ] Nota `notes/2026-09-27-11-github-dependabot-org-global-runner-private-access.md` · `github-auth-errors.md` §AB · `github-scm.md`

## 22. Security configurations + custom patterns (credenciais)

- [ ] Ligar SS / Dependabot / malware / PP em escala pela **UI** Configurations — sem classic PAT
- [ ] Custom patterns = Global settings UI; dry run antes de publish; PP custom só com SS-as-PP on
- [ ] Default só repos novos; transfer → attach manual; Enforce consciente
- [ ] REST: `write:org` classic se automação; enterprise-enforced ≠ FG/App (precisa `admin:enterprise`)
- [ ] Delete/detach mantém settings do repo; não confundir com revoke de PAT
- [ ] Cruzar §8/§O push protection · §16/§W malware · §21/§AB Global Dependabot
- [ ] Nota `notes/2026-09-27-12-github-security-configurations-custom-patterns.md` · `github-auth-errors.md` §AC · `github-scm.md`

## 23. Validity checks / config statuses / enforcement (credenciais)

- [ ] Partner validity / Extended metadata = **UI** Secret Protection ou security configuration — sem classic PAT
- [ ] GitHub token validity já default com SS; generic patterns sem validity
- [ ] `active` → remediar (§8/§O / IR); não mintar PAT para “só checar”
- [ ] Pós-Apply: filtrar `failed`/`removed`; Enforce para evitar override; REST 200 sob Enforce ≠ mudança
- [ ] Cruzar §22/§AC configs · §8/§O push protection · IR §13
- [ ] Nota `notes/2026-09-27-13-github-validity-checks-config-statuses-enforcement.md` · `github-auth-errors.md` §AD · `github-scm.md`

## 24. Secret scanning alert triage (REST / webhooks)

- [ ] Triage = **UI** primeiro — sem mintar classic só para listar alertas
- [ ] `active` / `public leak` → revoke/rotate antes de Close as; SS **não** auto-fecha
- [ ] Report leak (privado, PAT preview): rotacionar **antes** se downtime importa
- [ ] Automação: FG **Secret scanning alerts** (read/write); `hide_secret=true`; nunca logar campo `secret`
- [ ] Webhook `secret_scanning_alert` (+ location/scan) > poll; validar Signature-256; secret do hook em Secrets
- [ ] Cruzar §8/§O remediação · §23/§AD validity · IR §13
- [ ] Nota `notes/2026-09-27-14-github-secret-scanning-alert-triage-rest-webhooks.md` · `github-auth-errors.md` §AE · `github-scm.md`

## 25. CodeQL default setup / language matrix (credenciais)

- [ ] Ligar CodeQL = **UI** Default ou security configuration — sem mintar classic só para enable
- [ ] Automação enable: FG **Administration** (default-setup); multi-repo → App / config (§22/§AC)
- [ ] Triage/SARIF: FG **Code scanning alerts**; classic `security_events`/`repo` último
- [ ] REST languages enum **sem** `rust` — não inventar; UI/About listam Rust
- [ ] Runner self-hosted: label pronto (`code-scanning`); público preferir hosted (§14/§U)
- [ ] Compromisso token CodeQL automação → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §22/§AC configs · §20/§AA runners · §24/§AE SS triage (separar SS vs CodeQL)
- [ ] Nota `notes/2026-09-27-15-github-codeql-default-setup-language-matrix.md` · `github-auth-errors.md` §AF · `github-scm.md`

## 26. CodeQL advanced setup / custom queries (credenciais)

- [ ] Só advanced se default (§25) não cobrir; enable = **UI** commit workflow — sem mintar classic
- [ ] Packs/queries públicas: sem secret; privados: Actions secret → `external-repository-token` (FG Contents read)
- [ ] GHES registries: classic `read:packages` **só** esse path (gap FG Packages) + expiração curta
- [ ] Nunca PAT/`ghs_` no YAML do workflow CodeQL; preferir `GITHUB_TOKEN` / secrets tipados
- [ ] At-scale: App / script mínimo — não 1 classic multi-org
- [ ] Compromisso secret queries/packs → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §25/§AF default · §22/§AC configs · §20/§AA runners (Swift≠ARC)
- [ ] Nota `notes/2026-09-27-16-github-codeql-advanced-setup-custom-queries.md` · `github-auth-errors.md` §AG · `github-scm.md`

## 27. CodeQL compiled languages / build modes (credenciais)

- [ ] Escolher/trocar build-mode = **UI** default ou workflow advanced — sem mintar classic
- [ ] Private NuGet/Maven = org private registries + dependency caching — nunca PAT no YAML
- [ ] Packs/queries externos: igual §26 (`external-repository-token` FG Contents); GHES = classic `read:packages` só esse path
- [ ] Compromisso secret build/registry → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §25/§AF default · §26/§AG advanced · §20/§AA runners (Swift≠ARC) · §14/§U self-hosted
- [ ] Nota `notes/2026-09-27-17-github-codeql-compiled-languages-build-modes.md` · `github-auth-errors.md` §AH · `github-scm.md`

## 28. Code scanning alert triage + Autofix (credenciais)

- [ ] Triage / Autofix / dismiss = **UI** primeiro — sem mintar classic só para listar alertas
- [ ] Automação: FG **Code scanning alerts** (read/write); classic `security_events`/`repo` último
- [ ] Commit autofix via API = classic `repo`/`public_repo` — preferir UI Create PR with fix
- [ ] Agentic assign consome AI credits; Autofix clássico não exige Copilot sub nem credits
- [ ] Nunca PAT no YAML CodeQL para “gerar fix”; Autofix é produto Security UI/API
- [ ] Compromisso token triage/autofix → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §25/§AF default · §26/§AG advanced · §27/§AH build modes · §24/§AE SS (produto diferente)
- [ ] Nota `notes/2026-09-27-18-github-code-scanning-alert-triage-autofix.md` · `github-auth-errors.md` §AI · `github-scm.md`

## 29. Code scanning merge protection + delegated dismissal (credenciais)

- [ ] Ligar ruleset / Prevent = **UI** primeiro — sem mintar classic só para toggle
- [ ] Automação ruleset `code_scanning`: FG **Administration** / App; classic `repo` último
- [ ] Create dismissal request: FG **Code scanning alerts** + `create_request: true`
- [ ] Review dismissal REST: classic `security_events` + papel reviewer; preferir UI Requests
- [ ] Nunca PAT no YAML CodeQL para “abrir merge”; gate é ruleset Settings
- [ ] Compromisso token ruleset/dismissal → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §28/§AI triage · §25/§AF default · §22/§AC configs · §24/§AE SS (produto diferente)
- [ ] Nota `notes/2026-09-27-19-github-code-scanning-merge-protection-delegated-dismissal.md` · `github-auth-errors.md` §AJ · `github-scm.md`

## 30. SARIF upload / third-party CI (credenciais)

- [ ] Actions no repo: só `GITHUB_TOKEN` + `security-events: write` — sem mintar classic/FG
- [ ] CI externo: preferir **GitHub App**; FG **Code scanning alerts** write (1 repo, expiração curta); classic `security_events` último
- [ ] Secret store + `codeql github upload-results --github-auth-stdin` — não echo token
- [ ] Nunca PAT/`ghs_` no YAML do workflow de upload
- [ ] Default setup CodeQL: não forçar upload CodeQL externo (bloqueado) — third-party OK
- [ ] Compromisso token upload → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §28/§AI triage · §29/§AJ merge/delegated · §25/§AF default · §26/§AG advanced
- [ ] Nota `notes/2026-09-27-20-github-sarif-upload-third-party-ci.md` · `github-auth-errors.md` §AK · `github-scm.md`

## 31. Security campaigns + alert↔Issues (credenciais)

- [ ] Criar/editar/fechar campanha = **UI** (owner/security manager) — sem mintar classic/FG só para isso
- [ ] REST campanhas: classic/`OAuth` **`security_events`**; FG create = **Code scanning alerts** read nos repos incluídos; drafts fora da API
- [ ] Preferir App org-scoped para automação multi-campanha; classic `repo` amplo = último
- [ ] Link alert↔issue / campaign Automations issues = **UI** — sem token se UI basta
- [ ] Nunca classic long-lived “porque REST campaigns existe”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §AC configs · §AI triage/Autofix · §AJ merge/delegated · §AK SARIF · §AE SS
- [ ] Nota `notes/2026-09-27-21-github-security-campaigns-alert-tracking-issues.md` · `github-auth-errors.md` §AL · `github-scm.md`

## 32. Code Quality thresholds / tool status / coverage (credenciais)

- [ ] Enable Code Quality / Require code quality / Restrict coverage / Tool status = **UI** primeiro — sem mintar classic/FG só para isso
- [ ] Coverage upload: só `GITHUB_TOKEN` + `permissions.code-quality: write` — nunca PAT/`ghs_` no YAML
- [ ] Automação ruleset: FG **Administration** / App; classic `repo` último
- [ ] Nunca classic long-lived “porque REST rulesets existe”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §29/§AJ CS merge · §30/§AK SARIF · §28/§AI triage · §25/§AF CodeQL default
- [ ] Nota `notes/2026-09-27-22-github-code-quality-thresholds-tool-status-sarif.md` · `github-auth-errors.md` §AM · `github-scm.md`

## 33. Private vulnerability reporting / repository advisories (credenciais)

- [ ] Enable PVR / draft / triage / publish / credits = **UI** primeiro — sem mintar classic/FG só para isso
- [ ] Automação REST: FG **Repository security advisories** (read/write, 1 repo, expiração curta); classic `repository_advisories:read|write` ou `repo` último
- [ ] Preferir App org-scoped para list/create multi-repo; nunca classic long-lived “porque REST advisories existe”
- [ ] Org list advisories: owner/SM + scopes DOC; não usar token pessoal amplo de developer genérico
- [ ] Nunca PAT no chat/YAML para “abrir advisory”; publish/CVE = UI ou REST autenticado no secret store
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §AC configs · §AL campaigns/SM · §AM Code Quality · §W/§X Dependabot (pós-publish)
- [ ] Nota `notes/2026-09-27-23-github-private-vulnerability-reporting-repository-advisories.md` · `github-auth-errors.md` §AN · `github-scm.md`

## 34. Temporary private fork / writing advisories (credenciais)

- [ ] Start fork / Merge pull request(s) / Publish / Credits = **UI** (admin advisory) — sem mintar classic/FG só para isso
- [ ] Collaborator write = commits/PRs no fork via UI — sem token se UI basta
- [ ] Automação create+fork: FG **Repository security advisories** write (1 repo, expiração curta); `start_private_fork` / `POST …/forks`; classic `repository_advisories:write`/`repo` último
- [ ] Preferir App org-scoped multi-repo; nunca classic long-lived “porque REST forks existe”
- [ ] Nunca PAT no chat/YAML para “abrir private fork”; CI do fork **não** existe (integrations blocked)
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §33/§AN PVR/advisories · §AL campaigns/SM · Dependabot pós-publish
- [ ] Nota `notes/2026-09-27-24-github-advisory-private-fork-write-best-practices.md` · `github-auth-errors.md` §AO · `github-scm.md`

## 35. Edit/delete repository advisories + Improve global GAD (credenciais)

- [ ] Edit advisory / Suggest improvements / Support delete = **UI**/Support — sem mintar classic/FG só para isso
- [ ] Automação PATCH metadata: FG **Repository security advisories** write (1 repo, expiração curta); classic `repository_advisories:write`/`repo` último
- [ ] Preferir App org-scoped multi-repo; nunca classic long-lived “porque PATCH existe”
- [ ] Delete published → Support portal (**não** PAT)
- [ ] GAD community PR = conta pessoal contributor — **não** injetar PAT org Bruno em `advisory-database`
- [ ] Nunca PAT no chat/YAML para “corrigir GHSA” ou “apagar advisory”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §34/§AO private fork/write · §33/§AN PVR/advisories · Dependabot pós-publish
- [ ] Nota `notes/2026-09-28-01-github-edit-delete-advisory-global-gad.md` · `github-auth-errors.md` §AP · `github-scm.md`

## 36. Global advisories REST / Dependabot from GAD (credenciais)

- [ ] Browse GAD / search / Suggest improvements = **UI** — sem mintar classic/FG só para ler GHSA
- [ ] `GET /advisories` público: preferir UI ou unauth com respeito ao rate limit 60/h; auth só se automação contínua exigir
- [ ] Automação Dependabot alerts: FG **Dependabot alerts** (`vulnerability_alerts` read/write, 1 repo/org, expiração curta); classic `security_events`/`public_repo`/`repo` último
- [ ] Org-wide alerts: owner/SM + FG/App — não token pessoal amplo de developer
- [ ] Nunca confundir FG Repository security advisories com FG Dependabot alerts
- [ ] Nunca classic long-lived “porque GET /advisories ou /dependabot/alerts existe”
- [ ] Nunca PAT no chat/YAML para “listar GHSA” ou “dismiss alert”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §35/§AP edit-delete/Improve GAD · §33/§AN PVR · §W/§X/§Z Dependabot · §AB org Global
- [ ] Nota `notes/2026-09-28-02-github-global-advisories-rest-dependabot-from-gad.md` · `github-auth-errors.md` §AQ · `github-scm.md`

## 37. GraphQL GAD / Dependabot assign-agent (credenciais)

- [ ] Browse GAD = **UI** — sem mintar classic/FG só para GraphQL `securityAdvisories`
- [ ] GraphQL automação: App ou FG curto com permissões mínimas; classic long-lived **proibido** “porque GraphQL exige bearer”
- [ ] Unauth GraphQL/REST rate-limit → esperar / UI; não milking turns/cota
- [ ] Assign humano/team: UI write+; automação PATCH → FG **Dependabot alerts** write (`vulnerability_alerts`)
- [ ] Assign AI agent: só com autorização Bruno; bot login + opcional `agent_assignment`; App/FG write — classic último
- [ ] Nunca confundir FG Dependabot alerts com FG Repository security advisories
- [ ] Nunca PAT no chat/YAML para “assign agent” ou “query GraphQL GAD”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §36/§AQ REST+browse · §W/§X/§Z Dependabot · §AI agentic CS (eixo separado) · §AB org Global
- [ ] Nota `notes/2026-09-28-03-github-graphql-gad-dependabot-assign-agent.md` · `github-auth-errors.md` §AR · `github-scm.md`

## 38. Security overview / Dependabot webhooks (credenciais)

- [ ] Overview / Risk / Coverage / Dependabot dashboard / Assessments = **UI** — sem mintar classic/FG só para “ver posture”
- [ ] Stream IR Dependabot: webhook App com **Dependabot alerts** read — preferir a polling REST
- [ ] Automação list/dismiss/assign: FG **Dependabot alerts** read/write · App · classic `security_events`/`repo` último
- [ ] Nunca classic long-lived “porque security overview ou list alerts existe”
- [ ] Nunca PAT no chat/YAML para “export CSV overview” ou “subscribe webhook”
- [ ] Compliance estável → audit log (não dashboard); dashboard pode mudar no mesmo período
- [ ] Assignments: repo view (§37/§AR); org overview **não** lista assignees
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §37/§AR assign · §36/§AQ GAD · §W/§Z Dependabot · §AL campaigns · §AE SS webhooks
- [ ] Nota `notes/2026-09-28-04-github-security-overview-dependabot-webhooks.md` · `github-auth-errors.md` §AS · `github-scm.md`

## 39. GraphQL securityVulnerabilities / overview filters (credenciais)

- [ ] Browse/monitor pacote no GAD = **UI** `github.com/advisories` — sem mintar classic/FG só para GraphQL
- [ ] Automação package ranges: App ou FG curto em `POST /graphql` (`securityVulnerabilities`) — classic long-lived **proibido**
- [ ] Filtros Security overview / Dependabot dashboard = **UI** (Available filters) — sem token para “filtrar posture”
- [ ] Não confundir GraphQL GAD package-monitor com FG **Dependabot alerts** (alerts nos repos)
- [ ] Unauth GraphQL rate-limit → UI / esperar; não milking turns/cota
- [ ] Nunca PAT no chat/YAML para “monitorar lodash” ou “aplicar filtro overview”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §38/§AS overview/webhooks · §37/§AR GraphQL assign · §36/§AQ REST GAD · §W/§Z Dependabot
- [ ] Nota `notes/2026-09-28-05-github-securityvulnerabilities-package-monitor-overview-filters.md` · `github-auth-errors.md` §AT · `github-scm.md`

## 40. Secret scanning PP metrics / delegated bypass (credenciais)

- [ ] Insights Secret scanning / Detection “bypassed or blocked” = **UI** — sem mintar classic/FG só para posture
- [ ] Requests Push protection bypass = **UI first**; Approve só com autorização Bruno + plano revoke/rotate
- [ ] Automação list/review: App ou FG/custom role reviewer — classic `security_events` último
- [ ] Exempt actors = risco de leak; só migration/service bots confiáveis (DOC WARNING)
- [ ] Bypass aprovado sem revoke = leak aceito — cruzar §O remediação + §AE Close as Revoked
- [ ] CodeQL PR metrics / Prevention = **UI** — sem PAT para “benchmark Autofix”
- [ ] Compliance → audit log (não dashboard)
- [ ] Nunca PAT no chat/YAML para “ver métricas SS” ou “PATCH bypass”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §39/§AT filters · §38/§AS overview · §O PP · §AE SS triage · §AD validity
- [ ] Nota `notes/2026-09-28-06-github-secret-scanning-push-protection-metrics-delegated-bypass.md` · `github-auth-errors.md` §AU · `github-scm.md`


## 41. CodeQL PR metrics / Autofix MTTR / Prevention (credenciais)

- [ ] Insights CodeQL pull requests / Prevention / Export CSV = **UI** — sem mintar classic/FG só para posture/MTTR
- [ ] Métricas Autofix só onde Autofix enabled; agentic assign só com autorização Bruno + credits/policy
- [ ] Automação CS alerts (não métricas PR): App ou FG `code_scanning_alerts` — classic `security_events`/`repo` último
- [ ] Sem REST dedicado DOC para métricas PR — não inventar endpoint; CSV via UI
- [ ] Disable Autofix = policy (enterprise/org/repo); não precisa PAT
- [ ] Nunca PAT no chat/YAML para “ver MTTR Autofix” ou “baixar CSV CodeQL PR”
- [ ] Compliance → audit log (não dashboard)
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §40/§AU SS PP metrics · §38/§AS overview · §28/§AI Autofix triage · §AF–§AH CodeQL setup
- [ ] Nota `notes/2026-09-28-07-github-codeql-pr-metrics-autofix-mttr.md` · `github-auth-errors.md` §AV · `github-scm.md`


## 42. Production context / linked artifacts / custom props (credenciais)

- [ ] Filtros production context (`artifact-registry*`, `has:deployment`, `runtime-risk`) e `props.*` = **UI** — sem mintar classic/FG só para posture
- [ ] Upload metadata: App ou `GITHUB_TOKEN` + `permissions.artifact-metadata: write` — **não** PAT classic no YAML
- [ ] List records: App ou FG `artifact-metadata:read` curto — classic último
- [ ] MDC / JFrog / Dynatrace = integrações org (preview MDC) — conectar só com autorização Bruno
- [ ] Custom properties = org Settings UI / Apps com permissão custom properties — sem classic “para props”
- [ ] Nunca PAT no chat/YAML para “filtrar internet-exposed” ou “POST storage-record”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §41/§AV CodeQL PR · §40/§AU SS PP · §38/§AS overview · §39/§AT filters · §31/§AL campaigns · §14/§U attestations
- [ ] Nota `notes/2026-09-28-08-github-production-context-linked-artifacts-props-filters.md` · `github-auth-errors.md` §AW · `github-scm.md`


## 43. Rulesets deployable/deployed / remove artifacts status (credenciais)

- [ ] Search `deployable:true`/`deployed:true` e ruleset filter = **UI** — sem mintar classic/FG só para posture
- [ ] Automação rulesets: App ou FG Org Administration curto — classic `admin:org` último
- [ ] Popular/atualizar metadata: App ou `GITHUB_TOKEN` + `artifact-metadata: write` — **não** PAT no YAML
- [ ] “Remover” artifact: status `deleted`/`eol`/`decommissioned` via metadata write — sem DELETE de página
- [ ] `required_deployments` (environments) ≠ targeting `deployed:true` — não misturar na árvore
- [ ] Nunca PAT no chat/YAML para “proteger repos deployed” ou “POST /orgs/.../rulesets”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §42/§AW production context · §21/§AB rulesets Dependabot · §29/§AJ CS merge · §11/§R environments · §14/§U attestations
- [ ] Nota `notes/2026-09-28-09-github-rulesets-deployable-deployed-remove-artifacts.md` · `github-auth-errors.md` §AX · `github-scm.md`


## 44. Push rulesets / bypass actors / enforcement (credenciais)

- [ ] Criar/editar push ou branch ruleset + bypass list = **UI** — sem mintar classic/FG só para posture
- [ ] Automação mutate: App ou FG Repo/Org **Administration** curto — classic último
- [ ] Listar rulesets active / rules for branch: Metadata read ou UI — **não** Administration write
- [ ] Bypass: preferir App/team + PR only; DeployKey/`exempt` só com intenção (exempt = sem audit)
- [ ] Push bypass do root = fork network inteira — revisar root antes de liberar
- [ ] Nunca PAT no chat/YAML para “POST /rulesets” ou “adicionar bypass DeployKey”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §43/§AX deployable targeting · §29/§AJ CS merge · §21/§AB ruleset DR · §8/§O · §40/§AU SS PP (≠ push ruleset)
- [ ] Nota `notes/2026-09-28-10-github-push-rulesets-bypass-actors-enforcement.md` · `github-auth-errors.md` §AY · `github-scm.md`


## 45. Ruleset recipes / JSON import / Rule Insights (credenciais)

- [ ] Replicar ruleset = **UI Import** (recipe ou JSON) — sem mintar classic/FG só para posture
- [ ] Export JSON **não** traz bypass list — repor bypass após import (App/team; evitar DeployKey always)
- [ ] Recipe com `OrganizationAdmin` / metadata pattern → só org/Enterprise adequado
- [ ] Enterprise: Evaluate → Insights → Active; free: review Disabled → Active cauteloso
- [ ] Auditar bypassers: Insights / org Dashboard CSV — UI
- [ ] Automação suites: App ou FG Admin read (repo) / Org Admin write (org) — classic último
- [ ] Automação create/update: App ou FG Admin write — classic último
- [ ] Nunca PAT no chat/YAML para “importar recipe” ou “GET rule-suites”
- [ ] Compromisso → revoke + rotate (§6 / IR §13)
- [ ] Cruzar §44/§AY push+bypass · §43/§AX deployable · §29/§AJ CS merge · §40/§AU SS PP delegated (≠ push)
- [ ] Nota `notes/2026-09-28-11-github-ruleset-recipes-json-import-rule-insights.md` · `github-auth-errors.md` §AZ · `github-scm.md`

## Baseline 2026-10-05
- Ver `notes/2026-10-05-github-seguranca-baseline.md` (estado pós-limpeza; zero PATs; política sem PAT clássico no box).

- Baseline viva: `baseline/github-baseline-20261005.md` (2FA ON ~11:40; alertar desvio).
