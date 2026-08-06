#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo '[ERROR] Run this script as root.' >&2
  exit 1
fi

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="/root/vpn-a2z-backup-${STAMP}"
mkdir -p "$BACKUP"

backup_path() {
  local p="$1"
  [[ -e "$p" ]] || return 0
  mkdir -p "$BACKUP$(dirname "$p")"
  cp -a "$p" "$BACKUP$p"
}

for p in \
  /etc/haproxy/haproxy.cfg \
  /etc/systemd/system/v2ray.service \
  /etc/systemd/system/xray-tcp.service \
  /etc/funny/json/tcp.json \
  /etc/funny/config/tcp/tcp.conf \
  /usr/local/rere; do
  backup_path "$p"
done

echo "[INFO] Backup created: $BACKUP"

command -v python3 >/dev/null || { echo '[ERROR] python3 is required.'; exit 1; }
command -v jq >/dev/null || { echo '[ERROR] jq is required.'; exit 1; }
command -v haproxy >/dev/null || { echo '[ERROR] haproxy is not installed.'; exit 1; }

mkdir -p /var/log/xray /etc/funny/config/tcp
chown root:root /var/log/xray
chmod 755 /var/log/xray

# Preserve all existing clients. Only normalize the TCP transport structure.
python3 <<'PY'
import json
from pathlib import Path
p=Path('/etc/funny/json/tcp.json')
data=json.loads(p.read_text())
ports={1234:'vmess',1235:'vless',1236:'trojan'}
found={}
for inbound in data.get('inbounds',[]):
    if inbound.get('protocol') in ports.values():
        found[inbound['protocol']]=inbound
for proto in ('vmess','vless','trojan'):
    if proto not in found:
        raise SystemExit(f'[ERROR] Missing {proto} inbound in {p}')

for proto, port in [('vmess',1234),('vless',1235),('trojan',1236)]:
    i=found[proto]
    i['listen']='127.0.0.1'; i['port']=port
    ss=i.setdefault('streamSettings',{})
    ss['network']='tcp'; ss['security']='none'
    ts=ss.setdefault('tcpSettings',{})
    ts['acceptProxyProtocol']=True
    if proto in ('vmess','vless'):
        path='/tcpvmess' if proto=='vmess' else '/tcpvless'
        ts['header']={'type':'http','request':{'path':[path]}}
    else:
        ts.pop('header',None)
        i.get('settings',{}).pop('fallbacks',None)
p.write_text(json.dumps(data,indent=2)+"\n")
PY

# Remove old managed HAProxy block, then add a conflict-free dedicated listener.
python3 <<'PY'
from pathlib import Path
p=Path('/etc/haproxy/haproxy.cfg')
s=p.read_text()
marker='# === XRAY TCP TLS MULTIPLEXER (managed) ==='
if marker in s:
    s=s.split(marker)[0].rstrip()+"\n"
block=r'''

# === XRAY TCP TLS MULTIPLEXER (managed) ===
frontend xray_tcp_tls
    mode tcp
    bind *:2083 ssl crt /etc/haproxy/funny.pem alpn http/1.1
    tcp-request inspect-delay 5s
    tcp-request content accept if HTTP
    acl is_vless_tcp req.payload(0,4096) -m sub /tcpvless
    acl is_vmess_tcp req.payload(0,4096) -m sub /tcpvmess
    use_backend XRAY_VLESS_TCP if is_vless_tcp
    use_backend XRAY_VMESS_TCP if is_vmess_tcp
    default_backend XRAY_TROJAN_TCP

backend XRAY_VLESS_TCP
    mode tcp
    server vless_tcp 127.0.0.1:1235 send-proxy-v2 check

backend XRAY_VMESS_TCP
    mode tcp
    server vmess_tcp 127.0.0.1:1234 send-proxy-v2 check

backend XRAY_TROJAN_TCP
    mode tcp
    server trojan_tcp 127.0.0.1:1236 send-proxy-v2 check
'''
p.write_text(s.rstrip()+block+'\n')
PY

cat >/etc/funny/config/tcp/tcp.conf <<'CONF'
# Raw Xray TCP is handled by HAProxy, not Nginx.
# Public TLS :2083 -> VMess :1234, VLESS :1235, Trojan :1236.
CONF

