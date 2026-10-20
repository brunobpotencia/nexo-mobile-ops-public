# Checklist — GitHub auth errors (401 / 403 / 404 / 429) + secret injection

**Nota:** `notes/<nota>.md` · `notes/<nota>.md` · `notes/<nota>.md` · `notes/<nota>.md` · `notes/<nota>.md` · `notes/<nota>.md` · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`** · **`notes/<nota>.md`**  
**Lab / postmortem:** `nexo/ops/AAAA-MM-DD-github-auth-lab.md`, `nexo/ops/AAAA-MM-DD-postmortem-por-que-travou.md`  
**Higiene geral SCM:** `checklists/github-scm.md` · extract `github-credenciais-higiene.md`

Citações oficiais (acesso **AAAA-MM-DD** ~01:37):  
[Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) · [Org PAT policy](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization) · [Reviewing/revoking FG in org](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/reviewing-and-revoking-personal-access-tokens-in-your-organization) · [Privileged OAuth apps](https://docs.github.com/en/apps/oauth-apps/using-oauth-apps/privileged-oauth-apps) · [Token expiration](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation) · [Authorizing OAuth apps](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps) · [Authenticating to REST](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api) · [Rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api) · [Troubleshooting REST](https://docs.github.com/en/rest/using-the-rest-api/troubleshooting-the-rest-api)

Itens marcados **LAB** = observação Nexo/Guard na box; não são doc oficial.

> **AAAA-MM-DD (estado atual, fonte Nexo):** PATs classic/FG da conta = 0 (revogados); `GITHUB_TOKEN`/`GH_TOKEN`/`GITHUB_PERSONAL_ACCESS_TOKEN` removidos do `box-secrets.json`; 2FA ON. Os passos **LAB** abaixo que mandam usar/sobrescrever `GITHUB_PERSONAL_ACCESS_TOKEN` com classic `ghp_` são registro de AAAA-MM-DD — **não** reintroduzir PAT sem OK explícito do dono. Baseline: `<BASELINE_LOCAL>`.

## Árvore de decisão (operacional — AAAA-MM-DD)

1. **Canal?** Um só: MCP OAuth **ou** PAT env. Se xai sem a tool → não injeta PAT “pra criar tool” (**LAB**).
1b. **Instrumento certo?** Script/teste pessoal → FG PAT; automação long-lived / multi-repo / org → **GitHub App** (não classic `repo` eterno). Cap 50 FG → App. Nota `<nota>`.
2. **Probe** `GET /user` (Bearer via env, sem echo):
   - **401** → credencial morta; fingerprint prefix+len; **2º idêntico → STOP**.
   - **200** → ir à ação alvo.
   - **403** rate / **429** → esperar `retry-after` / reset; **sem** force_reauth.
   - **403** pós vários 401 → failed-login lockout possível; esperar.
3. **Ação** (ex. create-repo):
   - **403** “not accessible by PAT” → perms; FG precisa **Administration write**; classic `public_repo`/`repo`; ler `X-Accepted-GitHub-Permissions`.
   - **404** em recurso “existente” → auth/scopes/owner (máscara).
4. **Secret-request:** só nomes em `CLOUD_AGENT_INJECTED_SECRET_NAMES` (observado: `GITHUB_PERSONAL_ACCESS_TOKEN`); processo Shell **novo**; nunca unset sticky.
5. **Pós-incidente:** Security log 90d + inventário Developer settings + Applications (§G).

---

## A. Antes de pedir token / reauth

- [ ] **LAB:** `echo "$CLOUD_AGENT_INJECTED_SECRET_NAMES"` — só pedir/usar nomes que já injetam (observado: `GITHUB_PERSONAL_ACCESS_TOKEN`, `EXA_API_KEY`)
- [ ] Escolher **um** canal: MCP OAuth **ou** PAT no env — não os dois ao mesmo tempo (**LAB** / postmortem)
- [ ] Se MCP xai **não** tem a tool (ex. `create_repository`), não esperar que PAT no env “crie” a tool (**LAB**)
- [ ] Não abrir Settings / `force_reauth` em loop se o último sintoma foi **429** ou HTML estranho no OAuth (**LAB**)

---

## B. Diagnosticar 401 vs 403 vs 404 vs 429

Probe: `GET https://api.github.com/user` (Bearer via env; **não** imprimir o token). Depois a ação alvo.

- [ ] **401 Unauthorized** → credencial inválida (ausente, malformada, expirada, revogada). Docs: *Authenticating to the REST API*. **Ação:** parar; não reenviar o mesmo valor. Registrar só prefix + len (**LAB** fingerprint).
- [ ] **403** + corpo “Resource not accessible by personal access token” / “by integration” → token **autenticou**, falta permissão/scope. Checar `X-Accepted-GitHub-Permissions`. Docs: *Troubleshooting the REST API*.
- [ ] **403** + `x-ratelimit-remaining: 0` **ou** mensagem de secondary rate limit → rate limit (primary/secondary). Docs: *Rate limits*; *Troubleshooting*. **Ação:** respeitar `retry-after` / `x-ratelimit-reset`; senão ≥1 min + backoff; não continuar batendo.
- [ ] **403** logo após vários **401** → possível *failed login limit* (API rejeita até tokens válidos temporariamente). Docs: *Authenticating to the REST API* — Failed login limit. **Ação:** esperar; não insistir.
- [ ] **404** em recurso que “existe” na UI → tipicamente auth/scopes/resource owner (GitHub mascara privados) ou URL/método errado. Docs: *Troubleshooting* — 404 Not Found for an existing resource.
- [ ] **429 Too Many Requests** → rate limit. Mesma disciplina de backoff que 403 de rate limit. Docs: *Rate limits*; *Troubleshooting*. **LAB:** OAuth MCP oficial após force_reauth chegou a 429 — esperar, não reauth em loop.
- [ ] **LAB:** 2º **401** com mesmo prefix+len → **STOP**; mudar estratégia (postmortem). Não milking o usuário.

### Tabela rápida

| Código | Leitura | Próximo passo |
|---|---|---|
| 401 | Bad credentials | Novo token / canal; não loop |
| 403 (perms) | Escopo/permission | Ajustar PAT ou usar classic `repo` se gap FG |
| 403/429 (rate) | Primary/secondary limit | Esperar headers; sem force_reauth |
| 404 | Privado sem auth adequada / typo | Revisar auth + URL |

---

## C. Classic `ghp_` vs fine-grained `github_pat_`

- [ ] Preferir **fine-grained** (`github_pat_`) quando o fluxo couber; classic (`ghp_`) só se gap oficial (Packages, Checks, multi-org, outside collaborator, write em público alheio, etc.). Docs: *Managing PATs*.
- [ ] Inventário: Developer settings → Fine-grained **e** Tokens (classic); apagar órfãos / classic `repo` amplo / sem expiração.
- [ ] Fine-grained: um resource owner; **Only select repositories**; permissões mínimas; expiração 30–90 d; cap 50 tokens. Docs: *Managing PATs*.
- [ ] Classic inevitável: scope mínimo; lembrar blast radius em **todos** os repos acessíveis. Docs: *Managing PATs*.
- [ ] Create repo (`POST /user/repos`): classic precisa `public_repo` ou `repo`. Docs: *Create a repository for the authenticated user*. Fine-grained: **Administration write** (`POST /user/repos` na tabela *Permissions required for fine-grained PATs* — reconfirmado AAAA-MM-DD; docs também agrupa sob heading “Repository creation”). Confirmar falha via `X-Accepted-GitHub-Permissions`. **LAB:** sem Administration → 403; token morto → 401 (não confundir). Nota `<nota>`.
- [ ] Expirado/revogado/deletado **não restaura** — criar novo. Docs: *Token expiration and revocation*.
- [ ] Prefixos `ghp_` / `github_pat_` / `gho_` / `ghu_` / `ghs_` / `ghr_` = segredo. Docs: *About authentication* — token formats.
- [ ] **LAB (desbloqueio):** se FG no env está 401, sobrescrever **`GITHUB_PERSONAL_ACCESS_TOKEN`** com classic `ghp_` válido (único nome observado que injeta) **ou** esperar 429 e reauth MCP oficial — um caminho.

---

## D. Bot secret-request (Grok) — higiene

- [ ] **LAB:** Usar name **`GITHUB_PERSONAL_ACCESS_TOKEN`** (não `GH_TOKEN` / `GITHUB_TOKEN` — UI pode dizer “provided” e **não** injetar)
- [ ] Antes/depois: conferir `CLOUD_AGENT_INJECTED_SECRET_NAMES` contém o name esperado
- [ ] **Nunca** ecoar o token (chat, `echo`, log, commit, gist)
- [ ] Validar em **processo Shell novo** após inject (não reutilizar sessão onde houve `unset`)
- [ ] **LAB:** Não `unset GITHUB_TOKEN` (sticky shell — unset persiste e pode esconder re-injeção)
- [ ] Validar com probe `/user` sem imprimir valor; se 401 com mesmo len+prefix → stop
- [ ] Hipótese truncamento FG len=93 / mapeamento de names → **NÃO VALIDADO**; tratar só como hipótese (nota §5)

---

## E. OAuth MCP vs PAT (anti-loop)

- [ ] **DOC:** OAuth app ≤**10** tokens por combinação user / application / **mesmo scope**; o 11º **revoga** um existente (unused >1 min → LRU → oldest). *Token expiration* — excess of tokens. Nota `<nota>`
- [ ] **DOC:** criar **>10 tokens/h** (mesmo user/app/scope) **não** revoga oldest — dispara **re-authorization prompt** no browser (break de loop). Esperar ≥1 h; inventariar Authorized OAuth apps
- [ ] **DOC:** tokens expiráveis — access **8 h**; refresh `ghr_` **6 meses sem uso**; refresh invalida o par antigo; opt-in runtime scope **`offline_access`**. *Authorizing OAuth apps*. Nota `<nota>`
- [ ] **DOC:** device flow (CLI/GCM): poll sem `client_secret`; códigos **900 s**; respeitar `interval` / `slow_down` (+5 s); ≤**50** user-code submits/h/app. Nota `<nota>`
- [ ] **DOC WARNING:** revogar **todas** as permissões de uma OAuth app **apaga** SSH keys geradas pela app, **incluindo deploy keys** — inventariar SSH/Deploy keys antes. Nota `<nota>`
- [ ] **LAB:** force_reauth só se conector `needsAuth` **e** sem 429 recente **e** sem rajada de creates OAuth; nunca em loop
- [ ] Se OAuth devolver HTML anômalo (“What‽”) → não martelar Settings; esperar e retry limpo (**LAB**)
- [ ] Continuating requests sob rate limit pode piorar (docs: banimento de integração possível). *Rate limits* / *Troubleshooting*
- [ ] Bloqueado >15 min no mesmo eixo → postmortem + plano B (PAT env **ou** OAuth — um canal); parar de pedir ação ao usuário (**LAB** / postmortem)

---

## F. Após suspeita de vazamento / token ruim

- [ ] Revogar na UI (Developer settings) e/ou credential revocation API para prefixos suportados. Docs: *Token expiration and revocation*
- [ ] Confirmar Security log (`oauth_authorization.destroy` / eventos de PAT)
- [ ] Substituir usos → só então limpar caches locais/`gh auth`

---

## G. Security log após PAT / OAuth / SSH (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Reviewing your security log](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/reviewing-your-security-log) · [Security log events](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/security-log-events) · [Authorized OAuth apps](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/reviewing-your-authorized-applications-oauth) (acesso **AAAA-MM-DD**)

- [ ] Settings → Archives → **Security log** (90 d) — não é full-text; usar qualificadores / export JSON|CSV
- [ ] Filtrar FG PAT: `action:personal_access_token.create` / `.update` / `.credential_regenerated` / `.destroy` / `.credential_revoked` / `.access_revoked`
- [ ] Filtrar OAuth: `action:oauth_authorization.create|destroy` e `action:oauth_access.create|destroy|revoke`
- [ ] Expire/revoke de **PAT** (além de OAuth/App) pode gerar `oauth_authorization.destroy` — cruzar com `personal_access_token.*` (Token expiration NOTE; nota `<nota>`)
- [ ] Filtrar SSH/deploy/signing: `action:public_key.create|delete` e `action:git_signing_ssh_public_key.create|delete`
- [ ] Filtrar conta: `action:user.failed_login`, `user.sign_in_from_unrecognized_device`, `passkey.*`, `two_factor_authentication.*`
- [ ] Cruzar log com UI: Fine-grained **e** classic; SSH and GPG keys; Applications → Authorized OAuth/GitHub Apps
- [ ] Evento não reconhecido → revogar na UI → confirmar `*.destroy` / `access_revoked` no log → só então limpar `gh auth`/caches
- [ ] `personal_access_token.credential_revoked` → tratar como vazamento (GHAS/secret scanning) até prova contrária
- [ ] Push protection usuário: Settings → Code security → “Push protection for yourself” ligado

## H. GitHub App vs PAT (escalar automação — AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Deciding when to build a GitHub App](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/deciding-when-to-build-a-github-app) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) · [Best practices for creating a GitHub App](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/best-practices-for-creating-a-github-app) (acesso **AAAA-MM-DD**)

- [ ] Teste / script curto / uso pessoal → fine-grained PAT (não classic)
- [ ] Long-lived / org / multi-repo / bot persistente → **GitHub App** (installation token short-lived)
- [ ] CI no mesmo repo → `GITHUB_TOKEN` mínimo; cross-repo no Actions → App installation token
- [ ] Cap **50** FG atingido ou quase → planejar App (não acumular órfãos)
- [ ] App **nunca** autentica com PAT/senha do user (best practices)
- [ ] Não “consertar” gap de tool MCP com classic `repo` amplo (**LAB** + WARNING Managing PATs)

