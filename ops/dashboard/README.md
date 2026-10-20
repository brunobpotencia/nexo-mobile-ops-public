# Dashboard de segurança da casa do Bruno (somente leitura)

Gera um **PNG de 1200 px de largura** (dá para ler no celular), mais um resumo JSON, com o estado **ao vivo** de:
VPN, AdGuard Home, dispositivo Android, o computador do Nexo (nexo-box) e as pendências do último relatório de auditoria do dispositivo Android.

**Regra principal:** nenhum valor é inventado. Tudo vem de uma checagem feita na hora da geração.
Se uma checagem falha ou não existe, o painel mostra **"indisponível — motivo"** e lista o item em "Checagens indisponíveis".
O painel não mostra senhas nem chaves privadas. Das chaves SSH aparecem só as opções, o tipo e o fingerprint.

## Como rodar
```bash
/home/box/agent-data/nexo/ops/dashboard/dashboard.sh                 # coleta + PNG + JSON (~10–40 s)
DASH_NO_ANDROID=1 /home/box/agent-data/nexo/ops/dashboard/dashboard.sh # sem SSH no dispositivo Android (o netmon também pula o dispositivo Android)
```
- **Código de saída:** 0 = PNG gerado; 2 = coleta feita mas PNG falhou (o JSON é gravado mesmo assim, com `render_error`); 1 = outra geração em andamento.
- **Na tela:** imprime o nível geral, os alertas e as checagens indisponíveis.
- **Agendamento:** nenhum. O painel só roda quando chamado.

## Arquivos
| Caminho | O que é |
|---|---|
| `dashboard.sh` | ponto de entrada (trava contra execuções simultâneas, TZ America/Sao_Paulo) |
| `dashboard.py` | coleta, análise, HTML e PNG (Python 3 + Pillow, renderiza com `google-chrome --headless`) |
| `out/dashboard-latest.png` | último painel |
| `out/dashboard-AAAAMMDD-HHMMSS.png` | cópias com data e hora. Ficam só as **14** mais recentes |
| `out/dashboard-latest.json` | resumo: `overall`, `alerts[]` (level/section/text/source), `sections{}` (status + números-chave), `unavailable[]`, `pendencias_relatorio[]` |
| `out/dashboard-latest.html` | HTML que gerou o PNG (útil para depurar) |

**Cores:** vermelho = crítico, âmbar = atenção, verde = ok, azul = informativo. Uma seção fica "INDISPONÍVEL" quando a checagem principal dela falhou.

## O que cada seção mostra e de onde vem
### Alertas (topo)
- **Fonte `netmon`:** os alertas do `../netmon/netmon.sh --json` (o painel reaproveita todas as verificações do netmon). `[ALERTA]` → vermelho, `[HEURÍSTICA]` → âmbar, `[INFO]` → azul.
  O painel roda o netmon com `NETMON_NO_APT_UPDATE=1`, ou seja, **nunca** roda `apt update` no telefone.
- **Fonte `dashboard`:** checagens extras do painel. Os limites são estes:

| Condição | Nível |
|---|---|
| dispositivo Android offline na rede VPN | âmbar |
| aviso de saúde do VPN (`Health`) | âmbar |
| DNS global da rede VPN sem <VPN_IP_PC> | vermelho |
| AdGuard parado | vermelho |
| proteção do AdGuard desligada | vermelho |
| dispositivo Android online, mas 0 consultas no AdGuard na última hora | âmbar |
| sshd do dispositivo Android com `PasswordAuthentication` diferente de `no` | vermelho |
| `KbdInteractive`, `AllowTcpForwarding` ou `AllowAgentForwarding` diferente de `no` | âmbar |
| sshd escutando em 0.0.0.0 ou [::] | âmbar |
| chave em `authorized_keys` sem `from=`/`restrict` | âmbar |
| número de chaves diferente de 1 | âmbar |
| pacotes terminal Android pendentes > 0 | âmbar |
| patch Android com mais de 60 dias | âmbar |
| patch Android com mais de 120 dias | vermelho |
| disco do box ≥ 85% | âmbar |
| disco do box ≥ 95% | vermelho |
| memória disponível < 10% | âmbar |
| memória disponível < 5% | vermelho |
| carga de 5 min > 2× nº de CPUs | âmbar |

### VPN
| Campo | Fonte |
|---|---|
| estado, versão, rede VPN, MagicDNS, dispositivos (online, IP, SO, direta/relay, último handshake ou "visto por último") | `vpn --socket=/home/box/.local/run/vpnd.sock status --json` |
| DNS global, DNS dividido, DNS do sistema | `vpn … dns status --json` (configuração que o servidor de coordenação entrega a este nó) |
| "Use VPN DNS" neste computador | `vpn … debug prefs` → `CorpDNS`. Só campos inofensivos são lidos; o bloco `Config` com chaves é descartado |
| "Override local DNS" | **não é exposto** pela CLI local, por isso aparece como tal |

### AdGuard DNS
A API é `http://<VPN_IP_PC>:3000`. A senha é lida de `../secrets/adguard-admin.txt` e vai **só** no cabeçalho HTTP do Python, nunca na linha de comando.

