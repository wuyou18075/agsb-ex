#!/usr/bin/env bash
# =============================================================================
# base.sh - Core utilities: state, ports, backup, network
# =============================================================================

apply_node_prefix() {
  NODE_NAME_VLESS="${NODE_PREFIX:+${NODE_PREFIX}-}${NODE_NAME_VLESS_BASE}"
  NODE_NAME_HY2="${NODE_PREFIX:+${NODE_PREFIX}-}${NODE_NAME_HY2_BASE}"
  NODE_NAME_ANYTLS="${NODE_PREFIX:+${NODE_PREFIX}-}${NODE_NAME_ANYTLS_BASE}"
  NODE_NAME_ARGO="${NODE_PREFIX:+${NODE_PREFIX}-}${NODE_NAME_ARGO_BASE}"
  NODE_NAME_SS2022="${NODE_PREFIX:+${NODE_PREFIX}-}${NODE_NAME_SS2022_BASE}"
  NODE_NAME_TUIC="${NODE_PREFIX:+${NODE_PREFIX}-}${NODE_NAME_TUIC_BASE}"
  NODE_NAME_VMESS="${NODE_PREFIX:+${NODE_PREFIX}-}${NODE_NAME_VMESS_BASE}"
}
ARGO_CLIENT_FINGERPRINT="chrome"
ARGO_EDGE_SERVER="www.visa.com"
ARGO_NAMED_DEFAULT_LOCAL_PORT="18080"

STATE_DIR="/etc/${APP_NAME}"
STATE_FILE="${STATE_DIR}/install.env"
ARGO_BOOT_LOG="${STATE_DIR}/argo.log"

SING_BOX_BIN="/usr/local/bin/sing-box"
SING_BOX_DIR="/etc/sing-box"
SING_BOX_CFG="${SING_BOX_DIR}/config.json"
SING_BOX_SERVICE="sing-box.service"

XRAY_CFG="/usr/local/etc/xray/config.json"

NGINX_CFG="/etc/nginx/conf.d/${APP_NAME}.conf"
NGINX_REALIP_CFG="/etc/nginx/conf.d/${APP_NAME}-realip.conf"

WEB_ROOT="/var/www/${APP_NAME}"
SSL_DIR="/etc/ssl/${APP_NAME}"

CLIENT_JSON="/etc/sing-box/node-info/client.json"
SHARE_TXT="/etc/sing-box/node-info/share.txt"
SUB_RAW_TXT="/etc/sing-box/node-info/subscription-raw.txt"
SUB_B64_TXT="/etc/sing-box/node-info/subscription-base64.txt"
NODE_QR_PNG="/etc/sing-box/node-info/node-qr.png"
COMBO_SUB_RAW_TXT="/etc/sing-box/node-info/all-subscription-raw.txt"
COMBO_SUB_B64_TXT="/etc/sing-box/node-info/all-subscription-base64.txt"

HYSTERIA_CFG="/etc/hysteria/config.yaml"
HY2_CLIENT_YAML="/etc/sing-box/node-info/hy2-client.yaml"
HY2_CLIENT_OFFICIAL_YAML="/etc/sing-box/node-info/hy2-official-client.yaml"
HY2_CLIENT_SINGBOX_JSON="/etc/sing-box/node-info/hy2-singbox-client.json"
HY2_SHARE_TXT="/etc/sing-box/node-info/hy2-share.txt"
HY2_SUB_RAW_TXT="/etc/sing-box/node-info/hy2-subscription-raw.txt"
HY2_SUB_NOHOP_RAW_TXT="/etc/sing-box/node-info/hy2-subscription-nohop-raw.txt"
HY2_SUB_B64_TXT="/etc/sing-box/node-info/hy2-subscription-base64.txt"
HY2_QR_PNG="/etc/sing-box/node-info/hy2-node-qr.png"
HY2_SERVICE="hysteria-server.service"
HY2_URI_ALPN_COMPAT="h3,h2,http/1.1"
HY2_TLS_SNI=""
HY2_CERT_FILE="/etc/hysteria/cert.crt"
HY2_KEY_FILE="/etc/hysteria/private.key"
HY2_CLIENT_UP_MBPS="100"
HY2_CLIENT_DOWN_MBPS="1000"

MIHOMO_BIN="/usr/local/bin/mihomo"
MIHOMO_ANYTLS_DIR="/etc/mihomo-anytls"
MIHOMO_ANYTLS_CFG="${MIHOMO_ANYTLS_DIR}/config.yaml"
MIHOMO_ANYTLS_CERT="${MIHOMO_ANYTLS_DIR}/fullchain.cer"
MIHOMO_ANYTLS_KEY="${MIHOMO_ANYTLS_DIR}/private.key"
MIHOMO_ANYTLS_SERVICE="mihomo-anytls.service"
MIHOMO_GITHUB_API="https://api.github.com/repos/MetaCubeX/mihomo/releases/latest"
ANYTLS_CLIENT_YAML="/etc/sing-box/node-info/anytls-clash-client.yaml"
ANYTLS_SHARE_TXT="/etc/sing-box/node-info/anytls-share.txt"
ANYTLS_SUB_RAW_TXT="/etc/sing-box/node-info/anytls-subscription-raw.txt"
ANYTLS_SUB_B64_TXT="/etc/sing-box/node-info/anytls-subscription-base64.txt"
ANYTLS_QR_PNG="/etc/sing-box/node-info/anytls-node-qr.png"

MIHOMO_SS2022_DIR="/etc/mihomo-ss2022"
MIHOMO_SS2022_CFG="${MIHOMO_SS2022_DIR}/config.yaml"
MIHOMO_SS2022_SERVICE="mihomo-ss2022.service"
SS2022_CIPHER="2022-blake3-aes-256-gcm"
SS2022_CLIENT_YAML="/etc/sing-box/node-info/ss2022-clash-client.yaml"
SS2022_SHARE_TXT="/etc/sing-box/node-info/ss2022-share.txt"
SS2022_SUB_RAW_TXT="/etc/sing-box/node-info/ss2022-subscription-raw.txt"
SS2022_SUB_B64_TXT="/etc/sing-box/node-info/ss2022-subscription-base64.txt"
SS2022_QR_PNG="/etc/sing-box/node-info/ss2022-node-qr.png"

SUBSCRIPTION_DIR="${STATE_DIR}/subscription"
SUB_URI_RAW_TXT="${SUBSCRIPTION_DIR}/raw.txt"
SUB_URI_B64_TXT="${SUBSCRIPTION_DIR}/base64.txt"
SUB_CLASH_YAML="${SUBSCRIPTION_DIR}/clash.yaml"
SUB_CLASH_STABLE_YAML="${SUBSCRIPTION_DIR}/clash-stable.yaml"
SUB_INDEX_HTML="${SUBSCRIPTION_DIR}/index.html"
SUB_SERVER_SCRIPT="/usr/local/bin/${APP_NAME}-subscription-server.py"
SUB_SERVICE="${APP_NAME}-subscription.service"

CLOUDFLARED_BIN="/usr/local/bin/cloudflared"
CLOUDFLARED_GITHUB_API="https://api.github.com/repos/cloudflare/cloudflared/releases/latest"
ARGO_SERVICE="${APP_NAME}-argo.service"
ARGO_REFRESH_SERVICE="${APP_NAME}-argo-refresh.service"
ARGO_REFRESH_TIMER="${APP_NAME}-argo-refresh.timer"
ARGO_REFRESH_PATH="${APP_NAME}-argo-refresh.path"
ARGO_SHARE_TXT="/etc/sing-box/node-info/argo-share.txt"
ARGO_SUB_RAW_TXT="/etc/sing-box/node-info/argo-subscription-raw.txt"
ARGO_SUB_B64_TXT="/etc/sing-box/node-info/argo-subscription-base64.txt"
ARGO_QR_PNG="/etc/sing-box/node-info/argo-node-qr.png"

BACKUP_ROOT="/etc/sing-box/node-info/backup"
BBR_SYSCTL="/etc/sysctl.d/99-${APP_NAME}-bbr.conf"
DUAL_STACK_SYSCTL="/etc/sysctl.d/99-${APP_NAME}-dual-stack.conf"
XANMOD_KEYRING="/etc/apt/keyrings/xanmod-archive-keyring.gpg"
XANMOD_APT_LIST="/etc/apt/sources.list.d/xanmod-release.list"
XANMOD_BBRV3_PACKAGE="linux-xanmod-x64v3"
XANMOD_BBRV3_FALLBACK_PACKAGE="linux-xanmod-lts-x64v3"
XRAY_SERVICE_TUNING_DIR="/etc/systemd/system/xray.service.d"
XRAY_SERVICE_TUNING="${XRAY_SERVICE_TUNING_DIR}/10-${APP_NAME}-limits.conf"
SING_BOX_SERVICE_TUNING_DIR="/etc/systemd/system/${SING_BOX_SERVICE}.d"
SING_BOX_SERVICE_TUNING="${SING_BOX_SERVICE_TUNING_DIR}/10-${APP_NAME}-limits.conf"
MIHOMO_ANYTLS_SERVICE_TUNING_DIR="/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}.d"
MIHOMO_ANYTLS_SERVICE_TUNING="${MIHOMO_ANYTLS_SERVICE_TUNING_DIR}/10-${APP_NAME}-limits.conf"
MIHOMO_SS2022_SERVICE_TUNING_DIR="/etc/systemd/system/${MIHOMO_SS2022_SERVICE}.d"
MIHOMO_SS2022_SERVICE_TUNING="${MIHOMO_SS2022_SERVICE_TUNING_DIR}/10-${APP_NAME}-limits.conf"