## I. Installation / Actions `ghs_` formato stateless (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [About authentication — token formats](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github) · [Changelog AAAA-MM-DD](https://github.blog/changelog/AAAA-MM-DD-notice-about-upcoming-new-format-for-github-app-installation-tokens/) · [Override header AAAA-MM-DD](https://github.blog/changelog/AAAA-MM-DD-github-app-installation-tokens-per-request-override-header/) (acesso **AAAA-MM-DD**)

- [ ] Tratar `ghs_` / `GITHUB_TOKEN` como **opaco** — sem length==40; sem regex `ghs_[A-Za-z0-9]{36}`
- [ ] Aceitar formato novo `ghs_APPID_JWT` (~520 chars, **dois** dots) e o opaco antigo (sem dots)
- [ ] Storage/coluna ≥520 chars se persistir installation token (preferir não persistir — expira ~1 h)
- [ ] Teste App: header temporário `X-GitHub-Stateless-S2S-Token: enabled|disabled` em `POST .../access_tokens`; remover após validar
- [ ] Fingerprint LAB por length: **não** aplicar a `ghs_` (length varia); OK em `ghp_` / `github_pat_`
- [ ] Extract higiene consolidado: `checklists/github-credenciais-higiene.md`

## J. Org PAT policy / privileged OAuth / SSH que sobrevive (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Org PAT policy](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization) · [Reviewing/revoking FG in org](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/reviewing-and-revoking-personal-access-tokens-in-your-organization) · [Privileged OAuth apps](https://docs.github.com/en/apps/oauth-apps/using-oauth-apps/privileged-oauth-apps) · [SSO authorize PAT](https://docs.github.com/en/authentication/authenticating-with-saml-single-sign-on/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on) (acesso **AAAA-MM-DD** ~15:40)

- [ ] **403** em org com PAT 200 em `/user` → checar Restrict policy · max lifetime · FG `pending` · SSO Configure/Authorize · linked identity
- [ ] Org **Restrict** PAT: SSH keys **criadas por PATs continuam**; públicos da org ainda acessíveis
- [ ] Org **Revoke** FG: SSH do token **continua**; token ainda lê públicos; UI Active tokens = **só FG** (classic fora)
- [ ] Não assumir que Restrict/Revoke FG apaga deploy/SSH — inventariar e Delete keys
- [ ] Privileged OAuth (GCM / CLI / Desktop / Copilot CLI / VS Code / …): podem furar restrict OAuth da org; auto-incluídas podem faltar em Authorized OAuth — cruzar Security log
- [ ] Classic **não** passa por approval FG; Restrict classic é o controle correspondente
- [ ] `copilot_requests` em template FG = billing/overage — só com pedido explícito

## K. PAT CLI HTTPS / username / FG RO públicos / inactive (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) · [Token expiration](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation) · [Revoking your credentials](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/revoking-your-credentials) (acesso **AAAA-MM-DD** ~16:38)

- [ ] Git HTTPS: Password = PAT; **username não autentica** (vazio → inválido)
- [ ] PAT **não** autentica remote SSH — trocar para HTTPS ou usar SSH key
- [ ] Sem prompt → cache (Keychain/helper); limpar **após** confirmar Security log na rotação
- [ ] FG “Only select” **ainda** tem RO a **todos** os públicos no GitHub
- [ ] Token inactive se user **perde acesso** ao resource owner (member/collab)
- [ ] Classic sem scopes = só info pública (ainda inventariar)
- [ ] Danger zone Delete all = **só EMU**; Revoke all SSO ≠ apagar tokens

## L. GCM / credential cache + SSO SSH revoke + FG Agent (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Caching credentials](https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git) · [SSO authorize PAT](https://docs.github.com/en/authentication/authenticating-with-saml-single-sign-on/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on) · [SSO authorize SSH](https://docs.github.com/en/authentication/authenticating-with-saml-single-sign-on/authorizing-an-ssh-key-for-use-with-saml-single-sign-on) · [Permissions FG](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens) (acesso **AAAA-MM-DD** ~17:45)

- [ ] Git diário: **`gh auth login`** (HTTPS + autenticar Git **Y**) ou **GCM** antes de mintar PAT — GCM cobre OAuth/2FA
- [ ] Git HTTPS 401 com PAT API OK → cache stale: Windows Credential Manager (apagar GitHub); macOS Keychain; Linux store GCM; limpar **após** Security log
- [ ] Git for Windows **≥2.29**; legado “GCM for Windows” não conecta OAuth
- [ ] EMU: se re-prompt eterno → `git config --global credential.gitHubAccountFiltering "false"`
- [ ] SSO classic: Configure SSO pós-create; regenerar/editar scopes classic → **re-Authorize**
- [ ] Linked identity: só PAT/SSH autorizados na org — mesmo sem SSO enforced
- [ ] SSO SSH: org **revoga** authorize → **não** reusa a mesma key — criar key **nova**; certs do CA da org sem authorize
- [ ] Enterprise `internal` + IP allow list: cruzar SSO auth + IP allowed
- [ ] FG: não mintar **Agent secrets/variables**, Attestations write, Copilot Spaces/agent settings sem intenção (Permissions FG)
- [ ] Gaps FG reconfirmados inalterados; cap 50

## M. Passkeys / 2FA checkup / sudo / recovery (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [About passkeys](https://docs.github.com/en/authentication/authenticating-with-a-passkey/about-passkeys) · [Managing passkeys](https://docs.github.com/en/authentication/authenticating-with-a-passkey/managing-your-passkeys) · [Signing in with a passkey](https://docs.github.com/en/authentication/authenticating-with-a-passkey/signing-in-with-a-passkey) · [Configuring 2FA](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication) · [Changing 2FA method](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/changing-your-two-factor-authentication-method) · [2FA recovery methods](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication-recovery-methods) · [Sudo mode](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/sudo-mode) · [Preventing unauthorized access](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/preventing-unauthorized-access) · [About authentication](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github) (acesso **AAAA-MM-DD** ~18:38)

- [ ] Passkey cobre **password + 2FA**; security key WebAuthn sem UV = **só 2º fator** (com senha) — não confundir
- [ ] Add passkey exige TOTP **ou** SMS já configurado
- [ ] Synced (label UI) vs device-bound: se só device-bound → ≥**2** devices; FIDO2 hardware = tipicamente device-bound
- [ ] Upgrade security key → passkey; falha OS/browser → remove + re-register
- [ ] Login: `https://github.com/login?passkey=true` (nearby = QR/push)
- [ ] Pós-enable 2FA: **checkup 28 d** — realizar 2FA; dia 28 sem sucesso → reconfigurar via atalho
- [ ] Mudar/Add 2FA **sem** Disable: mantém recovery codes + membership orgs 2FA; só apagar TOTP antigo no app **após** Save
- [ ] Generate new recovery codes **invalida** anteriores; reconfig sem disable **não** muda codes
- [ ] Recovery DOC além dos codes: SSH tipo **authentication**; PAT classic scope **`repo`**; verified devices
- [ ] Sudo: timeout **2 h** (ação sensível reinicia); SMS **não** autentica (só SMS → senha); passkey/TOTP/Mobile/security key OK
- [ ] IR com login: senha → 2FA/passkey → SSH/deploy/OAuth/Apps → Security log → e-mails → webhooks → deploy keys → commits → collaborators
- [ ] Conta restricted: senha + hygiene + e-mail GitHub + Support se persistir
- [ ] Cookies: `gist.github.com` ≠ `github.com`; sessão ~2 semanas inatividade
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~21:47 nota `<nota>`)

## N. Gaps FG — Checks ≠ Statuses / Packages classic (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) · [Permissions FG](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens) · [Checks runs](https://docs.github.com/en/rest/checks/runs) · [Commit statuses](https://docs.github.com/en/rest/commits/statuses) · [Packages permissions](https://docs.github.com/en/packages/learn-github-packages/about-permissions-for-github-packages) · [Keeping API credentials](https://docs.github.com/en/rest/authentication/keeping-your-api-credentials-secure) (acesso **AAAA-MM-DD** ~20:46)

- [ ] Gaps FG **inalterados**: público alheio · outside collab · multi-org · Packages · Checks API · Projects de **user**; cap **50**
- [ ] **Checks write** (`POST/PATCH .../check-runs`) = **só GitHub App** — OAuth/user/classic **não criam**; classic/OAuth **lêem**
- [ ] Anti-padrão: gap “Checks” ≠ “mintar classic” — classic **também não escreve** Checks
- [ ] CI status simples com FG: permission **Commit statuses** (`statuses`) → `POST /repos/.../statuses/{sha}` (não check-runs)
- [ ] Classic fino para statuses: scope `repo:status` (sem código) vs `repo`
- [ ] **Packages**: DOC = auth só PAT **classic** (`read/write/delete:packages`); FG não cobre
- [ ] Packages em Actions: preferir **`GITHUB_TOKEN`** + *Manage Actions access*; classic só cross-repo inevitável
- [ ] Multi-org / bot long-lived: **GitHub App**, não classic “porque FG não dá”
- [ ] Template FG: não mintar sem intenção `user_models`/`organization_models`, `knowledge_bases`, `organization_private_registries`, `artifact_metadata`, `code_quality`, `organization_api_insights`, `organization_campaigns` (+ Agent/Copilot já §L)
- [ ] 403 em check-runs com PAT → instrumento errado (App), não “falta Administration”

## O. Push protection (users / MCP / REST) + remediação de leak (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Push protection](https://docs.github.com/en/code-security/concepts/secret-security/push-protection) · [Manage user push protection](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/prevent-future-leaks/manage-user-push-protection) · [PP CLI](https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection/working-with-push-protection-from-the-command-line) · [PP UI](https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection/working-with-push-protection-in-the-github-ui) · [PP REST](https://docs.github.com/en/code-security/concepts/secret-security/push-protection-from-the-rest-api) · [PP MCP](https://docs.github.com/en/code-security/concepts/secret-security/push-protection-and-the-github-mcp-server) · [Scan MCP](https://docs.github.com/en/code-security/how-tos/use-ghas-with-ai-coding-agents/scan-for-secrets-with-github-mcp-server) · [Patterns](https://docs.github.com/en/code-security/reference/secret-security/supported-secret-scanning-patterns) · [Remediate leaked secret](https://docs.github.com/en/code-security/tutorials/remediate-leaked-secrets/remediating-a-leaked-secret) · [Token expiration](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation) · [Resolving alerts](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-secret-scanning-alerts/resolving-alerts) (acesso **AAAA-MM-DD** ~21:47)

- [ ] Confirmar **Push protection for yourself** ON (Settings → Code security) — default ON; cobre push a **públicos**
- [ ] Repo PP ≠ user PP: repo exige **Secret Protection**; gera alertas em bypass; user PP **não** gera alerta sozinho
- [ ] Superfícies: CLI · UI commit · file upload (preview) · REST blob/contents (**409**) · **GitHub MCP** (público; privado com GHAS)
- [ ] Bloqueio CLI: remover secret (amend se HEAD; rebase -i se histórico) **antes** de bypass; URL de bypass = **mesmo user** (outro = 404); re-push ≤**3 h**
- [ ] Público sem secret scanning: user PP ainda bloqueia; bypass **sem** motivo / **sem** alerta
- [ ] REST 409: tirar secret do body **ou** create push protection bypass (API) — só se falso positivo
- [ ] MCP: não embutir `ghp_`/`github_pat_`/`gho_`/`ghu_`/`ghr_` em issues/PRs/files; PP bloqueia responses + actions
- [ ] Scan MCP (`secret_protection` + `run_secret_scanning`): findings **efêmeros**; precisa Secret Protection; remoto MCP only
- [ ] Padrões GitHub com PP: App install · OAuth · **PAT** · Refresh · SSH private key; **`github_test_token` sem PP**
- [ ] Leak público/gist: auto-revoke de PAT/OAuth/App token **válido** — tratar como morto; mint novo; limpar **todos** os stores
- [ ] Leak privado PAT: revogar/rotacionar → *Report leak* no alerta (preview; PAT only) → fechar alerta manual (*Revoked*)
- [ ] Ordem irrenunciável: **revogar provider** → rotacionar stores → auditar → (opcional) limpar histórico; apagar linha ≠ remediar
- [ ] Alerta secret scanning **não** fecha sozinho ao remover do tree — Close as manual
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~21:47)

## P. `GITHUB_TOKEN` Actions — permissões / forks / anti-PAT (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token) · [Use GITHUB_TOKEN](https://docs.github.com/en/actions/security-guides/automatic-token-authentication) · [Workflow syntax `permissions`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) · [Actions settings (repo)](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD** ~22:44)

- [ ] CI no **mesmo** repo: preferir **`GITHUB_TOKEN`** + `permissions:` mínimo — **antes** de mintar PAT (Managing PATs)
- [ ] Tratar como installation token App: escopo = **só** o repo do workflow; também em `github.token` (action pode ler sem pass)
- [ ] Expire: fim do job; hosted ≤**6 h**; self-hosted refresh ≤**24 h** (job >24 h → App/PAT)
- [ ] Repo Settings → Actions → General → Workflow permissions = **restricted** (contents+packages read) em conta pessoal
- [ ] “Allow GitHub Actions to create and approve pull requests” = OFF salvo necessidade
- [ ] YAML: listar escopos → não listados = `none`; evitar `write-all`
- [ ] Fork PR (≠ `pull_request_target`): writes → read salvo *Send write tokens…*; secrets de fork = opt-in perigoso
- [ ] **`pull_request_target`**: token **read/write** mesmo de fork público — não checkout untrusted com esse privilégio
- [ ] Dependabot PR: read-only + sem secrets Actions (store Dependabot — nota 29)
- [ ] Eventos do `GITHUB_TOKEN` não re-disparam workflows (exceto dispatch + PR open/sync/reopen → approval-required)
- [ ] Cross-repo / bot: **GitHub App** installation token no workflow; PAT secret = último recurso
- [ ] `checks: write` no token embutido OK (é App); gap FG Checks ≠ mintar classic (§N)
- [ ] Secret scanning alerts ≠ `security-events` do `GITHUB_TOKEN` (App/PAT)
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~22:44; reconfirm ~23:40 nota `<nota>`)

