# 🚀 VPS-Ultimate-Box (VPS 满血全自动优化与双栈双协议一键部署项目)

> **极简・极致・全自动化**：为 Debian / Ubuntu VPS 打造的工业级一键环境搭建项目。集成了 **VLESS-Reality (TCP 443)** 与 **Hysteria 2 (UDP 端口跳跃 20000-50000)** 双顶尖抗封锁协议，深度定制 **Linux 内核网络大缓存 (BBR + 16MB 缓冲区 + MTU 探测 + TFO)**，全栈支持 **原生 IPv4 / IPv6 双通道监听与容灾兜底**，内置 **Fail2ban 智能防爆破** 与 **全维度零日志 (Zero-Log)** 隐私保护。
>
> 部署完成后自动输出节点链接与 **Base64 一键订阅字符串**，客户端（Karing、v2rayN、Clash 等）直接复制即可秒速导入！

---

## ✨ 核心特性

- 🛡️ **双顶尖协议深度协同**：
  - **VLESS-Reality (TCP 443)**：伪装为 `addons.mozilla.org`，真实 TLS 1.3 证书握手，指纹完全契合主流浏览器，抗审查能力极强，日常浏览极度平稳。特别锁定 `Xray v1.8.24` 黄金稳定内核，完美兼容各类客户端（彻底规避 Xray 26+ 后量子加密引发的握手失败）。
  - **Hysteria 2 (UDP 34443 & 20000-50000 端口跳跃)**：基于定制 QUIC 协议，集成 `iptables / ip6tables` 动态端口跳跃（Port Hopping），彻底击穿晚高峰 ISP 针对单个 UDP 端口的 QoS 限速与丢包，百兆跨洋宽带跑满。
- 🌐 **IPv4 + IPv6 全栈监听与故障兜底（Anti-GFW 终极防线）**：
  - 核心服务默认绑定双栈通配地址（`::`），同时接受 IPv4 与 IPv6 外部连接。
  - 自动探测并输出 IPv4 与 IPv6 独立节点；一旦 IPv4 遭遇防火墙阻断或局部断流，客户端自动平滑切换至 IPv6 通道，保障全天候不断联。
- ⚡ **Linux 内核深度网络调优**：
  - 自动开启 **Google BBR** 拥塞控制与 **FQ** 队列算法。
  - 将 TCP 接收/发送缓冲区扩大至 **16MB**，消除高延迟长肥管道（BDP）断崖式掉速，破除 10Mbps 跨洋限速魔咒。
  - 启用 **TCP Fast Open (TFO=3)**，降低 1 次 RTT 握手延时；开启 **Path MTU Probing (MTU探测)**，根除数据包分片丢包导致的网页卡死。
  - 完整开放 IPv6 路由通告（SLAAC）与内核网络栈。
- 🔒 **全天候安全与保密防护**：
  - **Fail2ban 智能防御**：针对 Debian 12 / Ubuntu 自动接入 `systemd` 日志后端，自动拦截并封禁全网恶意 SSH 扫描工具与爆破黑客（超频重试直接封禁 24 小时）。
  - **全维度零日志 (Zero-Log)**：Xray 与 Hysteria 2 均配置为静默零日志（`/dev/null`），不记录任何访问目标、IP 及连接行为，彻底保护数字隐私。
- 📦 **开箱即用，一键导入**：
  - 安装完毕终端自动打印明文双栈节点链接与 **单行 Base64 订阅**。
  - 配置自动备份至服务器 `/root/vps_nodes.txt`，随时可回看。

---

## ⚡ 快速开始（一键安装）

在任何崭新的 **Debian 11/12** 或 **Ubuntu 20.04/22.04/24.04** VPS 上，以 `root` 权限执行以下单行命令即可：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/vps-ultimate-box/main/install.sh)
```

> 💡 **提示**：请将上述命令中的 `YOUR_GITHUB_USERNAME` 替换为您实际 Fork 或推送的 GitHub 用户名。若直接使用本地脚本，可在 VPS 执行：
> ```bash
> curl -O https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/vps-ultimate-box/main/install.sh && chmod +x install.sh && ./install.sh
> ```

---

## 💡 深度科普：使用 IPv6 是否体验更佳？

很多用户常问：**IPv6 会比 IPv4 更好用吗？我们该如何取舍？**

### 1. IPv6 的显著优势
- **天生防封锁（地址池极大）**：IPv4 全球仅 43 亿个，防火墙很容易把单个 IP 拉黑。而 IPv6 地址多达 $2^{128}$ 个，防火墙对 IPv6 的拦截策略相对宽松很多，不易被误封。
- **纯净度高（告别疯狂人机验证）**：由于 IPv6 人均独立公网 IP，不经过运营商多层 NAT 共享池，Google、Cloudflare 等安全风控对干净的 IPv6 几乎不弹出验证码。
- **中国移动 / 手机 5G 路由往往更快**：国内三大运营商（尤其是**中国移动**）在 IPv6 国际出口骨干网（CIPv6）上带宽充裕且轻载，移动 5G 或家宽直连美西 IPv6 时，延迟和丢包率往往显著优于拥堵的 IPv4 骨干网。

### 2. IPv6 的潜在局限
- **电信普通 163 骨干网晚高峰可能丢包**：中国电信传统的普通 163 出口在晚高峰可能对 IPv6 同样存在拥堵。
- **部分外围 Wi-Fi 不支持**：某些老旧酒店或公司内网路由器没有开启 IPv6 DHCP。

### 3. 最佳实践建议（黄金法则）
> **“以 IPv4 / Hysteria 2 为速度主力，以 IPv6 为容灾保底”**。  
> 在客户端（如 Karing）配置 **URL-Test（自动测速）** 分流组，让客户端每隔一定周期自动向两个 IP 测速。在 IPv6 通畅优质的网络下自动走 IPv6，在普通网络走 IPv4；一旦 IPv4 受到任何外部干扰，无需人工干预即可毫秒级无感切换至 IPv6！

---

## 📱 客户端配置与使用指南

脚本执行完毕后，终端将输出如下内容：

```text
==================================================================
           🎉 恭喜！VPS 全套环境与双栈双协议部署完成！          
