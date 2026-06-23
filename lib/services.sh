#!/usr/bin/env bash
# =============================================================================
# services.sh - BBR/XanMod/Nginx/Cert/Systemd tuning
# =============================================================================

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

