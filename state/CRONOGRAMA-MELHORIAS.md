# Cronograma de Melhorias do Meridian

Documento de workflow manual — tarefas pra Bruno executar etapa por etapa. Não entra em automação. Data base: 2026-10-19. Atualizado: 2026-10-20.

Base: dados de falha de agentes em produção (LangChain State of Agent Engineering 2026, Deloitte Tech Trends 2026, Flynaut 2026, S&P Global 2025, MIT NANDA 2025, Clyro 591 incidentes, Foundra 6259 agentes, Forrester, IDC 410 decisores).

## Fase 1 — Destravar permissões (semana 1, 20-26 out)

Causa raiz mais citada: 88% das falhas são infraestrutura ao redor do modelo, não alucinação (Clyro). O Meridian já tem a camada de honestidade; falta a camada de acesso.

- [ ] Revogar OAuth da abuse.ch em github.com/settings/applications
- [ ] Reconectar GitHub com escopos security_events e notifications (Dependabot listagem já funciona; notifications ainda 403)
- [ ] Gerar PAT em github.com/settings/tokens (escopos: repo, security_events, notifications, workflow) e colar como credencial manual no conector
- [x] Conectar Vercel: conector nativo funcional (projetos e deploys listados em 2026-10-20)
- [ ] Decidir público vs Pro: sanitizar ARSENAL.md e checklists antes de tornar público; ruleset só existe em Pro ou repo público

Critério de saída: dependabot-watch e logs-watch passam sem falha de permissão por três dias seguidos.

## Fase 2 — Primeiro ciclo completo (semana 2, 27 out - 2 nov)

Foundra: 75% das falhas reportavam sucesso em vez de falha. O Meridian já reverteu isso com REGRA-VERIFICACAO. Agora falta fechar o loop.

- [ ] Pico lê fonte, executa tarefa, produz destilado validado de ponta a ponta
- [ ] Eval compara destilado com fonte primária e aprova ou rejeita com motivo
- [ ] REGRA-VERIFICACAO-HUMANA recebe relatório real (não de falha) e responde a pergunta central
- [ ] Cap noite gera snapshot de disco funcional

Critério de saída: um destilado por dia que passa no teste honesto (lesses sem saber a autoria, aprenderias?).

## Fase 3 — Evals automatizados (semana 3, 3-9 nov)

Forrester: 47% de rollback sem evals vs 9% com cobertura completa. Hoje o eval é manual e diário; falta cobertura contínua.

- [ ] Eval roda em todo push na main via CI (github actions), não só no horário agendado
- [ ] Threshold de aprovação: destilado deve citar URL da fonte e trecho verificável
- [ ] Falha de eval bloqueia merge automático (o meridian-merge só executa se eval passou)
- [ ] Histórico de evals versionado em state/evals/ com data e resultado

Critério de saída: zero merges sem eval verde nas últimas duas semanas.

## Fase 4 — Síntese entre conectores (semana 4, 10-16 nov)

Nenhum conector sozinho dá a foto. Correlação é onde o valor real aparece.

- [ ] Cruzar Gmail (Caesb, Nubank, iFood) com GitHub (alertas, deploys) e Vercel (status) num relatório diário de risco
- [ ] Exemplo alvo: "deploy quebrou no mesmo dia que fatura venceu e token foi revogado" — correlação que humano levaria uma hora
- [ ] Relatório de risco vai pro e-mail às 7h, antes do pico das 8h

Critério de saída: pelo menos uma correlação acionável por semana que mudou uma decisão tua.

## Fase 5 — Auto-melhoria a partir de falhas (semana 5, 17-23 nov)

Cada relatório de falha da REGRA-VERIFICACAO é um caso de teste latente.

- [ ] Agregar falhas do mês em state/falhas-agregadas.md com padrão identificado
- [ ] Gerar entrada nova no fontes.md ou script de diagnóstico a partir do padrão
- [ ] O eval valida se a correção gerada resolve o caso original antes de mergear

Critério de saída: o Meridian propõe a própria correção e o eval aprova sem intervenção tua.

## Fase 6 — Medir valor real (contínuo, a partir de dez)

MIT NANDA: 95% sem retorno mensurável no P&L. IDC: 0% com autonomia total com guardrails.

- [ ] Registrar toda ação que mudou decisão ou economizou tempo em state/valor-real.md
- [ ] Revisão mensal: se valor-real.md tiver menos de três entradas, o sistema está organizando, não agindo
- [ ] Três meses de dados antes de qualquer expansão de escopo

Critério de saída: valor mensurável documentado, não impressionante.

## Anti-padrões (valem pra todas as fases)

- Não rebaixar critério pra passar (REGRA-VERIFICACAO)
- Não tratar falha honesta como fracasso
- Não expandir escopo antes de fechar o ciclo atual
- Não adicionar automação sem eval correspondente
- Três dias seguidos só organizando dispara alarme (REGRA-VERIFICACAO-HUMANA)
