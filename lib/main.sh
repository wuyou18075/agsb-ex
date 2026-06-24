#!/usr/bin/env bash
# =============================================================================
# main.sh - Main installer: services, state, installation, menu
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
TUIC_UUID=""
TUIC_SERVER_ADDR=""
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
  apply_node_prefix

  [[ -n "${DOMAIN:-}" ]] || return 0

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
    printf 'DOMAIN=%q\n' "${DOMAIN:-}"
    printf 'EMAIL=%q\n' "${EMAIL:-}"
    printf 'UUID=%q\n' "${UUID:-}"
    printf 'XHTTP_PATH=%q\n' "${XHTTP_PATH:-}"
    printf 'SHORT_ID=%q\n' "${SHORT_ID:-}"
    printf 'PRIVATE_KEY=%q\n' "${PRIVATE_KEY:-}"
    printf 'PUBLIC_KEY=%q\n' "${PUBLIC_KEY:-}"
    printf 'TARGET_PORT=%q\n' "${TARGET_PORT:-}"
      printf 'INSTALL_MODE=%q\n' "${INSTALL_MODE:-}"
      printf 'LAST_BACKUP_DIR=%q\n' "${LAST_BACKUP_DIR:-}"
      printf 'HY2_ENABLED=%q\n' "${HY2_ENABLED:-}"
      printf 'HY2_PORT=%q\n' "${HY2_PORT:-}"
      printf 'HY2_PASSWORD=%q\n' "${HY2_PASSWORD:-}"
      printf 'HY2_OBFS_ENABLED=%q\n' "${HY2_OBFS_ENABLED:-}"
      printf 'HY2_OBFS_PASSWORD=%q\n' "${HY2_OBFS_PASSWORD:-}"
      printf 'HY2_MASQUERADE_URL=%q\n' "${HY2_MASQUERADE_URL:-}"
      printf 'HY2_SERVER_ADDR=%q\n' "${HY2_SERVER_ADDR:-}"
      printf 'HY2_PORT_RANGE=%q\n' "${HY2_PORT_RANGE:-}"
      printf 'HY2_TLS_SNI=%q\n' "${HY2_TLS_SNI:-}"
      printf 'ANYTLS_ENABLED=%q\n' "${ANYTLS_ENABLED:-}"
      printf 'ANYTLS_PORT=%q\n' "${ANYTLS_PORT:-}"
      printf 'ANYTLS_PASSWORD=%q\n' "${ANYTLS_PASSWORD:-}"
      printf 'ANYTLS_SERVER_ADDR=%q\n' "${ANYTLS_SERVER_ADDR:-}"
      printf 'ANYTLS_TLS_SNI=%q\n' "${ANYTLS_TLS_SNI:-}"
      printf 'SS2022_ENABLED=%q\n' "${SS2022_ENABLED:-}"
      printf 'SS2022_PORT=%q\n' "${SS2022_PORT:-}"
      printf 'SS2022_CIPHER=%q\n' "${SS2022_CIPHER:-}"
      printf 'SS2022_PASSWORD=%q\n' "${SS2022_PASSWORD:-}"
      printf 'SS2022_SERVER_ADDR=%q\n' "${SS2022_SERVER_ADDR:-}"
      printf 'VMESS_ENABLED=%q\n' "${VMESS_ENABLED:-}"
      printf 'VMESS_PORT=%q\n' "${VMESS_PORT:-}"
      printf 'VMESS_UUID=%q\n' "${VMESS_UUID:-}"
      printf 'VMESS_WS_PATH=%q\n' "${VMESS_WS_PATH:-}"
      printf 'VMESS_TLS_ENABLED=%q\n' "${VMESS_TLS_ENABLED:-}"
      printf 'VMESS_SERVER_ADDR=%q\n' "${VMESS_SERVER_ADDR:-}"
      printf 'SUB_ENABLED=%q\n' "${SUB_ENABLED:-}"
      printf 'SUB_PORT=%q\n' "${SUB_PORT:-}"
      printf 'SUB_PATH=%q\n' "${SUB_PATH:-}"
      printf 'ARGO_ENABLED=%q\n' "${ARGO_ENABLED:-}"
      printf 'ARGO_LOCAL_PORT=%q\n' "${ARGO_LOCAL_PORT:-}"
      printf 'ARGO_UUID=%q\n' "${ARGO_UUID:-}"
      printf 'ARGO_WS_PATH=%q\n' "${ARGO_WS_PATH:-}"
      printf 'ARGO_DOMAIN=%q\n' "${ARGO_DOMAIN:-}"
      printf 'ARGO_TUNNEL_MODE=%q\n' "${ARGO_TUNNEL_MODE:-}"
      printf 'ARGO_FIXED_DOMAIN=%q\n' "${ARGO_FIXED_DOMAIN:-}"
      printf 'ARGO_TUNNEL_TOKEN=%q\n' "${ARGO_TUNNEL_TOKEN:-}"
      printf 'ARGO_PROTOCOL=%q\n' "${ARGO_PROTOCOL:-}"
      printf 'ARGO_EDGE_IP_VERSION=%q\n' "${ARGO_EDGE_IP_VERSION:-}"
      printf 'ARGO_EDGE_SERVER=%q\n' "${ARGO_EDGE_SERVER:-}"
      printf 'ARGO_MULTI_EDGE=%q\n' "${ARGO_MULTI_EDGE:-0}"
      printf 'ARGO_EDGE_INDEX=%q\n' "${ARGO_EDGE_INDEX:-0}"
      if [[ "${#ARGO_EDGE_SERVERS[@]}" -gt 0 ]]; then
        printf 'ARGO_EDGE_SERVERS=(%s)\n' "$(printf ' %q' "${ARGO_EDGE_SERVERS[@]}")"
      fi
      printf 'TUIC_ENABLED=%q\n' "${TUIC_ENABLED:-}"
      printf 'TUIC_PORT=%q\n' "${TUIC_PORT:-}"
      printf 'TUIC_PASSWORD=%q\n' "${TUIC_PASSWORD:-}"
      printf 'TUIC_UUID=%q\n' "${TUIC_UUID:-}"
      printf 'TUIC_SERVER_ADDR=%q\n' "${TUIC_SERVER_ADDR:-}"
      printf 'TUIC_TLS_SNI=%q\n' "${TUIC_TLS_SNI:-}"
      printf 'NODE_PREFIX=%q\n' "${NODE_PREFIX:-}"
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
    echo "${desc}端口已随机: ${candidate}"
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
  TUIC_UUID=""
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


