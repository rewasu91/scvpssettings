#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo '[ERROR] Run this script as root.' >&2
  exit 1
fi

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="/root/tcp-v6-backup-${STAMP}"
mkdir -p "$BACKUP"
backup_file(){ local f="$1"; [[ -f "$f" ]] || return 0; mkdir -p "$BACKUP$(dirname "$f")"; cp -a "$f" "$BACKUP$f"; }
for f in /etc/haproxy/haproxy.cfg /etc/funny/nginx/main.conf /etc/funny/json/tcp.json; do backup_file "$f"; done
if [[ -d /usr/local/rere ]]; then mkdir -p "$BACKUP/usr/local"; cp -a /usr/local/rere "$BACKUP/usr/local/rere"; fi

echo "[INFO] Backup: $BACKUP"

python3 <<'PY'
from pathlib import Path
import re, json

VHOST='vless.kaizen.local'
MHOST='vmess.kaizen.local'

# ---------- Xray TCP ----------
xp=Path('/etc/funny/json/tcp.json')
if not xp.exists(): raise SystemExit('[ERROR] tcp.json not found')
data=json.loads(xp.read_text())
seen=set()
for i in data.get('inbounds',[]):
    proto=i.get('protocol')
    if proto not in ('vless','vmess','trojan'): continue
    seen.add(proto)
    i['listen']='127.0.0.1'
    i['port']={'vmess':1234,'vless':1235,'trojan':1236}[proto]
    ss=i.setdefault('streamSettings',{})
    ss['network']='tcp'; ss['security']='none'
    ts=ss.setdefault('tcpSettings',{})
    ts['acceptProxyProtocol']=True
    if proto in ('vless','vmess'):
        host=VHOST if proto=='vless' else MHOST
        # Do not depend on a custom TCP path. Several clients discard/ignore it.
        # Host is the reliable legacy TCP HTTP camouflage discriminator.
        ts['header']={
            'type':'http',
            'request':{
                'path':['/'],
                'headers':{'Host':[host]}
            }
        }
    else:
        ts.pop('header',None)
        # Keep existing fallbacks if present, but they are no longer required for VMess/VLESS routing.
if not {'vless','vmess'}.issubset(seen):
    raise SystemExit('[ERROR] VMess/VLESS inbound missing from tcp.json')
xp.write_text(json.dumps(data,indent=2)+'\n')

# ---------- HAProxy ----------
hp=Path('/etc/haproxy/haproxy.cfg')
if not hp.exists(): raise SystemExit('[ERROR] haproxy.cfg not found')
s=hp.read_text()

# Ensure all requested plain TCP ports are bound by HAProxy.
m=re.search(r'(frontend\s+plain_http\b.*?)(?=\nfrontend\s+|\Z)',s,re.S)
if not m: raise SystemExit('[ERROR] frontend plain_http not found')
b=m.group(1)
for spec in ('*:80','*:81-108','*:2082','*:8000','*:8080-8180','*:2084-2199'):
    if not re.search(r'^\s*bind\s+'+re.escape(spec)+r'(?:\s|$)',b,re.M):
        b=b.replace('frontend plain_http\n',f'frontend plain_http\n    bind {spec} tfo\n',1)

# Replace only the managed TCP camouflage ACL/routing lines in the frontend.
b=re.sub(r'^\s*acl\s+is_xray_(?:vless|vmess)_tcp\b.*\n','',b,flags=re.M)
b=re.sub(r'^\s*use_backend\s+XRAY_(?:VLESS|VMESS)_TCP\s+if\s+is_xray_(?:vless|vmess)_tcp\s*\n','',b,flags=re.M)
anchor='    tcp-request content accept if HTTP\n'
managed=(
'\n    # Xray TCP HTTP camouflage: route by Host. TCP path is intentionally not required.\n'
'    acl is_xray_vless_tcp req.payload(0,2048) -m sub "Host: vless.kaizen.local"\n'
'    acl is_xray_vless_tcp req.payload(0,2048) -m sub "host: vless.kaizen.local"\n'
'    acl is_xray_vless_tcp req.payload(0,2048) -m sub /tcpvless\n'
'    acl is_xray_vmess_tcp req.payload(0,2048) -m sub "Host: vmess.kaizen.local"\n'
'    acl is_xray_vmess_tcp req.payload(0,2048) -m sub "host: vmess.kaizen.local"\n'
'    acl is_xray_vmess_tcp req.payload(0,2048) -m sub /tcpvmess\n'
'    use_backend XRAY_VLESS_TCP if is_xray_vless_tcp\n'
'    use_backend XRAY_VMESS_TCP if is_xray_vmess_tcp\n'
)
if anchor in b:
    b=b.replace(anchor,anchor+managed,1)
