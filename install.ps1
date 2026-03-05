# 通勤提醒脚本 - Windows 自动安装脚本
# 运行方式：以管理员身份打开 PowerShell，执行 .\install.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  通勤提醒脚本 - Windows 安装向导" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Python 是否安装
Write-Host "[1/5] 检查 Python 环境..." -ForegroundColor Yellow
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "  Python 未安装，正在引导安装..." -ForegroundColor Red
    Write-Host "  请访问 https://www.python.org/downloads/ 下载并安装 Python 3.8+" -ForegroundColor White
    Write-Host "  安装时务必勾选 'Add Python to PATH'" -ForegroundColor White
    Write-Host ""
    Read-Host "  安装完成后，按回车键继续"
}

$pythonVersion = python --version 2>&1
Write-Host "  当前 Python 版本: $pythonVersion" -ForegroundColor Green

# 安装依赖
Write-Host ""
Write-Host "[2/5] 安装 Python 依赖..." -ForegroundColor Yellow
pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "  依赖安装失败，尝试使用国内镜像源..." -ForegroundColor Red
    pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
}

# 检查 Edge 浏览器
Write-Host ""
Write-Host "[3/5] 检查 Microsoft Edge 浏览器..." -ForegroundColor Yellow
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$edgePathAlt = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"

if (Test-Path $edgePath) {
    Write-Host "  Microsoft Edge 已安装" -ForegroundColor Green
} elseif (Test-Path $edgePathAlt) {
    Write-Host "  Microsoft Edge 已安装" -ForegroundColor Green
} else {
    Write-Host "  Microsoft Edge 未安装，正在引导安装..." -ForegroundColor Red
    Write-Host "  请访问 https://www.microsoft.com/zh-cn/edge/download 下载安装" -ForegroundColor White
    Write-Host ""
    Read-Host "  安装完成后，按回车键继续"
}

# 创建配置提示
Write-Host ""
Write-Host "[4/5] 配置脚本..." -ForegroundColor Yellow
if (-not (Test-Path "router.py")) {
    Write-Host "  错误：router.py 文件不存在" -ForegroundColor Red
    exit 1
}

Write-Host "  请编辑 router.py 文件，配置以下内容：" -ForegroundColor White
Write-Host "  - 高德地图 API Key" -ForegroundColor White
Write-Host "  - 起点/终点坐标和名称" -ForegroundColor White
Write-Host "  - 邮箱 SMTP 配置" -ForegroundColor White
Write-Host ""

# 测试运行
Write-Host "[5/5] 测试运行脚本..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  准备测试运行..." -ForegroundColor White
Write-Host "  （如果配置未完成，可能会报错，这是正常的）" -ForegroundColor Gray
Write-Host ""

$testRun = Read-Host "  是否现在测试运行？(y/n)"
if ($testRun -eq "y" -or $testRun -eq "Y") {
    python router.py
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  安装完成！" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "后续步骤：" -ForegroundColor White
Write-Host "  1. 编辑 router.py 填入你的配置信息" -ForegroundColor Gray
Write-Host "  2. 运行 python router.py 测试" -ForegroundColor Gray
Write-Host "  3. 设置定时任务（可选）" -ForegroundColor Gray
Write-Host ""
Write-Host "详细文档请查看 DEPLOY.md" -ForegroundColor Cyan
Write-Host ""

# 设置定时任务提示
Write-Host "是否需要设置每日定时任务？(y/n)" -ForegroundColor Yellow
$scheduleTask = Read-Host ""
if ($scheduleTask -eq "y" -or $scheduleTask -eq "Y") {
    $time = Read-Host "  请输入运行时间（格式：HH:mm，例如 17:30）"
    $action = New-ScheduledTaskAction -Execute "python" -Argument "`"$PSScriptRoot\router.py`"" -WorkingDirectory $PSScriptRoot
    $trigger = New-ScheduledTaskTrigger -Daily -At $time
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "通勤提醒" -Description "每日通勤路线提醒" -Force
    Write-Host "  定时任务已创建！每天 $time 将自动运行脚本" -ForegroundColor Green
}

Write-Host ""
Write-Host "安装完成，按回车键退出..."
Read-Host
