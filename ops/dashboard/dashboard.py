#!/usr/bin/env python3
"""dashboard.py — coleta AO VIVO + renderiza o painel de segurança do dono (pt-BR).

Chamado por dashboard.sh. Regras:
  * nenhum valor é inventado: tudo vem de uma checagem feita agora; se falhar -> "indisponível" + motivo;
  * nunca imprime/grava senha ou chave privada (a senha do AdGuard só vai no cabeçalho HTTP);
  * somente leitura: não altera firewall, DNS, AdGuard, VPN nem o telefone.
"""
import base64, datetime as dt, glob, html, json, os, re, shutil, subprocess, sys, time, urllib.parse, urllib.request
from zoneinfo import ZoneInfo

TZ = ZoneInfo("America/Sao_Paulo")
OPS = os.path.expanduser("~/nexo/ops") + ""
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
NETMON = os.path.join(OPS, "netmon", "netmon.sh")
SECRET_FILE = os.path.join(OPS, "secrets", "adguard-admin.txt")
TS_SOCK = os.path.expanduser("~/") + ".local/run/vpnd.sock"
BOX_IP, BOX_NAME = os.environ.get("VPN_IP_PC", "<VPN_IP_PC>"), "servidor"
ANDROID_IP, ANDROID_PEER = os.environ.get("VPN_IP_ANDROID", "<VPN_IP_ANDROID>"), "android-device"
ANDROID_SSH = ["ssh", "-i", os.path.expanduser("~/") + ".ssh/id_ed25519_android", "-p", "8022", "-o", "BatchMode=yes",
             "-o", "ConnectTimeout=8", "-o", "StrictHostKeyChecking=yes", "-o", "LogLevel=ERROR",
             f"{os.environ.get('ANDROID_SSH_USER', '<ANDROID_USER>')}@{ANDROID_IP}"]
BOX_KEY = os.path.expanduser("~/") + ".ssh/id_ed25519_android"
AGH = f"http://{BOX_IP}:3000"
ANON_ANDROID = os.environ.get("ANON_CLIENT_ANDROID", "<ANON_CLIENT_ANDROID>")
ANON_PC = os.environ.get("ANON_CLIENT_PC", "<ANON_CLIENT_PC>")
CLIENT_LABEL = {ANON_ANDROID: "dispositivo Android (anonimizado /16)", ANON_PC: "servidor (anonimizado /16)"}
KEEP_PNGS = 14
SECURITY_AUDIT = os.path.join(HERE, "security-audit-latest.json")
NOW = dt.datetime.now(TZ)
T0 = time.time()


# ---------------------------------------------------------------- utilidades
def run(cmd, timeout=30, input_=None, env=None):
    """Executa comando; devolve (rc, stdout, stderr). rc=124 em timeout, 127 se não existir."""
    try:
        p = subprocess.run(cmd, input=input_, capture_output=True, text=True, timeout=timeout,
                           env={**os.environ, **(env or {})})
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired:
        return 124, "", f"tempo esgotado ({timeout}s)"
    except FileNotFoundError as e:
        return 127, "", f"comando não encontrado: {e.filename}"


def short(s, n=160):
    s = " ".join(str(s).split())
    return s if len(s) <= n else s[: n - 1] + "…"


def parse_ts(s):
    """ISO8601 com nanossegundos/offset -> datetime aware (ou None)."""
    if not s or s.startswith("0001-"):
        return None
    m = re.match(r"^(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d)(\.\d+)?(Z|[+-]\d\d:?\d\d)?$", s)
    if not m:
        return None
    frac = (m.group(2) or "")[:7]
    off = m.group(3) or "+00:00"
    if off == "Z":
        off = "+00:00"
    return dt.datetime.fromisoformat(m.group(1) + frac + off)


def brt(d, fmt="%d/%m %H:%M:%S"):
    return d.astimezone(TZ).strftime(fmt) + " BRT" if d else "—"


def ago(d):
    if not d:
        return ""
    s = int((NOW - d).total_seconds())
    if s < 0:
        return "agora"
    if s < 90:
        return f"há {s} s"
    if s < 5400:
        return f"há {s // 60} min"
    if s < 172800:
        return f"há {s / 3600:.1f} h".replace(".", ",")
    return f"há {s // 86400} dias"


def fail(err):
    return {"ok": False, "error": short(err, 240)}


def num(n):
    return f"{n:,}".replace(",", ".") if isinstance(n, int) else str(n)


def pct(a, b):
    return f"{100.0 * a / b:.1f}%".replace(".", ",") if b else "0%"


# ---------------------------------------------------------------- coletas
def collect_netmon():
    """Reaproveita TODAS as checagens do netmon (VPN, firewall, AdGuard proc/DNS/stats, dispositivo Android básico)."""
    if not os.access(NETMON, os.X_OK):
        return fail(f"{NETMON} não encontrado/executável")
    env = {"NETMON_NO_APT_UPDATE": "1"}  # dashboard nunca roda 'apt update' no telefone
    if os.environ.get("DASH_NO_ANDROID") == "1":
        env["NETMON_NO_ANDROID"] = "1"
    rc, out, err = run([NETMON, "--json"], timeout=420, env=env)
    if rc != 0:
        return fail(f"netmon rc={rc}: {err or out}")
    try:
        j = json.loads(out)
    except Exception as e:
        return fail(f"saída do netmon não é JSON ({e}): {out[:120]}")
    if not j.get("ok"):
        return fail(j.get("error", "erro desconhecido"))
    return j


def collect_vpn():
    r = {"ok": True, "error": ""}
    rc, out, err = run(["vpn", f"--socket={TS_SOCK}", "status", "--json"], 20)
    if rc != 0:
        return fail(f"vpn status rc={rc}: {err}")
    st = json.loads(out)
    r["backend"] = st.get("BackendState", "")
    r["version"] = st.get("Version", "")
    r["rede VPN"] = (st.get("CurrentRede VPN") or {}).get("MagicDNSSuffix", "")
    r["magicdns"] = (st.get("CurrentRede VPN") or {}).get("MagicDNSEnabled")
    r["health"] = st.get("Health") or []
    s = st.get("Self") or {}
    r["self"] = {"name": s.get("HostName", ""), "ips": s.get("VPNIPs") or [], "online": s.get("Online"), "os": s.get("OS", "")}
    peers = []
    for p in (st.get("Peer") or {}).values():
        peers.append({
            "key": (p.get("DNSName") or p.get("HostName", "")).split(".")[0].lower(),
            "name": p.get("HostName", ""), "ip": (p.get("VPNIPs") or [""])[0], "os": p.get("OS", ""),
            "online": bool(p.get("Online")), "active": bool(p.get("Active")),
            "conn": "direta" if p.get("CurAddr") else (f"relay DERP {p.get('Relay')}" if p.get("Online") else "—"),
            "last_seen": p.get("LastSeen", ""), "last_handshake": p.get("LastHandshake", ""),
        })
    r["peers"] = sorted(peers, key=lambda x: x["key"])
    # DNS entregue pelo servidor de coordenação + DNS do sistema
    rc, out, err = run(["vpn", f"--socket={TS_SOCK}", "dns", "status", "--json"], 20)
    if rc == 0:
        d = json.loads(out)
        r["dns"] = {"ok": True, "accept_dns_local": d.get("VPNDNS"),
                    "resolvers": [x.get("Addr") for x in d.get("Resolvers") or []],
                    "split": {k: [x.get("Addr") for x in v] for k, v in (d.get("SplitDNSRoutes") or {}).items()},
                    "search": d.get("SearchDomains") or [],
                    "system_ns": (d.get("SystemDNS") or {}).get("Nameservers") or []}
    else:
        r["dns"] = fail(f"vpn dns status rc={rc}: {err}")
    # preferências locais (só campos inofensivos; o bloco Config com chaves é descartado)
    rc, out, err = run(["vpn", f"--socket={TS_SOCK}", "debug", "prefs"], 20)
    if rc == 0:
        p = json.loads(out)
        r["prefs"] = {"ok": True, **{k: p.get(k) for k in ("CorpDNS", "WantRunning", "ShieldsUp", "RouteAll", "ExitNodeIP", "RunSSH", "Hostname")},
                      "AutoUpdateApply": (p.get("AutoUpdate") or {}).get("Apply")}
    else:
        r["prefs"] = fail(f"vpn debug prefs rc={rc}: {err}")
    return r


