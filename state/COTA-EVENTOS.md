# state/meridian-quota-events.jsonl

Append-only, uma linha JSON por execução (contrato: meridian-painel/DATA-CONTRACT.md).

- Criado vazio em 21/10/2026: não existe medição real de tokens do Grok por execução do Meridian (o CSV de grok.com/dashboard/usage não separa automação/agente). Nenhuma linha foi inventada.
- A main exige pull request, então workflows não fazem commit aqui. O workflow `.github/workflows/meridian-ciclo.yml` (botão Rodar ciclo) registra cada execução no próprio run do GitHub Actions (job summary + histórico de runs), com tokens Grok = 0 por construção (não chama o Grok).
- Nunca editar nem apagar linhas antigas.
