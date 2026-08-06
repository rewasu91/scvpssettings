#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Run this script as root."
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/root/tcp-fix-backup-${STAMP}"
TCP_JSON="/etc/funny/json/tcp.json"
HAPROXY_CFG="/etc/haproxy/haproxy.cfg"
XRAY_SERVICE="/etc/systemd/system/xray-tcp.service"
V2RAY_SERVICE="/etc/systemd/system/v2ray.service"
XRAY_BIN="/usr/local/xray-old/xray"
CERT_FILE="/etc/haproxy/funny.pem"

mkdir -p "$BACKUP_DIR"

backup_file() {
  local file="$1"
  [[ -e "$file" ]] && cp -a "$file" "$BACKUP_DIR/$(echo "$file" | sed 's#^/##; s#/#__#g')"
}

for file in "$TCP_JSON" "$HAPROXY_CFG" "$XRAY_SERVICE" "$V2RAY_SERVICE"; do
  backup_file "$file"
done

echo "[INFO] Backup saved to: $BACKUP_DIR"

for cmd in python3 haproxy systemctl ss; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "[ERROR] Required command not found: $cmd"
    exit 1
  }
done

[[ -x "$XRAY_BIN" ]] || {
  echo "[ERROR] Xray binary not found or not executable: $XRAY_BIN"
  exit 1
}

[[ -f "$TCP_JSON" ]] || {
  echo "[ERROR] TCP configuration not found: $TCP_JSON"
  exit 1
}

[[ -s "$CERT_FILE" ]] || {
  echo "[ERROR] HAProxy certificate not found: $CERT_FILE"
  echo "Restore/generate the certificate before running this patch."
  exit 1
}

# Preserve all existing clients while normalizing the three TCP inbounds.
python3 - "$TCP_JSON" <<'PY'
import json
import os
import sys
import tempfile

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

inbounds = data.setdefault("inbounds", [])

wanted = {
    "vmess": (1234, "/tcpvmess"),
    "vless": (1235, "/tcpvless"),
    "trojan": (1236, None),
}

found = {}
for inbound in inbounds:
    proto = inbound.get("protocol")
    port = inbound.get("port")
    if proto in wanted and (port == wanted[proto][0] or proto not in found):
        found[proto] = inbound

for proto, (port, path_header) in wanted.items():
    inbound = found.get(proto)
    if inbound is None:
        settings = {"clients": []}
        if proto == "vless":
            settings["decryption"] = "none"
        inbound = {
            "listen": "127.0.0.1",
            "port": port,
            "protocol": proto,
            "settings": settings,
            "streamSettings": {},
            "sniffing": {"enabled": True, "destOverride": ["http", "tls"]},
        }
        inbounds.append(inbound)

    inbound["listen"] = "127.0.0.1"
    inbound["port"] = port
    settings = inbound.setdefault("settings", {})
    settings.setdefault("clients", [])
    if proto == "vless":
        settings["decryption"] = "none"

    stream = inbound.setdefault("streamSettings", {})
    stream["network"] = "tcp"
    stream["security"] = "none"
    tcp = stream.setdefault("tcpSettings", {})
    tcp["acceptProxyProtocol"] = True

    if path_header:
        tcp["header"] = {
            "type": "http",
            "request": {"path": [path_header]},
        }
    else:
        tcp.pop("header", None)
        # HAProxy directly selects each protocol backend, so old Xray fallbacks
        # are unnecessary and can cause confusing double routing.
        settings.pop("fallbacks", None)

fd, tmp = tempfile.mkstemp(prefix="tcp.json.", dir=os.path.dirname(path))
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.chmod(tmp, 0o644)
    os.replace(tmp, path)
finally:
    if os.path.exists(tmp):
        os.unlink(tmp)
PY

cat > "$XRAY_SERVICE" <<EOF
[Unit]
Description=Xray TCP Service
Documentation=https://github.com/XTLS/Xray-core
After=network-online.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=$XRAY_BIN run -config $TCP_JSON
Restart=on-failure
RestartSec=3s
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

# Disable the obsolete service permanently so it cannot reclaim port 2083.
cat > "$V2RAY_SERVICE" <<'EOF'
[Unit]
Description=Legacy V2Ray Service (disabled; HAProxy owns public TCP port 2083)
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/haproxy
cat > "$HAPROXY_CFG" <<'EOF'
global
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 1d
    log /dev/log local0
    log /dev/log local1 notice
    tune.h2.initial-window-size 2147483647
    tune.ssl.default-dh-param 2048
    pidfile /run/haproxy.pid
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

defaults
    log global
    mode tcp
    option dontlognull
    timeout connect 5s
    timeout client 1m
    timeout server 1m

