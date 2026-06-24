#!/usr/bin/env bash
# =============================================================================
# subscription.sh - Subscription service
# =============================================================================

write_uri_subscription_raw() {
  local out_file="$1" saved_index="${ARGO_EDGE_INDEX:-0}"

  : > "$out_file"

  # Reset round-robin so subscription output starts from first domain
  ARGO_EDGE_INDEX=0
  if [[ "${ARGO_MULTI_EDGE:-0}" == "1" && "${#ARGO_EDGE_SERVERS[@]}" -gt 0 ]]; then
    ARGO_EDGE_SERVER="${ARGO_EDGE_SERVERS[0]}"
  fi

  if has_vless_install; then
    cycle_argo_edge_server
    build_client_files
    if [[ -f "$SUB_RAW_TXT" ]]; then
      sed '/^[[:space:]]*$/d' "$SUB_RAW_TXT" >> "$out_file"
    fi
  fi

  if has_hy2_install; then
    cycle_argo_edge_server
    build_hysteria2_share_files
    if [[ -f "$HY2_SUB_RAW_TXT" ]]; then
      sed '/^[[:space:]]*$/d' "$HY2_SUB_RAW_TXT" >> "$out_file"
    fi
  fi

  if has_anytls_install; then
    cycle_argo_edge_server
    build_anytls_share_files
    if [[ -f "$ANYTLS_SUB_RAW_TXT" ]]; then
      sed '/^[[:space:]]*$/d' "$ANYTLS_SUB_RAW_TXT" >> "$out_file"
    else
      anytls_uri >> "$out_file"
      printf '\n' >> "$out_file"
    fi
  fi

  if has_ss2022_install; then
    cycle_argo_edge_server
    build_ss2022_share_files
    if [[ -f "$SS2022_SUB_RAW_TXT" ]]; then
      sed '/^[[:space:]]*$/d' "$SS2022_SUB_RAW_TXT" >> "$out_file"
    else
      ss2022_uri >> "$out_file"
      printf '\n' >> "$out_file"
    fi
  fi

  if has_vmess_install; then
    cycle_argo_edge_server
    build_vmess_share_files
    if [[ -f /etc/sing-box/node-info/vmess-subscription-raw.txt ]]; then
      sed '/^[[:space:]]*$/d' /etc/sing-box/node-info/vmess-subscription-raw.txt >> "$out_file"
    else
      vmess_uri >> "$out_file"
      printf '\n' >> "$out_file"
    fi
  fi

  if has_tuic_install; then
    cycle_argo_edge_server
    build_tuic_share_files
    if [[ -f /etc/sing-box/node-info/tuic5-subscription-raw.txt ]]; then
      sed '/^[[:space:]]*$/d' /etc/sing-box/node-info/tuic5-subscription-raw.txt >> "$out_file"
    else
      tuic_uri >> "$out_file"
      printf "\n" >> "$out_file"
    fi
  fi

  if has_argo_install; then
    ensure_argo_quick_service
    resolve_argo_domain "0" || true
    if [[ -n "${ARGO_DOMAIN:-}" ]]; then
      build_argo_share_files "0" || true
      if [[ -f "$ARGO_SUB_RAW_TXT" ]]; then
        sed '/^[[:space:]]*$/d' "$ARGO_SUB_RAW_TXT" >> "$out_file"
      else
        argo_uri >> "$out_file"
        printf '\n' >> "$out_file"
      fi
    fi
  fi

  [[ -s "$out_file" ]]
  ARGO_EDGE_INDEX="$saved_index"
}

append_clash_proxy_names() {
  local name
  for name in "$@"; do
    printf '      - %s\n' "$(yaml_quote "$name")" >> "$SUB_CLASH_YAML"
  done
}

append_clash_stable_proxy_names() {
  local name
  for name in "$@"; do
    printf '      - %s\n' "$(yaml_quote "$name")" >> "$SUB_CLASH_STABLE_YAML"
  done
}

