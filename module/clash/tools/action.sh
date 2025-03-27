#!/system/bin/sh
# /data/clash/tools/action.sh

CLASH_ROOT="/data/clash"
CLASH_PROCESS="clashMeta"

# 检查进程是否存在
if pgrep -x "$CLASH_PROCESS" >/dev/null; then
    echo "检测到正在运行的clashMeta进程，执行停止操作"
    sh "$CLASH_ROOT/tools/stop.sh"
else
    echo "未检测到clashMeta进程，执行启动操作"
    sh "$CLASH_ROOT/tools/start.sh"
fi

# 最终状态验证
sleep 1
if pgrep -x "$CLASH_PROCESS" >/dev/null; then
    echo "当前状态：服务运行中 PID: $(pgrep -x "$CLASH_PROCESS")"
else
    echo "当前状态：服务已停止"
fi