else:
    b=b.replace('frontend plain_http\n','frontend plain_http\n    tcp-request inspect-delay 5s\n'+managed,1)
s=s[:m.start(1)]+b+s[m.end(1):]

# TLS frontend: ensure 2083 and use the same Host discriminator after TLS termination.
m=re.search(r'(frontend\s+multiports_ssl\b.*?)(?=\nfrontend\s+|\n# === BACKENDS|\Z)',s,re.S)
if not m: raise SystemExit('[ERROR] frontend multiports_ssl not found')
b=m.group(1)
if not re.search(r'^\s*bind\s+\*:2083\s+ssl\b',b,re.M):
    b=b.replace('frontend multiports_ssl\n','frontend multiports_ssl\n    bind *:2083 ssl crt /etc/haproxy/funny.pem alpn h2,http/1.1 tfo\n',1)
b=re.sub(r'^\s*acl\s+is_xray_(?:vless|vmess)_tcp\b.*\n','',b,flags=re.M)
b=re.sub(r'^\s*use_backend\s+XRAY_(?:VLESS|VMESS)_TCP\s+if\s+is_xray_(?:vless|vmess)_tcp\s*\n','',b,flags=re.M)
anchor='    tcp-request inspect-delay 5s\n'
managed=(
'\n    # Xray TCP HTTP camouflage after TLS termination; Host is reliable across clients.\n'
'    acl is_xray_vless_tcp req.payload(0,2048) -m sub "Host: vless.kaizen.local"\n'
'    acl is_xray_vless_tcp req.payload(0,2048) -m sub "host: vless.kaizen.local"\n'
'    acl is_xray_vless_tcp req.payload(0,2048) -m sub /tcpvless\n'
'    acl is_xray_vmess_tcp req.payload(0,2048) -m sub "Host: vmess.kaizen.local"\n'
'    acl is_xray_vmess_tcp req.payload(0,2048) -m sub "host: vmess.kaizen.local"\n'
'    acl is_xray_vmess_tcp req.payload(0,2048) -m sub /tcpvmess\n'
'    use_backend XRAY_VLESS_TCP if is_xray_vless_tcp\n'
'    use_backend XRAY_VMESS_TCP if is_xray_vmess_tcp\n'
)
if anchor in b: b=b.replace(anchor,anchor+managed,1)
else: b=b.replace('frontend multiports_ssl\n','frontend multiports_ssl\n    tcp-request inspect-delay 5s\n'+managed,1)
s=s[:m.start(1)]+b+s[m.end(1):]

# Ensure backends exist and do not health-check Xray PROXY-protocol inbounds.
def ensure_backend(name, body):
    global s
    if not re.search(r'^backend\s+'+re.escape(name)+r'\b',s,re.M): s=s.rstrip()+'\n\n'+body.strip()+'\n'
ensure_backend('XRAY_VLESS_TCP','''backend XRAY_VLESS_TCP\n    mode tcp\n    server xray-vless-tcp 127.0.0.1:1235 send-proxy-v2''')
ensure_backend('XRAY_VMESS_TCP','''backend XRAY_VMESS_TCP\n    mode tcp\n    server xray-vmess-tcp 127.0.0.1:1234 send-proxy-v2''')
ensure_backend('XRAY_TROJAN_TCP','''backend XRAY_TROJAN_TCP\n    mode tcp\n    server xray-trojan-tcp 127.0.0.1:1236 send-proxy-v2''')
ensure_backend('OPENVPN','''backend OPENVPN\n    mode tcp\n    balance roundrobin\n    server ovpn 127.0.0.1:1194 check\n    server wsovpn 127.0.0.1:2081 send-proxy check''')
s=re.sub(r'(^\s*server\s+xray-(?:vless|vmess|trojan)-tcp\s+[^\n]*?\s+send-proxy-v2)\s+check(?:\s+[^\n]*)?$',r'\1',s,flags=re.M)
hp.write_text(s)

# ---------- Nginx ----------
ng=Path('/etc/funny/nginx/main.conf')
if ng.exists():
    n=ng.read_text()
    n=re.sub(r'^\s*listen\s+(?:\[::\]:)?2082(?:\s+[^;]*)?;\s*\n?','',n,flags=re.M)
    ng.write_text(n)