## Q. OIDC / `id-token` — cloud sem PAT long-lived (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [About OIDC](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect) · [Configuring OIDC](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers) · [OIDC reference](https://docs.github.com/en/actions/reference/openid-connect-reference) · [Reusable workflows + OIDC](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/using-openid-connect-with-reusable-workflows) · [Environments](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) · well-known `https://token.actions.githubusercontent.com/.well-known/openid-configuration` (acesso **AAAA-MM-DD** ~23:40)

- [ ] Deploy cloud no CI: **OIDC** antes de mintar AWS/GCP/Azure/Vault key como Actions secret (Managing PATs + About OIDC)
- [ ] YAML: `permissions: id-token: write` (obrigatório) — **não** concede write em recursos GitHub; só JWT OIDC
- [ ] Preferir action oficial do cloud; senão `core.getIDToken([aud])` / `ACTIONS_ID_TOKEN_REQUEST_*`
- [ ] Issuer: `https://token.actions.githubusercontent.com` (JWKS `…/.well-known/jwks`)
- [ ] Cloud trust: ≥**1** condição (`sub`/`aud`/claims) — sem condição = qualquer repo pode pedir token
- [ ] `sub` default: `environment:` > `pull_request` > `ref:refs/heads|tags/…`; `:` → `%3A`
- [ ] Repos criados após **AAAA-MM-DD** (ou opt-in): `sub` **imutável** `repo:OWNER@ID/REPO@ID:…` — atualizar trust; não GHES
- [ ] Produção: job com `environment:` + protection (reviewers / branches / wait); Free pessoal = environments só em **público**
- [ ] Env criado só pelo YAML nasce **sem** rules — só admin configura
- [ ] Dependabot OIDC: `event_name=dynamic`; registries CodeArtifact / Azure Artifacts / JFrog
- [ ] Reusable deploy: pin cloud em `job_workflow_ref`; caller externo precisa `id-token: write` explícito
- [ ] Debug claims: `github/actions-oidc-debugger` antes de ligar o provider
- [ ] Árvore: mesmo-repo GitHub → `GITHUB_TOKEN` (§P) · cross-repo → App · **cloud → OIDC** · PAT/key = último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~23:40)

## R. Environment secrets / protection rules (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Managing environments](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment) · [Deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments) · [Secrets reference](https://docs.github.com/en/actions/reference/security/secrets) · [Control deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments) · [Secure use](https://docs.github.com/en/actions/reference/security/secure-use) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD** ~00:39)

- [ ] Secret de **produção** → store **environment** (não só repo): write no repo = lê secrets de repo (Secure use)
- [ ] Precedência mesmo nome: **environment > repository > organization** (Secrets reference)
- [ ] Timing: org/repo lidos no **queue**; environment secrets quando o job com `environment:` **starts** (pós-rules)
- [ ] Protection: required reviewers (≤6; 1 basta; Prevent self-review) · wait 1–43200 min · Selected branches/tags · deny admin bypass · custom App (≤6 enabled)
- [ ] Waiting reviewers: até **30 d** → falha automática
- [ ] Free pessoal: environments / env secrets / reviewers / wait / custom = só repo **público**; privado Free **ignora** rules+secrets
- [ ] Pro/Team: deployment branches/tags + env vars também em **privado**; reviewers/wait/custom/admin-bypass config ainda só público em Free/Pro/Team (DOC notes)
- [ ] YAML cria env inexistente **sem** rules/secrets — só admin configura; inventariar após merge
- [ ] Delete environment → wipe secrets+rules; jobs waiting falham
- [ ] Self-hosted: environment **não** isola — mesmo rigor que repo/org secrets
- [ ] `deployment: false`: secrets+reviewers+wait OK; **sem** deployment history; custom App rules → job falha
- [ ] Protected branches only: sem rules no repo → todas branches; tags homônimas / forks matching **não** deployam
- [ ] Limites: 1000 org / 100 repo / 100 env · 48 KB; >100 org assigned → só primeiros 100 alfabéticos no workflow
- [ ] Árvore: OIDC (§Q) → environment secret gated → PAT/key último; stores Actions≠Codespaces≠Dependabot
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~00:39; reconfirm ~01:37 nota `<nota>`); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64

## S. Actions variables vs secrets + reusable `secrets: inherit` (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Variables](https://docs.github.com/en/actions/concepts/workflows-and-actions/variables) · [Use variables](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-variables) · [Variables reference](https://docs.github.com/en/actions/reference/variables-reference) · [Secrets](https://docs.github.com/en/actions/concepts/security/secrets) · [Secrets reference](https://docs.github.com/en/actions/reference/security/secrets) · [Secure use](https://docs.github.com/en/actions/reference/security/secure-use) · [Reuse workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows) · [Reusing workflow configurations](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD** ~01:37)

- [ ] Config **não sensível** → Variables/`env`; PAT/key/webhook → **Secrets** (Variables = unmasked by default — WARNING DOC)
- [ ] Nunca colocar `ghp_`/`github_pat_`/`gho_`/`cloud key` em Settings → Variables
- [ ] Precedência vars: environment > repository > organization; env vars só no runner **após** start do job
- [ ] Limites vars: org 1000 / repo 500 / env 100 · 48 KB; org+repo ≤256 KB/run (env fora do cap)
- [ ] Org Free: org-level variables **e** secrets inacessíveis a private repos Free
- [ ] Valor sensível gerado no job → `::add-mask::` antes de log; sem JSON/XML como secret único
- [ ] Reusable: preferir `secrets:` **nomeados**; `secrets: inherit` = todos os secrets do caller (só mesma org/enterprise)
- [ ] Cadeia A→B→C: secrets só no hop direto — inherit A→B não entrega tudo a C
- [ ] Environment secrets **não** passam via `workflow_call`; job do reusable com `environment:` usa env secret local
- [ ] `env` do caller **não** propaga; usar `vars` ou `with:` inputs; vars = do **caller** repo
- [ ] Called: `GITHUB_TOKEN` do caller; permissions só downgrade; pin SHA em reusable externo
- [ ] Nesting ≤10; `cache-mode` do caller limita o called
- [ ] Árvore: vars (config) → `GITHUB_TOKEN` (§P) → OIDC (§Q) → env secret (§R) → PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~01:37); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 = agressivas Guard, sem flag API)

## T. Script injection / pwn request / checkout credentials (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Script injections](https://docs.github.com/en/actions/concepts/security/script-injections) · [Secure use](https://docs.github.com/en/actions/reference/security/secure-use) · [Securely using pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target) · [actions/checkout README](https://github.com/actions/checkout/blob/main/README.md) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD** ~02:46)

- [ ] Nunca interpolar `github.event.*.title|body|message|…` (nem branch/email) direto em `run:` `${{ }}` — shell injection → vazamento de secrets/`GITHUB_TOKEN`
- [ ] Preferir action JS com `with:` **ou** `env: VAR: ${{ … }}` + `"$VAR"` no script
- [ ] Contextos tipicamente untrusted (DOC): terminam em `body` / `default_branch` / `email` / `head_ref` / `label` / `message` / `name` / `page_name` / `ref` / `title`
- [ ] Evitar `pull_request_target` se `pull_request` basta (fork = RO token, sem secrets)
- [ ] **Pwn request:** PRT + `ref:` head/merge do PR (ou `repository:` fork / `git fetch` / artifact) + build/test = código do fork com secrets da base
- [ ] `workflow_run` / `issue_comment` com secrets: artifacts e código de fork = untrusted data
- [ ] Público sem event policy própria: default policy bloqueia PRT — hoje **evaluate**; **enforce AAAA-MM-DD** (private/internal fora)
- [ ] Se PRT inevitável: least privilege token/secrets · cache PRT read-only (não forçar write `cache-mode`) · self-hosted efêmero · CodeQL Actions
- [ ] Checkout: `persist-credentials: false` se o job não precisa git autenticado (default true; v6 guarda em `$RUNNER_TEMP`)
- [ ] Checkout **v7**: bloqueia fork PR em PRT/`workflow_run` por default; `allow-unsafe-pr-checkout: true` só inspeção-só (não cobre fetch/gh/artifact)
- [ ] Actions de terceiros: pin **full-length SHA**; CODEOWNERS em `.github/workflows`
- [ ] Árvore: vars (§S) → `GITHUB_TOKEN` (§P) → OIDC (§Q) → env secret (§R) → YAML hardened (§T) → PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~02:46); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard)


## U. Artifact attestations + compromised runners (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations) · [Using artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations) · [SLSA L3 / reusable](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/increase-security-rating) · [Manage attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/manage-attestations) · [Compromised runners](https://docs.github.com/en/actions/concepts/security/compromised-runners) · [Secure use](https://docs.github.com/en/actions/reference/security/secure-use) · [Self-hosted runners](https://docs.github.com/en/actions/reference/runners/self-hosted-runners) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD** ~03:43)

- [ ] Release / binário / package consumível → gerar **artifact attestation** (`actions/attest` + `id-token: write` + `attestations: write`; imagem + `packages: write`)
- [ ] Não assinar builds só de teste / source / docs (DOC When to generate)
- [ ] Attestation sozinha = SLSA **L2**; L3 = attest + **reusable workflow** (perms no caller **e** called)
- [ ] Público = Sigstore Public Good + transparency log; privado = Sigstore GitHub **sem** log público
- [ ] Verificar: `gh attestation verify` (`-R` / `oci://` / `--predicate-type` SBOM / `--signer-workflow` L3)
- [ ] Delete attestation = consumidores com verify **param** de aceitar o artefato — baixar cópia antes
- [ ] Pin `actions/attest` em **SHA completo** (Secure use)
- [ ] Runner comprometido: secrets **referenciados** + `GITHUB_TOKEN` colhem-se; redação de log ≠ boundary; exfil em frações de segundo
- [ ] Cross-repo (ordem DOC): `GITHUB_TOKEN` → deploy key → App → FG PAT conta **org**; **nunca** classic PAT / SSH pessoal no workflow
- [ ] Self-hosted em **público** ≈ proibido; privado ainda arriscado se há fork+PR; environment **não** isola
- [ ] Self-hosted: preferir **efêmero/JIT** + runner groups; destroy-after-job em persistente é insuficiente (`ps` cross-job)
- [ ] Hosted: sem scan de libs baixadas no job — pin actions / least privilege igual
- [ ] Árvore: vars (§S) → `GITHUB_TOKEN` (§P) → OIDC (§Q) → env secret (§R) → YAML (§T) → **attest** → runner hardening → PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~03:43); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`)

## V. Immutable releases + release attestations (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) · [Prevent release changes](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/establish-provenance-and-integrity/prevent-release-changes) · [Verify release integrity](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/verify-release-integrity) · [Using artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations) · [REST Releases](https://docs.github.com/en/rest/releases/releases) · [REST Orgs immutable-releases](https://docs.github.com/en/rest/orgs/orgs) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD** ~04:41)

- [ ] Repo com release consumível → Settings → Releases → **Enable release immutability** (só **futuros**)
- [ ] Org: Settings → Repository → General → Releases → All / Selected / none (só futuros)
- [ ] Publish: **draft → anexar assets → publish** (após publish, assets/tag travam)
- [ ] Travado: tag (não move/apaga enquanto release existe) + assets (não mod/delete); título/notes/pre-release/latest **editáveis**
- [ ] Apagar release imutável → pode apagar tag, **não reusa** o nome; resurrection do repo **não** reusa tags imutáveis
- [ ] Immutable publish gera **release attestation** automática (tag + commit SHA + assets) ≠ artifact attestation / SLSA (`actions/attest`, §U)
- [ ] Consumir: `gh release verify TAG` · `gh release verify-asset TAG PATH` · UI badge **Immutable**
- [ ] `verify-asset` **não** cobre source zip/tarball sob demanda (NOTE DOC)
- [ ] Org API: `GET/PUT /orgs/{org}/settings/immutable-releases` (`enforced_repositories` all|none|selected); classic `admin:org`; FG Organization read/write — preferir UI a mintar classic
- [ ] REST release object: campo `immutable` (boolean)
- [ ] Publicar no CI: `GITHUB_TOKEN` Contents write — **nunca** classic PAT (§P/§U)
- [ ] **LAB:** `gh` 2.46.0 box sem `release verify` / `attestation` — upgrade CLI antes de verificar na box
- [ ] Árvore: vars (§S) → `GITHUB_TOKEN` (§P) → OIDC (§Q) → env (§R) → YAML (§T) → attest build (§U) → **immutable release** → PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~04:41); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`)

## W. Dependabot malware alerts + dependency review (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Malware alerts](https://docs.github.com/en/code-security/concepts/supply-chain-security/malware-alerts) · [Configure malware alerts](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-malware-alerts) · [Manage malware alerts](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-dependabot-alerts/manage-malware-alerts) · [Auto-triage rules](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-auto-triage-rules) · [Advisory Database](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/github-advisory-database) · [Dependabot alerts](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-dependabot-alerts) · [Dependency review](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-dependency-review) · [Configure dependency-review-action](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configure-dependency-review-action) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD** ~05:45)