# === services.sh merged below ===

download_xanmod_key() {
  local output="$1"
  local url tmp
  local urls=(
    "https://dl.xanmod.org/archive.key"
    "https://gitlab.com/afrd.gpg"
  )

  for url in "${urls[@]}"; do
    tmp="$(mktemp)"
    yellow "尝试下载 XanMod GPG key: ${url}"

    if curl -fsSL --retry 2 --connect-timeout 10 --max-time 30 -A "Mozilla/5.0" "$url" -o "$tmp" 2>/dev/null \
      && grep -q "BEGIN PGP PUBLIC KEY BLOCK" "$tmp"; then
      mv "$tmp" "$output"
      return 0
    fi

    rm -f "$tmp"
    if command -v wget >/dev/null 2>&1; then
      tmp="$(mktemp)"
      if wget -q --tries=2 --timeout=30 --user-agent="Mozilla/5.0" -O "$tmp" "$url" \
        && grep -q "BEGIN PGP PUBLIC KEY BLOCK" "$tmp"; then
        mv "$tmp" "$output"
        return 0
      fi
      rm -f "$tmp"
    fi
  done

  red "XanMod GPG key 下载失败，可能是当前 VPS 到 dl.xanmod.org / gitlab.com 被阻断。"
  return 1
}

detect_apt_codename() {
  local codename=""

  if command -v lsb_release >/dev/null 2>&1; then
    codename="$(lsb_release -sc 2>/dev/null || true)"
  fi

  if [[ -z "$codename" && -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    codename="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
  fi

  printf '%s' "$codename"
}

cpu_supports_x86_64_v3() {
  local flags flag
  local required_flags=(cx16 lahf_lm popcnt sse4_1 sse4_2 ssse3 avx avx2 bmi1 bmi2 f16c fma abm movbe xsave osxsave)

  [[ "$(uname -m)" == "x86_64" ]] || return 1

  if [[ -x /lib64/ld-linux-x86-64.so.2 ]] && /lib64/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -q 'x86-64-v3 (supported'; then
    return 0
  fi

  flags="$(awk -F: '/^flags[[:space:]]*:/ {print " " $2 " "; exit}' /proc/cpuinfo 2>/dev/null || true)"
  [[ -n "$flags" ]] || return 1

  for flag in "${required_flags[@]}"; do
    [[ "$flags" == *" $flag "* ]] || return 1
  done
}

detect_x86_64_level() {
  local flags help level

  [[ "$(uname -m)" == "x86_64" ]] || return 1

  if [[ -x /lib64/ld-linux-x86-64.so.2 ]]; then
    help="$(/lib64/ld-linux-x86-64.so.2 --help 2>/dev/null || true)"
    for level in 4 3 2; do
      if printf '%s\n' "$help" | grep -q "x86-64-v${level} (supported"; then
        printf '%s' "$level"
        return 0
      fi
    done
  fi

  flags="$(awk -F: '/^flags[[:space:]]*:/ {print " " $2 " "; exit}' /proc/cpuinfo 2>/dev/null || true)"
  [[ -n "$flags" ]] || return 1

  if [[ "$flags" == *" avx512f "* && "$flags" == *" avx512bw "* && "$flags" == *" avx512cd "* && "$flags" == *" avx512dq "* && "$flags" == *" avx512vl "* ]]; then
    printf '4'
  elif cpu_supports_x86_64_v3; then
    printf '3'
  elif [[ "$flags" == *" cx16 "* && "$flags" == *" lahf_lm "* && "$flags" == *" popcnt "* && "$flags" == *" sse4_1 "* && "$flags" == *" sse4_2 "* && "$flags" == *" ssse3 "* ]]; then
    printf '2'
  else
    printf '1'
  fi
}

set_grub_default_first_entry() {
  local grub_file="/etc/default/grub"
  local backup_file

  [[ -f "$grub_file" ]] || return 0

  backup_file="${grub_file}.${APP_NAME}.bak.$(date +%Y%m%d%H%M%S)"
  cp -a "$grub_file" "$backup_file" 2>/dev/null || true

  if grep -q '^GRUB_DEFAULT=' "$grub_file"; then
    sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' "$grub_file"
  else
    printf '\nGRUB_DEFAULT=0\n' >> "$grub_file"
  fi

  if grep -q '^GRUB_SAVEDEFAULT=' "$grub_file"; then
    sed -i 's/^GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=false/' "$grub_file"
  fi
}

refresh_grub_config() {
  if command -v update-grub >/dev/null 2>&1; then
    update-grub || yellow "update-grub 执行失败，请重启前手动确认 GRUB 默认内核。"
  elif command -v grub-mkconfig >/dev/null 2>&1 && [[ -d /boot/grub ]]; then
    grub-mkconfig -o /boot/grub/grub.cfg || yellow "grub-mkconfig 执行失败，请重启前手动确认 GRUB 默认内核。"
  else
    yellow "未找到 update-grub / grub-mkconfig，请确认重启后默认进入新内核。"
  fi
}

xanmod_package_available() {
  local pkg="$1"
  apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2; exit}' | grep -vqE '^\(none\)$|^$'
}

select_xanmod_package() {
  local level="$1" pkg
  local candidates=()

  case "$level" in
    1)
      candidates=("linux-xanmod-lts-x64v1")
      ;;
    2)
      candidates=("linux-xanmod-x64v2" "linux-xanmod-lts-x64v2")
      ;;
    3)
      candidates=("linux-xanmod-x64v3" "linux-xanmod-lts-x64v3")
      ;;
    4)
      candidates=("linux-xanmod-x64v3" "linux-xanmod-lts-x64v3")
      ;;
    *)
      candidates=("linux-xanmod-x64v3" "linux-xanmod-lts-x64v3")
      ;;
  esac

  for pkg in "${candidates[@]}"; do
    if xanmod_package_available "$pkg"; then
      printf '%s' "$pkg"
      return 0
    fi
  done

  return 1
}