def agh_get(path, auth):
    req = urllib.request.Request(AGH + path, headers={"Authorization": auth})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.load(resp)


def collect_adguard():
    try:
        pw = open(SECRET_FILE).read().strip()
    except Exception as e:
        return fail(f"não consegui ler o arquivo de senha ({type(e).__name__})")
    auth = "Basic " + base64.b64encode(f"admin:{pw}".encode()).decode()
    del pw
    r = {"ok": True, "error": ""}
    try:
        r["status"] = agh_get("/control/status", auth)
        r["stats"] = agh_get("/control/stats", auth)
        try:
            r["stats_interval_h"] = agh_get("/control/stats/config", auth).get("interval", 0) / 3600000
        except Exception:
            r["stats_interval_h"] = None
        try:
            r["ql_config"] = agh_get("/control/querylog/config", auth)
        except Exception:
            r["ql_config"] = {}
        # consultas do dispositivo Android (cliente anonimizado <ANON_CLIENT_ANDROID>): pagina até passar de 1 h ou 5000 linhas
        cutoff = NOW - dt.timedelta(hours=1)
        rows, older, pages = [], "", 0
        while pages < 10:
            q = "/control/querylog?limit=500&search=" + ANON_ANDROID + (f"&older_than={urllib.parse.quote(older)}" if older else "")
            data = agh_get(q, auth).get("data") or []
            pages += 1
            rows += [d for d in data if d.get("client") == ANON_ANDROID]
            if len(data) < 500:
                break
            older = data[-1]["time"]
            if (parse_ts(older) or NOW) < cutoff:
                break
        last = parse_ts(rows[0]["time"]) if rows else None
        hour = [d for d in rows if (parse_ts(d["time"]) or cutoff) >= cutoff]
        blocked = [d for d in hour if (d.get("reason") or "").startswith("Filtered")]
        tb = {}
        for d in blocked:
            n = (d.get("question") or {}).get("name", "")
            tb[n] = tb.get(n, 0) + 1
        r["android"] = {"last_seen": rows[0]["time"] if rows else "", "last_domain": (rows[0].get("question") or {}).get("name", "") if rows else "",
                      "hour_n": len(hour), "hour_blocked": len(blocked), "pages": pages,
                      "hour_top_blocked": sorted(tb.items(), key=lambda x: -x[1])[:5],
                      "partial": pages >= 10}
        r["android"]["_last_dt"] = last
    except Exception as e:
        return fail(f"API {AGH}: {type(e).__name__}: {e}")
    return r


REMOTE = r'''
export LC_ALL=C
sec(){ echo "@@$1"; }
sec PATCH; getprop ro.build.version.security_patch
sec ANDROID; getprop ro.build.version.release
sec MODEL; getprop ro.product.model
sec UPTIME; uptime
sec SSHDPROC; if pgrep -x sshd >/dev/null 2>&1; then echo yes; else echo no; fi
sec SSHDT; sshd -T 2>&1 | grep -iE '^(port|listenaddress|passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication|permitrootlogin|permitemptypasswords|allowtcpforwarding|allowagentforwarding|x11forwarding|permittunnel|gatewayports|maxauthtries) '
sec AKOPTS; grep -vE '^[[:space:]]*(#|$)' "$HOME/.ssh/authorized_keys" 2>&1 | sed -E 's/((ssh|ecdsa|sk)-[A-Za-z0-9@.-]+)[[:space:]]+[A-Za-z0-9+\/=]+.*$/\1/'
sec AKFP; ssh-keygen -lf "$HOME/.ssh/authorized_keys" 2>&1
sec UPG; apt list --upgradable 2>/dev/null | grep / | cut -d/ -f1
sec APTLISTS; stat -c %Y "$PREFIX"/var/lib/apt/lists/*_Packages 2>/dev/null | sort -n | tail -1
sec BATT; if command -v termux-battery-status >/dev/null 2>&1; then timeout 10 termux-battery-status 2>&1; else echo __ABSENT__; fi
sec BOOTPKG; if pm path com.termux.boot >/dev/null 2>&1; then echo yes; else echo no; fi
sec BOOTDIR; if [ -d "$HOME/.termux/boot" ]; then echo yes; else echo no; fi
sec BOOTSCRIPTS; ls -1 "$HOME/.termux/boot" 2>/dev/null
sec END
'''


def collect_android():
    if os.environ.get("DASH_NO_ANDROID") == "1":
        return fail("pulado (DASH_NO_ANDROID=1)")
    t = time.time()
    rc, out, err = run(ANDROID_SSH + ["bash -s"], timeout=60, input_=REMOTE)
    lat = time.time() - t
    if rc != 0 or "@@END" not in out:
        return fail(f"SSH rc={rc}: {err.strip() or 'sem resposta'}")
    sec, cur = {}, None
    for line in out.splitlines():
        if line.startswith("@@"):
            cur = line[2:]
            sec[cur] = []
        elif cur:
            sec[cur].append(line)
    g = lambda k: "\n".join(sec.get(k, [])).strip()
    sshd = {}
    for line in sec.get("SSHDT", []):
        k, _, v = line.partition(" ")
        sshd.setdefault(k.lower(), []).append(v.strip())
    ak = []
    fps = [l for l in sec.get("AKFP", []) if l.strip()]
    for i, l in enumerate([l for l in sec.get("AKOPTS", []) if l.strip()]):
        m = re.match(r"^(.*?)\s*((?:ssh|ecdsa|sk)-[A-Za-z0-9@.-]+)$", l)
        opts, ktype = (m.group(1), m.group(2)) if m else (l, "?")
        fp = ""
        if i < len(fps):
            mm = re.search(r"(SHA256:\S+)", fps[i])
            fp = mm.group(1) if mm else ""
        ak.append({"options": opts or "(sem opções)", "type": ktype, "fingerprint": fp})
    upg = [l for l in sec.get("UPG", []) if l.strip()]
    lists = g("APTLISTS")
    batt = g("BATT")
    battery = None
    if batt == "__ABSENT__":
        battery = fail("termux-battery-status ausente (pacote termux-api não instalado)")
    else:
        try:
            battery = {"ok": True, **json.loads(batt)}
        except Exception:
            battery = fail(f"saída inválida: {short(batt, 80)}")
    boot_scripts = [l for l in sec.get("BOOTSCRIPTS", []) if l.strip()]
    termux_boot = {
        "pkg": g("BOOTPKG") == "yes",
        "dir": g("BOOTDIR") == "yes",
        "scripts": boot_scripts,
        "ok": g("BOOTPKG") == "yes" and g("BOOTDIR") == "yes" and bool(boot_scripts),
    }
    return {"ok": True, "error": "", "latency_s": round(lat, 1), "patch": g("PATCH"), "android": g("ANDROID"),
            "model": g("MODEL"), "uptime": g("UPTIME"), "sshd_running": g("SSHDPROC") == "yes", "sshd": sshd,
            "ak": ak, "upgradable": upg, "apt_lists_epoch": int(lists) if lists.isdigit() else None, "battery": battery,
            "termux_boot": termux_boot}