==================================================================

方式一：纯单行 Base64 订阅导入（强烈推荐 ⭐⭐⭐⭐⭐）
复制下方整行字符串，在 Karing/v2rayN/Clash 点击'从剪贴板导入'即可秒录入全部节点：

dmxlc3M6Ly9hMGUy...（单行加密订阅文本）...

方式二：明文双节点链接
【IPv4 通道】:
1. Reality: vless://...
2. Hy2:     hy2://...

【IPv6 通道 (备用容灾)】:
3. Reality-IPv6: vless://...
4. Hy2-IPv6:     hy2://...
```

### 1. 客户端推荐
- **全平台首选**：**[Karing](https://karing.app/)**（完全开源，原生内建 sing-box 内核，同时完美支持 VLESS-Reality 与 Hysteria 2 端口跳跃）。
- **Windows**：[v2rayN](https://github.com/2dust/v2rayN)。
- **Android**：[v2rayNG](https://github.com/2dust/v2rayNG) 或 [NekoBox](https://github.com/MatsuriDayo/NekoBoxForAndroid)。
- **macOS / iOS**：[Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev) 或 Surge / Shadowrocket。

### 2. 导入与双节点自动容灾
- **一键导入**：复制终端生成的 **Base64 单行订阅字符串**，在客户端中选择 **“从剪贴板添加 / 导入订阅”**。
- **自动切换与容灾设置**：
  1. 打开客户端的 **分流规则 / 代理分组**。
  2. 将导入的节点聚合进同一个分组。
  3. 将策略模式设为 **【URL-Test】（自动测速优选）** 或 **【Fallback】（故障自动转移）**：
     - **URL-Test 模式**：客户端定期探测延迟，自动走当前延迟最低、速度最快的链路（晚高峰 UDP 畅通时走 Hy2，遇干扰自动秒切 Reality 或 IPv6）。
     - **Fallback 模式**：优先走主力节点，一旦发生网络抖动或丢包，0.5秒内无感切换至备用节点救援。

---

## 🛠️ 服务器常用维护命令

| 功能 | 执行命令 |
| :--- | :--- |
| **查看节点信息备份** | `cat /root/vps_nodes.txt` |
| **查看 Reality 服务状态** | `systemctl status xray` |
| **重启 Reality 服务** | `systemctl restart xray` |
| **查看 Hysteria 2 状态** | `systemctl status hysteria-server` |
| **重启 Hysteria 2 服务** | `systemctl restart hysteria-server` |
| **查看 Fail2ban 防爆破封禁列表** | `fail2ban-client status sshd` |
| **查看当前 TCP 拥塞控制 (BBR)** | `sysctl net.ipv4.tcp_congestion_control` |
| **查看当前 IPv4 / IPv6 NAT 规则** | `iptables -t nat -L -n -v` / `ip6tables -t nat -L -n -v` |

---

## 📂 项目结构

```
.
├── install.sh     # 核心一键部署安装脚本 (兼容 Debian 11/12, Ubuntu 20.04/22.04/24.04)
├── README.md      # 项目说明与使用配置指南
└── LICENSE        # MIT 开源协议
```

---

## ⚠️ 注意事项与排错说明

1. **Reality 节点的 Mux (多路复用) 设置**：
   - VLESS-Reality 搭配 `flow: xtls-rprx-vision` 时，客户端**严禁开启 Mux**（多路复用）。若在客户端强制勾选 Mux，将破坏 Vision 的 TLS 流控协议头，导致握手失败。保持 Mux 关闭即可获得极致的原生 TLS 伪装体验。
2. **防火墙端口放行**：
   - 脚本已自动通过 `iptables` 与 `ip6tables` 开放 TCP `443` 与 UDP `20000-50000` 端口范围。
   - 若您的 VPS 位于云服务商（如腾讯云轻量、阿里云、AWS EC2、Oracle Cloud、Google Cloud），请务必在**服务商控制台的安全组规则（Security Group）**中放行：
     - **TCP**: `443`
     - **UDP**: `20000-50000`（以及 34443）
3. **域名绑定与 CDN 伪装说明**：
   - 本套方案采用 VLESS-Reality 借牌偷渡模式，直接偷取主流顶级站点证书指纹，**无需个人购买与解析域名**，天生抗封锁。
   - 不建议在此类大吞吐 UDP / 高速代理前套用 Cloudflare CDN（免费版 CDN 会阻断 UDP 并带来二次高延迟）。

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 开源。欢迎 Star、Fork 与提交 PR！
