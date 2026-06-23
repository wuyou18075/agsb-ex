#!/usr/bin/env bash
# =============================================================================
# installer.sh - Install flow, menu, status, uninstall
# =============================================================================

pause() {
  read -r -p "按回车继续..." _
}

prompt_reboot_for_bbrv3() {
  local ans=""

  echo
  yellow "BBRv3 内核已安装，新内核必须重启 VPS 后才会生效。"
  yellow "请确认节点信息已保存；按回车立即重启，输入 n 稍后手动重启。"
  read -r -p "立即重启？[Y/n]: " ans
  if [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]; then
    sync || true
    yellow "正在重启 VPS..."
    if command -v systemctl >/dev/null 2>&1; then
      systemctl reboot || reboot
    else
      reboot
    fi
    exit 0
  fi

  yellow "已取消自动重启。稍后执行 reboot 后，菜单 4 可查看 kernel / tcp_cc。"
}

install_anytls() {
  require_root

  if ! load_state; then
    red "请先完成菜单 1 的主安装，以便复用域名和证书。"
    return
  fi

  yellow "将为当前域名 ${DOMAIN} 安装/重装 AnyTLS（sing-box 服务端核心，随机高位 TCP 端口）"
  backup_existing_files
  arm_auto_rollback
  install_packages
  install_anytls_core
  save_state
  install_subscription_service || refresh_subscription_service
  save_state
  disarm_auto_rollback

  green "AnyTLS 安装完成"
  echo
  show_anytls_node_info
}

show_anytls_node_info() {
  if ! load_state || [[ "${ANYTLS_ENABLED:-0}" != "1" ]]; then
    red "未检测到 AnyTLS 安装记录"
    return
  fi

  if [[ ! -f "$ANYTLS_SHARE_TXT" || ! -f "$ANYTLS_CLIENT_YAML" || ! -f "$ANYTLS_SUB_B64_TXT" ]]; then
    build_anytls_share_files
  fi

  cyan "============== AnyTLS 节点信息 =============="
  echo "[AnyTLS URL / mihomo YAML]"
  if [[ -f "$ANYTLS_SUB_RAW_TXT" ]]; then
    sed -n '1p' "$ANYTLS_SUB_RAW_TXT"
  fi
  cyan "============================================="
}

install_ss2022() {
  require_root

  if ! load_state; then
    red "请先完成菜单 1 的主安装，以便写入域名和订阅服务。"
    return
  fi

  yellow "将为当前域名 ${DOMAIN} 安装/重装 Shadowsocks-2022（sing-box 服务端核心，随机高位 TCP/UDP 端口）"
  backup_existing_files
  arm_auto_rollback
  install_packages
  install_ss2022_core
  save_state
  install_subscription_service || refresh_subscription_service
  save_state
  disarm_auto_rollback

  green "Shadowsocks-2022 安装完成"
  echo
  show_ss2022_node_info
}

show_ss2022_node_info() {
  if ! load_state || [[ "${SS2022_ENABLED:-0}" != "1" ]]; then
    red "未检测到 Shadowsocks-2022 安装记录"
    return
  fi

  if [[ ! -f "$SS2022_SHARE_TXT" || ! -f "$SS2022_CLIENT_YAML" || ! -f "$SS2022_SUB_B64_TXT" ]]; then
    build_ss2022_share_files
  fi

  cyan "============== Shadowsocks-2022 节点信息 =============="
  echo "[Shadowsocks-2022 URL]"
  if [[ -f "$SS2022_SUB_RAW_TXT" ]]; then
    sed -n '1p' "$SS2022_SUB_RAW_TXT"
  fi
  cyan "======================================================="
}

install_argo() {
  require_root

  if ! load_state; then
    red "请先完成菜单 1 的主安装，以便写入域名、证书和订阅服务。"
    return
  fi

  prompt_argo_tunnel_config || return
  if argo_is_named_tunnel; then
    yellow "将安装 / 重装 Argo（Cloudflare Named Tunnel + VLESS-WS）"
    yellow "固定域名：${ARGO_FIXED_DOMAIN}；Cloudflare Service: http://localhost:${ARGO_LOCAL_PORT}"
  else
    yellow "将安装 / 重装 Argo（Cloudflare Quick Tunnel + VLESS-WS）"
    yellow "订阅连接地址固定为 ${ARGO_EDGE_SERVER}:443；SNI / Host 使用当前 trycloudflare.com。"
  fi
  backup_existing_files
  arm_auto_rollback
  install_packages
  install_argo_core
  save_state
  install_subscription_service || refresh_subscription_service
  save_state
  build_combined_subscription_files || true
  disarm_auto_rollback

  green "Argo 隧道节点安装完成"
  echo
  show_argo_node_info
}

show_argo_node_info() {
  if ! load_state || [[ "${ARGO_ENABLED:-0}" != "1" ]]; then
    red "未检测到 Argo 安装记录"
    return
  fi

  ensure_argo_quick_service
  build_argo_share_files "0" || true
  save_state

  cyan "============== Argo 节点信息 =============="
  echo "[Argo / Cloudflare Tunnel URL]"
  if [[ -f "$ARGO_SUB_RAW_TXT" ]]; then
    sed '/^[[:space:]]*$/d' "$ARGO_SUB_RAW_TXT"
  else
    yellow "暂未获取到 trycloudflare.com 域名，请查看 cloudflared 日志。"
  fi
  cyan "==========================================="
}

auto_tune_argo() {
  require_root

  if ! load_state || ! has_argo_install; then
    red "未检测到 Argo 安装记录"
    return
  fi

  auto_tune_argo_core "1" || true
  echo
  show_argo_node_info
}

refresh_argo_node() {
  require_root

  if ! load_state || ! has_argo_install; then
    red "未检测到 Argo 安装记录"
    return
  fi

  if argo_is_named_tunnel; then
    yellow "正在重启 Cloudflare Named Tunnel 并刷新 Argo 分享 / 订阅。"
  else
    yellow "正在重启 Quick Tunnel 并刷新 Argo 临时域名。"
  fi
  if ! restart_argo_with_tuning "${ARGO_PROTOCOL:-http2}" "${ARGO_EDGE_IP_VERSION:-auto}"; then
    if argo_is_named_tunnel; then
      yellow "cloudflared 已重启，但固定隧道可能尚未稳定；稍后可再次刷新。"
    else
      yellow "cloudflared 已重启，但暂未抓到 trycloudflare.com 域名；稍后可再次刷新。"
    fi
  fi
  build_argo_share_files "0" || true
  save_state
  refresh_subscription_service
  show_argo_node_info
}

argo_manual_tuning_menu() {
  local choice

  if ! load_state || ! has_argo_install; then
    red "未检测到 Argo 安装记录"
    return
  fi

  normalize_argo_tuning

  echo "当前 Argo 参数：protocol=${ARGO_PROTOCOL}, edge-ip-version=${ARGO_EDGE_IP_VERSION}"
  echo
  echo "高级手动切换："
  echo "1) quic  + auto"
  echo "2) quic  + IPv4"
  echo "3) quic  + IPv6"
  echo "4) http2 + auto"
  echo "5) http2 + IPv4"
  echo "6) http2 + IPv6"
  echo "7) 仅刷新 Argo 分享 / 订阅"
  echo "0) 返回"
  read -r -p "请选择 [0-7]: " choice

  case "$choice" in
    1) apply_argo_tuning "quic" "auto" ;;
    2) apply_argo_tuning "quic" "4" ;;
    3) apply_argo_tuning "quic" "6" ;;
    4) apply_argo_tuning "http2" "auto" ;;
    5) apply_argo_tuning "http2" "4" ;;
    6) apply_argo_tuning "http2" "6" ;;
    7) refresh_argo_node ;;
    *) ;;
  esac
}

argo_tuning_menu() {
  local choice

  if ! load_state || ! has_argo_install; then
    red "未检测到 Argo 安装记录"
    return
  fi

  normalize_argo_tuning

  echo "当前 Argo 参数：protocol=${ARGO_PROTOCOL}, edge-ip-version=${ARGO_EDGE_IP_VERSION}"
  echo
  echo "1) 自动优选并应用（推荐）"
  echo "2) 仅刷新 Argo 分享 / 订阅"
  echo "3) 高级手动切换"
  echo "0) 返回"
  read -r -p "请选择 [0-3]: " choice

  case "$choice" in
    1) auto_tune_argo ;;
    2) refresh_argo_node ;;
    3) argo_manual_tuning_menu ;;
    *) ;;
  esac
}

install_hysteria2() {
  require_root

  if ! load_state; then
    red "请先完成菜单 1 的主安装，以便复用域名和证书。"
    return
  fi

  yellow "将为当前域名 ${DOMAIN} 安装/重装 Hysteria2（随机高位 UDP 端口）"
  yellow "将按兼容优先方式生成 Hysteria2 自签证书与分享信息"
  backup_existing_files
  arm_auto_rollback
  install_packages
  prompt_hy2_obfs
  install_hysteria2_core
  save_state
  install_subscription_service || refresh_subscription_service
  save_state
  disarm_auto_rollback

  green "Hysteria2 安装完成"
  echo
  show_hysteria2_node_info
}

show_hysteria2_node_info() {
  if ! load_state || [[ "${HY2_ENABLED:-0}" != "1" ]]; then
    red "未检测到 Hysteria2 安装记录"
    return
  fi

  if [[ ! -f "$HY2_SHARE_TXT" || ! -f "$HY2_CLIENT_YAML" ]]; then
    build_hysteria2_share_files
  fi

  cyan "============== Hysteria2 节点信息 =============="
  echo "[Hysteria2 URL]"
  sed -n '/^=== Hysteria2 URI ===$/ {n;p;}' "$HY2_SHARE_TXT"
  cyan "==============================================="
}

show_hysteria2_qr_and_subscription() {
  if ! load_state || [[ "${HY2_ENABLED:-0}" != "1" ]]; then
    red "未检测到 Hysteria2 安装记录"
    return
  fi

  if [[ ! -f "$HY2_SHARE_TXT" || ! -f "$HY2_SUB_RAW_TXT" || ! -f "$HY2_SUB_B64_TXT" ]]; then
    build_hysteria2_share_files
  fi

  cyan "=========== Hysteria2 二维码 / 订阅 ==========="
  echo "订阅原文文件: $HY2_SUB_RAW_TXT"
  echo "订阅 Base64 文件: $HY2_SUB_B64_TXT"
  echo "节点二维码 PNG: $HY2_QR_PNG"
  echo
  echo "----- Hysteria2 订阅 Base64 -----"
  cat "$HY2_SUB_B64_TXT"
  echo
  echo

  if command -v qrencode >/dev/null 2>&1; then
    echo "----- Hysteria2 节点二维码 -----"
    qrencode -t ANSIUTF8 < "$HY2_SUB_RAW_TXT" || true
    echo
  else
    yellow "未安装 qrencode，无法在终端显示二维码"
  fi

  cyan "==============================================="
}