def collect_box():
    r = {"ok": True, "error": ""}
    try:
        u = shutil.disk_usage("/")
        # mesmo critério do df: usado / (usado + livre p/ usuário comum), arredondado para cima
        r["disk"] = {"total": u.total, "used": u.used, "free": u.free, "pct": float(-(-100 * u.used // (u.used + u.free)))}
    except Exception as e:
        r["disk"] = fail(e)
    try:
        mi = {}
        for l in open("/proc/meminfo"):
            k, v = l.split(":")
            mi[k] = int(v.split()[0]) * 1024
        r["mem"] = {"total": mi["MemTotal"], "avail": mi["MemAvailable"], "pct_avail": 100.0 * mi["MemAvailable"] / mi["MemTotal"],
                    "swap_total": mi.get("SwapTotal", 0), "swap_free": mi.get("SwapFree", 0)}
    except Exception as e:
        r["mem"] = fail(e)
    try:
        la = open("/proc/loadavg").read().split()
        r["load"] = {"l1": float(la[0]), "l5": float(la[1]), "l15": float(la[2]), "ncpu": os.cpu_count()}
    except Exception as e:
        r["load"] = fail(e)
    try:
        r["uptime_s"] = float(open("/proc/uptime").read().split()[0])
    except Exception:
        r["uptime_s"] = None
    # a chave do box usada no dispositivo Android tem passphrase? (ssh-keygen -y -P '' só funciona se NÃO tiver; saída descartada)
    rc, _, err = run(["ssh-keygen", "-y", "-P", "", "-f", BOX_KEY], 10)
    r["key_no_passphrase"] = (rc == 0) if rc in (0, 255, 1) else None
    return r


def collect_audit():
    files = sorted(glob.glob(os.path.join(OPS, "*-auditoria-android.md")))
    if not files:
        return fail("nenhum *-auditoria-android.md em " + OPS)
    path = files[-1]
    m = re.match(r"(\d{4})-(\d\d)-(\d\d)", os.path.basename(path))
    date = f"{m.group(3)}/{m.group(2)}/{m.group(1)}" if m else "?"
    txt = open(path, encoding="utf-8").read()
    sec6 = re.search(r"^## 6\..*?$(.*?)^## ", txt, re.S | re.M)
    items = []
    if sec6:
        blocks = re.split(r"^\*\*(?=\d+\.)", sec6.group(1), flags=re.M)
        for b in blocks:
            h = re.match(r"(\d+)\.\s+([A-ZÁÉÍÓÚÇ/]+):\s*(.+?)\*\*", b)
            if not h:
                continue
            act = re.search(r"\*Ação sugerida:\*(.*?)(?=^- \*|^\*\*|\Z)", b, re.S | re.M)
            action = ""
            if act:
                lines = [re.sub(r"^[-\s]+", "", l).strip() for l in act.group(1).splitlines()]
                action = "; ".join(l for l in lines if l).replace(":;", ":")
                action = short(re.sub(r"[`*]", "", action), 170)
            items.append({"n": int(h.group(1)), "sev": h.group(2), "title": h.group(3).strip(), "action": action})
    extra, head = [], ""
    for l in txt.splitlines():
        if l.startswith("## "):
            head = re.sub(r"\s*\(.*?\)\s*$", "", l[3:]).strip()
        if re.search(r"falta conferir", l, re.I):
            seg = next(x for x in re.split(r"[;.]\s+", l) if re.search(r"falta conferir", x, re.I))
            seg = re.sub(r"[`*]", "", seg).strip(" -.")
            extra.append(short(seg[:1].upper() + seg[1:] + (f" (seção “{head}”)" if head else ""), 160))
    has_fix = bool(re.search(r"^## Correções aplicadas", txt, re.M))
    return {"ok": True, "error": "", "path": path, "date": date, "items": items, "extra": extra, "has_fix_section": has_fix}




def reconcile_termux_boot_live(saud, rd):
    """Sobrescreve o item termux_boot do snapshot com o estado AO VIVO do collect_android.
    Só altera saud em memória (não grava o JSON). Se o vivo confirma pkg+dir+scripts, level=green.
    """
    if not (saud and saud.get("ok") and rd and rd.get("ok") and isinstance(rd.get("termux_boot"), dict)):
        return saud
    tb = rd["termux_boot"]
    termux = saud.setdefault("termux", {})
    items = termux.setdefault("items", [])
    detail = (
        f"ao vivo: com.termux.boot={'instalado' if tb.get('pkg') else 'AUSENTE'}; "
        f"~/.termux/boot={'existe' if tb.get('dir') else 'inexistente'}"
        + (f" (scripts: {', '.join(tb.get('scripts') or [])})" if tb.get('scripts') else "")
        + ("." if tb.get('ok') else ". sshd NÃO tem autostart completo.")
    )
    level = "green" if tb.get("ok") else "amber"
    found = False
    for it in items:
        if it.get("id") == "termux_boot":
            it["level"] = level
            it["detail"] = detail
            it["title"] = "termux-boot / serviços autostart"
            found = True
            break
    if not found:
        items.append({"id": "termux_boot", "level": level, "title": "termux-boot / serviços autostart", "detail": detail})
    # Recalcula section_status do grupo termux a partir dos levels
    lv = [it.get("level") for it in items if it.get("level") in ("red", "amber")]
    termux["section_status"] = "red" if "red" in lv else "amber" if "amber" in lv else "green"
    return saud


def collect_security_audit():
    """Lê o snapshot da auditoria VPN/terminal Android (somente leitura; gerado à mão)."""
    if not os.path.isfile(SECURITY_AUDIT):
        return fail(f"{SECURITY_AUDIT} ausente")
    try:
        j = json.load(open(SECURITY_AUDIT, encoding="utf-8"))
    except Exception as e:
        return fail(f"JSON inválido: {e}")
    j["ok"] = True
    j["error"] = ""
    return j


# ---------------------------------------------------------------- análise
ORDER = {"red": 0, "amber": 1, "info": 2, "green": 3, "na": 1}


def build(nm, ts, ag, rd, bx, au, saud=None):
    alerts = []   # {level, section, text, source}
    unavailable = []

    def A(level, section, text, source="dashboard"):
        alerts.append({"level": level, "section": section, "text": text, "source": source})

    def U(section, what, err):
        unavailable.append({"section": section, "check": what, "reason": err})

    snap = nm.get("snapshot", {}) if nm.get("ok") else {}
    # ---- netmon (reutilizado) ----
    if nm.get("ok"):
        lv = {"ALERTA": "red", "HEURÍSTICA": "amber", "INFO": "info"}
        for a in nm.get("alerts", []):
            t = a["text"]
            sec = ("Meu computador" if re.match(r"(Firewall|Outro processo|AdGuard Home NÃO|AdGuard: processo|AdGuard escutando|DNS:)", t)
                   else "VPN" if re.match(r"(VPN|Rede VPN)", t)
                   else "AdGuard" if t.startswith("AdGuard")
                   else "dispositivo Android" if re.match(r"(dispositivo Android|Wi-Fi)", t) else "Geral")
            for ip, lab in CLIENT_LABEL.items():
                if ip in t and "cliente" in t:
                    t += f" [{ip} = {lab.split(' (')[0]}]"
            A(lv.get(a["level"], "amber"), sec, t, "netmon")
    else:
        U("Geral", "netmon.sh --json", nm["error"])
        A("amber", "Geral", "netmon indisponível: " + nm["error"])

    # ---- VPN ----
    if ts.get("ok"):
        if ts["backend"] != "Running" and not nm.get("ok"):
            A("red", "VPN", f"VPN não está ativo (estado {ts['backend']})")
        for p in ts["peers"]:
            if p["key"] == ANDROID_PEER and not p["online"]:
                d = parse_ts(p["last_seen"])
                A("amber", "VPN", f"dispositivo Android offline na rede VPN (visto por último {brt(d)} {ago(d)})")
        if ts["health"]:
            for h in ts["health"]:
                A("amber", "VPN", "Aviso de saúde do VPN: " + short(h.splitlines()[0].split(": adding")[0], 90) + " (detalhe no card)")
        d = ts.get("dns", {})
        if d.get("ok"):
            if BOX_IP not in (d.get("resolvers") or []):
                A("red", "VPN", f"DNS global da rede VPN não aponta para o AdGuard {BOX_IP} (resolvers: {', '.join(d.get('resolvers') or []) or 'nenhum'})")
        else:
            U("VPN", "vpn dns status", d.get("error"))
        if not ts.get("prefs", {}).get("ok"):
            U("VPN", "vpn debug prefs", ts["prefs"].get("error"))
    else:
        U("VPN", "vpn status --json", ts["error"])
        A("red", "VPN", "VPN indisponível: " + ts["error"])

    android_online = any(p["key"] == ANDROID_PEER and p["online"] for p in ts.get("peers", [])) if ts.get("ok") else None

    # ---- AdGuard ----
    if ag.get("ok"):
        s = ag["status"]
        if not s.get("running"):
            A("red", "AdGuard", "AdGuard: API diz que o DNS NÃO está rodando")
        if not s.get("protection_enabled"):
            A("red", "AdGuard", "AdGuard: proteção (filtragem) DESLIGADA")
        if android_online and ag["android"]["hour_n"] == 0:
            A("amber", "AdGuard", "dispositivo Android online, mas 0 consultas DNS no AdGuard na última hora (Use VPN DNS ligado no app?)")
    else:
        U("AdGuard", "API /control/*", ag["error"])
        A("amber" if nm.get("ok") else "red", "AdGuard", "API do AdGuard indisponível: " + ag["error"])

    # ---- dispositivo Android ----
    if rd.get("ok"):
        sd = rd["sshd"]
        one = lambda k: (sd.get(k) or [""])[0].lower()
        if not sd:
            U("dispositivo Android", "sshd -T", "sem saída")
        else:
            if one("passwordauthentication") != "no":
                A("red", "dispositivo Android", f"sshd: PasswordAuthentication = {one('passwordauthentication') or '?'}")
            if one("kbdinteractiveauthentication") not in ("no",):
                A("amber", "dispositivo Android", f"sshd: KbdInteractiveAuthentication = {one('kbdinteractiveauthentication') or '?'}")
            for k in ("allowtcpforwarding", "allowagentforwarding"):
                if one(k) != "no":
                    A("amber", "dispositivo Android", f"sshd: {k} = {one(k) or '?'} (relatório recomendou 'no')")
            la = sd.get("listenaddress", [])
            if any(x.startswith(("0.0.0.0", "[::]", "::")) for x in la):
                A("amber", "dispositivo Android", "sshd escuta em todas as interfaces (" + ", ".join(la) + ")")
        for k in rd["ak"]:
            if "from=" not in k["options"] and "restrict" not in k["options"]:
                A("amber", "dispositivo Android", f"authorized_keys: chave {k['type']} {k['fingerprint'][:20]}… sem restrição from=/restrict")
        if len(rd["ak"]) != 1:
            A("amber", "dispositivo Android", f"authorized_keys tem {len(rd['ak'])} chaves (relatório: 1 chave conhecida)")
        if rd["upgradable"]:
            A("amber", "dispositivo Android", f"{len(rd['upgradable'])} pacote(s) terminal Android com atualização pendente")
        try:
            pd = dt.date.fromisoformat(rd["patch"])
            age = (NOW.date() - pd).days
            rd["patch_age"] = age
            if age > 120:
                A("red", "dispositivo Android", f"Patch de segurança Android {rd['patch']} ({age} dias)")
            elif age > 60:
                A("amber", "dispositivo Android", f"Patch de segurança Android {rd['patch']} ({age} dias; > 60)")
        except Exception:
            rd["patch_age"] = None
            U("dispositivo Android", "patch de segurança", f"valor ilegível: {rd['patch']!r}")
        if not rd["battery"].get("ok"):
            U("dispositivo Android", "bateria", rd["battery"]["error"])
    else:
        U("dispositivo Android", "SSH (checagens extras)", rd["error"])
        if not (nm.get("ok") and not snap.get("android", {}).get("ok", True)):  # netmon já alertou se ele também falhou
            A("red" if android_online else "amber", "dispositivo Android", "dispositivo Android: SSH inacessível: " + rd["error"])

    # ---- Meu computador ----
    if bx.get("disk", {}).get("pct") is not None:
        p = bx["disk"]["pct"]
        if p >= 95: A("red", "Meu computador", f"Disco / {p:.0f}% cheio")
        elif p >= 85: A("amber", "Meu computador", f"Disco / {p:.0f}% cheio")
    if bx.get("mem", {}).get("pct_avail") is not None:
        p = bx["mem"]["pct_avail"]
        if p < 5: A("red", "Meu computador", f"Memória disponível só {p:.0f}%")
        elif p < 10: A("amber", "Meu computador", f"Memória disponível só {p:.0f}%")
    if bx.get("load", {}).get("l5") is not None and bx["load"]["ncpu"]:
        if bx["load"]["l5"] > 2 * bx["load"]["ncpu"]:
            A("amber", "Meu computador", f"Carga alta: {bx['load']['l5']} (5 min) para {bx['load']['ncpu']} CPUs")

    # ---- Pendências da auditoria (com checagem ao vivo onde dá) ----
    pend = []
    if au.get("ok"):
        for it in au["items"]:
            t = it["title"].lower()
            live, state = "", "pendente (verificação manual; não checável pelo shell)" if "não verificáve" in t or "sessões" in t else "pendente"
            if re.search(r"desatualizad", t):
                if rd.get("ok"):
                    n = len(rd["upgradable"])
                    le = dt.datetime.fromtimestamp(rd["apt_lists_epoch"], TZ) if rd.get("apt_lists_epoch") else None
                    live = f"ao vivo: {n} pacote(s) pendente(s) (listas apt do telefone de {brt(le, '%d/%m %H:%M')})"
                    state = "resolvido (ao vivo)" if n == 0 else "pendente (ao vivo)"
                else:
                    live = "ao vivo: indisponível (" + rd["error"] + ")"
            elif re.search(r"chave ssh|forwarding", t):
                if rd.get("ok"):
                    sd = rd["sshd"]
                    ok_fw = all((sd.get(k) or [""])[0].lower() == "no" for k in ("allowtcpforwarding", "allowagentforwarding"))
                    ok_ak = bool(rd["ak"]) and all("from=" in k["options"] for k in rd["ak"])
                    np = bx.get("key_no_passphrase")
                    live = (f"ao vivo: forwarding {'bloqueado' if ok_fw else 'LIBERADO'}; authorized_keys {'com' if ok_ak else 'SEM'} from=; "
                            f"chave do box {'ainda SEM passphrase' if np else ('com passphrase' if np is False else 'passphrase: indisponível')}")
                    state = ("mitigado (ao vivo); resta: chave sem passphrase" if ok_fw and ok_ak and np else
                             "resolvido (ao vivo)" if ok_fw and ok_ak else "pendente (ao vivo)")
                else:
                    live = "ao vivo: indisponível (" + rd["error"] + ")"
            elif re.search(r"todas as interfaces|0\.0\.0\.0", t):
                if rd.get("ok"):
                    la = rd["sshd"].get("listenaddress", [])
                    anyif = any(x.startswith(("0.0.0.0", "[::]", "::")) for x in la)
                    live = "ao vivo: ListenAddress " + (", ".join(la) or "?")
                    state = "pendente (ao vivo)" if anyif or not la else "resolvido (ao vivo)"
                else:
                    live = "ao vivo: indisponível (" + rd["error"] + ")"
            elif re.search(r"patch", t):
                if rd.get("ok") and rd.get("patch_age") is not None:
                    live = f"ao vivo: patch {rd['patch']} ({rd['patch_age']} dias)"
                    state = "pendente (ao vivo)" if rd["patch_age"] > 31 else "resolvido (ao vivo)"
                else:
                    live = "ao vivo: indisponível"
            pend.append({**it, "state": state, "live": live, "label": f"do relatório de {au['date']}"})
        for e in au["extra"]:
            live = ""
            if re.search(r"Use VPN DNS", e) and ag.get("ok"):
                r = ag["android"]
                live = (f"ao vivo: AdGuard recebeu {r['hour_n']} consultas do dispositivo Android ({ANON_ANDROID}) na última hora → indica que o app já usa o DNS da rede VPN"
                        if r["hour_n"] else "ao vivo: 0 consultas do dispositivo Android na última hora")
            pend.append({"n": None, "sev": "INFO", "title": e, "action": "", "state": "a conferir" if not live or "0 consultas" in live else "indício ao vivo de resolvido",
                         "live": live, "label": f"do relatório de {au['date']}"})
    else:
        U("Pendências", "relatório de auditoria", au["error"])


    # ---- Segurança VPN / terminal Android (snapshot da auditoria) ----
    # Preferir estado ao vivo do dispositivo Android/SSH sobre snapshot velho (ex.: sshd closed às 08:41
    # enquanto a auditoria completa ~09:05 e o collect_android já mostram sshd up).
    saud = saud or {}
    live_sshd_up = bool(rd.get("ok") and rd.get("sshd_running"))
    live_android_online = any(p.get("key") == ANDROID_PEER and p.get("online") for p in (ts.get("peers") or [])) if ts.get("ok") else None
    if saud.get("ok"):
        for group, sec_name in (("vpn", "Segurança VPN"), ("termux", "Segurança terminal Android")):
            g = saud.get(group) or {}
            for it in g.get("items") or []:
                lv = it.get("level")
                iid = it.get("id") or ""
                # termux_boot: se o vivo já reconciliou para green, não alerta amber velho
                if iid == "termux_boot" and lv == "amber" and rd.get("ok") and (rd.get("termux_boot") or {}).get("ok"):
                    continue
                # Snapshot dizendo "sshd/8022 closed" não pode pintar vermelho se o vivo contradiz
                if iid in ("sshd_listen", "reach_android") and lv == "red":
                    if live_sshd_up:
                        continue  # vivo: sshd up — ignora vermelho antigo
                    if live_android_online is False:
                        # peer offline: o alerta de VPN (amber) já cobre; não duplicar red velho
                        A("amber", sec_name, f"{it.get('title')}: snapshot antigo falava closed; agora dispositivo Android offline na rede VPN (estado ao vivo)", "auditoria+vivo")
                        continue
                # só red/amber viram alerta global; "na" fica só no card (não verificado)
                if lv == "red":
                    A("red", sec_name, f"{it.get('title')}: {it.get('detail')}", "auditoria")
                elif lv == "amber":
                    A("amber", sec_name, f"{it.get('title')}: {it.get('detail')}", "auditoria")
    else:
        if saud:
            U("Segurança VPN", "security-audit-latest.json", saud.get("error", "indisponível"))
            U("Segurança terminal Android", "security-audit-latest.json", saud.get("error", "indisponível"))

    alerts.sort(key=lambda a: ORDER[a["level"]])

    def sec_status(name, core_ok):
        if not core_ok:
            return "indisponível"
        lv = [a["level"] for a in alerts if a["section"] == name and a["level"] in ("red", "amber")]
        return "red" if "red" in lv else "amber" if "amber" in lv else "green"

    def sec_audit_status(group_key, label):
        if not saud.get("ok"):
            return "indisponível"
        g = saud.get(group_key) or {}
        # prefer snapshot section_status, but escalate if live alerts exist
        base = g.get("section_status") or "green"
        lv = [a["level"] for a in alerts if a["section"] == label and a["level"] in ("red", "amber")]
        if "red" in lv or base == "red":
            return "red"
        if "amber" in lv or base == "amber":
            return "amber"
        return "green"

    sections = {
        "VPN": sec_status("VPN", ts.get("ok")),
        "Segurança VPN": sec_audit_status("vpn", "Segurança VPN"),
        "AdGuard": sec_status("AdGuard", ag.get("ok")),
        "dispositivo Android": sec_status("dispositivo Android", rd.get("ok")),
        "Segurança terminal Android": sec_audit_status("termux", "Segurança terminal Android"),
        "Meu computador": sec_status("Meu computador", nm.get("ok")),
        "Pendências da auditoria": "indisponível" if not au.get("ok") else
            ("amber" if any(p["state"].startswith(("pendente", "mitigado", "a conferir")) for p in pend) else "green"),
    }
    lv = [a["level"] for a in alerts]
    overall = "red" if "red" in lv else "amber" if "amber" in lv or "indisponível" in sections.values() else "green"
    return alerts, unavailable, pend, sections, overall


# ---------------------------------------------------------------- renderização
E = lambda s: html.escape(str(s))
LVL_TXT = {"red": "CRÍTICO", "amber": "ATENÇÃO", "info": "INFO", "green": "OK", "indisponível": "INDISPONÍVEL"}


def NA(reason):
    return f'<span class="na">indisponível — {E(short(reason, 150))}</span>'


def kv(rows):
    return "<table class='kv'>" + "".join(f"<tr><th>{E(k)}</th><td>{v}</td></tr>" for k, v in rows) + "</table>"


def dot(ok, txt_ok="sim", txt_no="não", warn=False):
    if ok is None:
        return '<span class="na">indisponível</span>'
    cls = "g" if ok else ("a" if warn else "r")
    return f'<span class="pill {cls}">{E(txt_ok if ok else txt_no)}</span>'


def badge(st):
    cls = {"red": "r", "amber": "a", "green": "g", "info": "i"}.get(st, "n")
    return f'<span class="badge {cls}">{E(LVL_TXT.get(st, st))}</span>'


def card(title, status, body, sub=""):
    return (f'<section class="card"><div class="ch"><h2>{E(title)}</h2>{badge(status)}</div>'
            + (f'<div class="sub">{sub}</div>' if sub else "") + body + "</section>")


def fmt_uptime(u):
    """'11:51:56 up 2 days,  3:18,  0 users, ...' -> '2 d 3 h 18 min' (texto original se não reconhecer)."""
    m = re.search(r"up\s+(?:(\d+)\s+days?,\s*)?(?:(\d+):(\d+)|(\d+)\s+min)", u)
    if not m:
        return u.strip() or "?"
    d, h, mi, mm = m.groups()
    h, mi = (int(h), int(mi)) if h else (0, int(mm))
    return (f"{d} d " if d else "") + (f"{h} h " if h else "") + f"{mi} min"


def gb(n):
    return f"{n / 1024 ** 3:.1f} GB".replace(".", ",")


def render(nm, ts, ag, rd, bx, au, alerts, unavailable, pend, sections, overall, saud=None):
    snap = nm.get("snapshot", {}) if nm.get("ok") else {}
    parts = []
    # ---------- cabeçalho ----------
    cnt = {k: sum(1 for a in alerts if a["level"] == k) for k in ("red", "amber", "info")}
    head = {"red": "Há alertas críticos", "amber": "Há pontos de atenção", "green": "Tudo verde"}[overall]
    parts.append(f'''<header class="hd {overall}"><div><div class="t1">Painel de segurança · casa</div>
      <div class="t2">{E(head)}</div></div><div class="cnt"><span class="pill r">{cnt["red"]} críticos</span>
      <span class="pill a">{cnt["amber"]} atenção</span><span class="pill i">{cnt["info"]} info</span></div></header>''')
    # ---------- alertas ----------
    if alerts:
        li = "".join(f'<li class="al {a["level"]}"><span class="tag">{E(a["section"])}</span>{E(a["text"])}'
                     f'<span class="src">· {E(a["source"])}</span></li>' for a in alerts)
        body = f"<ul class='alerts'>{li}</ul>"
        if any(a["source"] == "netmon" for a in alerts):
            body += ("<div class='note'>Alertas do netmon comparados com a baseline continuam aparecendo até alguém rodar "
                     "<code>netmon.sh --rebaseline</code> à mão (o painel nunca faz isso).</div>")
    else:
        body = "<div class='allok'>✓ Nenhum alerta nas checagens desta execução.</div>"
    parts.append(card("Alertas", overall, body))

    # ---------- VPN ----------
    if ts.get("ok"):
        s = ts["self"]
        rows = [("Este computador", f"{dot(ts['backend'] == 'Running', 'Running', ts['backend'] or '?')} {E(s['name'])} · {E(', '.join(s['ips'][:1]))}"),
                ("Rede VPN", f"{E(ts['rede VPN'])} · MagicDNS {'ligado' if ts['magicdns'] else 'desligado'}"),
                ("Versão", E(ts["version"].split("-")[0]))]
        on = sum(1 for p in ts["peers"] if p["online"])
        dev = "".join(
            f"<tr><td><b>{E(p['key'])}</b><br><span class='mut'>{E(p['os'])}</span></td><td>{E(p['ip'])}</td>"
            f"<td>{dot(p['online'], 'online', 'offline', warn=True)}<br><span class='mut'>{E(p['conn'])}</span></td>"
            f"<td>{(('último handshake ' + E(brt(parse_ts(p['last_handshake']), '%H:%M:%S')) + ' · ' + E(ago(parse_ts(p['last_handshake'])))) if p['online'] and parse_ts(p['last_handshake']) else ('online agora' if p['online'] else 'visto ' + E(brt(parse_ts(p['last_seen']))) + ' ' + E(ago(parse_ts(p['last_seen'])))))}</td></tr>"
            for p in ts["peers"])
        tbl = f"<h3>Dispositivos ({on}/{len(ts['peers'])} remotos online)</h3><table class='grid'><tr><th>Nome</th><th>IP</th><th>Estado</th><th>Último contato</th></tr>{dev}</table>"
        d = ts.get("dns", {})
        if d.get("ok"):
            pr = ts.get("prefs", {})
            dr = [("DNS global (do servidor VPN)", E(", ".join(d["resolvers"]) or "nenhum") + (" <span class='mut'>= AdGuard</span>" if BOX_IP in d["resolvers"] else "")),
                  ("DNS dividido", E("; ".join(f"{k} → {', '.join(v)}" for k, v in d["split"].items()) or "nenhum")),
                  ("'Use VPN DNS' neste computador", (("ligado" if pr.get("CorpDNS") else "desligado (o próprio box roda o AdGuard)") if pr.get("ok") else NA(pr.get("error")))),
                  ("DNS do sistema do box", E(", ".join(d["system_ns"]) or "—")),
                  ("'Override local DNS'", "<span class='mut'>não exposto pela CLI local (só no painel admin)</span>")]
            dns = "<h3>DNS (preferências locais)</h3>" + kv(dr)
        else:
            dns = "<h3>DNS</h3>" + NA(d.get("error"))
        hl = ""
        if ts["health"]:
            hl = "<div class='note'>Saúde: " + E(short(ts["health"][0], 200)) + "</div>"
        parts.append(card("VPN", sections["VPN"], kv(rows) + tbl + dns + hl))
    else:
        parts.append(card("VPN", "indisponível", NA(ts["error"])))

    # ---------- Segurança VPN / terminal Android ----------
    def _sec_card(title, group_key, status_key):
        st = sections.get(status_key, "indisponível")
        if not (saud and saud.get("ok")):
            return card(title, "indisponível", NA((saud or {}).get("error", "security-audit-latest.json ausente")))
        g = saud.get(group_key) or {}
        items = g.get("items") or []
        li = []
        for it in items:
            lv = it.get("level") or "na"
            pill = {"green": ("g", "OK"), "amber": ("a", "ATENÇÃO"), "red": ("r", "CRÍTICO"), "na": ("n", "NÃO VERIFICADO")}.get(lv, ("n", lv))
            li.append(f"<li><span class='pill {pill[0]}'>{E(pill[1])}</span> <b>{E(it.get('title',''))}</b>"
                      f"<div class='mut'>{E(it.get('detail',''))}</div></li>")
        sub = f"Fonte: {E(os.path.basename(saud.get('report_path') or SECURITY_AUDIT))} · gerado {E(saud.get('generated_at_brt') or '—')}"
        return card(title, st, f"<ul class='plain'>{''.join(li)}</ul>", sub)

    parts.append(_sec_card("Segurança VPN", "vpn", "Segurança VPN"))
    parts.append(_sec_card("Segurança terminal Android", "termux", "Segurança terminal Android"))

    # ---------- AdGuard ----------
    if ag.get("ok"):
        s, st = ag["status"], ag["stats"]
        apid = snap.get("box", {}).get("adguard", {})
        started = dt.datetime.fromtimestamp(s["start_time"] / 1000, TZ) if s.get("start_time") else None
        win = ag.get("stats_interval_h")
        winl = f"{win:g} h" if win else "janela do AdGuard"
        q, b = st.get("num_dns_queries", 0), st.get("num_blocked_filtering", 0)
        rows = [("Serviço", f"{dot(s.get('running'), 'rodando', 'PARADO')} {E(s.get('version'))} · proteção {dot(s.get('protection_enabled'), 'ligada', 'DESLIGADA')}"),
                ("Ativo desde", f"{E(brt(started, '%d/%m %H:%M'))} ({E(ago(started))})"),
                (f"Consultas ({winl})", f"<b class='big'>{num(q)}</b>"),
                (f"Bloqueadas ({winl})", f"<b class='big'>{num(b)}</b> = <b>{pct(b, q)}</b>"),
                ("IP de cliente", "anonimizado (/16)" if ag.get("ql_config", {}).get("anonymize_client_ip") else "completo")]
        tb = st.get("top_blocked_domains") or []
        tbl = "<h3>Mais bloqueados (" + E(winl) + ")</h3>" + ("<table class='grid'>" + "".join(
            f"<tr><td>{E(list(x)[0])}</td><td class='n'>{num(list(x.values())[0])}</td></tr>" for x in tb[:6]) + "</table>" if tb else "<div class='mut'>nenhum</div>")
        tc = st.get("top_clients") or []
        cl = "<h3>Clientes (" + E(winl) + ")</h3>" + ("<table class='grid'>" + "".join(
            f"<tr><td>{E(list(x)[0])} <span class='mut'>{E(CLIENT_LABEL.get(list(x)[0], 'desconhecido'))}</span></td><td class='n'>{num(list(x.values())[0])}</td></tr>" for x in tc) + "</table>" if tc else "<div class='mut'>nenhum</div>")
        r = ag["android"]
        rr = [("Consultas na última hora", f"<b class='big'>{num(r['hour_n'])}</b>" + (" <span class='mut'>(parcial)</span>" if r["partial"] else "")),
              ("Bloqueadas na última hora", f"{num(r['hour_blocked'])} ({pct(r['hour_blocked'], r['hour_n'])})"),
              ("Última consulta", (E(brt(r["_last_dt"])) + " · " + E(ago(r["_last_dt"])) + f"<br><span class='mut'>{E(r['last_domain'])}</span>") if r["_last_dt"] else "nenhuma no querylog")]
        parts.append(card("AdGuard DNS", sections["AdGuard"], kv(rows) + tbl + cl + "<h3>dispositivo Android (cliente " + ANON_ANDROID + ")</h3>" + kv(rr)))
    else:
        parts.append(card("AdGuard DNS", "indisponível", NA(ag["error"])))

    # ---------- dispositivo Android ----------
    nr = snap.get("android", {})
    if rd.get("ok"):
        sd = rd["sshd"]
        g1 = lambda k: E(", ".join(sd.get(k, [])) or "?")
        yn = lambda v: {"no": "não", "yes": "sim"}.get(v.lower(), v)
        good = lambda k, want: dot((sd.get(k) or [""])[0].lower() == want, yn((sd.get(k) or ["?"])[0]), yn((sd.get(k) or ["?"])[0]), warn=True)
        online = next((p["online"] for p in ts.get("peers", []) if p["key"] == ANDROID_PEER), None) if ts.get("ok") else None
        rows = [("VPN", dot(online, "online", "offline", warn=True)),
                ("SSH", f"{dot(True, 'acessível')} <span class='mut'>{rd['latency_s']} s · sshd {'rodando' if rd['sshd_running'] else 'NÃO encontrado'}</span>"),
                ("Aparelho", E(f"{rd['model']} · Android {rd['android']}")),
                ("Patch de segurança", f"<b>{E(rd['patch'])}</b>" + (f" <span class='mut'>({rd['patch_age']} dias)</span>" if rd.get("patch_age") is not None else "")),
                ("Ligado há", E(fmt_uptime(rd["uptime"]))),
                ("Bateria", f"{rd['battery'].get('percentage')}% · {E(rd['battery'].get('status', ''))}" if rd["battery"].get("ok") else NA(rd["battery"]["error"])),
                ("Rede (netmon)", E(f"{nr.get('net_type')} ({nr.get('active_iface')})") if nr.get("ok") else NA(nr.get("error", "netmon sem dados"))),
                ("Apps de terceiros (netmon)", E(nr.get("pkgs_count")) if nr.get("ok") else NA(nr.get("error", "netmon sem dados")))]
        sshd = [("Porta / escuta", f"{g1('port')} · {g1('listenaddress')}"),
                ("Login por senha", good("passwordauthentication", "no")), ("Teclado interativo", good("kbdinteractiveauthentication", "no")),
                ("Login por chave", good("pubkeyauthentication", "yes")),
                ("Encaminhamento TCP", good("allowtcpforwarding", "no")), ("Encaminhamento de agente", good("allowagentforwarding", "no")),
                ("X11", good("x11forwarding", "no")), ("MaxAuthTries", g1("maxauthtries"))]
        ak = "".join(f"<li><code>{E(k['options'])}</code> · {E(k['type'])} · <span class='mut'>{E(k['fingerprint'])}</span></li>" for k in rd["ak"])
        ups = rd["upgradable"]
        le = dt.datetime.fromtimestamp(rd["apt_lists_epoch"], TZ) if rd.get("apt_lists_epoch") else None
        pk = (f"<b class='big'>{len(ups)}</b> " + (E(", ".join(ups[:12])) + (" …" if len(ups) > 12 else "") if ups else "nenhum")
              + f"<br><span class='mut'>pelas listas apt do telefone de {E(brt(le, '%d/%m %H:%M'))}; o painel não roda apt update</span>")
        body = (kv(rows) + "<h3>sshd (sshd -T, efetivo)</h3>" + kv(sshd)
                + f"<h3>authorized_keys ({len(rd['ak'])} chave{'s' if len(rd['ak']) != 1 else ''}, sem mostrar a chave)</h3><ul class='plain'>{ak or '<li>vazio</li>'}</ul>"
                + "<h3>Pacotes terminal Android pendentes</h3>" + f"<div class='pad'>{pk}</div>")
        parts.append(card("dispositivo Android", sections["dispositivo Android"], body))
    else:
        parts.append(card("dispositivo Android", "indisponível", NA(rd["error"])))

    # ---------- Meu computador ----------
    rows = []
    if nm.get("ok"):
        b = snap["box"]
        t = b["vpn"]
        rows.append(("VPN", f"{dot(t.get('backend') == 'Running', 'Running', t.get('backend') or '?')} {E(t.get('self_name'))} {E((t.get('self_ips') or [''])[0])}"))
        for v, nmv in (("v4", "iptables"), ("v6", "ip6tables")):
            f = b["firewall"][v]
            top = ([x for x in f["input"] if x.startswith("-A")] or [""])[0] == "-A INPUT -i vpn0 -j nexo-ts-guard"
            allow = []
            for x in f["chain"]:
                m = re.search(r"-p (\w+) -m \w+ --dport (\d+) -j RETURN", x)
                if m: allow.append(f"{m.group(1)}/{m.group(2)}")
                elif re.search(r"-p (icmp|ipv6-icmp) -j RETURN", x): allow.append("ICMP")
            drop = bool(f["chain"]) and f["chain"][-1].endswith("-j DROP")
            rows.append((f"Firewall {nmv}", f"{dot(top, 'regra no topo', 'FORA do topo')} {dot(bool(f['chain']), 'nexo-ts-guard', 'cadeia AUSENTE')} "
                         f"<span class='mut'>permite {E(', '.join(allow) or 'nada')}{' · resto DROP' if drop else ''}</span>"))
        a = b["adguard"]
        rows.append(("AdGuard (processo)", f"{dot(a['running'], 'PID ' + a['pid'], 'parado')} <span class='mut'>{E(a['exe'])}<br>escuta: {E(', '.join(a['listen']) or '—')}</span>"))
        dn = b["dns"]
        exok = any(re.match(r"^\d+\.\d+\.\d+\.\d+$", x) and x != "0.0.0.0" for x in dn["example"])
        rows.append(("Teste DNS", f"{dot(exok, 'example.com resolve', 'example.com FALHOU')} {dot(dn['doubleclick'] == ['0.0.0.0'], 'doubleclick.net bloqueado', 'doubleclick NÃO bloqueado')}"))
    else:
        rows.append(("VPN / firewall / AdGuard / DNS", NA(nm["error"])))
    d, m, l = bx.get("disk", {}), bx.get("mem", {}), bx.get("load", {})
    rows.append(("Disco /", f"{d['pct']:.0f}% usado · {gb(d['free'])} livres de {gb(d['total'])}" if "pct" in d else NA(d.get("error"))))
    rows.append(("Memória", f"{m['pct_avail']:.0f}% disponível · {gb(m['avail'])} de {gb(m['total'])}" if "pct_avail" in m else NA(m.get("error"))))
    rows.append(("Carga (1/5/15 min)", f"{l['l1']} / {l['l5']} / {l['l15']} <span class='mut'>({l['ncpu']} CPUs)</span>" if "l1" in l else NA(l.get("error"))))
    if bx.get("uptime_s") is not None:
        up = bx["uptime_s"]
        rows.append(("Ligado há", (f"{int(up // 86400)} d " if up >= 86400 else "") + f"{int(up % 86400 // 3600)} h {int(up % 3600 // 60)} min"))
    parts.append(card("Meu computador (servidor)", sections["Meu computador"], kv(rows)))

    # ---------- Pendências ----------
    if au.get("ok"):
        li = []
        for p in pend:
            stc = "g" if p["state"].startswith(("resolvido", "indício")) else "a"
            sev = {"ALTO": "r", "MÉDIO": "a", "BAIXO/MÉDIO": "a"}.get(p["sev"], "n")
            li.append(f"<li><div><span class='pill {sev}'>{E(p['sev'])}</span> <b>{E((str(p['n']) + '. ') if p['n'] else '')}{E(p['title'])}</b></div>"
                      f"<div class='mut'>{E(p['label'])}{(' · ação sugerida: ' + E(p['action'])) if p['action'] else ''}</div>"
                      f"<div><span class='pill {stc}'>{E(p['state'])}</span> {E(p['live'])}</div></li>")
        sub = f"Fonte: {E(os.path.basename(au['path']))}. Itens são <b>do relatório</b>; só o que diz “ao vivo” foi checado agora."
        parts.append(card("Pendências da auditoria", sections["Pendências da auditoria"], f"<ul class='pend'>{''.join(li)}</ul>", sub))
    else:
        parts.append(card("Pendências da auditoria", "indisponível", NA(au["error"])))

    # ---------- indisponíveis + rodapé ----------
    if unavailable:
        parts.append(card("Checagens indisponíveis", "amber", "<ul class='plain'>" + "".join(
            f"<li><b>{E(u['section'])}</b> · {E(u['check'])}: <span class='na'>{E(short(u['reason'], 160))}</span></li>" for u in unavailable) + "</ul>"))
    dur = time.time() - T0
    parts.append(f"<footer>Gerado em {E(NOW.strftime('%d/%m/%Y %H:%M:%S'))} BRT (America/Sao_Paulo) · coleta em {dur:.0f} s · "
                 f"fontes: netmon.sh --json, vpn CLI, API do AdGuard, SSH no dispositivo Android, /proc do box, auditoria VPN/terminal Android</footer>")
    return HTML_HEAD + "".join(parts) + "</main></body></html>"


HTML_HEAD = """<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><style>
*{box-sizing:border-box} body{margin:0;background:#0b1220;color:#e5e7eb;font-family:'Noto Sans','DejaVu Sans',sans-serif;font-size:25px;line-height:1.35}
main{width:1200px;padding:24px 28px 30px}
.hd{display:flex;justify-content:space-between;align-items:center;border-radius:18px;padding:22px 26px;margin-bottom:22px}
.hd.red{background:#7f1d1d}.hd.amber{background:#78350f}.hd.green{background:#14532d}
.t1{font-size:24px;opacity:.85}.t2{font-size:40px;font-weight:700}.cnt{display:flex;flex-direction:column;gap:6px;align-items:flex-end}
.card{background:#111a2e;border:1px solid #1f2a44;border-radius:18px;padding:18px 24px 20px;margin-bottom:20px}
.ch{display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid #1f2a44;padding-bottom:10px;margin-bottom:10px}
h2{margin:0;font-size:33px} h3{margin:16px 0 6px;font-size:25px;color:#93c5fd;font-weight:600}
.sub{color:#9ca3af;font-size:21px;margin-bottom:6px}
.badge{font-weight:700;font-size:21px;padding:6px 14px;border-radius:999px}
.badge.r,.pill.r{background:#dc2626;color:#fff}.badge.a,.pill.a{background:#f59e0b;color:#111}.badge.g,.pill.g{background:#16a34a;color:#fff}
.badge.i,.pill.i{background:#2563eb;color:#fff}.badge.n,.pill.n{background:#4b5563;color:#fff}
.pill{display:inline-block;font-size:20px;font-weight:600;padding:2px 10px;border-radius:999px;margin:2px 4px 2px 0;white-space:nowrap}
table{border-collapse:collapse;width:100%} .kv th{text-align:left;color:#9ca3af;font-weight:500;width:36%;vertical-align:top;padding:6px 10px 6px 0}
.kv td{padding:6px 0;vertical-align:top} .grid th{text-align:left;color:#9ca3af;font-weight:500;font-size:21px;border-bottom:1px solid #1f2a44;padding:4px 8px 4px 0}
.grid td{padding:6px 8px 6px 0;border-bottom:1px solid #18223a;vertical-align:top} .n{text-align:right;font-weight:700}
.mut{color:#9ca3af;font-size:21px}.big{font-size:31px}.na{color:#fbbf24;font-style:italic}
code{font-family:'DejaVu Sans Mono',monospace;font-size:20px;background:#0b1220;padding:1px 6px;border-radius:6px;word-break:break-all}
ul{margin:0;padding:0;list-style:none}.alerts li{padding:10px 14px;border-radius:12px;margin:8px 0;border-left:10px solid}
.al.red{background:#3b0d0d;border-color:#dc2626}.al.amber{background:#3a2606;border-color:#f59e0b}.al.info{background:#0c1d40;border-color:#2563eb}
.tag{font-weight:700;margin-right:10px}.src{color:#9ca3af;font-size:18px;margin-left:10px;white-space:nowrap}
.allok{background:#0f2e1b;border-left:10px solid #16a34a;padding:14px;border-radius:12px;font-size:28px}
.note{color:#9ca3af;font-size:20px;margin-top:10px}.plain li{padding:5px 0;border-bottom:1px solid #18223a}
.pend li{padding:10px 0;border-bottom:1px solid #1f2a44}.pad{padding:4px 0}
footer{color:#9ca3af;font-size:21px;text-align:center;padding:8px 10px 0}
</style></head><body><main>"""


def screenshot(html_path, png_path):
    chrome = next((c for c in ("google-chrome", "chromium", "chromium-browser") if shutil.which(c)), None)
    if not chrome:
        raise RuntimeError("nenhum Chrome/Chromium encontrado para renderizar o PNG")
    from PIL import Image, ImageChops
    for h in (6000, 12000):
        rc, out, err = run([chrome, "--headless=new", "--no-sandbox", "--disable-gpu", "--hide-scrollbars",
                            "--force-device-scale-factor=1", f"--window-size=1200,{h}", f"--screenshot={png_path}",
                            "file://" + html_path], timeout=90)
        if rc != 0 or not os.path.exists(png_path):
            raise RuntimeError(f"chrome rc={rc}: {short(err, 200)}")
        im = Image.open(png_path).convert("RGB")
        bg = Image.new("RGB", im.size, im.getpixel((2, im.height - 2)))
        bbox = ImageChops.difference(im, bg).getbbox()
        if bbox and bbox[3] < h - 5:
            im = im.crop((0, 0, 1200, min(h, bbox[3] + 24)))
            break
    # paleta de 256 cores: ~4x menor, sem perda visível neste layout (cores chapadas + texto)
    im.quantize(colors=256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).save(png_path, optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    nm = collect_netmon()
    ts = collect_vpn()
    ag = collect_adguard()
    rd = collect_android()
    bx = collect_box()
    au = collect_audit()
    saud = collect_security_audit()
    saud = reconcile_termux_boot_live(saud, rd)
    alerts, unavailable, pend, sections, overall = build(nm, ts, ag, rd, bx, au, saud)
    page = render(nm, ts, ag, rd, bx, au, alerts, unavailable, pend, sections, overall, saud)
    stamp = NOW.strftime("%Y%m%d-%H%M%S")
    html_path = os.path.join(OUT, "dashboard-latest.html")
    open(html_path, "w", encoding="utf-8").write(page)
    png_ts = os.path.join(OUT, f"dashboard-{stamp}.png")
    png_latest = os.path.join(OUT, "dashboard-latest.png")
    render_err = ""
    try:
        screenshot(html_path, png_ts)
        shutil.copyfile(png_ts, png_latest)
    except Exception as e:
        render_err = str(e)
    for old in sorted(glob.glob(os.path.join(OUT, "dashboard-2*.png")))[:-KEEP_PNGS]:
        os.remove(old)
    summary = {
        "generated_at": NOW.isoformat(timespec="seconds"),
        "generated_at_brt": NOW.strftime("%d/%m/%Y %H:%M:%S") + " BRT",
        "overall": overall,
        "alerts": alerts,
        "sections": {k: {"status": v} for k, v in sections.items()},
        "unavailable": unavailable,
        "pendencias_relatorio": [{k: p[k] for k in ("n", "sev", "title", "state", "live", "label")} for p in pend],
        "files": {"png": png_latest if not render_err else None, "png_timestamped": png_ts if not render_err else None, "html": html_path},
        "render_error": render_err or None,
    }
    # números-chave por seção (para conferência)
    if ts.get("ok"):
        summary["sections"]["VPN"].update(backend=ts["backend"], peers=[{k: p[k] for k in ("key", "ip", "online", "conn")} for p in ts["peers"]],
                                                dns_resolvers=ts.get("dns", {}).get("resolvers"))
    if ag.get("ok"):
        st = ag["stats"]
        summary["sections"]["AdGuard"].update(running=ag["status"].get("running"), protection=ag["status"].get("protection_enabled"),
            window_h=ag.get("stats_interval_h"), queries=st.get("num_dns_queries"), blocked=st.get("num_blocked_filtering"),
            top_blocked=st.get("top_blocked_domains", [])[:6],
            android_last_hour=ag["android"]["hour_n"], android_blocked_last_hour=ag["android"]["hour_blocked"], android_last_seen=ag["android"]["last_seen"])
    if rd.get("ok"):
        summary["sections"]["dispositivo Android"].update(ssh="ok", patch=rd["patch"], patch_age_days=rd.get("patch_age"), upgradable=len(rd["upgradable"]),
            sshd={k: v for k, v in rd["sshd"].items()}, authorized_keys=[{k: x[k] for k in ("options", "type", "fingerprint")} for x in rd["ak"]])
    if bx.get("disk", {}).get("pct") is not None:
        summary["sections"]["Meu computador"].update(disk_pct=round(bx["disk"]["pct"], 1), mem_avail_pct=round(bx["mem"].get("pct_avail", 0), 1),
                                                     load=[bx["load"].get(k) for k in ("l1", "l5", "l15")])
    if saud.get("ok"):
        for label, key in (("Segurança VPN", "vpn"), ("Segurança terminal Android", "termux")):
            g = saud.get(key) or {}
            summary["sections"].setdefault(label, {})["items"] = [
                {k: it.get(k) for k in ("id", "level", "title")} for it in (g.get("items") or [])
            ]
            summary["sections"][label]["report"] = saud.get("report_path")
    tmp = os.path.join(OUT, ".dashboard-latest.json.tmp")
    json.dump(summary, open(tmp, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    os.replace(tmp, os.path.join(OUT, "dashboard-latest.json"))
    print(f"[{overall}] {len(alerts)} alerta(s); PNG: {png_latest if not render_err else 'FALHOU: ' + render_err}")
    for a in alerts:
        print(f"  - {a['level']:5} {a['section']}: {a['text']}")
    for u in unavailable:
        print(f"  ! indisponível: {u['section']} / {u['check']}: {u['reason']}")
    return 0 if not render_err else 2


if __name__ == "__main__":
    sys.exit(main())
