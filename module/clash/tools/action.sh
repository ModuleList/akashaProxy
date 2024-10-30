status=$(ps -A | grep clash)

if [ "${status}" ]; then
    echo "正在停止akashaProxy."
    /data/clash/scripts/clash.service -k && /data/clash/scripts/clash.iptables -k
else
    echo "正在启动akashaProxy."
    /data/clash/scripts/clash.service -s && /data/clash/scripts/clash.iptables -s
fi