install_bbrv3_kernel() {
  local codename cpu_level current_kernel install_pkg="" key_tmp

  current_kernel="$(uname -r 2>/dev/null || true)"
  if [[ "$current_kernel" == *xanmod* ]]; then
    green "当前已运行 XanMod 内核：${current_kernel}"
    enable_bbr
    return 0
  fi

  cpu_level="$(detect_x86_64_level || true)"
  if [[ -z "$cpu_level" ]]; then
    yellow "当前 CPU / 虚拟化环境暂不支持自动选择 XanMod x86_64 内核包。"
    yellow "将继续安装协议，并应用当前内核可用的 TCP/BBR 调优。"
    enable_bbr
    return 0
  fi

  codename="$(detect_apt_codename)"
  if [[ -z "$codename" ]]; then
    yellow "无法识别 Debian / Ubuntu 发行版代号，跳过 XanMod 源。"
    yellow "将继续安装协议，并应用当前内核可用的 TCP/BBR 调优。"
    enable_bbr
    return 0
  fi

  yellow "正在添加 XanMod 官方源并安装适配 CPU x86-64-v${cpu_level} 的 BBRv3 内核。"
  mkdir -p "$(dirname "$XANMOD_KEYRING")"
  key_tmp="$(mktemp)"
  if ! download_xanmod_key "$key_tmp"; then
    rm -f "$key_tmp"
    yellow "将跳过强制更换 XanMod 内核，继续安装协议并应用当前内核可用的 TCP/BBR 调优。"
    enable_bbr
    return 0
  fi
  if ! gpg --dearmor --yes -o "$XANMOD_KEYRING" "$key_tmp"; then
    rm -f "$key_tmp"
    yellow "XanMod GPG key 转换失败，将跳过强制更换内核并继续安装协议。"
    enable_bbr
    return 0
  fi
  rm -f "$key_tmp"
  chmod 0644 "$XANMOD_KEYRING"
  printf 'deb [signed-by=%s] http://deb.xanmod.org %s main\n' "$XANMOD_KEYRING" "$codename" > "$XANMOD_APT_LIST"

  if ! apt-get update; then
    yellow "XanMod 源刷新失败，将跳过强制更换内核并继续安装协议。"
    enable_bbr
    return 0
  fi
  install_pkg="$(select_xanmod_package "$cpu_level" || true)"
  if [[ -z "$install_pkg" ]]; then
    yellow "XanMod 源中未找到适配 x86-64-v${cpu_level} 的可用内核包。"
    yellow "将跳过强制更换 XanMod 内核，继续安装协议并应用当前内核可用的 TCP/BBR 调优。"
    enable_bbr
    return 0
  fi
  yellow "将安装 XanMod 内核包：${install_pkg}"
  if [[ "$cpu_level" == "4" && "$install_pkg" == *x64v3* ]]; then
    yellow "说明：XanMod 当前常用包以 x64v3 为主，x86-64-v4 CPU 使用 x64v3 包。"
  fi

  if ! apt-get install -y "$install_pkg"; then
    yellow "${install_pkg} 安装失败，将跳过强制更换 XanMod 内核，继续安装协议。"
    enable_bbr
    return 0
  fi
  set_grub_default_first_entry
  refresh_grub_config
  enable_bbr

  if [[ "$(uname -r 2>/dev/null || true)" == *xanmod* ]]; then
    green "BBRv3 / XanMod 内核已生效：$(uname -r)"
  else
    BBRV3_REBOOT_REQUIRED="1"
    yellow "BBRv3 / XanMod 内核已安装，重启 VPS 后才会真正生效。"
    yellow "建议安装完成、保存节点后执行: reboot"
  fi
}

detect_memory_mb() {
  awk '/MemTotal:/ {printf "%d", $2 / 1024; exit}' /proc/meminfo 2>/dev/null || printf '0'
}

calculate_bbr_buffer_mb() {
  local mem_mb
  mem_mb="$(detect_memory_mb)"

  if ! [[ "$mem_mb" =~ ^[0-9]+$ ]] || [[ "$mem_mb" -le 0 ]]; then
    printf '64'
  elif [[ "$mem_mb" -lt 512 ]]; then
    printf '8'
  elif [[ "$mem_mb" -lt 1024 ]]; then
    printf '16'
  elif [[ "$mem_mb" -lt 2048 ]]; then
    printf '32'
  else
    printf '64'
  fi
}

