#!/usr/bin/env bash
# =============================================================================
# protocols.sh - All proxy protocols
# =============================================================================

generate_keys_and_ids() {
  UUID="$(cat /proc/sys/kernel/random/uuid)"
  XHTTP_PATH=""
  SHORT_ID="$(openssl rand -hex 8)"

  local bin keys
  bin="$(sing_box_cmd 2>/dev/null || true)"
  if [[ -z "$bin" ]]; then
    install_sing_box
    bin="$(sing_box_cmd 2>/dev/null || true)"
  fi

  keys="$("$bin" generate reality-keypair)"
  PRIVATE_KEY="$(awk -F: 'tolower($1) ~ /private/ {v=$2; sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v); print v; exit}' <<<"$keys")"
  PUBLIC_KEY="$(awk -F: 'tolower($1) ~ /public/ {v=$2; sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v); print v; exit}' <<<"$keys")"

  if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
    red "sing-box reality-keypair 生成失败"
    echo "$keys"
    exit 1
  fi
}

write_sing_box_service() {
  cat > "/etc/systemd/system/${SING_BOX_SERVICE}" <<EOF
[Unit]
Description=${APP_NAME} sing-box service
Documentation=https://sing-box.sagernet.org
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${SING_BOX_BIN} run -c ${SING_BOX_CFG}
Restart=on-failure
RestartSec=5s
LimitNOFILE=1048576
LimitMEMLOCK=infinity
Nice=-5

[Install]
WantedBy=multi-user.target
EOF
}

write_sing_box_config() {
  local public_listen tmp_cfg

  install_sing_box
  disable_legacy_protocol_services

  if ! sing_box_has_enabled_inbound; then
    systemctl disable --now "$SING_BOX_SERVICE" >/dev/null 2>&1 || true
    rm -f "$SING_BOX_CFG"
    return 0
  fi

  ensure_dual_stack_ipv6_bind
  public_listen="$(public_sing_box_listen_addr)"
  mkdir -p "$SING_BOX_DIR"
  tmp_cfg="$(mktemp)"

  jq -n \
    --arg domain "${DOMAIN:-}" \
    --arg uuid "${UUID:-}" \
    --arg private_key "${PRIVATE_KEY:-}" \
    --arg public_key "${PUBLIC_KEY:-}" \
    --arg short_id "${SHORT_ID:-}" \
    --arg target_port "${TARGET_PORT:-$DEFAULT_TARGET_PORT}" \
    --arg cert_path "${SSL_DIR}/fullchain.cer" \
    --arg key_path "${SSL_DIR}/private.key" \
    --arg hy2_enabled "${HY2_ENABLED:-0}" \
    --arg hy2_port "${HY2_PORT:-}" \
    --arg hy2_password "${HY2_PASSWORD:-}" \
    --arg hy2_tls_sni "${HY2_TLS_SNI:-${DOMAIN:-}}" \
    --arg hy2_obfs_enabled "${HY2_OBFS_ENABLED:-0}" \
    --arg hy2_obfs_password "${HY2_OBFS_PASSWORD:-}" \
    --arg anytls_enabled "${ANYTLS_ENABLED:-0}" \
    --arg anytls_port "${ANYTLS_PORT:-}" \
    --arg anytls_password "${ANYTLS_PASSWORD:-}" \
    --arg anytls_tls_sni "${ANYTLS_TLS_SNI:-${DOMAIN:-}}" \
    --arg ss2022_enabled "${SS2022_ENABLED:-0}" \
    --arg ss2022_port "${SS2022_PORT:-}" \
    --arg ss2022_cipher "${SS2022_CIPHER:-}" \
    --arg ss2022_password "${SS2022_PASSWORD:-}" \
    --arg argo_enabled "${ARGO_ENABLED:-0}" \
    --arg argo_local_port "${ARGO_LOCAL_PORT:-}" \
    --arg argo_uuid "${ARGO_UUID:-}" \
    --arg argo_ws_path "${ARGO_WS_PATH:-}" \
    --arg vmess_enabled "${VMESS_ENABLED:-0}" \
    --arg vmess_port "${VMESS_PORT:-}" \
    --arg vmess_uuid "${VMESS_UUID:-}" \
    --arg vmess_ws_path "${VMESS_WS_PATH:-}" \
    --arg vmess_tls_enabled "${VMESS_TLS_ENABLED:-0}" \
    --arg vmess_enabled "${VMESS_ENABLED:-0}" \
    --arg vmess_port "${VMESS_PORT:-}" \
    --arg vmess_uuid "${VMESS_UUID:-}" \
    --arg vmess_ws_path "${VMESS_WS_PATH:-}" \
    --arg vmess_tls_enabled "${VMESS_TLS_ENABLED:-0}" \
    --arg tuic_enabled "${TUIC_ENABLED:-0}" \
    --arg tuic_port "${TUIC_PORT:-}" \
    --arg tuic_password "${TUIC_PASSWORD:-}" \
    --arg tuic_tls_sni "${TUIC_TLS_SNI:-${DOMAIN:-}}" \
    --arg public_listen "$public_listen" '
[
  (if $uuid != "" and $private_key != "" and $public_key != "" and $short_id != "" then
    {
      "type": "vless",
      "tag": "vless-tcp-reality-in",
      "listen": $public_listen,
      "listen_port": 443,
      "users": [
        {
          "name": "vless",
          "uuid": $uuid,
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": $domain,
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "127.0.0.1",
            "server_port": ($target_port | tonumber)
          },
          "private_key": $private_key,
          "short_id": [
            $short_id
          ]
        }
      }
    }
  else empty end),
  (if $hy2_enabled == "1" and $hy2_port != "" and $hy2_password != "" then
    ({
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": $public_listen,
      "listen_port": ($hy2_port | tonumber),
      "users": [
        {
          "name": "hy2",
          "password": $hy2_password
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": $hy2_tls_sni,
        "alpn": [
          "h3"
        ],
        "certificate_path": $cert_path,
        "key_path": $key_path
      }
    } + (if $hy2_obfs_enabled == "1" and $hy2_obfs_password != "" then
      {
        "obfs": {
          "type": "salamander",
          "password": $hy2_obfs_password
        }
      }
    else {} end))
  else empty end),
  (if $anytls_enabled == "1" and $anytls_port != "" and $anytls_password != "" then
    {
      "type": "anytls",
      "tag": "anytls-in",
      "listen": $public_listen,
      "listen_port": ($anytls_port | tonumber),
      "users": [
        {
          "name": "anytls",
          "password": $anytls_password
        }
      ],
      "padding_scheme": [],
      "tls": {
        "enabled": true,
        "server_name": $anytls_tls_sni,
        "certificate_path": $cert_path,
        "key_path": $key_path
      }
    }
  else empty end),
  (if $ss2022_enabled == "1" and $ss2022_port != "" and $ss2022_cipher != "" and $ss2022_password != "" then
    {
      "type": "shadowsocks",
      "tag": "ss2022-in",
      "listen": $public_listen,
      "listen_port": ($ss2022_port | tonumber),
      "method": $ss2022_cipher,
      "password": $ss2022_password
    }
  else empty end),
  (if $argo_enabled == "1" and $argo_local_port != "" and $argo_uuid != "" and $argo_ws_path != "" then
    {
      "type": "vless",
      "tag": "argo-vless-ws-in",
      "listen": "127.0.0.1",
      "listen_port": ($argo_local_port | tonumber),
      "users": [
        {
          "name": "argo",
          "uuid": $argo_uuid
        }
      ],
      "transport": {
        "type": "ws",
        "path": $argo_ws_path
      }
    }
  else empty end),
  (if $vmess_enabled == "1" and $vmess_port != "" and $vmess_uuid != "" and $vmess_ws_path != "" then
    {
      "type": "vmess",
      "tag": "vmess-ws-in",
      "listen": $public_listen,
      "listen_port": ($vmess_port | tonumber),
      "users": [
        {
          "name": "vmess",
          "uuid": $vmess_uuid,
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": $vmess_ws_path
      },
      "tls": {
        "enabled": ($vmess_tls_enabled == "1"),
        "server_name": $domain,
        "certificate_path": $cert_path,
        "key_path": $key_path
      }
    } + (if $vmess_tls_enabled != "1" then {"tls": {"enabled": false}} else {} end)
    }
  else empty end),
  (if $vmess_enabled == "1" and $vmess_port != "" and $vmess_uuid != "" and $vmess_ws_path != "" then
    {
      "type": "vmess",
      "tag": "vmess-ws-in",
      "listen": $public_listen,
      "listen_port": ($vmess_port | tonumber),
      "users": [
        {
          "name": "vmess",
          "uuid": $vmess_uuid,
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": $vmess_ws_path
      },
      "tls": (
        if $vmess_tls_enabled == "1" then
          {
            "enabled": true,
            "server_name": $domain,
            "certificate_path": $cert_path,
            "key_path": $key_path
          }
        else {
            "enabled": false
          }
        end
      )
    }
  else empty end),
  (if $tuic_enabled == "1" and $tuic_port != "" and $tuic_password != "" then
    {
      "type": "tuic",
      "tag": "tuic5-in",
      "listen": $public_listen,
      "listen_port": ($tuic_port | tonumber),
      "users": [
        {
          "uuid": $tuic_password,
          "password": $tuic_password
        }
      ],
      "congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "server_name": $tuic_tls_sni,
        "alpn": ["h3"],
        "certificate_path": $cert_path,
        "key_path": $key_path
      }
    }
  else empty end)
] as $inbounds
| if ($inbounds | length) == 0 then
    error("no sing-box inbounds enabled")
  else
    {
      "log": {
        "level": "info",
        "timestamp": true
      },
      "inbounds": $inbounds,
      "outbounds": [
        {
          "type": "direct",
          "tag": "direct"
        },
        {
          "type": "block",
          "tag": "block"
        }
      ],
      "route": {
        "final": "direct"
      },
      "inbound_opts": {
        "tcp_keep_alive_idle": "30s",
        "tcp_keep_alive_interval": "10s",
        "tcp_keep_alive_count": 3,
        "tcp_fast_open": true,
        "tcp_multi_path": false,
        "udp_fragment": true,
        "udp_timeout": "120s"
      }
    }
  end
' > "$tmp_cfg"

  "$SING_BOX_BIN" check -c "$tmp_cfg"
  install -m 0600 "$tmp_cfg" "$SING_BOX_CFG"
  rm -f "$tmp_cfg"

  write_sing_box_service
  write_sing_box_service_tuning
  systemctl daemon-reload
  systemctl enable "$SING_BOX_SERVICE" >/dev/null 2>&1 || true
  systemctl restart "$SING_BOX_SERVICE"
}