build_subscription_clash_yaml() {
  local proxies=()
  local name

  mkdir -p "$SUBSCRIPTION_DIR"

  cat > "$SUB_CLASH_YAML" <<EOF
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
ipv6: false

dns:
  enable: true
  ipv6: false
  enhanced-mode: fake-ip
  default-nameserver:
    - 223.5.5.5
    - 119.29.29.29
    - 1.1.1.1
  nameserver:
    - 223.5.5.5
    - 119.29.29.29
    - 1.1.1.1
  proxy-server-nameserver:
    - 223.5.5.5
    - 119.29.29.29
    - 1.1.1.1

proxies:
EOF

  if has_vless_install; then
    name="$NODE_NAME_VLESS"
    proxies+=("$name")
    cat >> "$SUB_CLASH_YAML" <<EOF
  - name: $(yaml_quote "$name")
    type: vless
    server: $(yaml_quote "$DOMAIN")
    port: 443
    uuid: $(yaml_quote "$UUID")
    encryption: ""
    network: tcp
    tls: true
    udp: true
    ip-version: ipv4-prefer
    packet-encoding: xudp
    servername: $(yaml_quote "$DOMAIN")
    client-fingerprint: chrome
    reality-opts:
      public-key: $(yaml_quote "$PUBLIC_KEY")
      short-id: $(yaml_quote "$SHORT_ID")
EOF
  fi

  if has_hy2_install; then
    name="$NODE_NAME_HY2"
    proxies+=("$name")
    cat >> "$SUB_CLASH_YAML" <<EOF
  - name: $(yaml_quote "$name")
    type: hysteria2
    server: $(yaml_quote "$HY2_SERVER_ADDR")
    port: ${HY2_PORT}
EOF
    cat >> "$SUB_CLASH_YAML" <<EOF
    password: $(yaml_quote "$HY2_PASSWORD")
    up: $(yaml_quote "${HY2_CLIENT_UP_MBPS} Mbps")
    down: $(yaml_quote "${HY2_CLIENT_DOWN_MBPS} Mbps")
    sni: $(yaml_quote "$HY2_TLS_SNI")
    skip-cert-verify: true
    udp: true
    ip-version: ipv4-prefer
    alpn:
      - h3
EOF
    if [[ "${HY2_OBFS_ENABLED:-0}" == "1" ]]; then
      cat >> "$SUB_CLASH_YAML" <<EOF
    obfs: salamander
    obfs-password: $(yaml_quote "$HY2_OBFS_PASSWORD")
EOF
    fi
  fi

  if has_anytls_install; then
    name="$NODE_NAME_ANYTLS"
    proxies+=("$name")
    cat >> "$SUB_CLASH_YAML" <<EOF
  - name: $(yaml_quote "$name")
    type: anytls
    server: $(yaml_quote "$ANYTLS_SERVER_ADDR")
    port: ${ANYTLS_PORT}
    password: $(yaml_quote "$ANYTLS_PASSWORD")
    client-fingerprint: chrome
    udp: true
    sni: $(yaml_quote "$ANYTLS_TLS_SNI")
    alpn:
      - h2
      - http/1.1
    skip-cert-verify: false
EOF
  fi

  if has_ss2022_install; then
    name="$NODE_NAME_SS2022"
    proxies+=("$name")
    cat >> "$SUB_CLASH_YAML" <<EOF
  - name: $(yaml_quote "$name")
    type: ss
    server: $(yaml_quote "$SS2022_SERVER_ADDR")
    port: ${SS2022_PORT}
    cipher: $(yaml_quote "$SS2022_CIPHER")
    password: $(yaml_quote "$SS2022_PASSWORD")
    udp: true
    tfo: true
    ip-version: ipv4-prefer
EOF
  fi

  if has_vmess_install; then
    name="$NODE_NAME_VMESS"
    proxies+=("$name")
    if [[ "${VMESS_TLS_ENABLED:-0}" == "1" ]]; then
      cat >> "$SUB_CLASH_YAML" <<EOF
  - name: $(yaml_quote "$name")
    type: vmess
    server: $(yaml_quote "$VMESS_SERVER_ADDR")
    port: ${VMESS_PORT}
    uuid: $(yaml_quote "$VMESS_UUID")
    alterId: 0
    cipher: auto
    network: ws
    tls: true
    udp: true
    ip-version: ipv4-prefer
    servername: $(yaml_quote "$DOMAIN")
    client-fingerprint: chrome
    ws-opts:
      path: $(yaml_quote "$VMESS_WS_PATH")
      headers:
        Host: $(yaml_quote "$DOMAIN")
EOF
    else
      cat >> "$SUB_CLASH_YAML" <<EOF
  - name: $(yaml_quote "$name")
    type: vmess
    server: $(yaml_quote "$VMESS_SERVER_ADDR")
    port: ${VMESS_PORT}
    uuid: $(yaml_quote "$VMESS_UUID")
    alterId: 0
    cipher: auto
    network: ws
    udp: true
    ip-version: ipv4-prefer
    ws-opts:
      path: $(yaml_quote "$VMESS_WS_PATH")
EOF
    fi
  fi
  if has_argo_install; then
    ensure_argo_quick_service
    resolve_argo_domain "0" || true
    if [[ -n "${ARGO_DOMAIN:-}" ]]; then
      name="$NODE_NAME_ARGO"
      proxies+=("$name")
      cat >> "$SUB_CLASH_YAML" <<EOF
  - name: $(yaml_quote "$name")
    type: vless
    server: $(yaml_quote "$ARGO_EDGE_SERVER")
    port: 443
    uuid: $(yaml_quote "$ARGO_UUID")
    encryption: ""
    network: ws
    tls: true
    udp: true
    ip-version: ipv4-prefer
    servername: $(yaml_quote "$ARGO_DOMAIN")
    client-fingerprint: $(yaml_quote "$ARGO_CLIENT_FINGERPRINT")
    skip-cert-verify: false
    ws-opts:
      path: $(yaml_quote "$ARGO_WS_PATH")
      headers:
        Host: $(yaml_quote "$ARGO_DOMAIN")
EOF
    fi
  fi

  if [[ "${#proxies[@]}" -eq 0 ]]; then
    rm -f "$SUB_CLASH_YAML"
    return 1
  fi

  cat >> "$SUB_CLASH_YAML" <<EOF

proxy-groups:
  - name: PROXY
    type: select
    proxies:
EOF
  append_clash_proxy_names "${proxies[@]}"
  cat >> "$SUB_CLASH_YAML" <<EOF
      - DIRECT

rules:
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
EOF
}