show_combined_subscription() {
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

  if has_argo_install; then
    build_argo_share_files || true
    save_state
  fi

  if ! build_combined_subscription_files; then
    red "未生成可用的合并订阅"
    return
  fi

  cyan "========= 合并 URI 订阅（VLESS / HY2 / AnyTLS / SS2022 / Argo） ========="
  echo "订阅原文文件: $COMBO_SUB_RAW_TXT"
  echo "订阅 Base64 文件: $COMBO_SUB_B64_TXT"
  if has_subscription_service; then
    local sub_url
    sub_url="$(subscription_url)"
    print_subscription_links "$sub_url"
  fi
  echo
  echo "----- 合并订阅原文 -----"
  cat "$COMBO_SUB_RAW_TXT"
  echo
  echo "----- 合并订阅 Base64 -----"
  cat "$COMBO_SUB_B64_TXT"
  echo
  cyan "==============================================="
}

reset_hysteria2_password() {
  require_root

  if ! load_state || [[ "${HY2_ENABLED:-0}" != "1" ]]; then
    red "未检测到 Hysteria2 安装记录"
    return
  fi

  yellow "此操作将重置 Hysteria2 密码。"
  if [[ "${HY2_OBFS_ENABLED:-0}" == "1" ]]; then
    yellow "当前已启用 obfs(salamander)，本次也会同步重置 obfs 密码。"
  fi
  backup_existing_files
  arm_auto_rollback
  generate_hy2_password
  write_hysteria2_config
  save_state
  build_hysteria2_share_files
  refresh_subscription_service
  disarm_auto_rollback

  green "Hysteria2 密码已重置"
  echo
  show_hysteria2_node_info
}

reset_anytls_password() {
  require_root

  if ! load_state || [[ "${ANYTLS_ENABLED:-0}" != "1" ]]; then
    red "未检测到 AnyTLS 安装记录"
    return
  fi

  yellow "此操作将重置 AnyTLS 密码，并重新生成 Clash / mihomo YAML。"
  backup_existing_files
  arm_auto_rollback
  install_sing_box
  generate_anytls_password
  write_anytls_config
  save_state
  build_anytls_share_files
  refresh_subscription_service
  disarm_auto_rollback

  green "AnyTLS 密码已重置"
  echo
  show_anytls_node_info
}

reset_ss2022_password() {
  require_root

  if ! load_state || [[ "${SS2022_ENABLED:-0}" != "1" ]]; then
    red "未检测到 Shadowsocks-2022 安装记录"
    return
  fi

  yellow "此操作将重置 Shadowsocks-2022 密码，并重新生成 Clash / mihomo YAML。"
  backup_existing_files
  arm_auto_rollback
  install_sing_box
  generate_ss2022_password
  write_ss2022_config
  save_state
  build_ss2022_share_files
  refresh_subscription_service
  disarm_auto_rollback

  green "Shadowsocks-2022 密码已重置"
  echo
  show_ss2022_node_info
}

uninstall_hysteria2() {
  require_root

  if ! load_state || [[ "${HY2_ENABLED:-0}" != "1" ]]; then
    red "未检测到 Hysteria2 安装记录"
    return
  fi

  yellow "将从 sing-box 中移除 Hysteria2 入站，并清理分享文件"
  yellow "不会自动卸载 sing-box 二进制"
  read -r -p "确认卸载 Hysteria2？[y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]] || return

  systemctl disable --now "$HY2_SERVICE" >/dev/null 2>&1 || true
  clear_hy2_port_hopping_rules
  rm -rf /etc/hysteria
  rm -f "$HY2_CLIENT_YAML" "$HY2_CLIENT_OFFICIAL_YAML" "$HY2_CLIENT_SINGBOX_JSON" "$HY2_SHARE_TXT" "$HY2_SUB_RAW_TXT" "$HY2_SUB_NOHOP_RAW_TXT" "$HY2_SUB_B64_TXT" "$HY2_QR_PNG"
  HY2_ENABLED="0"
  HY2_PORT=""
  HY2_PORT_RANGE=""
  HY2_PASSWORD=""
  write_sing_box_config || true
  save_state
  refresh_subscription_service

  green "Hysteria2 已卸载（配置级）"
}

uninstall_anytls() {
  require_root

  if ! load_state || [[ "${ANYTLS_ENABLED:-0}" != "1" ]]; then
    red "未检测到 AnyTLS 安装记录"
    return
  fi

  yellow "将从 sing-box 中移除 AnyTLS 入站，并清理分享文件"
  yellow "不会自动卸载 sing-box 二进制: ${SING_BOX_BIN}"
  read -r -p "确认卸载 AnyTLS？[y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]] || return

  systemctl disable --now "$MIHOMO_ANYTLS_SERVICE" >/dev/null 2>&1 || true
  rm -rf "$MIHOMO_ANYTLS_DIR"
  rm -f "/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}" "$ANYTLS_CLIENT_YAML" "$ANYTLS_SHARE_TXT" "$ANYTLS_SUB_RAW_TXT" "$ANYTLS_SUB_B64_TXT" "$ANYTLS_QR_PNG"
  systemctl daemon-reload >/dev/null 2>&1 || true

  ANYTLS_ENABLED="0"
  ANYTLS_PORT=""
  ANYTLS_PASSWORD=""
  ANYTLS_SERVER_ADDR=""
  ANYTLS_TLS_SNI=""
  write_sing_box_config || true
  save_state
  refresh_subscription_service

  green "AnyTLS 已卸载（配置级）"
}

uninstall_ss2022() {
  require_root

  if ! load_state || [[ "${SS2022_ENABLED:-0}" != "1" ]]; then
    red "未检测到 Shadowsocks-2022 安装记录"
    return
  fi

  yellow "将从 sing-box 中移除 Shadowsocks-2022 入站，并清理分享文件"
  yellow "不会自动卸载 sing-box 二进制: ${SING_BOX_BIN}"
  read -r -p "确认卸载 Shadowsocks-2022？[y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]] || return

  systemctl disable --now "$MIHOMO_SS2022_SERVICE" >/dev/null 2>&1 || true
  rm -rf "$MIHOMO_SS2022_DIR"
  rm -f "/etc/systemd/system/${MIHOMO_SS2022_SERVICE}" "$SS2022_CLIENT_YAML" "$SS2022_SHARE_TXT" "$SS2022_SUB_RAW_TXT" "$SS2022_SUB_B64_TXT" "$SS2022_QR_PNG"
  systemctl daemon-reload >/dev/null 2>&1 || true

  SS2022_ENABLED="0"
  SS2022_PORT=""
  SS2022_PASSWORD=""
  SS2022_SERVER_ADDR=""
  write_sing_box_config || true
  save_state
  refresh_subscription_service

  green "Shadowsocks-2022 已卸载（配置级）"
}

uninstall_argo() {
  require_root

  if ! load_state || [[ "${ARGO_ENABLED:-0}" != "1" ]]; then
    red "未检测到 Argo 安装记录"
    return
  fi

  yellow "将停止并清理 Argo / Cloudflare Tunnel 配置与分享文件"
  yellow "不会自动卸载 cloudflared 二进制: ${CLOUDFLARED_BIN}"
  read -r -p "确认卸载 Argo？[y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]] || return

  systemctl disable --now "$ARGO_REFRESH_PATH" "$ARGO_REFRESH_TIMER" "$ARGO_REFRESH_SERVICE" "$ARGO_SERVICE" >/dev/null 2>&1 || true
  rm -f "/etc/systemd/system/${ARGO_SERVICE}" "/etc/systemd/system/${ARGO_REFRESH_SERVICE}" "/etc/systemd/system/${ARGO_REFRESH_TIMER}" "/etc/systemd/system/${ARGO_REFRESH_PATH}" \
    "$ARGO_SHARE_TXT" "$ARGO_SUB_RAW_TXT" "$ARGO_SUB_B64_TXT" "$ARGO_QR_PNG" "$ARGO_BOOT_LOG"
  systemctl daemon-reload >/dev/null 2>&1 || true

  ARGO_ENABLED="0"
  ARGO_LOCAL_PORT=""
  ARGO_UUID=""
  ARGO_WS_PATH=""
  ARGO_DOMAIN=""
  ARGO_PROTOCOL="http2"
  ARGO_EDGE_IP_VERSION="auto"
  write_sing_box_config || true
  save_state
  refresh_subscription_service

  green "Argo 已卸载（配置级）"
}

reset_menu() {
  local choice

  if ! load_state; then
    red "未检测到安装记录"
    return
  fi

  echo "请选择要重置的协议参数："
  if has_vless_install; then
    echo "1) 重置 VLESS 参数"
  fi
  if has_hy2_install; then
    echo "2) 重置 Hysteria2 密码"
  fi
  if has_anytls_install; then
    echo "3) 重置 AnyTLS 密码"
  fi
  if has_ss2022_install; then
    echo "4) 重置 Shadowsocks-2022 密码"
  fi
  if has_vless_install || has_hy2_install || has_anytls_install || has_ss2022_install; then
    echo "5) 重置全部已安装协议"
  fi
  echo "0) 返回"
  read -r -p "请选择: " choice

  case "$choice" in
    1)
      if has_vless_install; then
        reset_node_identity
      fi
      ;;
    2)
      if has_hy2_install; then
        reset_hysteria2_password
      fi
      ;;
    3)
      if has_anytls_install; then
        reset_anytls_password
      fi
      ;;
    4)
      if has_ss2022_install; then
        reset_ss2022_password
      fi
      ;;
    5)
      if has_vless_install; then
        reset_node_identity
      fi
      if has_hy2_install; then
        reset_hysteria2_password
      fi
      if has_anytls_install; then
        reset_anytls_password
      fi
      if has_ss2022_install; then
        reset_ss2022_password
      fi
      ;;
    *)
      ;;
  esac
}

uninstall_menu() {
  local choice

  if ! load_state; then
    red "未检测到安装记录"
    return
  fi

  echo "请选择卸载方式："
  echo "1) 卸载全部"
  if has_hy2_install; then
    echo "2) 仅卸载 Hysteria2"
  fi
  if has_anytls_install; then
    echo "3) 仅卸载 AnyTLS"
  fi
  if has_ss2022_install; then
    echo "4) 仅卸载 Shadowsocks-2022"
  fi
  if has_argo_install; then
    echo "5) 仅卸载 Argo / Cloudflare Tunnel"
  fi
  echo "0) 返回"
  read -r -p "请选择: " choice

  case "$choice" in
    1) uninstall_all ;;
    2)
      if has_hy2_install; then
        uninstall_hysteria2
      fi
      ;;
    3)
      if has_anytls_install; then
        uninstall_anytls
      fi
      ;;
    4)
      if has_ss2022_install; then
        uninstall_ss2022
      fi
      ;;
    5)
      if has_argo_install; then
        uninstall_argo
      fi
      ;;
    *)
      ;;
  esac
}