write_xray_config() {
  write_sing_box_config
}

generate_subscription_path() {
  SUB_PATH="sub-$(openssl rand -hex 12)"
}

subscription_url() {
  if [[ -n "${DOMAIN:-}" && -n "${SUB_PORT:-}" && -n "${SUB_PATH:-}" ]]; then
    printf 'https://%s:%s/%s' "$DOMAIN" "$SUB_PORT" "$SUB_PATH"
  fi
}

print_subscription_links() {
  local sub_url="${1:-}"

  if [[ -z "$sub_url" ]]; then
    sub_url="$(subscription_url)"
  fi
  [[ -n "$sub_url" ]] || return 1

  echo "[智能订阅链接]"
  echo "Auto / 主链接: $sub_url"
  echo "Clash: ${sub_url}?target=clash-full"
  echo "mihomo: ${sub_url}?target=mihomo"
  echo "Shadowrocket: ${sub_url}?target=shadowrocket-full"
  echo "v2rayN / Base64: ${sub_url}?target=v2rayn"
  echo "Raw URI: ${sub_url}?target=raw"
}

anytls_uri() {
  local e_pass e_sni e_label
  e_pass="$(urlenc "$ANYTLS_PASSWORD")"
  e_sni="$(urlenc "$ANYTLS_TLS_SNI")"
  e_label="$(urlenc "$NODE_NAME_ANYTLS")"
  printf 'anytls://%s@%s:%s/?sni=%s&insecure=0#%s' \
    "$e_pass" "$ANYTLS_SERVER_ADDR" "$ANYTLS_PORT" "$e_sni" "$e_label"
}

ss2022_uri() {
  local e_label userinfo
  e_label="$(urlenc "$NODE_NAME_SS2022")"
  userinfo="$(printf '%s' "${SS2022_CIPHER}:${SS2022_PASSWORD}" | base64 -w 0 | tr '+/' '-_' | tr -d '=')"
  printf 'ss://%s@%s:%s#%s' "$userinfo" "$SS2022_SERVER_ADDR" "$SS2022_PORT" "$e_label"
}

argo_uri() {
  local e_host e_label e_path e_sni
  e_sni="$(urlenc "$ARGO_DOMAIN")"
  e_host="$(urlenc "$ARGO_DOMAIN")"
  e_path="$(urlenc "$ARGO_WS_PATH")"
  e_label="$(urlenc "$NODE_NAME_ARGO")"
  printf 'vless://%s@%s:443?encryption=none&security=tls&sni=%s&fp=%s&insecure=0&allowInsecure=0&type=ws&host=%s&path=%s#%s' \
    "$ARGO_UUID" "$ARGO_EDGE_SERVER" "$e_sni" "$ARGO_CLIENT_FINGERPRINT" "$e_host" "$e_path" "$e_label"
}

calc_cert_pin_sha256() {
  openssl x509 -in "$SSL_DIR/fullchain.cer" -noout -fingerprint -sha256 2>/dev/null | sed 's/^.*=//'
}

calc_cert_public_key_pin_sha256() {
  openssl x509 -in "$SSL_DIR/fullchain.cer" -pubkey -noout 2>/dev/null \
    | openssl pkey -pubin -outform der 2>/dev/null \
    | openssl dgst -sha256 -binary 2>/dev/null \
    | openssl base64 -A 2>/dev/null
}

resolve_hy2_server_addr() {
  HY2_SERVER_ADDR="$(preferred_direct_server_addr || printf '%s\n' "$DOMAIN")"
  HY2_TLS_SNI="$DOMAIN"
}

build_client_files() {
  local e_sni e_pbk e_sid e_spx e_label server_addr uri
  server_addr="$(preferred_direct_server_addr || printf '%s\n' "$DOMAIN")"
  e_sni="$(urlenc "$DOMAIN")"
  e_pbk="$(urlenc "$PUBLIC_KEY")"
  e_sid="$(urlenc "$SHORT_ID")"
  e_spx="$(urlenc "/")"
  e_label="$(urlenc "$NODE_NAME_VLESS")"

  cat > "$CLIENT_JSON" <<EOF
{
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$server_addr",
            "port": 443,
            "users": [
              {
                "id": "$UUID",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "chrome",
          "serverName": "$DOMAIN",
          "publicKey": "$PUBLIC_KEY",
          "shortId": "$SHORT_ID",
          "spiderX": "/"
        }
      }
    }
  ]
}
EOF

  uri="vless://${UUID}@${server_addr}:443?encryption=none&security=reality&sni=${e_sni}&fp=chrome&pbk=${e_pbk}&sid=${e_sid}&type=tcp&headerType=none&spx=${e_spx}#${e_label}"

  cat > "$SHARE_TXT" <<EOF
domain: $DOMAIN
serverAddress: $server_addr
uuid: $UUID
publicKey: $PUBLIC_KEY
shortId: $SHORT_ID
transport: tcp
mode: $INSTALL_MODE
targetPort: $TARGET_PORT

=== VLESS URI ===
$uri

=== Client JSON ===
$CLIENT_JSON
EOF

  printf '%s\n' "$uri" > "$SUB_RAW_TXT"
  printf '%s\n' "$uri" | base64 -w 0 > "$SUB_B64_TXT"

  if command -v qrencode >/dev/null 2>&1; then
    printf '%s' "$uri" | qrencode -o "$NODE_QR_PNG" -t PNG -s 8 -m 2 >/dev/null 2>&1 || true
  fi
}


pick_tuic_server_addr() {
  TUIC_SERVER_ADDR="$(preferred_direct_server_addr || printf '%s\n' "$DOMAIN")"
  TUIC_TLS_SNI="$DOMAIN"
}

generate_tuic_password() {
  TUIC_PASSWORD="$(generate_alnum_secret 24)"
}

generate_vmess_identity() {
  VMESS_UUID="$(cat /proc/sys/kernel/random/uuid)"
  VMESS_WS_PATH="/ws-$(openssl rand -hex 6)"
  [[ -z "${VMESS_TLS_ENABLED:-}" ]] && VMESS_TLS_ENABLED="0"
}

install_vmess_core() {
  install_sing_box
  pick_vmess_port
  generate_vmess_identity
  VMESS_ENABLED="1"
  write_sing_box_config
  build_vmess_share_files
  return 0
}

