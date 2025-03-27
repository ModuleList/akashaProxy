#!/system/bin/sh
CLASH_ROOT="/data/clash"
SCRIPTS_DIR="$CLASH_ROOT/scripts"
LOG_DIR="$CLASH_ROOT/logs"

{
echo "=== 停止流程开始 ==="

# 1. 停止核心服务
echo "停止核心服务..."
"$SCRIPTS_DIR/clash.service" -k

# 2. 清理网络规则（静默模式）
echo "清理网络规则..."
"$SCRIPTS_DIR/clash.iptables" -k 2>/dev/null

# 3. 终止进程
echo "终止残留进程..."
pkill -9 -x "clashMeta"

# 4. 清除路由表
echo "清理路由表..."
ip route flush table 666 >/dev/null 2>&1
ip -6 route flush table 666 >/dev/null 2>&1

# 5. 强制释放TUN设备（关键！）
echo "强制释放TUN接口..."
ip tuntap del mode tun Meta 2>/dev/null
ip tuntap del mode tun tun0 2>/dev/null
ip tuntap del mode tun vpn 2>/dev/null

# 6. 重新加载TUN驱动
echo "重置TUN内核模块..."
rmmod tun 2>/dev/null
modprobe tun

# 7. 恢复DNS
echo "恢复DNS配置..."
ndc resolver flushdefaultif
settings delete global private_dns_mode

# 8. 清除网络命名空间
echo "清除网络命名空间..."
ndc network destroy 100 2>/dev/null
ip netns delete meta 2>/dev/null

# 9. 修复权限
echo "修复系统权限..."
chmod 666 /dev/tun
setenforce 0

echo "=== 停止流程结束 ==="
} 2>&1 | tee "$LOG_DIR/stop.log"