# REGRA-VERIFICACAO-HUMANA

Regra de supervisão humana do Meridian. Escrita por Bruno, para Bruno.
Complementa state/REGRA-VERIFICACAO.md (anti-fantasma para o agente) com a camada que só um humano pode fazer: julgar se o output é real.

## Por que existe

A REGRA-VERIFICACAO impede o Meridian de inventar. Mas um sistema que só relata falha com honestidade ainda pode ser inútil: falha honesta não é entrega. Esta regra define quando e como o Bruno verifica se o Meridian produziu algo verificável de verdade.

## Checklist diário (5 minutos)

Roda de manhã, depois do pico das 08:00 e antes do forwarding das 09:30. Ou no fim do dia, se a manhã não der.

1. **Lê o relatório do pico.** Procura a palavra "falha" ou "não li". Se tiver, anota o arquivo e o endpoint citados — isso é a próxima tarefa de engenharia, com alvo preciso.
2. **Lê o destilado mais recente** em state/ ou no diretório de destilados. Teste honesto: se lesses sem saber quem escreveu, aprenderias algo novo e acionável? Se não, não conta como entrega.
3. **Confere uma fonte do fontes.md** ao acaso. Abre a URL e verifica se o conteúdo bate com o que o Meridian citou. Se não bater, é regressão da REGRA-VERIFICACAO.
4. **Olha o diff do dia** em main. Uma linha: o que mudou e por quê.
5. **Responde uma pergunta só:** o Meridian agiu ou só se organizou hoje?

## Regra de ouro

Se o checklist inteiro passar e a resposta da pergunta 5 for "só se organizou" por três dias seguidos, o Meridian não está entregando. Aí a correção não é forçar output — é isolar a falha mais barata (permissão, conector, script) e corrigir essa.

## Anti-padrões

- Não aceitar "limpo" ou "zero alertas" sem evidência de leitura bem-sucedida (isso já é a REGRA-VERIFICACAO, repetido aqui pra fechamento).
- Não rebaixar o critério de sucesso pra o sistema "passar".
- Não tratar relatório de falha honesto como fracasso do Meridian — é sucesso da especificação.
- Não pular o checklist porque "tá rodando sozinho". Rodar sozinho sem supervisão humana é exatamente o modo que produz museu de scripts.

## Histórico

- 2026-10-19: criada após auditoria completa do Meridian. Primeiro checklist: pico falhou na leitura, eval falhou nos destilados, logs-watch sem Vercel, cap noite sem snapshot.