build_vmess_share_files() {
  local label e_label
  label="$NODE_NAME_VMESS"
  e_label="$(urlenc "$label")"
  # Only build share files for non-Argo VMESS (Argo handles its own)
  if [[ "${VMESS_TLS_ENABLED:-0}" == "1" ]]; then
    uri="vmess://$(echo -n '{"add":"'"$VMESS_SERVER_ADDR"'","aid":"0","host":"'"$DOMAIN"'","id":"'"$VMESS_UUID"'","net":"ws","path":"'"$VMESS_WS_PATH"'","port":"'"$VMESS_PORT"'","ps":"'"$label"'","tls":"tls","sni":"'"$DOMAIN"'","fp":"chrome","type":"none","v":"2"}' | base64 -w 0)"
  else
    uri="vmess://$(echo -n '{"add":"'"$VMESS_SERVER_ADDR"'","aid":"0","id":"'"$VMESS_UUID"'","net":"ws","path":"'"$VMESS_WS_PATH"'","port":"'"$VMESS_PORT"'","ps":"'"$label"'","type":"none","v":"2"}' | base64 -w 0)"
  fi
  
  cat > /etc/sing-box/node-info/vmess-share.txt <<EOF
domain: $DOMAIN
serverAddress: ${VMESS_SERVER_ADDR}
serverPort: ${VMESS_PORT}
uuid: ${VMESS_UUID}
wsPath: ${VMESS_WS_PATH}
tls: ${VMESS_TLS_ENABLED}

=== VMess-WS URI ===
$uri
EOF

  printf '%s\n' "$uri" > /etc/sing-box/node-info/vmess-subscription-raw.txt
  base64 -w 0 < /etc/sing-box/node-info/vmess-subscription-raw.txt > /etc/sing-box/node-info/vmess-subscription-base64.txt

  if command -v qrencode >/dev/null 2>&1; then
    printf '%s' "$uri" | qrencode -o "/etc/sing-box/node-info/vmess-node-qr.png" -t PNG -s 8 -m 2 >/dev/null 2>&1 || true
  fi
}

vmess_uri() {
  local e_label
  e_label="$(urlenc "$NODE_NAME_VMESS")"
  if [[ "${VMESS_TLS_ENABLED:-0}" == "1" ]]; then
    printf 'vmess://%s' "$(echo -n '{"add":"'"$VMESS_SERVER_ADDR"'","aid":"0","host":"'"$DOMAIN"'","id":"'"$VMESS_UUID"'","net":"ws","path":"'"$VMESS_WS_PATH"'","port":"'"$VMESS_PORT"'","ps":"'"$NODE_NAME_VMESS"'","tls":"tls","sni":"'"$DOMAIN"'","fp":"chrome","type":"none","v":"2"}' | base64 -w 0)"
  else
    printf 'vmess://%s' "$(echo -n '{"add":"'"$VMESS_SERVER_ADDR"'","aid":"0","id":"'"$VMESS_UUID"'","net":"ws","path":"'"$VMESS_WS_PATH"'","port":"'"$VMESS_PORT"'","ps":"'"$NODE_NAME_VMESS"'","type":"none","v":"2"}' | base64 -w 0)"
  fi
}

generate_vmess_identity() {
  VMESS_UUID="$(cat /proc/sys/kernel/random/uuid)"
  VMESS_WS_PATH="/ws-$(openssl rand -hex 6)"
  [[ -z "${VMESS_TLS_ENABLED:-}" ]] && VMESS_TLS_ENABLED="0"
}

install_vmess_core() {
  install_sing_box
  generate_vmess_identity
  pick_vmess_port
  VMESS_ENABLED="1"
  write_sing_box_config
  build_vmess_share_files
  return 0
}

build_vmess_share_files() {
  local label uri
  label="$NODE_NAME_VMESS"
  if [[ "${VMESS_TLS_ENABLED:-0}" == "1" ]]; then
    uri="vmess://$(echo -n '{"add":"'"$VMESS_SERVER_ADDR"'","aid":"0","host":"'"$DOMAIN"'","id":"'"$VMESS_UUID"'","net":"ws","path":"'"$VMESS_WS_PATH"'","port":"'"$VMESS_PORT"'","ps":"'"$label"'","tls":"tls","sni":"'"$DOMAIN"'","fp":"chrome","type":"none","v":"2"}' | base64 -w 0)"
  else
    uri="vmess://$(echo -n '{"add":"'"$VMESS_SERVER_ADDR"'","aid":"0","id":"'"$VMESS_UUID"'","net":"ws","path":"'"$VMESS_WS_PATH"'","port":"'"$VMESS_PORT"'","ps":"'"$label"'","type":"none","v":"2"}' | base64 -w 0)"
  fi

  mkdir -p /etc/sing-box/node-info
  cat > /etc/sing-box/node-info/vmess-share.txt <<EOF
domain: $DOMAIN
serverAddress: ${VMESS_SERVER_ADDR}
serverPort: ${VMESS_PORT}
uuid: ${VMESS_UUID}
wsPath: ${VMESS_WS_PATH}
tls: ${VMESS_TLS_ENABLED}

=== Vmess-WS URI ===
$uri
EOF

  printf '%s\n' "$uri" > /etc/sing-box/node-info/vmess-subscription-raw.txt
  base64 -w 0 < /etc/sing-box/node-info/vmess-subscription-raw.txt > /etc/sing-box/node-info/vmess-subscription-base64.txt

  if command -v qrencode >/dev/null 2>&1; then
    printf '%s' "$uri" | qrencode -o "/etc/sing-box/node-info/vmess-node-qr.png" -t PNG -s 8 -m 2 >/dev/null 2>&1 || true
  fi
}

vmess_uri() {
  if [[ "${VMESS_TLS_ENABLED:-0}" == "1" ]]; then
    printf 'vmess://%s' "$(echo -n '{"add":"'"$VMESS_SERVER_ADDR"'","aid":"0","host":"'"$DOMAIN"'","id":"'"$VMESS_UUID"'","net":"ws","path":"'"$VMESS_WS_PATH"'","port":"'"$VMESS_PORT"'","ps":"'"$NODE_NAME_VMESS"'","tls":"tls","sni":"'"$DOMAIN"'","fp":"chrome","type":"none","v":"2"}' | base64 -w 0)"
  else
    printf 'vmess://%s' "$(echo -n '{"add":"'"$VMESS_SERVER_ADDR"'","aid":"0","id":"'"$VMESS_UUID"'","net":"ws","path":"'"$VMESS_WS_PATH"'","port":"'"$VMESS_PORT"'","ps":"'"$NODE_NAME_VMESS"'","type":"none","v":"2"}' | base64 -w 0)"
  fi
}

install_tuic_core() {
  if ! cert_matches_domain || ! cert_is_currently_valid; then
    red "当前域名证书不可用，请先执行菜单 3 修复证书。"
    return 1
  fi
  install_sing_box
  pick_tuic_server_addr
  generate_tuic_password
  pick_tuic_port
  TUIC_ENABLED="1"
  write_sing_box_config
  build_tuic_share_files
  return 0
}

build_tuic_share_files() {
  local label e_sni e_pass uri
  pick_tuic_server_addr
  label="$NODE_NAME_TUIC"
  e_pass="$(urlenc "$TUIC_PASSWORD")"
  e_sni="$(urlenc "$TUIC_TLS_SNI")"
  uri="tuic://${TUIC_PASSWORD}:${TUIC_PASSWORD}@${TUIC_SERVER_ADDR}:${TUIC_PORT}?congestion_control=bbr&udp_relay_mode=native&alpn=h3&sni=${e_sni}&insecure=0&allowInsecure=0#${label}"

  cat > /etc/sing-box/node-info/tuic5-share.txt <<EOF
domain: $DOMAIN
serverAddress: ${TUIC_SERVER_ADDR}
serverPort: ${TUIC_PORT}
sni: ${TUIC_TLS_SNI}
password: ${TUIC_PASSWORD}
firewallRequired: allow TCP/UDP ${TUIC_PORT}

=== Tuic-v5 URI ===
$uri
EOF

  printf '%s\n' "$uri" > /etc/sing-box/node-info/tuic5-subscription-raw.txt
  base64 -w 0 < /etc/sing-box/node-info/tuic5-subscription-raw.txt > /etc/sing-box/node-info/tuic5-subscription-base64.txt

  if command -v qrencode >/dev/null 2>&1; then
    printf '%s' "$uri" | qrencode -o "/etc/sing-box/node-info/tuic5-node-qr.png" -t PNG -s 8 -m 2 >/dev/null 2>&1 || true
  fi
}

tuic_uri() {
  local e_pass e_sni e_label
  e_pass="$(urlenc "$TUIC_PASSWORD")"
  e_sni="$(urlenc "$TUIC_TLS_SNI")"
  e_label="$(urlenc "$NODE_NAME_TUIC")"
  printf 'tuic://%s:%s@%s:%s?congestion_control=bbr&udp_relay_mode=native&alpn=h3&sni=%s&insecure=0#%s' \
    "$e_pass" "$e_pass" "$TUIC_SERVER_ADDR" "$TUIC_PORT" "$e_sni" "$e_label"
}

