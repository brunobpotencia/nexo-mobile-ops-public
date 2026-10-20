# Política de token GitHub

## Por que
O conector GitHub autenticado via OAuth não tem escopos security_events e notifications. Isso bloqueia leitura de alertas Dependabot e marcação de notificações.

## Como criar o PAT
1. Abre https://github.com/settings/tokens
2. Generate new token (classic)
3. Escopos: repo (completo), security_events, notifications, workflow
4. Expira em 90 dias
5. Cola o token nas configurações do conector GitHub em grok.com/settings/connectors como credencial manual

## Cuidados
- Nunca commitar o token no repo
- Revogar em github.com/settings/tokens se vazar
- Preferir fine-grained token com acesso só a <OWNER>/<REPO> se quiser escopo mínimo
- O token local no box (gh auth) já cobre as automações meridian-secret-scan e meridian-dependabot-watch

## Alternativa sem token
- Reconectar o OAuth em grok.com/settings/connectors pedindo escopos adicionais
- Aceitar que Dependabot alerts fiquem no navegador: github.com/<OWNER>/<REPO>/security/dependabot
