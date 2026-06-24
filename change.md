# 变更记录

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