- [ ] CVE Dependabot alerts ≠ malware alerts (toggle separado; UI Dependabot → **Malware**)
- [ ] Enable: Dependabot alerts **primeiro**, depois malware alerts (Settings → Advanced Security) — **UI, sem PAT**
- [ ] Org/Enterprise: custom **security configuration** (escala)
- [ ] Malware = npm security + OpenSSF malicious-packages (`type:malware`); ecossistemas: Composer/Go/Maven/npm/NuGet/pip/RubyGems/Rust
- [ ] Remediation malware: **remover** pacote / substituto — **sem** fix version segura (DOC Advisory DB)
- [ ] Dependabot **não** abre PR automático para malware alerts (só CVE)
- [ ] FP possível: pacote interno com mesmo nome/ecosystem/versão que público malicioso
- [ ] Preset **Dismiss package malware alerts** (default **off**): mitiga FP; **IMPORTANT** — também dismissa malware real all-versions
- [ ] Auto-triage aplica **antes** de notifications; `resolution:auto-dismiss` auditável
- [ ] Actions: malware/CVE alerts só para actions em **semver** (não SHA) — pin SHA no CI continua obrigatório (§T)
- [ ] Dependency review: pega vuln **no PR** (pré-merge); Dependabot: default branch (pós)
- [ ] `dependency-review-action`: `permissions: contents: read`; pin **SHA**; `fail-on-severity` / licenses / `allow-ghsas` / `fail-on-scopes`
- [ ] Config externo privado: **não** commit `ghp_` — FG/App Contents read via secret; preferir config no mesmo repo
- [ ] Privado: action exige Code Security / Advanced Security; org enforce via ruleset required workflow
- [ ] Submission + review API: mesmo workflow ou `retry-on-snapshot-warnings` (anti-race)
- [ ] Árvore: UI malware/DR → `GITHUB_TOKEN` read (§P) → OIDC (§Q) → env (§R) → YAML (§T) → attest/immutable (§U/§V) → PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~05:45); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`)

## X. Dependabot security updates + grouped PRs (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Security updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-security-updates) · [Configure security updates](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-security-updates) · [Private registries](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configure-access-to-private-registries) · [Dependabot on Actions](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-on-actions) · [Dependabot errors](https://docs.github.com/en/code-security/reference/supply-chain-security/troubleshoot-dependabot/dependabot-errors) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD** ~06:43)

- [ ] Security updates ≠ version updates ≠ malware alerts ≠ dependency review
- [ ] Enable ordem: dependency graph → Dependabot alerts → **security updates** (UI Advanced Security) — **sem PAT**
- [ ] Grouped: toggle repo/org **depois** de security updates **ou** `groups` + `applies-to: security-updates` no YAML
- [ ] 1ª vez grouped: Dependabot pode fechar PRs antigos e abrir agrupados
- [ ] Groups: por ecosystem; **não** misturar security×version; sem `applies-to` = só version; YAML override UI
- [ ] Só CVE (sem version noise): `open-pull-requests-limit: 0`; YAML precisa `directory`/`directories` e **sem** `target-branch`
- [ ] Filtrar quais CVEs viram PR: security updates **off** + auto-triage rule
- [ ] npm pode bump parent/transitiva; outros ecossistemas **não** se exigir parent
- [ ] GitHub Packages: **Manage Actions access** Read + `GITHUB_TOKEN` — **sem** PAT no `dependabot.yml`
- [ ] Registry terceiro: `${{secrets.NAME}}` no store **Dependabot** (não Actions) **ou** OIDC (CodeArtifact/Azure/Cloudsmith/GCP/JFrog)
- [ ] Nomes secret Dependabot: `[A-Z0-9_]`; sem `GITHUB_`; sem dígito inicial
- [ ] Workflow `dependabot[bot]`: `GITHUB_TOKEN` read-only; Actions secrets **indisponíveis** → duplicar no store Dependabot
- [ ] PRT + base Dependabot: token read-only **e** secrets off — cruzar §T
- [ ] `insecure-external-code-execution: allow` só se tooling exigir; escopo = registries do bloco updates
- [ ] Árvore: UI security/grouped → Packages `GITHUB_TOKEN` → Dependabot secrets/OIDC → CI store Dependabot → malware §W → PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~06:43); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`)

## Y. Dependabot version updates + schedule/cooldown (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Version updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates) · [Configure version updates](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-version-updates) · [Options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) · [Optimizing PR creation](https://docs.github.com/en/code-security/tutorials/secure-your-dependencies/optimizing-pr-creation-version-updates) · [Auto-update Actions](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/auto-update-actions) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD** ~07:47)

