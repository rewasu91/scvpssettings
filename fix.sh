#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo '[ERROR] Run this script as root.' >&2
  exit 1
fi

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="/root/tcp-v4-backup-${STAMP}"
mkdir -p "$BACKUP"

backup_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  mkdir -p "$BACKUP$(dirname "$f")"
  cp -a "$f" "$BACKUP$f"
}

for f in /etc/haproxy/haproxy.cfg /etc/funny/nginx/main.conf /etc/funny/json/tcp.json; do
  backup_file "$f"
done
if [[ -d /usr/local/rere ]]; then
  mkdir -p "$BACKUP/usr/local"
  cp -a /usr/local/rere "$BACKUP/usr/local/rere"
fi

echo "[INFO] Backup: $BACKUP"

python3 <<'PY'
from pathlib import Path
import re, json

# 1) HAProxy: own all requested public non-TLS ports and stop false-negative Xray health checks.
hp=Path('/etc/haproxy/haproxy.cfg')
if not hp.exists():
    raise SystemExit('[ERROR] /etc/haproxy/haproxy.cfg not found')
s=hp.read_text()

# Add 2082 to plain_http if missing. It must be handled by HAProxy, not nginx.
m=re.search(r'(frontend\s+plain_http\b.*?)(?=\nfrontend\s+|\Z)', s, flags=re.S)
if not m:
    raise SystemExit('[ERROR] frontend plain_http not found in HAProxy config')
block=m.group(1)
if not re.search(r'^\s*bind\s+\*:2082\b', block, flags=re.M):
    # put after port 8000 if possible, otherwise after frontend line
    if re.search(r'^\s*bind\s+\*:8000\b.*$', block, flags=re.M):
        block=re.sub(r'(^\s*bind\s+\*:8000\b.*$)', r'\1\n    bind *:2082 tfo', block, count=1, flags=re.M)
    else:
        block=block.replace('frontend plain_http', 'frontend plain_http\n    bind *:2082 tfo', 1)

# Ensure the exact requested non-TLS binds exist.
required=['bind *:80 tfo','bind *:81-108 tfo','bind *:2082 tfo','bind *:8000 tfo','bind *:8080-8180 tfo','bind *:2084-2199 tfo']
for line in required:
    portspec=line.split()[1]
    if portspec not in block:
        block=block.replace('frontend plain_http\n', 'frontend plain_http\n    '+line+'\n', 1)
s=s[:m.start(1)] + block + s[m.end(1):]

# Xray requires PROXY protocol on these local inbounds. Do not use raw TCP health checks that can mark them DOWN.
s=re.sub(r'(^\s*server\s+xray-(?:vless|vmess|trojan)-tcp\s+[^\n]*?\s+send-proxy-v2)\s+check(?:\s+[^\n]*)?$', r'\1', s, flags=re.M)

# Verify 2083 TLS listener exists.
if not re.search(r'^\s*bind\s+\*:2083\s+ssl\b', s, flags=re.M):
    m2=re.search(r'(frontend\s+multiports_ssl\b.*?)(?=\nfrontend\s+|\n# === BACKENDS|\Z)', s, flags=re.S)
    if not m2:
        raise SystemExit('[ERROR] frontend multiports_ssl not found in HAProxy config')
    b=m2.group(1)
    cert='/etc/haproxy/funny.pem'
    line=f'    bind *:2083 ssl crt {cert} alpn h2,http/1.1 tfo\n'
    b=b.replace('frontend multiports_ssl\n','frontend multiports_ssl\n'+line,1)
    s=s[:m2.start(1)] + b + s[m2.end(1):]

hp.write_text(s)

# 2) Nginx must not bind 2082 externally; otherwise HAProxy cannot own requested port 2082.
ng=Path('/etc/funny/nginx/main.conf')
if ng.exists():
    n=ng.read_text()
    n=re.sub(r'^\s*listen\s+(?:\[::\]:)?2082(?:\s+[^;]*)?;\s*\n?', '', n, flags=re.M)
    ng.write_text(n)

# 3) Validate/normalize Xray TCP transport.
xp=Path('/etc/funny/json/tcp.json')
if not xp.exists():
    raise SystemExit('[ERROR] /etc/funny/json/tcp.json not found')