# ---------- Generators ----------
root=Path('/usr/local/rere')
ports='80-108, 2082, 8000, 8080-8180, 2084-2199'
if root.exists():
    for p in root.rglob('*'):
        if not p.is_file(): continue
        try: t=p.read_text()
        except Exception: continue
        if 'tcp' not in p.name.lower() and '/tcpvless' not in t and '/tcpvmess' not in t: continue
        old=t
        # VLESS URI: URL-encode slash and use dedicated HTTP camouflage Host.
        t=re.sub(r'path=/tcpvless&security=(tls|none)&encryption=none&host=\$\{domain\}&type=tcp&headerType=http',
                 r'path=%2F&security=\1&encryption=none&host=vless.kaizen.local&type=tcp&headerType=http',t)
        # Also catch variants whose order differs slightly.
        t=t.replace('path=/tcpvless&security=tls&encryption=none&host=${domain}&type=tcp&headerType=http','path=%2F&security=tls&encryption=none&host=vless.kaizen.local&type=tcp&headerType=http')
        t=t.replace('path=/tcpvless&security=none&encryption=none&host=${domain}&type=tcp&headerType=http','path=%2F&security=none&encryption=none&host=vless.kaizen.local&type=tcp&headerType=http')
        # VMess legacy JSON: for TCP+HTTP, type+host are the portable fields. Path is '/'.
        if '/tcpvmess' in t or '"net": "tcp"' in t or '\\"net\\":\\"tcp\\"' in t:
            t=t.replace('"path": "/tcpvmess"','"path": "/"')
            t=t.replace('"host": "${domain}"','"host": "vmess.kaizen.local"')
            t=t.replace('\\"path\\":\\"/tcpvmess\\"','\\"path\\":\\"/\\"')
            t=t.replace('\\"host\\":\\"${domain}\\"','\\"host\\":\\"vmess.kaizen.local\\"')
            # compact shell JSON forms
            t=t.replace('"path":"/tcpvmess","type":"http","host":"${domain}"','"path":"/","type":"http","host":"vmess.kaizen.local"')
        # Human-readable fields
        t=t.replace('Path         : /tcpvless','Path         : /')
        t=t.replace('Path         : /tcpvmess','Path         : /')
        t=t.replace('<code>/tcpvless</code>','<code>/</code>')
        t=t.replace('<code>/tcpvmess</code>','<code>/</code>')
        if t != old: p.write_text(t)
PY

