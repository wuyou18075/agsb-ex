# agsb-ex
一键部署脚本
```bash
bash <(curl -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' -fsSL "https://raw.githubusercontent.com/wuyou18075/agsb-ex/main/install.sh?t=$(date +%s)")
```
# vless-xhttp-reality-self 功能文档

> 多协议 VPS 代理安装管理脚本。  
> 支持 7 种主流代理协议的一键部署、迁移管理、智能订阅、Argo 隧道、系统内核调优。

---

## 项目结构

```
install.sh                        # 入口文件（常量 + source 5 个模块 + main 调用）
lib/
├── base.sh                       # 核心工具（状态管理、端口检测、备份回滚、网络工具）
├── services.sh                   # 系统服务（BBR/XanMod 内核、Nginx 部署迁移、ACME 证书）
├── protocols.sh                  # 协议实现（全部 7 种协议的安装/配置/分享/清理）
├── subscription.sh               # 订阅服务（Clash YAML、Python HTTPS 服务器、URI 生成）
└── installer.sh                  # 安装编排（菜单、状态查看、日志、重置、卸载）
```

---

## 功能清单

### 1. 一键安装与重装

| 功能 | 说明 |
|---|---|
| 自签证书模式 | 无需域名，自动选最优 REALITY 伪装站域名并测速 |
| Let's Encrypt 模式 | 需要域名 A 记录指向 VPS，自动签发 ECC 证书 |
| 五合一协议安装 | 可选全部或自定义组合安装 |
| 节点名称前缀 | 可选前缀，多服务器区分 |
| 重复安装检测 | 自动识别已有配置并覆盖/迁移 |
| 安装前自动备份 | 备份当前配置，支持回滚 |
| 自动回滚 | 安装中断自动恢复上次备份 |

### 2. 支持的代理协议

| 协议 | 核心 | 传输 | 端口 |
|---|---|---|---|
| VLESS-REALITY | sing-box | TCP + REALITY | 443（sing-box 监听） |
| Hysteria2 | sing-box | UDP + Port Hopping | 随机高位 UDP |
| AnyTLS | sing-box | TCP + TLS | 随机高位 TCP |
| Shadowsocks-2022 | sing-box | TCP/UDP | 随机高位 TCP/UDP |
| VMess-WebSocket | sing-box | WS + TLS/无TLS | 随机高位 TCP |
| TUIC-v5 | sing-box | UDP + QUIC | 随机高位 TCP/UDP |
| Argo Tunnel | cloudflared | WS over Cloudflare | 本地后端端口 |

### 3. Nginx 部署与迁移

| 功能 | 说明 |
|---|---|
| 伪装站自动部署 | 写 Nginx config + HTML 登录页（fake 模式） |
| 443 端口迁移 | 检测已占用 443 的 Nginx 站点，自动迁移到 127.0.0.1:8443 |
| proxy_protocol 迁移 | 自动剥离 `proxy_protocol` 标记 |
| 反向迁移 | 卸载时可选择恢复迁移前的站点配置 |

### 4. 证书管理

| 功能 | 说明 |
|---|---|
| acme.sh 自动安装 | 多兜底源安装 |
| HTTP-01 验证 | 自动处理 IPv4/IPv6 双栈 ACME 验证 |
| 证书缓存复用 | 优先从 acme.sh 缓存/脚本备份/已知路径恢复 |
| 证书指纹 | 生成 SHA-256 指纹和 public key pin |
| 强制续签 | 菜单支持强制更新证书 |
| 自签证书 | 自签 ECC 证书用于无域名场景 |

### 5. 智能订阅服务

| 功能 | 说明 |
|---|---|
| HTTPS 订阅服务器 | 内嵌 Python3 服务器，双栈监听 |
| 多客户端自动适配 | 按 User-Agent 返回 Clash/mihomo/Shadowrocket/v2rayN/浏览器 |
| Clash YAML 生成 | 全量/稳定版两种 Clash YAML |
| 订阅页面 | 美观的订阅链接引导页面 |
| 订阅自动刷新 | systemd timer + path 双重触发 |
| 合并订阅文件 | 本地合并所有协议的 URI |

### 6. Cloudflare Argo 隧道

| 功能 | 说明 |
|---|---|
| Named Tunnel | 固定域名 + Tunnel Token，推荐 |
| Quick Tunnel | 免账号，随机 trycloudflare.com 域名 |
| 域名自动解析 | 从 journal/log 文件自动捕获 Argo 域名 |
| 自动刷新 | systemd oneshot + timer + path 三重保障 |
| 协议优选 | 自动测速 http2/quic * auto/IPv4/IPv6 组合，选最低延迟 |
| 速度测试 HTML 页面 | 生成可交互的浏览器测速页，提交优选域名回 VPS |
| 30+ 内置优选域名 | 含手动收集的三网优化域名 |

