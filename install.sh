#!/usr/bin/env bash
set -Eeuo pipefail
# =============================================================================
# vless-xhttp-reality-self - Multi-protocol VPS proxy installer (entry)
# =============================================================================

GITHUB_REPO="wuyou18075/agsb-ex"
GITHUB_BRANCH="main"
GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"

APP_NAME="vless-xhttp-reality-self"
APP_VERSION="0.19.11"
INSTALL_SCRIPT="/usr/local/bin/${APP_NAME}.sh"
INSTALL_SCRIPT_URL="${GITHUB_RAW}/install.sh"

NODE_NAME_VLESS="vless+tcp-reality"
NODE_NAME_HY2="hy2"
NODE_NAME_ANYTLS="anytls"
NODE_NAME_ARGO="argo"
NODE_PREFIX=""
NODE_NAME_VLESS_BASE="vless+tcp-reality"
NODE_NAME_HY2_BASE="hy2"
NODE_NAME_ANYTLS_BASE="anytls"
NODE_NAME_ARGO_BASE="argo"
NODE_NAME_SS2022_BASE="ss2022"
NODE_NAME_TUIC_BASE="tuic-v5"
NODE_NAME_VMESS_BASE="vmess-ws"
NODE_NAME_VLESS="$NODE_NAME_VLESS_BASE"
NODE_NAME_HY2="$NODE_NAME_HY2_BASE"
NODE_NAME_ANYTLS="$NODE_NAME_ANYTLS_BASE"
NODE_NAME_ARGO="$NODE_NAME_ARGO_BASE"
NODE_NAME_SS2022="$NODE_NAME_SS2022_BASE"
NODE_NAME_TUIC="$NODE_NAME_TUIC_BASE"
NODE_NAME_VMESS="$NODE_NAME_VMESS_BASE"

# ==== Auto-detect runtime environment ====
SCRIPT_SRC="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SRC")" 2>/dev/null && pwd || dirname "$SCRIPT_SRC" 2>/dev/null || echo ".")"

if [[ ! -f "${SCRIPT_DIR}/lib/main.sh" ]]; then
  REMOTE_DIR="$(mktemp -d)" || { echo "无法创建临时目录"; exit 1; }
  mkdir -p "${REMOTE_DIR}/lib"

  echo "检测到远程安装，正在下载模块文件..."
  for _lib in main.sh node.sh test.sh; do
    _url="${GITHUB_RAW}/lib/${_lib}"
    _out="${REMOTE_DIR}/lib/${_lib}"
    if ! curl -fsSL "$_url" -o "$_out"; then
      echo "下载失败: $_url"
      exit 1
    fi
  done
  echo "模块文件已下载到 ${REMOTE_DIR}/lib"
  SCRIPT_DIR="$REMOTE_DIR"
fi

# ==== Source modules ====
source "${SCRIPT_DIR}/lib/main.sh"
source "${SCRIPT_DIR}/lib/node.sh"
source "${SCRIPT_DIR}/lib/test.sh"

# ==== Entry ====
main "$@"