clean_bbr_sysctl_conflicts() {
  local file="/etc/sysctl.conf"

  if [[ -f "$file" ]]; then
    if [[ ! -f "${file}.${APP_NAME}.bak" ]]; then
      cp -a "$file" "${file}.${APP_NAME}.bak" 2>/dev/null || true
    fi
    sed -i -E '/^[[:space:]]*net\.(core\.(default_qdisc|rmem_max|wmem_max|optmem_max|somaxconn|netdev_max_backlog)|ipv4\.(tcp_congestion_control|tcp_rmem|tcp_wmem|tcp_fastopen|tcp_mtu_probing|tcp_notsent_lowat|tcp_tw_reuse|tcp_fin_timeout|tcp_max_tw_buckets|tcp_slow_start_after_idle|tcp_syncookies|udp_rmem_min|udp_wmem_min))[[:space:]]*=/s/^/# disabled by vless-xhttp-reality-self: /' "$file" 2>/dev/null || true
  fi

  if [[ -L /etc/sysctl.d/99-sysctl.conf ]]; then
    rm -f /etc/sysctl.d/99-sysctl.conf 2>/dev/null || true
  fi
}

clean_dual_stack_sysctl_conflicts() {
  local file="/etc/sysctl.conf"

  if [[ -f "$file" ]]; then
    if [[ ! -f "${file}.${APP_NAME}.bak" ]]; then
      cp -a "$file" "${file}.${APP_NAME}.bak" 2>/dev/null || true
    fi
    sed -i -E '/^[[:space:]]*net\.ipv6\.bindv6only[[:space:]]*=/s/^/# disabled by vless-xhttp-reality-self: /' "$file" 2>/dev/null || true
  fi
}

ipv6_stack_available() {
  local disabled

  [[ -d /proc/sys/net/ipv6 ]] || return 1
  disabled="$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || printf '0')"
  [[ "$disabled" != "1" ]]
}

public_sing_box_listen_addr() {
  if ipv6_stack_available; then
    printf '::'
  else
    printf '0.0.0.0'
  fi
}

ensure_dual_stack_ipv6_bind() {
  if ! ipv6_stack_available; then
    return 0
  fi

  if ! command -v sysctl >/dev/null 2>&1; then
    yellow "未找到 sysctl，无法自动设置 IPv6 双栈监听；将继续写入配置。"
    return 0
  fi

  clean_dual_stack_sysctl_conflicts
  mkdir -p "$(dirname "$DUAL_STACK_SYSCTL")"
  cat > "$DUAL_STACK_SYSCTL" <<EOF
# Generated by ${APP_NAME}. Keep IPv6 wildcard listeners dual-stack.
net.ipv6.bindv6only = 0
EOF

  if ! sysctl -e -p "$DUAL_STACK_SYSCTL" >/dev/null 2>&1; then
    yellow "IPv6 双栈监听参数应用失败；如域名使用 AAAA，请确认系统允许 IPv6 socket 接收 IPv4 映射连接。"
  fi
}

enable_bbr() {
  local buffer_bytes buffer_mb cc core_buffer_bytes optmem_bytes qdisc available want_bbr=0

  if ! command -v sysctl >/dev/null 2>&1; then
    yellow "未找到 sysctl，已跳过 TCP/BBR 调优。"
    return 0
  fi

  clean_bbr_sysctl_conflicts
  buffer_mb="$(calculate_bbr_buffer_mb)"
  buffer_bytes=$((buffer_mb * 1024 * 1024))
  core_buffer_bytes=$((buffer_bytes * 2))
  if [[ "$core_buffer_bytes" -gt 134217728 ]]; then
    core_buffer_bytes=134217728
  fi
  optmem_bytes="$buffer_bytes"
  if [[ "$optmem_bytes" -gt 67108864 ]]; then
    optmem_bytes=67108864
  fi

  modprobe tcp_bbr >/dev/null 2>&1 || true
  # If modprobe failed, try installing linux-modules-extra for current kernel
  if ! sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -qw bbr; then
    if command -v apt-get >/dev/null 2>&1; then
      local ker_ver
      ker_ver="$(uname -r)"
      apt-get install -y -qq "linux-modules-extra-${ker_ver}" 2>/dev/null || true
      modprobe tcp_bbr >/dev/null 2>&1 || true
      modprobe tcp_bbr2 >/dev/null 2>&1 || true
    fi
  fi
  available="$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || true)"
  if printf '%s\n' "$available" | grep -qw bbr; then
    want_bbr=1
  else
    yellow "当前内核未提供 BBR，将先应用通用 TCP 调优。可用拥塞控制: ${available:-unknown}"
  fi

  cat > "$BBR_SYSCTL" <<EOF
# Generated by ${APP_NAME}. Optimized for TCP proxy throughput and latency.
net.core.default_qdisc = fq
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65536
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = ${core_buffer_bytes}
net.core.wmem_max = ${core_buffer_bytes}
net.core.optmem_max = ${optmem_bytes}
net.ipv4.tcp_rmem = 4096 87380 ${buffer_bytes}
net.ipv4.tcp_wmem = 4096 65536 ${buffer_bytes}
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_syncookies = 1
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 2097152
EOF

  if [[ "$want_bbr" == "1" ]]; then
    printf 'net.ipv4.tcp_congestion_control = bbr\n' >> "$BBR_SYSCTL"
  fi

  sysctl -e -p "$BBR_SYSCTL" >/dev/null 2>&1 || true

  # 网卡中断合并优化（降低延迟）
  local _iface
  _iface="$(ip route show default | awk '{print $5; exit}' 2>/dev/null || true)"
  if [[ -n "$_iface" ]] && command -v ethtool >/dev/null 2>&1; then
    ethtool -C "$_iface" adaptive-rx off adaptive-tx off rx-usecs 8 tx-usecs 8 2>/dev/null || true
  fi

  cc="$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || true)"
  qdisc="$(sysctl -n net.core.default_qdisc 2>/dev/null || true)"
  if [[ "$cc" == "bbr" ]]; then
    green "TCP/BBR 调优已应用：tcp_congestion_control=${cc}, default_qdisc=${qdisc:-unknown}, tcp_buffer=${buffer_mb}MB"
  else
    green "TCP 调优已应用；当前拥塞控制为: ${cc:-unknown}, default_qdisc=${qdisc:-unknown}, tcp_buffer=${buffer_mb}MB"
  fi
}