show_status() {
  local argo_refresh_path_status argo_refresh_status bbr_cc bbr_qdisc bin kernel sing_box_status nginx_status sub_status argo_status tcp_ports udp_ports

  load_state || true

  kernel="$(uname -r 2>/dev/null || true)"
  sing_box_status="$(systemctl is-active "$SING_BOX_SERVICE" 2>/dev/null || true)"
  nginx_status="$(systemctl is-active nginx 2>/dev/null || true)"
  sub_status="$(systemctl is-active "$SUB_SERVICE" 2>/dev/null || true)"
  argo_status="$(systemctl is-active "$ARGO_SERVICE" 2>/dev/null || true)"
  argo_refresh_status="$(systemctl is-active "$ARGO_REFRESH_TIMER" 2>/dev/null || true)"
  argo_refresh_path_status="$(systemctl is-active "$ARGO_REFRESH_PATH" 2>/dev/null || true)"
  bbr_cc="$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || true)"
  bbr_qdisc="$(sysctl -n net.core.default_qdisc 2>/dev/null || true)"

  echo "version      : ${APP_VERSION}"
  echo "install_mode : ${INSTALL_MODE:-unknown}"
  echo "target_port  : ${TARGET_PORT:-unknown}"
  echo "hy2_port     : ${HY2_PORT:-unknown}"
  echo "anytls_port  : ${ANYTLS_PORT:-unknown}"
  echo "ss2022_port  : ${SS2022_PORT:-unknown}"
  echo "ss2022_cipher: ${SS2022_CIPHER:-unknown}"
  echo "sub_port     : ${SUB_PORT:-unknown}"
  echo "argo_local   : ${ARGO_LOCAL_PORT:-unknown}"
  echo "argo_domain  : ${ARGO_DOMAIN:-pending}"
  echo "argo_proto   : ${ARGO_PROTOCOL:-http2}"
  echo "argo_edge_ip : ${ARGO_EDGE_IP_VERSION:-auto}"
  echo "kernel       : ${kernel:-unknown}"
  echo "sing-box     : ${sing_box_status:-unknown}"
  echo "nginx        : ${nginx_status:-unknown}"
  echo "vless        : $(has_vless_install && printf 'enabled' || printf 'disabled')"
  echo "hysteria2    : $(has_hy2_install && printf 'enabled' || printf 'disabled')"
  echo "anytls       : $(has_anytls_install && printf 'enabled' || printf 'disabled')"
  echo "ss2022       : $(has_ss2022_install && printf 'enabled' || printf 'disabled')"
  echo "subscription : ${sub_status:-unknown}"
  echo "argo         : ${argo_status:-unknown}"
  echo "argo_mode    : ${ARGO_TUNNEL_MODE:-quick}${ARGO_FIXED_DOMAIN:+ (${ARGO_FIXED_DOMAIN})}"
  echo "argo_refresh : timer=${argo_refresh_status:-unknown}, path=${argo_refresh_path_status:-unknown}"
  echo "tcp_cc       : ${bbr_cc:-unknown}"
  echo "qdisc        : ${bbr_qdisc:-unknown}"
  echo

  if bin="$(sing_box_cmd 2>/dev/null)"; then
    echo "sing-box version:"
    "$bin" version | head -n 1 || true
    echo
  fi

  if [[ -x "$CLOUDFLARED_BIN" ]]; then
    echo "cloudflared version:"
    "$CLOUDFLARED_BIN" version | head -n 1 || true
    echo
  fi

  echo "监听端口："
  tcp_ports="80|443|${TARGET_PORT:-$DEFAULT_TARGET_PORT}"
  if [[ -n "${ANYTLS_PORT:-}" ]]; then
    tcp_ports="${tcp_ports}|${ANYTLS_PORT}"
  fi
  if [[ -n "${SS2022_PORT:-}" ]]; then
    tcp_ports="${tcp_ports}|${SS2022_PORT}"
  fi
  if [[ -n "${SUB_PORT:-}" ]]; then
    tcp_ports="${tcp_ports}|${SUB_PORT}"
  fi
  if [[ -n "${ARGO_LOCAL_PORT:-}" ]]; then
    tcp_ports="${tcp_ports}|${ARGO_LOCAL_PORT}"
  fi
  ss -ltnp | grep -E "(:|\\])(${tcp_ports})\\b" || true
  udp_ports=""
  if [[ -n "${HY2_PORT:-}" ]]; then
    udp_ports="${HY2_PORT}"
  fi
  if [[ -n "${SS2022_PORT:-}" ]]; then
    udp_ports="${udp_ports:+${udp_ports}|}${SS2022_PORT}"
  fi
  if [[ -n "$udp_ports" ]]; then
    ss -lunp | grep -E "(:|\\])(${udp_ports})\\b" || true
  fi
  echo

  if [[ -d "$BACKUP_ROOT" ]]; then
    echo "备份目录："
    find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort || true
  fi
}

restart_services() {
  if ! load_state; then
    red "未检测到安装记录"
    return
  fi

  enable_bbr
  if has_vless_install; then
    systemctl restart nginx
  fi
  if has_sing_box_protocol_install; then
    write_sing_box_config
  fi
  if has_argo_install; then
    write_argo_service
    systemctl daemon-reload
    systemctl enable "$ARGO_SERVICE" >/dev/null 2>&1 || true
    enable_argo_refresh_automation
    systemctl restart "$ARGO_SERVICE"
    ARGO_DOMAIN=""
    refresh_argo_domain || true
    build_argo_share_files "0" || true
    save_state
  fi
  refresh_subscription_service
  green "服务已重启"
}

show_logs() {
  if ! load_state; then
    red "未检测到安装记录"
    return
  fi

  if has_sing_box_protocol_install; then
    echo "========== sing-box 日志（最近 80 行） =========="
    journalctl -u "$SING_BOX_SERVICE" -n 80 --no-pager 2>/dev/null || true
  fi

  if has_vless_install; then
    echo
    echo "========== nginx 错误日志（最近 50 行） =========="
    if [[ -f /var/log/nginx/error.log ]]; then
      tail -n 50 /var/log/nginx/error.log || true
    else
      echo "未找到 /var/log/nginx/error.log"
    fi
  fi

  if has_argo_install; then
    echo
    echo "========== Argo / cloudflared 日志（最近 50 行） =========="
    journalctl -u "$ARGO_SERVICE" -n 50 --no-pager 2>/dev/null || true
    echo
    echo "========== Argo 自动刷新日志（最近 50 行） =========="
    journalctl -u "$ARGO_REFRESH_SERVICE" -n 50 --no-pager 2>/dev/null || true
  fi

  if has_subscription_service; then
    echo
    echo "========== 智能订阅服务日志（最近 50 行） =========="
    journalctl -u "$SUB_SERVICE" -n 50 --no-pager 2>/dev/null || true
  fi
}

prompt_install_profile() {
  local choice token
  INSTALL_WANT_VLESS="0"
  INSTALL_WANT_VMESS="0"
  INSTALL_WANT_HY2="0"
  INSTALL_WANT_ANYTLS="0"
  INSTALL_WANT_ARGO="0"
  INSTALL_WANT_SS2022="0"
  INSTALL_WANT_TUIC="0"
  INSTALL_WANT_BBRV3="0"

  cat <<'EOF'
========================================
 全协议安装（直连 + CDN 双版本）
========================================
1) 全部安装（推荐，回车默认）
2) 自定义安装
3) 直连协议（仅直连协议全部安装）
4) CDN 协议（仅 CDN 协议全部安装）
0) 返回
========================================
EOF
  read -r -p "请选择 [默认: 1]: " choice
  choice="${choice:-1}"
  [[ "$choice" == "0" ]] && return

  case "$choice" in
  1)
    INSTALL_WANT_VLESS="1"
    INSTALL_WANT_VMESS="1"
    INSTALL_WANT_HY2="1"
    INSTALL_WANT_ANYTLS="1"
    INSTALL_WANT_ARGO="1"
    INSTALL_WANT_TUIC="1"
    INSTALL_WANT_SS2022="1"
    return
    ;;
  2)
    cat <<'EOF2'

直连协议（不套 CDN，速度快但看线路）：
  a1) Vless-reality-vision（REALITY伪装）
  a2) Vless-WS-TLS
  a3) Vmess-WS-TLS
  a4) Trojan-WS-TLS
  a5) Shadowsocks-WS-TLS
  a6) Hysteria-2（UDP）
  a7) Tuic-v5（UDP）
  a8) Anytls（TCP）

CDN 协议（套 Cloudflare，延迟低稳）：
  b1) Vless-WS-TLS-CDN
  b2) Vmess-WS-TLS-CDN
  b3) Trojan-WS-TLS-CDN
  b4) Shadowsocks-WS-TLS-CDN
  b5) Argo-Vless-CDN（免域名，Cloudflare Tunnel）

========================================
EOF2
    read -r -p "请输入协议编号（逗号分隔，如 a1,a3,b2,b5）: " choice
    choice="${choice//，/,}"
    choice="${choice//,/ }"
    for token in $choice; do
      token="${token#,}"
      token="${token%,}"
      [[ -z "$token" ]] && continue
      case "$token" in
      a1) INSTALL_WANT_VLESS="1" ;;
      a2) yellow "Vless-WS-TLS 暂未实现，跳过" ;;
      a3) INSTALL_WANT_VMESS="1" ;;
      a4) yellow "Trojan-WS-TLS 暂未实现，跳过" ;;
      a5) INSTALL_WANT_SS2022="1" ;;
      a6) INSTALL_WANT_HY2="1" ;;
      a7) INSTALL_WANT_TUIC="1" ;;
      a8) INSTALL_WANT_ANYTLS="1" ;;
      b1) yellow "Vless-WS-TLS-CDN 暂未实现，跳过" ;;
      b2) INSTALL_WANT_VMESS="1"; INSTALL_WANT_ARGO="1" ;;
      b3) yellow "Trojan-WS-TLS-CDN 暂未实现，跳过" ;;
      b4) INSTALL_WANT_SS2022="1"; INSTALL_WANT_ARGO="1" ;;
      b5) INSTALL_WANT_ARGO="1" ;;
      *) yellow "忽略未知协议: $token" ;;
      esac
    done
    ;;
  3)
    INSTALL_WANT_VLESS="1"
    INSTALL_WANT_VMESS="1"
    INSTALL_WANT_HY2="1"
    INSTALL_WANT_ANYTLS="1"
    INSTALL_WANT_TUIC="1"
    INSTALL_WANT_SS2022="1"
    green "将安装全部直连协议"
    ;;
  4)
    INSTALL_WANT_ARGO="1"
    INSTALL_WANT_VMESS="1"
    green "将安装全部 CDN 协议"
    ;;
  *)
    yellow "无效，默认全部安装"
    INSTALL_WANT_VLESS="1"
    INSTALL_WANT_VMESS="1"
    INSTALL_WANT_HY2="1"
    INSTALL_WANT_ANYTLS="1"
    INSTALL_WANT_ARGO="1"
    INSTALL_WANT_TUIC="1"
    INSTALL_WANT_SS2022="1"
    ;;
  esac
}


