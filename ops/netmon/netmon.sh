#!/usr/bin/env bash
# netmon.sh — monitor de rede SOMENTE LEITURA do Nexo (box servidor + dispositivo Android + Wi-Fi de casa).
# Saída vazia = tudo normal. Só imprime mudanças/alertas. Sai com 0; sai com 2 (e uma linha [ERRO]) se a coleta/
# comparação falhar ou se não der para gravar o estado com segurança — nesse caso baseline.json/state/* NÃO são tocados.
# Toda gravação de estado é atômica: temporário no mesmo diretório -> jq rc 0 -> JSON objeto válido e não vazio -> mv.
# Uso: netmon.sh [--rebaseline] [--verbose] [--json]
#   --rebaseline  grava um novo baseline.json a partir da coleta atual
#   --verbose     também imprime o resumo completo de cada verificação
#   --json        imprime UM objeto JSON (snapshot + alertas + resumo) em vez do texto (usado pelo dashboard)
# Variáveis: NETMON_NO_APT_UPDATE=1  -> nunca roda 'apt update' no dispositivo Android
#            NETMON_TEST_RAW=arquivo -> (testes) usa saída simulada do dispositivo Android em vez de SSH
#            NETMON_NO_ANDROID=1       -> pula SSH no dispositivo Android (verificações 4 e 5)
# NUNCA altera firewall/DNS/telefone. Nunca imprime segredos.

set -u -o pipefail
umask 077
export LC_ALL=C

BASE="${NEXO_OPS:-$HOME/nexo/ops}/netmon"
BASELINE="$BASE/baseline.json"
STATE="$BASE/state"
LAST="$STATE/last.json"
LOGDIR="$BASE/logs"
SECRET_FILE="${NEXO_OPS:-$HOME/nexo/ops}/secrets/adguard-admin.txt"
GUARD_SCRIPT="${NEXO_OPS:-$HOME/nexo/ops}/nexo-ts-guard.sh"
TS_SOCK="$HOME/.local/run/vpnd.sock"
BOX_IP="${VPN_IP_PC:-<VPN_IP_PC>}"
BOX_NAME="servidor"
AGH_URL="http://$BOX_IP:3000"
ANDROID_IP="${VPN_IP_ANDROID:-<VPN_IP_ANDROID>}"
ANDROID_KEY="$HOME/.ssh/id_ed25519_android"
ANDROID_PEER="android-device"

REBASE=0; VERBOSE=0; JSON=0
for a in "$@"; do
  case "$a" in
    --rebaseline) REBASE=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    --json) JSON=1 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "Opção desconhecida: $a (use --rebaseline, --verbose ou --json)"; exit 0 ;;
  esac
done

mkdir -p "$STATE" "$LOGDIR"
TMP=$(mktemp -d /tmp/netmon.XXXXXX)
STAGED=()   # gravações preparadas e validadas, ainda não movidas: "temporário|destino"
cleanup() { local p; for p in "${STAGED[@]}"; do rm -f "${p%%|*}"; done; rm -rf "$TMP"; }
trap cleanup EXIT

