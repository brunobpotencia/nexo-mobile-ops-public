# Arsenal Nexo Guard — índice operacional

**Atualizado:** 2026-10-05 ~12:01 BRT (linha GitHub baseline do Estado atual); 2026-10-04 ~11:25 BRT (Estado atual + dispositivo Android check); antes 2026-09-28 ~10:58 BRT (ruleset recipes/JSON import + Rule Insights; AGH edge DELTA a.72)

## Valor do estudo
Último estudo focado (2026-09-28 ~10:55 BRT):
1. GitHub extract **desenvolvido**: **Ruleset recipes / JSON import-export + Rule Insights / evaluate** (UI Import; history Download exclui bypass; `github/ruleset-recipes`; Evaluate GHEC; Insights/dashboard; REST rule-suites; FG Admin read suites; delegated bypass push GHEC) — `notes/2026-09-28-11-github-ruleset-recipes-json-import-rule-insights.md` + `github-auth-errors.md` §AZ + higiene §45 + `github-scm.md`. Complementa §AY push/bypass · §AX deployable · §AJ CS merge · §AU SS PP delegated (≠ push).
1b. Anterior: **Push rulesets + bypass actors + enforcement** — `notes/2026-09-28-10-…` + §AY + higiene §44. Anterior deployable/deployed `2026-09-28-09` §AX; production context `2026-09-28-08` §AW.
2. PAT Managing **reconfirmado** (gaps FG inalterados; cap 50). AGH **DELTA edge**: release **0.107.79** · beta **b.90** · edge **1.0.0-a.72+75a29281** (antes a.69); tag `v0.107.80` **ausente** (`git ls-remote`; CDN ainda 0.107.79); Hostlists **71**/64 (49/51/56/70 = agressivas Guard; `deprecated: false`); path CDN = `adguardhome/`.
3. Sem tips ao Bruno; só arquivos Guard.

60+ notes + checklists com fontes oficiais. Não é “achismo”: cada trilha cita docs Google/GitHub/Apple/VPN/AdGuard/CERT.br / CISC / CTIR / MJ / MJSP / Play Console / HaGeZi / Pi-hole / Blocky / Technitium / SmartDNS / Gravity.

## Estado atual (verificado)
- Esta seção: 2026-10-04 ~11:25 BRT (linhas dispositivo Android/VPN); demais linhas de ~01:30 BRT. O restante do índice não foi rechecado.
- Estudo horário: **pausado** (agenda dias úteis 9:37 e 15:37; não reativado)
- Auditoria dispositivo Android dias úteis 9:25 e 15:25: **NÃO VALIDADO** hoje (agenda não conferida). Ferramenta pronta: `playbooks/android-check.sh` (ver seção "dispositivo Android check").
- VPN na box (11:21:41 BRT, `vpn --socket=/home/box/.local/run/vpnd.sock status --json`): BackendState **Running**, nexo-box <VPN_IP_PC>; peer `android-device` <VPN_IP_ANDROID> **online**, direct <IP_PUBLICO>:13834. `debug prefs`: ShieldsUp **false**, CorpDNS false (o "ShieldsUp true" de mais cedo **não** está valendo agora; não alterei).
- Box sem systemd: PID 1 = `tini`, `systemctl` ausente (11:24:37 BRT). vpnd e AdGuardHome rodavam como processos manuais → não voltam sozinhos após reinício do box; subir com `playbooks/start-vpnd.sh` (não faz login) e reaplicar firewall com `../nexo/ops/nexo-ts-guard.sh`.
- dispositivo Android lido ao vivo via SSH 11:22:13 BRT (telefone): usuário terminal Android **<ANDROID_USER>**; patch **2026-08-01**; Android 15; verifiedboot green, flash.locked=1; **292** pacotes (32 de terceiros). Baseline em `baseline/android/`. A baseline foi tirada no meio do hardening do Nexo. Às 11:25:18 BRT (`android-check.sh`): authorized_keys com `from="<VPN_IP_PC>",no-port-forwarding,no-agent-forwarding,no-X11-forwarding` (mesmo fingerprint); `sshd -T`: ListenAddress **<VPN_IP_ANDROID>:8022**, AllowTcp/AgentForwarding **no**, Password/KbdInteractive **no**; sshd reiniciado (PID 31290 → 4441); `pkg upgrade` feito (0 pendentes). Resultado: `CHANGE`, até o Bruno confirmar e rodar `--accept-baseline`. Ver `audit/2026-10-04-android-check-setup.md`.
- SuperGrok: linkado no Mac (confirmado Bruno em registro antigo; não rechecado hoje)
- Gmail MCP (`user-Gmail-xai`): needsAuth em 2026-10-04. GitHub-xai conectado como `brunobpotencia`. Sessões GitHub e aparelhos Google não verificados.

- DNS da rede VPN <VPN_DOMAIN> (fonte: Nexo, 04/10 11:44, aprovado pelo Bruno; NÃO lido por mim no console): servidor global AdGuard <VPN_IP_PC> com Override DNS servers ligado, MagicDNS ligado, sem DNS dividido. Esperado, não é incidente. Risco: nexo-box fora = aparelhos sem DNS (saída: desligar VPN no aparelho). Reverter: desligar o Override. Às 11:43 o querylog ainda não tinha consulta do dispositivo Android.
- ShieldsUp do nexo-box deve ficar **false**: com true o dispositivo Android não alcança o AdGuard na porta 53 (Nexo, 04/10). Não religar.
- Hardening SSH do terminal Android (from=, sem forwarding, ListenAddress <VPN_IP_ANDROID>): visto ao vivo pelo android-check às 11:25, mas o Nexo diz que ainda está em andamento. **Não aceitar baseline nova** até o Nexo avisar e o Bruno confirmar.

- Política de acesso da rede VPN mínima desde 11:53–11:56 (fonte: Nexo, aprovado pelo Bruno; NÃO lida por mim no console): dispositivo Android → nexo-box só udp/tcp 53, tcp 3000 e icmp; nexo-box → dispositivo Android só tcp 8022 e icmp. Sem SSH do VPN e sem Send Files. Aparelho ou porta nova precisa de regra nova. Arquivo `../nexo/ops/vpn/acl-exemplo.hujson`, backup `acl-backup-20261004-default.hujson`. Rede VPN Lock desligado (Android não assina; exige 2 nós).
- 11:59:48 `android-check.sh` ao vivo: SSH do terminal Android escuta só em <VPN_IP_ANDROID>:8022, chave presa a <VPN_IP_PC>, forwarding desligado. Novos no terminal Android desde 11:25: **nmap, libpcap, lua54**, instalados pelo Nexo às 11:27:35 com ok do Bruno, para a varredura da Wi-Fi de casa (conferido ao vivo no apt history às 12:00). Efeito: o `nc` do telefone passa a ser o do nmap. O diff do sshd_config contra `sshd_config.bak-20261004` só acrescenta AllowTcpForwarding/AllowAgentForwarding/X11Forwarding no e ListenAddress <VPN_IP_ANDROID> (conferido 12:00). sshd_config com hash novo `eecd941c…` (era `ba8201bd…` às 11:25). Baseline não aceita.

- 12:06:48 ao vivo: sshd_config sha256 `2cc7a0fe…71a1`. Diff contra `sshd_config.bak-weakalgos-20261004` só acrescenta HostKey ed25519, HostKeyAlgorithms/PubkeyAcceptedAlgorithms ssh-ed25519, KEX sem curvas NIST (mlkem768x25519, sntrup761, curve25519, dh-group16/18) e MACs etm sha2/umac-128 (feito pelo Nexo 12:03, ok do Bruno). sshd PID 11735. known_hosts da box: só ED25519 <HOSTKEY_FP>. O android-check compara só algumas opções do `sshd -T`; KEX/MACs entram pelo hash do arquivo.

- 12:07:52: Bruno confirmou no chat do Guard. Baseline do dispositivo Android gravada a partir da execução de 12:06:48 (anterior em `baseline/android-history/20261004T120752`). Checagem logo depois: NO_CHANGE.

- 2026-10-05 ~08:55 (fonte: Nexo; NÃO revalidado por mim): dispositivo Android sem internet com VPN ligado = a rede da box interceptava DNS UDP/TCP 53 e devolvia 198.18.0.1 para google/youtube/facebook/cloudflare; o AdGuard repassava. Correção aplicada: upstream AdGuard = DoH `https://1.1.1.1/dns-query` e `https://1.0.0.1/dns-query`. Backup `../nexo/ops/adguard/*.bak-20261005-0854-antes-doh`. Esperado. Não mexer em DNS/ACL/firewall/sshd sem autorização explícita do Bruno.

- 2026-10-05 ~10:25 (fonte: Nexo) + checagem Guard 10:25:31: AdGuard com DoH Cloudflare + DNSSEC; terminal Android:Boot (`com.termux.boot`) instalado (F-Droid/Nexo, instalador visto como `com.google.android.packageinstaller`); `~/.termux/boot/start-sshd` (wake-lock + sshd). android-check: CHANGE (292→293). Host key ED25519 <HOSTKEY_FP>. ShieldsUp continua off. Baseline **não** aceita até Bruno confirmar. Relatório Nexo: `../nexo/ops/2026-10-05-pos-melhorias.md`.

- 2026-10-05 ~10:44 (fonte: Nexo): Monitor de rede só resumo texto 8:31/20:31 (sem PNG/Notion). netmon rebaseline com `com.termux.boot`. known_hosts_android = <HOSTKEY_FP>. dash terminal Android 0.5.12→0.5.13.5. Painel Notion descontinuado (lixeira só no app do Bruno). AdGuard DoH+DNSSEC; nexo-status falha 198.18; Chrome box .97; ShieldsUp off.


- GitHub baseline 05/10 ~11:40 (fonte: Nexo, auditoria UI 11:32–11:40; NÃO lida por mim no site) (`baseline/github-baseline-20261005.md`): **2FA ON** (authenticator app); login via Google, sem senha GitHub, 0 passkeys; vigilant mode off; 0 PATs (classic/FG) / 0 OAuth Apps / 0 SSH / 0 GPG; Authorized GitHub Apps Copilot Chat/Cursor/Grok by xAI/Vercel (never used); Installed Cursor/Vercel; `nexo-mobile-ops` dependency graph + Dependabot alerts + security updates ON (malware/grouped/auto submission off; sem dependabot.yml); ruleset protect-main existe sem enforce (private free); secret scanning/push protection indisponíveis (Advanced Security). Conectores: `cursor-github` + `user-GitHub-xai`; `user-Github` residual error. Alertar se 2FA off, PAT/OAuth/app/SSH/GPG novo, ruleset mudar ou Dependabot off. Só leitura.

## Quando aplicar
Só após Bruno autorizar a ação concreta (remount, DNS, etc.).

