# REGRA DE VERIFICAÇÃO — anti-fantasma

Toda referência a arquivo, fonte, URL, config ou ferramenta deve ser verificada antes de ser citada como existente.

## Regras

1. Se uma leitura falhar (404, timeout, erro de permissão, conector sem ferramenta de blob): o output diz "não consegui ler" com o motivo. Nunca inventa conteúdo, nome de seção, contagem de linhas ou estrutura.
2. Se um arquivo é referenciado por prompt ou documentação mas não aparece na árvore do repo: ele é reportado como AUSENTE. A documentação é corrigida ou o arquivo é criado — uma das duas, nunca as duas ao mesmo tempo sem declarar.
3. Contagens (arquivos, linhas, tamanho) só são afirmadas quando vieram de uma leitura real: API de árvore, diff de commit, ou comando local.
4. "Provável", "deve ter", "tipicamente" são proibidos em output factual. Se a certeza for menor que alta, o output diz a incerteza explicitamente.
5. REGRA 0 (não peça o checável) não se aplica a falhas de leitura. Uma falha de leitura É checável pelo próprio sistema e deve ser reportada, não mascarada.

## Exemplos

- Certo: "fontes.md não aparece na árvore; o prompt que o cita está desatualizado."
- Errado: "fontes.md tem dez URLs validadas" sem ter lido o arquivo.
- Certo: "a API retornou 404 no raw.githubusercontent.com; não tenho como ler blob de repo privado."
- Errado: preencher o que o arquivo "deveria" conter.

## Por que existe

Em setembro de 2026 o Meridian citava fontes.md, state.fonte e priorities.md como existentes quando não estavam versionados. A REGRA 0 silenciou a dúvida em vez de surfacer a falha. Esta regra fecha essa lacuna: proibição de mentira no output + obrigação de reportar falha na leitura.