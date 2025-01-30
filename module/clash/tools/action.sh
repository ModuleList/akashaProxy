#!/system/bin/sh

source /data/clash/clash.env
pid=$(curl -sL http://127.0.0.1:${Clash_ui_port} | grep hello)
if [[ "${pid}" ]]; then
    echo "正在停止akashaProxy."
    /data/clash/scripts/clash.service -k && /data/clash/scripts/clash.iptables -k
else
    echo "正在启动akashaProxy."
    /data/clash/scripts/clash.service -s && /data/clash/scripts/clash.iptables -s
fi