write_service_limit_dropin() {
  local dir="$1"
  local file="$2"

  if ! command -v systemctl >/dev/null 2>&1; then
    return 0
  fi

  mkdir -p "$dir"
  cat > "$file" <<EOF
[Service]
LimitNOFILE=1048576
TasksMax=infinity
EOF
}

write_sing_box_service_tuning() {
  write_service_limit_dropin "$SING_BOX_SERVICE_TUNING_DIR" "$SING_BOX_SERVICE_TUNING"
}

write_xray_service_tuning() {
  write_sing_box_service_tuning
}

write_anytls_service_tuning() {
  write_service_limit_dropin "$SING_BOX_SERVICE_TUNING_DIR" "$SING_BOX_SERVICE_TUNING"
}

write_ss2022_service_tuning() {
  write_service_limit_dropin "$SING_BOX_SERVICE_TUNING_DIR" "$SING_BOX_SERVICE_TUNING"
}

install_acme() {
  local tmp_dir=""
  if [[ ! -x "$ACME_SH" ]]; then
    yellow "正在安装 acme.sh..."
    if ! curl_fsSL https://get.acme.sh | sh -s email="$EMAIL" --force; then
      yellow "get.acme.sh 安装失败，尝试 GitHub archive 兜底安装。"
    fi
  fi

  if [[ ! -x "$ACME_SH" ]]; then
    tmp_dir="$(mktemp -d)"
    curl_fsSL https://github.com/acmesh-official/acme.sh/archive/master.tar.gz -o "${tmp_dir}/acme.sh.tar.gz"
    tar -xzf "${tmp_dir}/acme.sh.tar.gz" -C "$tmp_dir"
    (
      cd "${tmp_dir}/acme.sh-master"
      ./acme.sh --install --force -m "$EMAIL"
    )
    rm -rf "$tmp_dir"
  fi

  if [[ ! -x "$ACME_SH" ]]; then
    red "acme.sh 安装失败：未找到 ${ACME_SH}"
    exit 1
  fi
}

cert_files_exist() {
  [[ -s "$SSL_DIR/fullchain.cer" && -s "$SSL_DIR/private.key" ]]
}

cert_matches_domain() {
  if ! cert_files_exist; then
    return 1
  fi

  openssl x509 -in "$SSL_DIR/fullchain.cer" -noout -ext subjectAltName 2>/dev/null \
    | grep -Eqi "(^|[,[:space:]])DNS:${DOMAIN//./\\.}([,[:space:]]|$)"
}

cert_is_currently_valid() {
  if ! cert_files_exist; then
    return 1
  fi

  openssl x509 -checkend 0 -noout -in "$SSL_DIR/fullchain.cer" >/dev/null 2>&1
}

cert_pair_is_usable() {
  local cert_file="$1" key_file="$2" cert_pub key_pub

  [[ -s "$cert_file" && -s "$key_file" ]] || return 1
  openssl x509 -checkend 0 -noout -in "$cert_file" >/dev/null 2>&1 || return 1
  openssl x509 -in "$cert_file" -noout -ext subjectAltName 2>/dev/null \
    | grep -Eqi "(^|[,[:space:]])DNS:${DOMAIN//./\\.}([,[:space:]]|$)" || return 1

  cert_pub="$(openssl x509 -in "$cert_file" -pubkey -noout 2>/dev/null \
    | openssl pkey -pubin -outform der 2>/dev/null \
    | openssl dgst -sha256 -r 2>/dev/null \
    | awk '{print $1}')"
  key_pub="$(openssl pkey -in "$key_file" -pubout -outform der 2>/dev/null \
    | openssl dgst -sha256 -r 2>/dev/null \
    | awk '{print $1}')"

  [[ -n "$cert_pub" && "$cert_pub" == "$key_pub" ]]
}

install_cert_pair() {
  local cert_file="$1" key_file="$2"

  cert_pair_is_usable "$cert_file" "$key_file" || return 1
  mkdir -p "$SSL_DIR"
  if [[ "$(readlink -f "$cert_file" 2>/dev/null || true)" != "$(readlink -f "$SSL_DIR/fullchain.cer" 2>/dev/null || true)" ]]; then
    install -m 0644 "$cert_file" "$SSL_DIR/fullchain.cer"
  fi
  if [[ "$(readlink -f "$key_file" 2>/dev/null || true)" != "$(readlink -f "$SSL_DIR/private.key" 2>/dev/null || true)" ]]; then
    install -m 0600 "$key_file" "$SSL_DIR/private.key"
  fi
  chmod 600 "$SSL_DIR/private.key" || true
  cert_matches_domain && cert_is_currently_valid
}