data=json.loads(xp.read_text())
seen=set()
for inbound in data.get('inbounds',[]):
    proto=inbound.get('protocol')
    if proto not in ('vless','vmess','trojan'):
        continue
    seen.add(proto)
    inbound['listen']='127.0.0.1'
    target={'vmess':1234,'vless':1235,'trojan':1236}[proto]
    inbound['port']=target
    ss=inbound.setdefault('streamSettings',{})
    ss['network']='tcp'; ss['security']='none'
    ts=ss.setdefault('tcpSettings',{})
    ts['acceptProxyProtocol']=True
    if proto in ('vless','vmess'):
        path='/tcpvless' if proto=='vless' else '/tcpvmess'
        ts['header']={'type':'http','request':{'path':[path]}}
    else:
        ts.pop('header',None)
if not {'vless','vmess'}.issubset(seen):
    raise SystemExit('[ERROR] VMess/VLESS TCP inbound missing from tcp.json')
xp.write_text(json.dumps(data,indent=2)+'\n')

# 4) Account/trial/bulk/API generators: TLS 2083, None-TLS advertised range, HTTP header camouflage.
root=Path('/usr/local/rere')
ports='80-108, 2082, 8000, 8080-8180, 2084-2199'
if root.exists():
    for p in root.rglob('*'):
        if not p.is_file():
            continue
        try: t=p.read_text()
        except Exception: continue
        low=p.name.lower()
        if 'tcp' not in low and '/tcpvless' not in t and '/tcpvmess' not in t:
            continue
        old=t
        t=t.replace('@${domain}:443?path=/tcpvless','@${domain}:2083?path=/tcpvless')
        t=t.replace('port_tcp_tls="443"','port_tcp_tls="2083"')
        lines=t.splitlines(True)
        for i,line in enumerate(lines):
            if '"port": "443"' in line:
                win=''.join(lines[max(0,i-12):min(len(lines),i+13)])
                if '/tcpvmess' in win:
                    lines[i]=line.replace('"port": "443"','"port": "2083"')
            if '\\"port\\":\\"443\\"' in line and '/tcpvmess' in line:
                lines[i]=line.replace('\\"port\\":\\"443\\"','\\"port\\":\\"2083\\"')
        t=''.join(lines)
        if 'tcp' in low:
            t=t.replace('<b>Port TLS     :</b> <code>443</code>','<b>Port TLS     :</b> <code>2083</code>')
            t=t.replace('Port TLS     : 443','Port TLS     : 2083')
            t=t.replace('<b>Port None TLS:</b> <code>80</code>',f'<b>Port None TLS:</b> <code>{ports}</code>')
            t=t.replace('Port None TLS: 80',f'Port None TLS: {ports}')
        if t != old:
            p.write_text(t)
PY

# Permissions
chmod +x /usr/local/rere/* 2>/dev/null || true
chmod +x /usr/local/rere/api/vps/* 2>/dev/null || true

# Validate before restart.
echo '[INFO] Validating Xray TCP config...'
XRAY_BIN=''
for x in /usr/local/xray-old/xray /usr/local/xray-new/xray /usr/local/xray-mod/xray /usr/local/bin/xray; do
  if [[ -x "$x" ]]; then XRAY_BIN="$x"; break; fi
done
if [[ -n "$XRAY_BIN" ]]; then
  mkdir -p /var/log/xray
  "$XRAY_BIN" run -test -config /etc/funny/json/tcp.json >/tmp/xray-tcp-test.log 2>&1 || {
    cat /tmp/xray-tcp-test.log >&2
    echo '[ERROR] Xray config test failed. Restore from backup above.' >&2
    exit 1
  }
fi

echo '[INFO] Validating HAProxy config...'
haproxy -c -f /etc/haproxy/haproxy.cfg

echo '[INFO] Validating Nginx config...'
nginx -t

systemctl daemon-reload
systemctl restart xray-tcp
systemctl restart nginx
systemctl restart haproxy
sleep 2

echo '[INFO] Service status:'
systemctl --no-pager --full is-active xray-tcp nginx haproxy || true

echo '[INFO] TCP listeners:'
ss -lntp | grep -E ':(80|8[1-9]|9[0-9]|10[0-8]|2082|2083|8000|8080|8180|2084|2199|1234|1235)\b' || true

echo
printf '%s\n' '[OK] TCP routing hotfix applied.' \
  'TLS TCP port     : 2083' \
  'None-TLS ports   : 80-108, 2082, 8000, 8080-8180, 2084-2199' \
  'VLESS HTTP header: /tcpvless' \
  'VMess HTTP header: /tcpvmess' \
  "Backup           : $BACKUP"