show_node_info() {
  if ! load_state; then
    red "未检测到安装记录"
    return
  fi

  if has_vless_install; then
    build_client_files
  fi

  if has_hy2_install; then
    build_hysteria2_share_files
  fi

  if has_anytls_install; then
    build_anytls_share_files
  fi

  if has_ss2022_install; then
    build_ss2022_share_files
  fi

  if has_vmess_install; then
    if [[ -f /etc/sing-box/node-info/vmess-subscription-raw.txt ]]; then
      sed /^[[:space:]]*$/d /etc/sing-box/node-info/vmess-subscription-raw.txt >> "$out_file"
    else
      vmess_uri >> "$out_file"
      printf "\n" >> "$out_file"
    fi
  fi
  if has_argo_install; then
    ensure_argo_quick_service
    build_argo_share_files "0" || true
    save_state
  fi

  build_combined_subscription_files || true

  cyan "================ 节点信息 ================"
  echo "脚本版本: ${APP_VERSION}"
  echo

  if has_vless_install; then
    echo "[VLESS URL]"
    sed -n '/^=== VLESS URI ===$/ {n;p;}' "$SHARE_TXT"
    echo
  fi

  if has_hy2_install; then
    echo "[Hysteria2 URL]"
    sed -n '/^=== Hysteria2 URI ===$/ {n;p;}' "$HY2_SHARE_TXT"
    echo
  fi

  if has_anytls_install; then
    echo "[AnyTLS URL / mihomo YAML]"
    if [[ -f "$ANYTLS_SUB_RAW_TXT" ]]; then
      sed -n '1p' "$ANYTLS_SUB_RAW_TXT"
    fi
    echo
  fi

  if has_ss2022_install; then
    echo "[Shadowsocks-2022 URL]"
    if [[ -f "$SS2022_SUB_RAW_TXT" ]]; then
      sed -n '1p' "$SS2022_SUB_RAW_TXT"
    fi
    echo
  fi

  if has_argo_install; then
    echo "[Argo / Cloudflare Tunnel URL]"
    if [[ -f "$ARGO_SUB_RAW_TXT" ]]; then
      sed '/^[[:space:]]*$/d' "$ARGO_SUB_RAW_TXT"
    else
      yellow "暂未获取到 trycloudflare.com 域名，请查看 cloudflared 日志。"
    fi
    echo
  fi

  if has_subscription_service; then
    local sub_url
    sub_url="$(subscription_url)"
    print_subscription_links "$sub_url"
    echo
    if command -v qrencode >/dev/null 2>&1 && [[ -n "$sub_url" ]]; then
      echo "----- 智能订阅二维码 -----"
      printf '%s' "$sub_url" | qrencode -t ANSIUTF8 || true
      echo
    fi
  elif [[ -f "$COMBO_SUB_RAW_TXT" || -f "$COMBO_SUB_B64_TXT" ]]; then
    echo "[本地合并订阅文件]"
    echo "raw: $COMBO_SUB_RAW_TXT"
    echo "base64: $COMBO_SUB_B64_TXT"
    echo
  fi

  if ! has_vless_install && ! has_hy2_install && ! has_anytls_install && ! has_ss2022_install && ! has_argo_install; then
    yellow "未检测到可展示的协议配置"
  fi

  cyan "========================================"
}

prompt_hy2_obfs() {
  HY2_OBFS_ENABLED="0"
  HY2_OBFS_PASSWORD=""
}

resolve_anytls_server_addr() {
  ANYTLS_SERVER_ADDR="$(preferred_direct_server_addr || printf '%s\n' "$DOMAIN")"
  ANYTLS_TLS_SNI="$DOMAIN"
}

resolve_ss2022_server_addr() {
  SS2022_SERVER_ADDR="$(preferred_direct_server_addr || printf '%s\n' "$DOMAIN")"
}

write_anytls_config() {
  write_sing_box_config
}

build_anytls_share_files() {
  local label
  resolve_anytls_server_addr
  label="$NODE_NAME_ANYTLS"

  cat > "$ANYTLS_CLIENT_YAML" <<EOF
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
  - name: "${label}"
    type: anytls
    server: "${ANYTLS_SERVER_ADDR}"
    port: ${ANYTLS_PORT}
    password: "${ANYTLS_PASSWORD}"
    client-fingerprint: chrome
    udp: true
    sni: "${ANYTLS_TLS_SNI}"
    alpn:
      - h2
      - http/1.1
    skip-cert-verify: false

proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - "${label}"
      - DIRECT

rules:
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
EOF

  chmod 600 "$ANYTLS_CLIENT_YAML"

  cat > "$ANYTLS_SHARE_TXT" <<EOF
domain: $DOMAIN
serverAddress: ${ANYTLS_SERVER_ADDR}
serverPort: ${ANYTLS_PORT}
sni: ${ANYTLS_TLS_SNI}
password: ${ANYTLS_PASSWORD}
client: mihomo / Clash Meta compatible
uri: $(anytls_uri)
note: 需要放行 TCP ${ANYTLS_PORT}，域名应直连服务器 IP（Cloudflare DNS-only/灰云），不能走橙云代理。

=== AnyTLS mihomo Client YAML ===
$ANYTLS_CLIENT_YAML
EOF

  anytls_uri > "$ANYTLS_SUB_RAW_TXT"
  printf '\n' >> "$ANYTLS_SUB_RAW_TXT"
  base64 -w 0 < "$ANYTLS_SUB_RAW_TXT" > "$ANYTLS_SUB_B64_TXT"

  if command -v qrencode >/dev/null 2>&1; then
    qrencode -o "$ANYTLS_QR_PNG" -t PNG -s 8 -m 2 < "$ANYTLS_SUB_RAW_TXT" >/dev/null 2>&1 || true
  fi
}

install_anytls_core() {
  if ! cert_matches_domain || ! cert_is_currently_valid; then
    red "当前域名证书不可用，请先执行菜单 2 修复证书。"
    return 1
  fi

  install_sing_box
  resolve_anytls_server_addr
  pick_anytls_port
  generate_anytls_password
  ANYTLS_ENABLED="1"
  write_anytls_config
  build_anytls_share_files
  return 0
}

write_ss2022_config() {
  write_sing_box_config
}

build_ss2022_share_files() {
  local label
  resolve_ss2022_server_addr
  label="$NODE_NAME_SS2022"

  cat > "$SS2022_CLIENT_YAML" <<EOF
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
ipv6: true

dns:
  enable: true
  ipv6: true
  enhanced-mode: fake-ip
  nameserver:
    - https://1.1.1.1/dns-query
    - https://8.8.8.8/dns-query

proxies:
  - name: "${label}"
    type: ss
    server: "${SS2022_SERVER_ADDR}"
    port: ${SS2022_PORT}
    cipher: "${SS2022_CIPHER}"
    password: "${SS2022_PASSWORD}"
    udp: true
    tfo: true
    ip-version: ipv4-prefer

proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - "${label}"
      - DIRECT

rules:
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
EOF

  chmod 600 "$SS2022_CLIENT_YAML"

  cat > "$SS2022_SHARE_TXT" <<EOF
domain: $DOMAIN
serverAddress: ${SS2022_SERVER_ADDR}
serverPort: ${SS2022_PORT}
cipher: ${SS2022_CIPHER}
password: ${SS2022_PASSWORD}
client: mihomo / Clash Meta compatible
uri: $(ss2022_uri)
note: 需要放行 TCP/UDP ${SS2022_PORT}，域名应直连服务器 IP（Cloudflare DNS-only/灰云），不能走橙云代理。

=== Shadowsocks-2022 URI ===
$(ss2022_uri)

=== Shadowsocks-2022 mihomo Client YAML ===
$SS2022_CLIENT_YAML
EOF

  ss2022_uri > "$SS2022_SUB_RAW_TXT"
  printf '\n' >> "$SS2022_SUB_RAW_TXT"
  base64 -w 0 < "$SS2022_SUB_RAW_TXT" > "$SS2022_SUB_B64_TXT"

  if command -v qrencode >/dev/null 2>&1; then
    qrencode -o "$SS2022_QR_PNG" -t PNG -s 8 -m 2 < "$SS2022_SUB_RAW_TXT" >/dev/null 2>&1 || true
  fi
}

install_ss2022_core() {
  install_sing_box
  resolve_ss2022_server_addr
  pick_ss2022_port
  generate_ss2022_password
  SS2022_ENABLED="1"
  write_ss2022_config
  build_ss2022_share_files
  return 0
}

write_hysteria2_config() {
  write_sing_box_config
}