- [ ] Version updates ≠ security updates (§X) ≠ malware (§W) — version = `dependabot.yml` (ou Enable UI que cria o arquivo)
- [ ] Obrigatório por ecosystem: `package-ecosystem` + `directory`/`directories` + `schedule.interval`
- [ ] Fork: YAML sozinho **não** liga — Enable explícito no fork
- [ ] `schedule.interval`: daily (seg–sex) · weekly · monthly · quarterly · semiannually · yearly · cron (+ `cronjob`)
- [ ] Higiene: preferir `weekly` + `day`/`time`/`timezone` a `daily` contínuo; default sem `time` = horário aleatório
- [ ] Cooldown default **3 d** só version (não security); custom 1–90 d; `exclude` > `include`
- [ ] `open-pull-requests-limit` default **5** (version); **0** = desliga version; security **fora** do contador / sem esse teto
- [ ] Groups sem `applies-to` = só version; um group ≠ version+security
- [ ] Actions: `package-ecosystem: github-actions` + `directory: "/"` (workflows + action.yml + reusable)
- [ ] `target-branch` → opções do bloco só version; security sempre default branch
- [ ] Packages: Manage Actions access + `GITHUB_TOKEN`; terceiros: store Dependabot / OIDC — **nunca** classic no YAML
- [ ] CI `dependabot[bot]`: secrets no store Dependabot; cruzar §X/§P/§T
- [ ] Árvore: só CVE → §X `limit: 0` · version → YAML schedule/cooldown/groups · Actions → bloco github-actions · PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~07:47); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`)

## Z. Dependabot auto-triage + multi-ecosystem updates (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Auto-triage rules](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-auto-triage-rules) · [Preset rules](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/prioritize-with-preset-rules) · [Customizing auto-triage](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/auto-triage-dependabot-alerts) · [Managing auto-dismissed](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-dependabot-alerts/managing-automatically-dismissed-alerts) · [CWE criteria](https://docs.github.com/en/code-security/reference/supply-chain-security/criteria-for-preset-rules) · [Multi-ecosystem](https://docs.github.com/en/code-security/concepts/supply-chain-security/multi-ecosystem-updates) · [Configuring multi-ecosystem](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configuring-multi-ecosystem-updates) · [Options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD** ~08:44)

- [ ] Auto-triage = UI Advanced Security → Dependabot rules — **sem PAT**; CRUD de rules não é REST Dependabot alerts/secrets
- [ ] Preset **low-impact npm dev**: default on público; private = Enable UI; CWEs GitHub-curated (criteria-for-preset-rules)
- [ ] Preset **Dismiss package malware alerts**: default **off**; IMPORTANT — dismissa também malware real all-versions (§W)
- [ ] Custom: público ou org+Code Security; preview ≤**10**/repo; metadata CVE/CWE/scope/ecosystem/GHSA/path/package/patch/severity/EPSS
- [ ] Org rule **enforced** > repo; dismissal **antes** de open-PR rules
- [ ] "Open a pull request" **só** com security updates UI **off**; malware **nunca** via essa action
- [ ] Security updates UI **on** = PR em todo CVE patchável — custom open-PR não filtra (§X)
- [ ] Auto-dismiss: `resolution:auto-dismiss`; filtrar Closed as Auto-dismissed; pode auto-reabrir se metadata mudar
- [ ] Multi-ecosystem ≠ `groups` single-ecosystem ≠ grouped security (security **não** cross-ecosystem)
- [ ] `multi-ecosystem-groups` + schedule; cada ecosystem: `multi-ecosystem-group` + **`patterns`** (ou `["*"]`)
- [ ] Merge: assignees/labels additive; milestone/commit-message/target-branch/pull-request-branch-name = **só** no group
- [ ] Verify: Insights → Dependency graph → Dependabot; registries = store Dependabot/OIDC — nunca classic no YAML
- [ ] Árvore: presets UI → custom dismiss/open-PR → security §X → version §Y → multi-ecosystem YAML → PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~08:44); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 API 403 unauth (CDN ainda 0.107.79)

## AA. Actions Runner Controller / scale sets auth + ops (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [About ARC](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller) · [Authenticate ARC](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/authenticating-to-the-github-api) · [Deploy scale sets](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/deploying-runner-scale-sets-with-actions-runner-controller) · [Use in workflow](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/using-actions-runner-controller-runners-in-a-workflow) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~09:43**)

- [ ] ARC = K8s operator + **ephemeral** scale sets (JIT); charts OCI `gha-runner-scale-set-controller` + `gha-runner-scale-set`
- [ ] Auth ordem: **GitHub App** (org/repo) → FG mínimo → classic último; **enterprise** = classic só (App não autentica)
- [ ] App perms: repo Administration RW + Metadata RO; org Self-hosted runners RW; Homepage `actions/actions-runner-controller`
- [ ] FG: repo Administration RW; org Administration R + Self-hosted runners RW
- [ ] Classic: repo → `repo`; org → `admin:org`
- [ ] Secret: K8s Secret + `githubConfigSecret: name` — **não** PAT/App key plain text no CLI/values commitado
- [ ] Vault preview (≥0.12.0): Azure Key Vault JSON (`github_token` ou trio App) + cert `.pfx` no controller e listener
- [ ] Namespaces: runners ≠ operator; preferir NS por org/group/scale set
- [ ] Isolamento: cluster dedicado a Actions (workflow = código arbitrário); coletar logs controller/listener/runners
- [ ] `runnerGroup` + groups GitHub = boundary; `maxRunners`/`minRunners`; `0`/`0` = drain
- [ ] `runs-on`: INSTALLATION_NAME / `runnerScaleSetName` ou `runnerScaleSetLabels` array
- [ ] DinD = privileged; k8s mode: **não** setar `ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER=false` sem revisar (API secrets)
- [ ] Público + self-hosted ≈ proibido — cruzar §U; preferir hosted
- [ ] Compromisso: revoke App/PAT + rotate secrets + IR §13 / higiene §6
- [ ] Upgrade: uninstall scale sets → ARC → CRDs se mudaram → reinstall (Helm não upgrade CRDs)
- [ ] Árvore: App Secret → FG → classic enterprise → hosted se público → PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~09:43); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 API 403 unauth (CDN ainda 0.107.79)

## AB. Dependabot org Global (runner type / private access) + ruleset DR + group-by (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Global security settings](https://docs.github.com/en/code-security/securing-your-organization/enabling-security-features-in-your-organization/configuring-global-security-settings-for-your-organization) · [Dependabot on self-hosted](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configure-on-self-hosted-runners) · [Dependabot on Actions](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-on-actions) · [Enforce dependency review](https://docs.github.com/en/code-security/how-tos/secure-at-scale/configure-organization-security/configure-specific-tools/enforce-dependency-review) · [Options reference group-by](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~10:38**)

- [ ] Org Global Dependabot = UI Advanced Security → Global settings — **sem PAT** (auto-triage §Z · grouped security §X · Actions runners · runner type · private grant)
- [ ] Default runner = **Standard GitHub** (hosted); Labeled = self-hosted/larger com label (default `dependabot`) + group opcional
- [ ] **Público** → sempre hosted, mesmo com labeled runners (NOTE DOC); labeled **não** serve público
- [ ] Antes de Enable self-hosted Dependabot: runners **já** com o label — senão jobs **queued indefinitely**
- [ ] Disable/re-enable self-hosted **não** dispara novo run Dependabot
- [ ] Self-hosted req: Linux **x64** + Docker; outbound `dependabot-actions.githubapp.com`; limitar rede interna; certs Node.js p/ self-signed
- [ ] Grant private repo mesma org: aceitar blast — **todos users da org** acessam conteúdo via Dependabot updates
- [ ] Registry privado ≠ grant GitHub: `registries:` + store Dependabot / OIDC — nunca classic no YAML
- [ ] Enforce DR org: Rulesets → branch ruleset Active → **Require workflows to pass** → workflow DR pinado (§W)
- [ ] Monorepo: `groups.*.group-by: dependency-name` = 1 PR/dep across dirs; mesmo ecosystem; **só version**; constraints incompatíveis → PRs separados
- [ ] Cruzar ARC §AA se label/scale set for a infra; compromisso self-hosted → revoke + §U/IR
- [ ] Árvore: UI Global → hosted default → labeled só private+rede → grant consciente → ruleset DR → group-by monorepo → PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~10:38); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 API **404** (DELTA vs 403; CDN ainda 0.107.79)

## AC. Security configurations at scale + secret scanning custom patterns (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Enabling security features at scale](https://docs.github.com/en/code-security/concepts/security-at-scale/organization-security) · [Creating a custom security configuration](https://docs.github.com/en/code-security/how-tos/secure-at-scale/configure-organization-security/establish-complete-coverage/create-custom-configuration) · [Defining custom patterns](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/customize-leak-detection/define-custom-patterns) · [REST Configurations](https://docs.github.com/en/rest/code-security/configurations) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~11:44**)

- [ ] Configurations = enablement **repo-level** em escala; Global settings = **org-level** (custom patterns) — UI Advanced Security — **sem PAT** no dia a dia
- [ ] Secret Protection / Code Security em private = paid; toggles enable/disable/keep existing
- [ ] Default config: só repos **novos**; transferidos → attach **manual**
- [ ] Enforce: bloqueia override do repo admin nas features **set**; `not_set` não enforced
- [ ] Custom pattern: SS/Secret Protection **já** on → Global Custom patterns → dry run (org: all ou ≤10 selected) → publish → PP opcional
- [ ] PP custom só onde SS as push protection já on; patterns comuns com PP = disruptive (§O)
- [ ] REST org: list `read:org`; mutate/attach/default `write:org` (admin ou security manager)
- [ ] Enterprise-enforced attach/default/detach ativo: classic + `admin:enterprise`; **FG PAT e GitHub App tokens NÃO** suportados (DOC REST)
- [ ] Delete/detach config: settings do repo **permanecem**; some associação
- [ ] Attach `scope`: all / all_without_configurations / public / private_or_internal / selected; GHAS license short → só free features
- [ ] Árvore: UI config+Global → dry-run pattern → PP consciente → REST só se automação → classic `write:org` → enterprise classic+admin → PAT último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~11:44); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (releases/tags 403 rate; CDN ainda 0.107.79)

## AD. Validity checks (partner) + configuration statuses / enforcement (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Validity checks](https://docs.github.com/en/code-security/concepts/secret-security/validity-checks) · [Enable validity checks](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/customize-leak-detection/enable-validity-checks) · [Evaluating alerts](https://docs.github.com/en/code-security/tutorials/remediate-leaked-secrets/evaluating-alerts) · [Supported patterns](https://docs.github.com/en/code-security/reference/secret-security/supported-secret-scanning-patterns) · [Apply configuration](https://docs.github.com/en/code-security/how-tos/secure-at-scale/configure-organization-security/establish-complete-coverage/apply-custom-configuration) · [Configuration statuses](https://docs.github.com/en/code-security/reference/security-at-scale/configuration-statuses) · [Diagnosing issues](https://docs.github.com/en/code-security/reference/security-at-scale/troubleshoot-security-configurations/configuration-issue-diagnosis) · [Enforcement](https://docs.github.com/en/code-security/reference/security-at-scale/configuration-enforcement) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~12:39**)

- [ ] GitHub token validity = **default** com secret scanning; partner validity = Team/Enterprise + **Secret Protection** (org-owned) — UI ou security configuration — **sem PAT**
- [ ] Generic patterns: validity **não** suportada; Extended metadata só com validity on (preview; provedores limitados)
- [ ] Status alert: `active` priorizar · `inactive` auditar abuso prévio · `unknown` = sem check ou falha
- [ ] On-demand: **Verify secret** no alert (partner validity on)
- [ ] Labels: `public leak` · `multi-repo` — cruzar §O remediação
- [ ] Apply config: aba Repositories; default só **novos**; transfer = manual; active **e** archived
- [ ] Statuses: `attached`/`enforced` OK · `attaching`/`updating` esperar · `failed` → `config-status:failed` + remediação · `removed` → re-apply (+ Enforce) · `removed_by_enterprise` → enterprise · `detached` = No configuration (UI não filtra; REST aceita)
- [ ] `failed`: só parte dos settings; **não** herda updates futuros até fix
- [ ] Enforce break (code scanning): Actions disabled depois · actions required ausentes · languages default setup mudadas
- [ ] REST sob Enforce: pode “suceder” sem mudar enablement — reler GET/UI; não milking PAT
- [ ] Audit: `action:repository_security_configuration`
- [ ] Árvore: UI validity/config → statuses → Enforce consciente → REST configs §AC → classic último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~12:39); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (CDN ainda 0.107.79)

## AE. Secret scanning alert triage — REST / webhooks / monitor (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Resolving alerts](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-secret-scanning-alerts/resolving-alerts) · [Evaluating alerts](https://docs.github.com/en/code-security/tutorials/remediate-leaked-secrets/evaluating-alerts) · [Monitoring alerts](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-secret-scanning-alerts/monitoring-alerts) · [REST secret scanning](https://docs.github.com/en/rest/secret-scanning/secret-scanning) · [Auditing security alerts](https://docs.github.com/en/code-security/concepts/security-at-scale/audit-security-alerts) · [Webhooks secret_scanning_alert](https://docs.github.com/en/webhooks/webhook-events-and-payloads#secret_scanning_alert) · [FG Secret scanning alerts](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens#repository-permissions-for-secret-scanning-alerts) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~13:39**)

- [ ] Avaliar: `active` priorizar · `inactive` auditar prévio · `unknown` = possivelmente ativo; labels `public leak` / `multi-repo`; Verify secret se partner validity (§AD)
- [ ] Ordem: **revogar/rotacionar** → atualizar stores → (privado PAT) Report leak preview **após** rotate se downtime · **Close as** manual — SS **não** auto-fecha ao apagar do tree (§O)
- [ ] Close as / PATCH `resolution`: `false_positive` · `wont_fix` · `revoked` · `used_in_tests` (+ comment timeline)
- [ ] Ruleset “SS resolved”: após Close as, merge pode esperar scan do head commit
- [ ] Dia a dia = **UI** — sem classic só para triage
- [ ] REST automação: FG **Secret scanning alerts** read/write; classic `security_events`/`repo` (público: `public_repo`); org list = admin **ou** security manager
- [ ] Filtros: `validity` · `is_bypassed` · `is_publicly_leaked` · `is_multi_repo` · `hide_secret=true` (API devolve `secret` plaintext — **não logar**)
- [ ] PATCH: `state`+`resolution`; assignee write no repo; 403 = delegated dismissal; 422 = mismatch
- [ ] Webhook `secret_scanning_alert`: `created`/`resolved`/`reopened`/`validated`/`publicly_leaked`/`assigned`/`unassigned`/`metadata_*` + `secret_scanning_alert_location` + `secret_scanning_scan`; filtrar `push_protection_bypassed`
- [ ] Notificações: incremental (author **sempre**) vs historical (owners sempre no fim; admins só se hit; **sem** author)
- [ ] Audit: timeline + audit log (SS create/resolve/reopen/PP bypass; code scanning **sem** audit timeline) + API snapshot + webhooks stream
- [ ] Árvore: UI evaluate→revoke→Close as → webhook IR → REST FG SS alerts → classic `security_events` último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~13:39); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (CDN ainda 0.107.79)

## AF. CodeQL default setup — language matrix / runners / auth (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Configuring default setup](https://docs.github.com/en/code-security/code-scanning/enabling-code-scanning/configuring-default-setup-for-code-scanning) · [At scale](https://docs.github.com/en/code-security/code-scanning/enabling-code-scanning/configuring-default-setup-for-code-scanning-at-scale) · [About CodeQL](https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning-with-codeql) · [Query suites](https://docs.github.com/en/code-security/concepts/code-scanning/codeql/codeql-query-suites) · [Edit default setup](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/edit-default-setup) · [REST code scanning](https://docs.github.com/en/rest/code-scanning/code-scanning) · [FG permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~14:39**)

- [ ] Elegível: Actions on + (público **ou** Code Security); advanced setup já ativo → at-scale inelegível até trocar
- [ ] Enable/edit dia a dia = **UI** Default ou security configuration (§AC) — **sem** classic só para ligar scan
- [ ] Switch default←advanced: override workflow + bloqueia uploads CodeQL API
- [ ] Falha em **todas** linguagens CodeQL: setup enabled mas **sem** scans/minutes até linguagem OK ou reconfig
- [ ] Idle 6 meses sem push/PR → weekly schedule off; org pode monthly inactive
- [ ] Linguagens CodeQL: C/C++ · C# · Go · Java/Kotlin · JS/TS · Python · Ruby · Rust · Swift · Actions; **não** PHP/Scala
- [ ] REST default-setup `languages`: `actions` · `c-cpp` · `csharp` · `go` · `java-kotlin` · `javascript-typescript` · `python` · `ruby` · `swift` — **sem** `rust` no enum (DELTA vs About)
- [ ] Suite: `default` vs `extended` (= security-extended); Extended = mais FP possíveis
- [ ] Threat model preview: `remote` / `remote_and_local` — UI Java/Kotlin + C#
- [ ] Runner: `standard` / `labeled` (`code-scanning` ou custom); larger runner nome `code-scanning` (1/org); runner pós-enable → disable+re-enable ou edit manual
- [ ] Build: `none` C/C++·C#·Java·Rust; `autobuild` outras compiled; self-hosted precisa cmds C/C++/C#/Swift
- [ ] REST enable: FG **Administration** read/write default-setup; triage/SARIF: FG **Code scanning alerts**; autofix commit: **Contents** write
- [ ] Classic: `security_events`/`repo` (alerts/SARIF); default-setup mutate = `repo`/`public_repo`; último recurso
- [ ] PATCH 409 = validation run paralelo; 422 = state inválido; dismiss + `create_request` = delegated dismissal (residual)
- [ ] Árvore: UI/config → FG Administration → FG Code scanning alerts → classic `security_events`/`repo` último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~14:39); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (CDN ainda 0.107.79); path CDN = `adguardhome/` (não `adguard-home`)

## AG. CodeQL advanced setup — custom queries / packs / config / auth (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Configuring advanced setup](https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/configuring-advanced-setup-for-code-scanning) · [Workflow configuration options](https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/customizing-your-advanced-setup-for-code-scanning) · [At scale](https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/configuring-advanced-setup-for-code-scanning-with-codeql-at-scale) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~15:44**)

- [ ] Preferir **default** (§AF) / security configuration (§AC) se não precisar customização real
- [ ] Elegível: Actions on + (público **ou** Code Security) + linguagens CodeQL ou SARIF third-party
- [ ] Enable dia a dia = **UI** Advanced (commit `.github/workflows/codeql-analysis.yml`) — **sem** classic só para ligar
- [ ] Switch default→advanced: Disable CodeQL no pop-up → Advanced; advanced→default: override workflow + bloqueia uploads API (§AF)
- [ ] Pins DOC: `github/codeql-action/init@v4` · `analyze@v4`; matrix 1 language/`init`; evitar detecção sequencial sem `languages`
- [ ] Languages advanced incluem **`rust`** (DELTA vs REST default-setup enum sem `rust`); alternates não excluem sibling (usar config `paths-ignore`)
- [ ] Triggers: push + PR (+ `merge_group` se queue) + schedule; workflow `paths` = se job roda ≠ o que analisa
- [ ] Swift = macOS; **não** ARC (Linux-only); self-hosted: Git PATH + limpar `db-location`
- [ ] Suites: `security-extended` · `security-and-quality`; **não** `github/codeql/...@main`
- [ ] Packs / model packs (preview): `packs:`; multi-lang → config nested; pin version = revisar
- [ ] Config: `config-file` local/`remote=` · inline `config:` · `vars.CODEQL_CONF`; `+` combina workflow+config
- [ ] `disable-default-queries` / `query-filters` / `threat-models: local` (Java/Kotlin+C#) / `category` monorepo
- [ ] Secrets: `external-repository-token` (FG Contents read no repo privado) — nunca PAT no YAML
- [ ] GHES `registries:` token = classic `read:packages` (gap FG Packages) — escopo mínimo + inventário
- [ ] Packs privados org: `GITHUB_TOKEN` / secret tipado; at-scale: App + scripts (`gh-add-files`…)
- [ ] Árvore: default primeiro → UI advanced → secrets tipados → classic `read:packages` só GHES → App multi-repo → classic último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~15:44); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (CDN ainda 0.107.79); path CDN = `adguardhome/`

## AH. CodeQL compiled languages — build modes none/autobuild/manual (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Concepts compiled](https://docs.github.com/en/code-security/concepts/code-scanning/codeql/codeql-for-compiled-languages) · [How-to compiled](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/codeql-for-compiled-languages) · [Build options](https://docs.github.com/en/code-security/reference/code-scanning/codeql/build-options-for-compiled-languages) · [Automatic build failed](https://docs.github.com/en/code-security/reference/code-scanning/troubleshoot-analysis-errors/automatic-build-failed) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~16:43**)

- [ ] Build-mode **não** exige PAT — default UI / security configuration (§AF/§AC) ou editar workflow advanced (§AG)
- [ ] `none` = DB sem build (interpreted + C/C++ · C# · Java · Rust); completeness: generated code **fora**
- [ ] `autobuild` = heurística (C/C++ · C# · Go · Java · Kotlin · Swift); `manual` = cmds user (mesmas + best accuracy)
- [ ] Default tipicamente: C/C++·C#·Java·Rust → `none`; Go·Swift·Kotlin/Java+Kotlin → `autobuild`
- [ ] Kotlin em repo Java `none` → warning; disable+re-enable default (`autobuild`) **ou** advanced
- [ ] Rust: **só** `none`; `Cargo.toml`/`rust-project.json`; runner `rustup`+`cargo`
- [ ] Swift: macOS; **não** ARC; CocoaPods/Carthage **antes** do DB; 1 arch preferível
- [ ] Multi-lang: matrix `language`+`build-mode`; sem matrix autobuild = lang com mais sources (exceto Go, outras falham)
- [ ] Autobuild falhou → advanced `manual` ou remover `autobuild@v4` + `run:` real ([Automatic build failed](https://docs.github.com/en/code-security/reference/code-scanning/troubleshoot-analysis-errors/automatic-build-failed))
- [ ] Dependency caching: default = on (hosted); advanced = off até `dependency-caching: true` (Java·Go·C#)
- [ ] Private NuGet/Maven: org private registries / caching — **nunca** classic no YAML CodeQL
- [ ] Self-hosted: instalar toolchain; C/C++ Ubuntu `CODEQL_EXTRACTOR_CPP_AUTOINSTALL_DEPENDENCIES`; público preferir hosted (§U)
- [ ] Árvore: default `none`/`autobuild` → advanced `manual` se high-risk/fail → secrets só packs/registries (§AG) → classic `read:packages` só GHES → App multi-repo
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~16:43); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (CDN ainda 0.107.79); path CDN = `adguardhome/`

## AI. Code scanning alert triage + Copilot Autofix / agentic (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Resolving alerts](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/resolve-alerts) · [Triage in PRs](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/triage-alerts-in-pull-requests) · [About autofix](https://docs.github.com/en/code-security/concepts/code-scanning/autofix-for-code-scanning) · [REST code scanning](https://docs.github.com/en/rest/code-scanning/code-scanning) · [Merge protection](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/set-merge-protection) · [Delegated dismissal](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/enable-delegated-alert-dismissal) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~17:39**)

- [ ] Dia a dia triage / Generate fix / Create PR with fix = **UI** Security — **sem** classic só para olhar alertas
- [ ] Check **Code scanning results**; fail default = `error`/`critical`/`high`; override severities no default setup
- [ ] Alerta no PR só se **todas** as linhas existem no diff; status na alert page = **default branch**
- [ ] Fechar: fix via PR (re-scan) **ou** Dismiss + reason (`false positive` · `won't fix` · `used in tests` · `mitigated`) + `dismissed_comment` ≤280
- [ ] Dismiss fecha em **todas** as branches; reason pode afetar inclusão futura da query
- [ ] Copilot Autofix: on com CodeQL (default/advanced); **sem** Copilot sub; **sem** AI credits; subset queries; best-effort
- [ ] Agentic (preview): assign Copilot / `copilot-swe-agent[bot]`; precisa cloud agent; **consome** AI credits; valida com suite code-scanning (não custom/extended)
- [ ] REST list/PATCH/autofix get·create: FG **Code scanning alerts**; classic `security_events`/`repo` (público `public_repo`)
- [ ] REST commit autofix: classic **`repo`**/`public_repo` (DOC) — preferir UI Create PR
- [ ] Org list alerts: owner **ou** security manager
- [ ] 403 dismiss → delegated dismissal enabled — ver §AJ (Prevent + review requests)
- [ ] Merge gate: ruleset Require code scanning results + thresholds — ver §AJ
- [ ] Separar SS triage §AE (FG Secret scanning alerts ≠ Code scanning alerts)
- [ ] Árvore: UI triage/Autofix → FG Code scanning alerts → classic `repo` só commit autofix API → App multi-repo → classic amplo último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~17:39); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (CDN ainda 0.107.79); path CDN = `adguardhome/`

