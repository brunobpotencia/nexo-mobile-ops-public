# netmon — monitor de rede do Nexo (somente leitura)

Script: `~/nexo/ops/netmon/netmon.sh` (bash; usa `jq`, `dig`, `ss`, `curl`, `sudo -n`, `ssh`).

```bash
~/nexo/ops/netmon/netmon.sh               # saída vazia = tudo normal
~/nexo/ops/netmon/netmon.sh --verbose     # + resumo completo de cada verificação
~/nexo/ops/netmon/netmon.sh --rebaseline  # aceita o estado atual como novo "normal"
```

Termina com código 0. Se algo falhar, termina com código **2** e uma linha `[ERRO]` (veja "Gravação segura do estado"). Só imprime mudanças/alertas, com as etiquetas `[ALERTA]`, `[HEURÍSTICA]` e `[INFO]`.
**Não** altera firewall, DNS, AdGuard nem o telefone. A única ação com efeito no dispositivo Android é
`apt update` (só atualiza as listas de pacotes do terminal Android), no máximo 1x por dia. Para desligar: `NETMON_NO_APT_UPDATE=1`.
Para pular o dispositivo Android: `NETMON_NO_ANDROID=1`. Não existe rotina agendada: ele só roda quando chamado.

## Arquivos
| Caminho | Conteúdo |
|---|---|
| `baseline.json` | estado "normal" de referência (criado na 1ª execução ou com `--rebaseline`) |
| `state/last.json` | última foto completa (usada para mudanças entre uma execução e a seguinte, como online/offline e a contagem do AdGuard) |
| `state/baseline.prev.json` | baseline anterior (guardada a cada `--rebaseline`) |
| `state/android_apt_update.date` | dia do último `apt update` no dispositivo Android |
| `state/last.json.invalid-*`, `state/baseline.invalid-*.json` | cópias de arquivos de estado corrompidos encontrados (só aparecem se isso acontecer) |
| `logs/AAAA-MM-DD.log` | resumo de cada execução + alertas (sempre, mesmo quando a tela fica vazia) |

Nenhum arquivo guarda senha. A senha do AdGuard é lida de `../secrets/adguard-admin.txt` e passada ao curl pela entrada padrão (`-K -`), por isso não aparece na lista de processos nem nos logs.

## Verificações

### 1. Saúde do box
- VPN `Running`, nó `servidor` com IP `<VPN_IP_PC>`.
- Firewall: a 1ª regra `-A` do INPUT em **iptables e ip6tables** tem de ser `-A INPUT -i vpn0 -j nexo-ts-guard`. A cadeia `nexo-ts-guard` e o INPUT inteiro são comparados com a baseline.
  Se algo mudar, o script avisa e mostra o comando para reaplicar: `sh ~/nexo/ops/nexo-ts-guard.sh`. **Ele nunca roda esse comando sozinho.**
- AdGuard Home: o pid de `/run/adguardhome.pid` tem de estar vivo, o binário tem de ser `/opt/AdGuardHome/AdGuardHome` e ele só pode escutar em
  `<VPN_IP_PC>:53` (tcp+udp) e `<VPN_IP_PC>:3000`. Também alerta se outro processo ocupar a porta 53 ou 3000.
- DNS: `dig @<VPN_IP_PC> example.com` tem de resolver para um IPv4 real, e `doubleclick.net` tem de voltar `0.0.0.0`.

### 2. Dispositivos da rede VPN
Lista os peers com nome, IP, SO, se estão online e o tipo de conexão (direta ou relay/DERP). Alertas:
- dispositivo novo ou desconhecido (fora da baseline), dispositivo removido, ou mudança de IP/SO (comparado com a baseline);
- `android-device` ficou ONLINE ou OFFLINE (comparado com a execução anterior).
- A troca direta↔relay só vai para o log/resumo e não gera alerta, porque o VPN troca sozinho quando a conexão fica ociosa.