DEFAULT_TARGET_PORT="8443"
TARGET_PORT="$DEFAULT_TARGET_PORT"

ACME_SH="/root/.acme.sh/acme.sh"

DOMAIN=""
EMAIL=""
UUID=""
XHTTP_PATH=""
SHORT_ID=""
PRIVATE_KEY=""
PUBLIC_KEY=""

DEFAULT_JSHOOK="123"

get_effective_jshook() {
  printf '%s' "${JSHOOK:-${DEFAULT_JSHOOK}}"
}

curl_fsSL() {
  local url="$1"
  shift
  curl -fsSL --connect-timeout 15 --retry 3 --retry-delay 2 \
    -H "jshook: $(get_effective_jshook)" "$url" "$@"
}

github_api_json() {
  local url="$1" label="${2:-GitHub API}" tmp attempt max_attempts=3

  tmp="$(mktemp)"
  for attempt in $(seq 1 "$max_attempts"); do
    if curl_fsSL "$url" -o "$tmp" && jq -e . "$tmp" >/dev/null 2>&1; then
      cat "$tmp"
      rm -f "$tmp"
      return 0
    fi

    if [[ "$attempt" -lt "$max_attempts" ]]; then
      yellow "${label} 返回失败或 JSON 不完整，${attempt}/${max_attempts}，稍后重试..." >&2
      sleep 2
    fi
  done

  rm -f "$tmp"
  red "${label} 获取失败，请稍后重试，或检查 VPS 到 api.github.com 的网络。" >&2
  return 1
}
INSTALL_MODE="fake"
LAST_BACKUP_DIR=""
HY2_ENABLED="0"
HY2_PORT=""
HY2_PASSWORD=""
HY2_OBFS_ENABLED="0"
HY2_OBFS_PASSWORD=""
HY2_MASQUERADE_URL="https://maimai.sega.jp"
HY2_SERVER_ADDR=""
HY2_TLS_SNI=""
HY2_PORT_RANGE=""
ANYTLS_ENABLED="0"
ANYTLS_PORT=""
ANYTLS_PASSWORD=""
ANYTLS_SERVER_ADDR=""
ANYTLS_TLS_SNI=""
SS2022_ENABLED="0"
SS2022_PORT=""
SS2022_PASSWORD=""
SS2022_SERVER_ADDR=""
VMESS_ENABLED="0"
VMESS_PORT=""
VMESS_UUID=""
VMESS_WS_PATH=""
VMESS_TLS_ENABLED="0"
VMESS_SERVER_ADDR=""
TUIC_ENABLED="0"
TUIC_PORT=""
TUIC_PASSWORD=""
TUIC_TLS_SNI=""
SUB_ENABLED="0"
SUB_PORT=""
SUB_PATH=""
ARGO_ENABLED="0"
ARGO_LOCAL_PORT=""
ARGO_UUID=""
ARGO_WS_PATH=""
ARGO_DOMAIN=""
ARGO_TUNNEL_MODE="quick"
ARGO_FIXED_DOMAIN=""
ARGO_TUNNEL_TOKEN=""
ARGO_PROTOCOL="http2"
ARGO_EDGE_IP_VERSION="auto"
BBRV3_REBOOT_REQUIRED="0"
SELF_SIGN_CERT="0"
SING_BOX_VERSION_PRINTED="0"
ACME_HTTP01_HAS_AAAA="0"
DIRECT_SERVER_ADDR=""
declare -a ACME_STANDALONE_LISTEN_ARGS=()
AUTO_ROLLBACK_ARMED="0"
ROLLBACK_IN_PROGRESS="0"

green()  { echo -e "\033[32m$*\033[0m"; }
yellow() { echo -e "\033[33m$*\033[0m"; }
red()    { echo -e "\033[31m$*\033[0m"; }
cyan()   { echo -e "\033[36m$*\033[0m"; }

on_error() {
  local exit_code=$?

  trap - ERR
  red "脚本执行失败，行号: ${BASH_LINENO[0]:-unknown}，退出码: ${exit_code}"

  if [[ "${AUTO_ROLLBACK_ARMED}" == "1" && "${ROLLBACK_IN_PROGRESS}" != "1" && -n "${LAST_BACKUP_DIR}" && -d "${LAST_BACKUP_DIR}" ]]; then
    yellow "检测到安装/维护过程中断，尝试自动回滚到: ${LAST_BACKUP_DIR}"
    ROLLBACK_IN_PROGRESS="1"
    if restore_backup_dir "$LAST_BACKUP_DIR"; then
      green "自动回滚完成"
    else
      red "自动回滚失败，请手动检查备份: ${LAST_BACKUP_DIR}"
    fi
  fi

  exit "$exit_code"
}

trap on_error ERR

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    red "请用 root 运行"
    exit 1
  fi
}

require_supported_os() {
  if [[ ! -r /etc/os-release ]]; then
    red "无法识别系统版本"
    exit 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  if ! command -v apt-get >/dev/null 2>&1; then
    red "当前脚本仅支持 Debian / Ubuntu（apt 系）"
    exit 1
  fi

  case "${ID:-}:${ID_LIKE:-}" in
    debian:*|ubuntu:*|*:debian*)
      ;;
    *)
      yellow "检测到系统: ${PRETTY_NAME:-unknown}"
      yellow "当前脚本按 Debian / Ubuntu 适配，请自行确认兼容性。"
      ;;
  esac
}

