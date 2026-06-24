# 变更记录

## 2026-06-25 - 修复全安装缺少 TUIC 和 VMess 协议

### 问题
选择"全部安装"后，`full_install()` 中未调用 `install_tuic_core()` 和 `install_vmess_core()`，导致 TUIC 和 VMess 实际未被安装，节点信息只显示有安装到的协议。

### 修改列表

| 文件 | 说明 |
|------|------|
| `lib/installer.sh` | `full_install()` 补充 TUIC 和 VMess 的安装调用；`show_node_info()` 后的分享文件生成补充 TUIC 和 VMess |

### 改动细节

1. **全安装流程修复**：
   - `full_install()` 末尾新增 `install_tuic_core` 和 `install_vmess_core` 调用
   - 安装完成后生成分享文件时，补充 `build_tuic_share_files` 和 `build_vmess_share_files`

---

## 2026-06-25 - 修复 sing-box 配置中 VMess-WS 入站标签重复

### 问题
`write_sing_box_config()` 的 jq 模板中，VMess-WS 入站对象出现了两次（两段完全相同的 `"tag": "vmess-ws-in"` 代码块），导致 sing-box 启动时报错 `duplicate inbound tag: vmess-ws-in`。

### 修改列表

| 文件 | 说明 |
|------|------|
| `lib/protocols.sh` | 删除第二段重复的 VMess-WS 入站对象（lines 248~279） |

---

## 2026-06-24 - 修复订阅链接 URL 使用伪装域名而非服务器 IP 的问题

### 问题
在自签证书模式下，`subscription_url()` 输出的订阅链接使用了 `DOMAIN`（REALITY 伪装站域名，如 `www.apple.com`）而不是服务器的实际公网 IP。

### 修改列表

| 文件 | 说明 |
|------|------|
| `lib/protocols.sh` | `subscription_url()` 中当 `SELF_SIGN_CERT=1` 时跳过 DOMAIN，直接使用 `detect_public_ipv4` 获取公网 IP |
| `lib/subscription.sh` | Python 订阅服务器中 `/all` 路径的匹配逻辑修复，使用 `rfind("/")` 代替硬编码 `[:-4]` |

### 改动细节

1. **订阅 URL 生成 (`subscription_url`)**：
   - 自签模式时使用 `detect_public_ipv4` 获取公网 IP 作为 fallback
   - 有域名且非自签模式时使用 `DOMAIN` + `SUB_PORT`
   - 无域名时通过 `preferred_direct_server_addr` 或 `ip.sb` 获取公网 IP

2. **`/all` 路径匹配**：
   - Python 服务器使用 `rfind("/")` 代替硬编码 `[:-4]`，兼容路径结尾/不带斜杠的情况

