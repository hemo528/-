#!/bin/bash

# 通勤提醒脚本 - Linux/macOS 自动安装脚本
# 运行方式：chmod +x install.sh && ./install.sh

echo "========================================"
echo "  通勤提醒脚本 - Linux/macOS 安装向导"
echo "========================================"
echo ""

# 检查 Python
echo "[1/5] 检查 Python 环境..."
if ! command -v python3 &> /dev/null; then
    echo "  Python 未安装，正在引导安装..."
    echo "  Ubuntu/Debian: sudo apt-get install python3 python3-pip"
    echo "  macOS: brew install python3"
    echo ""
    read -p "  安装完成后，按回车键继续"
fi

pythonVersion=$(python3 --version)
echo "  当前 Python 版本: $pythonVersion"

# 检查 pip
if ! command -v pip3 &> /dev/null; then
    echo "  pip 未安装，正在安装..."
    # Ubuntu/Debian
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3-pip
    fi
fi

# 安装依赖
echo ""
echo "[2/5] 安装 Python 依赖..."
pip3 install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "  依赖安装失败，尝试使用国内镜像源..."
    pip3 install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
fi

# 检查浏览器
echo ""
echo "[3/5] 检查浏览器..."
if command -v chromium &> /dev/null; then
    echo "  Chromium 已安装"
elif command -v chromium-browser &> /dev/null; then
    echo "  Chromium 已安装"
elif command -v google-chrome &> /dev/null; then
    echo "  Chrome 已安装"
elif [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    echo "  Chrome 已安装"
else
    echo "  浏览器未安装，正在引导安装..."
    echo "  Ubuntu/Debian: sudo apt-get install chromium-browser"
    echo "  macOS: brew install chromium"
    echo ""
    read -p "  安装完成后，按回车键继续"
fi

# 配置提示
echo ""
echo "[4/5] 配置脚本..."
if [ ! -f "router.py" ]; then
    echo "  错误：router.py 文件不存在"
    exit 1
fi

echo "  请编辑 router.py 文件，配置以下内容："
echo "  - 高德地图 API Key"
echo "  - 起点/终点坐标和名称"
echo "  - 邮箱 SMTP 配置"
echo ""

# 测试运行
echo "[5/5] 测试运行脚本..."
echo ""
echo "  准备测试运行..."
echo "  （如果配置未完成，可能会报错，这是正常的）"
echo ""
read -p "  是否现在测试运行？(y/n): " testRun
if [ "$testRun" = "y" ] || [ "$testRun" = "Y" ]; then
    python3 router.py
fi

echo ""
echo "========================================"
echo "  安装完成！"
echo "========================================"
echo ""
echo "后续步骤："
echo "  1. 编辑 router.py 填入你的配置信息"
echo "  2. 运行 python3 router.py 测试"
echo "  3. 设置定时任务（可选）"
echo ""
echo "详细文档请查看 DEPLOY.md"
echo ""

# 设置定时任务提示
read -p "是否需要设置每日定时任务？(y/n): " scheduleTask
if [ "$scheduleTask" = "y" ] || [ "$scheduleTask" = "Y" ]; then
    read -p "  请输入运行时间（格式：HH:MM，例如 17:30）: " runTime

    # 获取脚本绝对路径
    scriptPath=$(readlink -f "$0")
    scriptDir=$(dirname "$scriptPath")

    # 添加 crontab 任务
    (crontab -l 2>/dev/null | grep -v "router.py"; echo "30 17 * * * cd $scriptDir && /usr/bin/python3 router.py >> $scriptDir/log.txt 2>&1") | crontab -

    echo "  定时任务已创建！每天 $runTime 将自动运行脚本"
fi

echo ""
echo "安装完成！"