build_hysteria2_share_files() {
  local e_auth e_label e_obfs_pass e_sni nohop_uri uri pin_sha256 pubkey_pin_sha256
  resolve_hy2_server_addr
  pin_sha256="$(calc_cert_pin_sha256)"
  pubkey_pin_sha256="$(calc_cert_public_key_pin_sha256)"
  e_auth="$(urlenc "$HY2_PASSWORD")"
  e_sni="$(urlenc "$HY2_TLS_SNI")"
  e_label="$(urlenc "$NODE_NAME_HY2")"
  uri="hysteria2://${e_auth}@${HY2_SERVER_ADDR}:${HY2_PORT},${HY2_PORT_RANGE}/?insecure=1&sni=${e_sni}&alpn=h3"
  nohop_uri="hysteria2://${e_auth}@${HY2_SERVER_ADDR}:${HY2_PORT}/?insecure=1&sni=${e_sni}&alpn=h3"
  if [[ "${HY2_OBFS_ENABLED:-0}" == "1" ]]; then
    e_obfs_pass="$(urlenc "$HY2_OBFS_PASSWORD")"
    uri="${uri}&obfs=salamander&obfs-password=${e_obfs_pass}"
    nohop_uri="${nohop_uri}&obfs=salamander&obfs-password=${e_obfs_pass}"
  fi
  uri="${uri}#${e_label}"
  nohop_uri="${nohop_uri}#${e_label}"

  cat > "$HY2_CLIENT_YAML" <<EOF
server: ${HY2_SERVER_ADDR}:${HY2_PORT},${HY2_PORT_RANGE}
auth: ${HY2_PASSWORD}
bandwidth:
  up: ${HY2_CLIENT_UP_MBPS} mbps
  down: ${HY2_CLIENT_DOWN_MBPS} mbps
tls:
  sni: ${HY2_TLS_SNI}
  insecure: true
quic:
  initStreamReceiveWindow: 16777216
  maxStreamReceiveWindow: 16777216
  initConnReceiveWindow: 33554432
  maxConnReceiveWindow: 33554432
fastOpen: true
EOF

  if [[ "${HY2_OBFS_ENABLED:-0}" == "1" ]]; then
    cat >> "$HY2_CLIENT_YAML" <<EOF
obfs:
  type: salamander
  salamander:
    password: ${HY2_OBFS_PASSWORD}
EOF
  fi

  cat >> "$HY2_CLIENT_YAML" <<EOF
socks5:
  listen: 127.0.0.1:1080
transport:
  udp:
    hopInterval: 30s
EOF

  cat > "$HY2_CLIENT_OFFICIAL_YAML" <<EOF
server: ${HY2_SERVER_ADDR}:${HY2_PORT},${HY2_PORT_RANGE}
auth: ${HY2_PASSWORD}
bandwidth:
  up: ${HY2_CLIENT_UP_MBPS} mbps
  down: ${HY2_CLIENT_DOWN_MBPS} mbps
tls:
  sni: ${HY2_TLS_SNI}
  insecure: true
  # pinSHA256: ${pin_sha256}
quic:
  initStreamReceiveWindow: 16777216
  maxStreamReceiveWindow: 16777216
  initConnReceiveWindow: 33554432
  maxConnReceiveWindow: 33554432
fastOpen: true
socks5:
  listen: 127.0.0.1:1080
transport:
  udp:
    hopInterval: 30s
EOF

  if [[ "${HY2_OBFS_ENABLED:-0}" == "1" ]]; then
    cat >> "$HY2_CLIENT_OFFICIAL_YAML" <<EOF
obfs:
  type: salamander
  salamander:
    password: ${HY2_OBFS_PASSWORD}
EOF
  fi

  cat > "$HY2_CLIENT_SINGBOX_JSON" <<EOF
{
  "outbounds": [
    {
      "type": "hysteria2",
      "tag": "hy2-out",
      "server": "${HY2_SERVER_ADDR}",
      "server_port": ${HY2_PORT},
      "server_ports": [
        "${HY2_PORT_RANGE}"
      ],
      "password": "${HY2_PASSWORD}",
      "up_mbps": ${HY2_CLIENT_UP_MBPS},
      "down_mbps": ${HY2_CLIENT_DOWN_MBPS},
      "tls": {
        "enabled": true,
        "server_name": "${HY2_TLS_SNI}",
        "insecure": true,
        "alpn": [
          "h3"
        ]
      }$( if [[ "${HY2_OBFS_ENABLED:-0}" == "1" ]]; then cat <<JSON
,
      "obfs": {
        "type": "salamander",
        "password": "${HY2_OBFS_PASSWORD}"
      }
JSON
fi )
    }
  ]
}
EOF

  cat > "$HY2_SHARE_TXT" <<EOF
domain: $DOMAIN
serverAddress: ${HY2_SERVER_ADDR}
serverPort: ${HY2_PORT}
serverPorts: ${HY2_PORT_RANGE}
sni: ${HY2_TLS_SNI}
auth: $HY2_PASSWORD
obfs: $( [[ "${HY2_OBFS_ENABLED:-0}" == "1" ]] && echo "salamander" || echo "off" )
obfsPassword: $( [[ "${HY2_OBFS_ENABLED:-0}" == "1" ]] && echo "$HY2_OBFS_PASSWORD" || echo "-" )
masqueradeUrl: ${HY2_MASQUERADE_URL}
tlsInsecure: true
clientBandwidth: up ${HY2_CLIENT_UP_MBPS} Mbps / down ${HY2_CLIENT_DOWN_MBPS} Mbps
serverBandwidth: unset
firewallRequired: allow UDP ${HY2_PORT}
firewallPortHoppingOptional: allow UDP ${HY2_PORT_RANGE}
pinSHA256(optional): ${pin_sha256}

=== Hysteria2 URI ===
$nohop_uri

=== Hysteria2 URI (Port Hopping / Advanced) ===
$uri

=== Client YAML ===
$HY2_CLIENT_YAML

=== Official Client YAML ===
$HY2_CLIENT_OFFICIAL_YAML

=== sing-box Client JSON ===
$HY2_CLIENT_SINGBOX_JSON
EOF

  printf '%s\n' "$nohop_uri" > "$HY2_SUB_RAW_TXT"
  printf '%s\n' "$nohop_uri" > "$HY2_SUB_NOHOP_RAW_TXT"
  printf '%s\n' "$nohop_uri" | base64 -w 0 > "$HY2_SUB_B64_TXT"

  if command -v qrencode >/dev/null 2>&1; then
    printf '%s' "$nohop_uri" | qrencode -o "$HY2_QR_PNG" -t PNG -s 8 -m 2 >/dev/null 2>&1 || true
  fi
}

install_cloudflared_binary() {
  local tag asset tmp_dir url release_json

  if [[ -x "$CLOUDFLARED_BIN" ]]; then
    "$CLOUDFLARED_BIN" version | head -n 1 || true
    return 0
  fi

  release_json="$(github_api_json "$CLOUDFLARED_GITHUB_API" "cloudflared release API")" || return 1
  tag="$(printf '%s' "$release_json" | jq -r '.tag_name // empty')"
  if [[ -z "$tag" || "$tag" == "null" ]]; then
    red "无法获取 cloudflared 最新版本"
    return 1
  fi

  asset="$(detect_cloudflared_asset "$release_json")"
  tmp_dir="$(mktemp -d)"
  url="https://github.com/cloudflare/cloudflared/releases/download/${tag}/${asset}"

  yellow "正在下载 cloudflared ${tag}: ${asset}"
  curl_fsSL "$url" -o "${tmp_dir}/cloudflared"
  install -m 0755 "${tmp_dir}/cloudflared" "$CLOUDFLARED_BIN"
  rm -rf "$tmp_dir"

  "$CLOUDFLARED_BIN" version | head -n 1 || true
}

generate_argo_identity() {
  ARGO_UUID="$(cat /proc/sys/kernel/random/uuid)"
  ARGO_WS_PATH="/argo-$(openssl rand -hex 8)"
  if [[ -z "${ARGO_LOCAL_PORT:-}" ]]; then
    if argo_is_named_tunnel; then
      read -r -p "请输入本地监听端口 [默认: $ARGO_NAMED_DEFAULT_LOCAL_PORT]: " custom_port
  custom_port="${custom_port:-$ARGO_NAMED_DEFAULT_LOCAL_PORT}"
  pick_argo_local_port "$custom_port"
    else
      pick_argo_local_port
    fi
  fi
  if argo_is_named_tunnel; then
    ARGO_DOMAIN="$ARGO_FIXED_DOMAIN"
  else
    ARGO_DOMAIN=""
  fi
  ARGO_PROTOCOL="http2"
  ARGO_EDGE_IP_VERSION="${ARGO_EDGE_IP_VERSION:-auto}"
}

prompt_argo_tunnel_config() {
  local choice token

  normalize_argo_tunnel_state

  echo
  echo "Argo 隧道模式："
  echo "1) Cloudflare Named Tunnel（固定域名，推荐）"
  echo "2) Quick Tunnel（免账号，trycloudflare.com 重启可能变化）"
  read -r -p "请选择 [默认: 1]: " choice
  choice="${choice:-1}"

  case "$choice" in
    2)
      ARGO_TUNNEL_MODE="quick"
      ARGO_FIXED_DOMAIN=""
      ARGO_TUNNEL_TOKEN=""
      ARGO_DOMAIN=""
      return 0
      ;;
    1|"")
      ARGO_TUNNEL_MODE="named"
      ;;
    *)
      yellow "无效选项，按固定 Named Tunnel 处理。"
      ARGO_TUNNEL_MODE="named"
      ;;
  esac

  read -r -p "请输入固定隧道域名（如 tunnel.example.com）: " ARGO_FIXED_DOMAIN
  ARGO_FIXED_DOMAIN="$(normalize_argo_host "${ARGO_FIXED_DOMAIN:-}")"
  if [[ -z "$ARGO_FIXED_DOMAIN" ]]; then
    red "固定隧道域名不能为空。"
    return 1
  fi
  ARGO_DOMAIN="$ARGO_FIXED_DOMAIN"

  if [[ -z "${ARGO_LOCAL_PORT:-}" ]]; then
    pick_argo_local_port "$ARGO_NAMED_DEFAULT_LOCAL_PORT"
  fi

  echo
  yellow "固定 Argo 隧道域名：${ARGO_FIXED_DOMAIN}"
  yellow "请在 Cloudflare Zero Trust 的 Tunnel 里添加 Public Hostname：${ARGO_FIXED_DOMAIN}"
  yellow "Public Hostname 的 Service 填：http://localhost:${ARGO_LOCAL_PORT}"

  if [[ -n "${ARGO_TUNNEL_TOKEN:-}" ]]; then
    read -r -s -p "Cloudflare Tunnel Token [已保存，回车沿用]: " token
    echo
    token="${token:-$ARGO_TUNNEL_TOKEN}"
  else
    read -r -s -p "Cloudflare Tunnel Token: " token
    echo
  fi
  if [[ -z "$token" ]]; then
    red "固定 Named Tunnel 必须填写 Cloudflare Tunnel Token。"
    return 1
  fi

  ARGO_TUNNEL_TOKEN="$token"
}