## Atalhos
- Curriculum: `curriculum/README.md`
- Fontes verificadas (repos/feeds/APIs + conexões necessárias, 2026-10-04): `/home/box/agent-data/workflows/arsenal-nexo-guard/FONTES.md`
- Checklists: `checklists/*.md` — incl. **`checklists/github-credenciais-higiene.md`** + **`checklists/github-auth-errors.md`** (árvore + §A–Z · §AA · §AB · §AC · §AD · §AE · §AF · §AG · §AH · §AI · §AJ · §AK · §AL · §AM · §AN · §AO · §AP · §AQ · §AR · §AS · §AT · §AU · §AV · §AW · §AX · §AY · §AZ) + **`checklists/resposta-incidente.md`** (§12/§24 Furto · §13 GitHub · §14 Apple · §16 gov.br · §18 Golpes pós · §19 Vazamento · §20 Redes sociais · §21 2º fator · §22 malware · §23 PC/Mac) + **`checklists/android-higiene.md`** (Furto pré) + **`checklists/rede-pessoal.md`** + **`checklists/identidade-conta.md`** + **`checklists/phishing.md`** + **`checklists/dns-adblock.md`**
- Notes: `notes/YYYY-MM-DD-*.md` — incl. **`2026-09-28-11-…`** (ruleset recipes / JSON import + Rule Insights) · **`2026-09-28-10-…`** (push rulesets + bypass actors + enforcement) · **`2026-09-28-09-…`** (rulesets deployable/deployed + remove artifacts status) · **`2026-09-28-08-…`** (production context / linked artifacts / props filters) · **`2026-09-28-07-…`** (CodeQL PR metrics + Autofix MTTR/Prevention) · **`2026-09-28-06-…`** (SS PP metrics + delegated bypass) · **`2026-09-28-05-…`** (securityVulnerabilities package monitor + overview filters) · **`2026-09-28-04-…`** (Security overview + Dependabot webhooks) · **`2026-09-28-03-…`** (GraphQL GAD + Dependabot assign/agent) · **`2026-09-28-02-…`** (global advisories REST + Dependabot from GAD) · **`2026-09-28-01-…`** (edit/delete advisories + Improve GAD) · **`2026-09-27-24-…`** (temporary private fork + write advisories best practices) · **`2026-09-27-23-…`** (PVR + repository advisories + security managers) · **`2026-09-27-22-…`** (Code Quality thresholds + tool status + SARIF residual) · **`2026-09-27-21-…`** (security campaigns + alert tracking Issues) · **`2026-09-27-20-…`** (SARIF upload / third-party CI) · **`2026-09-27-19-…`** (CS merge protection + delegated dismissal) · **`2026-09-27-18-…`** (Code scanning alert triage + Autofix) · **`2026-09-27-17-…`** (CodeQL compiled languages / build modes) · **`2026-09-27-16-…`** (CodeQL advanced setup / custom queries) · **`2026-09-27-15-…`** (CodeQL default setup / language matrix) · **`2026-09-27-14-…`** (SS alert triage REST/webhooks) · **`2026-09-27-13-…`** (validity checks + config statuses/enforcement) · **`2026-09-27-12-…`** (security configurations + custom patterns) · **`2026-09-27-11-…`** (Dependabot org Global runner/private + ruleset DR + group-by) · **`2026-09-27-10-…`** (ARC / scale sets auth+ops) · **`2026-09-27-09-…`** (Dependabot auto-triage / multi-ecosystem) · **`2026-09-27-08-…`** (Dependabot version updates / schedule/cooldown) · **`2026-09-27-07-…`** (Dependabot security updates / grouped) · **`2026-09-27-06-…`** (Dependabot malware / dependency review) · **`2026-09-27-05-…`** (immutable releases / release attestations) · **`2026-09-27-04-…`** (artifact attestations / compromised runners) · **`2026-09-27-03-…`** (script injection / pwn request / checkout) · **`2026-09-27-02-…`** (variables vs secrets / inherit) · **`2026-09-27-01-…`** (environment secrets / protection) · **`2026-09-26-12-…`** (OIDC / `id-token` cloud) · **`2026-09-26-11-…`** (`GITHUB_TOKEN` Actions / forks) · **`2026-09-26-10-…`** (push protection users/MCP/REST + remediação) · **`2026-09-26-09-…`** (FG gaps Checks≠Statuses / Packages classic) · **`2026-09-26-08-…`** (AGH update ops / edge CHANGELOG / PAT reconfirm) · **`2026-09-26-07-…`** (passkeys/2FA checkup/sudo/recovery + AGH reconfirm) · **`2026-09-26-06-…`** (GCM/cache + SSO SSH + FG Agent + AGH edge 1.0.0-a) · **`2026-09-26-05-…`** (PAT CLI HTTPS/username + FG RO públicos) · **`2026-09-26-04-…`** (org PAT Restrict/Revoke→SSH + privileged OAuth) · **`2026-09-26-03-…`** (OAuth refresh / device flow / revoke-SSH) · **`2026-09-26-02-…`** (OAuth issuance cap / CLI / deploy key) · **`2026-09-26-01-…`** (AGH Unreleased pré-0.107.80 + KOR) · **`2026-09-22-01-…`** (Hostlists #68/#69/#71 + KO) · **`2026-09-21-18-…`** (AGH edge UI / 0.108) · **`2026-09-21-17-…`** (AGH 0.107.78/79 + OCSP/CRLite) · **`2026-09-21-16-…`** (AdGuard Android 4.13/4.14 + Ext v5.5) · **`2026-09-21-15-…`** (CERT.br Furto de Celular) · **`2026-09-21-14-…`** (Backup) · **`2026-09-21-13-…`** (Trabalho Remoto) · **`2026-09-21-12-…`** (Computadores) · **`2026-09-21-11-…`** (Redes) · **`2026-09-21-10-…`** (Códigos Maliciosos) · **`2026-09-21-09-…`** (CERT.br Autenticação) · **`2026-09-21-08-…`** (Redes Sociais) · **`2026-09-21-07-…`** (Proteção de Dados + Celulares) · **`2026-09-21-06-…`** (Boatos/Vazamento/Privacidade) · **`2026-09-21-05-…`** (CERT.br Golpes) · **`2026-09-21-04-…`** (CERT.br Banco/Comércio) · **`2026-09-21-03-…`** (Quick Fixes / FiltersRegistry) · **`2026-09-21-02-…`** (CERT.br v1.4 / IA) · **`2026-09-21-01-…`** (Chrome MV2/MV3) · **`2026-09-20-29-…`** (Actions/Codespaces/Dependabot secrets)
- AdGuard catalog: `curriculum/adguard-repos.md` + `repos-complementares.md`
- Playbooks: `playbooks/` (incl. `REMOUNT_WIPED.txt`)
- Lab GitHub auth (ops): `../nexo/ops/2026-09-20-github-auth-lab.md`, `../nexo/ops/2026-09-20-postmortem-por-que-travou.md`

## dispositivo Android check (somente leitura) — 2026-10-04
- **Rodar:** `playbooks/android-check.sh` → imprime `SILENT` (offline/ssh_fail, registrado no log), `NO_CHANGE` ou `CHANGE: …` (resumo PT). Exit 0.
- **Aceitar mudanças** (só com confirmação do Bruno): `playbooks/android-check.sh --accept-baseline` (copia a última execução para `baseline/android/`, guarda a anterior em `baseline/android-history/`).
- **Coleta remota:** `playbooks/android-remote-collect.sh` (getprop, `pm list packages -3 -i`, `pm list packages`, sha256 de authorized_keys/sshd_config, `sshd -T`, `dpkg-query`, `apt list --upgradable` com cache só em memória). Não grava no telefone; nunca faz `pkg update/upgrade`.
- **Compara:** usuário, patch, verifiedboot/flash.locked/fingerprint, apps de terceiros novos/removidos, instalador alterado, instalador fora de {`com.android.vending`, `org.fdroid.fdroid`} em app novo/alterado, total de pacotes, hashes + forma do authorized_keys (opções/fingerprint, sem chave), `sshd -T`, pacotes terminal Android (pendentes, novos/removidos, versões).
- **Saídas:** `audit/android-runs/<timestamp>/` (bruto + `parsed/` + `summary.txt`) e uma linha JSON por execução em `audit/android-check.jsonl`.
- **Instaladores desconhecidos tolerados na baseline (vistos ao vivo):** `<LOJA_DO_FABRICANTE>` (RAR, Meu gov.br, Wallpaper Carousel), `com.google.android.packageinstaller` (terminal Android, F-Droid), `null` (Calendar Go, Calculator Go, Celular Legal). São do Bruno/fábrica; não são malware.
- **Armadilhas verificadas:** `pm`/`cmd` consomem o stdin → não usar `ssh … bash -s < script` (cortou a coleta em 11:22:10); passar o script como argumento com `ssh -n`. `sshd -T` mostra o **arquivo**, não o daemon em execução: mudança só vale após reiniciar o sshd (conferir PID em `sshd_proc`).




## Skill-ready (GitHub ruleset recipes / JSON import + Rule Insights)

- Import: Settings → Rules → Rulesets → New → **Import a ruleset** (UI, sem PAT).
- Export/history (GHEC DOC): 180d · Download JSON **sem** bypass list — repor bypass após import.
- Recipes: `github/ruleset-recipes` (branch best practices / PRs+commits / org one-rule / tag prevent-delete / org tag semver).
- Recipe PRs+commits: `OrganizationAdmin` + `commit_message_pattern` → org/Enterprise; não Active cego em pessoal.
- Evaluate (GHEC) → Insights → Active; dashboard Team+; org Dashboard + CSV.
- REST rule-suites: `pass`/`fail`/`bypass` + `evaluate_status` all/active/evaluate.
- Auth: UI · Metadata read (list) · Admin **read** (repo suites) · Admin **write** (mutate/org suites) · App · classic último.
- Delegated bypass push GHEC (Bypass Requests, 7d) ≠ SS PP delegated (§AU).
- Nota `notes/2026-09-28-11-github-ruleset-recipes-json-import-rule-insights.md` · `github-auth-errors.md` §AZ · higiene §45 · `github-scm.md`.

## Skill-ready (GitHub push rulesets + bypass + enforcement)

- Caps: 75 rulesets/repo · 75 org-wide.
- Push ruleset: private/internal + **fork network**; bypass só do **root**.
- Protections: file paths (`fnmatch`) · path length · extensions · file size (MB; ≠ LFS); exceptions path+size.
- Bypass UI: admins/owners · maintain/write · teams (não secret) · Apps · Dependabot; branch **PR only**.
- REST: `actor_type` Integration/OrganizationAdmin/RepositoryRole/Team/DeployKey/User · modes `always`/`pull_request`/`exempt`.
- Enforcement: Active · Disabled · `evaluate` (Enterprise); layering = mais restritivo (+ branch protection).
- Auth: UI first · Metadata read (list) · Repo/Org Administration write · App · classic último.
- Push ruleset ≠ secret scanning push protection (§O/§AU).
- Nota `notes/2026-09-28-10-github-push-rulesets-bypass-actors-enforcement.md` · `github-auth-errors.md` §AY · higiene §44 · `github-scm.md`.

## Skill-ready (GitHub rulesets deployable/deployed + remove artifacts)

- System props GA: `deployable` (storage ativo) · `deployed` (deployment ativo).
- Search/ruleset UI: `deployable:true` · `deployed:true` (precisa linked artifacts records).
- REST: `repository_property` + `source: system`; FG Org Administration write; App preferido.
- Remove: sem DELETE página — storage `deleted`/`eol` · deployment `decommissioned`.
- `required_deployments` (Actions env) ≠ filter `deployed:true` / alert `has:deployment`.
- Auth: UI first · metadata App/`GITHUB_TOKEN` · App/FG Admin rulesets · classic último.
- Nota `notes/2026-09-28-09-github-rulesets-deployable-deployed-remove-artifacts.md` · `github-auth-errors.md` §AX · higiene §43 · `github-scm.md`.

## Skill-ready (GitHub production context / linked artifacts / props)

- Production filters (Dependabot/CS/campaigns): `artifact-registry` · `artifact-registry-url` · `has:deployment` · `runtime-risk` (MDC preview).
- Linked artifacts: storage (registry) vs deployment (runtime risks); metadata only; Actions-built org artifacts.
- Runtime risks: `critical-resource` · `internet-exposed` · `lateral-movement` · `sensitive-data`.
- Upload: attest+`artifact-metadata: write` · JFrog · Dynatrace · MDC · REST storage/deployment-record.
- Custom props (preview): Overview `props.NAME:value`; also Dependabot/SS; org Custom properties UI.
- Auth: UI filtros/props · integração · `GITHUB_TOKEN` write · FG `artifact-metadata:read` · classic último.
- Nota `notes/2026-09-28-08-github-production-context-linked-artifacts-props-filters.md` · `github-auth-errors.md` §AW · higiene §42 · `github-scm.md`.

## Skill-ready (GitHub CodeQL PR metrics + Autofix MTTR / Prevention)

- Insights **CodeQL pull requests** — UI; só PRs merged→default; date = alert creation; Export CSV (filtros; Teams ≤20).
- Métricas Autofix: accepted fraction · remediation rates · **MTTR** with/without; só se Autofix enabled.
- Prevention tab: Prevented (fix date) vs Introduced (risk accepted / unresolved at merge); fixed PRs CodeQL|SS.
- Autofix on com CodeQL (sem Copilot sub/credits); agentic assign = credits/preview; disable enterprise/org/repo.
- Auth: UI metrics/CSV · App/FG `code_scanning_alerts` p/ automação · classic último.
- Nota `notes/2026-09-28-07-github-codeql-pr-metrics-autofix-mttr.md` · `github-auth-errors.md` §AV · higiene §41 · `github-scm.md`.

## Skill-ready (GitHub Secret scanning PP metrics + delegated bypass)

- Insights **Secret scanning** (PP metrics, public preview) + Detection **bypassed/blocked** — UI; date picker = bypass date.
- Delegated bypass: bypass list · Exempt (bots only) · 7d review; owners/SM always; custom role “Review and manage secret scanning bypass requests”.
- Review UI: Requests → Push protection bypass → Approve/Deny + audit comment.
- REST: GET enterprise/org/repo bypass-requests · PATCH approve|reject + message · DELETE dismiss; classic `security_events` último.
- SS filters: `bypassed` · `validity` · `results` · Overview `secret-scanning.*`.
- CodeQL PR metrics deep-dive → `notes/2026-09-28-07-…` §AV / higiene §41 (não residual).
- Auth: UI · App/FG reviewer · FG `secret_scanning_alerts` · classic último.
- Nota `notes/2026-09-28-06-github-secret-scanning-push-protection-metrics-delegated-bypass.md` · `github-auth-errors.md` §AU · higiene §40 · `github-scm.md`.

## Skill-ready (GitHub GraphQL securityVulnerabilities + overview filters)

- `securityVulnerabilities` = package/version monitor; `securityAdvisories` = advisory/EPSS/CVE; nested `vulnerabilities` = dentro de um GHSA.
- Args: `ecosystem` · `package` · `severities` · `classifications` · `orderBy(UPDATED_AT)` — sem identifier/EPSS no root.
- Ecosystems: ACTIONS COMPOSER ERLANG GO MAVEN NPM NUGET PIP PUB RUBYGEMS RUST SWIFT.
- `vulnerableVersionRange` DOC: `=` · `<=` · `<` · `>=x, <y` · `>=x`; malware = remover (sem patch tipicamente).
- Overview filters = UI (AND/OR/NOT); Dependabot view tem `assignee`/`package`/`epss-percentage`; org Overview **não** lista assignees.
- GraphQL package ≠ filtro `dependabot.package` (GAD global vs alerts nos repos).
- Auth: UI · GraphQL App/FG curto · webhook Dependabot · FG alerts · classic último.
- Nota `notes/2026-09-28-05-github-securityvulnerabilities-package-monitor-overview-filters.md` · `github-auth-errors.md` §AT · higiene §39 · `github-scm.md`.

## Skill-ready (GitHub Security overview + Dependabot webhooks)

- Overview = org **Security and quality** UI — sem mintar PAT só para postura.
- Team free secret risk assessment; GHAS Code Security / Secret Protection = insights extras.
- Views: Overview · Risk · Coverage · Assessments (owners/SM) · Campaigns · Enablement · Dependabot dashboard.
- Org overview **não** mostra assignments (§AR) — filtrar assignee no **repo**.
- Perms: owner/SM all; write = CS+Dependabot sem Coverage; members cap 3000 repos.
- Dashboard: Detection/Remediation/Prevention; só Critical–Low; compliance = **audit log**.
- Funnel Dependabot default: `has:patch` · critical/high · EPSS≥0.01.
- Webhook `dependabot_alert` (não `repository_vulnerability_alert`); App **Dependabot alerts** read; Signature-256; cap 25 MB.
- Auth: UI · webhook App · FG Dependabot alerts · classic `security_events`/`repo` último.
- Nota `notes/2026-09-28-04-github-security-overview-dependabot-webhooks.md` · `github-auth-errors.md` §AS · higiene §38 · `github-scm.md`.

## Skill-ready (GitHub GraphQL GAD + Dependabot assign / AI agents)

- GraphQL GAD: `securityAdvisories` · `securityAdvisory(ghsaId)` · `securityVulnerabilities` — `POST /graphql`; classification `GENERAL`/`MALWARE`.
- Preferir UI `github.com/advisories`; GraphQL com token mínimo se automação precisar; unauth IP limited ≠ motivo para classic.
- Usar `cvssSeverities` (não `cvss` deprecated); `notificationsPermalink` = página Dependabot alerts do GHSA.
- Assign: write+ → user/team/AI agent (Copilot / third-party enabled); agent → session + draft PR; View Session; só user remove agent.
- Org overview **não** mostra assignments — filtrar assignee na view do repo.
- REST PATCH: `assignees` + `agent_assignment` (`custom_instructions`/`custom_agent`/`model`); webhook `assignees_changed`.
- Auth: UI · FG **Dependabot alerts** write · App · classic `security_events`/`repo` último; agent só com autorização Bruno.
- Nota `notes/2026-09-28-03-github-graphql-gad-dependabot-assign-agent.md` · `github-auth-errors.md` §AR · higiene §37 · `github-scm.md`.

## Skill-ready (GitHub global advisories REST + Dependabot from GAD)

- Browse/search GAD = UI `github.com/advisories` (ou `GET /advisories`) — default reviewed não-malware; `type=malware` explícito.
- Unauth rate limit **60**/h (medido) — não mintar classic só para subir teto; UI primeiro.
- Global `/advisories` **≠** FG Repository security advisories (repo-level).
- Repos afetados por um GHSA = botão **Dependabot alerts** no advisory (precisa acesso alerts).
- Automação alerts: FG **Dependabot alerts** (`vulnerability_alerts`) · App · classic `security_events`/`repo` último.
- Só advisories **reviewed** disparam Dependabot alerts; first enable não notifica backlog histórico.
- Cruzar §AP edit/delete/Improve · §AN PVR · §W/§X/§Z Dependabot · §AB org Global.
- Nota `notes/2026-09-28-02-github-global-advisories-rest-dependabot-from-gad.md` · `github-auth-errors.md` §AQ · higiene §36 · `github-scm.md`.

## Skill-ready (GitHub edit/delete advisories + Improve global GAD)

- Edit repo advisory = UI **Edit advisory** (admin: metadata/credits/CVE/severity/CWE/products); write = fork only (§AO).
- Delete **published** = GitHub **Support** — sem self-serve UI/REST; close draft ≠ delete.
- Global GAD: Suggest improvements / PR `github/advisory-database` (1/PR, OSV, refs públicas); **não** muda página do repo.
- Withdraw ≠ um botão: GAD `is:withdrawn` · Support delete · innersource `withdrawn` (enterprise).
- Auth: UI/Support first · FG **Repository security advisories** write · App · classic `repository_advisories`/`repo` último.
- Cruzar §AO private fork/write · §AN PVR/advisories · Dependabot pós-publish.
- Nota `notes/2026-09-28-01-github-edit-delete-advisory-global-gad.md` · `github-auth-errors.md` §AP · higiene §35 · `github-scm.md`.

## Skill-ready (GitHub temporary private fork + writing advisories)

- Temporary private fork: CI/integrations **blocked**; status checks **off**; branch protection **not** enforced on advisory merge.
- Merge = **all** open PRs at once (admin) on advisory page; ≤1 PR targeting fork `main`; publish **deletes** fork.
- Nome `repo-ghsa-xxxx-xxxx-xxxx` (repo truncado ≤80).
- VVR: sintaxe GAD/OSV; 1 range/campo (+ Add another affected product); evitar `>` e lower-bound-only; prereleases/branches no número com cuidado.
- Permissões: write = commit/PR; admin = create fork · merge · collaborators · publish · credits.
- Auth: UI first · FG **Repository security advisories** write · App · classic `repository_advisories`/`repo` último.
- Cruzar §AN PVR/advisories · §AL campaigns/SM · Dependabot pós-publish.
- Nota `notes/2026-09-27-24-github-advisory-private-fork-write-best-practices.md` · `github-auth-errors.md` §AO · higiene §34 · `github-scm.md`.

## Skill-ready (GitHub PVR + repository advisories + security managers)

- PVR ≠ SECURITY.md; enable = UI Advanced Security (public repos); org = security configuration (§AC).
- Researcher Report a vulnerability → Triage; maintainer Accept as draft / private fork / Close.
- Draft → private fork → **fix version** → Publish (publish apaga fork); CVE request ≠ publish (~72h).
- Security manager: least privilege org (read all repos + alerts + config); campaigns (§AL) = owner/SM.
- Auth: UI first · FG **Repository security advisories** · App · classic `repository_advisories`/`repo` último.
- Cruzar §AC · §AL · §AM · Dependabot pós-publish.
- Nota `notes/2026-09-27-23-github-private-vulnerability-reporting-repository-advisories.md` · `github-auth-errors.md` §AN · higiene §33 · `github-scm.md`.

## Skill-ready (GitHub Code Quality thresholds + tool status)

- Code Quality gate ≠ CS merge protection (§AJ); AI findings **fora** do threshold.
- Enable = **UI** (enterprise Allow + Actions); confirmar check **"CodeQL - Code Quality"** antes de Active.
- Require code quality results: Errors / Warnings+ / Notes+ / All; piloto **Evaluate** → Active.
- Coverage = **Restrict code coverage** (min line % · max drop); Cobertura `actions/upload-code-coverage@v1` + `permissions.code-quality: write` — sem PAT.
- Tool status: Security → Code scanning → Tool status; **repo / default branch**; working/attention/not working; file coverage %; delete config só default.
- SARIF residual: cruzar §AK (válido 2.1.0 · ≤10 MB gzip · default setup bloqueia SARIF CodeQL · fingerprints).
- Auth: UI first · GITHUB_TOKEN coverage · FG Administration ruleset · classic último.
- Cruzar §AJ · §AK · §AL · §AF.
- Nota `notes/2026-09-27-22-github-code-quality-thresholds-tool-status-sarif.md` · `github-auth-errors.md` §AM · higiene §32 · `github-scm.md`.

## Skill-ready (GitHub security campaigns + alert tracking Issues)

- Campaign = burn-down focado (CWE/classe); configurations (§AC) = enablement — não misturar.
- UI org Security and quality → Campaigns (owner/security manager); **sem** mintar classic só para abrir.
- ≤1000 alerts · ≤10 active; draft→publish; due + managers (owner/SM users/teams) + contact link.
- Code: Autofix on publish; opcional campaign issues por repo (description/contact/due sync; comment no due/close); Assign Copilot ≤25.
- Alert↔Issues (CS **public preview**): 1 alerta→1 issue; issue≤50; **sem** auto-sync close; UI Tracking.
- REST `/orgs/{org}/campaigns`: classic `security_events`; FG create = Code scanning alerts **read**; drafts fora da API.
- Cruzar §AC · §AI · §AJ · §AK · §AE.
- Nota `notes/2026-09-27-21-github-security-campaigns-alert-tracking-issues.md` · `github-auth-errors.md` §AL · higiene §31 · `github-scm.md`.

## Skill-ready (GitHub SARIF upload / third-party CI)

- Actions: `upload-sarif@v4` + `permissions.security-events: write`; CodeQL Actions = upload automático.
- Preferir `GITHUB_TOKEN` — sem PAT no YAML.
- CI externo: App (`security_events`) → FG **Code scanning alerts** write → classic `security_events` último; `--github-auth-stdin`.
- REST: gzip+Base64; `commit_sha`+`ref`+`sarif`; 1000/h; 202 + `sarif_id`.
- Limites: 10 MB gzip; category se multi-upload; default setup bloqueia só SARIF CodeQL.
- Cruzar §AJ merge · §AI triage · §AF/§AG setup.
- Nota `notes/2026-09-27-20-github-sarif-upload-third-party-ci.md` · `github-auth-errors.md` §AK · higiene §30 · `github-scm.md`.

## Skill-ready (GitHub Code scanning merge protection + delegated dismissal)

- Ruleset Require code scanning results + tool + Alerts/`security_alerts` thresholds; blocks alert≥threshold · scan pending · tool missing.
- REST `type: code_scanning` + `alerts_threshold` / `security_alerts_threshold` enums.
- Prevent direct alert dismissals: repo Advanced Security ou security configuration Enforce.
- Create request: PATCH alert `create_request`; review: UI Requests ou PATCH dismissal-requests `approve`/`deny` (classic `security_events`).
- Auth: UI first · FG Administration (rulesets) · FG Code scanning alerts (request) · classic último.
- Nota `notes/2026-09-27-19-github-code-scanning-merge-protection-delegated-dismissal.md` · `github-auth-errors.md` §AJ · higiene §29 · `github-scm.md`.

## Skill-ready (GitHub Code scanning alert triage + Autofix)

- Triage / Generate fix / Create PR with fix = **UI** — sem classic só para olhar.
- Dismiss: `false positive` · `won't fix` · `used in tests` · `mitigated` + comment ≤280; fecha todas as branches.
- Autofix on com CodeQL (sem Copilot sub / sem AI credits); agentic = assign Copilot (credits; preview).
- REST: FG **Code scanning alerts**; commit autofix API = classic `repo`/`public_repo` (preferir UI).
- 403 dismiss / merge gate → §AJ (Prevent + ruleset `code_scanning`).
- Separar SS §AE; cruzar §AF/§AG/§AH setup.
- Nota `notes/2026-09-27-18-github-code-scanning-alert-triage-autofix.md` · `github-auth-errors.md` §AI · higiene §28 · `github-scm.md`.

## Skill-ready (GitHub CodeQL compiled languages — build modes)

- Build-mode **sem PAT**: default UI / config; advanced só se `autobuild`/`manual`.
- `none` (C/C++·C#·Java·Rust) vs `autobuild` (Go·Swift·Kotlin) vs `manual` (best accuracy / high-risk).
- Kotlin em Java `none` → re-enable default ou advanced; Rust só `none`; Swift macOS ≠ ARC.
- Autobuild fail → `manual` + cmds reais; matrix `build-mode` por linguagem.
- Dependency caching: default on hosted; advanced `dependency-caching` (Java·Go·C#); private registries org — nunca classic no YAML.
- Cruzar §AF default · §AG advanced · §AA runners · §U self-hosted.
- Nota `notes/2026-09-27-17-github-codeql-compiled-languages-build-modes.md` · `github-auth-errors.md` §AH · higiene §27 · `github-scm.md`.

## Skill-ready (GitHub CodeQL advanced setup — custom queries / packs / auth)

- Preferir default (§AF) se não precisar custom; enable advanced = **UI** + workflow — sem classic só para ligar.
- Languages/`init` incluem **`rust`** (DELTA vs REST default-setup); matrix 1 lang; Swift ≠ ARC.
- Suites `security-extended` / `security-and-quality`; packs/model packs; config-file ou `vars.CODEQL_CONF`; não `github/codeql@main`.
- Secrets: `external-repository-token` (FG Contents read); GHES `registries` = classic `read:packages` (gap FG Packages).
- Nunca PAT no YAML; at-scale = App + scripts; compromisso → revoke (§6 / IR).
- Cruzar §AF default · §AC configs · §AA runners.
- Nota `notes/2026-09-27-16-github-codeql-advanced-setup-custom-queries.md` · `github-auth-errors.md` §AG · higiene §26 · `github-scm.md`.

## Skill-ready (GitHub CodeQL default setup — language matrix / auth)

- Enable/edit: **UI** Default ou security configuration — sem classic só para ligar scan.
- Elegível: Actions on + (público ou Code Security); falha em todas linguagens = enabled sem scans/minutes.
- Languages CodeQL: C/C++ · C# · Go · Java/Kotlin · JS/TS · Python · Ruby · Rust · Swift · Actions; REST enum default-setup **sem** `rust`.
- Suite: default vs extended; threat model preview Java/Kotlin+C#; idle 6m → weekly off.
- Runners: label `code-scanning` / labeled; runner pós-enable → re-enable ou edit.
- Auth: FG **Administration** (default-setup) · FG **Code scanning alerts** (triage/SARIF) · Contents (autofix commit) · classic último.
- Cruzar §AC configs · §AA runners · §AE SS (produto diferente).
- Nota `notes/2026-09-27-15-github-codeql-default-setup-language-matrix.md` · `github-auth-errors.md` §AF · higiene §25 · `github-scm.md`.

## Skill-ready (GitHub secret scanning alert triage — REST / webhooks)

- Ordem: avaliar validity/labels → **revogar/rotacionar** → Close as manual (SS não auto-fecha).
- Report leak privado = PAT preview; rotacionar antes se downtime.
- UI primeiro; automação = FG **Secret scanning alerts** (+ `hide_secret`); classic `security_events`/`repo` último.
- Nunca logar campo `secret` da API (plaintext).
- Webhook `secret_scanning_alert` (`created`/`resolved`/`validated`/`publicly_leaked`/…) + location + scan; filtrar PP bypass.
- Incremental: commit author sempre notificado; historical: sem author.
- Cruzar §AD validity · §O remediação · IR §13.
- Nota `notes/2026-09-27-14-github-secret-scanning-alert-triage-rest-webhooks.md` · `github-auth-errors.md` §AE · higiene §24 · `github-scm.md`.

## Skill-ready (GitHub validity checks + config statuses / enforcement)

- Partner validity = Team/Enterprise + Secret Protection; GitHub tokens validity = default com SS; generic **sem** validity.
- Extended metadata só com validity on (preview); on-demand **Verify secret**.
- Apply config: default só novos; active+archived; monitorar `attached`/`failed`/`removed`/`enforced`.
- `failed` = partial apply, sem herança futura; `removed` ≠ `detached`; audit `repository_security_configuration`.
- Enforce break: Actions off / actions required ausentes / languages default setup; REST sob Enforce pode “suceder” sem mudar.
- UI/config — **sem PAT**; cruzar §AC · §O · IR.
- Nota `notes/2026-09-27-13-github-validity-checks-config-statuses-enforcement.md` · `github-auth-errors.md` §AD · higiene §23 · `github-scm.md`.

## Skill-ready (GitHub security configurations + custom patterns)

- Configurations = enablement **repo** em escala; Global settings = **org** (custom patterns) — UI, **sem PAT**.
- Default só repos **novos**; transferidos = attach manual; Enforce = bloqueia override das features set.
- Secret Protection / Code Security private = paid; malware/Dependabot/SS/PP via toggles na config.
- Custom pattern: SS on → Global → dry run → publish → PP opcional (só com SS-as-PP; patterns comuns disruptive).
- REST: `read:org` list / `write:org` mutate; enterprise-enforced attach/default ≠ FG PAT / GitHub App (`admin:enterprise` classic).
- Delete/detach: settings do repo ficam; some associação à config.
- Cruzar §AB Global Dependabot · §O push protection · §W malware/DR.
- Nota `notes/2026-09-27-12-github-security-configurations-custom-patterns.md` · `github-auth-errors.md` §AC · higiene §22 · `github-scm.md`.

## Skill-ready (GitHub Dependabot org Global / self-hosted / grant / ruleset DR)

- Global settings: org → Advanced Security → Global — **UI, sem PAT**.
- Runner type: Standard (hosted) default; Labeled = self-hosted com label (`dependabot` ou custom) + group opcional.
- Público → **sempre hosted** (mesmo com labeled); labeled não serve público.
- Enable self-hosted só com runners já rotulados — senão fila infinita.
- Self-hosted: Linux x64 + Docker; outbound `dependabot-actions.githubapp.com`; limitar rede interna.
- Grant private repo mesma org = **todos users org** acessam via Dependabot — blast consciente.
- Registries privados: store Dependabot / OIDC / Packages `GITHUB_TOKEN` — nunca classic no YAML.
- Enforce DR: Rulesets → Require workflows to pass → workflow `dependency-review-action` pinado (§W).
- Monorepo: `group-by: dependency-name` (version, mesmo ecosystem, multi-dir).
- Cruzar ARC §AA se label/scale set; compromisso → revoke.
- Nota `notes/2026-09-27-11-github-dependabot-org-global-runner-private-access.md` · `github-auth-errors.md` §AB · higiene §21 · `github-scm.md`.

## Skill-ready (GitHub ARC / scale sets auth + ops)

- Auth ordem: **GitHub App** (org/repo) → FG mínimo → classic último; **enterprise** = classic só.
- App: Administration RW (repo) + Metadata RO; org Self-hosted runners RW; Secret K8s (`github_app_*`).
- FG: repo Administration RW; org Administration R + Self-hosted runners RW → `github_token`.
- Classic: `repo` (repo) / `admin:org` (org) — nunca plain text Helm CLI em prod.
- Namespaces: runners ≠ operator; runner groups; cluster isolado; logs retidos.
- `runs-on`: INSTALLATION_NAME / `runnerScaleSetName` ou labels; DinD = privileged; k8s: keep require job container.
- Público → hosted (§U); compromisso → revoke App/PAT + rotate.
- Nota `notes/2026-09-27-10-github-arc-scale-sets-auth-ops.md` · `github-auth-errors.md` §AA · higiene §20 · `github-scm.md`.

## Skill-ready (GitHub Dependabot auto-triage + multi-ecosystem)

- Auto-triage: Settings → Advanced Security → Dependabot rules — **UI, sem PAT**.
- Preset low-impact npm-dev: on público; private Enable; CWEs em criteria-for-preset-rules.
- Preset malware dismiss: default off; IMPORTANT — também dismissa malware real all-versions.
- Custom open-PR: só com security updates **off**; malware nunca via open-PR rule.
- Security updates **on** = PR em todo CVE com patch (§X) — custom open-PR não filtra.
- Org: enforced > repo; dismissal before open-PR; audit `resolution:auto-dismiss`.
- Multi-ecosystem: top-level `multi-ecosystem-groups` + schedule; cada ecosystem `multi-ecosystem-group` + **`patterns`** (`["*"]` ok).
- Merge: assignees/labels additive; milestone/commit-message/target-branch/branch-name = group-only.
- Registries: Dependabot secrets / OIDC / Packages `GITHUB_TOKEN` — nunca classic no YAML.
- Nota `notes/2026-09-27-09-github-dependabot-auto-triage-multi-ecosystem.md` · `github-auth-errors.md` §Z · higiene §19 · `github-scm.md`.

## Skill-ready (GitHub Dependabot version updates + schedule)

- Enable: commit `.github/dependabot.yml` **ou** Advanced Security → Dependabot version updates Enable (cria arquivo) — sem PAT.
- Obrigatório: `package-ecosystem` + `directory`/`directories` + `schedule.interval` (`daily`=seg–sex · `weekly` · `monthly` · `cron`…).
- Fork: Enable UI **além** do YAML herdado.
- Cooldown default **3 d** só version (não security); custom 1–90 d.
- `open-pull-requests-limit` default **5**; **0** = desliga version; security fora do contador.
- Groups sem `applies-to` = só version; majors manuais via `ignore` update-types.
- Actions: `package-ecosystem: github-actions` + `directory: "/"`.
- Packages / registries: Manage Actions access + `GITHUB_TOKEN` / Dependabot secrets / OIDC — nunca classic no YAML.
- Nota `notes/2026-09-27-08-github-dependabot-version-updates-schedule-hygiene.md` · `github-auth-errors.md` §Y · higiene §18 · `github-scm.md`.

## Skill-ready (GitHub Dependabot security updates + grouped)

- Enable: dependency graph → Dependabot alerts → **security updates** (UI Advanced Security) — sem PAT; org via Global/security settings.
- Grouped: toggle repo/org **ou** `groups` + `applies-to: security-updates` no `dependabot.yml` (YAML override UI).
- Só CVE: `open-pull-requests-limit: 0`; sem `target-branch`; groups sem `applies-to` = só version.
- Não misturar security×version no mesmo group; não misturar ecosystems.
- GitHub Packages: **Manage Actions access** Read + `GITHUB_TOKEN` — remover PAT do YAML.
- Registry terceiro: store **Dependabot** `${{secrets…}}` ou OIDC (CodeArtifact/Azure/Cloudsmith/GCP/JFrog).
- CI `dependabot[bot]`: `GITHUB_TOKEN` read-only; Actions secrets indisponíveis → duplicar no store Dependabot.
- Malware ≠ security update (§W) — remover pacote; não esperar PR.
- Nota `notes/2026-09-27-07-github-dependabot-security-updates-grouped.md` · `github-auth-errors.md` §X · higiene §17 · `github-scm.md`.

## Skill-ready (GitHub Dependabot malware + dependency review)

- Enable malware alerts **depois** de Dependabot alerts (Settings → Advanced Security) — UI, sem PAT; org via security configuration.
- Malware ≠ CVE: remover pacote / substituto; **sem** fix version; Dependabot **não** abre PR de malware.
- Fontes: npm security + OpenSSF malicious-packages (`type:malware`); 8 ecossistemas (Composer/Go/Maven/npm/NuGet/pip/RubyGems/Rust).
- FP interno homônimo possível; preset **Dismiss package malware alerts** (default off) — IMPORTANT: também dismissa malware real all-versions.
- Dependency review no PR + `dependency-review-action` (`contents: read`, pin SHA, fail-on-severity/licenses/scopes); privado precisa Code Security.
- Config externo privado: sem `ghp_` no YAML — FG/App Contents read via secret.
- Nota `notes/2026-09-27-06-github-dependabot-malware-dependency-review.md` · `github-auth-errors.md` §W · higiene §16 · `github-scm.md`.

## Skill-ready (GitHub immutable releases / release attestations)

- Repo/org com release consumível → Enable release immutability (**só futuros**); org All/Selected via Settings ou API.
- Publish: **draft → anexar assets → publish** (pós-publish: tag+assets travados; notes/title/latest editáveis).
- Delete release imutável: tag pode ir embora, **nome de tag não reusa**; resurrection do repo bloqueada para essas tags.
- Immutable publish gera **release attestation** (tag+SHA+assets) automática ≠ build provenance `actions/attest` (§U) — preferir ambos.
- Consumir: `gh release verify TAG` · `gh release verify-asset TAG PATH` · UI badge Immutable (não cobre source zip sob demanda).
- Org API: classic `admin:org` / FG Organization write — preferir UI; CI publish com `GITHUB_TOKEN`.
- **LAB:** `gh` 2.46.0 box sem `release verify` — upgrade CLI se for verificar aqui.
- Nota `notes/2026-09-27-05-github-immutable-releases-release-attestations.md` · `github-auth-errors.md` §V · higiene §15 · `github-scm.md`.

## Skill-ready (GitHub artifact attestations / compromised runners)

- Release/binário/imagem consumível → `actions/attest` com `id-token: write` + `attestations: write` (+ `packages: write` se imagem); pin **SHA**.
- Attest sozinha = SLSA **L2**; L3 = attest + **reusable** (perms nos dois lados); `gh attestation verify` + `--signer-workflow`.
- Público = Sigstore Public Good + transparency log; privado = Sigstore GitHub sem log público.
- Delete attestation = consumidores com verify param de aceitar — baixar cópia antes.
- Runner comprometido: secrets referenciados + `GITHUB_TOKEN` colhem-se em segundos; redação de log ≠ boundary.
- Cross-repo: `GITHUB_TOKEN` → deploy key → App → FG org; **nunca** classic PAT / SSH pessoal no workflow.
- Self-hosted em público ≈ proibido; preferir hosted ou **efêmero/JIT** + groups; environment **não** isola.
- Nota `notes/2026-09-27-04-github-actions-artifact-attestations-compromised-runners.md` · `github-auth-errors.md` §U · higiene §14 · `github-scm.md`.

## Skill-ready (GitHub Actions script injection / pwn request / checkout)

- Nunca `${{ github.event.*.title|body|… }}` (nem branch/email) direto em `run:` — action `with:` ou `env:` + `"$VAR"`.
- Injection = caminho para exfiltrar secrets / `GITHUB_TOKEN`.
- Preferir `pull_request` a `pull_request_target` se não precisa secrets em fork.
- Pwn request: PRT + checkout head + build/test (ou fetch/artifact) = fork com secrets da base.
- Público: default policy PRT em **evaluate**; enforce **2026-11-02**.
- `persist-credentials: false` se o job não precisa git auth; checkout v7 bloqueia fork PR em PRT/`workflow_run`.
- `allow-unsafe-pr-checkout: true` só inspeção-só; pin actions em **SHA completo**.
- Nota `notes/2026-09-27-03-github-actions-script-injection-pwn-request-checkout.md` · `github-auth-errors.md` §T · higiene §13 · `github-scm.md`.

## Skill-ready (GitHub Actions variables vs secrets / inherit)

- Variables = config **não sensível** (unmasked by default); PAT/key → **Secrets** nunca Variables.
- Precedência vars: environment > repository > organization; env vars só após start do job no runner.
- Limites vars: org 1000 / repo 500 / env 100 · 48 KB; org+repo ≤256 KB/run.
- Reusable: `secrets:` nomeados > `secrets: inherit` (todos; só mesma org/enterprise).
- Cadeia A→B→C: secrets só hop direto; env secrets no job called com `environment:` (não via `workflow_call`).
- `env` do caller não propaga; vars = do caller; pin SHA em reusable externo; nesting ≤10.
- Sensitive gerado no job → `::add-mask::` antes de log.
- Nota `notes/2026-09-27-02-github-actions-variables-vs-secrets-inherit.md` · `github-auth-errors.md` §S · higiene §12 · `github-scm.md`.

## Skill-ready (GitHub environment secrets / protection)

- Prod secret no CI → **environment** atrás de protection; write no repo = lê secrets de **repo**.
- Precedência: environment > repository > organization; org/repo no queue, env no start do job.
- Rules: reviewers ≤6 (Prevent self-review) · wait ≤30 d · Selected branches/tags · deny admin bypass · custom App ≤6.
- Free pessoal: environments efetivos só em **público**; privado Free ignora rules+secrets.
- YAML cria env sem rules — admin configura; delete env = wipe secrets.
- `deployment: false`: gate sem deployment history; incompatível com custom App rules.
- Self-hosted ≠ isolamento; preferir OIDC (§Q) antes de secret.
- Nota `notes/2026-09-27-01-github-environment-secrets-protection-rules.md` · `github-auth-errors.md` §R · higiene §11 · `github-scm.md`.

## Skill-ready (GitHub Actions OIDC / `id-token` / cloud)

- Cloud no CI: **OIDC** short-lived **antes** de mintar AWS/GCP/Azure/Vault key em Actions secrets.
- YAML: `permissions: id-token: write` — só JWT; **não** dá write no GitHub.
- Issuer: `https://token.actions.githubusercontent.com` (JWKS `…/.well-known/jwks`).
- Trust cloud: ≥1 condição; pin `sub` (preferir `environment:prod` / branch/tag).
- `sub` default: environment > pull_request > ref; pós-**2026-07-15** formato imutável `OWNER@ID/REPO@ID` (não GHES).
- Environments + protection (reviewers/branches); Free pessoal = só repo **público**.
- Dependabot OIDC: `event_name=dynamic`; CodeArtifact / Azure Artifacts / JFrog.
- Reusable: pin `job_workflow_ref`; caller externo com `id-token: write`.
- Árvore: mesmo-repo → `GITHUB_TOKEN` · cross-repo → App · **cloud → OIDC** · PAT/key = último.
- Nota `2026-09-26-12-…` · `github-auth-errors.md` §Q · `github-credenciais-higiene.md` §10 · `github-scm.md`.

## Skill-ready (GitHub `GITHUB_TOKEN` / Actions / forks)

- `GITHUB_TOKEN` = App **installation** token do repo; também `github.token` (action lê sem pass).
- Preferir embutido a PAT no CI do **mesmo** repo; cross-repo → App; PAT secret = último recurso.
- Expire: fim do job; hosted ≤**6 h**; self-hosted refresh ≤**24 h**.
- Default pessoal: Workflow permissions **restricted** (contents+packages read); create/approve PRs **off**.
- YAML `permissions:` → não listados = `none`; evitar `write-all`.
- Fork PR: writes→read salvo *Send write tokens*; `pull_request_target` = **write** mesmo de fork público.
- Dependabot PR ≈ fork (read-only; sem secrets Actions).
- Eventos do token não re-disparam workflows (exceto dispatch; PR open/sync/reopen → approval-required).
- `checks: write` no embutido OK; secret scanning alerts ≠ `security-events`.
- Nota `2026-09-26-11-…` · `github-auth-errors.md` §P · `github-credenciais-higiene.md` §9 · `github-scm.md`.

## Skill-ready (GitHub push protection / MCP / remediação leak)

- User PP: **ON by default** (Settings → Code security); bloqueia secrets suportados em **públicos**.
- Superfícies: CLI · UI · upload · REST contents/blob (**409**) · **GitHub MCP** (público; privado com GHAS).
- Bypass CLI: URL = **mesmo user** (404 senão); re-push ≤**3 h**; público sem scanning = bypass sem motivo/alerta.
- Leak público/gist → **auto-revoke** PAT/OAuth/App; mint novo; limpar **todos** stores; Security log.
- Privado PAT: revogar → *Report leak* (preview) → Close as Revoked (alerta não fecha sozinho).
- Ordem: **revoke provider** antes de apagar linha / reescrever histórico.
- Padrões PP: PAT · OAuth · App install · Refresh · SSH key; `github_test_token` **sem** PP.
- Nota `2026-09-26-10-…` · `github-auth-errors.md` §O · `github-credenciais-higiene.md` §8.

## Skill-ready (GitHub FG gaps — Checks ≠ Statuses / Packages)

- Gaps FG inalterados: público alheio · outside collab · multi-org · Packages · Checks API · user Projects; cap **50**.
- **Checks write** = **GitHub App only**; OAuth/user/classic **não criam** check runs (podem ler).
- Anti-padrão: gap “Checks” ≠ mintar classic — classic também **não** escreve Checks.
- CI status simples: FG **Commit statuses** (`statuses`) → `POST .../statuses/{sha}`.
- **Packages**: auth só PAT **classic** (`read/write/delete:packages`); Actions → `GITHUB_TOKEN` + Manage Actions access.
- Template: não mintar Models / Knowledge bases / Private registries / Artifact metadata / Code quality / API Insights sem intenção.
- Nota `2026-09-26-09-…` · `github-auth-errors.md` §N · `github-credenciais-higiene.md` §7.

## Skill-ready (AGH update ops / edge CHANGELOG DOC)

- CHANGELOG v0.107.79: edge **switched** to new UI + versioning → tip `v1.0.0-a.*` esperado.
- Produção (só se Bruno pedir): **release ≥0.107.79**; tag **`v0.107.80` ausente** (Unreleased approx 2026-09-03 ainda no CHANGELOG).
- Update: UI *Update now* (`backup/`) · CLI `./AdGuardHome --update` · Docker/Hass/Snap = **sem** auto-update.
- `Error: control/version.json` → ISP/servers; `--no-check-update` ou manual.
- CDN: `static.adguard.com` (FAQ/Platforms) **e** `static.adtidy.org` (version.json) — ambos vivos (~19:45).
- Verify: GPG `28645AC9776EC4C00BCE2AFC0FE641E7235E2EC6` · dir/bin root 755.
- Nota `2026-09-26-08-…` · `dns-adblock.md` · higiene §6 (PAT remediation).

## Skill-ready (GitHub passkeys / 2FA checkup / sudo / recovery)

- Passkey = password + 2FA; security key WebAuthn sem UV = só 2º fator; Add passkey exige TOTP/SMS prévio.
- Synced vs device-bound (≥2 devices se device-bound); upgrade security key; login `?passkey=true`.
- Checkup **28 d** pós-enable 2FA; Edit/Add sem Disable; Save no GitHub antes de apagar TOTP antigo.
- Recovery: codes (Generate new invalida); SSH **authentication**; PAT classic **`repo`**; verified devices.
- Sudo: 2 h; SMS não autentica; passkey/TOTP/Mobile/security key.
- IR Preventing unauthorized: inventário SSH/deploy/OAuth/Apps + Security log + e-mails + webhooks.
- Nota `2026-09-26-07-…` · `github-auth-errors.md` §M · `github-credenciais-higiene.md` §5c · `github-scm.md`.

## Skill-ready (GitHub GCM/cache + SSO SSH revoke + FG Agent)

- Git diário: **`gh auth login`** (HTTPS + autenticar Git) ou **GCM** — evita mintar PAT; password Git removida.
- HTTPS 401 com PAT API OK → cache stale (Windows Credential Manager / Keychain / GCM); limpar **após** Security log; Git for Windows ≥2.29.
- EMU re-prompt: `credential.gitHubAccountFiltering false`.
- SSO: classic Configure SSO; regenerate/edit scopes → re-Authorize; linked identity força authorize mesmo sem SSO enforced.
- SSH SSO: org **revoga** authorize → **criar key nova** (mesma key não reautoriza); certs CA org sem authorize.
- FG: não mintar **Agent secrets/variables**, Attestations write, Copilot Spaces/agent settings sem intenção.
- Nota `2026-09-26-06-…` · `github-auth-errors.md` §L · `github-credenciais-higiene.md`.

## Skill-ready (AGH canais — edge 1.0.0-a)

- Produção (só se Bruno pedir): **release ≥0.107.79**; tag **`v0.107.80` ausente**.
- `version.json` (~07:47 2026-09-27 **reconfirm**): release **v0.107.79** · beta **v0.108.0-b.90** · edge **v1.0.0-a.69+27fbabe7**.
- Não migrar para edge (alpha 1.0.0-a) nem beta só por UI; Unreleased: Go 1.26.8 / #8565 / #8572.
- Hostlists: max **71** / count **64** / problematic **49/51/56/70**.
- Nota `2026-09-26-08-…` · `2026-09-26-07-…` · `2026-09-26-06-…` · `2026-09-26-01-…` · `dns-adblock.md`.

## Skill-ready (GitHub PAT CLI HTTPS / FG RO públicos / inactive)

- Git HTTPS: Password = **PAT**; **username não autentica** (vazio → inválido); preferir CLI/GCM.
- PAT **não** autentica remote SSH — trocar URL ou usar SSH key; sem prompt → limpar cache após rotação.
- FG “Only select” **ainda** tem read-only a **todos** os repositórios públicos no GitHub.
- FG/classic ficam **inactive** se o user perde acesso ao resource owner.
- Expire/revoke PAT pode gerar `oauth_authorization.destroy` no Security log (cruzar com `personal_access_token.*`).
- Danger zone: Revoke all SSO ≠ apagar tokens; Delete all = **só EMU**.
- Nota `2026-09-26-05-…` · `github-auth-errors.md` §K · `github-credenciais-higiene.md` §2/§6.

## Skill-ready (GitHub org PAT policy / privileged OAuth / SSH sobrevive)

- Org **Restrict** PAT: bloqueia owned resources — **SSH keys criadas por PATs continuam**; públicos da org ainda acessíveis a PATs.
- Org **Revoke** FG (*Active tokens*): SSH do token **continua**; token ainda lê públicos; UI = só FG (classic fora); API review = só GitHub Apps.
- IR: Restrict/Revoke FG **≠** Delete SSH/deploy — inventariar keys à parte (cruzar delete-PAT→deploy-key e revoke-all OAuth→SSH).
- Privileged OAuth (GCM, CLI, Desktop, Copilot CLI, VS Code, …): furam restrict OAuth da org; auto-incluídas podem faltar em Authorized OAuth — cruzar Security log.
- FG approval default require; `pending` → só públicos; max lifetime FG default **366 d**; classic fora do approval.
- Não mintar FG com `copilot_requests` sem intenção (allowance/overage).
- Nota `2026-09-26-04-…` · `github-auth-errors.md` §J · `github-credenciais-higiene.md` §5b.

## Skill-ready (GitHub OAuth refresh / device flow / revoke-SSH)

- OAuth expirável: access **8 h**; refresh `ghr_` **6 meses sem uso**; refresh **invalida** o par antigo; opt-in runtime **`offline_access`**.
- Device flow (CLI/GCM): sem `client_secret`; códigos **900 s**; respeitar `interval`/`slow_down` (+5 s); ≤**50** user-code/h/app.
- WARNING: revogar **todas** as permissões de uma OAuth app **apaga** SSH keys geradas pela app, **incluindo deploy keys** — inventariar antes.
- PKCE `S256` strongly recommended; wildcard callback legado pré-2026-08-03 — desligar se não precisar.
- Nota `2026-09-26-03-…` · `github-auth-errors.md` §E · `github-credenciais-higiene.md`.

## Skill-ready (GitHub OAuth issuance / CLI / deploy key)

- OAuth app: ≤**10** tokens por user + application + **mesmo scope**; 11º **revoga** outro (unused >1 min → LRU → oldest).
- **10 creates/h** → **re-authorization prompt** (não revoga oldest) — parar force_reauth; esperar ≥1 h; inventariar Authorized OAuth.
- CLI: preferir **GitHub CLI** / **Git Credential Manager** antes de mintar PAT; CI → `GITHUB_TOKEN`; script → Actions **ou** Codespaces secret.
- Deletar PAT que **criou** deploy key **remove** a deploy key — inventariar Deploy keys / `public_key.*` antes.
- Nota `2026-09-26-02-…` · `github-auth-errors.md` §E · `github-credenciais-higiene.md`.

## Skill-ready (AGH Unreleased pré-0.107.80 + KOR lag fechado)

- Produção AGH (só se Bruno pedir): **≥0.107.79** hoje; tag **`v0.107.80` ainda ausente** — Unreleased: Go **1.26.8**, `#8565`, `#8572`.
- Canais 2026-09-26: release **0.107.79** · beta **0.108.0-b.90** · edge **1.0.0-a.69** (ver skill-ready canais).
- Hostlists: max id **71**; problematic **49/51/56/70**; KOR #25 = filterslists-KO.
- Nota `2026-09-26-01-…` · `2026-09-26-06-…` · `dns-adblock.md`.

## Skill-ready (Hostlists #68/#69/#71 — baseline)

- Apps AdGuard: só `filters_apps` IDs **1 / 3 / 5 / 34 / 53** — não empilhar #68/#69/#70/#71 no telefone.
- AGH (só se Bruno pedir): security sob demanda **#71** DNS Rebind + **#68** URL Shortener; general **#69** Tracking — testar FP.
- Tag `problematic` (111): **49 / 51 / 56 / 70** — um de cada vez + unbreak.
- FilterListManager = lib de update (Filters + Hostlists), não catálogo novo.
- Nota `2026-09-22-01-…` · refresh KOR em `2026-09-26-01-…` · `dns-adblock.md`.

## Skill-ready (AdGuard Home edge / UI nova 0.108)

- Produção (só se Bruno pedir): canal **release ≥0.107.79** (monitorar tag 0.107.80) — não migrar para edge só por UI.
- `edge` agora **`v1.0.0-a.N`** (`version.json`); `beta` ainda **`v0.108.0-b.90`** — checar `version.json` antes de tipar.
- Troca de canal: backup YAML + `data/`; FAQ path `/release/` = stable.
- Linha 0.108-b: schema 33/34 (`ignored_enabled`; `http.doh.*`); durations com `d`.
- Nota `2026-09-21-18-…` · `dns-adblock.md` (canais).

## Skill-ready (AdGuard Home 0.107.78/79 + OCSP/CRLite)

- Self-host AGH (só se Bruno pedir): preferir **≥0.107.79** (DoQ exhaustion fix + Go 1.26.6); mínimo útil security **≥0.107.78**.
- Pós-0.107.78: se filter update falhar em lista enorme → `filtering.max_http_size` (default **256MB**); H2C HTTP/1.1 upgrade off — testar reverse proxy.
- Não depender de `strict_sni_check` (deprecated 0.107.79).
- ≥0.107.72: TLS cert/key auto-reload (#3962).
- Android 4.13+: CRLite no engine; KB low-level **ainda** tem toggle OCSP checking (HTTPS on) — não tipar remoção do toggle.
- Nota `2026-09-21-17-…` · `dns-adblock.md` (AGH security + Android OCSP).

## Skill-ready (AdGuard Android 4.13/4.14 + Ext v5.5)

- Preferir canal Android **≥4.14.1** se Local VPN já em uso (Always-on pós-reboot #6084; HTTP/2+3; DNS64).
- 4.13+: CRLite (revogação) + DnsLibs PQ; Google Backup no app; ColorOS CA instructions; Integration VPN = credentials + **ambos** apps atualizados — **ainda** XOR VPN.
- Device admin listado em 4.14 (#5320): só ativar se Bruno pedir.
- Extensão PC v5.5: RulesEditor para higiene User rules; Filters → **Mail Tracking (#25)**; `$urltransform` avançado.
- Nota `2026-09-21-16-…` · `dns-adblock.md` (Android + BrowserExtension + Quick Fixes).

## Skill-ready (CERT.br Furto de Celular)

- Pré: lock forte + auto-lock curto + lock screen sem preview/atalhos + App Lock bancos/e-mail + SIM PIN + IMEI (`*#06#`) + Find Hub/Buscar + Celular Seguro + Contato de Confiança + limites Pix baixos + Theft Protection / SDP + backup codes 2SV.
- Via pública com tela aberta: Fixação de Tela / Acesso Guiado.
- Pós (ordem): bancos → Celular Seguro → operadora (SIM+IMEI) → BO (IMEI+série) → `android.com/lock` / Find erase → trocar e-mail/IdP/bancos/Google-Apple → monitorar/contestar.
- Celular Seguro ≠ BO ≠ Find Hub — os três se complementam.
- Nota `2026-09-21-15-…` · IR §12 + §24 · `android-higiene.md` · `phishing.md`.

## Skill-ready (CERT.br Backup)

- ≥2 cópias em locais diferentes; uma offline **desconectada** (anti-ransom wipe).
- Auto + manual antes de viagem/update/manutenção/troca.
- Nuvem: 2SV forte; mídia cifrada; não deixar HD sempre plugado se for a “offline”.
- Celular: backup nativo Wi‑Fi; cruzar Google One E2E (`2026-09-19-17`).
- Testar restore / espaço / notificações periodicamente.
- Nota `2026-09-21-14-…` · `privacidade-dados.md` · `android-higiene.md` · IR §23.

## Skill-ready (CERT.br Trabalho Remoto)

- Segregar device/contas pessoal × trabalho; sem família no PC corp; prestador = máquina exclusiva.
- VPN corp só com política; **nunca** + VPN no mesmo device sem pedido.
- 2SV em VPN/webmail/nuvem; senhas em gerenciador (**não** browser save).
- Dados sensíveis: canais aprovados; USB cifrado; mínimo + apagar após.
- Rede casa: firmware/admin/firewall/Wi‑Fi; ideal segmento separado (cruzar Redes).
- Shoulder surfing / assistente de voz off em call; phishing e-mail = outro canal.
- Sem employer: IR self §22/§23 + CERT.br se incidente técnico.
- Nota `2026-09-21-13-…` · `rede-pessoal.md` · `identidade-conta.md` · `phishing.md`.

## Skill-ready (CERT.br Computadores)

- Original + updates auto (incl. BIOS) + AV + firewall pessoal.
- FileVault/BitLocker + Find My / Localizar device + lock curto.
- Loja oficial; minimizar apps; contas por usuário; admin raro + 2SV no ID do sistema.
- Compartilhamento off por default; NTP (ntp.br); backup auto.
- Suspeita: AV → reinstall SO → senhas em outro device.
- Manutenção/descarte: backup → wipe → verificar AV/firewall pós.
- Pessoal ≠ trabalho no mesmo PC (cruzar Trabalho Remoto).
- Nota `2026-09-21-12-…` · `privacidade-dados.md` · IR §23.

## Skill-ready (CERT.br Códigos Maliciosos)

- Prevenir > limpar: AV atualizado + firewall pessoal + updates + loja oficial + ceticismo link/anexo.
- Scareware: fechar popup; **não** instalar o AV oferecido; verificar com AV conhecido da loja.
- Tipificação: ransomware / spyware (key/screen/stalker) / trojan / RAT / backdoor / worm / bot-botnet / rootkit.
- Pós-suspeita: AV → reboot (RAM-only) → reinstall/factory reset se persiste → cascata de senhas do device (IR §22).
- Conta padrão no cotidiano; admin só para installs (privilégio mínimo).
- Stalkerware = IR (não só “apagar app”); ransomware = backup + sem tipar “pague”.
- Nota `2026-09-21-10-…` · `phishing.md` · `android-higiene.md` · IR §22.

## Skill-ready (CERT.br Redes — casa / Wi‑Fi)

- Admin router **e** Wi‑Fi: trocar vs fábrica; Wi‑Fi também após furto de device conectado.
- SSID sem PII/vendor/ISP; WPA3 ou WPA2/WPA3; **não** WEP/WPA; firewall on; firmware atualizado.
- Guest isolado + senha própria (visitas/IoT); principal só confiança.
- Segregação de segmentos (bridge ISP) só se Bruno autorizar mudança física.
- Grants VPN ≠ higiene do roteador; sem AdGuard VPN + VPN no mesmo phone sem pedido.
- Nota `2026-09-21-11-…` · `rede-pessoal.md`.

## Skill-ready (CERT.br Autenticação)

- 2SV: chave física U2F/FIDO/FIDO2 (ou celular como chave) > app TOTP > SMS só fallback; sem 2SV no serviço → caprichar senha única/forte/armazenamento.
- Negar toda autorização/push de login não iniciado; backup codes offline; revogar+regenerar se perda/suspeita.
- Senha única por conta; reusada vazada → cascata em todos os serviços; 3 palavras aleatórias + charset misto.
- Guardar: gerenciador / papel seguro / arquivo criptografado; banco+e-mail: sem autofill browser nem auto-login.
- Nunca repassar senha/código por msg/e-mail/ligação.
- Lock: bloquear antes de sair; face com atenção; padrão sem rastro + não-trivial.
- IdP social: escopos mínimos + revogar órfãos; alerta indevido → URL digitada → senha → 2SV → sessões.
- Contatos 2SV atualizados + alternativos; trusted device/chave/backup: higiene de perda (IR §21).
- Nota `2026-09-21-09-…` · `identidade-conta.md` · `android-higiene.md` · IR §21.

## Skill-ready (CERT.br Redes Sociais)


- Conta privada quando possível; verificar identidade antes de aceitar; bloquear falsos.
- Perfil sem telefone/PII público; público-alvo das infos + listas por post.
- 2SV + alertas de login; inventário de apps OAuth de terceiros → revogar órfãos; login social = superfície ampliada.
- Links/anúncios/chats: ceticismo mesmo de “conhecido”; denunciar/bloquear + avisar rede se clone.
- Takeover: senha → 2SV → sessões/apps → recovery oficial; avisar contatos (IR §20).
- Reputação: separar pessoal/profissional; não curtir violência/difamação/discriminação; review de marcações; autorização antes de foto de terceiros.
- Nota `2026-09-21-08-…` · `phishing.md` · `privacidade-dados.md` · IR §20.

## Skill-ready (CERT.br Proteção de Dados / Celulares e Tablets)

- Cadastro: política (dados/finalidade/compartilhamento) + consentimento; discordar = não usar.
- Abuso LGPD: Encarregado do Controlador → ANPD **petição** (direitos) ou **denúncia** (infração).
- Glossário: Titular / Controlador / Operador / Encarregado / dados sensíveis / ANPD (até R$ 50 mi/infração).
- LGPD ≠ uso particular puro; = orgs + fins econômicos.
- Repouso: criptografia nativa; sensível criptografado **antes** da nuvem; ≥1 backup offline.
- Lock: auto-lock mínimo; sem preview SMS/notif; sem atalhos de settings na lock.
- Loja oficial + confirmar desenvolvedor; usado = IMEI Anatel Celular Legal + unbound + reset antes.
- Descarte: Remover conta → factory reset → untrust device + revogar apps + unpair BT.
- Wi‑Fi público: SSID verificado; finanças fora; VPN só se Bruno pedir e sem VPN no mesmo device.
- Nota `2026-09-21-07-…` · `privacidade-dados.md` · `android-higiene.md` · IR §19.

## Skill-ready (CERT.br Boatos / Vazamento / Privacidade)

- Boato: alarmista + “compartilhe” + sem fonte/data → fonte oficial + ≥2 checagens; dúvida = não repassar.
- Viral/Pix/doação: só dados oficiais da campanha; clickbait pode ser phishing.
- Pós-vazamento: canal oficial digitado → senhas em cascata + 2SV → bancos → Registrato + Cadastro Pré-Pago → ANPD se Controlador falhar.
- Nunca comprar leak / abrir “confirme se vazou” duvidoso.
- Privacidade: post = permanente; cookies 3º off; permissões mínimas; wipe = reset + untrust device; CPF por desconto = pesar exposição.
- Furto fino (já §12): Fixação/Acesso Guiado em via pública; hygiene lock-screen; limites bancários prévios.
- Nota `2026-09-21-06-…` · `phishing.md` · `privacidade-dados.md` · IR §19.

## Skill-ready (CERT.br Golpes trilogia)

- Triagem: conhecido/org? dinheiro/vantagem/dados? urgência? → alerta; default = golpe até prova.
- Temas cotidianos (CPF cancelado, encomenda, emprego…) e em destaque (Black Friday, IR…) → só canal oficial digitado.
- QR público: checar adesivo; pagamento: valor+CNPJ; ignorar QR de mensagem.
- Pix “por engano”: devolução **só** à conta de origem no app (nunca novo Pix).
- Ativar BC PROTEGE+ **e** Proteção do CPF [Redesim](https://www.gov.br/empresas-e-negocios/pt-br/redesim/).
- Pós-golpe: cortar → senhas/2SV/sessões → MED → cartão → evidências/BO → denunciar → avisar → reset se malware → Registrato.
- Nota `2026-09-21-05-…` · `phishing.md` · IR §18.

## Skill-ready (AdGuard Quick Fixes / FiltersRegistry)

- Quick Fixes **#24** = Obsolete/DISABLED — **nunca** assinar `filters.adtidy.org/.../24.txt`.
- Embutidos MV3: update só com update da extensão (fast-track DNR + full review); sem auto-update de filtros na UI.
- Registry patches: AdGuard **1 h**; third-party **4 h** (`auto_build.sh`).
- Custom filters: Chrome Allow user scripts (138+) ou Developer mode (&lt;138); v5.4+ updates independentes.
- Site quebrado: User/Custom rule ou esperar bump — não caçar Quick Fixes.
- Nota `2026-09-21-03-…` · `dns-adblock.md` · base MV3 `2026-09-21-01-…`.

## Skill-ready (CERT.br Banco / Comércio)

- Banco **não** pede senha/código/token/QR/cartão por contato outbound.
- Limites PIX/TED/DOC reduzidos; cartão **virtual** + limite baixo; wallet com auth.
- E-mail **só** financeiro, sem login permanente no celular; boletos via **DDA**.
- Marketplace: reputação do vendedor; pagar **dentro** da plataforma.
- Pix venda: entregar só após crédito; boleto PDF: CNPJ + banco emissor + valor.
- Disputa: plataforma → Procon → BO; fraude Pix → também MED.
- Nota `2026-09-21-04-…` · `phishing.md`.

## Skill-ready (CERT.br notificações / IA / Security Checkup)

- Reportar: só e-mail `<redacted-email>`; **sem formulário**; preferir abuse da rede origem + **Cc** CERT.br; logs + data/hora/**TZ**.
- Spam → **só** `<redacted-email>`.
- Phishing domínio malicioso/lookalike: **não** WHOIS do domínio; abuse AS/IP + Registrar (notificações v1.4 §3).
- `.gov.br` APF: + CTIR Gov `<redacted-email>`.
- PGP incidente 2026: Key ID `0xDA556E88` · FP `E5A8 3E5E 7FB2 F448 F72E 4AC7 62BE 60DC DA55 6E88` (anual; página contato).
- Fascículo IA: permissão mínima do agente; sem secret no prompt; aprovação humana antes de mutação; deepfake/comprovante = suspeito.
- Security Checkup: Recommended actions azul/amarelo/vermelho; shield verde = OK; recovery · passkey · 2SV forte · Remove apps.
- Nota `2026-09-21-02-certbr-notificacoes-ia-security-checkup.md` · IR §10/§17 · `identidade-conta.md` · `phishing.md`.

## Skill-ready (AdGuard Chrome MV2 removal / MV3)

- CWS removeu **AdGuard Ad Blocker MV2** (2026-09-02, Manifest V2 Deprecation) — blog AG.
- Listing principal (MV3 desde ~2024-09): updates automáticos → em geral nada a fazer.
- Listing **separado** MV2 (outro Extension ID): Chrome **não** migra → instalar AdGuard Ad Blocker **MV3** manualmente; remover órfão.
- Quer MV2 pleno: **Firefox**; Brave = MV2 best-effort (sem garantia permanente).
- App system-wide Android = Local VPN → **XOR VPN** (só se Bruno pedir).
- MV3: phishing = filtros **Security**; sem cookie self-destruct; filtros embutidos amarrados a update da extensão; custom independentes (5.4+).
- Limites: citar Chrome DNR (30k safe dynamic 121+) **e** pipeline AG 5k Allowlist→User→Custom.
- Unreleased 5.5.2: `$removeparam` vazio / `$urltransform` / modifiers desconhecidos — revalidar store.
- Nota `2026-09-21-01-adguard-chrome-mv2-removal-mv3-edge.md` · `dns-adblock.md` · base `2026-09-19-04-…`.

## Skill-ready (GitHub secrets Actions / Codespaces / Dependabot)

- Três stores **separados**: Actions · Codespaces · Dependabot — **não** se cruzam.
- Dependabot-triggered workflow → secret no store **Dependabot** (Actions secret não serve).
- Codespaces: user Settings → Codespaces; repo access mínimo; secret novo = **stop/restart**; sem Dockerfile/build/features.
- Nomes: `[A-Za-z0-9_]`; sem `GITHUB_`; sem dígito inicial; ≤100 (user/repo) × 48 KB.
- Precedência: nível mais baixo (repo > org).
- PAT de script: Codespaces secret (dev) **ou** Actions secret (CI) — Managing PATs.
- FG **sem** `secrets` / `codespaces_secrets` / `dependabot_secrets` write sem necessidade.
- Packages GitHub p/ Dependabot: Manage Actions access + `GITHUB_TOKEN` > PAT em `dependabot.yml`.
- OIDC > long-lived cloud creds quando couber.
- Nota `2026-09-20-29-…` · `github-scm.md` · `github-credenciais-higiene.md`.

## Skill-ready (Find Hub / Theft Protection)

- Prep: Location on; Find Hub Allow locate; offline finding consciente; Show In Menus; teste `android.com/find`; backup codes 2SV; IMEI offline.
- IMEI lock screen (Android 12+): Security & Privacy → Theft Protection toggle; Android path NÃO VALIDADO.
- Remote Lock: `android.com/lock` + número verificado (+ security question opcional — errada = falha); máx **2/24h** (mesmo Offline Device Lock).
- Pós-perda: Remote Lock → Find Hub (locate / Mark as lost / erase) → conta Google → Celular Seguro se furto BR.
- Mark as lost 2SV (PIN+biometria) = Android **17+**; dispositivo Android=15 → Mark as lost clássico.
- Theft Detection: não dispara com tela já locked; pode falhar com Wi‑Fi/BT estáveis.
- Identity Check: só se listado; biometria fora de trusted places p/ desligar Find Hub / factory reset / Developer options.
- Nota `2026-09-20-26-android-find-hub-theft-protection-refresh.md` · `android-higiene.md` · IR §4.

## Skill-ready (My Activity / Nearby / Local network)

- History settings: Auto-delete **3 / 18 / 36** meses; Turn off ≠ apagar (usar Turn off and delete); Search Services History em rollout — se UI antiga, ainda Web & App (Accounts 6139018).
- Shared device: Require extra verification em My Activity; atividade estranha → Security Checkup **antes** de só apagar.
- Nearby devices: Allow só fone/watch/cast/IoT; Deny resto; grupo BT+Wi‑Fi+UWB all-or-nothing (Android 12+).
- Bluetooth: Forget órfãos; off quando idle.
- Android **17** `ACCESS_LOCAL_NETWORK`: LAN bloqueada por default p/ target 37+; preferir system picker/Cast; dispositivo Android=15 → NÃO VALIDADO UI.
- Nota `2026-09-20-25-privacidade-my-activity-nearby-local-network.md` · `privacidade-dados.md`.

## Skill-ready (Photo Picker / Selected Photos / Contacts Play)

- Preferir Photo Picker / “Select photos” (Help 13356023: ≤100; Browse = só selecionado; Android 13+).
- Android 14+ parcial: acesso pode expirar (compat ≈ one-time ao background); URI temporário.
- Pós-upgrade OS: reauditar Photos and videos — full pode ter sido herdado sem novo diálogo.
- App exige “todas as fotos” sem ser galeria/editor amplo = suspeito (Play Restricted; May 2025).
- Contacts: negar se só invite/share; Contact Picker nativo = Android **17+** (Play Jan 2027); dispositivo Android=15 → picker OS NÃO VALIDADO.
- Privacy Dashboard 7d (13+); Privacy controls = kill switch cam/mic; Health/Body Sensors sem necessidade = Deny.
- Nota `2026-09-20-24-privacidade-photo-picker-partial-contacts.md` · `privacidade-dados.md`.

## Skill-ready (CISC / gov.br WhatsApp + 2FA / IR)

- Órgão **nunca** WhatsApp para cobrar / benefício / ameaça bloqueio CPF (CISC 2026-02/04).
- Dados reais na mensagem ≠ legitimidade; pretextos Dívida Ativa / CPF / Correios + link + boleto/PIX = golpe.
- Só `.gov.br` **digitado** (`gov.br`, `regularize.pgfn.gov.br`, `e-cac.receita.fazenda.gov.br`); bloquear/reportar.
- 2FA gov.br: Prata/Ouro; código **só** app oficial; **não** SMS; Authy/GA **não** geram; 1 device; e-mail recuperação no app.
- Dispositivos: revisar; dúvida → Excluir todos; desativar 2FA limpa lista.
- IR MJ: BO → senha portal digitado → app loja → Prata/Ouro → 2FA → dispositivos → métodos recuperação.
- Nota `2026-09-20-23-cisc-govbr-whatsapp-2fa-ir.md` · IR §16 · phishing CISC.

## Skill-ready (GitHub IR / 2FA lockout)
- Com login: senha → 2FA/passkey → Sessions revoke → SSH/deploy/OAuth/Apps/PAT → verify emails → Security log (repos/webhooks/collaborators).
- Token vazado: `POST /credentials/revoke` **sem** auth; `ghp_`/`github_pat_`/`gho_`/`ghu_`/`ghr_`; **não** `ghs_`; 60/h; ≤1000/req.
- Bulk Credentials Danger zone = enterprise SSO / EMU — Free/Pro = inventário manual.
- 2FA lockout: recovery codes → passkey → security key → account recovery (device/SSH/PAT, ≤3 business days); Support **não** restaura sem recovery methods.
- Conta restricted: hygiene + e-mail GitHub + Support se persistir.
- Nota `2026-09-20-17-github-unauthorized-access-2fa-recovery.md`.

## Skill-ready (Apple Account IR / ADP)
- Sinais + `account.apple.com` Devices + SMS forwarding check; `iforgot.apple.com` se lockout (dias; Support não encurta).
- Apple nunca pede senha/código/passcode nem desligar 2FA/SDP.
- ADP: E2E Backup/Photos/Notes…; recovery contact/key antes; Apple não recupera E2E se perder acesso.
- Furto BR: Celular Seguro + BO + Find My (camadas).
- Nota `2026-09-20-18-apple-account-compromised-adp-recovery.md`.

## Skill-ready (Google passkeys / at-risk / recovery)
- Passkeys só em devices pessoais; shared = unlock = acesso à conta; UI `signinoptions/passkeys`.
- Skip password = passkey-first; desligar se preferir senha; com 2SV passkey ainda é 2º passo.
- Manter ≥1 trusted passkey/security key → Re-enable at-risk + speed-up (passkey/key/2SV phone/recovery phone/Authenticator).
- At-risk: sem ação → remove em **30 d**; não reconhecer → Remove + senha + hygiene.
- Métodos novos: até **7 d**; recovery phone **≠** Google Voice; contacts 7d+7d; selfie indisponível sob APP/Workspace/Child.
- Lockout: recovery oficial; Google não liga; recusar serviços recovery de terceiros.
- Nota `2026-09-20-19-google-passkeys-at-risk-recovery.md` · IR §15.

## Skill-ready (GitHub auth + Security log)
- Extract higiene: `checklists/github-credenciais-higiene.md`; erros: `checklists/github-auth-errors.md` (árvore + §A–Z).
- OAuth issuance: ≤**10**/user-app-scope; 10 creates/h → reauth prompt — nota `2026-09-26-02-…` · §E.
- Org Restrict/Revoke FG: SSH do PAT/token **sobrevive** — nota `2026-09-26-04-…` · §J.
- Privileged OAuth (CLI/GCM/Desktop/…): security log ≠ audit org; podem faltar na UI Applications.
- Deletar PAT que criou deploy key remove a key; CLI/GCM antes de mintar PAT.
- Antes de pedir token: canal → instrumento App/PAT → probe → ação → secret → Security log.
- Create-repo FG: **Administration write** (`POST /user/repos`; docs também listam sob “Repository creation”); classic `public_repo`/`repo`; falha → `X-Accepted-GitHub-Permissions` (nota `2026-09-20-06`; reconfirm 2026-09-26).
- Long-lived / multi-repo / org → **GitHub App**; PAT = teste/scripts; cap 50 FG → App (nota `2026-09-20-11`).
- CI mesmo repo → `GITHUB_TOKEN`; cross-repo Actions → App installation token.
- **`ghs_` / Actions token:** opaco **ou** `ghs_APPID_JWT` (~520 chars, 2 dots) desde rollout 2026-04-27 — sem validar length 40; storage ≥520; não parsear JWT (nota `2026-09-20-15`).
- Após PAT/OAuth MCP: Security log (90 d) **e** inventário Developer settings **e** Applications.
- FG no log = `personal_access_token.*`; OAuth = `oauth_authorization.*` / `oauth_access.*`; SSH/deploy = `public_key.*`.
- `personal_access_token.credential_revoked` → tratar como vazamento até prova contrária.
- Após 2º 401 com mesmo fingerprint (prefix+len em PAT) → stop; sem force_reauth sob 429; secret-request só nomes em `CLOUD_AGENT_INJECTED_SECRET_NAMES`.


## Skill-ready (SSH / agent forwarding / persistent signing)

- `ForwardAgent yes` só em `Host` nomeado confiável — **nunca** `Host *` (doc WARNING).
- Preferir deploy key RO / GitHub App no remoto a forward da chave de conta.
- Audit: Settings → SSH and GPG keys ↔ `ssh-add -l -E sha256`; chave estranha → Delete + Support.
- Erro “SSH key audit” / lack of use → Approve ou Delete em `github.com/settings/ssh`.
- SSH sem uso **1 ano** → delete automático GitHub; regenerar se precisar.
- Ed25519 + passphrase; opcional hardware `ed25519-sk`; Auth e Signing = dois uploads.
- Persistent Verified: record imutável pós-push (`verified_at`); revogar chave **não** desverifica histórico.
- Rebase and Merge na UI PR → commits sem assinatura do autor; merge local se política exige Verified.
- Nota `2026-09-20-27-github-ssh-agent-forwarding-persistent-signing.md` · `github-scm.md`.

## Skill-ready (Rede VPN Lock / posture)

- Device approval **XOR** Rede VPN Lock (mutuamente exclusivos).
- Preferir approval em rede VPN pessoal; Lock só com Bruno pedir + plano de secrets.
- Lock init: ≥2 signers (máx 20); ≥ v1.46.1; **10** disablement secrets (1 basta); perda sem escrow suporte = irrecuperável.
- Android **≠** signing node; dispositivo Android = destino a assinar, nunca signer.
- Pré-assinar auth key (`vpn lock sign $AUTH_KEY`) se Lock ligado.
- Pós-init: `vpn lock status` idêntico em todos os nós (TOFU).
- `local-disable` = só aquele nó; não libera peers unsigned no resto.
- Posture: default `node:*` em todos os planos; `srcPosture` OR entre postures / AND dentro; `defaultSrcPosture` não aditivo.
- Shared nodes + subnet router **bypass** posture.
- Nota `2026-09-20-28-vpn-rede VPN-lock-posture-ops.md` · `rede-pessoal.md`.

## Skill-ready (SMS / OTP / SIM / Celular Seguro)
- 2SV: passkey/chave → app TOTP ou prompts → SMS **só** se não houver alternativa (CERT.br Autenticação; Google 185839; GitHub Configuring 2FA).
- Nunca enviar código SMS/OTP; Google/Apple/GitHub não pedem código por mensagem/ligação.
- GitHub SMS: WARNING oficial — interceptável, sem anti-phishing; preferir TOTP + security key / Mobile.
- PIN do SIM ativo + trocar PIN padrão (CERT.br Celulares/Furto).
- Apple SMS falso → `<redacted-email>`; nunca desligar 2FA/Stolen Device Protection a pedido de “suporte”.
- Pré-furto: Celular Seguro (gov.br) aparelhos + Contato de Confiança; alerta + BO (alerta ≠ BO); protocolo; Recuperação vs Bloqueio Total IMEI irreversível.
- Nota `2026-09-20-14-sms-otp-sim-pin-celular-seguro.md`.

## Skill-ready (Private Space / VPN)
- Android 15+ Private Space: conta Google **dedicada**; lock distinto; Hide when locked; auto-lock com device lock (Help 15341885).
- Apps no Private Space **bypass VpnService** do device → VPN / AdGuard Local VPN **não** cobrem o space.
- Apps que precisam de VPN → fora do Private Space; Android presença = NÃO VALIDADO sem UI.
- Sem Find Hub no space; sem device backup do space; ADB/logs podem detectar.
- Nota `2026-09-20-16-android-private-space-vpn-vpn.md`.


## Skill-ready (Play Protect / developer verification)
- Play Protect Scan on; Improve harmful app detection on se sideload; scan sob demanda; code-level se recomendado (Help 2812853 + client-protections).
- Certificação Play Protect ≠ scan — “not certified” → Fix device issue, não desligar Protect.
- Bloqueio unverified + permissões sensíveis (fraude) = barreira Play Protect; privacy / Unwanted Software → preferir Uninstall.
- Verification (BR 2026-09-30, lojas incl. GetApps) = **ID do dev**, não review do APK; Sept = só lojas participantes (sideload direto ainda fora até 2027 — FAQ).
- Advanced flow: Developer Options → anti-coaching → restart → **24 h** → reauth → 7d ou indefinite → ainda Install anyway; ADB isento; updates unregistered falham se flow off.
- Serviço `com.google.android.verifier`; Android UI = NÃO VALIDADO sem inspeção.
- Nota `2026-09-20-20-android-play-protect-developer-verification.md`.


## Skill-ready (Advanced Protection / Accessibility)

- Accessibility: só tools assistivos; pedido de acessibilidade por cleaner/APK/mensagem = scam até prova contrária.
- Restricted settings (13+): Allow só se confiar; sideload + pressão = incidente (Help 12623953).
- Play: `isAccessibilityTool` = deficiência; antivirus/automation/password managers/launchers **não** (10964491); autonomia AI via Accessibility API proibida (exceto tools).
- Device protection (Help 16339980): restringe accessibility a verified tools; unknown apps off; Play Protect não desliga; USB/theft/Scam Detection.
- AAPM Developers = Android **16**; A5=15 → presença Android **NÃO VALIDADO**; “Apps that checked” = 16 only.
- Nota `2026-09-20-22-android-advanced-protection-accessibility.md`.

## Skill-ready (Pix MED — consumidor)

- Contestar no app (autoatendimento Pix) **já**; sem esperar BO para o PSP abrir Recuperação de Valores (Guia BCB 4.3).
- Prazo: ≤80 d raiz; ≤30 d contestação de devolução.
- Fora: desacordo comercial; terceiro boa-fé; Pix errado → só devolução à origem no app.
- MED ≠ chargeback; depende de saldo + confirmação de fraude.
- Guia: `bcb.gov.br/.../Guia_MED.pdf` (4.3; 4.4 citada com vigências futuras — não inventar UI do banco).

## Skill-ready (VPN DNS / wireless ADB)
- Cliente precisa **Use VPN DNS** (`--accept-dns`) para MagicDNS/split/Override; Override só com nameserver alcançável.
- Públicos no console → DoH; exit node = DNS do exit por default.
- Android: **sem** shields-up — entrada = grants/ACL (ex. tcp:8022); um VPN por vez (KB 1105).
- Private DNS DoT estrito + VPN DNS/Override: não empilhar sem teste.
- Wireless ADB: mesma Wi‑Fi real; Forget peer ou Revoke all; Always allow só Wi‑Fi casa; off quando idle; USB p/ auditoria.
- ADB Wi-Fi 2.0 = Android 17 — dispositivo Android (15) = fluxo clássico.
- Nota `2026-09-20-21-vpn-dns-android-wireless-adb.md`.

## Skill-ready (Technitium)
- Trocar `admin`/`admin` na primeira UI; Local End Points = IP LAN + firewall.
- Recursion: `AllowOnlyForPrivateNetworks` ou ACL — nunca `Allow` em VPS sem ACL.
- Built-in Blocking **XOR** Advanced Blocking App (App não herda Settings > Blocking).
- HaGeZi: formato **Wildcard Domains** (ou hosts/AdBlock no App); um Multi + unbreak.
- Rebinding App: `privateDomains` para split-horizon; se Block Page usa IP privado, validar strip.
- Docker: liberar `:53` (resolved/dnsmasq); volume `/etc/dns`; sem install no dispositivo Android.

## Skill-ready (SmartDNS)
- Default = fan-out a **todos** upstreams → privacy leak; `-exclude-default-group` + `nameserver` para split (FAQ).
- Preferir `server-tls`/`server-https` com `-tls-host-verify`; evitar `-k`; ~≤10 upstreams.
- Adblock = `address /d/#` (SOA); iOS: `force-qtype-SOA 65`; uma lista comunidade via `conf-file`.
- Dual-stack: `dualstack-ip-selection yes`; um sinkhole :53 (SmartDNS **ou** AGH/Blocky/Pi-hole).
- Sem install no dispositivo Android; HaGeZi→SmartDNS conf = NÃO VALIDADO.

## Skill-ready (Gravity / BeryJu)
- Só se meta = DNS+DHCP+HA etcd; senão Blocky/AGH/Pi-hole/SmartDNS.
- Compose: host net, hostname único, `/data`, UI `:8008` LAN-only; trocar admin; Sentry off.
- Ads: `forward_blocky` in-process (sem container Blocky); **não** usar defaults empilhados — 1 Multi HaGeZi (+TIF) + allowlist.
- Cluster: nós ímpares; 2 nós = quorum frágil (DNS pode seguir via `memory`/`forward_*`).
- DHCP: um por L2; `dns.zone` → A/PTR; ou cortar role dhcp se router DHCP fica.
- API: Bearer; sock `/var/run/gravity.sock` sem auth = risco local.
- Sem install no dispositivo Android; um sinkhole `:53` na LAN.

## Skill-ready (DNS Native fora do registry)
- HostlistsRegistry Native HaGeZi = só `#60/#61/#63/#65/#66/#67`. Amazon/Huawei/TikTok/LG/Roku → **URL custom** (jsDelivr/`@latest` ou build mirror); **não** há toggle no AdGuard DNS Private Native Tracker.
- TikTok: preferir `native.tiktok.txt`; `native.tiktok.extended.txt` = Aggressive (+~179 regras).
- Sem `share/amazon|huawei|tiktok.txt` (404 2026-09-20) — unbreak via Lookup + issues.
- dispositivo Android = Android `#60`; não ligar Amazon/TikTok/LG/Roku sem device correspondente na rede filtrada.

## Skill-ready (AdGuard DNS Private clients / Access / API)
- Android sem XOR VPN: Private DNS SO = DoT `{Device_ID}.d.adguard-dns.com` — **não** AdGuard DNS app / Local VPN / AdGuard VPN.
- Server = perfil; Device no Dashboard; auto-connect / Setup ID = secreto (reset invalida links).
- Access: Allowed prioridade; allowlist estrita = Disallowed `0.0.0.0/0`+`::/0` + Allowed; allow sozinho não basta; deny ≠ query log / gratis.
- DoH-auth + Deny other protocols = apps/Client (não Private DNS SO).
- User API: ApiKey ou Bearer; PKCE recomendado; OpenAPI `api.adguard-dns.io/swagger/openapi.json`; DoH JSON Public ≠ User API.
- Linked IP = plain + residencial + refresh linkip/DDNS.
- Nota `2026-09-20-13-adguard-dns-private-clients-devices-api.md`.

## Skill-ready (AGH bind / Access)
- LAN: `bind_hosts` = IP LAN + `127.0.0.1`; evitar `0.0.0.0` sem allowlist+rate.
- Público: Allowed clients (ClientID) + `ratelimit` + plain DNS off ou loopback-only.
- `users: []` = UI sem auth; `http.address` não em WAN sem proxy/auth.
- `disallowed_clients` ignorado se `allowed_clients` preenchido; `serve_plain_dns: false` só com DoH/DoT/DoQ.
- Verify `.sig` GPG `28645AC9776EC4C00BCE2AFC0FE641E7235E2EC6`; dir root:root 755.
- Nota `2026-09-20-12-adguard-home-bind-access-hardening.md`.

## Skill-ready (Scriptlets Trusted)
- `trusted-*` / lista Trusted = código privilegiado (clique, cookie, storage, rewrite JSON/rede); FiltersCompiler trust **high** corta `trusted-*`.
- Novos (wiki 2026-09-20): `trusted-json-set*` (+ JSONPath), `trusted-prevent-xhr` com body literal.
- DNS/AGH não executa scriptlets.

## Skill-ready (Blocky)
- Evitar `blockType: refused` (bypass stub); preferir zeroIp/nxDomain.
- Manter specialUseDomains (DDR resolver.arpa); rebindingProtection se upstream público; rateLimit ≠ firewall.
- Docker UID 100 + NET_BIND_SERVICE ou porta ≥1024; freeBind se VPN; um sinkhole :53 na LAN.
- Listas HaGeZi formato Asterisk; sem install no dispositivo Android.

## Skill-ready (Pi-hole v6 vs AGH)
- Um sinkhole na LAN: **Pi-hole ou AGH**, não os dois em :53 sem desenho.
- `listeningMode=ALL` sem firewall = open resolver; Docker bridge precisa ALL **com** firewall host.
- `FTLCONF_*` no Docker trava o setting (read-only) até remover o env; `FTLCONF_dns_upstreams` sobrescreve UI no restart.
- Gravity: um Multi HaGeZi + TIF opcional; specialDomains (mozilla/iCloud/DDR) on se meta é anti-bypass.
- AGH ganha DoH/DoT/DoQ client→sinkhole + `$dnsrewrite`/`$client`; Pi-hole = Gravity + FTL + guia Unbound oficial.
- Sem install no dispositivo Android; sem AdGuard VPN + VPN.

## Regras
- Sem AdGuard VPN + VPN no mesmo aparelho sem pedido
- Sem Magisk/adguardcert sem pedido
- Sem afirmar estado remoto do dispositivo Android sem bridge
- Sem insistir em filtros Gmail via MCP
- Preferir Playwright a Browser-use
- GitHub auth: após 2º 401 com mesmo fingerprint (prefix+len em PAT) → stop; sem force_reauth sob 429; secret-request só com nomes que injetam (`CLOUD_AGENT_INJECTED_SECRET_NAMES`); `ghs_` length variável (não fingerprint por len)

## Meridian (acoplado 2026-09-21)
- Cockpit de skills no Grok Build; brand kit em `../nexo/meridian/`
- Skill Nexo: `modos-de-construcao`
- Não confundir com acesso dispositivo Android (Tail+terminal Android)