chmod +x /usr/local/rere/* 2>/dev/null || true
chmod +x /usr/local/rere/api/vps/* 2>/dev/null || true

XRAY_BIN=''
for x in /usr/local/xray-old/xray /usr/local/xray-new/xray /usr/local/xray-mod/xray /usr/local/bin/xray; do [[ -x "$x" ]] && { XRAY_BIN="$x"; break; }; done
[[ -n "$XRAY_BIN" ]] || { echo '[ERROR] No Xray binary found.'; exit 1; }

echo '[INFO] Validating Xray TCP config...'
"$XRAY_BIN" run -test -config /etc/funny/json/tcp.json

echo '[INFO] Validating HAProxy config...'
haproxy -c -f /etc/haproxy/haproxy.cfg

echo '[INFO] Validating Nginx config...'
nginx -t

systemctl daemon-reload
systemctl restart xray-tcp
systemctl restart nginx
systemctl restart haproxy
sleep 2

echo '[INFO] Listener check:'
ss -lntp | grep -E ':(80|81|108|2082|2083|8000|8080|8180|2084|2199|1234|1235|1236)\b' || true

# ---------------- end-to-end temporary self test ----------------
echo '[INFO] Running end-to-end TCP self-test through HAProxy...'
SELF_DIR=$(mktemp -d /tmp/kaizen-tcp-test.XXXXXX)
TEST_UUID='6f187b80-bf6c-4d9f-9d88-973a486e9a61'
ORIG_TCP="$SELF_DIR/tcp.orig.json"
cp -a /etc/funny/json/tcp.json "$ORIG_TCP"
cleanup_test(){
  set +e
  [[ -n "${P_HTTP:-}" ]] && kill "$P_HTTP" 2>/dev/null
  [[ -n "${P_XC:-}" ]] && kill "$P_XC" 2>/dev/null
  if [[ -f "$ORIG_TCP" ]]; then cp -a "$ORIG_TCP" /etc/funny/json/tcp.json; systemctl restart xray-tcp >/dev/null 2>&1; fi
  rm -rf "$SELF_DIR"
}
trap cleanup_test EXIT

jq --arg id "$TEST_UUID" '
 (.inbounds[]|select(.protocol=="vless").settings.clients) += [{id:$id,email:"kaizen-selftest-vless"}] |
 (.inbounds[]|select(.protocol=="vmess").settings.clients) += [{id:$id,email:"kaizen-selftest-vmess"}]' \
 /etc/funny/json/tcp.json > "$SELF_DIR/tcp.test.json"
mv "$SELF_DIR/tcp.test.json" /etc/funny/json/tcp.json
systemctl restart xray-tcp
sleep 1
python3 -m http.server 19090 --bind 127.0.0.1 >"$SELF_DIR/http.log" 2>&1 & P_HTTP=$!

DOMAIN=$(cat /etc/xray/domain 2>/dev/null || true)
run_case(){
  local proto="$1" tls="$2" public_port="$3" host="$4" socks_port="$5" name="$6"
  local security tlsblock=''
  if [[ "$tls" == tls ]]; then
    security='tls'
    tlsblock=",\"tlsSettings\":{\"serverName\":\"${DOMAIN}\",\"allowInsecure\":false}"
  else security='none'; fi
  cat >"$SELF_DIR/client.json" <<EOF
{"log":{"loglevel":"warning"},"inbounds":[{"listen":"127.0.0.1","port":${socks_port},"protocol":"socks","settings":{"auth":"noauth","udp":false}}],"outbounds":[{"protocol":"${proto}","settings":{"vnext":[{"address":"127.0.0.1","port":${public_port},"users":[{"id":"${TEST_UUID}"$( [[ "$proto" == vless ]] && printf ',"encryption":"none"' )}]}]},"streamSettings":{"network":"tcp","security":"${security}","tcpSettings":{"header":{"type":"http","request":{"path":["/"],"headers":{"Host":["${host}"]}}}}}${tlsblock}}}]}
EOF
  "$XRAY_BIN" run -test -config "$SELF_DIR/client.json" >/dev/null 2>&1 || { echo "[FAIL] $name: client config invalid"; return 1; }
  "$XRAY_BIN" run -config "$SELF_DIR/client.json" >"$SELF_DIR/client.log" 2>&1 & P_XC=$!
  sleep 0.6
  if timeout 8 curl -fsS --socks5-hostname "127.0.0.1:${socks_port}" http://127.0.0.1:19090/ >/dev/null 2>&1; then
    echo "[PASS] $name"
    kill "$P_XC" 2>/dev/null || true; wait "$P_XC" 2>/dev/null || true; P_XC=''; return 0
  else
    echo "[FAIL] $name"
    tail -n 8 "$SELF_DIR/client.log" 2>/dev/null | sed 's/^/       /'
    kill "$P_XC" 2>/dev/null || true; wait "$P_XC" 2>/dev/null || true; P_XC=''; return 1
  fi
}

FAIL=0
run_case vless none 80 vless.kaizen.local 19101 'VLESS TCP None TLS :80' || FAIL=1
run_case vmess none 80 vmess.kaizen.local 19102 'VMess TCP None TLS :80' || FAIL=1
if [[ -n "$DOMAIN" ]]; then
  run_case vless tls 2083 vless.kaizen.local 19103 'VLESS TCP TLS :2083' || FAIL=1
  run_case vmess tls 2083 vmess.kaizen.local 19104 'VMess TCP TLS :2083' || FAIL=1
else
  echo '[WARN] TLS self-test skipped because /etc/xray/domain is empty.'
fi

cleanup_test
trap - EXIT

echo
if [[ "$FAIL" -eq 0 ]]; then
  echo '[OK] All TCP self-tests passed.'
else
  echo '[WARN] One or more self-tests failed. The PASS/FAIL lines above identify the exact layer.'
fi
printf '%s\n' \
  'TLS TCP port   : 2083' \
  'None-TLS ports : 80-108, 2082, 8000, 8080-8180, 2084-2199' \
  'VLESS HTTP Host: vless.kaizen.local' \
  'VMess HTTP Host: vmess.kaizen.local' \
  'TCP HTTP Path  : /' \
  "Backup         : $BACKUP"