build_subscription_clash_stable_yaml() {
  local proxies=()
  local name

  mkdir -p "$SUBSCRIPTION_DIR"
  rm -f "$SUB_CLASH_STABLE_YAML"

  cat > "$SUB_CLASH_STABLE_YAML" <<EOF
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
ipv6: false

dns:
  enable: true
  ipv6: false
  enhanced-mode: fake-ip
  default-nameserver:
    - 223.5.5.5
    - 119.29.29.29
    - 1.1.1.1
  nameserver:
    - 223.5.5.5
    - 119.29.29.29
    - 1.1.1.1
  proxy-server-nameserver:
    - 223.5.5.5
    - 119.29.29.29
    - 1.1.1.1

proxies:
EOF
  if has_argo_install; then
    ensure_argo_quick_service
    resolve_argo_domain "0" || true
    if [[ -n "${ARGO_DOMAIN:-}" ]]; then
      name="$NODE_NAME_ARGO"
      proxies+=("$name")
      cat >> "$SUB_CLASH_STABLE_YAML" <<EOF
  - name: $(yaml_quote "$name")
    type: vless
    server: $(yaml_quote "$ARGO_EDGE_SERVER")
    port: 443
    uuid: $(yaml_quote "$ARGO_UUID")
    encryption: ""
    network: ws
    tls: true
    udp: true
    ip-version: ipv4-prefer
    servername: $(yaml_quote "$ARGO_DOMAIN")
    client-fingerprint: $(yaml_quote "$ARGO_CLIENT_FINGERPRINT")
    skip-cert-verify: false
    ws-opts:
      path: $(yaml_quote "$ARGO_WS_PATH")
      headers:
        Host: $(yaml_quote "$ARGO_DOMAIN")
EOF
    fi
  fi

  if [[ "${#proxies[@]}" -eq 0 ]]; then
    rm -f "$SUB_CLASH_STABLE_YAML"
    return 1
  fi

  cat >> "$SUB_CLASH_STABLE_YAML" <<EOF

proxy-groups:
  - name: PROXY
    type: select
    proxies:
EOF
  append_clash_stable_proxy_names "${proxies[@]}"
  cat >> "$SUB_CLASH_STABLE_YAML" <<EOF
      - DIRECT

rules:
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
EOF
}