full_install() {
  require_root
  local need_cert_work=0
  local saved_email=""

  if load_state; then
    saved_email="${EMAIL:-}"
  fi

  clear
  cyan "========== 全新安装 / 重装 =========="
  echo
  echo "证书方式："
  echo "1) 自签证书（REALITY 伪装用，推荐，无需域名）"
  echo "2) 申请 Let's Encrypt 证书（需要域名指向本机）"
  read -r -p "请选择 [默认: 1]: " cert_mode
  cert_mode="${cert_mode:-1}"

  if [[ "$cert_mode" == "1" ]]; then
    # 自签证书模式
    SELF_SIGN_CERT="1"

    # 尝试读取上次安装配置
    if load_state && [[ "${SELF_SIGN_CERT:-0}" == "1" && -n "${DOMAIN:-}" ]]; then
      echo
      yellow "检测到上次自签证书安装配置："
      echo "  伪装域名: ${DOMAIN}"
      echo "  节点前缀: ${NODE_PREFIX:-（无）}"
      echo "  已选协议:$( [[ ${HY2_ENABLED:-0} == 1 ]] && echo -n ' Hysteria2'; [[ ${ANYTLS_ENABLED:-0} == 1 ]] && echo -n ' AnyTLS'; [[ ${SS2022_ENABLED:-0} == 1 ]] && echo -n ' Shadowsocks'; [[ ${VMESS_ENABLED:-0} == 1 ]] && echo -n ' VMess'; [[ ${TUIC_ENABLED:-0} == 1 ]] && echo -n ' TUIC'; [[ ${ARGO_ENABLED:-0} == 1 ]] && echo -n ' Argo')"
      read -r -p "是否采用上次配置重新安装？[y/N]: " use_prev
      if [[ "$use_prev" =~ ^[Yy]$ ]]; then
        green "采用上次配置，跳过配置选择"
        UUID="$(cat /proc/sys/kernel/random/uuid)"
        local bin
        bin="$(sing_box_cmd 2>/dev/null || true)"
        if [[ -n "$bin" ]]; then
          local keys
          keys="$("$bin" generate reality-keypair)"
          PRIVATE_KEY="$(awk -F: 'tolower($1) ~ /private/ {v=$2; sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v); print v; exit}' <<<"$keys")"
          PUBLIC_KEY="$(awk -F: 'tolower($1) ~ /public/ {v=$2; sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v); print v; exit}' <<<"$keys")"
        fi
        XHTTP_PATH=""
        SHORT_ID="$(openssl rand -hex 8)"
      fi
    fi

    # 用户选 n 或没有上次配置时：删缓存 → 直接进入伪装域名选择
    if [[ "${use_prev:-}" != "Y" && "${use_prev:-}" != "y" ]]; then
      # 清除旧的浏览器测速缓存
      rm -f /etc/sing-box/node-info/selected_domains.txt

      # 自签模式：选伪装域名
      local -a reality_domains=(
        "www.cloudflare.com#1位·CF自家边缘节点最多"
        "www.bing.com#2位·微软搜索全球验证最久"
        "www.apple.com#3位·Apple企业CDN延迟极低"
        "arxiv.org#4位·Cornell学术预印本Cloudflare"
        "dl.acm.org#5位·ACM计算机协会Cloudflare"
        "www.semanticscholar.org#6位·AI2研究所Cloudflare"
        "www.shopify.com#7位·全球电商平台企业CDN"
        "www.sciencedirect.com#8位·Elsevier科学期刊"
        "www.ieee.org#9位·国际电气电子工程师学会"
        "www.nature.com#10位·顶级科学期刊"
      )
      echo
      echo
      # 先测速（VPS → 伪装域名 TLS 握手延迟，即 REALITY 实际路径）
      cyan "正在从 VPS 实测各伪装域名的 TLS 握手延迟..."
      local i d note lat lat_ms
      local -a reality_lats=()
      for i in "${!reality_domains[@]}"; do
        d="${reality_domains[$i]%%#*}"
        note="${reality_domains[$i]#*#}"
        printf "  测速 %s ... " "$d"
        lat="$(curl -o /dev/null -sS --connect-timeout 5 --max-time 15 -w "%{time_total}" "https://${d}/" 2>/dev/null || echo "999")"
        lat_ms="$(awk -v t="$lat" 'BEGIN {printf "%d", t*1000}' 2>/dev/null)"
        echo "${lat_ms} ms"
        reality_lats+=("$lat_ms")
      done

      # 找最低延迟
      local best_rt_idx=0 best_rt_ms=999999
      for i in "${!reality_lats[@]}"; do
        if (( ${reality_lats[$i]} < best_rt_ms )); then
          best_rt_ms="${reality_lats[$i]}"
          best_rt_idx="$i"
        fi
      done

      echo
      echo "序号  域名                             备注                              延迟"
      echo "------------------------------------------------------------------"
      for i in "${!reality_domains[@]}"; do
        d="${reality_domains[$i]%%#*}"
        note="${reality_domains[$i]#*#}"
        local mark=""
        if (( i == best_rt_idx )); then
          mark=" $(green '← 最低')"
        fi
        printf " %2d)   %-32s %-32s %s ms%s\\n" "$((i+1))" "$d" "$note" "${reality_lats[$i]}" "$mark"
      done
      echo "  0) 返回"
      echo "------------------------------------------------------------------"
      echo "注：延迟为 VPS → 伪装域名 的 TLS 握手时间（REALITY 实际走的链路）"
      read -r -p "请选择 [默认: $((best_rt_idx+1)) 最低延迟]: " reality_choice
      reality_choice="${reality_choice:-$((best_rt_idx+1))}"
      [[ "$reality_choice" == "0" ]] && return

      local idx=$((reality_choice - 1))
      if (( idx >= 0 && idx < ${#reality_domains[@]} )); then
        REALITY_SNI="${reality_domains[$idx]%%#*}"
        DOMAIN="$REALITY_SNI"
      else
        REALITY_SNI="www.cloudflare.com"
        DOMAIN="$REALITY_SNI"
        idx=0
      fi

      green "已选择: ${REALITY_SNI}（VPS→伪装站 TLS 握手 ${reality_lats[$idx]} ms）"
    fi
  else
    SELF_SIGN_CERT="0"
    read -r -p "请输入域名: " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
      red "域名不能为空"
      return
    fi
  fi

  read -r -p "请输入节点名称前缀（可选，直接回车跳过）: " NODE_PREFIX
  [[ -n "$NODE_PREFIX" ]] && yellow "节点名称将添加前缀: ${NODE_PREFIX}-"
  apply_node_prefix

  prompt_install_profile
  if [[ "$INSTALL_WANT_VLESS" != "1" && "$INSTALL_WANT_VMESS" != "1" && "$INSTALL_WANT_HY2" != "1" && "$INSTALL_WANT_ANYTLS" != "1" && "$INSTALL_WANT_ARGO" != "1" && "$INSTALL_WANT_SS2022" != "1" && "$INSTALL_WANT_TUIC" != "1" ]]; then
    return
  fi

  if [[ "$INSTALL_WANT_ARGO" == "1" ]]; then
    select_argo_edge_server
    prompt_argo_tunnel_config || return
    if argo_is_named_tunnel && [[ "$INSTALL_WANT_VLESS" == "1" || "$INSTALL_WANT_HY2" == "1" || "$INSTALL_WANT_ANYTLS" == "1" || "$INSTALL_WANT_SS2022" == "1" ]]; then
      yellow "提示：固定 Argo 使用开头输入的域名 ${ARGO_FIXED_DOMAIN} 作为 Cloudflare Tunnel Host/SNI。"
      yellow "同一个域名不适合再同时作为直连高位端口节点的 DNS-only 域名；全协议场景建议给直连协议另用子域名。"
    fi
  fi

  if [[ "${SELF_SIGN_CERT:-0}" == "1" ]]; then
    need_cert_work=0
    yellow "自签证书模式：跳过 ACME 证书申请"
    # Generate self-signed cert for internal services
    mkdir -p "$SSL_DIR"
    if ! cert_files_exist || ! cert_matches_domain; then
      openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1)         -keyout "$SSL_DIR/private.key" -out "$SSL_DIR/fullchain.cer"         -days 3650 -subj "/CN=${DOMAIN}" -addext "subjectAltName=DNS:${DOMAIN}" 2>/dev/null
      green "自签证书已生成"
    fi
  else
    if ! cert_matches_domain || ! cert_is_currently_valid; then
      need_cert_work=1
    fi

    if [[ "$need_cert_work" == "1" ]]; then
      EMAIL="${saved_email:-$(default_acme_email)}"
      yellow "证书邮箱自动使用：${EMAIL}"
    else
      EMAIL="${saved_email:-$(default_acme_email)}"
    fi
  fi

  if [[ "$INSTALL_WANT_VLESS" == "1" ]]; then
    systemctl stop "$SING_BOX_SERVICE" 2>/dev/null || true
    determine_install_mode
    yellow "将重新生成 ${SING_BOX_CFG}（会覆盖旧配置）。"
    yellow "VLESS：TCP + REALITY，由 sing-box 统一承载。"
    yellow "Nginx 伪装站模式：${INSTALL_MODE}"
    if [[ "$INSTALL_MODE" == "migrate" ]]; then
      yellow "将尝试把现有 Nginx 的 443 站点迁移到 127.0.0.1:${TARGET_PORT}"
    else
      yellow "将写入伪装站配置 ${NGINX_CFG}"
    fi
  fi

  if [[ "$INSTALL_WANT_HY2" == "1" ]]; then
    yellow "Hysteria2：sing-box 入站，随机高位 UDP 端口（需要放行 UDP）。"
    yellow "将使用域名证书，并为 Clash / mihomo 订阅写入 HY2 带宽字段。"
  fi

  if [[ "$INSTALL_WANT_ANYTLS" == "1" ]]; then
    yellow "AnyTLS：sing-box 入站，随机高位 TCP 端口。"
    yellow "将导出 Clash / mihomo YAML，并写入智能订阅。"
  fi

  if [[ "$INSTALL_WANT_ARGO" == "1" ]]; then
    if argo_is_named_tunnel; then
      yellow "Argo：Cloudflare Named Tunnel + VLESS-WS，本地后端为 sing-box。"
      yellow "固定域名：${ARGO_FIXED_DOMAIN}；Cloudflare Service: http://localhost:${ARGO_LOCAL_PORT}"
    else
      yellow "Argo：Cloudflare Quick Tunnel + VLESS-WS，本地后端为 sing-box。"
      yellow "订阅连接地址固定为 ${ARGO_EDGE_SERVER}:443；SNI / Host 使用当前 trycloudflare.com。"
    fi
  fi

  if [[ "$INSTALL_WANT_SS2022" == "1" ]]; then
    yellow "Shadowsocks-2022：sing-box 入站，随机高位 TCP/UDP 端口。"
    yellow "将导出 ss:// 链接、Clash / mihomo YAML，并写入智能订阅。"
  fi

  if [[ "${INSTALL_WANT_BBRV3:-0}" == "1" ]]; then
    yellow "将尝试安装 XanMod / BBRv3 内核；失败时继续安装协议。"
    yellow "如安装成功，新内核需要重启 VPS 后才会真正生效。"
  fi

  backup_existing_files
  arm_auto_rollback
  apply_install_profile_selection
  if [[ "${INSTALL_WANT_BBRV3:-0}" == "1" ]]; then
    install_packages "0"
    install_bbrv3_kernel
  else
    install_packages
  fi
  if [[ "$need_cert_work" == "1" && "${SELF_SIGN_CERT:-0}" != "1" ]]; then
    install_acme
    issue_cert
  fi

  if [[ "$INSTALL_WANT_HY2" == "1" ]]; then
    prompt_hy2_obfs
  fi

  if [[ "$INSTALL_WANT_VLESS" == "1" ]]; then
    systemctl stop "$SING_BOX_SERVICE" 2>/dev/null || true
    stop_common_services
    check_ports_before_install
    install_sing_box
    generate_keys_and_ids
    cleanup_generated_nginx_files

    if [[ "$INSTALL_MODE" == "migrate" ]]; then
      migrate_existing_nginx_to_target_port
    else
      write_fake_site
      write_nginx_fake_conf
    fi

    write_sing_box_config
  fi

  if [[ "$INSTALL_WANT_HY2" == "1" ]]; then
    install_hysteria2_core
  fi

  if [[ "$INSTALL_WANT_ANYTLS" == "1" ]]; then
    install_anytls_core
  fi

  if [[ "$INSTALL_WANT_ARGO" == "1" ]]; then
    install_argo_core
  fi

  if [[ "$INSTALL_WANT_SS2022" == "1" ]]; then
    install_ss2022_core
  fi

  save_state
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
  if has_argo_install; then
    build_argo_share_files || true
  fi
  install_subscription_service || refresh_subscription_service
  save_state
  build_combined_subscription_files || true
  disarm_auto_rollback

  green "安装完成"
  echo
  show_node_info
  if [[ "${BBRV3_REBOOT_REQUIRED:-0}" == "1" ]]; then
    prompt_reboot_for_bbrv3
  fi
}

reset_node_identity() {
  require_root

  if ! load_state; then
    red "未检测到安装记录"
    return
  fi

  yellow "此操作将重置以下项目："
  echo "  - UUID"
  echo "  - REALITY shortId"
  echo "  - REALITY key pair"
  echo
  yellow "不会重新签发证书，也不会改动现有 Nginx 迁移模式。"
  backup_existing_files
  arm_auto_rollback
  generate_keys_and_ids
  write_sing_box_config
  save_state
  build_client_files
  refresh_subscription_service
  disarm_auto_rollback

  green "身份参数已重置"
  echo
  show_node_info
}

renew_cert() {
  require_root

  if ! load_state; then
    red "未检测到安装记录"
    return
  fi

  if [[ ! -x "$ACME_SH" ]]; then
    red "未找到 acme.sh"
    return
  fi

  stop_common_services

  if port_in_use 80; then
    red "80 端口仍被占用，无法续签"
    show_port_usage 80
    return
  fi

  prepare_acme_http01 || return 1

  if ! "$ACME_SH" --renew -d "$DOMAIN" --ecc --force "${ACME_STANDALONE_LISTEN_ARGS[@]}"; then
    yellow "证书续签失败，尝试继续使用现有证书或备份证书。"
    print_acme_http01_failure_hint
    if ! cert_matches_domain || ! cert_is_currently_valid; then
      restore_cert_from_known_locations || return 1
    fi
  elif ! "$ACME_SH" --install-cert -d "$DOMAIN" --ecc \
    --fullchain-file "${SSL_DIR}/fullchain.cer" \
    --key-file "${SSL_DIR}/private.key" \
    --reloadcmd "systemctl reload nginx || true"; then
    yellow "证书安装失败，尝试恢复旧证书。"
    restore_cert_from_known_locations || return 1
  fi

  if has_vless_install; then
    systemctl restart nginx
  fi
  if has_sing_box_protocol_install; then
    write_sing_box_config
  fi
  if has_subscription_service; then
    systemctl restart "$SUB_SERVICE"
  fi
  green "证书已续签 / 重装完成"
}

uninstall_all() {
  local restore_answer="Y"

  require_root

  yellow "将删除本脚本生成的 sing-box/nginx/hysteria2/anytls/ss2022/argo/订阅 配置与分享文件"
  yellow "不会自动卸载 sing-box/nginx/cloudflared 二进制或软件包"
  read -r -p "确认卸载？[y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]] || return

  load_state || true

  if [[ "${INSTALL_MODE:-}" == "migrate" && -n "${LAST_BACKUP_DIR:-}" && -d "${LAST_BACKUP_DIR:-}" ]]; then
    read -r -p "检测到迁移前备份，是否同时恢复旧站点配置？[Y/n]: " restore_answer
    if [[ ! "$restore_answer" =~ ^[Nn]$ ]]; then
      restore_backup_dir "$LAST_BACKUP_DIR"
      rm -rf "$STATE_DIR"
      green "卸载并恢复完成"
      return
    fi
  fi

  if [[ -x "$ACME_SH" && -n "${DOMAIN:-}" ]]; then
    "$ACME_SH" --remove -d "$DOMAIN" --ecc >/dev/null 2>&1 || true
  fi

  stop_all_related
  systemctl disable --now "$HY2_SERVICE" >/dev/null 2>&1 || true
  systemctl disable --now "$MIHOMO_ANYTLS_SERVICE" >/dev/null 2>&1 || true
  systemctl disable --now "$MIHOMO_SS2022_SERVICE" >/dev/null 2>&1 || true
  systemctl disable --now "$SUB_SERVICE" >/dev/null 2>&1 || true
  systemctl disable --now "$ARGO_REFRESH_PATH" "$ARGO_REFRESH_TIMER" "$ARGO_REFRESH_SERVICE" >/dev/null 2>&1 || true
  systemctl disable --now "$ARGO_SERVICE" >/dev/null 2>&1 || true
  clear_hy2_port_hopping_rules

  rm -f "$SING_BOX_CFG" "$XRAY_CFG" "$NGINX_CFG" "$NGINX_REALIP_CFG" "$CLIENT_JSON" "$SHARE_TXT" "$SUB_RAW_TXT" "$SUB_B64_TXT" "$NODE_QR_PNG" \
    "$HY2_CLIENT_YAML" "$HY2_CLIENT_OFFICIAL_YAML" "$HY2_CLIENT_SINGBOX_JSON" "$HY2_SHARE_TXT" "$HY2_SUB_RAW_TXT" "$HY2_SUB_NOHOP_RAW_TXT" "$HY2_SUB_B64_TXT" "$HY2_QR_PNG" \
    "$ANYTLS_CLIENT_YAML" "$ANYTLS_SHARE_TXT" "$ANYTLS_SUB_RAW_TXT" "$ANYTLS_SUB_B64_TXT" "$ANYTLS_QR_PNG" \
    "$SS2022_CLIENT_YAML" "$SS2022_SHARE_TXT" "$SS2022_SUB_RAW_TXT" "$SS2022_SUB_B64_TXT" "$SS2022_QR_PNG" \
    "$ARGO_SHARE_TXT" "$ARGO_SUB_RAW_TXT" "$ARGO_SUB_B64_TXT" "$ARGO_QR_PNG" "$ARGO_BOOT_LOG" \
    "$SUB_SERVER_SCRIPT" "$INSTALL_SCRIPT" "$COMBO_SUB_RAW_TXT" "$COMBO_SUB_B64_TXT" "$BBR_SYSCTL" "$DUAL_STACK_SYSCTL" "$XANMOD_APT_LIST" "$XANMOD_KEYRING" \
    "$SING_BOX_SERVICE_TUNING" "$XRAY_SERVICE_TUNING" "$MIHOMO_ANYTLS_SERVICE_TUNING" "$MIHOMO_SS2022_SERVICE_TUNING"
  rmdir "$SING_BOX_SERVICE_TUNING_DIR" "$XRAY_SERVICE_TUNING_DIR" "$MIHOMO_ANYTLS_SERVICE_TUNING_DIR" "$MIHOMO_SS2022_SERVICE_TUNING_DIR" >/dev/null 2>&1 || true
  rm -f "/etc/systemd/system/${SING_BOX_SERVICE}" "/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}" "/etc/systemd/system/${MIHOMO_SS2022_SERVICE}" "/etc/systemd/system/${SUB_SERVICE}" \
    "/etc/systemd/system/${ARGO_SERVICE}" "/etc/systemd/system/${ARGO_REFRESH_SERVICE}" "/etc/systemd/system/${ARGO_REFRESH_TIMER}" "/etc/systemd/system/${ARGO_REFRESH_PATH}"
  rm -rf /etc/hysteria
  rm -rf "$SING_BOX_DIR" "$MIHOMO_ANYTLS_DIR" "$MIHOMO_SS2022_DIR" "$SUBSCRIPTION_DIR" "$WEB_ROOT" "$SSL_DIR" "$STATE_DIR"
  systemctl daemon-reload >/dev/null 2>&1 || true

  green "卸载完成（仅清理本脚本生成内容）"
}

generate_speedtest_html() {
  mkdir -p /etc/sing-box/node-info
  SPEED_IP="$(curl -4fsS --connect-timeout 5 --max-time 15 https://api.ipify.org 2>/dev/null || curl -4fsS --connect-timeout 5 --max-time 15 https://ipv4.icanhazip.com 2>/dev/null || echo 'get IP failed')"
  SPEED_PORT="$(shuf -i 50000-60000 -n 1 2>/dev/null || echo '58888')"
  while port_in_use "$SPEED_PORT" 2>/dev/null; do SPEED_PORT="$(shuf -i 50000-60000 -n 1 2>/dev/null || echo '58888')"; done
  export SPEED_PORT

  cat > /etc/sing-box/node-info/speedtest.html << 'SPDT_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>CF Domain Speed Test</title>
<style>
:root{color-scheme:light}
body{font-family:system-ui,-apple-system,sans-serif;background:#f5f5f5;margin:0;padding:20px}
.container{max-width:800px;margin:0 auto}
h1{font-size:24px;margin:0 0 10px}
.info{color:#666;margin:0 0 8px;font-size:13px}
.warn{background:#fff3cd;border-radius:6px;padding:10px;margin:0 0 15px;font-size:13px}
.rec{background:#e8f5e9;border-radius:8px;padding:12px;margin:0 0 20px;font-size:13px}
.rec strong{color:#2e7d32}
table{width:100%;border-collapse:collapse;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08)}
th{background:#333;color:#fff;padding:10px 12px;text-align:left;font-size:14px}
td{padding:8px 12px;border-bottom:1px solid #eee;font-size:14px}
tr:hover{background:#f0f7ff}
.bar{display:inline-block;height:14px;border-radius:3px;margin-right:6px;vertical-align:middle}
.fast{background:#4caf50}.mid{background:#ff9800}.slow{background:#f44336}.wait{background:#ccc;animation:pulse 1s infinite}
@keyframes pulse{50%{opacity:.5}}
.btn{display:inline-block;padding:10px 20px;background:#1976d2;color:#fff;border:none;border-radius:6px;cursor:pointer;font-size:14px;margin:10px 5px 0 0}
.btn:hover{background:#1565c0}
.result{font-size:12px;color:#888;margin:10px 0}
</style>
</head>
<body>
<div class="container">
<h1>Cloudflare Preferred Domain Speed Test</h1>
<p class="info">Your IP: <strong id="myip">detecting...</strong></p>
<div class="warn"><strong>Note:</strong> If using proxy/VPN, test measures proxy latency. Close proxy for real local latency.</div>
<div id="ipv6-notice" class="warn" style="display:none;background:#d1ecf1"><strong>IPv6 detected:</strong> CF domain optimization has minimal effect for IPv6 users. Close page and return to terminal.</div>
<div class="rec">
<strong>ISP recommendations:</strong><br>
Telecom - visa.cn / shopify.com / cf.877774.xyz<br>
Unicom - cloudflare-dl.byoip.top / saas.sin.fan<br>
Mobile - bestcf.030101.xyz / cf.090227.xyz<br>
Unknown - www.visa.cn (best domestic CDN)
</div>
<button class="btn" onclick="startTest()">Start Test (30 domains)</button>
<button class="btn" onclick="stopTest()">Stop</button>
<button class="btn" onclick="submitDomains()" style="background:#4caf50">Submit Selected to VPS</button>
<p class="result" id="status">Click "Start Test" to begin</p>
<table id="results">
<thead><tr><th>#</th><th>Domain</th><th>Note</th><th>Latency (ms)</th><th>Select</th></tr></thead>
<tbody id="tbody"></tbody>
</table>
</div>
<script>
var domains=[
{d:"www.visa.cn",n:"Visa China"},{d:"www.shopify.com",n:"Shopify"},{d:"www.apple.com",n:"Apple"},
{d:"www.bing.com",n:"MS Bing"},{d:"www.cloudflare.com",n:"Cloudflare"},{d:"arxiv.org",n:"Cornell"},
{d:"dl.acm.org",n:"ACM"},{d:"www.semanticscholar.org",n:"AI2"},{d:"www.sciencedirect.com",n:"Elsevier"},
{d:"www.nature.com",n:"Nature"},{d:"www.ieee.org",n:"IEEE"},{d:"time.is",n:"time.is"},
{d:"mfa.gov.ua",n:"MFA Ukraine"},{d:"store.ubi.com",n:"Ubisoft"},{d:"staticdelivery.nexusmods.com",n:"NexusMods"},
{d:"icook.hk",n:"icook HK"},{d:"icook.tw",n:"icook TW"},{d:"cloudflare-dl.byoip.top",n:"NB preferred"},
{d:"cf.877774.xyz",n:"QMS"},{d:"saas.sin.fan",n:"MIYU"},{d:"bestcf.030101.xyz",n:"Mingyu mobile"},
{d:"cf.090227.xyz",n:"CM maintained"},{d:"cdn.2020111.xyz",n:"cdn.2020111"},{d:"cdns.doon.eu.org",n:"cdns.doon"},
{d:"cf.0sm.com",n:"cf.0sm"},{d:"cf.900501.xyz",n:"cf.900501"},{d:"cfip.1323123.xyz",n:"cfip.1323123"},
{d:"cfip.cfcdn.vip",n:"cfip.cfcdn"},{d:"cloudflare-ip.mofashi.ltd",n:"mofashi"},{d:"fn.130519.xyz",n:"fn.130519"}
];
var running=false,results=[],selected=new Set(),CONCURRENCY=15;

(function(){
  var ipDisplayed = false;
  function showIP(ip, via){
    if(ipDisplayed) return;
    ipDisplayed = true;
    var el = document.getElementById("myip");
    if(ip.indexOf(":") >= 0){
      el.innerHTML = ip + ' <span style=color:#888>(' + via + ', IPv6)</span>';
      document.getElementById("ipv6-notice").style.display = "block";
    } else {
      el.innerHTML = ip + ' <span style=color:#888>(' + via + ')</span>';
    }
  }
  try{
    var pc = new (window.RTCPeerConnection||window.webkitRTCPeerConnection)({iceServers:[]});
    pc.createDataChannel("");
    pc.onicecandidate = function(e){
      if(e && e.candidate && e.candidate.candidate){
        var parts = e.candidate.candidate.split(" ");
        if(parts.length >= 5){
          var ip = parts[4];
          if(ip && !ip.startsWith("192.168.") && !ip.startsWith("10.") && !ip.startsWith("172.1") && !ip.startsWith("0.") && !ip.startsWith("127.") && !ip.startsWith("fe80:") && !ip.startsWith("fc") && !ip.startsWith("fd") && ip.indexOf(".local") < 0){
            showIP(ip, "local IP, bypassed proxy");
            pc.close();
          }
        }
      }
    };
    pc.createOffer().then(function(s){pc.setLocalDescription(s)});
  }catch(e){}
  var ipDone = false;
  function multiFallback(){
    if(ipDone) return;
    ipDone = true;
    var timedOut = false;
    var t = setTimeout(function(){ timedOut = true; }, 5000);
    function extractIp(resp){ if(resp && resp.ip) return resp.ip; if(typeof resp === "string" && resp.trim()) return resp.trim(); return null; }
    Promise.any([
      fetch("https://api.ipify.org?format=json", {mode: "cors"}).then(function(r){return r.json()}),
      fetch("https://ipv4.icanhazip.com/", {mode: "cors"}).then(function(r){return r.text()}),
      fetch("https://api.ip.sb/geoip", {mode: "cors"}).then(function(r){return r.json()}),
      fetch("https://api6.ipify.org?format=json", {mode: "cors"}).then(function(r){return r.json()})
    ]).then(function(result){
      if(!timedOut){ var ip = extractIp(result); if(ip) showIP(ip, "via external API"); }
    }).catch(function(){
      if(!timedOut){
        fetch("/myip", {mode: "cors"}).then(function(r){return r.text()}).then(function(ip){
          if(ip && ip.trim() && !timedOut) showIP(ip.trim(), "detected by VPS");
        }).catch(function(){
          if(!timedOut) showIP("unavailable", "all methods failed");
        });
      }
    }).finally(function(){ clearTimeout(t); });
  }
  setTimeout(function(){ if(!ipDisplayed) multiFallback(); }, 2000);
  setTimeout(function(){ if(!ipDisplayed) document.getElementById("myip").innerHTML = 'failed <span style=color:#888>(browser restriction)</span>'; }, 7000);
})();

function init(){var t=document.getElementById("tbody");t.innerHTML="";domains.forEach(function(d,i){var r=document.createElement("tr");r.id="row-"+i;r.innerHTML="<td>"+(i+1)+"</td><td>"+d.d+"</td><td>"+d.n+"</td><td id=lat-"+i+"><span class='bar wait' style=width:60px></span></td><td><input type=checkbox id=chk-"+i+" onchange=toggle("+i+")></td>";t.appendChild(r)})}
function toggle(i){var c=document.getElementById("chk-"+i);c.checked?selected.add(i):selected.delete(i);updateSel()}
function updateSel(){var s=[...selected].sort((a,b)=>a-b).map(i=>domains[i].d);document.getElementById("status").textContent=s.length?"selected: "+s.join(", "):"check the fastest domains"}
function pingOnce(d){return new Promise(function(resolve){var s=performance.now();var c=new AbortController();var to=setTimeout(function(){c.abort();resolve(9999)},5000);fetch("https://"+d+"/favicon.ico?"+Math.random(),{mode:"no-cors",cache:"no-cache",signal:c.signal}).then(function(){clearTimeout(to);resolve(Math.round(performance.now()-s))}).catch(function(){clearTimeout(to);if(performance.now()-s<4900){resolve(Math.round(performance.now()-s))}else{resolve(9999)}})})}
function testOne(i){if(!running)return;var d=domains[i];return Promise.all([pingOnce(d.d),pingOnce(d.d),pingOnce(d.d)]).then(function(ms){results[i]=Math.min.apply(null,ms);updateRow(i)})}
function updateRow(i){var m=results[i],t=document.getElementById("lat-"+i),c=m<200?"fast":m<500?"mid":"slow",w=m<200?m:200+(m-200)/3;c=m>=5000?"slow":c;t.innerHTML="<span class='bar "+c+"' style=width:"+Math.min(w,300)+"px></span> "+(m>=9999?"timeout":m+" ms")}
async function startTest(){
  running=true;results=[];selected.clear();
  init();
  var statusEl=document.getElementById("status");
  statusEl.textContent="testing... (concurrency "+CONCURRENCY+")";
  for(var i=0;i<domains.length&&running;i+=CONCURRENCY){
    var batch=[];
    for(var j=i;j<Math.min(i+CONCURRENCY,domains.length)&&running;j++){
      (function(idx){batch.push(testOne(idx));})(j);
    }
    await Promise.all(batch);
  }
  if(running){
    var sorted=results.map(function(r,i){return{r:i}}).filter(function(x){return x.r<9000}).sort(function(a,b){return a.r-b.r});
    selected.clear();
    sorted.slice(0,5).forEach(function(x){selected.add(x.i);document.getElementById("chk-"+x.i).checked=true});
    updateSel();
    statusEl.textContent="done! fastest 5 auto-selected. submit to VPS.";
    running=false;
  }
}
function submitDomains(){
  var sel=[...selected].sort((a,b)=>a-b).map(i=>domains[i].d);
  if(sel.length===0){alert("select domains first");return}
  document.getElementById("status").textContent="submitting...";
  fetch("/submit",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({domains:sel})})
  .then(function(r){return r.json()}).then(function(d){
    var ipInfo = d.client_ip ? "VPS sees you as: " + d.client_ip + "<br>" : "";
    document.getElementById("status").innerHTML="<span style='color:#4caf50'>submitted "+d.count+" domains:<br>"+d.domains.join(", ")+"</span><br>"+ipInfo+"<span style='color:#888'>close page, return to terminal</span>";
  }).catch(function(e){document.getElementById("status").innerHTML="<span style='color:red'>submit failed</span>, check VPS server";});
}
function stopTest(){running=false;document.getElementById("status").textContent="stopped"}
init();
</script>
</body>
</html>
SPDT_EOF

  echo
  cyan "--- local browser speed test ---"
  echo "open in browser (disable proxy for accurate results):"
  echo ""
  echo "  http://${SPEED_IP:-get IP failed}:${SPEED_PORT:-58888}/speedtest.html"
  echo ""
  yellow "measures YOUR latency to CF domains. select fastest and submit."
  echo "(server auto-stops after 60s)"
  echo ""

  (cd /etc/sing-box/node-info && SPEED_PORT="${SPEED_PORT}" python3 << 'SRVEOF' &
import http.server, json, os, datetime
PORT = int(os.environ.get("SPEED_PORT","8888"))
SAVE = "/etc/sing-box/node-info/selected_domains.txt"

class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/myip":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(self.client_address[0].encode("utf-8"))
            return
        super().do_GET()
    def do_POST(self):
        if self.path != "/submit":
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length", 0))
        data = json.loads(self.rfile.read(length))
        domains = data.get("domains", [])
        client_ip = self.client_address[0]
        ts = datetime.datetime.now().strftime("%H:%M:%S")
        with open(SAVE, "w") as f:
            f.write(",".join(domains))
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        resp = json.dumps({"ok": True, "count": len(domains), "domains": domains, "client_ip": client_ip}, ensure_ascii=False)
        self.wfile.write(resp.encode("utf-8"))
        print("[%s] Received from %s: %s" % (ts, client_ip, ", ".join(domains)))
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
    def log_message(self, *a):
        pass

srv = http.server.HTTPServer(("0.0.0.0", PORT), H)
srv.timeout = 60
try:
    print("Speedtest server on port %d" % PORT)
    srv.serve_forever()
except:
    pass
SRVEOF
  )
  sleep 60
  kill %1 2>/dev/null || true
}



detect_sing_box() {
  local bin="" status="" version="" status_text=""
  for b in /usr/local/bin/sing-box /etc/s-box/sing-box /usr/bin/sing-box; do
    if [[ -x "$b" ]]; then
      bin="$b"
      break
    fi
  done
  if [[ -z "$bin" ]] && command -v sing-box >/dev/null 2>&1; then
    bin="$(command -v sing-box)"
  fi
  if [[ -z "$bin" ]]; then
    local sb_pid
    sb_pid="$(pgrep -x sing-box 2>/dev/null || true)"
    if [[ -n "$sb_pid" ]]; then
      bin="/proc/${sb_pid}/exe"
    fi
  fi
  if [[ -n "$bin" ]]; then
    status="$(systemctl is-active sing-box.service 2>/dev/null || true)"
    if [[ -z "$status" || "$status" == "unknown" ]]; then
      if pgrep -x sing-box >/dev/null 2>&1; then
        status="active"
      else
        status="inactive"
      fi
    fi
    case "$status" in
      active)       status_text="$(green "● 运行中")" ;;
      inactive)     status_text="$(yellow "○ 已停止")" ;;
      activating)   status_text="$(yellow "◎ 启动中")" ;;
      deactivating) status_text="$(yellow "◎ 停止中")" ;;
      failed)       status_text="$(red "✗ 失败")" ;;
      *)            status_text="$(yellow "? ${status}")" ;;
    esac
    version="$("$bin" version 2>/dev/null | head -1 | sed 's/^.* //' || echo '?')"
    printf " sing-box %s | version: %s\\n" "$status_text" "$version"
  else
    printf " sing-box %s\\n" "$(yellow "未安装")"
  fi
}

install_singbox_only() {
  require_root
  local ans
  if command -v sing-box >/dev/null 2>&1 || [[ -x /usr/local/bin/sing-box ]] || [[ -x /etc/s-box/sing-box ]]; then
    yellow "检测到已安装 sing-box"
    read -r -p "是否卸载重新安装？[Y/n]: " ans
    if [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]; then
      yellow "正在卸载旧版本..."
      systemctl stop sing-box.service 2>/dev/null || true
      rm -f /usr/local/bin/sing-box /usr/local/bin/agsb /etc/s-box/sing-box
      rm -f /etc/systemd/system/sing-box.service
      systemctl daemon-reload 2>/dev/null || true
      green "旧版本已清理"
    else
      yellow "跳过安装，保持现有版本"
      if [[ -f "$INSTALL_SCRIPT" ]]; then
        rm -f /usr/local/bin/agsb 2>/dev/null || true
        ln -sf "$INSTALL_SCRIPT" /usr/local/bin/agsb 2>/dev/null || true
      else
        local sp
        sp="$(realpath "$0" 2>/dev/null || true)"
        [[ -n "$sp" ]] && ln -sf "$sp" /usr/local/bin/agsb 2>/dev/null || true
      fi
      green "快捷命令 agsb 已注册，输入 agsb 即可打开菜单"
      return
    fi
  fi
  install_sing_box
  if [[ -x "$SING_BOX_BIN" ]]; then
    if command -v agsb >/dev/null 2>&1; then
      rm -f /usr/local/bin/agsb
    fi
    if [[ -f "$INSTALL_SCRIPT" ]]; then
      ln -sf "$INSTALL_SCRIPT" /usr/local/bin/agsb 2>/dev/null || true
    else
      local sp
      sp="$(realpath "$0" 2>/dev/null || true)"
      [[ -n "$sp" ]] && ln -sf "$sp" /usr/local/bin/agsb 2>/dev/null || true
    fi
    green "快捷命令 agsb 已注册，输入 agsb 即可打开菜单"
    write_sing_box_service
    write_sing_box_service_tuning
    systemctl daemon-reload
    systemctl enable sing-box.service 2>/dev/null || true
    systemctl restart sing-box.service 2>/dev/null || true
    sleep 2
    if systemctl is-active --quiet sing-box.service 2>/dev/null; then
      green "安装成功，sing-box 已启动运行正常"
    else
      yellow "sing-box 已安装但尚无节点配置。"
      read -r -p "现在安装节点？[Y/n]: " install_node_now
      install_node_now="${install_node_now:-y}"
      if [[ "$install_node_now" =~ ^[Yy]$ ]]; then
        full_install
      fi
    fi
  fi
}

enable_fq_qdisc() {
  require_root
  local iface
  iface="$(ip route show default | awk '{print $5; exit}')"
  if [[ -z "$iface" ]]; then
    red "未检测到默认网卡"
    return
  fi
  if tc qdisc replace dev "$iface" root fq 2>/dev/null; then
    green "fq qdisc 已生效（${iface}）"
  else
    red "开启 fq 失败"
  fi
}

enable_cake_qdisc() {
  require_root
  local iface bw
  iface="$(ip route show default | awk '{print $5; exit}')"
  if [[ -z "$iface" ]]; then
    red "未检测到默认网卡"
    return
  fi
  bw="$(ethtool "$iface" 2>/dev/null | awk '/Speed:/ {print $2; exit}' || true)"
  [[ -n "$bw" ]] && bw="${bw}bit" || bw="1gbit"
  if tc qdisc replace dev "$iface" root cake bandwidth "$bw" 2>/dev/null; then
    green "cake qdisc 已生效（${iface}, bandwidth ${bw}）"
  else
    red "开启 cake 失败"
  fi
}

install_bbrv3_only() {
  require_root
  install_packages "0"
  install_bbrv3_kernel
  if [[ "${BBRV3_REBOOT_REQUIRED:-0}" == "1" ]]; then
    prompt_reboot_for_bbrv3
  fi
}

uninstall_singbox_only() {
  require_root
  local ans
  yellow "将卸载 sing-box 二进制、所有配置文件、分享文件和快捷命令 agsb"
  read -r -p "确认卸载？[y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]] || return
  systemctl disable --now sing-box.service 2>/dev/null || true
  systemctl disable --now "$ARGO_SERVICE" "$ARGO_REFRESH_SERVICE" "$ARGO_REFRESH_TIMER" "$ARGO_REFRESH_PATH" "$SUB_SERVICE" 2>/dev/null || true
  clear_hy2_port_hopping_rules 2>/dev/null || true
  rm -f "$SING_BOX_BIN" /usr/local/bin/agsb
  rm -f "$SING_BOX_CFG"
  rm -f "/etc/systemd/system/${SING_BOX_SERVICE}"
  rm -rf "$SING_BOX_SERVICE_TUNING_DIR" "$SING_BOX_DIR" "$STATE_DIR"
  rm -f "$CLIENT_JSON" "$SHARE_TXT" "$SUB_RAW_TXT" "$SUB_B64_TXT" "$NODE_QR_PNG"
  rm -f "$HY2_CLIENT_YAML" "$HY2_CLIENT_OFFICIAL_YAML" "$HY2_CLIENT_SINGBOX_JSON" "$HY2_SHARE_TXT" "$HY2_SUB_RAW_TXT" "$HY2_SUB_NOHOP_RAW_TXT" "$HY2_SUB_B64_TXT" "$HY2_QR_PNG"
  rm -f "$ANYTLS_CLIENT_YAML" "$ANYTLS_SHARE_TXT" "$ANYTLS_SUB_RAW_TXT" "$ANYTLS_SUB_B64_TXT" "$ANYTLS_QR_PNG"
  rm -f "$SS2022_CLIENT_YAML" "$SS2022_SHARE_TXT" "$SS2022_SUB_RAW_TXT" "$SS2022_SUB_B64_TXT" "$SS2022_QR_PNG"
  rm -f "$ARGO_SHARE_TXT" "$ARGO_SUB_RAW_TXT" "$ARGO_SUB_B64_TXT" "$ARGO_QR_PNG" "$ARGO_BOOT_LOG"
  rm -f "$SUB_SERVER_SCRIPT" "$COMBO_SUB_RAW_TXT" "$COMBO_SUB_B64_TXT"
  rm -f "$INSTALL_SCRIPT"
  rm -rf /etc/s-box 2>/dev/null || true
  systemctl daemon-reload 2>/dev/null || true
  green "sing-box 及所有生成文件已卸载"
}


select_argo_edge_server() {
  load_state || true
  if [[ -n "${ARGO_EDGE_SERVER:-}" && "${ARGO_MULTI_EDGE:-}" == "1" ]]; then
    local yn
    echo
    cyan "已保存优选域名: ${ARGO_EDGE_SERVER}"
    read -r -p "重新选择？[y/N]: " yn
    if [[ -z "$yn" || ! "$yn" =~ ^[Yy]$ ]]; then
      green "保持当前优选域名"
      return 0
    fi
  fi
  local edge_choice
  local -a argo_all_domains=(
    "*.cf.090227.xyz#三网优选，CM维护（泛域名）"
    "www.visa.cn#Visa中国，必须带www"
    "mfa.gov.ua#乌克兰外交部"
    "www.shopify.com#Shopify企业级CDN"
    "store.ubi.com#Ubisoft育碧官方"
    "staticdelivery.nexusmods.com#NexusMods静态分发"
    "time.is#官方优选"
    "icook.hk#官方优选"
    "icook.tw#官方优选"
    "*.tencentapp.cn#三网优选，ktff维护"
    "cloudflare-dl.byoip.top#三网优选，NB优化"
    "cf.877774.xyz#三网优选，秋名山维护"
    "saas.sin.fan#三网优选，MIYU维护"
    "bestcf.030101.xyz#移动专属，Mingyu维护"
    "*.cloudflare.182682.xyz#WeTest.Vip维护"
    "cdn.2020111.xyz#收集自网络"
    "cdns.doon.eu.org#收集自网络"
    "cf.0sm.com#收集自网络"
    "cf.877771.xyz#收集自网络"
    "cf.900501.xyz#收集自网络"
    "cfip.1323123.xyz#收集自网络"
    "cfip.cfcdn.vip#收集自网络"
    "cfip.xxxxxxxx.tk#OTC维护"
    "cloudflare-ip.mofashi.ltd#收集自网络"
    "fn.130519.xyz#收集自网络"
    "freeyx.cloudflare88.eu.org#收集自网络"
    "nrt.xxxxxxxx.nyc.mn#收集自网络"
    "nrtcfdns.zone.id#收集自网络"
    "xn--b6gac.eu.org#收集自网络"
    "777.ai7777777.xyz#收集自网络"
  )
  local i d note
  echo
  cyan "========== CloudFlare 优选域名列表（来源 cf.090227.xyz）=========="
  echo
  cyan "提示：输入 93 先生成本地浏览器测速页面，测完回来再选域名"
  echo
  for i in "${!argo_all_domains[@]}"; do
    d="${argo_all_domains[$i]%%#*}"
    note="${argo_all_domains[$i]#*#}"
    printf " %2d) %-42s %s\n" "$((i+1))" "$d" "$note"
  done
  echo " 93) 生成本地浏览器测速页面"
  echo "  0) 返回"
  cyan "=============================================================="
  echo
  echo "可输入单个序号，或逗号分隔多个，例如: 1,11,12,14"
  echo "多选时会为每个域名生成独立 Argo 节点"
  # Check if browser submitted domains from speedtest page
  if [[ -f /etc/sing-box/node-info/selected_domains.txt && -s /etc/sing-box/node-info/selected_domains.txt ]]; then
    local saved_doms
    saved_doms="$(cat /etc/sing-box/node-info/selected_domains.txt)"
    if [[ -n "$saved_doms" ]]; then
      echo
      green "检测到浏览器提交的优选域名: ${saved_doms}"
      read -r -p "是否使用这些域名？[Y/n]: " use_saved
      if [[ -z "$use_saved" || "$use_saved" =~ ^[Yy]$ ]]; then
        # Convert saved domain names to their indices in argo_all_domains
        local dom_idx saved_dom dom i
        local saved_indices=""
        for saved_dom in $(echo "$saved_doms" | tr ',' ' '); do
          for i in "${!argo_all_domains[@]}"; do
            dom="${argo_all_domains[$i]%%#*}"
            dom="${dom#\*.}"
            if [[ "$dom" == "$saved_dom" ]]; then
              saved_indices="${saved_indices}$((i+1)),"
              break
            fi
          done
        done
        saved_indices="${saved_indices%,}"
        if [[ -n "$saved_indices" ]]; then
          edge_choice="$saved_indices"
          green "已自动选择序号: ${saved_indices}"
        fi
      fi
      rm -f /etc/sing-box/node-info/selected_domains.txt
    fi
  fi
  if [[ -z "${edge_choice:-}" ]]; then
    read -r -p "请选择 [默认: 2] (输入93生成测速页面): " edge_choice
    edge_choice="${edge_choice:-2}"
    if [[ "$edge_choice" == "93" ]]; then
      generate_speedtest_html
      echo
      yellow "测速完成后回到这里输入优选域名序号"
      read -r -p "请选择 [默认: 2]: " edge_choice
      edge_choice="${edge_choice:-2}"
    fi
  fi

  local -a selected_domains=()
  local -a selected_notes=()
  local sel token idx
  IFS=',' read -ra tokens <<< "$edge_choice"
  for token in "${tokens[@]}"; do
    token="$(printf '%s' "$token" | tr -d ' ')"
    [[ -z "$token" || "$token" == "0" ]] && continue
    if [[ "$token" =~ ^[0-9]+$ ]] && (( token >= 1 && token <= 30 )); then
      idx=$((token - 1))
      d="${argo_all_domains[$idx]%%#*}"
      note="${argo_all_domains[$idx]#*#}"
      d="${d#\*.}"
      selected_domains+=("$d")
      selected_notes+=("$note")
    fi
  done

  if [[ "${#selected_domains[@]}" -eq 0 ]]; then
    yellow "未选择有效域名，使用默认 www.visa.cn"
    selected_domains=("www.visa.cn")
    selected_notes=("Visa中国（默认）")
  fi

  echo
  cyan "已选择 ${#selected_domains[@]} 个优选域名："
  for i in "${!selected_domains[@]}"; do
    printf "  %d) %s - %s\n" "$((i+1))" "${selected_domains[$i]}" "${selected_notes[$i]}"
  done

  # 测速
  echo
  yellow "--- 测速中（HTTPS 握手延迟）---"
  local -a argo_domain_latency=()
  local lat lat_ms best_idx=0 best_ms=999999
  for i in "${!selected_domains[@]}"; do
    d="${selected_domains[$i]}"
    printf "  测速 %s ... " "$d"
    lat="$(curl -o /dev/null -sS --connect-timeout 5 --max-time 15 -w "%{time_total}" "https://$d/" 2>/dev/null || echo "999")"
    lat_ms="$(awk -v t="$lat" 'BEGIN {printf "%d", t*1000}' 2>/dev/null)"
    echo "${lat_ms} ms"
    argo_domain_latency+=("$lat_ms")
    if (( lat_ms < best_ms )); then
      best_ms="$lat_ms"
      best_idx="$i"
    fi
  done

  echo
  green "最低延迟: ${selected_domains[$best_idx]} (${best_ms} ms)"

  ARGO_EDGE_SERVERS=("${selected_domains[@]}")
  ARGO_EDGE_NOTES=("${selected_notes[@]}")
  ARGO_EDGE_SERVER="${selected_domains[$best_idx]}"
  ARGO_MULTI_EDGE="1"
  save_state
  refresh_subscription_service
  green "优选域名已更新，订阅已刷新"
}

argo_speedtest_and_select() {
  select_argo_edge_server
}



tune_proxy_machine() {
  require_root
  local tune_choice ssh_host rtt i url lat lat_ms best_url best_latency speed_urls speed_labels best_buffer best_buffer_bytes
  echo
  cyan "========== 代理机器调优 =========="
  echo "1) 自动测速选优（推荐）"
  echo "2) 仅查看当前 SSH 延迟"
  echo "0) 返回"
  read -r -p "请选择 [默认: 1]: " tune_choice
  tune_choice="${tune_choice:-1}"
  [[ "$tune_choice" == "0" ]] && return
  echo
  yellow "--- SSH 延迟检测 ---"
  ssh_host="${SSH_CONNECTION%% *}"
  if [[ -z "$ssh_host" ]]; then
    ssh_host="$(curl -4 -fsS --connect-timeout 5 --max-time 10 https://api.ipify.org 2>/dev/null || true)"
    rtt="N/A"
  else
    rtt="$(ping -c 3 -W 2 "$ssh_host" 2>/dev/null | tail -1 | awk -F/ '{print int($5)}' 2>/dev/null || echo "N/A")"
  fi
  echo "SSH 连接端: ${ssh_host:-unable to detect}"
  echo "延迟 RTT:   ${rtt} ms"
  echo
  [[ "$tune_choice" != "1" ]] && return
  yellow "--- 国内友好测速点检测（选延迟最低的） ---"
  speed_urls=("https://www.visa.com" "https://www.speedtest.net" "https://time.cloudflare.com")
  speed_labels=("www.visa.com" "www.speedtest.net" "time.cloudflare.com")
  best_latency="999999"
  for i in "${!speed_urls[@]}"; do
    url="${speed_urls[$i]}"
    label="${speed_labels[$i]}"
    printf "  测速 %s ... " "$label"
    lat="$(curl -o /dev/null -sS --connect-timeout 5 --max-time 15 -w "%{time_total}" "$url" 2>/dev/null || echo "999")"
    lat_ms="$(awk -v t="$lat" 'BEGIN {printf "%d", t*1000}' 2>/dev/null)"
    echo "${lat_ms} ms"
    if [[ "$lat_ms" -lt "$best_latency" ]]; then
      best_latency="$lat_ms"
      best_url="$label"
    fi
  done
  echo
  if [[ -n "$best_url" && "$best_latency" -lt 999999 ]]; then
    green "最佳测速点: ${best_url} (${best_latency} ms)"
    yellow "正在根据延迟应用最优 TCP 参数..."
    best_buffer="$(calculate_bbr_buffer_mb)"
    best_buffer_bytes=$((best_buffer * 1024 * 1024))
    mkdir -p "$(dirname "$BBR_SYSCTL")"
    cat > "$BBR_SYSCTL" <<EOF
# Generated by ${APP_NAME} auto-tune
net.core.default_qdisc = fq
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65536
net.core.rmem_max = ${best_buffer_bytes}
net.core.wmem_max = ${best_buffer_bytes}
net.ipv4.tcp_rmem = 4096 87380 ${best_buffer_bytes}
net.ipv4.tcp_wmem = 4096 65536 ${best_buffer_bytes}
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_adv_win_scale = -2
net.ipv4.udp_rmem_min = 4096
net.ipv4.udp_wmem_min = 4096
net.core.udp_mem = ${best_buffer_bytes} $((best_buffer_bytes / 4))
EOF
  fi
  if sysctl -p "$BBR_SYSCTL" >/dev/null 2>&1; then
    green "TCP 参数已应用"
  else
    yellow "部分参数应用失败，请检查系统兼容性"
  fi
  green "代理机器调优完成"
}

menu() {
  while true; do
    clear
    cat <<EOMENU
=============================================
      五合一协议（Vless/Hy2/Tuic/Anytls/Vmess+Argo）
=============================================
$(detect_sing_box)
 快捷命令 agsb
=============================================
 1) 安装sing-box
 2) 安装节点
 3) 续签证书
 4) 节点信息
 5) 服务状态
 6) 重启服务
 7) 日志
 8) 重置参数
 9) 恢复备份