### 3. AdGuard DNS (API em `http://<VPN_IP_PC>:3000`)
- Usa `/control/stats` (janela de 24 h) e `/control/querylog?limit=500`.
- No log/resumo: consultas e bloqueios desde a última execução, os domínios mais bloqueados e os clientes. As consultas de teste do próprio netmon (`example.com` e `doubleclick.net` vindas do box) não entram na conta.
- Alerta de **cliente DNS novo** (fora da baseline).
- Alerta de **pico**: taxa por hora acima de 3× a baseline. Há pisos mínimos (30 consultas/h e 10 bloqueios/h, além de ≥50 consultas ou ≥20 bloqueios na janela) para não disparar com volumes muito baixos.
- `[HEURÍSTICA]` consultas a DNS dinâmico, túneis e stalkerware conhecidos (duckdns, no-ip, ddns.net, hopto, zapto, dynu, afraid, ngrok*, trycloudflare, serveo, mSpy, FlexiSpy, Hoverwatch etc.). Isso é **só um indício**: pode ser uso legítimo.

### 4. dispositivo Android via SSH (`ssh -i ~/.ssh/id_ed25519_android -p 8022 <VPN_IP_ANDROID>`, BatchMode, timeout de 10 s)
Usa uma única conexão. Se falhar, tenta de novo **uma** vez (só em erro de conexão) e então mostra `dispositivo Android offline/inacessível`.
Coleta: sha256 de `~/.ssh/authorized_keys` e de `$PREFIX/etc/ssh/sshd_config`, se o sshd está rodando, portas em escuta,
interfaces/IPs (`ifconfig`), tipo de rede (`wlan*` = wifi; `rmnet*`/`ccmni*`/`seth_lte*` = dados móveis), quantos pacotes do terminal Android têm atualização
(`apt list --upgradable`) e a lista e o hash dos apps de terceiros (`pm list packages -3`).
- Comparados com a **baseline**, com alerta até você rodar `--rebaseline`: hashes, portas, lista de apps (mostra quais entraram e quais saíram) e interfaces fora do padrão (VPN/túnel extra).
- Comparados com a **execução anterior**, como `[INFO]`: tipo de rede e número de pacotes atualizáveis. O IP de dados móveis muda o tempo todo (CGNAT), então não gera alerta.

### 5. Wi-Fi de casa (só quando o dispositivo Android está em `wlan*`)
- Registra a interface, o IP e a sub-rede (calculada pelo `ifconfig`). O gateway só aparece se `ip route` ou `getprop dhcp.wlan0.gateway` responderem; caso contrário fica "ilegível", com o palpite `.1` se esse endereço responder.
- O SSID só é lido se o `termux-api` estiver instalado, e ele **não** é instalado pelo script.
- Descobre aparelhos na rede com `nmap -sn -n --unprivileged` (só para sub-redes /22 ou menores). Sem root, isso é um "ping" por conexão TCP nas portas 21, 22, 53, 80, 443, 445, 554, 631, 5000, 7000, 8008, 8080, 8443, 9100 e 62078.
- A 1ª vez que o Wi-Fi aparece, a lista vira a baseline automaticamente. Depois disso, há alerta para **IP novo** na rede e para troca de gateway. Se a sub-rede for diferente da de casa, ele só avisa que é outra rede e não compara os aparelhos.

## Como refazer a baseline
Depois de uma mudança legítima (app instalado, sshd endurecido, aparelho novo na rede VPN ou no Wi-Fi):
```bash
~/nexo/ops/netmon/netmon.sh --rebaseline
```
Partes que não puderem ser coletadas na hora (dispositivo Android offline, ou dispositivo Android fora do Wi-Fi) **mantêm** a baseline anterior.
Se não houver baseline para o dispositivo Android, o Wi-Fi ou o AdGuard, ela é criada automaticamente na 1ª coleta boa, com um aviso `[INFO]`.

## Limites conhecidos
- **Portas do dispositivo Android:** o Android bloqueia `/proc/net` sem root (`netstat: no support for AF INET`) e o `ss` não existe no terminal Android. Por isso a lista de portas fica vazia e "sem permissão". Esse item só detecta mudança se o acesso mudar.
- **`ip` não existe** no terminal Android deste aparelho, e `/proc/net/route` e `/proc/net/arp` estão bloqueados. Sem root não dá para ver o gateway nem o MAC/fabricante dos aparelhos da LAN.
- **nmap sem root:** aparelhos que não respondem em nenhuma das portas testadas (celulares em repouso, por exemplo) **não aparecem**. Como o DHCP muda IPs, um aparelho conhecido pode aparecer como "novo". Sem MAC não dá para distinguir esses casos.
- **AdGuard com `anonymize_client_ip: true`:** o cliente aparece só como /16 (ex.: `<ANON_CLIENT_PC>`, `<ANON_CLIENT_ANDROID>`). "Cliente novo" é, então, uma faixa nova, não um aparelho específico.
- O querylog é lido no máximo em 500 linhas por execução. Acima disso a contagem é parcial (`[INFO]`).
- A lista suspeita é pequena e heurística: não substitui um antivírus nem uma auditoria do aparelho.
- Itens comparados com a baseline continuam alertando a cada execução até o `--rebaseline`. Isso é proposital, para alertas de segurança não sumirem.
- O teste DNS usa a rede real (upstreams 1.1.1.1/1.0.0.1). Uma queda de internet do box aparece como falha de `example.com`.