default_acme_email() {
  printf 'admin@%s' "$DOMAIN"
}

normalize_ip_list() {
  python3 -c '
import ipaddress
import sys

seen = set()
for line in sys.stdin:
    value = line.strip().split("%", 1)[0]
    if not value:
        continue
    try:
        normalized = str(ipaddress.ip_address(value))
    except ValueError:
        continue
    if normalized not in seen:
        print(normalized)
        seen.add(normalized)
'
}

resolve_domain_ips() {
  local family="$1" domain="$2"

  python3 - "$family" "$domain" <<'PY'
import ipaddress
import socket
import sys

family = socket.AF_INET6 if sys.argv[1] == "6" else socket.AF_INET
domain = sys.argv[2]
seen = set()

try:
    infos = socket.getaddrinfo(domain, None, family, socket.SOCK_STREAM)
except socket.gaierror:
    sys.exit(0)

for info in infos:
    addr = info[4][0].split("%", 1)[0]
    try:
        normalized = str(ipaddress.ip_address(addr))
    except ValueError:
        continue
    if normalized not in seen:
        print(normalized)
        seen.add(normalized)
PY
}

is_global_ipv4() {
  local value="$1"
  python3 - "$value" <<'PY'
import ipaddress
import sys

try:
    ip = ipaddress.ip_address(sys.argv[1])
except ValueError:
    sys.exit(1)

sys.exit(0 if ip.version == 4 and ip.is_global else 1)
PY
}

detect_public_ipv4() {
  local ip url
  for url in \
    "https://api.ipify.org" \
    "https://ipv4.icanhazip.com" \
    "https://ifconfig.me/ip"; do
    ip="$(curl -4 -fsS --connect-timeout 5 --max-time 10 "$url" 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ -n "$ip" ]] && is_global_ipv4 "$ip"; then
      printf '%s\n' "$ip"
      return 0
    fi
  done
  return 1
}

preferred_direct_server_addr() {
  local a_records ipv4

  if [[ -n "${DIRECT_SERVER_ADDR:-}" ]]; then
    printf '%s\n' "$DIRECT_SERVER_ADDR"
    return 0
  fi

  if [[ -z "${DOMAIN:-}" ]]; then
    return 1
  fi

  a_records="$(resolve_domain_ips 4 "$DOMAIN" || true)"
  if [[ -n "$a_records" ]]; then
    DIRECT_SERVER_ADDR="$DOMAIN"
    printf '%s\n' "$DIRECT_SERVER_ADDR"
    return 0
  fi

  if ipv4="$(detect_public_ipv4)"; then
    DIRECT_SERVER_ADDR="$ipv4"
  else
    DIRECT_SERVER_ADDR="$DOMAIN"
  fi

  printf '%s\n' "$DIRECT_SERVER_ADDR"
}

local_global_ipv6_addresses() {
  command -v ip >/dev/null 2>&1 || return 0
  ip -o -6 addr show scope global 2>/dev/null \
    | awk '{split($4, a, "/"); print a[1]}' \
    | normalize_ip_list
}

prepare_acme_http01() {
  local a_records aaaa_records local_v6 ip matched=0

  ACME_HTTP01_HAS_AAAA="0"
  ACME_STANDALONE_LISTEN_ARGS=()

  a_records="$(resolve_domain_ips 4 "$DOMAIN" || true)"
  aaaa_records="$(resolve_domain_ips 6 "$DOMAIN" || true)"

  if [[ -z "$a_records" && -z "$aaaa_records" ]]; then
    red "域名 ${DOMAIN} 没有解析到 A 或 AAAA 记录，无法进行 HTTP-01 验证。"
    return 1
  fi

  if [[ -z "$aaaa_records" ]]; then
    return 0
  fi

  ACME_HTTP01_HAS_AAAA="1"
  ACME_STANDALONE_LISTEN_ARGS=(--listen-v6)
  yellow "检测到 ${DOMAIN} 存在 AAAA 记录，Let's Encrypt 可能优先通过 IPv6 验证。"
  printf '%s\n' "$aaaa_records" | print_indented_lines "AAAA: "

  local_v6="$(local_global_ipv6_addresses || true)"
  if [[ -z "$local_v6" ]]; then
    red "当前 VPS 未检测到全局 IPv6，但域名存在 AAAA 记录。"
    red "请先删除/暂停 AAAA 记录，或给 VPS 正确配置 IPv6 并放行 TCP 80 后再申请证书。"
    return 1
  fi

  while IFS= read -r ip; do
    if grep -Fxiq "$ip" <<< "$local_v6"; then
      matched=1
      break
    fi
  done <<< "$aaaa_records"

  if [[ "$matched" != "1" ]]; then
    red "域名 AAAA 记录没有指向当前 VPS 的任一全局 IPv6。"
    printf '%s\n' "$aaaa_records" | print_indented_lines "DNS AAAA: "
    printf '%s\n' "$local_v6" | print_indented_lines "本机 IPv6: "
    red "请把 AAAA 改到当前 VPS IPv6，或临时删除 AAAA 后再申请证书。"
    return 1
  fi

  yellow "acme.sh 将使用 --listen-v6；请确认云安全组和系统防火墙已放行 TCP 80/IPv6。"
}

print_acme_http01_failure_hint() {
  if [[ "${ACME_HTTP01_HAS_AAAA:-0}" == "1" ]]; then
    red "本次域名存在 AAAA 记录。若日志仍出现 IPv6 Connection refused，请检查："
    red "1. 云厂商安全组是否放行 TCP 80 的 IPv6 入站"
    red "2. VPS 系统防火墙是否放行 TCP 80/IPv6"
    red "3. AAAA 是否指向当前 VPS 的 IPv6；不使用 IPv6 时请删除 AAAA 后重试"
  fi
}

