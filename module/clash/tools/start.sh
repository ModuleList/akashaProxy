#!/system/bin/sh
# 修改后的 /data/clash/tools/start.sh

# 定义自定义内核路径
CLASH_KERNEL="/data/clash/clashkernel/clashMeta"
SCRIPTS_DIR="/data/clash/scripts"

# 验证内核文件是否存在
if [ ! -x "$CLASH_KERNEL" ]; then
    echo -e "\033[1;31m[错误] 内核文件未找到或不可执行！\033[0m"
    echo "当前路径：$CLASH_KERNEL"
    echo "请检查："
    echo "1. 文件是否存在：ls -l $CLASH_KERNEL"
    echo "2. 文件权限：chmod 755 $CLASH_KERNEL"
    exit 1
fi

# 启动服务
{
    echo "=== 启动流程开始 ==="
    echo "内核路径：$CLASH_KERNEL"
    
    # 设置环境变量
    export CLASH_BIN_PATH="$CLASH_KERNEL"
    
    # 执行启动脚本
    "$SCRIPTS_DIR/clash.service" -s && \
    sleep 3 && \
    "$SCRIPTS_DIR/clash.iptables" -s
    
    echo "=== 启动完成 ==="
} 2>&1 | tee /data/clash/logs/start.log