install_self_script() {
  local src src_real target_real tmp_file

  mkdir -p "$(dirname "$INSTALL_SCRIPT")"
  src="${BASH_SOURCE[0]:-$0}"

  case "$src" in
    /dev/fd/*|/proc/self/fd/*|/proc/[0-9]*/fd/*)
      src=""
      ;;
  esac

  if [[ -n "$src" && -r "$src" ]]; then
    src_real="$(realpath "$src" 2>/dev/null || printf '%s' "$src")"
    target_real="$(realpath "$INSTALL_SCRIPT" 2>/dev/null || printf '%s' "$INSTALL_SCRIPT")"
    if [[ "$src_real" == "$target_real" ]]; then
      chmod 0755 "$INSTALL_SCRIPT" 2>/dev/null || true
      return 0
    fi
    if install -m 0755 "$src" "$INSTALL_SCRIPT" 2>/dev/null; then
      return 0
    fi
  fi

  if command -v curl >/dev/null 2>&1; then
    tmp_file="$(mktemp)"
    if curl -fsSL "$INSTALL_SCRIPT_URL" -o "$tmp_file" 2>/dev/null; then
      install -m 0755 "$tmp_file" "$INSTALL_SCRIPT"
      rm -f "$tmp_file"
      return 0
    fi
    rm -f "$tmp_file"
  fi

  yellow "未能写入维护脚本副本 ${INSTALL_SCRIPT}，Argo 开机自动刷新将暂不可用。"
  return 1
}

load_state() {
  [[ -f "$STATE_FILE" ]] || return 1
  # shellcheck disable=SC1090
  source "$STATE_FILE"
  normalize_loaded_state
}

normalize_loaded_state() {
  [[ -n "${DOMAIN:-}" ]] || return 0

  apply_node_prefix
  normalize_argo_tunnel_state

  if [[ "${HY2_ENABLED:-0}" == "1" ]]; then
    [[ -n "${HY2_SERVER_ADDR:-}" ]] || HY2_SERVER_ADDR="$DOMAIN"
    [[ -n "${HY2_TLS_SNI:-}" ]] || HY2_TLS_SNI="$DOMAIN"
  fi

  if [[ "${ANYTLS_ENABLED:-0}" == "1" ]]; then
    [[ -n "${ANYTLS_SERVER_ADDR:-}" ]] || ANYTLS_SERVER_ADDR="$DOMAIN"
    [[ -n "${ANYTLS_TLS_SNI:-}" ]] || ANYTLS_TLS_SNI="$DOMAIN"
  fi

  if [[ "${SS2022_ENABLED:-0}" == "1" ]]; then
    [[ -n "${SS2022_SERVER_ADDR:-}" ]] || SS2022_SERVER_ADDR="$DOMAIN"
  fi
}

normalize_argo_host() {
  printf '%s' "$1" \
    | sed -E 's#^[[:space:]]+##; s#[[:space:]]+$##; s#^https?://##; s#/.*$##; s#:$##' \
    | tr '[:upper:]' '[:lower:]'
}

normalize_argo_tunnel_state() {
  case "${ARGO_TUNNEL_MODE:-quick}" in
    named|fixed) ARGO_TUNNEL_MODE="named" ;;
    *) ARGO_TUNNEL_MODE="quick" ;;
  esac

  if [[ "$ARGO_TUNNEL_MODE" == "named" ]]; then
    ARGO_FIXED_DOMAIN="$(normalize_argo_host "${ARGO_FIXED_DOMAIN:-${ARGO_DOMAIN:-}}")"
    if [[ -n "$ARGO_FIXED_DOMAIN" ]]; then
      ARGO_DOMAIN="$ARGO_FIXED_DOMAIN"
    fi
  else
    ARGO_FIXED_DOMAIN=""
    ARGO_TUNNEL_TOKEN=""
  fi
}

argo_is_named_tunnel() {
  normalize_argo_tunnel_state
  [[ "$ARGO_TUNNEL_MODE" == "named" && -n "${ARGO_FIXED_DOMAIN:-}" && -n "${ARGO_TUNNEL_TOKEN:-}" ]]
}

has_vless_install() {
  [[ -n "${UUID:-}" && -n "${PUBLIC_KEY:-}" && -f "$SING_BOX_CFG" ]]
}

has_hy2_install() {
  [[ "${HY2_ENABLED:-0}" == "1" && -n "${HY2_PASSWORD:-}" && -f "$SING_BOX_CFG" ]]
}

has_anytls_install() {
  [[ "${ANYTLS_ENABLED:-0}" == "1" && -n "${ANYTLS_PASSWORD:-}" && -f "$SING_BOX_CFG" ]]
}

has_ss2022_install() {
  [[ "${SS2022_ENABLED:-0}" == "1" && -n "${SS2022_PASSWORD:-}" && -f "$SING_BOX_CFG" ]]
}

has_subscription_service() {
  [[ "${SUB_ENABLED:-0}" == "1" && -n "${SUB_PORT:-}" && -n "${SUB_PATH:-}" ]]
}

has_argo_install() {
  [[ "${ARGO_ENABLED:-0}" == "1" && -n "${ARGO_UUID:-}" && -n "${ARGO_WS_PATH:-}" && -n "${ARGO_LOCAL_PORT:-}" ]]
}

has_sing_box_protocol_install() {
  has_vless_install || has_vmess_install || has_hy2_install || has_anytls_install || has_ss2022_install || has_argo_install || has_tuic_install
}

clear_vless_state_for_profile() {
  UUID=""
  XHTTP_PATH=""
  SHORT_ID=""
  PRIVATE_KEY=""
  PUBLIC_KEY=""
  rm -f "$CLIENT_JSON" "$SHARE_TXT" "$SUB_RAW_TXT" "$SUB_B64_TXT" "$NODE_QR_PNG"
  cleanup_generated_nginx_files
}

clear_hy2_state_for_profile() {
  clear_hy2_port_hopping_rules
  systemctl disable --now "$HY2_SERVICE" >/dev/null 2>&1 || true
  rm -rf /etc/hysteria
  rm -f "$HY2_CLIENT_YAML" "$HY2_CLIENT_OFFICIAL_YAML" "$HY2_CLIENT_SINGBOX_JSON" "$HY2_SHARE_TXT" "$HY2_SUB_RAW_TXT" "$HY2_SUB_NOHOP_RAW_TXT" "$HY2_SUB_B64_TXT" "$HY2_QR_PNG"
  HY2_ENABLED="0"
  HY2_PORT=""
  HY2_PORT_RANGE=""
  HY2_PASSWORD=""
  HY2_OBFS_ENABLED="0"
  HY2_OBFS_PASSWORD=""
  HY2_SERVER_ADDR=""
  HY2_TLS_SNI=""
}

clear_anytls_state_for_profile() {
  systemctl disable --now "$MIHOMO_ANYTLS_SERVICE" >/dev/null 2>&1 || true
  rm -rf "$MIHOMO_ANYTLS_DIR"
  rm -f "/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}" "$ANYTLS_CLIENT_YAML" "$ANYTLS_SHARE_TXT" "$ANYTLS_SUB_RAW_TXT" "$ANYTLS_SUB_B64_TXT" "$ANYTLS_QR_PNG"
  ANYTLS_ENABLED="0"
  ANYTLS_PORT=""
  ANYTLS_PASSWORD=""
  ANYTLS_SERVER_ADDR=""
  ANYTLS_TLS_SNI=""
}

clear_ss2022_state_for_profile() {
  systemctl disable --now "$MIHOMO_SS2022_SERVICE" >/dev/null 2>&1 || true
  rm -rf "$MIHOMO_SS2022_DIR"
  rm -f "/etc/systemd/system/${MIHOMO_SS2022_SERVICE}" "$SS2022_CLIENT_YAML" "$SS2022_SHARE_TXT" "$SS2022_SUB_RAW_TXT" "$SS2022_SUB_B64_TXT" "$SS2022_QR_PNG"
  SS2022_ENABLED="0"
  SS2022_PORT=""
  SS2022_PASSWORD=""
  SS2022_SERVER_ADDR=""
}

clear_argo_state_for_profile() {
  systemctl disable --now "$ARGO_REFRESH_PATH" "$ARGO_REFRESH_TIMER" "$ARGO_REFRESH_SERVICE" "$ARGO_SERVICE" >/dev/null 2>&1 || true
  rm -f "/etc/systemd/system/${ARGO_SERVICE}" "/etc/systemd/system/${ARGO_REFRESH_SERVICE}" "/etc/systemd/system/${ARGO_REFRESH_TIMER}" "/etc/systemd/system/${ARGO_REFRESH_PATH}" \
    "$ARGO_SHARE_TXT" "$ARGO_SUB_RAW_TXT" "$ARGO_SUB_B64_TXT" "$ARGO_QR_PNG" "$ARGO_BOOT_LOG"
  ARGO_ENABLED="0"
  ARGO_LOCAL_PORT=""
  ARGO_UUID=""
  ARGO_WS_PATH=""
  ARGO_DOMAIN=""
  ARGO_TUNNEL_MODE="quick"
  ARGO_FIXED_DOMAIN=""
  ARGO_TUNNEL_TOKEN=""
  ARGO_PROTOCOL="http2"
  ARGO_EDGE_IP_VERSION="auto"
}

apply_install_profile_selection() {
  local removed=0

  if [[ "$INSTALL_WANT_VLESS" != "1" && ( -n "${UUID:-}" || -n "${PUBLIC_KEY:-}" ) ]]; then
    clear_vless_state_for_profile
    removed=1
  fi
  if [[ "$INSTALL_WANT_HY2" != "1" && "${HY2_ENABLED:-0}" == "1" ]]; then
    clear_hy2_state_for_profile
    removed=1
  fi
  if [[ "$INSTALL_WANT_ANYTLS" != "1" && "${ANYTLS_ENABLED:-0}" == "1" ]]; then
    clear_anytls_state_for_profile
    removed=1
  fi
  if [[ "$INSTALL_WANT_SS2022" != "1" && "${SS2022_ENABLED:-0}" == "1" ]]; then
    clear_ss2022_state_for_profile
    removed=1
  fi
  if [[ "$INSTALL_WANT_ARGO" != "1" && "${ARGO_ENABLED:-0}" == "1" ]]; then
    clear_argo_state_for_profile
    removed=1
  fi
  if [[ "$INSTALL_WANT_TUIC" != "1" && "${TUIC_ENABLED:-0}" == "1" ]]; then
    clear_tuic_state_for_profile
    removed=1
  fi
  if [[ "$INSTALL_WANT_VMESS" != "1" && "${VMESS_ENABLED:-0}" == "1" ]]; then
    clear_vmess_state_for_profile
    removed=1
  fi

  if [[ "$removed" == "1" ]]; then
    systemctl daemon-reload >/dev/null 2>&1 || true
    yellow "已按本次选择清理未选协议的旧安装状态。"
  fi
}

save_state() {
  mkdir -p "$STATE_DIR"
  {
    printf 'DOMAIN=%q\n' "$DOMAIN"
    printf 'EMAIL=%q\n' "$EMAIL"
    printf 'UUID=%q\n' "$UUID"
    printf 'XHTTP_PATH=%q\n' "$XHTTP_PATH"
    printf 'SHORT_ID=%q\n' "$SHORT_ID"
    printf 'PRIVATE_KEY=%q\n' "$PRIVATE_KEY"
    printf 'PUBLIC_KEY=%q\n' "$PUBLIC_KEY"
    printf 'TARGET_PORT=%q\n' "$TARGET_PORT"
      printf 'INSTALL_MODE=%q\n' "$INSTALL_MODE"
      printf 'LAST_BACKUP_DIR=%q\n' "$LAST_BACKUP_DIR"
      printf 'HY2_ENABLED=%q\n' "$HY2_ENABLED"
      printf 'HY2_PORT=%q\n' "$HY2_PORT"
      printf 'HY2_PASSWORD=%q\n' "$HY2_PASSWORD"
      printf 'HY2_OBFS_ENABLED=%q\n' "$HY2_OBFS_ENABLED"
      printf 'HY2_OBFS_PASSWORD=%q\n' "$HY2_OBFS_PASSWORD"
      printf 'HY2_MASQUERADE_URL=%q\n' "$HY2_MASQUERADE_URL"
      printf 'HY2_SERVER_ADDR=%q\n' "$HY2_SERVER_ADDR"
      printf 'HY2_PORT_RANGE=%q\n' "$HY2_PORT_RANGE"
      printf 'HY2_TLS_SNI=%q\n' "$HY2_TLS_SNI"
      printf 'ANYTLS_ENABLED=%q\n' "$ANYTLS_ENABLED"
      printf 'ANYTLS_PORT=%q\n' "$ANYTLS_PORT"
      printf 'ANYTLS_PASSWORD=%q\n' "$ANYTLS_PASSWORD"
      printf 'ANYTLS_SERVER_ADDR=%q\n' "$ANYTLS_SERVER_ADDR"
      printf 'ANYTLS_TLS_SNI=%q\n' "$ANYTLS_TLS_SNI"
      printf 'SS2022_ENABLED=%q\n' "$SS2022_ENABLED"
      printf 'SS2022_PORT=%q\n' "$SS2022_PORT"
      printf 'SS2022_CIPHER=%q\n' "$SS2022_CIPHER"
      printf 'SS2022_PASSWORD=%q\n' "$SS2022_PASSWORD"
      printf 'SS2022_SERVER_ADDR=%q\n' "$SS2022_SERVER_ADDR"
      printf 'VMESS_ENABLED=%q\n' "$VMESS_ENABLED"
      printf 'VMESS_PORT=%q\n' "$VMESS_PORT"
      printf 'VMESS_UUID=%q\n' "$VMESS_UUID"
      printf 'VMESS_WS_PATH=%q\n' "$VMESS_WS_PATH"
      printf 'VMESS_TLS_ENABLED=%q\n' "$VMESS_TLS_ENABLED"
      printf 'VMESS_SERVER_ADDR=%q\n' "$VMESS_SERVER_ADDR"
      printf 'SUB_ENABLED=%q\n' "$SUB_ENABLED"
      printf 'SUB_PORT=%q\n' "$SUB_PORT"
      printf 'SUB_PATH=%q\n' "$SUB_PATH"
      printf 'ARGO_ENABLED=%q\n' "$ARGO_ENABLED"
      printf 'ARGO_LOCAL_PORT=%q\n' "$ARGO_LOCAL_PORT"
      printf 'ARGO_UUID=%q\n' "$ARGO_UUID"
      printf 'ARGO_WS_PATH=%q\n' "$ARGO_WS_PATH"
      printf 'ARGO_DOMAIN=%q\n' "$ARGO_DOMAIN"
      printf 'ARGO_TUNNEL_MODE=%q\n' "$ARGO_TUNNEL_MODE"
      printf 'ARGO_FIXED_DOMAIN=%q\n' "$ARGO_FIXED_DOMAIN"
      printf 'ARGO_TUNNEL_TOKEN=%q\n' "$ARGO_TUNNEL_TOKEN"
      printf 'ARGO_PROTOCOL=%q\n' "$ARGO_PROTOCOL"
      printf 'ARGO_EDGE_IP_VERSION=%q\n' "$ARGO_EDGE_IP_VERSION"
      printf 'ARGO_EDGE_SERVER=%q\n' "$ARGO_EDGE_SERVER"
      printf 'ARGO_MULTI_EDGE=%q\n' "${ARGO_MULTI_EDGE:-0}"
      printf 'ARGO_EDGE_INDEX=%q\n' "${ARGO_EDGE_INDEX:-0}"
      if [[ "${#ARGO_EDGE_SERVERS[@]}" -gt 0 ]]; then
        printf 'ARGO_EDGE_SERVERS=(%s)\n' "$(printf ' %q' "${ARGO_EDGE_SERVERS[@]}")"
      fi
      printf 'TUIC_ENABLED=%q\n' "$TUIC_ENABLED"
      printf 'TUIC_PORT=%q\n' "$TUIC_PORT"
      printf 'TUIC_PASSWORD=%q\n' "$TUIC_PASSWORD"
      printf 'TUIC_TLS_SNI=%q\n' "$TUIC_TLS_SNI"
      printf 'NODE_PREFIX=%q\n' "$NODE_PREFIX"
      printf 'SELF_SIGN_CERT=%q\n' "${SELF_SIGN_CERT:-0}"
    } > "$STATE_FILE"
  chmod 600 "$STATE_FILE"
}

arm_auto_rollback() {
  if [[ -n "$LAST_BACKUP_DIR" && -d "$LAST_BACKUP_DIR" ]]; then
    AUTO_ROLLBACK_ARMED="1"
  fi
}

disarm_auto_rollback() {
  AUTO_ROLLBACK_ARMED="0"
  ROLLBACK_IN_PROGRESS="0"
}

stop_common_services() {
  systemctl stop nginx 2>/dev/null || true
  systemctl stop apache2 2>/dev/null || true
  systemctl stop caddy 2>/dev/null || true
}

stop_all_related() {
  systemctl stop "$SING_BOX_SERVICE" 2>/dev/null || true
  systemctl stop xray 2>/dev/null || true
  systemctl stop "$HY2_SERVICE" 2>/dev/null || true
  systemctl stop "$MIHOMO_ANYTLS_SERVICE" 2>/dev/null || true
  systemctl stop "$MIHOMO_SS2022_SERVICE" 2>/dev/null || true
  systemctl stop "$SUB_SERVICE" 2>/dev/null || true
  systemctl stop "$ARGO_REFRESH_PATH" 2>/dev/null || true
  systemctl stop "$ARGO_REFRESH_TIMER" 2>/dev/null || true
  systemctl stop "$ARGO_REFRESH_SERVICE" 2>/dev/null || true
  systemctl stop "$ARGO_SERVICE" 2>/dev/null || true
  stop_common_services
}

port_in_use() {
  local port="$1"
  ss -ltn | awk '{print $4}' | grep -Eq "(:|\\])${port}$"
}

port_in_use_udp() {
  local port="$1"
  ss -lun | awk '{print $5}' | grep -Eq "(:|\\])${port}$"
}

show_port_usage() {
  local port="$1"
  ss -ltnp | grep -E "(:|\\])${port}\\b" || true
}

show_udp_port_usage() {
  local port="$1"
  ss -lunp | grep -E "(:|\\])${port}\\b" || true
}

port_used_by_nginx() {
  local port="$1"
  show_port_usage "$port" | grep -qi 'nginx'
}

port_used_by_common_web_service() {
  local port="$1"
  show_port_usage "$port" | grep -Eqi 'nginx|apache2|httpd|caddy'
}

udp_port_used_by_hysteria() {
  local port="$1"
  show_udp_port_usage "$port" | grep -Eqi 'hysteria'
}

prompt_port() {
  local var_name="$1" desc="$2" min="${3:-50000}" max="${4:-60000}" udp="${5:-0}" candidate
  read -r -p "请输入${desc}端口 [回车随机${min}-${max}]: " candidate
  if [[ -z "$candidate" ]]; then
    while :; do
      candidate="$(shuf -i "$min"-"$max" -n 1)"
      if [[ "$udp" == "2" ]]; then
        if ! port_in_use_udp "$candidate"; then break; fi
      elif [[ "$udp" == "1" ]]; then
        if ! port_in_use "$candidate" && ! port_in_use_udp "$candidate"; then break; fi
      else
        if ! port_in_use "$candidate"; then break; fi
      fi
    done
  else
    if [[ ! "$candidate" =~ ^[0-9]+$ ]] || (( candidate < 1 || candidate > 65535 )); then
      red "端口格式错误，跳过"
      return 1
    fi
    if port_in_use "$candidate"; then
      red "端口 ${candidate} 已被占用"
      return 1
    fi
    if [[ "$udp" != "0" ]] && port_in_use_udp "$candidate"; then
      red "端口 ${candidate} UDP 已被占用"
      return 1
    fi
  fi
  printf -v "$var_name" '%s' "$candidate" 2>/dev/null || eval "$var_name=\$candidate"
}

cycle_argo_edge_server() {
  if (( ${#ARGO_EDGE_SERVERS[@]} <= 1 )); then
    return
  fi
  ARGO_EDGE_INDEX="${ARGO_EDGE_INDEX:-0}"
  ARGO_EDGE_SERVER="${ARGO_EDGE_SERVERS[$ARGO_EDGE_INDEX]}"
  ARGO_EDGE_INDEX=$(( (ARGO_EDGE_INDEX + 1) % ${#ARGO_EDGE_SERVERS[@]} ))
}

pick_subscription_port() {
  prompt_port SUB_PORT "订阅" 50000 60000 || true
}

pick_argo_local_port() {
  local candidate preferred="${1:-}"

  if [[ -n "$preferred" ]] && ! port_in_use "$preferred"; then
    ARGO_LOCAL_PORT="$preferred"
    return 0
  fi

  while :; do
    candidate="$(shuf -i 2000-65000 -n 1)"
    if ! port_in_use "$candidate"; then
      ARGO_LOCAL_PORT="$candidate"
      return 0
    fi
  done
}

prompt_hy2_port_range() {
  prompt_port HY2_PORT "HY2" 50000 60000 1 || return 1
  local start end
  while :; do
    start="$(shuf -i 20000-59000 -n 1)"
    end="$((start + 999))"
    if [[ "$HY2_PORT" -ge "$start" && "$HY2_PORT" -le "$end" ]]; then
      continue
    fi
    HY2_PORT_RANGE="${start}-${end}"
    return 0
  done
}

clear_hy2_port_hopping_rules() {
  local iptables_range
  if [[ -z "${HY2_PORT:-}" || -z "${HY2_PORT_RANGE:-}" ]]; then
    return 0
  fi

  iptables_range="${HY2_PORT_RANGE/-/:}"
  iptables -t nat -D PREROUTING -p udp --dport "$iptables_range" -j DNAT --to-destination ":$HY2_PORT" >/dev/null 2>&1 || true
  ip6tables -t nat -D PREROUTING -p udp --dport "$iptables_range" -j DNAT --to-destination ":$HY2_PORT" >/dev/null 2>&1 || true
}

apply_hy2_port_hopping_rules() {
  local iptables_range
  if [[ -z "${HY2_PORT:-}" || -z "${HY2_PORT_RANGE:-}" ]]; then
    return 1
  fi

  clear_hy2_port_hopping_rules
  iptables_range="${HY2_PORT_RANGE/-/:}"
  iptables -t nat -A PREROUTING -p udp --dport "$iptables_range" -j DNAT --to-destination ":$HY2_PORT"
  ip6tables -t nat -A PREROUTING -p udp --dport "$iptables_range" -j DNAT --to-destination ":$HY2_PORT" >/dev/null 2>&1 || true
}


list_active_nginx_files() {
  {
    find /etc/nginx/conf.d -maxdepth 1 -type f -name '*.conf' 2>/dev/null || true
    find /etc/nginx/sites-enabled -maxdepth 1 \( -type f -o -type l \) 2>/dev/null | while IFS= read -r f; do
      realpath "$f" 2>/dev/null || true
    done
  } | awk 'NF && !seen[$0]++'
}

nginx_active_config_has_443() {
  local file
  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    if grep -Eq '^[[:space:]]*listen[[:space:]].*(^|[^0-9])443([[:space:];]|$)' "$file"; then
      return 0
    fi
  done < <(list_active_nginx_files)
  return 1
}

nginx_active_config_mentions_domain() {
  local file
  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    if grep -Eq "^[[:space:]]*server_name[[:space:]].*\\b${DOMAIN//./\\.}\\b" "$file"; then
      return 0
    fi
  done < <(list_active_nginx_files)
  return 1
}

nginx_active_config_has_target_port() {
  local file
  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    if grep -Eq "^[[:space:]]*listen[[:space:]].*(127\\.0\\.0\\.1:)?${TARGET_PORT}([[:space:];]|$)" "$file"; then
      return 0
    fi
  done < <(list_active_nginx_files)
  return 1
}

determine_install_mode() {
  local saved_mode=""

  if load_state; then
    saved_mode="${INSTALL_MODE:-}"
  fi

  INSTALL_MODE="fake"

  if [[ "$saved_mode" == "migrate" ]]; then
    INSTALL_MODE="migrate"
  fi

  if port_in_use 443; then
    if port_used_by_nginx 443; then
      INSTALL_MODE="migrate"
    else
      red "检测到 443 被非 nginx 服务占用，当前版本暂不支持自动迁移。"
      show_port_usage 443
      exit 1
    fi
  elif nginx_active_config_has_443; then
    INSTALL_MODE="migrate"
  fi

  if [[ "$INSTALL_MODE" == "migrate" ]]; then
    if nginx_active_config_has_target_port && ! nginx_active_config_has_443; then
      green "检测到 Nginx 已处于 127.0.0.1:${TARGET_PORT} 迁移状态，本次将跳过重复迁移"
    else
      green "检测到现有 Nginx HTTPS 站点，将尝试迁移到 127.0.0.1:${TARGET_PORT}"
    fi
    if ! nginx_active_config_mentions_domain; then
      yellow "未在当前 Nginx 有效配置中明确检测到域名 ${DOMAIN}"
      yellow "仍会继续迁移 443 站点，但请确认该域名确实指向当前站点。"
    fi
  else
    green "未检测到现有 Nginx 443 站点，将部署本地伪装站。"
  fi
}

backup_existing_files() {
  local ts copied=0
  ts="$(date +%Y%m%d-%H%M%S)"
  LAST_BACKUP_DIR="${BACKUP_ROOT}/${ts}"

  mkdir -p "$LAST_BACKUP_DIR"

  if [[ -d /etc/nginx ]]; then
    mkdir -p "$LAST_BACKUP_DIR/etc"
    cp -a /etc/nginx "$LAST_BACKUP_DIR/etc/"
    copied=1
  fi

  if [[ -f "$SING_BOX_CFG" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$SING_BOX_CFG")"
    cp -a "$SING_BOX_CFG" "$LAST_BACKUP_DIR$SING_BOX_CFG"
    copied=1
  fi

  if [[ -f "$XRAY_CFG" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$XRAY_CFG")"
    cp -a "$XRAY_CFG" "$LAST_BACKUP_DIR$XRAY_CFG"
    copied=1
  fi

  if [[ -d "$WEB_ROOT" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$WEB_ROOT")"
    cp -a "$WEB_ROOT" "$LAST_BACKUP_DIR$WEB_ROOT"
    copied=1
  fi

  if [[ -d "$SSL_DIR" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$SSL_DIR")"
    cp -a "$SSL_DIR" "$LAST_BACKUP_DIR$SSL_DIR"
    copied=1
  fi

  if [[ -f "$STATE_FILE" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$STATE_FILE")"
    cp -a "$STATE_FILE" "$LAST_BACKUP_DIR$STATE_FILE"
    copied=1
  fi

  if [[ -d /etc/hysteria ]]; then
    mkdir -p "$LAST_BACKUP_DIR/etc"
    cp -a /etc/hysteria "$LAST_BACKUP_DIR/etc/"
    copied=1
  fi

  if [[ -d "$MIHOMO_ANYTLS_DIR" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$MIHOMO_ANYTLS_DIR")"
    cp -a "$MIHOMO_ANYTLS_DIR" "$LAST_BACKUP_DIR$MIHOMO_ANYTLS_DIR"
    copied=1
  fi

  if [[ -d "$MIHOMO_SS2022_DIR" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$MIHOMO_SS2022_DIR")"
    cp -a "$MIHOMO_SS2022_DIR" "$LAST_BACKUP_DIR$MIHOMO_SS2022_DIR"
    copied=1
  fi

  if [[ -f "/etc/systemd/system/${SING_BOX_SERVICE}" ]]; then
    mkdir -p "$LAST_BACKUP_DIR/etc/systemd/system"
    cp -a "/etc/systemd/system/${SING_BOX_SERVICE}" "$LAST_BACKUP_DIR/etc/systemd/system/"
    copied=1
  fi

  if [[ -f "$SING_BOX_SERVICE_TUNING" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$SING_BOX_SERVICE_TUNING")"
    cp -a "$SING_BOX_SERVICE_TUNING" "$LAST_BACKUP_DIR$SING_BOX_SERVICE_TUNING"
    copied=1
  fi

  if [[ -f "/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}" ]]; then
    mkdir -p "$LAST_BACKUP_DIR/etc/systemd/system"
    cp -a "/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}" "$LAST_BACKUP_DIR/etc/systemd/system/"
    copied=1
  fi

  if [[ -f "/etc/systemd/system/${MIHOMO_SS2022_SERVICE}" ]]; then
    mkdir -p "$LAST_BACKUP_DIR/etc/systemd/system"
    cp -a "/etc/systemd/system/${MIHOMO_SS2022_SERVICE}" "$LAST_BACKUP_DIR/etc/systemd/system/"
    copied=1
  fi

  if [[ -d "$SUBSCRIPTION_DIR" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$SUBSCRIPTION_DIR")"
    cp -a "$SUBSCRIPTION_DIR" "$LAST_BACKUP_DIR$SUBSCRIPTION_DIR"
    copied=1
  fi

  if [[ -f "$SUB_SERVER_SCRIPT" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$SUB_SERVER_SCRIPT")"
    cp -a "$SUB_SERVER_SCRIPT" "$LAST_BACKUP_DIR$SUB_SERVER_SCRIPT"
    copied=1
  fi

  if [[ -f "$INSTALL_SCRIPT" ]]; then
    mkdir -p "$LAST_BACKUP_DIR$(dirname "$INSTALL_SCRIPT")"
    cp -a "$INSTALL_SCRIPT" "$LAST_BACKUP_DIR$INSTALL_SCRIPT"
    copied=1
  fi

  for unit_file in "$SUB_SERVICE" "$ARGO_SERVICE" "$ARGO_REFRESH_SERVICE" "$ARGO_REFRESH_TIMER" "$ARGO_REFRESH_PATH"; do
    if [[ -f "/etc/systemd/system/${unit_file}" ]]; then
      mkdir -p "$LAST_BACKUP_DIR/etc/systemd/system"
      cp -a "/etc/systemd/system/${unit_file}" "$LAST_BACKUP_DIR/etc/systemd/system/"
      copied=1
    fi
  done

  for share_file in "$HY2_CLIENT_YAML" "$HY2_CLIENT_OFFICIAL_YAML" "$HY2_CLIENT_SINGBOX_JSON" "$HY2_SHARE_TXT" "$HY2_SUB_RAW_TXT" "$HY2_SUB_NOHOP_RAW_TXT" "$HY2_SUB_B64_TXT" "$HY2_QR_PNG" \
    "$ANYTLS_CLIENT_YAML" "$ANYTLS_SHARE_TXT" "$ANYTLS_SUB_RAW_TXT" "$ANYTLS_SUB_B64_TXT" "$ANYTLS_QR_PNG" \
    "$SS2022_CLIENT_YAML" "$SS2022_SHARE_TXT" "$SS2022_SUB_RAW_TXT" "$SS2022_SUB_B64_TXT" "$SS2022_QR_PNG" \
    "$ARGO_SHARE_TXT" "$ARGO_SUB_RAW_TXT" "$ARGO_SUB_B64_TXT" "$ARGO_QR_PNG" \
    "$COMBO_SUB_RAW_TXT" "$COMBO_SUB_B64_TXT"; do
    if [[ -f "$share_file" ]]; then
      mkdir -p "$LAST_BACKUP_DIR$(dirname "$share_file")"
      cp -a "$share_file" "$LAST_BACKUP_DIR$share_file"
      copied=1
    fi
  done

  if [[ $copied -eq 1 ]]; then
    green "已备份现有配置到: $LAST_BACKUP_DIR"
  else
    rm -rf "$LAST_BACKUP_DIR"
    LAST_BACKUP_DIR=""
    yellow "未检测到需要备份的旧配置"
  fi
}

restore_backup_dir() {
  local backup_dir="$1" restored_sing_box=0

  if [[ -z "$backup_dir" || ! -d "$backup_dir" ]]; then
    red "备份目录不存在: ${backup_dir:-<empty>}"
    return 1
  fi

  stop_all_related

  rm -f "$NGINX_CFG" "$NGINX_REALIP_CFG" "$CLIENT_JSON" "$SHARE_TXT" "$SUB_RAW_TXT" "$SUB_B64_TXT" "$NODE_QR_PNG" \
    "$HY2_CLIENT_YAML" "$HY2_CLIENT_OFFICIAL_YAML" "$HY2_CLIENT_SINGBOX_JSON" "$HY2_SHARE_TXT" "$HY2_SUB_RAW_TXT" "$HY2_SUB_NOHOP_RAW_TXT" "$HY2_SUB_B64_TXT" "$HY2_QR_PNG" \
    "$ANYTLS_CLIENT_YAML" "$ANYTLS_SHARE_TXT" "$ANYTLS_SUB_RAW_TXT" "$ANYTLS_SUB_B64_TXT" "$ANYTLS_QR_PNG" \
    "$SS2022_CLIENT_YAML" "$SS2022_SHARE_TXT" "$SS2022_SUB_RAW_TXT" "$SS2022_SUB_B64_TXT" "$SS2022_QR_PNG" \
    "$SUB_SERVER_SCRIPT" "$ARGO_SHARE_TXT" "$ARGO_SUB_RAW_TXT" "$ARGO_SUB_B64_TXT" "$ARGO_QR_PNG" \
    "$COMBO_SUB_RAW_TXT" "$COMBO_SUB_B64_TXT"
  rm -f "$SING_BOX_CFG"
  rm -f "/etc/systemd/system/${SUB_SERVICE}" "/etc/systemd/system/${ARGO_SERVICE}" "/etc/systemd/system/${ARGO_REFRESH_SERVICE}" "/etc/systemd/system/${ARGO_REFRESH_TIMER}" "/etc/systemd/system/${ARGO_REFRESH_PATH}" \
    "/etc/systemd/system/${SING_BOX_SERVICE}" "/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}" "/etc/systemd/system/${MIHOMO_SS2022_SERVICE}"
  rm -rf "$WEB_ROOT" "$SSL_DIR" "$MIHOMO_ANYTLS_DIR" "$MIHOMO_SS2022_DIR" "$SUBSCRIPTION_DIR"

  if [[ -d "$backup_dir/etc/nginx" ]]; then
    rm -rf /etc/nginx
    mkdir -p /etc
    cp -a "$backup_dir/etc/nginx" /etc/
  fi

  if [[ -f "$backup_dir$SING_BOX_CFG" ]]; then
    mkdir -p "$(dirname "$SING_BOX_CFG")"
    cp -a "$backup_dir$SING_BOX_CFG" "$SING_BOX_CFG"
  else
    rm -f "$SING_BOX_CFG"
  fi

  if [[ -f "$backup_dir$XRAY_CFG" ]]; then
    mkdir -p "$(dirname "$XRAY_CFG")"
    cp -a "$backup_dir$XRAY_CFG" "$XRAY_CFG"
  else
    rm -f "$XRAY_CFG"
  fi

  if [[ -d "$backup_dir$WEB_ROOT" ]]; then
    mkdir -p "$(dirname "$WEB_ROOT")"
    cp -a "$backup_dir$WEB_ROOT" "$WEB_ROOT"
  fi

  if [[ -d "$backup_dir$SSL_DIR" ]]; then
    mkdir -p "$(dirname "$SSL_DIR")"
    cp -a "$backup_dir$SSL_DIR" "$SSL_DIR"
  fi

  if [[ -f "$backup_dir$STATE_FILE" ]]; then
    mkdir -p "$STATE_DIR"
    cp -a "$backup_dir$STATE_FILE" "$STATE_FILE"
  else
    rm -rf "$STATE_DIR"
  fi

  if [[ -d "$backup_dir$SUBSCRIPTION_DIR" ]]; then
    mkdir -p "$(dirname "$SUBSCRIPTION_DIR")"
    cp -a "$backup_dir$SUBSCRIPTION_DIR" "$SUBSCRIPTION_DIR"
  fi

  if [[ -d "$backup_dir/etc/hysteria" ]]; then
    rm -rf /etc/hysteria
    mkdir -p /etc
    cp -a "$backup_dir/etc/hysteria" /etc/
  else
    rm -rf /etc/hysteria
  fi

  if [[ -d "$backup_dir$MIHOMO_ANYTLS_DIR" ]]; then
    mkdir -p "$(dirname "$MIHOMO_ANYTLS_DIR")"
    cp -a "$backup_dir$MIHOMO_ANYTLS_DIR" "$MIHOMO_ANYTLS_DIR"
  fi

  if [[ -d "$backup_dir$MIHOMO_SS2022_DIR" ]]; then
    mkdir -p "$(dirname "$MIHOMO_SS2022_DIR")"
    cp -a "$backup_dir$MIHOMO_SS2022_DIR" "$MIHOMO_SS2022_DIR"
  fi

  if [[ -f "$backup_dir/etc/systemd/system/${SING_BOX_SERVICE}" ]]; then
    mkdir -p /etc/systemd/system
    cp -a "$backup_dir/etc/systemd/system/${SING_BOX_SERVICE}" "/etc/systemd/system/${SING_BOX_SERVICE}"
  else
    rm -f "/etc/systemd/system/${SING_BOX_SERVICE}"
  fi

  if [[ -f "$backup_dir$SING_BOX_SERVICE_TUNING" ]]; then
    mkdir -p "$(dirname "$SING_BOX_SERVICE_TUNING")"
    cp -a "$backup_dir$SING_BOX_SERVICE_TUNING" "$SING_BOX_SERVICE_TUNING"
  else
    rm -f "$SING_BOX_SERVICE_TUNING"
  fi

  if [[ -f "$backup_dir/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}" ]]; then
    mkdir -p /etc/systemd/system
    cp -a "$backup_dir/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}" "/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}"
  else
    rm -f "/etc/systemd/system/${MIHOMO_ANYTLS_SERVICE}"
  fi

  if [[ -f "$backup_dir/etc/systemd/system/${MIHOMO_SS2022_SERVICE}" ]]; then
    mkdir -p /etc/systemd/system
    cp -a "$backup_dir/etc/systemd/system/${MIHOMO_SS2022_SERVICE}" "/etc/systemd/system/${MIHOMO_SS2022_SERVICE}"
  else
    rm -f "/etc/systemd/system/${MIHOMO_SS2022_SERVICE}"
  fi

  if [[ -f "$backup_dir$SUB_SERVER_SCRIPT" ]]; then
    mkdir -p "$(dirname "$SUB_SERVER_SCRIPT")"
    cp -a "$backup_dir$SUB_SERVER_SCRIPT" "$SUB_SERVER_SCRIPT"
  fi

  if [[ -f "$backup_dir$INSTALL_SCRIPT" ]]; then
    mkdir -p "$(dirname "$INSTALL_SCRIPT")"
    cp -a "$backup_dir$INSTALL_SCRIPT" "$INSTALL_SCRIPT"
  fi

  for unit_file in "$SUB_SERVICE" "$ARGO_SERVICE" "$ARGO_REFRESH_SERVICE" "$ARGO_REFRESH_TIMER" "$ARGO_REFRESH_PATH"; do
    if [[ -f "$backup_dir/etc/systemd/system/${unit_file}" ]]; then
      mkdir -p /etc/systemd/system
      cp -a "$backup_dir/etc/systemd/system/${unit_file}" "/etc/systemd/system/${unit_file}"
    else
      rm -f "/etc/systemd/system/${unit_file}"
    fi
  done

  for share_file in "$HY2_CLIENT_YAML" "$HY2_CLIENT_OFFICIAL_YAML" "$HY2_CLIENT_SINGBOX_JSON" "$HY2_SHARE_TXT" "$HY2_SUB_RAW_TXT" "$HY2_SUB_NOHOP_RAW_TXT" "$HY2_SUB_B64_TXT" "$HY2_QR_PNG" \
    "$ANYTLS_CLIENT_YAML" "$ANYTLS_SHARE_TXT" "$ANYTLS_SUB_RAW_TXT" "$ANYTLS_SUB_B64_TXT" "$ANYTLS_QR_PNG" \
    "$SS2022_CLIENT_YAML" "$SS2022_SHARE_TXT" "$SS2022_SUB_RAW_TXT" "$SS2022_SUB_B64_TXT" "$SS2022_QR_PNG" \
    "$ARGO_SHARE_TXT" "$ARGO_SUB_RAW_TXT" "$ARGO_SUB_B64_TXT" "$ARGO_QR_PNG" \
    "$COMBO_SUB_RAW_TXT" "$COMBO_SUB_B64_TXT"; do
    if [[ -f "$backup_dir$share_file" ]]; then
      mkdir -p "$(dirname "$share_file")"
      cp -a "$backup_dir$share_file" "$share_file"
    else
      rm -f "$share_file"
    fi
  done

  systemctl daemon-reload >/dev/null 2>&1 || true

  if [[ -d /etc/nginx && -x "$(command -v nginx 2>/dev/null)" ]]; then
    nginx -t
    systemctl enable nginx >/dev/null 2>&1 || true
    systemctl restart nginx
  fi

  if [[ -f "$SING_BOX_CFG" ]]; then
    install_sing_box
    "$SING_BOX_BIN" check -c "$SING_BOX_CFG"
    systemctl enable "$SING_BOX_SERVICE" >/dev/null 2>&1 || true
    systemctl restart "$SING_BOX_SERVICE"
    restored_sing_box=1
    disable_legacy_protocol_services
  else
    systemctl disable --now "$SING_BOX_SERVICE" >/dev/null 2>&1 || true
  fi

  if [[ "$restored_sing_box" != "1" && -f "$XRAY_CFG" && -x "$(command -v xray 2>/dev/null)" ]]; then
    xray run -test -c "$XRAY_CFG"
    systemctl enable xray >/dev/null 2>&1 || true
    systemctl restart xray
  else
    systemctl disable --now xray >/dev/null 2>&1 || true
  fi

  if [[ "$restored_sing_box" != "1" && -f "$HYSTERIA_CFG" && -x "$(command -v hysteria 2>/dev/null)" ]]; then
    systemctl enable "$HY2_SERVICE" >/dev/null 2>&1 || true
    systemctl restart "$HY2_SERVICE"
  else
    systemctl disable --now "$HY2_SERVICE" >/dev/null 2>&1 || true
  fi

  if [[ "$restored_sing_box" != "1" && -f "$MIHOMO_ANYTLS_CFG" && -x "$MIHOMO_BIN" ]]; then
    systemctl enable "$MIHOMO_ANYTLS_SERVICE" >/dev/null 2>&1 || true
    systemctl restart "$MIHOMO_ANYTLS_SERVICE"
  else
    systemctl disable --now "$MIHOMO_ANYTLS_SERVICE" >/dev/null 2>&1 || true
  fi

  if [[ "$restored_sing_box" != "1" && -f "$MIHOMO_SS2022_CFG" && -x "$MIHOMO_BIN" ]]; then
    systemctl enable "$MIHOMO_SS2022_SERVICE" >/dev/null 2>&1 || true
    systemctl restart "$MIHOMO_SS2022_SERVICE"
  else
    systemctl disable --now "$MIHOMO_SS2022_SERVICE" >/dev/null 2>&1 || true
  fi

  if [[ -f "/etc/systemd/system/${SUB_SERVICE}" && -x "$SUB_SERVER_SCRIPT" && -d "$SUBSCRIPTION_DIR" && -s "$SSL_DIR/fullchain.cer" && -s "$SSL_DIR/private.key" ]]; then
    systemctl enable "$SUB_SERVICE" >/dev/null 2>&1 || true
    systemctl restart "$SUB_SERVICE"
  else
    systemctl disable --now "$SUB_SERVICE" >/dev/null 2>&1 || true
  fi

  if [[ -f "/etc/systemd/system/${ARGO_SERVICE}" && -x "$CLOUDFLARED_BIN" && ( -f "$SING_BOX_CFG" || -f "$XRAY_CFG" ) ]]; then
    systemctl enable "$ARGO_SERVICE" >/dev/null 2>&1 || true
    if [[ -f "/etc/systemd/system/${ARGO_REFRESH_SERVICE}" && -f "/etc/systemd/system/${ARGO_REFRESH_TIMER}" && -f "/etc/systemd/system/${ARGO_REFRESH_PATH}" ]]; then
      enable_argo_refresh_automation
    fi
    systemctl restart "$ARGO_SERVICE"
  else
    systemctl disable --now "$ARGO_REFRESH_PATH" "$ARGO_REFRESH_TIMER" "$ARGO_REFRESH_SERVICE" >/dev/null 2>&1 || true
    systemctl disable --now "$ARGO_SERVICE" >/dev/null 2>&1 || true
  fi

  green "已恢复备份: $backup_dir"
}

restore_latest_backup() {
  local backup_dir=""

  require_root

  if load_state && [[ -n "${LAST_BACKUP_DIR:-}" && -d "${LAST_BACKUP_DIR:-}" ]]; then
    backup_dir="$LAST_BACKUP_DIR"
  elif [[ -d "$BACKUP_ROOT" ]]; then
    backup_dir="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
  fi

  if [[ -z "$backup_dir" ]]; then
    red "未找到可恢复的备份"
    return 1
  fi

  yellow "将恢复最近备份: $backup_dir"
  read -r -p "确认恢复？[y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]] || return 0

  restore_backup_dir "$backup_dir"
}

check_ports_before_install() {
  if port_in_use 443; then
    red "443 端口仍被占用，无法继续。"
    show_port_usage 443
    exit 1
  fi

  if port_in_use 80 && ! port_used_by_common_web_service 80; then
    red "80 端口仍被未知服务占用，无法签发证书。"
    show_port_usage 80
    exit 1
  fi

  if port_in_use 80; then
    red "80 端口仍被占用，无法签发证书。"
    show_port_usage 80
    exit 1
  fi

  if port_in_use "$TARGET_PORT"; then
    red "${TARGET_PORT} 端口仍被占用，无法部署本地目标站。"
    show_port_usage "$TARGET_PORT"
    exit 1
  fi
}

install_packages() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y curl wget socat openssl nginx jq ca-certificates python3 qrencode iptables nftables gzip cron kmod procps gnupg lsb-release || \
    apt-get install -y curl wget socat openssl nginx jq ca-certificates python3 qrencode iptables nftables gzip kmod procps gnupg lsb-release
  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now cron >/dev/null 2>&1 || systemctl enable --now crond >/dev/null 2>&1 || true
  fi
  if [[ "${1:-1}" == "1" ]]; then
    enable_bbr
  fi
}

sing_box_cmd() {
  if command -v sing-box >/dev/null 2>&1; then
    command -v sing-box
    return 0
  fi

  if [[ -x "$SING_BOX_BIN" ]]; then
    printf '%s\n' "$SING_BOX_BIN"
    return 0
  fi

  return 1
}

install_sing_box() {
  local bin version_line

  if ! bin="$(sing_box_cmd 2>/dev/null)"; then
    yellow "正在安装 sing-box..."
    bash <(curl_fsSL https://sing-box.app/install.sh)
    bin="$(sing_box_cmd 2>/dev/null || true)"
  fi

  if [[ -z "$bin" || ! -x "$bin" ]]; then
    red "sing-box 安装失败：未找到可执行文件"
    return 1
  fi

  SING_BOX_BIN="$bin"
  if [[ "${SING_BOX_VERSION_PRINTED:-0}" != "1" ]]; then
    version_line="$("$SING_BOX_BIN" version | head -n 1 || true)"
    if [[ -n "$version_line" ]]; then
      green "sing-box 已就绪：${version_line}"
    fi
    SING_BOX_VERSION_PRINTED="1"
  fi
}

install_xray() {
  install_sing_box
}

print_indented_lines() {
  local prefix="$1"
  while IFS= read -r line; do
    [[ -n "$line" ]] && printf '%s%s\n' "$prefix" "$line"
  done
}

disable_legacy_protocol_services() {
  systemctl disable --now xray "$HY2_SERVICE" "$MIHOMO_ANYTLS_SERVICE" "$MIHOMO_SS2022_SERVICE" >/dev/null 2>&1 || true
}

sing_box_has_enabled_inbound() {
  [[ -n "${UUID:-}" && -n "${PRIVATE_KEY:-}" && -n "${PUBLIC_KEY:-}" && -n "${SHORT_ID:-}" ]] && return 0
  [[ "${HY2_ENABLED:-0}" == "1" && -n "${HY2_PORT:-}" && -n "${HY2_PASSWORD:-}" ]] && return 0
  [[ "${ANYTLS_ENABLED:-0}" == "1" && -n "${ANYTLS_PORT:-}" && -n "${ANYTLS_PASSWORD:-}" ]] && return 0
  [[ "${SS2022_ENABLED:-0}" == "1" && -n "${SS2022_PORT:-}" && -n "${SS2022_PASSWORD:-}" ]] && return 0
  [[ "${ARGO_ENABLED:-0}" == "1" && -n "${ARGO_LOCAL_PORT:-}" && -n "${ARGO_UUID:-}" && -n "${ARGO_WS_PATH:-}" ]] && return 0
  [[ "${TUIC_ENABLED:-0}" == "1" && -n "${TUIC_PORT:-}" && -n "${TUIC_PASSWORD:-}" ]] && return 0
  [[ "${VMESS_ENABLED:-0}" == "1" && -n "${VMESS_UUID:-}" && -n "${VMESS_PORT:-}" && -n "${VMESS_WS_PATH:-}" ]] && return 0
  return 1
}

urlenc() {
  jq -rn --arg v "$1" '$v|@uri'
}

yaml_quote() {
  jq -rn --arg v "$1" '$v|@json'
}

prompt_vmess_port() {
  prompt_port VMESS_PORT "VMess" 50000 60000 || true
}

has_vmess_install() {
  [[ "${VMESS_ENABLED:-0}" == "1" && -n "${VMESS_UUID:-}" && -f "$SING_BOX_CFG" ]]
}

clear_vmess_state_for_profile() {
  VMESS_ENABLED="0"
  VMESS_PORT=""
  VMESS_UUID=""
  VMESS_WS_PATH=""
  VMESS_TLS_ENABLED="0"
  VMESS_SERVER_ADDR=""
  rm -f /etc/sing-box/node-info/vmess-share.txt /etc/sing-box/node-info/vmess-subscription-raw.txt /etc/sing-box/node-info/vmess-subscription-base64.txt /etc/sing-box/node-info/vmess-node-qr.png
}

has_tuic_install() {
  [[ "${TUIC_ENABLED:-0}" == "1" && -n "${TUIC_PASSWORD:-}" && -f "$SING_BOX_CFG" ]]
}

prompt_tuic_port() {
  prompt_port TUIC_PORT "TUIC" 50000 60000 1 || true
}

clear_tuic_state_for_profile() {
  TUIC_ENABLED="0"
  TUIC_PORT=""
  TUIC_PASSWORD=""
  TUIC_SERVER_ADDR=""
  TUIC_TLS_SNI=""
  rm -f /etc/sing-box/node-info/tuic5-share.txt /etc/sing-box/node-info/tuic5-subscription-raw.txt
  rm -f /etc/sing-box/node-info/tuic5-subscription-base64.txt /etc/sing-box/node-info/tuic5-node-qr.png
}

install_hysteria2_binary() {
  install_sing_box
}

generate_alnum_secret() {
  local length="${1:-20}"
  python3 - "$length" <<'PY'
import secrets
import string
import sys

length = int(sys.argv[1])
alphabet = string.ascii_letters + string.digits
print(''.join(secrets.choice(alphabet) for _ in range(length)), end='')
PY
}

generate_hy2_password() {
  HY2_PASSWORD="$(generate_alnum_secret 20)"
  if [[ "${HY2_OBFS_ENABLED:-0}" == "1" ]]; then
    HY2_OBFS_PASSWORD="$(generate_alnum_secret 20)"
  else
    HY2_OBFS_PASSWORD=""
  fi
}

generate_anytls_password() {
  ANYTLS_PASSWORD="$(generate_alnum_secret 24)"
}

cpu_has_aes_accel() {
  if [[ -r /proc/cpuinfo ]] && grep -qiE '(^flags|^Features)[[:space:]]*:.*(^|[[:space:]])aes($|[[:space:]])' /proc/cpuinfo; then
    return 0
  fi
  return 1
}

select_ss2022_cipher() {
  if cpu_has_aes_accel; then
    SS2022_CIPHER="2022-blake3-aes-128-gcm"
  else
    SS2022_CIPHER="2022-blake3-chacha20-poly1305"
  fi
}

ss2022_key_bytes() {
  case "${SS2022_CIPHER:-}" in
    2022-blake3-aes-128-gcm)
      printf '16'
      ;;
    *)
      printf '32'
      ;;
  esac
}

generate_ss2022_password() {
  select_ss2022_cipher
  SS2022_PASSWORD="$(openssl rand -base64 "$(ss2022_key_bytes)")"
}

detect_mihomo_asset() {
  local arch tag release_json asset_arch exact_name asset_pattern asset names
  tag="$1"
  release_json="$2"
  arch="$(uname -m)"

  case "$arch" in
    x86_64|amd64)
      asset_arch="amd64"
      ;;
    aarch64|arm64)
      asset_arch="arm64"
      ;;
    armv7l|armv7)
      asset_arch="armv7"
      ;;
    armv6l|armv6)
      asset_arch="armv6"
      ;;
    armv5l|armv5)
      asset_arch="armv5"
      ;;
    i386|i686)
      asset_arch="386"
      ;;
    riscv64)
      asset_arch="riscv64"
      ;;
    *)
      red "mihomo 暂未适配当前 CPU 架构: $arch"
      return 1
      ;;
  esac

  exact_name="mihomo-linux-${asset_arch}-${tag}.gz"
  asset_pattern="^mihomo-linux-${asset_arch}(-[^.]+)?-${tag}\\.gz$"
  names="$(printf '%s' "$release_json" | jq -r '.assets[].name')"
  asset="$(printf '%s\n' "$names" | grep -Fx "$exact_name" | head -n 1 || true)"
  if [[ -z "$asset" ]]; then
    asset="$(printf '%s\n' "$names" | grep -E "$asset_pattern" | grep -Ev 'go[0-9]+|compatible|softfloat' | head -n 1 || true)"
  fi
  if [[ -z "$asset" ]]; then
    red "未找到 mihomo release 资产，匹配规则: ${asset_pattern}"
    return 1
  fi

  printf '%s' "$asset"
}

install_mihomo_binary() {
  install_sing_box
}

detect_cloudflared_asset() {
  local arch release_json asset names
  release_json="$1"
  arch="$(uname -m)"

  case "$arch" in
    x86_64|amd64)
      asset="cloudflared-linux-amd64"
      ;;
    aarch64|arm64)
      asset="cloudflared-linux-arm64"
      ;;
    armv7l|armv7|armv6l|armv6)
      asset="cloudflared-linux-arm"
      ;;
    i386|i686)
      asset="cloudflared-linux-386"
      ;;
    *)
      red "cloudflared 暂未适配当前 CPU 架构: $arch"
      return 1
      ;;
  esac

  names="$(printf '%s' "$release_json" | jq -r '.assets[].name')"
  if ! printf '%s\n' "$names" | grep -Fxq "$asset"; then
    red "未找到 cloudflared release 资产: ${asset}"
    return 1
  fi

  printf '%s' "$asset"
}