## AJ. Code scanning merge protection + delegated dismissal (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Set merge protection](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/set-merge-protection) · [Available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets) · [REST rules](https://docs.github.com/en/rest/repos/rules) · [Enable delegated dismissal](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/enable-delegated-alert-dismissal) · [Review dismissal requests](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/review-alert-dismissal-requests) · [REST dismissal-requests](https://docs.github.com/en/rest/code-scanning/alert-dismissal-requests) · [REST code scanning](https://docs.github.com/en/rest/code-scanning/code-scanning) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~18:42**)

- [ ] Ligar gate / Prevent = **UI** — **sem** mintar classic só para toggle
- [ ] Pré-req: Code scanning configurado (§AF/§AG) **antes** de ruleset `active` (senão bloqueia “tool not configured”)
- [ ] Ruleset branch → Require code scanning results → tool (ex. CodeQL) + Alerts + Security alerts thresholds
- [ ] Bloqueia se: alerta ≥ threshold · análise em progresso · tool não configurada (≠ só check fail do PR §AI)
- [ ] REST `type: code_scanning` + `code_scanning_tools[{tool, alerts_threshold, security_alerts_threshold}]`
- [ ] `alerts_threshold`: `none`/`errors`/`errors_and_warnings`/`all` · `security_alerts_threshold`: `none`/`critical`/`high_or_higher`/`medium_or_higher`/`all`
- [ ] Enforcement: `disabled`/`active`/`evaluate` (evaluate = Enterprise); bypass_actors opcional
- [ ] Automação ruleset: FG **Administration** / App; classic `repo` último
- [ ] Prevent direct alert dismissals: repo Advanced Security **ou** security configuration org/ent (Enforce → repo locked)
- [ ] Create request: PATCH alert + `create_request: true` (FG **Code scanning alerts**); 403 dismiss direto = delegated on
- [ ] Review: UI Security and quality → Requests → Code scanning alert dismissal → Approve/Deny
- [ ] REST review: `GET/PATCH …/dismissal-requests/code-scanning/{alert_number}` — `approve`|`deny` + `message` ≤2048; classic `security_events` + reviewer
- [ ] Filtros status: `open`/`approved`/`expired`/`denied`/`all`; objeto: `pending`/`approved`/`denied`/`expired`
- [ ] Separar SS/Dependabot delegated (mesma UI Requests; produtos ≠); FG SS alerts ≠ Code scanning alerts
- [ ] Árvore: enable CS → ruleset thresholds → Prevent on → request/review → App multi-repo → classic amplo último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~18:42); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **403** unauth/rate (CDN ainda 0.107.79); path CDN = `adguardhome/`

## AK. SARIF upload / third-party tooling / CI externo (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Upload SARIF](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/integrate-with-existing-tools/upload-sarif-file) · [SARIF support](https://docs.github.com/en/code-security/reference/code-scanning/sarif-files/sarif-support) · [Troubleshoot uploads](https://docs.github.com/en/code-security/reference/code-scanning/sarif-files/troubleshoot-sarif-uploads) · [Existing CI](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/integrate-with-existing-tools/use-with-existing-ci-system) · [Upload results CLI](https://docs.github.com/en/code-security/tutorials/customize-code-scanning/upload-results) · [REST code scanning](https://docs.github.com/en/rest/code-scanning/code-scanning) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~19:39**)

- [ ] CodeQL em Actions (default/advanced) = upload **automático** — sem mintar PAT
- [ ] Third-party em Actions: `github/codeql-action/upload-sarif@v4` + `permissions.security-events: write` (+ `actions:read`/`contents:read` privado)
- [ ] `GITHUB_TOKEN` do workflow — **nunca** PAT no YAML para upload
- [ ] Multi-tool / monorepo: `category` ou `runAutomationDetails.id` (senão 2º upload substitui)
- [ ] CI externo: App (`security_events`) → FG **Code scanning alerts** write → classic `security_events` / `public_repo` último; `--github-auth-stdin`
- [ ] REST `POST …/code-scanning/sarifs`: gzip+Base64; body `commit_sha`+`ref`+`sarif`; rate **1000**/h; **202** + `sarif_id`
- [ ] Auth REST: FG **Code scanning alerts** write; classic `security_events` (DOC REST — preferir a wording do tutorial Upload results)
- [ ] Limite tamanho: **10 MB** gzip; results/run hard 25k (top 5k); runs/file 20; ver §AK nota
- [ ] Default setup CodeQL **bloqueia** SARIF **CodeQL** externo — third-party OK; escolher default vs advanced/CI
- [ ] Privado sem Code Security → 403; público CS default on
- [ ] Fingerprints: action calcula; REST sem `partialFingerprints` → risco duplicados
- [ ] Árvore: Actions GITHUB_TOKEN → App CI → FG Code scanning alerts → classic último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~19:39); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **403** rate (CDN ainda 0.107.79); path CDN = `adguardhome/`

## AL. Security campaigns + alert tracking with Issues (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [About campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns) · [Creating/managing](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/creating-managing-security-campaigns) · [Tracking](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/tracking-security-campaigns) · [Fixing in campaign](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/fixing-alerts-in-security-campaign) · [Best practice scale](https://docs.github.com/en/code-security/tutorials/secure-your-organization/best-practice-fix-alerts-at-scale) · [Alert↔issues concepts](https://docs.github.com/en/code-security/concepts/code-scanning/alert-tracking-with-issues) · [Link to issues](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/track-alerts-in-issues) · [REST campaigns](https://docs.github.com/en/rest/campaigns/campaigns) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~20:50**)

- [ ] Enablement at scale = security configurations (§AC) — **não** é campanha
- [ ] Burn-down focado (CWE/classe) com developers = **security campaign** (UI org Security and quality → Campaigns)
- [ ] Criar/gerir = **owner** ou **security manager**; managers = users/teams com esses papéis — **sem** mintar classic só para abrir campanha
- [ ] Seleção: template **ou** custom filters; code = default branch + tipicamente `is:open`/`autofilter:true`; ≤ **1000** alertas; ≤ **10** active
- [ ] Draft → Review and publish **ou** publish direto; due date + managers + contact link
- [ ] Code publish: opcional **Create issues for N repositories** (campaign issue por repo; description/contact/due sync; comment no due/close)
- [ ] Secret campaigns = **public preview**; notificação = view alert list (≠ write-only code)
- [ ] Progress: Open / In progress (code) / Fixed / Dismissed; tracking org + single campaign
- [ ] Fix: Commit autofix / Create branch + PR + review manager; **Assign to Copilot** ≤25 (cloud agent; preview)
- [ ] Alert↔Issues (CS, **public preview**): 1 alerta → 1 issue; 1 issue → ≤50 alertas; cross-repo OK
- [ ] **Sem** auto-sync: alert close ≠ issue close; issue close ≠ alert; delete issue remove link só
- [ ] UI Tracking: Create issue / Add existing / Change or remove — **sem** PAT
- [ ] REST `/orgs/{org}/campaigns`: owner/SM; classic/`OAuth` `security_events`; FG create = **Code scanning alerts** read em todos os repos; drafts **fora** da API
- [ ] Árvore: UI campaign → campaign issues checkbox → alert↔issue Tracking → REST `security_events`/FG CS read → App → classic amplo último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~20:45); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (CDN ainda 0.107.79); path CDN = `adguardhome/`

## AM. Code Quality thresholds + tool status + SARIF residual (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Set PR thresholds](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/set-pr-thresholds) · [Enable Code Quality](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/enable-code-quality) · [Restrict code coverage](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/restrict-code-coverage) · [Set up code coverage](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/set-up-code-coverage) · [Tool status concepts](https://docs.github.com/en/code-security/concepts/code-scanning/tool-status-page) · [Use tool status](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/manage-your-configuration/use-the-tools-status-page-for-code-scanning) · [Available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets) · [Troubleshoot SARIF](https://docs.github.com/en/code-security/reference/code-scanning/sarif-files/troubleshoot-sarif-uploads) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~21:48**)

- [ ] Security CS gate = Require **code scanning** results (§AJ) — **≠** Code Quality gate
- [ ] Quality gate = Enable Code Quality (UI) → confirmar check **"CodeQL - Code Quality"** no PR → Require **code quality results**
- [ ] Pré-req: enterprise **Allow** Code Quality + Actions on + linguagem suportada
- [ ] Enable dia a dia = **UI** Settings → Code quality (repo/org) — **sem** mintar classic
- [ ] Org: Repository access all/selected/filter; opcional Enforce; Confirm billing dialog
- [ ] Severity: Errors · Warnings and higher · Notes and higher · All; **AI findings** fora do threshold
- [ ] Piloto: Enforcement **Evaluate** → Rule Insights → **Active** (Active sem check = pode bloquear todos os PRs)
- [ ] Coverage = regra **separada** Restrict code coverage: min line % · max drop vs default (0 = off)
- [ ] Upload Cobertura: `actions/upload-code-coverage@v1` + `permissions.code-quality: write` + `GITHUB_TOKEN` — sem PAT YAML
- [ ] Triggers coverage: push default (baseline) + pull_request; checkout head ref; fork guard `if`
- [ ] Tool status: Security → Code scanning → Tool status; **repo / default branch only**; sem PAT
- [ ] Status: working / need attention / not working; CodeQL = file coverage % + CSV + errors
- [ ] Default+advanced ambos → tool status mostra **só default**; compiled = ficheiros pré-build
- [ ] Delete config só default branch via UI (warning alerts)
- [ ] SARIF residual: 2.1.0 válido · ≤10 MB gzip · default setup bloqueia SARIF CodeQL · fingerprints REST · §AK
- [ ] Automação ruleset: FG **Administration** / App; classic `repo` último
- [ ] Árvore: UI enable/gate/tool status → coverage GITHUB_TOKEN → FG Administration ruleset → App → classic último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~21:45); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (CDN ainda 0.107.79); path CDN = `adguardhome/`

## AN. Private vulnerability reporting + repository advisories + security managers (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Coordinated disclosure](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/coordinated-disclosure) · [Repository advisories](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/repository-security-advisories) · [Configure PVR repo](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository) · [Report privately](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately) · [Manage reports](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/manage-vulnerability-reports) · [Create](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/create-repository-advisory) · [Publish](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/publish-repository-advisory) · [Collaborators](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/add-collaborators) · [SECURITY.md](https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository) · [Security managers](https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/managing-security-managers-in-your-organization) · [REST advisories](https://docs.github.com/en/rest/security-advisories/repository-advisories) · [FG permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens#repository-permissions-for-repository-security-advisories) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~22:46**)

- [ ] PVR ≠ SECURITY.md — policy = contacto; PVR = formulário/REST só se enabled (repos **públicos**)
- [ ] Enable PVR = **UI** Settings → Advanced Security → Private vulnerability reporting — **sem** mintar classic
- [ ] Org at scale = custom security configuration (§AC) + Watch Security alerts (admins/SM)
- [ ] Researcher: Report a vulnerability → title+description; vira collaborator + credit pendente; opcional private fork
- [ ] Maintainer Triage: comment · private fork · Accept as draft · Close (com motivo)
- [ ] Draft maintainer: ecosystem required; Severity ou CVSS; CWEs; Credits; temporary private fork
- [ ] Publish: preferir **fix version** antes; publish apaga private fork; CVE request ≠ publish (~72h CNA)
- [ ] Estados: `triage`/`draft`/`published`/`closed` (+ `withdrawn` schema)
- [ ] Collaborators = write no advisory; remoção repo/org remove do advisory
- [ ] Security manager: read all repos · write alerts · config security org/repo; campaigns (§AL) = owner/SM
- [ ] REST: FG **Repository security advisories** read/write; classic `repository_advisories:read|write` ou `repo`; App multi-repo
- [ ] `GET /orgs/{org}/security-advisories` = owner/SM + write scope DOC; create/PATCH/CVE = write; list repo unpublished = read
- [ ] Árvore: UI PVR/draft/publish → FG Repository security advisories → App → classic `repo`/`repository_advisories` último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~22:45); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (CDN ainda 0.107.79); path CDN = `adguardhome/`

## AO. Temporary private fork ops + writing advisories best practices (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Collaborate in a fork](https://docs.github.com/en/code-security/tutorials/fix-reported-vulnerabilities/collaborate-in-a-fork) · [Write security advisories](https://docs.github.com/en/code-security/tutorials/fix-reported-vulnerabilities/write-security-advisories) · [Permissions](https://docs.github.com/en/code-security/reference/permissions/repository-security-advisory) · [REST advisories](https://docs.github.com/en/rest/security-advisories/repository-advisories) · [GAD](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/github-advisory-database) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~23:47 BRT**)