install_cert_from_acme_cache() {
  if [[ ! -x "$ACME_SH" ]]; then
    return 1
  fi

  "$ACME_SH" --install-cert -d "$DOMAIN" --ecc \
    --fullchain-file "$SSL_DIR/fullchain.cer" \
    --key-file "$SSL_DIR/private.key" \
    --reloadcmd "systemctl reload nginx || true" >/dev/null 2>&1 || return 1

  chmod 600 "$SSL_DIR/private.key" || true
  cert_matches_domain && cert_is_currently_valid
}

restore_cert_from_known_locations() {
  local cert key
  local dirs=(
    "$SSL_DIR"
    "/root/.acme.sh/${DOMAIN}_ecc"
    "/root/.acme.sh/${DOMAIN}"
  )
  local dir

  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    for key in "$dir/private.key" "$dir/${DOMAIN}.key"; do
      cert="$dir/fullchain.cer"
      if install_cert_pair "$cert" "$key"; then
        green "已复用本机已有证书：${cert}"
        return 0
      fi
    done
  done

  if [[ -d "$BACKUP_ROOT" ]]; then
    while IFS= read -r cert; do
      key="$(dirname "$cert")/private.key"
      if install_cert_pair "$cert" "$key"; then
        green "已从脚本备份中恢复证书：${cert}"
        return 0
      fi
    done < <(find "$BACKUP_ROOT" -type f -path "*/etc/ssl/${APP_NAME}/fullchain.cer" 2>/dev/null | sort -r)
  fi

  return 1
}

issue_cert() {
  mkdir -p "$SSL_DIR"

  if cert_matches_domain && cert_is_currently_valid; then
    green "检测到当前域名已有可用证书，跳过重新申请。"
    yellow "如需强制更新证书，请使用菜单 2。"
    chmod 600 "$SSL_DIR/private.key" || true
    return 0
  fi

  if restore_cert_from_known_locations; then
    return 0
  fi

  if install_cert_from_acme_cache; then
    green "已从 acme.sh 缓存恢复证书，无需重新下单。"
    return 0
  fi

  stop_common_services

  if port_in_use 80; then
    red "申请证书前检测到 80 端口被占用"
    show_port_usage 80
    exit 1
  fi

  prepare_acme_http01 || return 1

  "$ACME_SH" --set-default-ca --server letsencrypt || true
  if ! "$ACME_SH" --issue -d "$DOMAIN" --standalone "${ACME_STANDALONE_LISTEN_ARGS[@]}" --keylength ec-256 --force; then
    yellow "证书申请失败，正在尝试复用 acme.sh 缓存或脚本备份中的旧证书。"
    if install_cert_from_acme_cache || restore_cert_from_known_locations; then
      green "已恢复可用证书，继续安装。"
      return 0
    fi
    print_acme_http01_failure_hint
    red "证书申请失败且未找到可复用证书。"
    red "如果是 Let's Encrypt exact set 限流，请等提示的 retry after 时间之后再重试，或临时换一个子域名。"
    return 1
  fi

  if ! "$ACME_SH" --install-cert -d "$DOMAIN" --ecc \
    --fullchain-file "$SSL_DIR/fullchain.cer" \
    --key-file "$SSL_DIR/private.key" \
    --reloadcmd "systemctl reload nginx || true"; then
    yellow "证书安装到 ${SSL_DIR} 失败，尝试复用本机已有证书。"
    restore_cert_from_known_locations || return 1
  fi

  chmod 600 "$SSL_DIR/private.key" || true
  cert_matches_domain && cert_is_currently_valid
}

cleanup_generated_nginx_files() {
  rm -f "$NGINX_CFG" "$NGINX_REALIP_CFG"
}

