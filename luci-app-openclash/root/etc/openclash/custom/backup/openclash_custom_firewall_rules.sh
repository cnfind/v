#!/bin/sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

# This script is called by /etc/init.d/openclash
# Add your custom firewall rules here, they will be added after the end of the OpenClash iptables rules

LOG_OUT "Tip: Start Add Custom Firewall Rules..."
# -------------------------------------- 自定义脚本开始 --------------------------------------
LOG_OUT "国内IP绕过 Openclash 内核功能开启"
ipset -! flush china_ip_route
ipset -! restore </etc/openclash/china_ip_route.ipset 2>/dev/null
# 避免国内流量经过代理，需要走代理的保留 Fake IP
iptables -t nat -D openclash -p tcp -s 0.0.0.0/0 -d 0.0.0.0/0 -j REDIRECT --to-ports 7892
# 避免宿主机自身的出口流量全部走代理
iptables -t nat -D openclash_output -p tcp -m owner ! --uid-owner 65534 -j REDIRECT --to-ports 7892
# 避免来自国内的 UDP 流量经过代理
iptables -t mangle -D openclash -p udp -j TPROXY --tproxy-mark 0x162/0xffffffff --on-port 7895
# 除 Fake IP 外，非国内 IP 的流量重定向到代理
iptables -t nat -A openclash -p tcp -m set ! --match-set china_ip_route dst -j REDIRECT --to-ports 7892
# 重定向非国内的 UDP 流量到代理
iptables -t mangle -A openclash -p udp -m set ! --match-set china_ip_route dst -j TPROXY --tproxy-mark 0x162/0xffffffff --on-port 7895
# 对于宿主机自身的 TCP 流量除了 Fake IP 外，对于非国内 IP 的流量且非 OpenClash 的出口流量重定向到代理
iptables -t nat -A openclash_output -p tcp -m set ! --match-set china_ip_route dst -m owner ! --uid-owner 65534 -j REDIRECT --to-ports 7892
# ADG
##LOG_OUT "重启 AdGuardHome 程序..."
##/etc/init.d/AdGuardHome restart
# -------------------------------------- 自定义脚本结束 --------------------------------------
exit 0