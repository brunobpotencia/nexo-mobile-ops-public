# Plano de resposta a incidente — Meridian

## Se token ou senha vazar
1. Revogar em github.com/settings/tokens em menos de 5 minutos.
2. Revogar OAuth em github.com/settings/applications.
3. Rodar ops/boot/oauth-check.sh e reportar.
4. Trocar senha do Google e ativar 2FA se ainda não.
5. Abrir issue BRU-5 com timeline.

## Se push suspeito em main
1. git revert do commit.
2. Bloquear o autor: gh api -X PUT repos/.../collaborators/{user}/permission -f permission=none.
3. Auditar git log --all --oneline desde o incidente.

## Contatos
- GitHub Support: https://github.com/contact
- Google Account Recovery: https://accounts.google.com/signin/recovery