cat >/etc/systemd/system/xray-tcp.service <<'UNIT'
[Unit]
Description=Xray TCP Internal Inbounds
Documentation=https://github.com/XTLS/Xray-core
After=network-online.target nss-lookup.target
Wants=network-online.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/xray-old/xray run -config /etc/funny/json/tcp.json
Restart=on-failure
RestartSec=2s
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
UNIT

# Patch every account/trial/bulk/API generator without deleting users.
python3 <<'PY'
from pathlib import Path
import re
roots=[Path('/usr/local/rere'),Path('/usr/local/bin')]
for root in roots:
  if not root.exists(): continue
  for p in root.rglob('*'):
    if not p.is_file() or p.stat().st_size>2_000_000: continue
    try: s=p.read_text()
    except UnicodeDecodeError: continue
    old=s
    if '/tcpvmess' in s:
      s=s.replace('"path": "/tcpvmess",\n"type": "none"','"path": "/tcpvmess",\n"type": "http"')
      s=s.replace('"path":"/tcpvmess","type":"none"','"path":"/tcpvmess","type":"http"')
      s=s.replace('\\"path\\":\\"/tcpvmess\\",\\"type\\":\\"none\\"','\\"path\\":\\"/tcpvmess\\",\\"type\\":\\"http\\"')
    if '/tcpvless' in s:
      s=re.sub(r'(vless://[^\n"\']*?/tcpvless[^\n"\']*?type=tcp)(?![^\n"\']*headerType=)',r'\1&headerType=http',s)
    lines=[]
    for line in s.splitlines(True):
      if ('tcpvless' in line or 'tcpvmess' in line) and (':80?' in line or '"port": "80"' in line or '"port":"80"' in line):
        if '=' in line and not line.lstrip().startswith(('#','echo','<')):
          line=line.split('=',1)[0]+'="" # Non-TLS raw TCP is unsupported\n'
        else:
          continue
      lines.append(line)
    s=''.join(lines)
    s=s.replace('Port nonetls : 80-108, 2082, 8000, 8080-8180, 2084-2199','Port non-TLS  : Not supported for raw TCP profiles')
    s=s.replace('Port nonetls :</b> <code>80, 2082</code>','Port non-TLS:</b> <code>Not supported</code>')
    if s!=old: p.write_text(s)
PY

# Disable the obsolete service that previously occupied public port 2083.
systemctl disable --now v2ray.service 2>/dev/null || true
systemctl mask v2ray.service 2>/dev/null || true
systemctl daemon-reload

# Validate before restarting anything.
python3 -m json.tool /etc/funny/json/tcp.json >/dev/null
if [[ -x /usr/local/xray-old/xray ]]; then
  /usr/local/xray-old/xray run -test -config /etc/funny/json/tcp.json
else
  echo '[ERROR] /usr/local/xray-old/xray is missing or not executable.' >&2
  exit 1
fi

if [[ ! -s /etc/haproxy/funny.pem ]]; then
  echo '[ERROR] /etc/haproxy/funny.pem is missing. HAProxy TLS cannot start.' >&2
  exit 1
fi
haproxy -c -f /etc/haproxy/haproxy.cfg

systemctl unmask xray-tcp.service haproxy.service 2>/dev/null || true
systemctl enable xray-tcp.service haproxy.service >/dev/null
systemctl restart xray-tcp.service
systemctl restart haproxy.service

sleep 2
if ! systemctl is-active --quiet xray-tcp.service; then
  journalctl -u xray-tcp.service -n 80 --no-pager
  exit 1
fi
if ! systemctl is-active --quiet haproxy.service; then
  journalctl -u haproxy.service -n 80 --no-pager
  exit 1
fi

echo
ss -lntp | grep -E ':(2083|1234|1235|1236)\b' || true
echo
cat <<'DONE'
[SUCCESS] Existing installation patched.

Client settings:
  VMess TCP: port 2083, TLS on, network tcp, header type http, path /tcpvmess
  VLESS TCP: port 2083, TLS on, network tcp, header type http, path /tcpvless
  Trojan TCP: port 2083, TLS on, network tcp
DONE
