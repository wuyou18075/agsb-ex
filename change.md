# 变更记录

## 2026-06-24 - 智能订阅链接改进

### 修改列表

| 文件 | 说明 |
|------|------|
| `lib/protocols.sh` | `subscription_url()` 支持无绑定域名时 fallback 到公网 IP；`print_subscription_links()` 添加 `/all` 链接；`show_node_info()` 添加 TUIC 协议显示 |
| `lib/subscription.sh` | `write_uri_subscription_raw()` 添加 TUIC 输出；Python 订阅服务器添加 `/all` 端点支持（`/sub-xxx/all` 返回所有协议 URI）；HTML 页面添加 `/all` 链接 |
| `lib/base.sh` | `save_state()` 添加 `TUIC_SERVER_ADDR` 持久化 |

### 改动细节

1. **订阅 URL 生成 (`subscription_url`)**：
   - 有域名时使用 `DOMAIN` + `SUB_PORT`
   - 无域名时通过 `preferred_direct_server_addr` 或 `ip.sb` 获取公网 IP 作为 fallback

2. **`/all` 端点**：
   - Python 服务器支持 `GET /sub-xxx/all` 返回 `raw.txt`（所有协议原始 URI，ss:// vless:// vmess:// 格式）
   - `print_subscription_links` 输出 `All(所有协议URI): /all`
   - HTML 页面添加了 `/all` 链接

3. **TUIC 协议支持**：
   - `write_uri_subscription_raw` 中添加 TUIC 输出
   - `show_node_info` 中添加 TUIC URL 显示
   - `save_state` 中添加 `TUIC_SERVER_ADDR` 持久化
