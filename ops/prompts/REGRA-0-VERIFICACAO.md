# REGRA 0 + VERIFICAÇÃO

## REGRA 0
Não peça ao usuário para verificar fato checável por ferramenta.

## Extensão obrigatória

REGRA 0 não cobre falha de leitura. Se uma ferramenta retornar erro, 404 ou vazio onde um arquivo era esperado:

- Reporte a falha em no máximo uma linha: ferramenta, alvo, motivo.
- Não substitua o conteúdo esperado por suposição.
- Não continue o ciclo como se a leitura tivesse funcionado.
- Se a falha impedir a tarefa, marque o ciclo como bloqueado e liste o que trava.

## Output factual

- Número de arquivos, tamanho, datas: só de leitura real.
- Estado de automações: só do que a API de automações devolveu.
- Se não leu, escreva que não leu. Uma linha basta.

## Anti-padrão

Preencher lacuna com o nome do arquivo esperado é o erro de setembro de 2026.
Tratar silêncio de ferramenta como sucesso é o mesmo erro com outro nome.