write_fake_site() {
  mkdir -p "$WEB_ROOT"
  cat > "${WEB_ROOT}/index.html" <<EOF
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${DOMAIN}</title>
  <style>
    body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;background:#f6f7fb;margin:0}
    .box{max-width:520px;margin:12vh auto;background:#fff;padding:32px;border-radius:16px;box-shadow:0 10px 30px rgba(0,0,0,.08)}
    h1{margin:0 0 12px;font-size:26px}
    p{color:#555;line-height:1.7}
    input{width:100%;padding:12px;margin:8px 0;border:1px solid #ddd;border-radius:10px;box-sizing:border-box}
    button{width:100%;padding:12px;background:#111;color:#fff;border:0;border-radius:10px;cursor:pointer}
  </style>
</head>
<body>
  <div class="box">
    <h1>Member Login</h1>
    <p>Welcome back. Please sign in to continue.</p>
    <input placeholder="Email">
    <input placeholder="Password" type="password">
    <button>Sign in</button>
  </div>
</body>
</html>
EOF
}

write_nginx_fake_conf() {
  mkdir -p /etc/nginx/conf.d
  rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf 2>/dev/null || true

  cat > "$NGINX_CFG" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 127.0.0.1:${TARGET_PORT} ssl default_server;
    ssl_reject_handshake on;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_timeout 1h;
    ssl_session_cache shared:SSL:10m;
}

server {
    listen 127.0.0.1:${TARGET_PORT} ssl http2;
    server_name ${DOMAIN};

    ssl_certificate     ${SSL_DIR}/fullchain.cer;
    ssl_certificate_key ${SSL_DIR}/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    root ${WEB_ROOT};
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

  nginx -t
  systemctl enable nginx >/dev/null 2>&1 || true
  systemctl restart nginx
}

write_nginx_realip_conf() {
  rm -f "$NGINX_REALIP_CFG"
}

strip_nginx_proxy_protocol_for_target_port() {
  local file

  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    TARGET_PORT_ENV="$TARGET_PORT" python3 - "$file" <<'PY'
import os
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
target_port = os.environ["TARGET_PORT_ENV"]
text = path.read_text(encoding="utf-8")
out = []
changed = False

for line in text.splitlines(True):
    if re.match(r'^\s*#', line):
        out.append(line)
        continue

    m = re.match(r'^(\s*)listen\s+([^;]*?)\s*;\s*$', line)
    if not m:
        out.append(line)
        continue

    indent, inner = m.groups()
    if f"127.0.0.1:{target_port}" not in inner and f"localhost:{target_port}" not in inner:
        out.append(line)
        continue

    parts = [part for part in inner.split() if part != "proxy_protocol"]
    new_line = f"{indent}listen {' '.join(parts)};"
    if line.endswith("\n"):
        new_line += "\n"
    out.append(new_line)
    changed = changed or (new_line != line)

if changed:
    path.write_text("".join(out), encoding="utf-8")
PY
  done < <(list_active_nginx_files)
}

migrate_existing_nginx_to_target_port() {
  local changed=0 file

  write_nginx_realip_conf

  if nginx_active_config_has_target_port && ! nginx_active_config_has_443; then
    yellow "检测到 Nginx 已监听在 127.0.0.1:${TARGET_PORT}，跳过重复迁移"
    cleanup_generated_nginx_files
    write_nginx_realip_conf
    strip_nginx_proxy_protocol_for_target_port
    nginx -t
    systemctl enable nginx >/dev/null 2>&1 || true
    systemctl restart nginx
    return 0
  fi

  while IFS= read -r file; do
    [[ -f "$file" ]] || continue

    if ! grep -Eq '^[[:space:]]*listen[[:space:]].*443([[:space:];]|$)' "$file"; then
      continue
    fi

    TARGET_PORT_ENV="$TARGET_PORT" APP_NAME_ENV="$APP_NAME" python3 - "$file" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
target_port = sys.argv[2] if len(sys.argv) > 2 else None
if target_port is None:
    target_port = pathlib.os.environ["TARGET_PORT_ENV"]
app_name = pathlib.os.environ["APP_NAME_ENV"]

text = path.read_text(encoding="utf-8")
out = []
changed = False

for line in text.splitlines(True):
    if re.match(r'^\s*#', line):
        out.append(line)
        continue

    if re.search(r'^\s*listen\s+\[::\]:443\b', line):
        indent = re.match(r'^(\s*)', line).group(1)
        suffix = "\n" if line.endswith("\n") else ""
        out.append(f"{indent}# migrated by {app_name}: {line.lstrip().rstrip()}{suffix}")
        changed = True
        continue

    m = re.match(r'^(\s*)listen\s+([^;]*?)\s*;\s*$', line)
    if not m:
        out.append(line)
        continue

    indent, inner = m.groups()
    if not re.search(r'(^|[\s:])443($|[\s])', inner):
        out.append(line)
        continue

    parts = inner.split()
    new_parts = []
    replaced = False

    for part in parts:
        if not replaced and (part == '443' or part == '*:443' or part.endswith(':443') or part == '[::]:443'):
            replaced = True
            continue
        if part in ('default_server', 'proxy_protocol'):
            continue
        new_parts.append(part)

    if not replaced:
        out.append(line)
        continue

    new_line = f"{indent}listen 127.0.0.1:{target_port}"
    if new_parts:
        new_line += " " + " ".join(new_parts)
    new_line += ";\n" if line.endswith("\n") else ";"

    out.append(new_line)
    changed = True

if changed:
    path.write_text("".join(out), encoding="utf-8")
PY
  done < <(list_active_nginx_files)

  if nginx_active_config_has_target_port; then
    changed=1
  fi

  if [[ $changed -ne 1 ]]; then
    if nginx_active_config_has_target_port; then
      yellow "检测到 Nginx 已监听在 127.0.0.1:${TARGET_PORT}，跳过重复迁移"
    else
      red "未检测到可迁移的 Nginx 443 配置"
      exit 1
    fi
  fi

  cleanup_generated_nginx_files
  write_nginx_realip_conf
  strip_nginx_proxy_protocol_for_target_port

  nginx -t
  systemctl enable nginx >/dev/null 2>&1 || true
  systemctl restart nginx
}


# === installer.sh merged below ===

pause() {
  read -r -p "按回车继续..." _
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

  if [[ "$INSTALL_WANT_TUIC" == "1" ]]; then
    install_tuic_core
  fi

  if [[ "$INSTALL_WANT_VMESS" == "1" ]]; then
    install_vmess_core
  fi

  save_state
  if has_vless_install; then
    cycle_argo_edge_server
    build_client_files
  fi
  if has_hy2_install; then
    cycle_argo_edge_server
    build_hysteria2_share_files
  fi
  if has_anytls_install; then
    cycle_argo_edge_server
    build_anytls_share_files
  fi
  if has_ss2022_install; then
    cycle_argo_edge_server
    build_ss2022_share_files
  fi
  if has_argo_install; then
    cycle_argo_edge_server
    build_argo_share_files || true
  fi
  if has_tuic_install; then
    cycle_argo_edge_server
    build_tuic_share_files
  fi
  if has_vmess_install; then
    cycle_argo_edge_server
    build_vmess_share_files
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