| Campo | Fonte |
|---|---|
| rodando, versão, proteção, "ativo desde" | `/control/status` (`running`, `protection_enabled`, `start_time`) |
| consultas, bloqueadas, %, mais bloqueados, clientes | `/control/stats`. A janela vem de `/control/stats/config` (hoje 24 h) |
| dispositivo Android: consultas e bloqueios na última hora, última consulta | `/control/querylog?search=<ANON_CLIENT_ANDROID>`, paginado com `older_than` até passar de 1 h (no máximo 10 páginas de 500), filtrando `client == <ANON_CLIENT_ANDROID>` |

O IP de cliente é anonimizado (`anonymize_client_ip`, em `/control/querylog/config`). Por isso `<ANON_CLIENT_ANDROID>` = faixa do dispositivo Android e `<ANON_CLIENT_PC>` = faixa do box.

### dispositivo Android (SSH somente leitura)
Conexão: `ssh -i ~/.ssh/nexo_box_to_android -p 8022 -o BatchMode=yes -o ConnectTimeout=8 <ANDROID_USER>@<VPN_IP_ANDROID>`.

| Campo | Fonte |
|---|---|
| patch, Android, modelo | `getprop ro.build.version.security_patch`, `getprop ro.build.version.release`, `getprop ro.product.model` |
| ligado há | `uptime` |
| sshd | `sshd -T` (configuração efetiva): porta, ListenAddress, senha, kbd-interactive, pubkey, forwarding TCP/agente, X11, MaxAuthTries |
| authorized_keys | opções + tipo (a chave é cortada no próprio telefone com `sed`) + fingerprint (`ssh-keygen -lf`) |
| pacotes pendentes | `apt list --upgradable`, que usa as listas **locais** do telefone. A data delas vem de `stat` em `$PREFIX/var/lib/apt/lists/*_Packages`. O painel **não** roda `apt update` |
| bateria | `termux-battery-status`, se existir |
| rede e nº de apps de terceiros | snapshot do netmon (`ifconfig` e `pm list packages -3`) |

### Meu computador (nexo-box)
| Campo | Fonte |
|---|---|
| VPN, firewall (regra `-i vpn0 -j nexo-ts-guard` no topo do INPUT em iptables e ip6tables, portas liberadas, DROP final), processo do AdGuard (PID de `/run/adguardhome.pid`, binário, portas em escuta), teste DNS (example.com resolve, doubleclick.net = 0.0.0.0) | snapshot do netmon (`sudo -n iptables -S`, `ss -tulnp`, `dig`) |
| disco | `shutil.disk_usage('/')`, mesmo critério do `df` |
| memória | `/proc/meminfo` (MemAvailable) |
| carga | `/proc/loadavg` |
| ligado há | `/proc/uptime` |

O painel **não** reaplica o firewall (`nexo-ts-guard.sh`).

### Pendências da auditoria
- **Fonte:** o relatório `*-auditoria-android.md` mais recente em `/home/box/agent-data/nexo/ops/`. Hoje é o `2026-10-04-auditoria-android.md`.
- **O que é extraído:** os itens da seção "6. Riscos priorizados" (severidade, título, ação sugerida) e as linhas com "falta conferir".
- **Rótulo:** todos os itens vêm marcados como **"do relatório de DD/MM/AAAA"**.
- **Checagem ao vivo:** onde dá, o item ganha uma checagem feita agora, marcada "ao vivo":

| Item do relatório | Checagem ao vivo |
|---|---|
| terminal Android desatualizado | nº de pacotes pendentes |
| chave/forwarding | opções do `authorized_keys`, `AllowTcp/AgentForwarding` e se a chave do box tem passphrase (`ssh-keygen -y -P ''` local, saída descartada) |
| escuta em todas as interfaces | `ListenAddress` |
| patch | `getprop` |
| "Use VPN DNS" | consultas do dispositivo Android no AdGuard na última hora. É só um **indício**, não uma leitura da configuração do app |

- **Sem checagem pelo shell** (configurações do Android, permissões, sessões): ficam "pendente (verificação manual)".

## Limitações
- **Mapeamento das pendências:** a ligação entre os itens do relatório e as checagens ao vivo é feita por palavras-chave do título ("desatualizad", "chave ssh|forwarding", "todas as interfaces", "patch"). Um relatório novo com títulos diferentes fica sem checagem ao vivo, mas continua aparecendo.
- **O netmon roda de verdade:** gera log e atualiza `netmon/state/last.json`. As métricas "desde a última execução" do netmon passam a contar a partir do painel.
- **Alertas que dependem da baseline:** por exemplo "cliente DNS novo". Eles continuam até alguém rodar `netmon.sh --rebaseline` **manualmente**. O painel nunca faz isso.
- **Pacotes pendentes do dispositivo Android:** refletem as listas apt locais do telefone (a data aparece no painel). Uma lista velha pode esconder atualizações.
- **Override e configurações do app:** o "Override local DNS" da rede VPN e o "Use VPN DNS" do app Android não são legíveis por aqui.
- **Bateria:** precisa do `termux-api` (app + pacote), que não está instalado. Por isso aparece "indisponível".
- **Android sem root:** as portas em escuta, o gateway e as configurações do Android não são visíveis (ver `../netmon/README.md` e o relatório).
- **IP anonimizado no AdGuard:** a contagem por cliente é por faixa /16, não por aparelho.
- **Aviso de saúde do VPN sobre `connmark`:** é uma limitação do kernel/iptables deste box. Aparece em âmbar enquanto o VPN o reportar.
- **Renderização:** depende do `google-chrome` (ou `chromium`) headless e da fonte Noto Sans. Se o Chrome falhar, o JSON é gravado e o código de saída é 2.