- [ ] Pré-req fork = draft advisory; UI Start a temporary private fork — **sem** mintar classic
- [ ] Nome `repo-ghsa-xxxx-xxxx-xxxx` (repo ≤80 chars); charset GHSA DOC
- [ ] CI/integrations **não** acedem temporary private forks; status checks **não** correm nos PRs
- [ ] Write: commit/PR; Admin: create fork · merge · collaborators · metadata · credits · close · publish
- [ ] Merge = **todos** os PRs abertos de uma vez na página do advisory; ≤1 PR → `main` do fork
- [ ] Branch protection do alvo **não** enforced neste merge; publish **apaga** o fork
- [ ] REST `POST …/forks` async ≤5 min; create/report `start_private_fork: true`
- [ ] VVR: operadores com espaço; 1 range/campo (+ Add another affected product); evitar `>` (OSV); lower-only só malware
- [ ] Package name cedo (GAD reviewed); ecosystems REST incl. npm/pip/maven/go/actions/swift/…
- [ ] Prereleases/branches no número: patched = primeiro no alfabeto (ex. `*-android` antes de `*-jre`)
- [ ] Auth: UI first · FG **Repository security advisories** write · App · classic `repository_advisories`/`repo` último
- [ ] Árvore: UI fork/PR/merge → FG write create+fork → App → classic último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~23:47); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 git/refs **404** (CDN ainda 0.107.79); path CDN = `adguardhome/`

## AP. Edit/delete repository advisories + Improve global GAD (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Edit repository advisories](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/edit-repository-advisories) · [Delete](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/delete-repository-advisories) · [Edit Advisory Database](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/edit-advisory-database) · [About GAD](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/about-the-github-advisory-database) · [Browse](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/browse-advisory-database) · [Permissions](https://docs.github.com/en/code-security/reference/permissions/repository-security-advisory) · [REST](https://docs.github.com/en/rest/security-advisories/repository-advisories) · [Innersource withdraw](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/manage-innersource-advisories) · [CONTRIBUTING](https://github.com/github/advisory-database/blob/main/CONTRIBUTING.md) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~00:40 BRT**)

- [ ] Edit repo advisory = UI **Edit advisory** (Security and quality → Advisories) — **sem** mintar classic
- [ ] Edit metadata/credits/CVE/severity/CWE/affected products = **admin** no advisory; write = fork commits/PRs (§AO)
- [ ] Credits: accept notification; público só após accept + publish
- [ ] REST `PATCH …/security-advisories/{ghsa_id}`: SM/admin **ou** collaborator; FG **Repository security advisories** write; classic `repository_advisories:write`/`repo`
- [ ] PATCH `state`: `published` · `closed` · `draft` (list filter também `triage`); response pode ter `withdrawn_at`
- [ ] **Delete published** = GitHub **Support** portal — sem self-serve UI/REST delete documentado
- [ ] Close **draft** ≠ delete published
- [ ] Global GAD improve = `github.com/advisories` → Suggest improvements → PR `github/advisory-database` **ou** PR direto (1 advisory/PR, OSV, refs públicas)
- [ ] GAD edit **não** muda aparência do advisory no repo de origem
- [ ] CONTRIBUTING: **não** reportar vuln nova / PoC / disclosure privado no repo público
- [ ] Community credit aceite = **Analyst**; EPSS **não** editável via contribution
- [ ] Withdraw ≠ um botão: GAD `is:withdrawn` · Support delete repo · innersource `withdrawn` (enterprise App) — não misturar
- [ ] Árvore: UI Edit/Suggest/Support → FG write PATCH → App → classic último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~00:40); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`

## AQ. Global advisories REST + browse GAD + Dependabot from advisory (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [REST global advisories](https://docs.github.com/en/rest/security-advisories/global-advisories) · [Browse GAD](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/browse-advisory-database) · [About Dependabot alerts](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-dependabot-alerts) · [REST Dependabot alerts](https://docs.github.com/en/rest/dependabot/alerts) · [FG Dependabot alerts](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens#repository-permissions-for-dependabot-alerts) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~01:40 BRT**)

- [ ] Browse GAD = UI `github.com/advisories` — **sem** mintar classic
- [ ] REST global: `GET /advisories` · `GET /advisories/{ghsa_id}` — leitura pública típica; default = reviewed **não**-malware (`type=malware` para malware)
- [ ] Filtros REST: ecosystem/severity/cwes/affects/is_withdrawn/epss_*/published|updated|modified; sort published|updated|epss_*; 429 possível
- [ ] Unauth rate limit **60**/h (medido 403 remaining 0 nesta sessão) — não milking; auth sobe teto **sem** justificar classic long-lived
- [ ] Global `/advisories` **≠** FG Repository security advisories (repo-level §AN–§AP)
- [ ] Search UI: `type:` · `ecosystem:` · `severity:` · `affects:` · `cwe:` · `credit:` · `is:withdrawn` · `sort:created|updated-*` · datas ISO8601
- [ ] GraphQL também acessa GAD; default reviewed não-malware
- [ ] “Vulnerable repositories” = botão **Dependabot alerts** no advisory reviewed — só repos com acesso a alerts
- [ ] Só advisories **reviewed** disparam Dependabot alerts; archived não; Actions só semver
- [ ] REST alerts: FG **Dependabot alerts** read/write (`vulnerability_alerts`); classic `security_events` (ou `public_repo` se só públicos); org = owner/SM
- [ ] PATCH dismiss: reason obrigatório; assignees/agents via API/UI; webhook `assignees_changed`
- [ ] Árvore: UI browse/Dependabot alerts → unauth/light `GET /advisories` → FG Dependabot alerts → App → classic `security_events`/`repo` último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~01:40); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`

## AR. GraphQL GAD + Dependabot assign / AI agents (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [GraphQL security advisories](https://docs.github.com/en/graphql/reference/security-advisories) · [Forming calls](https://docs.github.com/en/graphql/guides/forming-calls-with-graphql) · [GraphQL rate limits](https://docs.github.com/en/graphql/overview/rate-limits-and-node-limits-for-the-graphql-api) · [Browse GAD](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/browse-advisory-database) · [About Dependabot alerts](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-dependabot-alerts) · [Viewing/updating alerts](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-dependabot-alerts/viewing-and-updating-dependabot-alerts) · [REST Dependabot alerts](https://docs.github.com/en/rest/dependabot/alerts) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~02:42 BRT**)

- [ ] GraphQL GAD: `securityAdvisories` · `securityAdvisory(ghsaId)` · `securityVulnerabilities` — endpoint `POST /graphql`
- [ ] Classification GraphQL: `GENERAL` / `MALWARE` (unreviewed = eixo UI/REST §AQ; não inventar enum)
- [ ] Usar `cvssSeverities` (não `cvss` deprecated); campo skill `notificationsPermalink` → página Dependabot alerts do GHSA
- [ ] Auth GraphQL: PAT/App/OAuth (DOC); unauth nesta sessão → 403 rate-limit (IP já 0/60 REST) — UI primeiro
- [ ] Rate GraphQL = **pontos**/h (user ~5000); headers `resource=graphql`; ≠ REST 60/h unauth — **não** mintar classic só para pontos
- [ ] Assign alerts: write+ → user / team / AI agent (Copilot + third-party se enabled)
- [ ] Agent: session + draft PR; falha → fica assignee; View Session; só user remove agent
- [ ] Org security overview **não** mostra assignments — triagem assignee na view do **repo**
- [ ] REST PATCH: `assignees` (replace; `[]` limpa; bot login p/ agent) + `agent_assignment` (`custom_instructions` / `custom_agent` / `model`)
- [ ] Filtro list `assignee`: logins · `*` · `none`; webhook `dependabot_alert` / `assignees_changed`
- [ ] Auth assign: UI first · FG **Dependabot alerts** write · App · classic `security_events`/`repo` último
- [ ] Agent assign só com autorização do dono; preferir webhook a polling
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~02:42); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`

## AS. Security overview (org) + Dependabot alert webhooks (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Security overview](https://docs.github.com/en/code-security/concepts/security-at-scale/security-overview) · [Permissions](https://docs.github.com/en/code-security/reference/permissions/security-overview) · [Viewing insights](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/viewing-security-insights) · [Assessing risk](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/assessing-code-security-risk) · [Assessing adoption](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/assessing-adoption-code-security) · [Filtering](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/filtering-alerts-in-security-overview) · [Dashboard metrics](https://docs.github.com/en/code-security/reference/security-at-scale/overview-dashboard-metrics) · [Export CSV](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/exporting-data-from-security-overview) · [Dependabot metrics](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/viewing-metrics-for-dependabot-alerts) · [Webhooks dependabot_alert](https://docs.github.com/en/webhooks/webhook-events-and-payloads#dependabot_alert) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~03:49 BRT**)

- [ ] Security overview = org/enterprise → **Security and quality** — **UI first**, sem mintar classic/FG só para “ver postura”
- [ ] Team: free secret risk assessment; insights extras = Secret Protection / Code Security
- [ ] Views: Overview · Risk · Coverage · Assessments (owners/SM) · Campaigns · Enablement · CodeQL PRs · Dependabot dashboard · Secret scanning
- [ ] Default branches only; Overview/Coverage/Risk = default alerts (omit SS generic/ignored + CS third-party nos summary)
- [ ] Org overview **não** mostra Dependabot assignments — assignee na view do **repo** (§AR)
- [ ] Perms: owner/SM = all; write = CS+Dependabot (sem Coverage); read/triage = sem; Assessments = só owners/SM
- [ ] Membros: cap **3000** repos recentes; owners/SM = todos
- [ ] Dashboard severidade só Critical/High/Medium/Low; compliance → **audit log** (métricas mudam)
- [ ] Alert histórico vs repo atributo **atual** (archive fecha alerts; filtro archived = estado agora)
- [ ] Filtros: AND / OR vírgulas / NOT `-`; Advanced Filter em Overview/Insights
- [ ] CSV Export: filtros aplicados; Teams ≤20; Overview também e-mail
- [ ] Dependabot dashboard funnel default: `has:patch` · `severity:critical,high` · `epss-percentage:>=0.01`
- [ ] Webhook `dependabot_alert`: actions assignees_changed/auto_dismissed/auto_reopened/created/dismissed/fixed/reintroduced/reopened
- [ ] App ≥ read **Dependabot alerts**; availability repo/org/app; payload `alert`; preferir Signature-256; cap 25 MB
- [ ] `repository_vulnerability_alert` **closing down** → usar `dependabot_alert`
- [ ] Árvore: UI overview/dashboard → webhook App read → FG Dependabot alerts → classic `security_events`/`repo` último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~03:49); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`

## AT. GraphQL securityVulnerabilities package monitor + overview filters reference (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [GraphQL security advisories](https://docs.github.com/en/graphql/reference/security-advisories) · [Forming calls](https://docs.github.com/en/graphql/guides/forming-calls-with-graphql) · [GraphQL rate limits](https://docs.github.com/en/graphql/overview/rate-limits-and-node-limits-for-the-graphql-api) · [About GAD](https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/about-the-github-advisory-database) · [Browse GAD](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/fix-reported-vulnerabilities/browse-advisory-database) · [Available filters](https://docs.github.com/en/code-security/reference/security-at-scale/available-filters-for-security-overview) · [Filtering](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/filtering-alerts-in-security-overview) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~04:42 BRT**)