normalize_argo_tuning() {
  case "${ARGO_PROTOCOL:-http2}" in
    quic|http2|auto) ;;
    *) ARGO_PROTOCOL="http2" ;;
  esac

  case "${ARGO_EDGE_IP_VERSION:-auto}" in
    4|6|auto) ;;
    *) ARGO_EDGE_IP_VERSION="auto" ;;
  esac
}

wait_tcp_endpoint() {
  local attempts="${3:-45}" host="${1:-}" i port="${2:-}"

  [[ -n "$host" && -n "$port" ]] || return 1

  for i in $(seq 1 "$attempts"); do
    if timeout 1 bash -c ':</dev/tcp/"$1"/"$2"' _ "$host" "$port" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  return 1
}

write_argo_service() {
  local description edge_arg="" exec_start
  normalize_argo_tuning
  normalize_argo_tunnel_state
  mkdir -p "$STATE_DIR"
  rm -f "${STATE_DIR}/argo.env"
  install_self_script || true

  if [[ "${ARGO_EDGE_IP_VERSION:-auto}" != "auto" ]]; then
    edge_arg=" --edge-ip-version ${ARGO_EDGE_IP_VERSION}"
  fi

  if argo_is_named_tunnel; then
    description="${APP_NAME} Cloudflare Named Tunnel"
    exec_start="${CLOUDFLARED_BIN} tunnel --no-autoupdate --protocol ${ARGO_PROTOCOL:-http2}${edge_arg} --logfile ${ARGO_BOOT_LOG} --loglevel info run --token ${ARGO_TUNNEL_TOKEN}"
  else
    description="${APP_NAME} Cloudflare Quick Tunnel"
    exec_start="${CLOUDFLARED_BIN} tunnel --no-autoupdate --protocol ${ARGO_PROTOCOL:-http2}${edge_arg} --logfile ${ARGO_BOOT_LOG} --loglevel info --url http://127.0.0.1:${ARGO_LOCAL_PORT}"
  fi

  cat > "/etc/systemd/system/${ARGO_SERVICE}" <<EOF
[Unit]
Description=${description}
After=network-online.target ${SING_BOX_SERVICE}
Wants=network-online.target ${SING_BOX_SERVICE}

[Service]
Type=simple
TimeoutStartSec=180s
ExecStartPre=/bin/mkdir -p ${STATE_DIR}
ExecStartPre=/bin/rm -f ${ARGO_BOOT_LOG}
ExecStartPre=-/bin/bash ${INSTALL_SCRIPT} --wait-tcp 127.0.0.1 ${ARGO_LOCAL_PORT} 45
ExecStart=${exec_start}
ExecStartPost=-/bin/systemctl --no-block start ${ARGO_REFRESH_SERVICE}
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

  write_argo_refresh_units
}

write_argo_refresh_units() {
  install_self_script || true

  cat > "/etc/systemd/system/${ARGO_REFRESH_SERVICE}" <<EOF
[Unit]
Description=${APP_NAME} refresh Argo domain and subscription
After=network-online.target ${SING_BOX_SERVICE} ${ARGO_SERVICE}
Wants=network-online.target ${ARGO_SERVICE}

[Service]
Type=oneshot
TimeoutStartSec=240s
ExecStart=/bin/bash ${INSTALL_SCRIPT} --refresh-argo-subscription systemd

[Install]
WantedBy=multi-user.target
EOF

  cat > "/etc/systemd/system/${ARGO_REFRESH_TIMER}" <<EOF
[Unit]
Description=${APP_NAME} periodic Argo subscription refresh

[Timer]
OnBootSec=5s
OnUnitActiveSec=10min
AccuracySec=15s
Persistent=true
Unit=${ARGO_REFRESH_SERVICE}

[Install]
WantedBy=timers.target
EOF

  cat > "/etc/systemd/system/${ARGO_REFRESH_PATH}" <<EOF
[Unit]
Description=${APP_NAME} refresh Argo subscription when cloudflared log changes

[Path]
PathExists=${ARGO_BOOT_LOG}
PathModified=${ARGO_BOOT_LOG}
Unit=${ARGO_REFRESH_SERVICE}

[Install]
WantedBy=multi-user.target
EOF
}

enable_argo_refresh_automation() {
  systemctl enable "$ARGO_REFRESH_SERVICE" "$ARGO_REFRESH_TIMER" "$ARGO_REFRESH_PATH" >/dev/null 2>&1 || true
  systemctl restart "$ARGO_REFRESH_TIMER" "$ARGO_REFRESH_PATH" >/dev/null 2>&1 || true
}

argo_service_needs_rewrite() {
  local service_file="/etc/systemd/system/${ARGO_SERVICE}"

  normalize_argo_tunnel_state
  [[ -f "$service_file" ]] || return 0
  systemctl is-active --quiet "$ARGO_SERVICE" || return 0
  if argo_is_named_tunnel; then
    grep -Fq -- " run --token " "$service_file" || return 0
    grep -Fq -- "--url http://127.0.0.1:" "$service_file" && return 0
  else
    grep -Fq -- "--url http://127.0.0.1:${ARGO_LOCAL_PORT}" "$service_file" || return 0
  fi
  grep -Fq -- "--protocol ${ARGO_PROTOCOL:-http2}" "$service_file" || return 0
  grep -Fq -- "--logfile ${ARGO_BOOT_LOG}" "$service_file" || return 0
  grep -Fq -- "--wait-tcp 127.0.0.1 ${ARGO_LOCAL_PORT} 45" "$service_file" || return 0
  grep -Fq -- "systemctl --no-block start ${ARGO_REFRESH_SERVICE}" "$service_file" || return 0
  [[ -f "/etc/systemd/system/${ARGO_REFRESH_SERVICE}" ]] || return 0
  [[ -f "/etc/systemd/system/${ARGO_REFRESH_TIMER}" ]] || return 0
  [[ -f "/etc/systemd/system/${ARGO_REFRESH_PATH}" ]] || return 0
  if [[ "${ARGO_EDGE_IP_VERSION:-auto}" != "auto" ]]; then
    grep -Fq -- "--edge-ip-version ${ARGO_EDGE_IP_VERSION}" "$service_file" || return 0
  fi
  return 1
}

ensure_argo_quick_service() {
  if [[ "${ARGO_SKIP_SERVICE_ENSURE:-0}" == "1" ]]; then
    return 0
  fi

  if [[ "$(systemctl is-active "$ARGO_SERVICE" 2>/dev/null || true)" == "activating" ]]; then
    return 0
  fi

  if argo_service_needs_rewrite; then
    yellow "检测到 Argo 服务配置需要刷新，正在重写 systemd 单元。"
    write_argo_service
    systemctl daemon-reload
    systemctl enable "$ARGO_SERVICE" >/dev/null 2>&1 || true
    enable_argo_refresh_automation
    systemctl restart "$ARGO_SERVICE"
    ARGO_DOMAIN=""
    refresh_argo_domain || true
  fi
}

extract_argo_domain_from_text() {
  grep -Eo 'https?://[A-Za-z0-9-]+\.trycloudflare\.com|[A-Za-z0-9-]+\.trycloudflare\.com' \
    | sed -E 's#^https?://##' \
    | tail -n 1
}

read_argo_domain_from_journal() {
  local found
  found="$(journalctl "$@" --no-pager 2>/dev/null | extract_argo_domain_from_text || true)"
  [[ -n "$found" ]] || return 1
  printf '%s\n' "$found"
}

read_argo_domain_from_logfile() {
  local found

  [[ -f "$ARGO_BOOT_LOG" ]] || return 1
  found="$(extract_argo_domain_from_text < "$ARGO_BOOT_LOG" || true)"
  [[ -n "$found" ]] || return 1
  printf '%s\n' "$found"
}

