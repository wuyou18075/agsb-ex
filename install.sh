#!/usr/bin/env bash
set -Eeuo pipefail
# =============================================================================
# vless-xhttp-reality-self - Multi-protocol VPS proxy installer (entry)
# =============================================================================


APP_NAME="vless-xhttp-reality-self"
APP_VERSION="0.19.11"
INSTALL_SCRIPT="/usr/local/bin/${APP_NAME}.sh"
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/tao-t356/vless-xhttp-reality-self/main/scripts/install.sh"

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


# ==== Load modules ====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/base.sh"
source "${SCRIPT_DIR}/lib/services.sh"
source "${SCRIPT_DIR}/lib/protocols.sh"
source "${SCRIPT_DIR}/lib/subscription.sh"
source "${SCRIPT_DIR}/lib/installer.sh"

# ==== Entry ====
main "$@"
