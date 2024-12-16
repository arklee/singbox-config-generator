# 设置策略路由
ip rule add fwmark 1 table 100 
ip route add local 0.0.0.0/0 dev lo table 100

#代理局域网设备
nft add table singbox
nft add chain singbox prerouting { type filter hook prerouting priority 0 \; }
nft add rule singbox prerouting ip daddr {127.0.0.1/32, 224.0.0.0/4, 255.255.255.255/32} return
nft add rule singbox prerouting meta l4proto tcp ip daddr 192.168.0.0/16 return
nft add rule singbox prerouting ip daddr 192.168.0.0/16 udp dport != 53 return
nft add rule singbox prerouting mark 0xff return # 直连 0xff 流量
nft add rule singbox prerouting meta l4proto {tcp, udp} mark set 1 tproxy to 127.0.0.1:12345 accept # 转发至 singbox 12345 端口

# 代理网关本机
nft add chain singbox output { type route hook output priority 0 \; }
nft add rule singbox output ip daddr {127.0.0.1/32, 224.0.0.0/4, 255.255.255.255/32} return
nft add rule singbox output meta l4proto tcp ip daddr 192.168.0.0/16 return
nft add rule singbox output ip daddr 192.168.0.0/16 udp dport != 53 return
nft add rule singbox output mark 0xff return # 直连 0xff 流量
nft add rule singbox output meta l4proto {tcp, udp} mark set 1 accept # 重路由至 prerouting

# DIVERT 规则
nft add table filter
nft add chain filter divert { type filter hook prerouting priority -150 \; }
nft add rule filter divert meta l4proto tcp socket transparent 1 meta mark set 1 accept