read_argo_domain_from_existing_files() {
  local found

  found="$(read_argo_domain_from_logfile || true)"
  if [[ -n "$found" ]]; then
    printf '%s\n' "$found"
    return 0
  fi

  if [[ -f "$ARGO_SUB_RAW_TXT" ]]; then
    found="$(extract_argo_domain_from_text < "$ARGO_SUB_RAW_TXT" || true)"
    if [[ -n "$found" ]]; then
      printf '%s\n' "$found"
      return 0
    fi
  fi

  if [[ -f "$ARGO_SHARE_TXT" ]]; then
    found="$(extract_argo_domain_from_text < "$ARGO_SHARE_TXT" || true)"
    if [[ -n "$found" ]]; then
      printf '%s\n' "$found"
      return 0
    fi
  fi

  return 1
}

resolve_argo_domain() {
  local allow_existing_fallback="${1:-1}" found max_attempts="${2:-}"

  if [[ -z "$max_attempts" ]]; then
    if [[ "$allow_existing_fallback" == "1" ]]; then
      max_attempts="2"
    else
      max_attempts="20"
    fi
  fi

  refresh_argo_domain "$max_attempts" || true
  if [[ -z "${ARGO_DOMAIN:-}" && "$allow_existing_fallback" == "1" ]]; then
    found="$(read_argo_domain_from_existing_files || true)"
    if [[ -n "$found" ]]; then
      ARGO_DOMAIN="$found"
    fi
  fi

  [[ -n "${ARGO_DOMAIN:-}" ]]
}

refresh_argo_domain() {
  local active_since found i invocation_id max_attempts="${1:-20}"

  if argo_is_named_tunnel; then
    ARGO_DOMAIN="$ARGO_FIXED_DOMAIN"
    return 0
  fi

  invocation_id="$(systemctl show -p InvocationID --value "$ARGO_SERVICE" 2>/dev/null || true)"
  active_since="$(systemctl show -p ActiveEnterTimestamp --value "$ARGO_SERVICE" 2>/dev/null || true)"

  for i in $(seq 1 "$max_attempts"); do
    found=""

    found="$(read_argo_domain_from_logfile || true)"

    if [[ -n "$invocation_id" && "$invocation_id" != "n/a" ]]; then
      if [[ -z "$found" ]]; then
        found="$(read_argo_domain_from_journal -u "$ARGO_SERVICE" "_SYSTEMD_INVOCATION_ID=${invocation_id}" || true)"
      fi
    fi

    if [[ -z "$found" && -n "$active_since" && "$active_since" != "n/a" ]]; then
      found="$(read_argo_domain_from_journal -u "$ARGO_SERVICE" --since "$active_since" || true)"
    fi

    if [[ -n "$found" ]]; then
      ARGO_DOMAIN="$found"
      return 0
    fi

    sleep 2
  done

  ARGO_DOMAIN=""
  return 1
}

measure_argo_latency_ms() {
  local samples="${1:-2}" i result status seconds ms best=""

  if [[ -z "${ARGO_DOMAIN:-}" ]]; then
    return 1
  fi

  for i in $(seq 1 "$samples"); do
    result="$(curl -k -o /dev/null -sS --connect-timeout 3 --max-time 8 \
      -w '%{http_code} %{time_total}' "https://${ARGO_DOMAIN}/" 2>/dev/null || true)"
    read -r status seconds <<< "$result"
    if [[ "$status" =~ ^[0-9]{3}$ && "$status" != "000" && "$seconds" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
      ms="$(awk -v t="$seconds" 'BEGIN { printf "%d", (t * 1000) + 0.5 }')"
      if [[ -z "$best" || "$ms" -lt "$best" ]]; then
        best="$ms"
      fi
    fi
    sleep 1
  done

  [[ -n "$best" ]] || return 1
  printf '%s\n' "$best"
}

validate_argo_https_reachable() {
  local status

  if [[ -z "${ARGO_DOMAIN:-}" ]]; then
    return 1
  fi

  status="$(curl -k -sS --connect-timeout 3 --max-time 8 \
    -o /dev/null -w '%{http_code}' "https://${ARGO_DOMAIN}/" 2>/dev/null || true)"

  [[ "$status" != "000" && -n "$status" ]]
}

wait_argo_https_reachable() {
  local attempts="${1:-8}" i

  for i in $(seq 1 "$attempts"); do
    if validate_argo_https_reachable; then
      return 0
    fi
    sleep 2
  done

  return 1
}

restart_argo_with_tuning() {
  local protocol="$1" edge_ip_version="$2" domain_attempts="${3:-20}"

  ARGO_PROTOCOL="$protocol"
  ARGO_EDGE_IP_VERSION="$edge_ip_version"
  normalize_argo_tuning
  ARGO_DOMAIN=""

  write_argo_service
  systemctl daemon-reload
  enable_argo_refresh_automation
  systemctl restart "$ARGO_SERVICE"
  refresh_argo_domain "$domain_attempts"
}

build_argo_share_files() {
  local allow_existing_fallback="${1:-1}" mode_note tunnel_label uri

  resolve_argo_domain "$allow_existing_fallback" || true

  if [[ -z "${ARGO_DOMAIN:-}" ]]; then
    if argo_is_named_tunnel; then
      yellow "固定 Argo 域名为空，请检查安装状态。"
    else
      yellow "暂未从 cloudflared 日志中获取到 Argo 域名。"
    fi
    if [[ "$allow_existing_fallback" != "1" ]]; then
      rm -f "$ARGO_SHARE_TXT" "$ARGO_SUB_RAW_TXT" "$ARGO_SUB_B64_TXT" "$ARGO_QR_PNG"
    fi
    return 1
  fi

  uri="$(argo_uri)"
  if argo_is_named_tunnel; then
    tunnel_label="Cloudflare Named Tunnel"
    mode_note="客户端连接地址固定为 ${ARGO_EDGE_SERVER}:443；SNI / Host 使用固定域名 ${ARGO_DOMAIN}。"
  else
    tunnel_label="Cloudflare Quick Tunnel"
    mode_note="客户端连接地址固定为 ${ARGO_EDGE_SERVER}:443；SNI / Host 使用当前 Quick Tunnel 域名。"
  fi

  cat > "$ARGO_SHARE_TXT" <<EOF
domain: $DOMAIN
tunnelMode: ${ARGO_TUNNEL_MODE:-quick}
cloudflareTunnel: ${tunnel_label}
tunnelHost: ${ARGO_DOMAIN}
edgeServer: ${ARGO_EDGE_SERVER}
localPort: ${ARGO_LOCAL_PORT}
protocol: ${ARGO_PROTOCOL:-http2}
edgeIpVersion: ${ARGO_EDGE_IP_VERSION:-auto}
uuid: ${ARGO_UUID}
wsPath: ${ARGO_WS_PATH}
client: VLESS over WebSocket + TLS
note: ${mode_note}

=== Argo VLESS-WS URI ===
$uri
EOF

  printf '%s\n' "$uri" > "$ARGO_SUB_RAW_TXT"
  base64 -w 0 < "$ARGO_SUB_RAW_TXT" > "$ARGO_SUB_B64_TXT"

  if command -v qrencode >/dev/null 2>&1; then
    printf '%s' "$uri" | qrencode -o "$ARGO_QR_PNG" -t PNG -s 8 -m 2 >/dev/null 2>&1 || true
  fi
}

install_argo_core() {
  select_argo_edge_server
  install_sing_box
  install_cloudflared_binary
  normalize_argo_tunnel_state
  if [[ "${ARGO_TUNNEL_MODE:-quick}" == "named" && -z "${ARGO_TUNNEL_TOKEN:-}" ]]; then
    red "固定 Named Tunnel 缺少 Cloudflare Tunnel Token。"
    return 1
  fi
  generate_argo_identity
  ARGO_ENABLED="1"
  write_sing_box_config
  write_argo_service
  systemctl daemon-reload
  systemctl enable "$ARGO_SERVICE" >/dev/null 2>&1 || true
  enable_argo_refresh_automation
  systemctl restart "$ARGO_SERVICE"

  if ! refresh_argo_domain; then
    if argo_is_named_tunnel; then
      yellow "cloudflared 已启动，但固定域名状态未写入；请检查 Tunnel Token。"
    else
      yellow "cloudflared 已启动，但暂未抓到 trycloudflare.com 域名；稍后可在节点信息里刷新查看。"
    fi
  fi

  build_argo_share_files "0" || true
}

apply_argo_tuning() {
  local protocol="$1" edge_ip_version="$2"

  require_root

  if ! load_state || ! has_argo_install; then
    red "未检测到 Argo 安装记录"
    return
  fi

  ARGO_PROTOCOL="$protocol"
  ARGO_EDGE_IP_VERSION="$edge_ip_version"
  normalize_argo_tuning
  ARGO_DOMAIN=""

  yellow "将切换 Argo: protocol=${ARGO_PROTOCOL}, edge-ip-version=${ARGO_EDGE_IP_VERSION}"
  if argo_is_named_tunnel; then
    yellow "固定 Named Tunnel 域名保持为：${ARGO_FIXED_DOMAIN}"
  else
    yellow "Quick Tunnel 重启后会换 trycloudflare.com 域名，客户端需要重新导入新节点。"
  fi

  if ! restart_argo_with_tuning "$protocol" "$edge_ip_version"; then
    yellow "cloudflared 已重启，但暂未抓到 trycloudflare.com 域名；稍后可再次查看节点信息。"
  fi
  build_argo_share_files "0" || true
  save_state
  refresh_subscription_service

  green "Argo 优选参数已切换"
  echo
  show_argo_node_info
}

auto_tune_argo_core() {
  local refresh_sub="${1:-0}" best_edge="" best_ms="" best_protocol="" combo edge ip_label ms old_edge old_protocol protocol
  local combos=(
    "http2 auto"
    "http2 4"
    "http2 6"
  )

  if ! has_argo_install; then
    red "未检测到 Argo 安装记录"
    return 1
  fi

  normalize_argo_tuning
  old_protocol="$ARGO_PROTOCOL"
  old_edge="$ARGO_EDGE_IP_VERSION"

  yellow "开始自动优选 Argo。"
  if argo_is_named_tunnel; then
    yellow "脚本会逐个重启 Cloudflare Named Tunnel 测速，完成后自动保留最低延迟组合。"
  else
    yellow "脚本会逐个重启 Quick Tunnel 测速，完成后自动保留最低延迟组合。"
  fi
  yellow "测速只代表 VPS 到 Cloudflare Tunnel 这一段；客户端本地线路仍可能有差异。"
  echo

  for combo in "${combos[@]}"; do
    read -r protocol edge <<< "$combo"
    case "$edge" in
      4) ip_label="IPv4" ;;
      6) ip_label="IPv6" ;;
      *) ip_label="auto" ;;
    esac

    yellow "测试 ${protocol} + ${ip_label} ..."
    if ! restart_argo_with_tuning "$protocol" "$edge" 10; then
      yellow "  跳过：未获取到 trycloudflare.com 域名。"
      continue
    fi

    if ! wait_argo_https_reachable 6; then
      yellow "  跳过：HTTPS 暂未可达。"
      continue
    fi

    ms="$(measure_argo_latency_ms 2 || true)"
    if [[ -z "$ms" ]]; then
      yellow "  跳过：测速失败。"
      continue
    fi

    echo "  测得延迟：${ms} ms"
    if [[ -z "$best_ms" || "$ms" -lt "$best_ms" ]]; then
      best_ms="$ms"
      best_protocol="$protocol"
      best_edge="$edge"
    fi
  done

  echo
  if [[ -z "$best_ms" ]]; then
    red "自动优选失败：所有组合都未测出有效结果，恢复原参数。"
    restart_argo_with_tuning "$old_protocol" "$old_edge" 10 || true
    build_argo_share_files "0" || true
    save_state
    if [[ "$refresh_sub" == "1" ]]; then
      refresh_subscription_service
    fi
    return 1
  fi

  case "$best_edge" in
    4) ip_label="IPv4" ;;
    6) ip_label="IPv6" ;;
    *) ip_label="auto" ;;
  esac

  yellow "最佳组合：${best_protocol} + ${ip_label}，本轮最低 ${best_ms} ms。"
  if ! restart_argo_with_tuning "$best_protocol" "$best_edge"; then
    if argo_is_named_tunnel; then
      yellow "最佳组合已写入，但 cloudflared 重启可能尚未稳定；稍后可再次刷新节点信息。"
    else
      yellow "最佳组合已写入，但暂未抓到新域名；稍后可再次刷新节点信息。"
    fi
  fi

  build_argo_share_files "0" || true
  save_state
  if [[ "$refresh_sub" == "1" ]]; then
    refresh_subscription_service
  fi

  green "Argo 自动优选完成"
  return 0
}

