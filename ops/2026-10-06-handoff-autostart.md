# HANDOFF GROK→NEXO
Atualizado: 2026-10-06. Nexo sem cota. Correcao feita no repo, nao no box.

Correcao: ops/boot/nexo-up-autostart.sh nao instala nada sem o argumento APPLY e sem NEXO_RUN_USER. A versao anterior habilitava unit de sistema como root e gravava copia do crontab em /tmp.

Nao mexer: DNS, Override, ACL, ShieldsUp, sshd, chaves, resolv.conf do terminal Android.

Box, dispositivo Android e painel VPN nao foram medidos nesta sessao. Conteudo dos checklists grandes nao foi lido: o conector nao devolve o corpo do arquivo.