- [ ] `securityVulnerabilities` = eixo **package/version**; `securityAdvisories` = eixo **advisory**; nested `advisory.vulnerabilities` = mesmo tipo filtrado dentro de um GHSA
- [ ] Args package-monitor: `ecosystem` · `package` · `severities` · `classifications` · `orderBy(UPDATED_AT)` · cursor — **sem** identifier/EPSS/publishedSince (usar `securityAdvisories` ou `advisory {…}`)
- [ ] Ecosystems GraphQL: ACTIONS COMPOSER ERLANG GO MAVEN NPM NUGET PIP PUB RUBYGEMS RUST SWIFT
- [ ] `vulnerableVersionRange`: `=` · `<=` · `<` · `>= x, < y` · `>= x` (DOC)
- [ ] Malware: `classifications: [MALWARE]` — sem patched version tipicamente; remoção, não bump
- [ ] Unreviewed ≠ enum GraphQL — UI/REST `type=unreviewed` (§AQ); Dependabot não alerta unreviewed
- [ ] Auth: UI advisories primeiro · GraphQL App/FG curto · classic **proibido** “porque GraphQL/bearer”
- [ ] Probe unauth ~04:42: GraphQL **403** rate-limit (`x-ratelimit-limit: 0`, resource=graphql) — não milking
- [ ] Package monitor GraphQL ≠ filtro overview `dependabot.package`/`package:` (GAD global vs alerts nos repos)
- [ ] Overview filters: AND / OR `,` / NOT `-`; Advanced Filter Overview/Insights
- [ ] Qualifiers skill: `repo`/`team`/`topic`/`archived`/`visibility`/`props.*` · Coverage enablement · Risk counts · `tool:` · Dependabot `assignee`/`epss-percentage`/`has:patch`/`relationship` · CS `autofilter`/`autofix` · SS `validity`/`bypassed`/`results`
- [ ] `assignee` = Dependabot **view** (não org Overview) — cruzar §AR/§AS
- [ ] Filtros overview / dashboard = **UI** — sem mintar PAT
- [ ] Árvore: UI GAD/overview → GraphQL package App/FG → webhook Dependabot → FG alerts write → classic último
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~04:42); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`

## AU. Secret scanning push protection metrics + delegated bypass (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [SS push protection metrics](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/viewing-metrics-for-secret-scanning-push-protection) · [Dashboard metrics](https://docs.github.com/en/code-security/reference/security-at-scale/overview-dashboard-metrics) · [Delegated bypass](https://docs.github.com/en/code-security/concepts/secret-security/delegated-bypass) · [Enable delegated bypass](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/manage-bypass-requests/enable-delegated-bypass) · [Review bypass requests](https://docs.github.com/en/code-security/how-tos/secure-your-secrets/manage-bypass-requests/review-bypass-requests) · [REST delegated-bypass](https://docs.github.com/en/rest/secret-scanning/delegated-bypass) · [Available filters](https://docs.github.com/en/code-security/reference/security-at-scale/available-filters-for-security-overview) · [CodeQL PR metrics](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/viewing-metrics-for-pull-request-alerts) · [PR alert metrics concept](https://docs.github.com/en/code-security/concepts/code-scanning/pull-request-alert-metrics) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~05:42 BRT**)

- [ ] Insights → **Secret scanning** (public preview) = métricas PP; date picker = data do **bypass**
- [ ] Detection → **Secrets bypassed or blocked**: Bypassed vs Successfully blocked; View details → SS report
- [ ] Métricas overview ≠ compliance estável → **audit log** (§AS)
- [ ] Delegated bypass: bypass list · **Exempt** (só bots confiáveis) · review cycle 7d para demais
- [ ] Always bypass: owners · security managers · bypass list · custom role “Review and manage secret scanning bypass requests”
- [ ] Enable: repo Settings Advanced Security **ou** org/enterprise security configuration (org/ent desliga repo-level)
- [ ] Review UI: Requests → Push protection bypass → Open → Approve/Deny + comment auditável
- [ ] Status: Open · Approved (ainda não pushed) · Completed · Denied · Cancelled · Expired (7d)
- [ ] REST: GET enterprise/org/repo bypass-requests · PATCH approve/reject + message ≤2048 · DELETE dismiss response
- [ ] Auth REST: bypass reviewer; classic `security_events` — preferir App/FG/custom role; FG alerts = `secret_scanning_alerts`
- [ ] Filtros SS: `bypassed` · `validity` · `results:default|generic` · Overview `secret-scanning.bypassed|provider|secret-type|validity`
- [ ] Residual CodeQL PR Insights: só merged → default; CSV; Autofix metrics se enabled; UI first
- [ ] Árvore: UI metrics/requests → REST App/FG reviewer → FG SS alerts (§AE) → classic `security_events`/`repo` último
- [ ] Nunca classic “porque métricas SS / aprovar bypass via API”
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~05:42); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`


## AV. CodeQL PR metrics + Autofix MTTR / Prevention (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [View PR alert metrics](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/viewing-metrics-for-pull-request-alerts) · [PR alert metrics concept](https://docs.github.com/en/code-security/concepts/code-scanning/pull-request-alert-metrics) · [Dashboard metrics](https://docs.github.com/en/code-security/reference/security-at-scale/overview-dashboard-metrics) · [Export data](https://docs.github.com/en/code-security/how-tos/view-and-interpret-data/analyze-organization-data/export-data) · [Autofix](https://docs.github.com/en/code-security/concepts/code-scanning/autofix-for-code-scanning) · [Disable Autofix](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/disabling-autofix-for-code-scanning) · [Triage PRs](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-code-scanning-alerts/triage-alerts-in-pull-requests) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~06:42 BRT**)

- [ ] Insights → **CodeQL pull requests** (Team/Enterprise + Code Security); date picker = **creation** das PR alerts
- [ ] Escopo: só PRs **merged** → **default** branch
- [ ] Métricas: prevented · fixed with/without Autofix · unresolved-and-merged · dismissed FP/risk-accepted · top rules · Autofix accepted fraction · remediation rates graph · **MTTR** with/without Autofix
- [ ] Autofix metrics só se Autofix **enabled** no repo
- [ ] Visibilidade repo: admin · custom “View code scanning alerts” · access to alerts
- [ ] Prevention tab: Prevented (fix date) vs Introduced (risk accepted / unresolved at merge); fixed in PRs = CodeQL **ou** SS Fixed tied to merged PR; Autofix ratio
- [ ] Detection/Remediation = default branch; Prevention = merged PR CodeQL alerts
- [ ] Dashboard severity = Critical/High/Medium/Low only; compliance → **audit log** (§AS)
- [ ] Export CSV: Overview/Risk/Coverage/**CodeQL pull requests**; filtros aplicados; Teams ≤20; Overview + e-mail
- [ ] Autofix suggestions: sem Copilot sub / sem AI credits; on com CodeQL; disable enterprise/org/repo fecha comments abertos
- [ ] Agentic autofix (preview): assign Copilot cloud agent = credits; fallback Autofix; valida code-scanning suite (não custom/extended/third-party)
- [ ] Disable Autofix security ≠ Code Quality Autofix (continua)
- [ ] Árvore: UI Insights/Prevention/CSV → triage PR §AI → App/FG `code_scanning_alerts` → classic `security_events`/`repo` último
- [ ] Nunca classic “porque CodeQL PR metrics / Autofix MTTR / Export CSV”
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~06:42); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`


## AW. Production context (linked artifacts / MDC) + custom props filters (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Prioritize production](https://docs.github.com/en/code-security/tutorials/secure-your-organization/prioritize-alerts-in-production-code) · [Linked artifacts](https://docs.github.com/en/code-security/concepts/supply-chain-security/linked-artifacts) · [Upload linked artifacts](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/establish-provenance-and-integrity/upload-linked-artifacts) · [Available filters](https://docs.github.com/en/code-security/reference/security-at-scale/overview-dashboard-filters) · [Custom properties](https://docs.github.com/en/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization) · [REST artifact-metadata](https://docs.github.com/en/rest/orgs/artifact-metadata) · [Org security](https://docs.github.com/en/code-security/concepts/security-at-scale/organization-security) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~07:38 BRT**)

- [ ] Production context = filtrar Dependabot/CS/campaigns por artifacts em produção (não “todos os alerts”)
- [ ] Linked artifacts = metadata org-level de builds **Actions**; **não** guarda o arquivo; **não** lista deps OSS externas
- [ ] Storage records → `artifact-registry` / `artifact-registry-url` (Storage Record API)
- [ ] Deployment records → `has:deployment` / `runtime-risk` (Deployment Record API); ≠ repo deployments dashboard
- [ ] Runtime risks enum: `critical-resource` · `internet-exposed` · `lateral-movement` · `sensitive-data`
- [ ] Upload storage: attest (`push-to-registry: true` + `artifact-metadata: write`) · JFrog · REST `POST …/storage-record`
- [ ] Upload deployment: Dynatrace · **MDC** (public preview) · REST `POST …/deployment-record`
- [ ] Sem provenance → `github_repository` obrigatório nos POSTs
- [ ] Delete da página **não** existe — storage `deleted`/`eol` · deployment `decommissioned`
- [ ] Filtros UI: `has:deployment AND runtime-risk:internet-exposed` · `epss > 0.5 AND artifact-registry-url:…` · `artifact-registry:jfrog-artifactory`
- [ ] Custom props (preview): Overview `props.NAME:value`; Dependabot/SS views também; org Settings → Custom properties
- [ ] Props chars: name `a-zA-Z0-9_-$#` ≤75; values printable ASCII exceto `"`; types text/select/multi/bool
- [ ] List REST: FG `artifact-metadata:read`; write via App/`GITHUB_TOKEN` + `artifact-metadata: write`
- [ ] Árvore: UI filtros/props → integração MDC/JFrog/Dynatrace → Actions attest/TOKEN → App/FG read → classic último
- [ ] Nunca classic “porque preciso filtrar production / POST storage-record / set props”
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~07:38); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`


## AX. Rulesets `deployable`/`deployed` + remove linked artifacts status (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Changelog deployable/deployed GA](https://github.blog/changelog/AAAA-MM-DD-deployment-context-in-repository-properties-and-alerts/) · [Creating org rulesets](https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization) · [Searching repositories](https://docs.github.com/en/search-github/searching-on-github/searching-for-repositories) · [Available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets) · [Remove linked artifacts](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/establish-provenance-and-integrity/remove-linked-artifacts) · [REST org rules](https://docs.github.com/en/rest/orgs/rules) · [FG permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~08:38 BRT**)

- [ ] System props GA: `deployable` = storage record ativo · `deployed` = deployment record ativo (linked artifacts)
- [ ] Search/list org: `deployable:true` · `deployed:true` (Repositories page); ≠ `props.*` custom
- [ ] Ruleset target: Repositories matching a filter → `deployed:true` / `deployable:true` (precisa records na página)
- [ ] Também: All / Only selected / name fnmatch / custom+system properties (`props.team:infra`)
- [ ] Enforcement UI DOC: Active · Disabled; REST também `evaluate` (Enterprise)
- [ ] Org ruleset edit = owners; repo-level só **mais restritivo**
- [ ] REST: `repository_property` include/exclude com `source: system` · name `deployed`/`deployable` · values `true`
- [ ] FG Org **Administration** write cobre `/orgs/{org}/rulesets` — App preferido; classic último
- [ ] `required_deployments` = environments Actions antes do merge — **≠** filtro `deployed:true` / alert `has:deployment`
- [ ] Remove da página: **não** existe DELETE — storage `deleted`/`eol` · deployment `decommissioned` (POST metadata)
- [ ] Registry delete → atualizar storage + lifecycle attestations
- [ ] Árvore: UI filter/ruleset → metadata App/`GITHUB_TOKEN` → App/FG Admin rulesets → classic último
- [ ] Nunca classic “porque preciso filtrar deployed / POST ruleset / marcar decommissioned”
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~08:38); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`


## AY. Push rulesets + bypass actors + enforcement / layering (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets) · [Creating rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository) · [Available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets) · [Org rulesets](https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization) · [REST repos rules](https://docs.github.com/en/rest/repos/rules) · [FG permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (acesso **AAAA-MM-DD ~09:49 BRT**)

- [ ] Caps: **75** rulesets/repo · **75** org-wide (Team/Enterprise)
- [ ] Push ruleset: private/internal + **fork network**; sem branch targeting; bypass só do **root**
- [ ] Push protections: paths (`fnmatch`) · path length · extensions · file size (MB; ≠ LFS); exceptions só path/size
- [ ] Limits path/ext: ≤200 entradas · ≤200 chars; extension **sem** exception nativa
- [ ] Bypass UI: admins/owners · maintain/write · teams (não secret) · Apps · Dependabot; branch: **PR only** opcional
- [ ] REST `actor_type`: Integration · OrganizationAdmin · RepositoryRole · Team · DeployKey · User
- [ ] `bypass_mode`: `always` · `pull_request` (branch; ≠ DeployKey) · `exempt` (sem audit bypass)
- [ ] GET ruleset: `bypass_actors` só com write no ruleset
- [ ] Enforcement: Active · Disabled · `evaluate` (Enterprise / Rule Insights)
- [ ] Layering: aggregate + **mais restritivo**; layer com branch protection; org+repo = só mais restrito
- [ ] Read access vê active rulesets — auditar sem admin/PAT
- [ ] Auth: UI · Metadata read (list) · Repo/Org Administration write (mutate/history) · App preferido · classic último
- [ ] Push ruleset ≠ secret scanning push protection (§O/§AU)
- [ ] Nunca classic “porque preciso POST ruleset / DeployKey bypass / ver bypass_actors”
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~09:49); AGH 0.107.79 / b.90 / 1.0.0-a.69; Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`


## AZ. Ruleset recipes / JSON import-export + Rule Insights / evaluate (AAAA-MM-DD)

**Nota:** `notes/<nota>.md`  
Fontes: [Managing rulesets repo](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository) · [Managing GHEC](https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository) · [Managing org](https://docs.github.com/en/organizations/managing-organization-settings/managing-rulesets-for-repositories-in-your-organization) · [About free](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets) · [About GHEC](https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets) · [REST rule-suites](https://docs.github.com/en/rest/repos/rule-suites) · [FG permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens) · [Managing PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) · [github/ruleset-recipes](https://github.com/github/ruleset-recipes) (acesso **AAAA-MM-DD ~10:55 BRT**)

- [ ] Import: Settings → Rules → Rulesets → New → **Import a ruleset** (repo/org) — **UI, sem PAT**
- [ ] Export/history (GHEC DOC): History 180d · Compare/Restore/Download; **bypass list excluída** do JSON
- [ ] Pós-import: reconstruir bypass de propósito (App/team; PR-only em branch)
- [ ] Recipes: `github/ruleset-recipes` (branch best practices / PRs+commits / org one-rule / tag prevent-delete / org tag semver)
- [ ] Recipe `PRs and commits`: bypass `OrganizationAdmin` + `commit_message_pattern` — org/Enterprise; não Active cego em repo pessoal
- [ ] Enforcement free DOC: Active/Disabled; GHEC: + **Evaluate**; REST inclui `evaluate`
- [ ] Insights: pass/fail/bypass; Evaluate mostra would-pass/fail; dashboard Team+Enterprise; org Dashboard + CSV
- [ ] REST rule-suites: filters `rule_suite_result` + `evaluate_status` (`all`/`active`/`evaluate`)
- [ ] Auth: UI import/Insights · Metadata read (list rulesets) · Admin **read** (repo rule-suites) · Admin **write** (mutate/history; org suites) · App · classic último
- [ ] Delegated bypass push (GHEC): Bypass Requests · 7d · ≠ SS PP delegated (§AU) · ≠ `exempt`
- [ ] Nunca classic “porque preciso importar recipe / Download history / listar rule-suites”
- [ ] Gaps FG reconfirmados inalterados; cap 50 (~10:56); AGH 0.107.79 / b.90 / edge **1.0.0-a.72** (**DELTA** vs a.69); Hostlists 71/64 (49/51/56/70 agressivas Guard; `deprecated: false`); tag v0.107.80 **ausente** (`git ls-remote`; CDN ainda 0.107.79); path CDN = `adguardhome/`
