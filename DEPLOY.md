# 通勤提醒脚本 - 部署指南

## 目录
- [功能概述](#功能概述)
- [环境要求](#环境要求)
- [准备工作](#准备工作)
- [安装步骤](#安装步骤)
- [配置说明](#配置说明)
- [运行测试](#运行测试)
- [定时任务设置](#定时任务设置)
- [常见问题](#常见问题)

---

## 功能概述

本脚本可以：
1. 查询通勤路线（驾车）
2. 生成路线地图（HTML）
3. 自动截图生成图片
4. 发送邮件通知

---

## 环境要求

### 操作系统
- Windows 10/11
- Linux (Ubuntu/Debian/CentOS)
- macOS

### 软件依赖
- Python 3.8+
- Microsoft Edge 浏览器
- 网络连接（用于调用高德地图 API 和发送邮件）

---

## 准备工作

### 1. 申请高德地图 API Key

1. 访问 [高德开放平台](https://console.amap.com/)
2. 注册/登录账号
3. 进入「应用管理」→「我的应用」→「创建应用」
4. 点击「添加 Key」，填写以下信息：
   - 应用名称：通勤提醒
   - 平台：Web服务
   - 提交后获得 **API Key**

### 2. 配置邮箱 SMTP 服务

#### 如果使用 QQ 邮箱：
1. 登录 QQ 邮箱
2. 设置 → 账户
3. 找到「POP3/IMAP/SMTP/Exchange/CardDAV/CalDAV服务」
4. 开启「POP3/SMTP 服务」
5. 点击「生成授权码」（需要手机验证）
6. **保存好授权码**，这就是你需要在脚本中使用的密码

#### 如果使用 163 邮箱：
1. 登录 163 邮箱
2. 设置 → POP3/SMTP/IMAP
3. 开启「SMTP 服务」
4. 设置客户端授权密码
5. 保存好授权码

#### 如果使用 Gmail：
1. 登录 Google 账户
2. 开启两步验证
3. 生成应用专用密码
4. 参考 [Google SMTP 设置](https://support.google.com/mail/answer/7126229)

---

## 安装步骤

### Windows 系统

#### 方式一：使用部署脚本（推荐）

```powershell
# 1. 克隆或下载项目
# 将项目文件夹放到合适的位置，如 C:\commute_script

# 2. 以管理员身份打开 PowerShell
# 进入项目目录
cd C:\commute_script

# 3. 运行部署脚本
.\install.ps1
```

#### 方式二：手动安装

```powershell
# 1. 安装 Python（如果未安装）
# 下载地址：https://www.python.org/downloads/
# 安装时勾选 "Add Python to PATH"

# 2. 打开命令提示符或 PowerShell
# 进入项目目录
cd C:\commute_script

# 3. 安装依赖
pip install -r requirements.txt
```

### Linux/macOS 系统

```bash
# 1. 克隆或下载项目
# 进入项目目录
cd /path/to/commute_script

# 2. 创建虚拟环境（推荐）
python -m venv venv
source venv/bin/activate  # Linux/macOS
# 或
venv\Scripts\activate  # Windows

# 3. 安装依赖
pip install -r requirements.txt

# 4. 安装 Chrome/Edge（用于截图）
# Ubuntu/Debian:
sudo apt-get install chromium-browser

# macOS:
# brew install chromium
```

---

## 配置说明

打开 `router.py` 文件，修改配置部分：

```python
# ==================== 配置 ====================

# 高德地图 API Key
AMAP_API_KEY = '你的API Key'

# 起点坐标 (经度, 纬度)
# 获取坐标方法：在高德地图点击位置 -> 右键 -> 复制坐标
ORIGIN = (118.906676, 32.071277)      # 起点：你的起点名称

# 终点坐标
DESTINATION = (118.701930, 31.949473) # 终点：你的终点名称

# 邮件配置
SMTP_SERVER = 'smtp.qq.com'  # 或 smtp.163.com, smtp.gmail.com
SMTP_PORT = 465
SENDER = 'your_email@qq.com'
PASSWORD = '你的授权码'
RECEIVER = 'receiver@example.com'
```

### 获取坐标的方法

1. 打开 [高德地图](https://www.amap.com/)
2. 搜索你的起点/终点位置
3. 点击目标位置
4. 在详情页面中找到坐标（经度, 纬度格式）

---

## 运行测试

### 测试脚本是否正常工作

```powershell
# Windows
python router.py

# Linux/macOS
python3 router.py
```

正常情况下，输出应该类似：

```
==================================================
开始查询通勤信息...
==================================================

[0/4] 清理旧文件...

[1/4] 查询通勤路线...
     驾车时间：30分钟
     路程距离：25公里

[2/4] 生成路线地图...
新地图已保存到: commute_route.html

[3/4] 自动截图...
截图已保存到: commute_route.png

[4/4] 发送邮件...
邮件发送成功！

==================================================
任务完成！
==================================================
```

---

## 定时任务设置

### Windows 任务计划程序

1. 打开「任务计划程序」
2. 创建基本任务
3. 设置：
   - 名称：通勤提醒
   - 触发器：每天，例如下午 5:30
   - 操作：启动程序
   - 程序脚本：`python C:\commute_script\router.py`
4. 完成

### Linux/macOS crontab

```bash
# 编辑 crontab
crontab -e

# 添加定时任务（每天下午5:30执行）
30 17 * * * /usr/bin/python3 /path/to/commute_script/router.py >> /path/to/commute_script/log.txt 2>&1
```

### Windows 定时任务（PowerShell）

```powershell
# 创建每日下午5:30的任务
$action = New-ScheduledTaskAction -Execute "python" -Argument "C:\commute_script\router.py" -WorkingDirectory "C:\commute_script"
$trigger = New-ScheduledTaskTrigger -Daily -At "17:30"
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "通勤提醒" -Description "每日通勤路线提醒"
```

---

## 常见问题

### Q1: 截图是空白的

**原因**：Selenium 无法加载在线地图瓦片
**解决**：
1. 确保网络连接正常
2. 等待时间可能不够，增加 `time.sleep(5)` 中的秒数
3. 检查 Edge 浏览器是否正常安装

### Q2: 邮件发送失败

**原因**：
1. SMTP 服务器/端口配置错误
2. 邮箱密码/授权码错误
3. 邮箱未开启 SMTP 服务

**解决**：
1. 确认 SMTP 配置正确
2. 确认使用的是授权码而非登录密码
3. 检查邮箱是否开启了 SMTP 服务

### Q3: 高德 API 调用失败

**原因**：
1. API Key 错误或已失效
2. API 调用次数超限
3. 网络问题

**解决**：
1. 检查 API Key 是否正确
2. 到高德开放平台查看调用次数
3. 检查网络连接

### Q4: 依赖安装失败

**解决**：
```powershell
# 升级 pip
python -m pip install --upgrade pip

# 单独安装失败的包
pip install folium
pip install requests
pip install selenium
pip install webdriver-manager
```

### Q5: Edge WebDriver 自动下载失败

**解决**：
1. 手动下载 Edge WebDriver：https://msedgedriver.azureedge.net/
2. 选择与你的 Edge 浏览器版本匹配的版本
3. 将 msedgedriver.exe 放到 Python Scripts 目录或项目目录

---

## 技术支持

如果遇到其他问题，请检查：
1. Python 版本是否 >= 3.8
2. 所有依赖是否正确安装
3. 网络是否正常
4. API Key 和邮箱配置是否正确

---

## 目录结构

```
commute_script/
├── router.py           # 主程序
├── requirements.txt    # Python 依赖
├── install.ps1        # Windows 安装脚本
├── install.sh         # Linux/macOS 安装脚本
├── DEPLOY.md          # 部署文档（本文件）
└── README.md          # 项目说明
```
