#!/usr/bin/env bash
# ==============================================================================
# VPS-Ultimate-Box: 一键全自动落地满血代理与全维度安全加速环境
# 协议包含: VLESS-Reality (TCP 443) + Hysteria 2 (UDP 端口跳跃 20000-50000)
# 双栈支持: 原生 IPv4 + IPv6 双栈监听与冗余容灾 (IPv4 阻断自动切换 IPv6)
# 系统优化: BBR + 16MB 内核网络大缓存 + Path MTU 探测 + TFO 快速打开
# 安全保密: 零日志策略 (Zero-Log) + Fail2ban 智能防暴力破解封禁
# ==============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PURPLE='\033[0;35m'
PLAIN='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
WHITE='\033[1;37m'

info() { echo -e "${BLUE}[INFO]${PLAIN} $1"; }
ok()   { echo -e "${GREEN}[OK]${PLAIN} $1"; }
warn() { echo -e "${YELLOW}[WARN]${PLAIN} $1"; }
err()  { echo -e "${RED}[ERROR]${PLAIN} $1"; exit 1; }

# 1. 权限检查
[[ $EUID -ne 0 ]] && err "必须使用 root 权限运行此脚本！(例如: sudo bash $0)"

echo -e "${PURPLE}${BOLD}"
cat << "EOF"
==================================================================
   __     ______  ____    _   _ _ _   _                 _       
   \ \   / /  _ \/ ___|  | | | | | |_(_)_ __ ___   __ _| |_ ___ 
    \ \ / /| |_) \___ \  | | | | | __| | '_ ` _ \ / _` | __/ _ \
     \ V / |  __/ ___) | | |_| | | |_| | | | | | | (_| | ||  __/
      \_/  |_|   |____/   \___/|_|\__|_|_| |_| |_|\__,_|\__\___|
                                                            
       一键全自动部署: VLESS-Reality + Hysteria 2 端口跳跃
       IPv4/IPv6 双栈容灾 + 内核 BBR 调优 + 零日志 + Fail2ban
==================================================================
EOF
echo -e "${PLAIN}"