10) 卸载
93) 本地浏览器测速（推荐）
94) Argo优选域名（测速+切换）
95) 代理机器调优（测速选优）
96) 开启 fq qdisc
97) 开启 cake qdisc
98) 安装 BBRv3 内核
99) 卸载 sing-box
 0) 退出
=============================================
EOMENU
    read -r -p "请选择 [0-99]: " choice
    case "$choice" in
      1) install_singbox_only; pause ;;
      2) full_install; pause ;;
      3) renew_cert; pause ;;
      4) show_node_info; pause ;;
      5) show_status; pause ;;
      6) restart_services; pause ;;
      7) show_logs; pause ;;
      8) reset_menu; pause ;;
      9) restore_latest_backup; pause ;;
      10) uninstall_menu; pause ;;
      93) generate_speedtest_html; pause ;;
      94) argo_speedtest_and_select; pause ;;
      95) tune_proxy_machine; pause ;;
      96) enable_fq_qdisc; pause ;;
      97) enable_cake_qdisc; pause ;;
      98) install_bbrv3_only; pause ;;
      99) uninstall_singbox_only; pause ;;
      0) exit 0 ;;
      *) yellow "无效选项"; pause ;;
    esac
  done
}

main() {
  case "${1:-menu}" in
    -h|--help|help)
      show_help
      ;;
    -v|--version|version)
      echo "${APP_NAME} ${APP_VERSION}"
      ;;
    --refresh-argo-subscription)
      refresh_argo_subscription_once "${2:-manual}"
      ;;
    --wait-tcp)
      wait_tcp_endpoint "${2:-}" "${3:-}" "${4:-45}"
      ;;
    menu)
      require_root
      require_supported_os
      menu
      ;;
    *)
      red "未知参数: $1"
      show_help
      exit 1
      ;;
  esac
}