# Falha: mantém todos os arquivos de estado antigos, imprime [ERRO] e sai com código 2.
die() {
  local msg="$1"
  if [ "${JSON:-0}" = 1 ]; then
    jq -n --arg e "$msg" '{ok:false,error:$e}' 2>/dev/null || echo '{"ok":false,"error":"netmon: erro interno"}'
    echo "[ERRO] $msg" >&2
  else
    echo "[ERRO] $msg"
  fi
  [ -n "${LOG:-}" ] && echo "=== ${NOW_ISO:-$(date '+%Y-%m-%dT%H:%M:%S%z')} [ERRO] $msg (estado não alterado)" >>"$LOG" 2>/dev/null
  exit 2
}
# arquivo existe, não é vazio e é um objeto JSON válido
valid_json_file() { [ -s "$1" ] && jq -e 'type == "object"' "$1" >/dev/null 2>&1; }
# stage_json DESTINO comando [args...]: grava a saída do comando num temporário ao lado do destino, confere
# rc == 0 e JSON válido/não vazio. Não move ainda (ver commit_staged). Caminho do temporário em $STAGED_PATH.
stage_json() {
  local dest=$1 tmp rc; shift
  tmp=$(mktemp "$(dirname "$dest")/.$(basename "$dest").tmp.XXXXXX") || die "não foi possível criar temporário para $dest; nada gravado"
  STAGED+=("$tmp|$dest")
  "$@" >"$tmp" 2>"$TMP/stage.err"; rc=$?
  [ $rc -eq 0 ] || die "falha ao gerar $dest (rc=$rc: $(head -c 200 "$TMP/stage.err" | tr '\n' ' ')); arquivo antigo mantido"
  valid_json_file "$tmp" || die "conteúdo gerado para $dest não é JSON válido ou está vazio; arquivo antigo mantido"
  STAGED_PATH=$tmp
}
unstage() { # $1 = temporário a descartar
  local p keep=()
  for p in "${STAGED[@]}"; do if [ "${p%%|*}" = "$1" ]; then rm -f "$1"; else keep+=("$p"); fi; done
  STAGED=("${keep[@]}")
}
# move todos os temporários validados para o lugar (rename atômico no mesmo diretório)
commit_staged() {
  local p tmp dest
  for p in "${STAGED[@]}"; do
    tmp=${p%%|*}; dest=${p#*|}
    valid_json_file "$tmp" || die "temporário de $dest sumiu ou ficou inválido; arquivo antigo mantido"
    chmod 600 "$tmp" 2>/dev/null
    mv -f "$tmp" "$dest" || die "mv para $dest falhou; arquivo antigo mantido"
  done
  STAGED=()
}

# trava contra execuções simultâneas
exec 9>"$STATE/.lock"
if ! flock -w 120 9; then
  if [ "$JSON" = 1 ]; then echo '{"ok":false,"error":"outra execução do netmon está rodando; abortado."}'
  else echo "[ERRO] outra execução do netmon está rodando; abortado."; fi
  exit 0
fi

NOW_EPOCH=$(date +%s)
NOW_ISO=$(date '+%Y-%m-%dT%H:%M:%S%z')
TODAY=$(date +%F)
LOG="$LOGDIR/$TODAY.log"

S() { sudo -n "$@"; }
jstr() { jq -Rs 'rtrimstr("\n")'; }   # stdin -> string JSON
jlines() { jq -R . | jq -s 'map(select(length>0))'; }  # stdin -> array JSON

# state/last.json: só é usado se for JSON válido. Se estiver corrompido, é guardado de lado e ignorado
# (a execução segue como se fosse a primeira "desde a última"); será regravado de forma atômica no fim.
LAST_EPOCH=0
LASTF="$TMP/last-null.json"; echo null >"$LASTF"
PRENOTES=""
if valid_json_file "$LAST"; then
  LASTF="$LAST"
  LAST_EPOCH=$(jq -r '.epoch // 0 | tonumber? // 0 | floor' "$LAST" 2>/dev/null)
  [[ "$LAST_EPOCH" =~ ^[0-9]+$ ]] || LAST_EPOCH=0
elif [ -e "$LAST" ]; then
  cp -p "$LAST" "$STATE/last.json.invalid-$(date +%Y%m%d-%H%M%S)" 2>/dev/null
  PRENOTES="[INFO] state/last.json estava inválido/vazio; ignorado (cópia em state/last.json.invalid-*) e será regravado."
fi

########################################################################
# 1. Saúde do box
########################################################################
collect_vpn() {
  local out rc
  out=$(timeout 20 sudo -n vpn --socket="$TS_SOCK" status --json 2>"$TMP/ts.err"); rc=$?
  if [ $rc -ne 0 ] || ! jq -e . >/dev/null 2>&1 <<<"$out"; then
    jq -n --arg e "rc=$rc $(head -c 300 "$TMP/ts.err" | tr '\n' ' ')" '{ok:false,error:$e,backend:"",self_name:"",self_ips:[],peers:[]}'
    return
  fi
  jq '{
    ok: true, error: "",
    backend: (.BackendState // ""),
    self_name: (.Self.HostName // ""),
    self_dns: ((.Self.DNSName // "") | split(".")[0]),
    self_ips: (.Self.VPNIPs // []),
    peers: [ (.Peer // {}) | to_entries[] | .value | {
      key: (((.DNSName // "") | split(".")[0] | ascii_downcase) as $k | if $k == "" then (.HostName|ascii_downcase) else $k end),
      name: (.HostName // ""),
      ip: ((.VPNIPs // [])[0] // ""),
      ips: (.VPNIPs // []),
      os: (.OS // ""),
      online: (.Online // false),
      conn: (if (.CurAddr // "") != "" then "direta" elif (.Online // false) then "relay(DERP " + (.Relay // "?") + ")" else "-" end),
      relay: (.Relay // ""),
      last_seen: (.LastSeen // "")
    } ] | sort_by(.key)
  }' <<<"$out"
}

collect_firewall() {
  S iptables -S INPUT 2>/dev/null | grep -v '^#' | jlines >"$TMP/fw_v4i.json"
  S iptables -S nexo-ts-guard 2>/dev/null | grep -v '^#' | jlines >"$TMP/fw_v4c.json"
  S ip6tables -S INPUT 2>/dev/null | grep -v '^#' | jlines >"$TMP/fw_v6i.json"
  S ip6tables -S nexo-ts-guard 2>/dev/null | grep -v '^#' | jlines >"$TMP/fw_v6c.json"
  jq -n --slurpfile a "$TMP/fw_v4i.json" --slurpfile b "$TMP/fw_v4c.json" --slurpfile c "$TMP/fw_v6i.json" --slurpfile d "$TMP/fw_v6c.json" \
    '{v4:{input:$a[0],chain:$b[0]}, v6:{input:$c[0],chain:$d[0]}}'
}

collect_adguard_proc() {
  local pid="" running=false exe=""
  [ -r /run/adguardhome.pid ] && pid=$(tr -dc '0-9' </run/adguardhome.pid)
  [ -z "$pid" ] && pid=$(S cat /run/adguardhome.pid 2>/dev/null | tr -dc '0-9')
  if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
    running=true
    exe=$(S readlink -f "/proc/$pid/exe" 2>/dev/null)
  fi
  S ss -tulnpH 2>/dev/null >"$TMP/ss.txt"
  awk '/"AdGuardHome"/{print $1" "$5}' "$TMP/ss.txt" | sort -u | jlines >"$TMP/agp_listen.json"
  awk '!/"AdGuardHome"/ && ($5 ~ /:53$/ || $5 ~ /:3000$/){u=$7; sub(/^users:\(\("/,"",u); sub(/".*/,"",u); print $1" "$5" ("u")"}' "$TMP/ss.txt" | sort -u | jlines >"$TMP/agp_other.json"
  jq -n --arg pid "$pid" --argjson r "$running" --arg exe "$exe" --slurpfile l "$TMP/agp_listen.json" --slurpfile o "$TMP/agp_other.json" \
    '{pid:$pid, running:$r, exe:$exe, listen:$l[0], other_53_3000:$o[0]}'
}

collect_dns() {
  dig +short +time=3 +tries=2 @"$BOX_IP" example.com A 2>/dev/null | grep -v '^;' | jlines >"$TMP/dns_ex.json"
  dig +short +time=3 +tries=2 @"$BOX_IP" doubleclick.net A 2>/dev/null | grep -v '^;' | jlines >"$TMP/dns_dc.json"
  jq -n --slurpfile a "$TMP/dns_ex.json" --slurpfile b "$TMP/dns_dc.json" '{example:$a[0], doubleclick:$b[0]}'
}

########################################################################
# 3. AdGuard API (senha só via stdin do curl; nunca impressa/gravada)
########################################################################
agh_get() { # $1 = caminho; saída JSON em stdout; rc != 0 em falha
  local pw
  [ -r "$SECRET_FILE" ] || return 9
  pw=$(tr -d '\r\n' <"$SECRET_FILE")
  pw=${pw//\\/\\\\}; pw=${pw//\"/\\\"}
  curl -sS -f -m 15 -K - "$AGH_URL$1" <<<"user = \"admin:$pw\"" 2>"$TMP/curl.err"
}

collect_adguard_api() {
  # stats e querylog vão direto para arquivos e entram no jq com --slurpfile: o querylog passa fácil do limite
  # de 128 KB por argumento (MAX_ARG_STRLEN), que derrubou o --argjson em DD/MM/AAAA.
  if ! agh_get /control/stats >"$TMP/agh_stats.json" || ! valid_json_file "$TMP/agh_stats.json"; then
    jq -n --arg e "stats: $(head -c 200 "$TMP/curl.err" | tr '\n' ' ')" '{ok:false,error:$e}'; return
  fi
  if ! agh_get '/control/querylog?limit=500' >"$TMP/agh_ql.json" || ! valid_json_file "$TMP/agh_ql.json"; then
    jq -n --arg e "querylog: $(head -c 200 "$TMP/curl.err" | tr '\n' ' ')" '{ok:false,error:$e}'; return
  fi
  if ! jq -n --slurpfile sts "$TMP/agh_stats.json" --slurpfile qls "$TMP/agh_ql.json" --argjson last "$LAST_EPOCH" --argjson now "$NOW_EPOCH" '
    def epoch: sub("\\.[0-9]+"; "") | capture("^(?<d>[0-9-]+T[0-9:]+)(?<o>Z|[+-][0-9]{2}:[0-9]{2})$") as $c
      | ($c.d + "Z" | fromdateiso8601) - (if $c.o == "Z" then 0 else
          ((($c.o[1:3]|tonumber)*3600 + ($c.o[4:6]|tonumber)*60) * (if $c.o[0:1] == "-" then -1 else 1 end)) end);
    def suspicious: test("(^|\\.)(duckdns\\.org|no-?ip\\.[a-z]+|ddns\\.net|hopto\\.org|zapto\\.org|sytes\\.net|servebeer\\.com|serveftp\\.com|myftp\\.(biz|org)|dynu\\.(com|net)|afraid\\.org|dyndns\\.(org|com)|changeip\\.com|3utilities\\.com|serveo\\.net|trycloudflare\\.com|loca\\.lt|localtunnel\\.me|portmap\\.(io|host)|pagekite\\.me|playit\\.gg|mspy\\.com|mspyonline\\.com|flexispy\\.com|hoverwatch\\.com|spyic\\.com|cocospy\\.com|thetruthspy\\.com|xnspy\\.com|eyezy\\.com|spyzie\\.com|ikeymonitor\\.com|clevguard\\.(com|net)|mobile-spy\\.com|spyera\\.com|highstermobile\\.com|webwatcher\\.com|cerberusapp\\.com)$") or test("(^|\\.)ngrok[^.]*\\.");
    def top($n): group_by(.) | map({d: .[0], n: length}) | sort_by(-.n) | .[:$n];
    $sts[0] as $st | $qls[0] as $ql | ($ql.data // []) | map({
        t: (.time | epoch), d: ((.question.name // "") | ascii_downcase | rtrimstr(".")),
        c: (.client // ""), blocked: ((.reason // "") | startswith("Filtered"))
      })
      # exclui os testes do próprio netmon (dig example.com / doubleclick.net feitos pelo box)
      | map(select(((.d == "example.com" or .d == "doubleclick.net") and (.c | startswith("<ANON_PREFIX_PC>"))) | not)) as $all
    | ($all | map(.t) | min // $now) as $oldest
    | (if $last > 0 then $last else ($now - 3600) end) as $from
    | ($all | map(select(.t > $from))) as $since
    | ((($now - $from) / 3600) | if . < 0.05 then 0.05 else . end) as $h
    | ((($now - $oldest) / 3600) | if . < 1 then 1 else . end) as $span
    | {
        ok: true, error: "",
        stats: {
          num_dns_queries: $st.num_dns_queries, num_blocked_filtering: $st.num_blocked_filtering,
          time_units: $st.time_units,
          top_blocked: ($st.top_blocked_domains // [] | map(to_entries[0] | {d: .key, n: .value}) | .[:10]),
          top_clients: ($st.top_clients // [] | map(to_entries[0] | {c: .key, n: .value}))
        },
        since: {
          from_epoch: $from, hours: ($h * 100 | round / 100),
          n: ($since | length), blocked: ($since | map(select(.blocked)) | length),
          truncated: (($ql.data // [] | length) >= 500 and $oldest > $from),
          top_blocked: ($since | map(select(.blocked) | .d) | top(5)),
          clients: ($since | map(.c) | unique),
          suspicious: ($since | map(select(.d | suspicious)) | group_by([.d, .c]) | map({d: .[0].d, c: .[0].c, n: length})),
          rate_q_h: (($since | length) / $h * 10 | round / 10),
          rate_b_h: (($since | map(select(.blocked)) | length) / $h * 10 | round / 10)
        },
        window: {
          entries: ($all | length), span_h: ($span * 100 | round / 100),
          rate_q_h: (($all | length) / $span * 10 | round / 10),
          rate_b_h: (($all | map(select(.blocked)) | length) / $span * 10 | round / 10),
          suspicious: ($all | map(select(.d | suspicious)) | group_by([.d, .c]) | map({d: .[0].d, c: .[0].c, n: length}))
        },
        known_clients: ((($all | map(.c)) + ($st.top_clients // [] | map(keys[0]))) | unique)
      }' >"$TMP/agh_out.json" 2>"$TMP/agh_jq.err" || ! valid_json_file "$TMP/agh_out.json"; then
    jq -n --arg e "falha ao processar stats/querylog: $(head -c 200 "$TMP/agh_jq.err" | tr '\n' ' ')" '{ok:false,error:$e}'; return
  fi
  cat "$TMP/agh_out.json"
}

########################################################################
# 4 + 5. dispositivo Android via SSH (uma conexão; no máximo 1 nova tentativa)
########################################################################
REMOTE_SCRIPT='
export LC_ALL=C
sec(){ echo "@@$1"; }
sec AK; sha256sum "$HOME/.ssh/authorized_keys" 2>/dev/null | cut -d" " -f1
sec SSHD; sha256sum "$PREFIX/etc/ssh/sshd_config" 2>/dev/null | cut -d" " -f1
sec SSHDPROC; if pgrep -x sshd >/dev/null 2>&1; then echo yes; else echo no; fi
sec LISTEN
if command -v ss >/dev/null 2>&1; then ss -tlnH 2>&1; else netstat -tln 2>&1; fi
sec IFCONFIG; ifconfig 2>/dev/null
sec APTUPDATE
if [ "${DO_UPDATE:-0}" = 1 ]; then
  if pgrep -x apt >/dev/null 2>&1 || pgrep -x apt-get >/dev/null 2>&1 || pgrep -x dpkg >/dev/null 2>&1; then echo busy
  else timeout 120 apt update >/dev/null 2>&1; echo "rc=$?"; fi
else echo skipped; fi
sec UPG; apt list --upgradable 2>/dev/null | grep -c "/"
sec PKGS; pm list packages -3 2>/dev/null | sed "s/^package://" | sort
sec TOOLS; for t in nmap termux-wifi-connectioninfo ip ss; do command -v $t >/dev/null 2>&1 && echo $t; done
WIF=$(ifconfig 2>/dev/null | awk "/^[^ \t]/{i=\$1; sub(\":\$\",\"\",i)} i ~ /^wlan/ && /inet /{print i, \$2, \$4; exit}")
sec WIFI
if [ -n "$WIF" ]; then
  set -- $WIF; IFN=$1; IP4=$2; MASK=$3
  echo "iface=$IFN"; echo "ip=$IP4"; echo "mask=$MASK"
  IFS=. read -r a b c d <<<"$IP4"; IFS=. read -r m1 m2 m3 m4 <<<"$MASK"
  NET="$((a&m1)).$((b&m2)).$((c&m3)).$((d&m4))"
  BITS=0; for m in $m1 $m2 $m3 $m4; do while [ "$m" -gt 0 ]; do BITS=$((BITS+(m&1))); m=$((m>>1)); done; done
  echo "subnet=$NET/$BITS"
  GW=""
  command -v ip >/dev/null 2>&1 && GW=$(ip route 2>/dev/null | awk "/^default/{print \$3; exit}")
  [ -z "$GW" ] && GW=$(getprop "dhcp.$IFN.gateway" 2>/dev/null)
  echo "gateway=$GW"
  if command -v termux-wifi-connectioninfo >/dev/null 2>&1; then
    echo "wifiinfo=$(timeout 15 termux-wifi-connectioninfo 2>/dev/null | tr -d "\n")"
  fi
  if command -v nmap >/dev/null 2>&1; then
    if [ "$BITS" -ge 22 ]; then
      sec NMAP
      timeout 240 nmap -sn -n --unprivileged -T4 --max-retries 1 -PS21,22,53,80,443,445,554,631,5000,7000,8008,8080,8443,9100,62078 -oG - "$NET/$BITS" 2>&1
      sec NMAPRC; echo $?
    else echo "nmap_skip=sub-rede maior que /22"; fi
  else echo "nmap_skip=nmap não instalado"; fi
fi
sec END
'

collect_android() {  # escreve $TMP/android.json e $TMP/wifi.json
  local rc=0 do_update=0 try sec d="$TMP/r"
  mkdir -p "$d"
  if [ "${NETMON_NO_ANDROID:-0}" = 1 ]; then
    echo '{"ok":false,"skipped":true,"error":"pulado (NETMON_NO_ANDROID=1)"}' >"$TMP/android.json"
    echo '{"status":"pulado"}' >"$TMP/wifi.json"; return
  fi
  if [ "${NETMON_NO_APT_UPDATE:-0}" != 1 ] && [ "$(cat "$STATE/android_apt_update.date" 2>/dev/null)" != "$TODAY" ]; then
    do_update=1
  fi
  for try in 1 2; do
    if [ -n "${NETMON_TEST_RAW:-}" ]; then  # só para testes: usa saída remota simulada
      cp "$NETMON_TEST_RAW" "$TMP/android.raw"; : >"$TMP/android.err"; rc=0; break
    fi
    timeout 330 ssh -i "$ANDROID_KEY" -p 8022 -o BatchMode=yes -o ConnectTimeout=10 \
      -o StrictHostKeyChecking=yes -o LogLevel=ERROR "$ANDROID_IP" "DO_UPDATE=$do_update bash -s" \
      <<<"$REMOTE_SCRIPT" >"$TMP/android.raw" 2>"$TMP/android.err"
    rc=$?
    [ $rc -eq 0 ] && grep -q '^@@END' "$TMP/android.raw" && break
    [ $rc -ne 255 ] && break   # só repete em falha de conexão
    [ $try -eq 1 ] && sleep 5
  done
  if [ $rc -ne 0 ] || ! grep -q '^@@END' "$TMP/android.raw"; then
    jq -n --arg e "ssh rc=$rc: $(head -c 200 "$TMP/android.err" | tr '\n' ' ')" '{ok:false,error:$e}' >"$TMP/android.json"
    echo '{"status":"android_inacessivel"}' >"$TMP/wifi.json"
    return
  fi
  awk -v d="$d" '/^@@/{f=d"/"substr($0,3); printf "" > f; next} f{print >> f}' "$TMP/android.raw"
  local apt_up; apt_up=$(cat "$d/APTUPDATE" 2>/dev/null)
  [[ "$apt_up" == rc=0 ]] && APT_DATE_PENDING=1   # gravado de forma atômica só no fim, se a execução der certo

  local listen_status
  awk '/^[^ \t]/{i=$1; sub(/:$/,"",i); print i" - -"; next} /inet /{print i" "$2" "$4}' "$d/IFCONFIG" 2>/dev/null \
    | jq -R 'split(" ") | {name: .[0], inet: .[1], mask: .[2]}' | jq -s 'group_by(.name) | map({name: .[0].name, inet: (map(select(.inet != "-") | .inet) | .[0] // ""), mask: (map(select(.mask != "-") | .mask) | .[0] // "")})' >"$d/ifaces.json"
  if grep -qiE 'no support|permission denied|not configured' "$d/LISTEN" 2>/dev/null; then
    listen_status="sem permissão (Android bloqueia /proc/net sem root)"
  else listen_status="ok"; fi
  grep -E '^(tcp|LISTEN)' "$d/LISTEN" 2>/dev/null | awk '{ if ($1=="LISTEN") print $4; else print $4 }' | sort -u | jlines >"$d/listen.json"
  jlines <"$d/PKGS" >"$d/pkgs.json" 2>/dev/null || echo '[]' >"$d/pkgs.json"
  jlines <"$d/TOOLS" >"$d/tools.json" 2>/dev/null || echo '[]' >"$d/tools.json"

  # listas (apps, interfaces, portas, ferramentas) entram por arquivo (--slurpfile), não como argumento
  if ! jq -n \
    --arg ak "$(head -c 200 "$d/AK" 2>/dev/null | tr -d '\n')" --arg sshd "$(head -c 200 "$d/SSHD" 2>/dev/null | tr -d '\n')" \
    --arg sp "$(head -c 20 "$d/SSHDPROC" 2>/dev/null | tr -d '\n')" --arg ls "$listen_status" --slurpfile ll "$d/listen.json" \
    --slurpfile ifss "$d/ifaces.json" --arg upg "$(head -c 20 "$d/UPG" 2>/dev/null | tr -dc '0-9')" --arg au "$apt_up" \
    --slurpfile pk "$d/pkgs.json" --arg psha "$(sha256sum "$d/PKGS" | cut -d' ' -f1)" \
    --slurpfile tl "$d/tools.json" '
    $ll[0] as $l | $ifss[0] as $ifs | $pk[0] as $pkgs | $tl[0] as $tools
    | ($ifs | map(select(.inet != "" and (.name | test("^wlan"))))) as $w
    | ($ifs | map(select(.inet != "" and (.name | test("^(rmnet|ccmni|seth|v4-rmnet|clat|rev_rmnet)"))))) as $m
    | {
      ok: true, error: "",
      ak_sha: $ak, sshd_sha: $sshd, sshd_running: ($sp == "yes"),
      listen_status: $ls, listen: $l,
      ifaces: $ifs,
      net_type: (if ($w | length) > 0 then "wifi" elif ($m | length) > 0 then "dados móveis" else "desconhecido/sem rede" end),
      active_iface: (($w + $m)[0].name // ""), active_ip: (($w + $m)[0].inet // ""),
      upgradable: (if $upg == "" then null else ($upg | tonumber) end), apt_update: $au,
      pkgs: $pkgs, pkgs_count: ($pkgs | length), pkgs_sha: (if ($pkgs | length) > 0 then $psha else "" end),
      tools: $tools
    }' >"$TMP/android.json" 2>"$TMP/android_jq.err" || ! valid_json_file "$TMP/android.json"; then
    jq -n --arg e "falha ao processar a saída do dispositivo Android: $(head -c 200 "$TMP/android_jq.err" | tr '\n' ' ')" '{ok:false,error:$e}' >"$TMP/android.json"
    echo '{"status":"erro_processamento"}' >"$TMP/wifi.json"
    return
  fi

  # ---- 5. Wi-Fi de casa ----
  if [ ! -s "$d/WIFI" ] || ! grep -q '^iface=' "$d/WIFI"; then
    jq -n --arg nt "$(jq -r .net_type "$TMP/android.json")" '{status:"nao_aplicavel", motivo:("dispositivo Android não está em Wi-Fi (" + $nt + ")")}' >"$TMP/wifi.json"
    return
  fi
  kv() { grep -m1 "^$1=" "$d/WIFI" | cut -d= -f2-; }
  local wi ssid="" bssid="" nstat="ok" nmsg=""
  echo '[]' >"$d/devs.json"
  wi=$(kv wifiinfo)
  if [ -n "$wi" ] && jq -e . >/dev/null 2>&1 <<<"$wi"; then
    ssid=$(jq -r '.ssid // ""' <<<"$wi"); bssid=$(jq -r '.bssid // ""' <<<"$wi")
  fi
  if [ -f "$d/NMAP" ]; then
    awk '/^Host: .*Status: Up/{print $2}' "$d/NMAP" | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n -u \
      | jq -R '{ip: ., mac: "", vendor: ""}' | jq -s . >"$d/devs.json"
    # MAC/fabricante só aparecem se o nmap conseguir (sem root normalmente não consegue)
    nmsg="rc=$(tr -d '\n' <"$d/NMAPRC" 2>/dev/null)"
  else
    nstat="sem_scan"; nmsg=$(kv nmap_skip)
  fi
  if ! jq -n --arg if "$(kv iface)" --arg ip "$(kv ip)" --arg sn "$(kv subnet)" --arg gw "$(kv gateway)" \
    --arg ssid "$ssid" --arg bssid "$bssid" --arg ns "$nstat" --arg nm "$nmsg" --slurpfile dv "$d/devs.json" '
    $dv[0] as $devs
    | ($sn | split("/")[0] | split(".") | .[3] = ((.[3] | tonumber) + 1 | tostring) | join(".")) as $g1
    | {status: "ok", iface: $if, ip: $ip, subnet: $sn,
       gateway: (if $gw != "" then $gw else "ilegível" end),
       gateway_guess: (if $gw == "" and ($devs | map(.ip) | index($g1)) != null then $g1 + " (heurística: .1 respondeu)" else "" end),
       ssid: (if $ssid != "" then $ssid else "ilegível (termux-api não instalado)" end), bssid: $bssid,
       scan: $ns, scan_info: $nm, devices: $devs}' >"$TMP/wifi.json" 2>/dev/null || ! valid_json_file "$TMP/wifi.json"; then
    echo '{"status":"erro_processamento","motivo":"falha ao processar dados do Wi-Fi"}' >"$TMP/wifi.json"
  fi
}

########################################################################
# Coleta
########################################################################
# cada coleta vai para um arquivo; nada de JSON grande em argumento de linha de comando
APT_DATE_PENDING=0
collect_vpn    >"$TMP/c_ts.json"
collect_firewall     >"$TMP/c_fw.json"
collect_adguard_proc >"$TMP/c_agp.json"
collect_dns          >"$TMP/c_dns.json"
collect_adguard_api  >"$TMP/c_aga.json"
collect_android
for c in c_ts:VPN c_fw:firewall c_agp:"processo do AdGuard" c_dns:DNS c_aga:"API do AdGuard" android:dispositivo Android wifi:Wi-Fi; do
  valid_json_file "$TMP/${c%%:*}.json" || die "coleta '${c#*:}' gerou JSON inválido ou vazio; estado não alterado"
done

jq -n --arg ts "$NOW_ISO" --argjson ep "$NOW_EPOCH" --slurpfile t "$TMP/c_ts.json" --slurpfile fw "$TMP/c_fw.json" \
  --slurpfile ap "$TMP/c_agp.json" --slurpfile dns "$TMP/c_dns.json" --slurpfile aa "$TMP/c_aga.json" \
  --slurpfile r "$TMP/android.json" --slurpfile w "$TMP/wifi.json" '{
    ts: $ts, epoch: $ep,
    box: {vpn: ($t[0] | del(.peers)), firewall: $fw[0], adguard: $ap[0], dns: $dns[0]},
    peers: $t[0].peers, adguard_api: $aa[0], android: $r[0], wifi: $w[0]
  }' >"$TMP/snap.json" 2>"$TMP/snap.err" || die "falha ao montar o snapshot ($(head -c 200 "$TMP/snap.err" | tr '\n' ' ')); estado não alterado"
valid_json_file "$TMP/snap.json" || die "snapshot inválido ou vazio; estado não alterado"

########################################################################
# Baseline
########################################################################
make_baseline() { # $1 = ARQUIVO com o baseline antigo (ou {}); preserva seções que não puderam ser coletadas agora
  jq -n --slurpfile ss "$TMP/snap.json" --slurpfile olds "$1" '$ss[0] as $s | $olds[0] as $old | {
    created: $s.ts, epoch: $s.epoch,
    box: $s.box,
    peers: $s.peers,
    adguard: (if $s.adguard_api.ok then {
        rate_q_h: $s.adguard_api.window.rate_q_h, rate_b_h: $s.adguard_api.window.rate_b_h,
        window_entries: $s.adguard_api.window.entries, known_clients: $s.adguard_api.known_clients
      } else ($old.adguard // null) end),
    android: (if $s.android.ok then ($s.android | del(.error, .apt_update)) else ($old.android // null) end),
    wifi: (if $s.wifi.status == "ok" and $s.wifi.scan == "ok" then ($s.wifi | {iface, subnet, gateway, ssid, bssid, devices}) else ($old.wifi // null) end)
  }'
}

# Nada é gravado aqui: o baseline novo é preparado num temporário validado (stage_json) e só é movido no fim,
# depois que alertas e resumo também deram certo. BASEF = arquivo usado na comparação.
echo '{}' >"$TMP/empty.json"
BASEF="$BASELINE"; NEWBASE=0
if [ -e "$BASELINE" ] && ! valid_json_file "$BASELINE"; then
  if [ $REBASE -eq 1 ]; then
    cp -p "$BASELINE" "$STATE/baseline.invalid-$(date +%Y%m%d-%H%M%S).json" 2>/dev/null
    PRENOTES="${PRENOTES:+$PRENOTES$'\n'}[INFO] baseline.json atual estava inválido/vazio; ignorado (cópia em state/baseline.invalid-*)."
  else
    die "baseline.json está inválido ou vazio. Restaure de state/baseline.prev.json (se for válido) ou rode --rebaseline; nada foi gravado"
  fi
fi
if [ $REBASE -eq 1 ] || [ ! -e "$BASELINE" ]; then
  OLDF="$TMP/empty.json"
  if valid_json_file "$BASELINE"; then
    OLDF="$BASELINE"
    stage_json "$STATE/baseline.prev.json" jq . "$BASELINE"
  fi
  stage_json "$BASELINE" make_baseline "$OLDF"
  BASEF=$STAGED_PATH
  NEWBASE=1
else
  # completa seções ausentes (ex.: dispositivo Android estava offline no 1º run, Wi-Fi nunca visto)
  stage_json "$BASELINE" jq --slurpfile ss "$TMP/snap.json" '
    $ss[0] as $s
    | . as $b
    | (if ($b.android == null and $s.android.ok) then .android = ($s.android | del(.error, .apt_update)) | .android_learned = $s.ts else . end)
    | (if ($b.wifi == null and $s.wifi.status == "ok" and $s.wifi.scan == "ok") then .wifi = ($s.wifi | {iface, subnet, gateway, ssid, bssid, devices}) | .wifi_learned = $s.ts else . end)
    | (if ($b.adguard == null and $s.adguard_api.ok) then .adguard = {rate_q_h: $s.adguard_api.window.rate_q_h, rate_b_h: $s.adguard_api.window.rate_b_h, window_entries: $s.adguard_api.window.entries, known_clients: $s.adguard_api.known_clients} else . end)' "$BASELINE"
  if cmp -s <(jq -cS . "$STAGED_PATH") <(jq -cS . "$BASELINE"); then
    unstage "$STAGED_PATH"          # nada a completar: baseline.json não é reescrito
  else
    BASEF=$STAGED_PATH
  fi
fi

########################################################################
# Comparação -> alertas
########################################################################
ALERTS=$(jq -r -n --slurpfile ss "$TMP/snap.json" --slurpfile b "$BASEF" --slurpfile ls "$LASTF" --argjson nb "$NEWBASE" \
  --arg boxip "$BOX_IP" --arg boxname "$BOX_NAME" --arg android "$ANDROID_PEER" --arg guard "$GUARD_SCRIPT" 2>"$TMP/alerts.err" '
  $ss[0] as $s | $b[0] as $b | $ls[0] as $l
  | def arr: . // [];
    def minus($x; $y): ($x | arr) - ($y | arr);
    def lst: if length == 0 then "-" else join(", ") end;
    def delta($new; $old): [ (minus($new; $old) | select(length > 0) | "novos: " + join(", ")),
                             (minus($old; $new) | select(length > 0) | "removidos: " + join(", ")) ] | join("; ");
    def fixfw: " Para reaplicar (manual, NÃO automático): sh " + $guard;
  [
  # ---------- 1. box ----------
  ( $s.box.vpn as $t |
    if ($t.ok | not) then "[ALERTA] VPN: falha ao ler status (" + $t.error + ")"
    elif $t.backend != "Running" then "[ALERTA] VPN não está ativo (estado: " + $t.backend + ")"
    else empty end ),
  ( $s.box.vpn as $t | select($t.ok) |
    if ($t.self_ips | index($boxip)) == null then "[ALERTA] VPN: IP do box mudou (esperado " + $boxip + ", atual " + ($t.self_ips | lst) + ")" else empty end,
    if ($t.self_name != $boxname and $t.self_dns != $boxname) then "[ALERTA] VPN: nome do box mudou (atual " + $t.self_name + ")" else empty end ),
  ( ["v4", "iptables"], ["v6", "ip6tables"] | . as [$v, $cmd] | $s.box.firewall[$v] as $f |
    if (($f.input | map(select(startswith("-A"))) | .[0]) // "") != "-A INPUT -i vpn0 -j nexo-ts-guard"
      then "[ALERTA] Firewall " + $cmd + ": regra nexo-ts-guard NÃO está no topo do INPUT para vpn0." + fixfw else empty end,
    if ($f.chain | length) == 0 then "[ALERTA] Firewall " + $cmd + ": cadeia nexo-ts-guard ausente." + fixfw
    elif $f.chain != ($b.box.firewall[$v].chain // $f.chain) then "[ALERTA] Firewall " + $cmd + ": regras da cadeia nexo-ts-guard mudaram vs baseline (" + delta($f.chain; $b.box.firewall[$v].chain) + ")." + fixfw else empty end,
    if $f.input != ($b.box.firewall[$v].input // $f.input) then "[ALERTA] Firewall " + $cmd + ": cadeia INPUT mudou vs baseline (" + delta($f.input; $b.box.firewall[$v].input) + ")." else empty end ),
  ( $s.box.adguard as $a |
    if ($a.running | not) then "[ALERTA] AdGuard Home NÃO está rodando (pid file: " + (if $a.pid == "" then "ausente" else $a.pid end) + ")"
    else
      (if $a.exe != "/opt/AdGuardHome/AdGuardHome" then "[ALERTA] AdGuard: processo do pid " + $a.pid + " não é /opt/AdGuardHome/AdGuardHome (é \"" + $a.exe + "\")" else empty end),
      (( ["tcp " + $boxip + ":3000", "tcp " + $boxip + ":53", "udp " + $boxip + ":53"] | sort ) as $exp |
        if ($a.listen | sort) != $exp then "[ALERTA] AdGuard escutando fora do esperado: " + ($a.listen | lst) + " (esperado só " + ($exp | lst) + ")" else empty end)
    end,
    if ($a.other_53_3000 | length) > 0 then "[ALERTA] Outro processo nas portas 53/3000: " + ($a.other_53_3000 | lst) else empty end ),
  ( $s.box.dns as $d |
    if ($d.example | map(select(test("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$") and . != "0.0.0.0")) | length) == 0
      then "[ALERTA] DNS: example.com não resolveu via " + $boxip + " (resposta: " + ($d.example | lst) + ")" else empty end,
    if $d.doubleclick != ["0.0.0.0"] then "[ALERTA] DNS: doubleclick.net NÃO foi bloqueado (resposta: " + ($d.doubleclick | lst) + ", esperado 0.0.0.0)" else empty end ),

  # ---------- 2. dispositivos da rede VPN ----------
  ( select($s.box.vpn.ok) |
    ($b.peers | arr | map({key: .key, value: .}) | from_entries) as $bp
    | (($l.peers // null) | if . == null then null else (map({key: .key, value: .}) | from_entries) end) as $lp
    | ($s.peers[] | . as $p |
        if $bp[$p.key] == null then "[ALERTA] Rede VPN: dispositivo NOVO/desconhecido: " + $p.key + " (" + $p.name + ", " + $p.ip + ", " + $p.os + ", " + (if $p.online then "online" else "offline" end) + ")"
        else
          (if $bp[$p.key].ip != $p.ip then "[ALERTA] Rede VPN: " + $p.key + " mudou de IP (" + $bp[$p.key].ip + " -> " + $p.ip + ")" else empty end),
          (if $bp[$p.key].os != $p.os then "[ALERTA] Rede VPN: " + $p.key + " mudou de SO (" + $bp[$p.key].os + " -> " + $p.os + ")" else empty end),
          # online/offline: só o dispositivo Android gera alerta (vs última execução). Direta/relay oscila sozinho
          # (VPN derruba o caminho direto quando ocioso), então fica só no resumo/log.
          # ONLINE = recuperação informativa; OFFLINE = alerta
          (if $p.key == $android and $lp != null and $lp[$p.key] != null and $lp[$p.key].online != $p.online
             then (if $p.online then "[INFO] " else "[ALERTA] " end) + "Rede VPN: " + $p.key + " ficou " + (if $p.online then "ONLINE" else "OFFLINE" end) else empty end)
        end),
      ( ($b.peers | arr | map(.key)) - ($s.peers | map(.key)) | .[] | "[ALERTA] Rede VPN: dispositivo REMOVIDO da rede VPN: " + . ) ),

  # ---------- 3. AdGuard ----------
  ( $s.adguard_api as $q |
    if ($q.ok | not) then "[ALERTA] AdGuard API inacessível (" + $q.error + ")"
    else
      ( $q.since.clients - ($b.adguard.known_clients // $q.since.clients) | select(length > 0)
        | "[ALERTA] AdGuard: cliente(s) DNS novo(s) desde a última execução: " + lst ),
      ( select($nb == 0 and $b.adguard != null) |
        ([($b.adguard.rate_q_h // 0), 30] | max) as $bq | ([($b.adguard.rate_b_h // 0), 10] | max) as $bb |
        (if $q.since.rate_q_h > 3 * $bq and $q.since.n >= 50 then "[ALERTA] AdGuard: PICO de consultas: " + ($q.since.rate_q_h | tostring) + "/h (baseline " + ($b.adguard.rate_q_h | tostring) + "/h; " + ($q.since.n | tostring) + " consultas em " + ($q.since.hours | tostring) + " h)" else empty end),
        (if $q.since.rate_b_h > 3 * $bb and $q.since.blocked >= 20 then "[ALERTA] AdGuard: PICO de bloqueios: " + ($q.since.rate_b_h | tostring) + "/h (baseline " + ($b.adguard.rate_b_h | tostring) + "/h). Top bloqueados: " + ($q.since.top_blocked | map(.d + " (" + (.n | tostring) + ")") | lst) else empty end) ),
      ( (if $nb == 1 then $q.window.suspicious else $q.since.suspicious end)[] |
        "[HEURÍSTICA] AdGuard: consulta a domínio suspeito (DNS dinâmico/túnel/stalkerware): " + .d + " — cliente " + .c + " (" + (.n | tostring) + "x). Pode ser legítimo; verificar." ),
      ( select($q.since.truncated) | "[INFO] AdGuard: mais de 500 consultas desde a última execução; contagem parcial (" + ($q.since.n | tostring) + "+)." )
    end ),

  # ---------- 4. dispositivo Android ----------
  ( $s.android as $r | $b.android as $br |
    if ($r.ok | not) then (if ($r.skipped // false) then empty else "[ALERTA] dispositivo Android offline/inacessível (" + $r.error + ")" end)
    elif $br == null then empty
    else
      (if $r.ak_sha != $br.ak_sha then "[ALERTA] dispositivo Android: ~/.ssh/authorized_keys MUDOU (sha256 " + ($br.ak_sha[:12]) + "… -> " + ($r.ak_sha[:12]) + "…)" else empty end),
      (if $r.sshd_sha != $br.sshd_sha then "[ALERTA] dispositivo Android: sshd_config MUDOU (sha256 " + ($br.sshd_sha[:12]) + "… -> " + ($r.sshd_sha[:12]) + "…)" else empty end),
      (if ($r.sshd_running | not) then "[ALERTA] dispositivo Android: processo sshd não encontrado (estranho, já que o SSH respondeu)" else empty end),
      (if $r.listen_status != $br.listen_status then "[INFO] dispositivo Android: leitura de portas mudou: " + $br.listen_status + " -> " + $r.listen_status else empty end),
      (if $r.listen != $br.listen then "[ALERTA] dispositivo Android: portas em escuta mudaram (" + delta($r.listen; $br.listen) + ")" else empty end),
      (if $r.pkgs_sha != $br.pkgs_sha then "[ALERTA] dispositivo Android: lista de apps de terceiros mudou (" + delta($r.pkgs; $br.pkgs) + ")" else empty end),
      ( ($r.ifaces | map(.name) | map(select(test("^(lo|wlan[0-9]*|rmnet.*|ccmni.*|seth.*|v4-.*|clat.*|dummy.*|p2p.*|ifb.*|tun0)$") | not))) - ($br.ifaces | arr | map(.name))
        | select(length > 0) | "[ALERTA] dispositivo Android: interface(s) de rede incomum(ns): " + lst + " (VPN/túnel extra?)" ),
      (if $l != null and ($l.android.ok // false) and $l.android.net_type != $r.net_type then "[INFO] dispositivo Android: tipo de rede mudou: " + $l.android.net_type + " -> " + $r.net_type + " (" + $r.active_iface + " " + $r.active_ip + ")" else empty end),
      (if $l != null and ($l.android.ok // false) and $r.upgradable != null and $l.android.upgradable != $r.upgradable then "[INFO] dispositivo Android: pacotes terminal Android atualizáveis: " + ($l.android.upgradable | tostring) + " -> " + ($r.upgradable | tostring) else empty end)
    end ),

  # ---------- 5. Wi-Fi de casa ----------
  ( $s.wifi as $w | $b.wifi as $bw |
    if $w.status != "ok" then empty
    elif $w.scan != "ok" then "[INFO] Wi-Fi de casa: dispositivo Android em Wi-Fi (" + $w.subnet + ") mas sem varredura: " + $w.scan_info
    elif $bw == null then empty
    elif $bw.subnet != $w.subnet then "[INFO] Wi-Fi: dispositivo Android em rede diferente da de casa (" + $w.subnet + ", SSID " + $w.ssid + "; casa = " + $bw.subnet + "). Dispositivos não comparados."
    else
      ( ($w.devices | map(.ip)) - ($bw.devices | map(.ip)) | select(length > 0) | "[ALERTA] Wi-Fi de casa: dispositivo(s) NOVO(s) na rede: " + lst ),
      (if $bw.gateway != $w.gateway and $w.gateway != "ilegível" then "[ALERTA] Wi-Fi de casa: gateway mudou (" + $bw.gateway + " -> " + $w.gateway + ")" else empty end),
      (if $bw.bssid != "" and $w.bssid != "" and $bw.bssid != $w.bssid then "[INFO] Wi-Fi de casa: BSSID mudou (" + $bw.bssid + " -> " + $w.bssid + ")" else empty end)
    end )
  ] | .[]') || die "falha ao comparar com a baseline ($(head -c 200 "$TMP/alerts.err" | tr '\n' ' ')); estado não alterado"

########################################################################
# Resumo (log sempre; tela só com --verbose)
########################################################################
SUMMARY=$(jq -r '
  def lst: if length == 0 then "-" else join(", ") end;
  "1) Box: VPN " + .box.vpn.backend + " (" + .box.vpn.self_name + " " + (.box.vpn.self_ips | lst) + ")"
  + " | guard v4 topo=" + ((.box.firewall.v4.input | map(select(startswith("-A")))[0] // "") == "-A INPUT -i vpn0 -j nexo-ts-guard" | tostring)
  + " v6 topo=" + ((.box.firewall.v6.input | map(select(startswith("-A")))[0] // "") == "-A INPUT -i vpn0 -j nexo-ts-guard" | tostring)
  + " | AdGuard pid " + .box.adguard.pid + " rodando=" + (.box.adguard.running | tostring) + " escuta: " + (.box.adguard.listen | lst)
  + " | dig example.com=" + (.box.dns.example | lst) + " doubleclick.net=" + (.box.dns.doubleclick | lst),
  "2) Rede VPN: " + (.peers | map(.key + " [" + .ip + ", " + .os + ", " + (if .online then "online" else "offline" end) + ", " + .conn + "]") | lst),
  "3) AdGuard: " + (if .adguard_api.ok then
      "desde última execução (" + (.adguard_api.since.hours | tostring) + " h): " + (.adguard_api.since.n | tostring) + " consultas, " + (.adguard_api.since.blocked | tostring) + " bloqueadas"
      + "; top bloqueados: " + (.adguard_api.since.top_blocked | map(.d + "(" + (.n | tostring) + ")") | lst)
      + "; clientes: " + (.adguard_api.since.clients | lst)
      + " | stats janela 24h: " + (.adguard_api.stats.num_dns_queries | tostring) + " consultas / " + (.adguard_api.stats.num_blocked_filtering | tostring) + " bloqueadas; top bloqueados: " + (.adguard_api.stats.top_blocked | map(.d + "(" + (.n | tostring) + ")") | lst)
      + " | suspeitos (heurística) desde última: " + (.adguard_api.since.suspicious | length | tostring)
    else "ERRO " + .adguard_api.error end),
  "4) dispositivo Android: " + (if .android.ok then
      "rede=" + .android.net_type + " (" + .android.active_iface + " " + .android.active_ip + "); ifaces: " + (.android.ifaces | map(.name + (if .inet != "" then "=" + .inet else "" end)) | lst)
      + "; authorized_keys " + .android.ak_sha[:12] + "…; sshd_config " + .android.sshd_sha[:12] + "…; sshd=" + (.android.sshd_running | tostring)
      + "; portas: " + .android.listen_status + " " + (.android.listen | lst)
      + "; atualizáveis terminal Android: " + (.android.upgradable | tostring) + " (apt update: " + .android.apt_update + ")"
      + "; apps terceiros: " + (.android.pkgs_count | tostring) + " (sha " + .android.pkgs_sha[:12] + "…); ferramentas: " + (.android.tools | lst)
    else "inacessível (" + (.android.error // "") + ")" end),
  "5) Wi-Fi de casa: " + (if .wifi.status == "ok" then
      .wifi.iface + " " + .wifi.ip + " sub-rede " + .wifi.subnet + " gateway " + .wifi.gateway + (if .wifi.gateway_guess != "" then " / " + .wifi.gateway_guess else "" end) + " SSID " + .wifi.ssid
      + " | varredura: " + .wifi.scan + " " + .wifi.scan_info + " | dispositivos (" + (.wifi.devices | length | tostring) + "): " + (.wifi.devices | map(.ip) | lst)
    else "não executado — " + (.wifi.motivo // .wifi.status) end)
' "$TMP/snap.json" 2>"$TMP/summary.err") || die "falha ao montar o resumo ($(head -c 200 "$TMP/summary.err" | tr '\n' ' ')); estado não alterado"

########################################################################
# Gravação do estado (atômica). Até aqui nada em baseline.json/state/ foi alterado.
########################################################################
stage_json "$LAST" jq . "$TMP/snap.json"
commit_staged
if [ "$APT_DATE_PENDING" = 1 ]; then
  ATMP=$(mktemp "$STATE/.android_apt_update.date.tmp.XXXXXX") && printf '%s\n' "$TODAY" >"$ATMP" \
    && grep -qxE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$ATMP" && mv -f "$ATMP" "$STATE/android_apt_update.date" \
    || { rm -f "$ATMP"; PRENOTES="${PRENOTES:+$PRENOTES$'\n'}[INFO] não foi possível gravar state/android_apt_update.date (o apt update pode rodar de novo hoje)."; }
fi

# avisos de baseline aprendida (só depois que a gravação realmente deu certo)
NOTES="$PRENOTES"
if [ "$NEWBASE" = 1 ] && valid_json_file "$BASELINE" && jq -e --arg ts "$NOW_ISO" '.created == $ts' "$BASELINE" >/dev/null 2>&1; then
  if [ $REBASE -eq 1 ]; then NOTES="${NOTES:+$NOTES$'\n'}[INFO] Baseline regravada em $BASELINE (anterior salva em state/baseline.prev.json)."
  else NOTES="${NOTES:+$NOTES$'\n'}[INFO] Primeira execução: baseline criada em $BASELINE."; fi
elif [ "$NEWBASE" = 1 ]; then
  die "baseline.json não ficou com o conteúdo esperado depois da gravação"
fi
jq -e --arg ts "$NOW_ISO" '.android_learned == $ts' "$BASELINE" >/dev/null 2>&1 && NOTES="${NOTES:+$NOTES$'\n'}[INFO] dispositivo Android respondeu pela 1ª vez: baseline do dispositivo Android gravada."
jq -e --arg ts "$NOW_ISO" '.wifi_learned == $ts' "$BASELINE" >/dev/null 2>&1 && NOTES="${NOTES:+$NOTES$'\n'}[INFO] Wi-Fi de casa visto pela 1ª vez: baseline gravada ($(jq -r '.wifi.subnet + ", " + (.wifi.devices|length|tostring) + " dispositivos"' "$BASELINE"))."

OUT="$NOTES"
[ -n "$ALERTS" ] && OUT="${OUT:+$OUT$'\n'}$ALERTS"

{
  echo "=== $NOW_ISO ${REBASE:+$( [ $REBASE -eq 1 ] && echo '(rebaseline)')}"
  echo "$SUMMARY"
  if [ -n "$OUT" ]; then echo "--- alertas ---"; echo "$OUT"; else echo "--- sem alterações ---"; fi
} >>"$LOG"

if [ $JSON -eq 1 ]; then  # saída para máquinas (dashboard): mesmo conteúdo do texto, estruturado
  printf '%s' "$OUT" >"$TMP/out.txt"; printf '%s' "$SUMMARY" >"$TMP/sum.txt"
  jq -n --slurpfile s "$TMP/snap.json" --rawfile out "$TMP/out.txt" --rawfile sum "$TMP/sum.txt" --arg base "$BASELINE" --arg log "$LOG" '{
    ok: true, snapshot: $s[0], baseline_file: $base, log_file: $log,
    alerts: ($out | split("\n") | map(select(length > 0)) | map(
      if test("^\\[[^]]+\\] ") then capture("^\\[(?<level>[^]]+)\\] (?<text>.*)$") else {level: "", text: .} end)),
    summary: ($sum | split("\n") | map(select(length > 0)))
  }' >"$TMP/json_out.json" 2>"$TMP/json_out.err" && valid_json_file "$TMP/json_out.json" \
    || die "falha ao montar a saída JSON ($(head -c 200 "$TMP/json_out.err" | tr '\n' ' ')) — o estado já foi gravado"
  cat "$TMP/json_out.json"
  exit 0
fi

[ $VERBOSE -eq 1 ] && { echo "$SUMMARY"; [ -n "$OUT" ] && echo "---"; }
[ -n "$OUT" ] && echo "$OUT"
exit 0