# 2. 获取公网 IPv4 与 IPv6
info "正在探测本机公网 IP 地址 (IPv4 / IPv6 双栈)..."
IPV4=$(curl -s4m 6 https://api.ipify.org || curl -s4m 6 https://ip.sb || curl -s4m 6 https://ifconfig.me || true)
IPV6=$(curl -s6m 6 https://api64.ipify.org || curl -s6m 6 https://ip.sb || curl -s6m 6 https://ifconfig.co || true)

if [[ -n "$IPV4" ]]; then
    ok "公网 IPv4: ${GREEN}${BOLD}${IPV4}${PLAIN}"
else
    warn "未检测到公网 IPv4 地址 (可能为纯 IPv6 VPS)"
fi

if [[ -n "$IPV6" ]]; then
    ok "公网 IPv6: ${GREEN}${BOLD}${IPV6}${PLAIN} (具备 IPv4/IPv6 双通道抗封锁能力)"
else
    info "暂未检测到分配的公网 IPv6 地址 (服务器已预开启 IPv6 双栈监听，若主机商后续分配将自动生效)"
fi

[[ -z "$IPV4" && -z "$IPV6" ]] && err "无法获取任何公网 IP 地址，请检查服务器网络！"

# 3. 更新系统与基础依赖
info "正在更新系统软件包并安装依赖组件..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y > /dev/null 2>&1 || true
apt-get install -y curl wget unzip openssl jq procps iptables iptables-persistent fail2ban > /dev/null 2>&1
ok "基础软件包安装完成"

# 4. Linux 内核网络高并发与高吞吐调优 (支持 IPv4/IPv6 双栈加速)
info "正在配置 Linux 内核网络参数 (BBR + 16MB 缓存 + TFO + MTU 探测 + IPv6 支持)..."
cat << 'EOF' > /etc/sysctl.d/99-vps-ultimate.conf
# 开启 BBR 拥塞控制与 FQ 队列
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# 提升接收/发送缓冲区到 16MB，消除高延迟长肥管道断崖式降速
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# 系统连接队列与高并发优化
fs.file-max = 1000000
net.core.somaxconn = 32768
net.ipv4.tcp_max_syn_backlog = 16384
net.core.netdev_max_backlog = 16384

# 开启 TCP Fast Open (减少 1 次 RTT 握手延时)
net.ipv4.tcp_fastopen = 3

# 自动 Path MTU 探测，根治丢包卡顿
net.ipv4.tcp_mtu_probing = 1

# TIME_WAIT 端口极速复用，加速并发网页请求
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# 心跳保活
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5

# 启用 IPv6 支持并允许自动接收路由通告 (SLAAC)
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2
EOF
sysctl --system > /dev/null 2>&1
ok "内核网络深度调优已生效 (BBR 已启用，IPv4/IPv6 双栈就绪)"

# 5. 部署 VLESS-Reality (Xray v1.8.24 黄金高兼容版本，支持双栈监听)
info "正在安装与配置 VLESS-Reality 协议 (TCP 443 双栈监听)..."
mkdir -p /usr/local/bin /usr/local/etc/xray

# 下载官方稳定二进制
curl -L -s -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-linux-64.zip"
unzip -o /tmp/xray.zip -d /usr/local/bin/ xray > /dev/null 2>&1
chmod +x /usr/local/bin/xray
rm -f /tmp/xray.zip

# 生成凭证
KEY_OUTPUT=$(/usr/local/bin/xray x25519)
REALITY_PRIV=$(echo "$KEY_OUTPUT" | grep -i "Private" | awk '{print $NF}')
REALITY_PUB=$(echo "$KEY_OUTPUT" | grep -iE "(Password|Public)" | awk '{print $NF}')
VLESS_UUID=$(/usr/local/bin/xray uuid)
REALITY_SID=$(openssl rand -hex 4)
REALITY_SNI="addons.mozilla.org"

# 写入零日志 Xray 配置文件 (listen: :: 自动兼听 IPv4 与 IPv6)
cat << EOF > /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "none",
    "access": "/dev/null",
    "error": "/dev/null"
  },
  "inbounds": [
    {
      "listen": "::",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${VLESS_UUID}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${REALITY_SNI}:443",
          "xver": 0,
          "serverNames": [
            "${REALITY_SNI}"
          ],
          "privateKey": "${REALITY_PRIV}",
          "shortIds": [
            "${REALITY_SID}"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {
        "domainStrategy": "AsIs"
      }
    }
  ],
  "dns": {
    "servers": [
      "1.1.1.1",
      "8.8.8.8",
      "2606:4700:4700::1111",
      "2001:4860:4860::8888"
    ],
    "queryStrategy": "UseIP"
  }
}
EOF

# 配置 Xray systemd
cat << 'EOF' > /etc/systemd/system/xray.service
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartSec=2s
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xray > /dev/null 2>&1
systemctl restart xray
ok "VLESS-Reality 部署成功并已守护启动 (端口 443 支持 IPv4/IPv6 双栈访问)"

# 6. 部署 Hysteria 2 (官方最新版) + 端口跳跃 (20000-50000)
info "正在安装与配置 Hysteria 2 协议 (UDP 34443 & 端口跳跃)..."
bash <(curl -fsSL https://get.hy2.sh/) > /dev/null 2>&1 || true
mkdir -p /etc/hysteria

# 生成 10 年期自签高强度 ECDSA 证书
openssl ecparam -name prime256v1 -genkey -noout -out /etc/hysteria/server.key
openssl req -new -x509 -sha256 -key /etc/hysteria/server.key -out /etc/hysteria/server.crt -days 3650 -subj "/CN=www.bing.com" > /dev/null 2>&1
chown -R hysteria:hysteria /etc/hysteria 2>/dev/null || true
chmod 700 /etc/hysteria
chmod 600 /etc/hysteria/server.key
chmod 644 /etc/hysteria/server.crt

HY2_PORT=34443
HY2_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
HY2_SNI="www.bing.com"

# 写入 Hysteria 2 配置文件 (:34443 自动在 Linux 下监听双栈 [::]:34443)
cat << EOF > /etc/hysteria/config.yaml
listen: :${HY2_PORT}

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: ${HY2_PASS}

masquerade:
  type: proxy
  proxy:
    url: https://${HY2_SNI}
    rewriteHost: true

outbounds:
  - name: default
    type: direct
    direct:
      mode: auto
EOF

# 配置 Hysteria 2 静默零日志 systemd 服务
cat << 'EOF' > /etc/systemd/system/hysteria-server.service
[Unit]
Description=Hysteria Server Service (config.yaml)
After=network.target

[Service]
Type=simple
User=hysteria
Group=hysteria
WorkingDirectory=/etc/hysteria
ExecStart=/usr/local/bin/hysteria server --config /etc/hysteria/config.yaml --log-level error
StandardOutput=null
StandardError=journal
Restart=on-failure
RestartSec=3s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# 部署 UDP 端口跳跃与防火墙放行 (同时覆盖 IPv4 与 IPv6)
# IPv4 iptables
iptables -t nat -D PREROUTING -p udp --dport 20000:50000 -j REDIRECT --to-ports ${HY2_PORT} 2>/dev/null || true
iptables -t nat -A PREROUTING -p udp --dport 20000:50000 -j REDIRECT --to-ports ${HY2_PORT}
iptables -D INPUT -p udp --dport 20000:50000 -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p udp --dport 20000:50000 -j ACCEPT
iptables -D INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p tcp --dport 443 -j ACCEPT

# IPv6 ip6tables (如果系统支持 ip6tables)
ip6tables -D INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
ip6tables -I INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
ip6tables -D INPUT -p udp --dport 20000:50000 -j ACCEPT 2>/dev/null || true
ip6tables -I INPUT -p udp --dport 20000:50000 -j ACCEPT 2>/dev/null || true
ip6tables -t nat -D PREROUTING -p udp --dport 20000:50000 -j REDIRECT --to-ports ${HY2_PORT} 2>/dev/null || true
ip6tables -t nat -A PREROUTING -p udp --dport 20000:50000 -j REDIRECT --to-ports ${HY2_PORT} 2>/dev/null || true

netfilter-persistent save > /dev/null 2>&1 || true

systemctl daemon-reload
systemctl enable hysteria-server > /dev/null 2>&1
systemctl restart hysteria-server
ok "Hysteria 2 部署成功并已开启端口跳跃 (20000-50000，支持双栈)"

# 7. 部署 Fail2ban 自动防爆破
info "正在配置 Fail2ban 自动防御系统..."
cat << 'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 86400
findtime = 600
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = 22
EOF
systemctl enable fail2ban > /dev/null 2>&1
systemctl restart fail2ban
ok "Fail2ban 自动防黑客爆破系统已上线"

# 8. 组装节点链接与 Base64 订阅
NODE_LIST=""

# IPv4 节点
if [[ -n "$IPV4" ]]; then
    VLESS_V4="vless://${VLESS_UUID}@${IPV4}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PUB}&sid=${REALITY_SID}&type=tcp#VPS-Reality-IPv4"
    HY2_V4="hy2://${HY2_PASS}@${IPV4}:${HY2_PORT}/?mport=20000-50000&insecure=1&sni=${HY2_SNI}#VPS-Hy2-IPv4"
    NODE_LIST="${VLESS_V4}
${HY2_V4}"
fi

# IPv6 节点 (如果检测到公网 IPv6)
if [[ -n "$IPV6" ]]; then
    VLESS_V6="vless://${VLESS_UUID}@[${IPV6}]:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PUB}&sid=${REALITY_SID}&type=tcp#VPS-Reality-IPv6备用"
    HY2_V6="hy2://${HY2_PASS}@[${IPV6}]:${HY2_PORT}/?mport=20000-50000&insecure=1&sni=${HY2_SNI}#VPS-Hy2-IPv6备用"
    if [[ -z "$NODE_LIST" ]]; then
        NODE_LIST="${VLESS_V6}
${HY2_V6}"
    else
        NODE_LIST="${NODE_LIST}
${VLESS_V6}
${HY2_V6}"
    fi
fi

BASE64_SUB=$(echo -e "$NODE_LIST" | base64 -w 0 2>/dev/null || echo -e "$NODE_LIST" | base64 | tr -d '\n')

# 备份到根目录文件
cat << EOF > /root/vps_nodes.txt
======================================================
VPS-Ultimate-Box 节点配置与订阅信息
======================================================

$(if [[ -n "$IPV4" ]]; then cat << INNER_EOF
【IPv4 主力节点】:
1. VLESS-Reality:
${VLESS_V4}

2. Hysteria 2 (端口跳跃):
${HY2_V4}
INNER_EOF
fi)

$(if [[ -n "$IPV6" ]]; then cat << INNER_EOF
【IPv6 容灾备用节点 (防 IPv4 封锁)】:
1. VLESS-Reality IPv6:
${VLESS_V6}

2. Hysteria 2 IPv6:
${HY2_V6}
INNER_EOF
fi)

【Base64 纯单行订阅字符串 (导入可同时录入所有可用节点)】:
${BASE64_SUB}
======================================================
EOF

# 9. 输出展示卡片
echo ""
echo -e "${GREEN}${BOLD}==================================================================${PLAIN}"
echo -e "${GREEN}${BOLD}           🎉 恭喜！VPS 全套环境与双栈双协议部署完成！          ${PLAIN}"
echo -e "${GREEN}${BOLD}==================================================================${PLAIN}"
echo ""
echo -e "${YELLOW}${BOLD}方式一：纯单行 Base64 订阅导入（强烈推荐 ⭐⭐⭐⭐⭐）${PLAIN}"
echo -e "${DIM}复制下方整行字符串，在 Karing/v2rayN/Clash 点击'从剪贴板导入'即可秒录入全部节点：${PLAIN}"
echo ""
echo -e "${WHITE}${BOLD}${BASE64_SUB}${PLAIN}"
echo ""
echo -e "${YELLOW}${BOLD}方式二：明文节点链接${PLAIN}"
if [[ -n "$IPV4" ]]; then
    echo -e "${DIM}【IPv4 通道】:${PLAIN}"
    echo -e "${BLUE}1. Reality: ${VLESS_V4}${PLAIN}"
    echo -e "${BLUE}2. Hy2:     ${HY2_V4}${PLAIN}"
fi
if [[ -n "$IPV6" ]]; then
    echo -e "${DIM}【IPv6 通道 (万一 IPv4 被墙，无缝切换此节点)】:${PLAIN}"
    echo -e "${BLUE}3. Reality-IPv6: ${VLESS_V6}${PLAIN}"
    echo -e "${BLUE}4. Hy2-IPv6:     ${HY2_V6}${PLAIN}"
else
    echo ""
    echo -e "${DIM}💡 提示: 本 VPS 目前未分配公网 IPv6 地址。服务端已开启双栈监听与防火墙放行，若主机商开通分配 IPv6，只需在客户端将 IP 替换为 [IPv6] 即可直接连接！${PLAIN}"
fi
echo ""
echo -e "${GREEN}==================================================================${PLAIN}"
echo -e "${DIM} 配置文件已永久备份在服务器本地: /root/vps_nodes.txt${PLAIN}"
echo -e "${DIM} 建议将客户端分组设置为【URL-Test / 自动优选】，享受断线自动秒切！${PLAIN}"
echo -e "${GREEN}==================================================================${PLAIN}"
echo ""