build_subscription_index_html() {
  local url
  url="$(subscription_url)"

  cat > "$SUB_INDEX_HTML" <<EOF
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${APP_NAME} subscription</title>
  <style>
    body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;margin:0;background:#f7f7f8;color:#18181b}
    main{max-width:760px;margin:8vh auto;padding:0 20px}
    h1{font-size:28px;margin:0 0 10px}
    p{line-height:1.7;color:#52525b}
    a{display:block;margin:10px 0;padding:12px 14px;background:#fff;border:1px solid #e4e4e7;border-radius:8px;color:#18181b;text-decoration:none}
    code{word-break:break-all;background:#fff;border:1px solid #e4e4e7;border-radius:6px;padding:2px 6px}
  </style>
</head>
<body>
  <main>
    <h1>${APP_NAME}</h1>
    <p>主订阅链接会按客户端 User-Agent 自动返回 Clash / mihomo 全量 YAML、通用 Base64 URI 或浏览器页面。</p>
    <p><code>${url}</code></p>
    <a href="${url}?target=clash-full">Clash YAML</a>
    <a href="${url}?target=mihomo">mihomo YAML</a>
    <a href="${url}?target=shadowrocket-full">Shadowrocket Base64</a>
    <a href="${url}?target=v2rayn">v2rayN / Base64 URI</a>
    <a href="${url}?target=raw">Raw URI</a>
    <a href="${url}/all">All / 所有协议 URI（v2rayN 格式）</a>
  </main>
</body>
</html>
EOF
}

write_subscription_server_script() {
  cat > "$SUB_SERVER_SCRIPT" <<'PY'
#!/usr/bin/env python3
import argparse
import http.server
import pathlib
import socket
import subprocess
import ssl
import threading
import time
import urllib.parse


TARGETS = {
    "clash": ("clash.yaml", "text/yaml; charset=utf-8"),
    "clash-verge": ("clash.yaml", "text/yaml; charset=utf-8"),
    "clash-compatible": ("clash.yaml", "text/yaml; charset=utf-8"),
    "clash-full": ("clash.yaml", "text/yaml; charset=utf-8"),
    "mihomo": ("clash.yaml", "text/yaml; charset=utf-8"),
    "stash": ("clash.yaml", "text/yaml; charset=utf-8"),
    "stable": ("clash-stable.yaml", "text/yaml; charset=utf-8"),
    "clash-stable": ("clash-stable.yaml", "text/yaml; charset=utf-8"),
    "mihomo-stable": ("clash-stable.yaml", "text/yaml; charset=utf-8"),
    "raw": ("raw.txt", "text/plain; charset=utf-8"),
    "all": ("raw.txt", "text/plain; charset=utf-8"),
    "base64": ("base64.txt", "text/plain; charset=utf-8"),
    "v2rayn": ("base64.txt", "text/plain; charset=utf-8"),
    "shadowrocket": ("base64.txt", "text/plain; charset=utf-8"),
    "shadowrocket-full": ("base64.txt", "text/plain; charset=utf-8"),
    "html": ("index.html", "text/html; charset=utf-8"),
}

MIHOMO_UA = ("mihomo", "meta")
CLASH_UA = ("clash", "stash", "verge", "flclash")
SHADOWROCKET_UA = ("shadowrocket",)
BASE64_UA = ("v2ray", "v2rayn", "streisand", "nekobox", "hiddify")
BROWSER_UA = ("mozilla", "chrome", "safari", "firefox", "edge", "edg/", "opera")


class DualStackThreadingHTTPServer(http.server.ThreadingHTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        if hasattr(socket, "IPV6_V6ONLY"):
            try:
                self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
            except OSError:
                pass
        super().server_bind()


class SubscriptionHandler(http.server.BaseHTTPRequestHandler):
    root = pathlib.Path(".")
    sub_path = ""
    refresh_script = ""
    refresh_ttl = 10
    last_refresh = 0.0
    refresh_lock = threading.Lock()

    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        parsed = urllib.parse.urlsplit(self.path)
        normalized_path = parsed.path.strip("/")
        is_all = normalized_path.endswith("/all") and normalized_path[:normalized_path.rfind("/")] == self.sub_path
        if normalized_path != self.sub_path and not is_all:
            self.send_error(404)
            return

        self.refresh_payload()

        query = urllib.parse.parse_qs(parsed.query)
        target = (query.get("target", [""])[0] or "").lower()
        if is_all:
            filename, content_type = TARGETS["raw"]
        elif not target:
            target = self.detect_target()
            filename, content_type = TARGETS.get(target, TARGETS["base64"])
        else:
            filename, content_type = TARGETS.get(target, TARGETS["base64"])
        file_path = self.root / filename
        if target in ("clash", "clash-verge", "clash-compatible") and not file_path.is_file():
            filename, content_type = TARGETS["clash-full"]
            file_path = self.root / filename
        if not file_path.is_file():
            self.send_error(404)
            return

        data = file_path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def refresh_payload(self):
        if not self.refresh_script:
            return

        now = time.monotonic()
        with self.refresh_lock:
            if now - self.last_refresh < self.refresh_ttl:
                return
            self.last_refresh = now
            try:
                subprocess.run(
                    ["/bin/bash", self.refresh_script, "--refresh-argo-subscription", "request"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=10,
                    check=False,
                )
            except Exception:
                return

    def detect_target(self):
        ua = self.headers.get("User-Agent", "").lower()
        if any(item in ua for item in MIHOMO_UA):
            return "mihomo"
        if any(item in ua for item in CLASH_UA):
            return "clash"
        if any(item in ua for item in SHADOWROCKET_UA):
            return "shadowrocket-full"
        if any(item in ua for item in BASE64_UA):
            return "base64"
        if any(item in ua for item in BROWSER_UA):
            return "html"
        return "base64"


def make_http_server(host, port):
    if ":" in host:
        try:
            return DualStackThreadingHTTPServer((host, port), SubscriptionHandler)
        except OSError:
            if host == "::":
                return http.server.ThreadingHTTPServer(("0.0.0.0", port), SubscriptionHandler)
            raise
    return http.server.ThreadingHTTPServer((host, port), SubscriptionHandler)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="::")
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--path", required=True)
    parser.add_argument("--dir", required=True)
    parser.add_argument("--cert", required=True)
    parser.add_argument("--key", required=True)
    parser.add_argument("--refresh-script", default="")
    parser.add_argument("--refresh-ttl", type=int, default=10)
    args = parser.parse_args()

    SubscriptionHandler.root = pathlib.Path(args.dir)
    SubscriptionHandler.sub_path = args.path.strip("/")
    SubscriptionHandler.refresh_script = args.refresh_script
    SubscriptionHandler.refresh_ttl = max(args.refresh_ttl, 0)

    httpd = make_http_server(args.host, args.port)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(args.cert, args.key)
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
PY
  chmod 0755 "$SUB_SERVER_SCRIPT"
}

write_subscription_service() {
  local argo_after="" argo_prestart="" argo_wants="" refresh_args=""

  if has_argo_install; then
    install_self_script || true
    argo_after=" ${ARGO_SERVICE}"
    argo_wants=" ${ARGO_SERVICE}"
    argo_prestart="ExecStartPre=-/bin/bash ${INSTALL_SCRIPT} --refresh-argo-subscription request"
    refresh_args=" --refresh-script ${INSTALL_SCRIPT} --refresh-ttl 15"
  fi

  cat > "/etc/systemd/system/${SUB_SERVICE}" <<EOF
[Unit]
Description=${APP_NAME} smart subscription service
After=network-online.target${argo_after}
Wants=network-online.target${argo_wants}

[Service]
Type=simple
${argo_prestart}
ExecStart=/usr/bin/python3 ${SUB_SERVER_SCRIPT} --host :: --port ${SUB_PORT} --path ${SUB_PATH} --dir ${SUBSCRIPTION_DIR} --cert ${SSL_DIR}/fullchain.cer --key ${SSL_DIR}/private.key${refresh_args}
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
}

build_subscription_payload_files() {
  mkdir -p "$SUBSCRIPTION_DIR"

  if ! write_uri_subscription_raw "$SUB_URI_RAW_TXT"; then
    rm -f "$SUB_URI_RAW_TXT" "$SUB_URI_B64_TXT" "$SUB_CLASH_YAML" "$SUB_INDEX_HTML"
    return 1
  fi

  base64 -w 0 < "$SUB_URI_RAW_TXT" > "$SUB_URI_B64_TXT"
  build_subscription_clash_yaml
  build_subscription_clash_stable_yaml || true
  build_subscription_index_html
}

install_subscription_service() {
  if ! cert_matches_domain || ! cert_is_currently_valid; then
    yellow "订阅服务需要可用域名证书，已跳过 HTTPS 订阅服务。"
    return 1
  fi

  systemctl stop "$SUB_SERVICE" >/dev/null 2>&1 || true
  ensure_dual_stack_ipv6_bind

  if [[ -z "${SUB_PORT:-}" ]]; then
    pick_subscription_port
  elif port_in_use "$SUB_PORT"; then
    yellow "订阅端口 ${SUB_PORT} 已被占用，重新选择随机高位端口。"
    pick_subscription_port
  fi

  if [[ -z "${SUB_PATH:-}" ]]; then
    generate_subscription_path
  fi

  SUB_ENABLED="1"
  if ! build_subscription_payload_files; then
    yellow "当前没有可发布的订阅内容，已跳过 HTTPS 订阅服务。"
    SUB_ENABLED="0"
    return 1
  fi
  write_subscription_server_script
  write_subscription_service
  systemctl daemon-reload
  systemctl enable "$SUB_SERVICE" >/dev/null 2>&1 || true
  systemctl restart "$SUB_SERVICE"
}

refresh_subscription_service() {
  if ! has_subscription_service; then
    build_combined_subscription_files || true
    return 0
  fi

  if build_subscription_payload_files; then
    write_subscription_server_script
    write_subscription_service
    systemctl daemon-reload
    systemctl enable "$SUB_SERVICE" >/dev/null 2>&1 || true
    systemctl restart "$SUB_SERVICE" >/dev/null 2>&1 || true
    build_combined_subscription_files || true
  else
    yellow "已无可用节点，关闭智能订阅服务。"
    systemctl disable --now "$SUB_SERVICE" >/dev/null 2>&1 || true
    rm -rf "$SUBSCRIPTION_DIR"
    SUB_ENABLED="0"
    SUB_PORT=""
    SUB_PATH=""
    save_state
    build_combined_subscription_files || true
  fi
}