## Saída JSON (`--json`, adicionada em DD/MM/AAAA para o dashboard)
```bash
NETMON_NO_APT_UPDATE=1 ~/nexo/ops/netmon/netmon.sh --json
```
Faz exatamente a mesma coleta, comparação, log e atualização de `state/last.json` de uma execução normal, mas em vez do texto imprime
**um** objeto JSON: `{ok, snapshot, alerts:[{level,text}], summary:[...], baseline_file, log_file}` (`level` = `ALERTA`, `HEURÍSTICA` ou `INFO`).
Em caso de trava ocupada imprime `{"ok":false,"error":"..."}`. É usado por `../dashboard/dashboard.sh`.
Como é uma execução normal, as contagens "desde a última execução" e os alertas de online/offline passam a contar a partir dela.
Backup do script antes desta mudança: `netmon.sh.bak-AAAAMMDD-antes-json`.

## Gravação segura do estado (DD/MM/AAAA)
Motivo: em 04/10 o querylog do AdGuard passou de 128 KB e estourou o limite de argumento do `jq --argjson`. O script seguiu sem perceber,
gravou `state/last.json` e depois `baseline.json` com 1 byte e ainda imprimiu "Baseline regravada".
- **Escrita atômica e validada:** `baseline.json`, `state/baseline.prev.json`, `state/last.json` e `state/android_apt_update.date` são escritos primeiro num temporário
  (`.<nome>.tmp.XXXXXX`) no mesmo diretório. O temporário só vai para o lugar com `mv` se o comando terminou com rc 0 e o conteúdo é um objeto JSON válido e
  não vazio (`jq -e 'type == "object"'`; para a data, `AAAA-MM-DD`).
- **Tudo ou nada:** nada é gravado até coleta, snapshot, comparação e resumo terminarem bem. Só então todos os arquivos são movidos.
- **Em falha:** os arquivos antigos ficam intactos, os temporários são apagados, aparece uma linha `[ERRO] …` e o script sai com código 2. Com `--json`, a saída é `{"ok":false,"error":…}`
  e o `[ERRO]` vai para o stderr, então o dashboard mostra "netmon indisponível". A falha também é registrada no log do dia.
- **`--rebaseline`:** só imprime "Baseline regravada" depois que o `baseline.json` novo foi movido e conferido.
- **Arquivos corrompidos:** um `baseline.json` inválido ou vazio faz a execução normal **abortar** (`[ERRO]`), para não aceitar o estado atual como "normal" sem ninguém ver.
  Para resolver, restaure `state/baseline.prev.json` ou rode `--rebaseline`; o inválido é guardado em `state/baseline.invalid-*.json`. Um `state/last.json` inválido é guardado de lado,
  ignorado com `[INFO]` e regravado.
- **Sem dados grandes em argumentos:** querylog, stats, snapshot, baseline, last, regras de firewall, listas do dispositivo Android e saída de texto entram no `jq` por arquivo
  (`--slurpfile` / `--rawfile`). Em `--arg`/`--argjson` só passam valores pequenos.
- **AdGuard e dispositivo Android degradam sem abortar:** se o processamento da resposta deles falhar, a execução segue com `[ALERTA] AdGuard API inacessível (…)` ou `dispositivo Android … (falha ao processar …)`.
- **Teste de falha:** foi feito numa cópia do script em `/tmp`, com `BASE` trocado e um `jq` falso no PATH que falha ou devolve lixo numa chamada específica.
  Em todos os casos o `baseline.json` e o `state/` ficaram iguais e não sobrou temporário.
- Backups do script: `netmon.sh.bak-AAAAMMDD-antes-argmax` e `netmon.sh.bak-AAAAMMDD-antes-atomic`.