### 7. 节点分享文件

每个协议独立生成：
- 分享 TXT（含参数说明）
- 订阅 URI（纯文本 + Base64）
- 二维码 PNG
- 客户端配置文件
  - Hysteria2：官方 YAML + sing-box JSON + Clash YAML
  - AnyTLS、SS2022：Clash/mihomo 兼容 YAML
  - VMess：v2rayN JSON
  - TUIC：tuic URI

### 8. 系统调优

| 功能 | 说明 |
|---|---|
| BBR 自动启用 | 自动安装内核模块、配置 sysctl 参数 |
| BBRv3 内核安装 | 自动检测 CPU 级别，安装 XanMod 内核 |
| TCP 参数优化 | 根据内存自动计算缓冲区大小 |
| IPv6 双栈处理 | 关闭 IPv6 only 绑定，保证双栈兼容 |
| fq/cake qdisc | 菜单支持手动切换 |
| 代理机器调优 | 自动测速国内友好点，应用最优参数 |
| service limit dropin | 为 sing-box/xray/mihomo 设置最大文件数和无限 tasks |
| 网卡中断合并优化 | 自适应关闭，降低延迟 |

### 9. 端口管理

| 功能 | 说明 |
|---|---|
| 端口占用检测 | 自动检测 80/443/TARGET_PORT 占用的进程 |
| 随机端口分配 | 各协议自动分配随机高位端口 |
| Port Hopping | Hysteria2 自动配置 iptables DNAT 端口跳跃 |

### 10. 备份与恢复

| 功能 | 说明 |
|---|---|
| 安装前自动备份 | Nginx、证书、sing-box 配置、状态、各协议配置 |
| 恢复最新备份 | 菜单可恢复 |
| 自动回滚 | 安装中断时自动恢复 |
| 卸载恢复 | 迁移模式卸载可恢复原站点 |

### 11. 管理交互

| 功能 | 说明 |
|---|---|
| 交互菜单 | 主菜单含 0-99 选项入口 |
| 快捷命令 agsb | 安装后注册到 /usr/local/bin/agsb |
| 状态查看 | 显示所有服务状态、端口监听、版本、备份列表 |
| 日志查看 | sing-box/nginx/cloudflared/订阅服务日志 |
| 重启服务 | 一键重启所有相关服务 |
| 密码重置 | Hysteria2/AnyTLS/SS2022 单独重置密码 |
| 节点重置 | 重置 UUID + REALITY key pair |
| 协议级卸载 | 单独卸载某个协议 |
| 完全卸载 | 清理所有生成的文件，可选恢复迁移前站点 |

### 12. 安装流程优化

| 功能 | 说明 |
|---|---|
| 上次配置复用 | 选自签证书时自动读取上次安装配置，询问是否复用，默认否 |
| 缓存自动清理 | 新安装时先清除旧浏览器测速缓存，再重生成测速页面 |
| Argo 域名选择 | 进入 Argo 域名菜单时自动检测浏览器测速提交结果并提示使用 |
| WebRTC 本地 IP 检测 | 浏览器测速页面使用 WebRTC 绕过代理检测真实本地出口 IP，兜底 ipify API |
| 提交日志 | 后端 Python 服务器打印时间戳 + 客户端 IP + 提交域名列表 |
| 提交回显客户端 IP | 浏览器页面提交后显示 VPS 看到的客户端 IP |
| 全协议安装菜单 | 直连协议（a1-a8）+ CDN 协议（b1-b5）分类选择，支持逗号混选 |

### 13. 脚本自维护

| 功能 | 说明 |
|---|---|
| 脚本自安装 | 安装时复制自身到 /usr/local/bin |
| 远程更新 | 可通过 GitHub raw 重新拉取 |
| jshook 认证 | 所有 curl 请求带 jshook header |

---

## 依赖

运行时自动安装：

- curl、wget、openssl、nginx、jq
- ca-certificates、python3、qrencode
- iptables、nftables、systemd
- sing-box（自官方脚本）
- acme.sh（自动安装）
- cloudflared（自动下载）
- XanMod 内核（可选，通过官方源）

## 兼容性

| 项目 | 支持 |
|---|---|
| 系统 | Debian >= 10 / Ubuntu >= 20.04 |
| 架构 | x86_64, aarch64, armv7 |
| 内核 | 默认 BBR，可选升级 XanMod BBRv3 |

---

> 本文档由脚本结构自动生成，后续功能变更会自动维护更新。