argo_subscription_needs_refresh() {
  if [[ -z "${ARGO_DOMAIN:-}" ]]; then
    return 1
  fi

  if [[ ! -s "$ARGO_SUB_RAW_TXT" ]] || ! grep -Fq "$ARGO_DOMAIN" "$ARGO_SUB_RAW_TXT"; then
    return 0
  fi

  if [[ ! -s "$COMBO_SUB_RAW_TXT" ]] || ! grep -Fq "$ARGO_DOMAIN" "$COMBO_SUB_RAW_TXT"; then
    return 0
  fi

  if has_subscription_service; then
    if [[ ! -s "$SUB_URI_RAW_TXT" ]] || ! grep -Fq "$ARGO_DOMAIN" "$SUB_URI_RAW_TXT"; then
      return 0
    fi
    if [[ ! -s "$SUB_CLASH_YAML" ]] || ! grep -Fq "$ARGO_DOMAIN" "$SUB_CLASH_YAML"; then
      return 0
    fi
  fi

  return 1
}

clear_stale_argo_share_files() {
  ARGO_DOMAIN=""
  rm -f "$ARGO_SHARE_TXT" "$ARGO_SUB_RAW_TXT" "$ARGO_SUB_B64_TXT" "$ARGO_QR_PNG"
}

refresh_argo_subscription_once() {
  local domain_attempts="45" mode="${1:-manual}" old_domain="" saved_argo_enabled=""

  require_root

  if ! load_state || ! has_argo_install; then
    if [[ "$mode" == "manual" ]]; then
      yellow "未检测到 Argo 安装记录，已跳过刷新。"
    fi
    return 0
  fi

  normalize_argo_tuning
  old_domain="${ARGO_DOMAIN:-}"

  if [[ "$mode" == "manual" ]]; then
    install_self_script || true
    if [[ ! -f "/etc/systemd/system/${ARGO_SERVICE}" ]]; then
      write_argo_service
      systemctl daemon-reload
    fi
    systemctl enable "$ARGO_SERVICE" >/dev/null 2>&1 || true
    enable_argo_refresh_automation
    if ! systemctl is-active --quiet "$ARGO_SERVICE"; then
      systemctl restart "$ARGO_SERVICE" >/dev/null 2>&1 || true
    fi
  fi

  if [[ "$mode" == "request" ]]; then
    domain_attempts="3"
  elif [[ "$mode" == "systemd" || "$mode" == "subscription-prestart" ]]; then
    domain_attempts="60"
  fi

  if ! refresh_argo_domain "$domain_attempts"; then
    if [[ "$mode" == "manual" ]]; then
      yellow "暂未获取到新的 trycloudflare.com 域名，稍后 cloudflared 启动稳定后会再刷新。"
    else
      ARGO_SKIP_SERVICE_ENSURE="1"
      clear_stale_argo_share_files
      save_state
      saved_argo_enabled="${ARGO_ENABLED:-0}"
      ARGO_ENABLED="0"
      build_subscription_payload_files || true
      build_combined_subscription_files || true
      if [[ "$mode" != "subscription-prestart" && "$mode" != "request" ]]; then
        systemctl restart "$SUB_SERVICE" >/dev/null 2>&1 || true
      fi
      ARGO_ENABLED="$saved_argo_enabled"
      ARGO_SKIP_SERVICE_ENSURE="0"
    fi
    return 0
  fi

  if [[ "$mode" != "manual" && "$old_domain" == "$ARGO_DOMAIN" ]] && ! argo_subscription_needs_refresh; then
    return 0
  fi

  ARGO_SKIP_SERVICE_ENSURE="1"
  build_argo_share_files "0" || true
  save_state

  if [[ "$mode" == "subscription-prestart" || "$mode" == "request" ]]; then
    build_subscription_payload_files || true
  else
    refresh_subscription_service || true
  fi
  build_combined_subscription_files || true
  ARGO_SKIP_SERVICE_ENSURE="0"

  if [[ "$mode" == "manual" ]]; then
    if [[ -n "$old_domain" && "$old_domain" != "$ARGO_DOMAIN" ]]; then
      yellow "Argo 临时域名已更新：${old_domain} -> ${ARGO_DOMAIN}"
    fi
    green "Argo 域名和订阅已刷新。"
  fi
}

build_combined_subscription_files() {
  if ! write_uri_subscription_raw "$COMBO_SUB_RAW_TXT"; then
    rm -f "$COMBO_SUB_RAW_TXT" "$COMBO_SUB_B64_TXT"
    return 1
  fi

  base64 -w 0 < "$COMBO_SUB_RAW_TXT" > "$COMBO_SUB_B64_TXT"
  if has_subscription_service; then
    build_subscription_payload_files || true
  fi
}

install_hysteria2_core() {
  if ! cert_matches_domain || ! cert_is_currently_valid; then
    red "当前域名证书不可用，请先执行菜单 2 修复证书。"
    return 1
  fi

  if [[ -n "${HY2_PORT:-}" || -n "${HY2_PORT_RANGE:-}" ]]; then
    clear_hy2_port_hopping_rules
  fi

  install_hysteria2_binary
  resolve_hy2_server_addr
  pick_hy2_port_range
  generate_hy2_password
  HY2_ENABLED="1"
  write_hysteria2_config
  apply_hy2_port_hopping_rules
  build_hysteria2_share_files
  return 0
}