# Public TLS ports. Do not bind 80, 2053, or 2082 because they are commonly
# owned by Nginx/other services in this autoscript.
frontend multipurpose_tls
    mode tcp
    bind *:8443 tfo
    bind *:8999 tfo
    bind *:9443 tfo
    bind *:9755 tfo
    bind *:2083 tfo
    bind *:2087 tfo
    bind *:2096 tfo
    bind *:400-777 tfo
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }
    tcp-request content accept if HTTP
    acl is_ssh payload(0,3) -m bin 535348
    use_backend recir_http if HTTP
    use_backend STUNNEL5 if is_ssh
    default_backend recir_https

frontend plain_http
    mode tcp
    bind *:2052 tfo
    bind *:2086 tfo
    bind *:2095 tfo
    bind *:8000 tfo
    bind *:81-108 tfo
    bind *:8080-8180 tfo
    tcp-request inspect-delay 5s
    acl is_tcp_vless req.payload(0,4096) -m sub /tcpvless
    acl is_tcp_vmess req.payload(0,4096) -m sub /tcpvmess
    acl is_tcp_trojan req.payload(0,4096) -m sub /tcptrojan
    tcp-request content accept if is_tcp_vless or is_tcp_vmess or is_tcp_trojan or HTTP
    use_backend XRAY_TCP_VLESS if is_tcp_vless
    use_backend XRAY_TCP_VMESS if is_tcp_vmess
    use_backend XRAY_TCP_TROJAN if is_tcp_trojan
    use_backend recir_http if HTTP
    default_backend OPENVPN

frontend multiports
    mode http
    bind abns@haproxy-http accept-proxy
    default_backend MULTIPLEWS

frontend multiports_ssl
    mode tcp
    bind abns@haproxy-https accept-proxy ssl crt /etc/haproxy/funny.pem alpn h2,http/1.1
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }
    tcp-request content accept if HTTP
    acl is_grpc ssl_fc_alpn -i h2
    acl is_ws hdr(Upgrade) -i websocket
    acl is_ssh payload(0,3) -m bin 535348
    acl is_tcp_vless req.payload(0,4096) -m sub /tcpvless
    acl is_tcp_vmess req.payload(0,4096) -m sub /tcpvmess
    acl is_tcp_trojan req.payload(0,4096) -m sub /tcptrojan
    use_backend XRAY_TCP_VLESS if is_tcp_vless
    use_backend XRAY_TCP_VMESS if is_tcp_vmess
    use_backend XRAY_TCP_TROJAN if is_tcp_trojan
    use_backend H2H3 if is_grpc
    use_backend MULTIPLEWS if is_ws
    use_backend STUNNEL5 if is_ssh
    default_backend XRAY_TCP_TROJAN

backend recir_http
    mode tcp
    server local-http abns@haproxy-http send-proxy-v2 check

backend recir_https
    mode tcp
    server local-https abns@haproxy-https send-proxy-v2 check

backend MULTIPLEWS
    mode http
    server websocket 127.0.0.1:1010 send-proxy check

backend H2H3
    mode tcp
    server grpc 127.0.0.1:1013 send-proxy check

backend OPENVPN
    mode tcp
    balance roundrobin
    server ovpn 127.0.0.1:1194 check
    server wsovpn 127.0.0.1:2081 send-proxy check

backend STUNNEL5
    mode tcp
    balance roundrobin
    server ssh 127.0.0.1:22 check
    server dropbear 127.0.0.1:111 check

backend XRAY_TCP_VLESS
    mode tcp
    server xray-vless 127.0.0.1:1235 send-proxy-v2 check

backend XRAY_TCP_VMESS
    mode tcp
    server xray-vmess 127.0.0.1:1234 send-proxy-v2 check

backend XRAY_TCP_TROJAN
    mode tcp
    server xray-trojan 127.0.0.1:1236 send-proxy-v2 check
EOF

# Validate before touching running services.
python3 -m json.tool "$TCP_JSON" >/dev/null
"$XRAY_BIN" run -test -config "$TCP_JSON"
haproxy -c -f "$HAPROXY_CFG"

systemctl stop v2ray.service 2>/dev/null || true
systemctl disable v2ray.service 2>/dev/null || true
systemctl mask v2ray.service 2>/dev/null || true
systemctl daemon-reload
systemctl reset-failed haproxy xray-tcp 2>/dev/null || true
systemctl enable xray-tcp haproxy >/dev/null
systemctl restart xray-tcp
sleep 1
systemctl restart haproxy
sleep 1

echo
echo "========== SERVICE STATUS =========="
systemctl --no-pager --full status xray-tcp haproxy | sed -n '1,80p' || true

echo
echo "========== REQUIRED LISTENERS =========="
ss -lntp | grep -E ':(2083|1234|1235|1236)\b' || true

echo
echo "[DONE] TCP patch completed."
echo "Expected ownership:"
echo "  0.0.0.0:2083   -> haproxy"
echo "  127.0.0.1:1234 -> xray-tcp (VMess TCP)"
echo "  127.0.0.1:1235 -> xray-tcp (VLESS TCP)"
echo "  127.0.0.1:1236 -> xray-tcp (Trojan TCP)"
echo "Backup: $BACKUP_DIR"
