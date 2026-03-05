# -*- coding: utf-8 -*-
"""
通勤提醒脚本
查询通勤路线，生成路线地图，自动截图，发送邮件
"""
import os
import requests
import json
import folium
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from datetime import datetime

# ==================== 配置 ====================
# 高德地图 API Key（申请地址：https://console.amap.com/）
# 1. 登录高德开放平台
# 2. 创建应用 -> 添加 Key（选择 Web服务）
# 3. 将获得的 API Key 填入下方
AMAP_API_KEY = '你的高德地图API_KEY'

# 起点坐标 (经度, 纬度) 和名称
ORIGIN = (经度, 纬度)      # 起点：你的起点地址名称
DESTINATION = (经度, 纬度) # 终点：你的终点地址名称

# 邮件配置
# SMTP 服务器地址（常见：smtp.163.com, smtp.qq.com, smtp.gmail.com）
SMTP_SERVER = 'smtp.你的邮箱服务商.com'
SMTP_PORT = 465  # 通常使用 465（SSL）或 587（TLS）
# 发件人邮箱和密码/授权码
SENDER = 'your_email@example.com'
# 注意：QQ邮箱需要使用授权码而非登录密码
# 授权码获取：QQ邮箱 -> 设置 -> 账户 -> POP3/IMAP/SMTP/Exchange/CardDAV/CalDAV服务 -> 开启 -> 获取授权码
PASSWORD = '你的邮箱密码或授权码'
# 收件人邮箱
RECEIVER = 'receiver@example.com'

# 文件路径
MAP_HTML_PATH = 'commute_route.html'
MAP_PNG_PATH = 'commute_route.png'

# ==================== 清理旧文件 ====================
def clean_old_files():
    """清理旧的地图文件"""
    if os.path.exists(MAP_HTML_PATH):
        os.remove(MAP_HTML_PATH)
        print(f"已删除旧文件: {MAP_HTML_PATH}")
    if os.path.exists(MAP_PNG_PATH):
        os.remove(MAP_PNG_PATH)
        print(f"已删除旧文件: {MAP_PNG_PATH}")

# ==================== 1. 查询通勤路线 ====================
def get_commute_info():
    url = f'https://restapi.amap.com/v3/direction/driving?key={AMAP_API_KEY}&origin={ORIGIN[0]},{ORIGIN[1]}&destination={DESTINATION[0]},{DESTINATION[1]}'
    data = json.loads(requests.get(url).text)

    paths = data['route']['paths'][0]
    duration = int(paths['duration']) // 60
    distance = int(paths['distance']) / 1000

    return duration, distance, paths['steps']

# ==================== 2. 生成路线地图 ====================
def generate_route_map(steps):
    segments = []
    for step in steps:
        polyline = step['polyline']
        points = [(float(p.split(',')[1]), float(p.split(',')[0])) for p in polyline.split(';')]

        traffic_status = '未知'
        if step.get('tmcs'):
            traffic_status = step['tmcs'][0].get('status', '未知')

        segments.append({'points': points, 'status': traffic_status})

    color_map = {'畅通': 'green', '缓行': 'orange', '拥堵': 'red', '未知': 'blue'}

    all_points = []
    for seg in segments:
        all_points.extend(seg['points'])

    center_lat = sum(p[0] for p in all_points) / len(all_points)
    center_lon = sum(p[1] for p in all_points) / len(all_points)

    m = folium.Map(location=[center_lat, center_lon], zoom_start=12)

    folium.TileLayer(
        tiles='https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
        attr='高德地图',
        subdomains='1234'
    ).add_to(m)

    for seg in segments:
        color = color_map.get(seg['status'], 'blue')
        folium.PolyLine(locations=seg['points'], color=color, weight=8, opacity=0.9).add_to(m)

    folium.Marker(
        location=[ORIGIN[1], ORIGIN[0]],
        popup='起点：你的起点名称',
        icon=folium.Icon(color='green', icon='play')
    ).add_to(m)

    folium.Marker(
        location=[DESTINATION[1], DESTINATION[0]],
        popup='终点：你的终点名称',
        icon=folium.Icon(color='red', icon='stop')
    ).add_to(m)

    legend_html = '''
    <div style="position: fixed; bottom: 50px; left: 50px; border:2px solid grey; z-index:9999;
         background-color:white; padding: 10px; font-size:14px; border-radius: 5px;">
        <b>路况图例</b><br>
        <i style="background:green; width:20px; height:10px; display:inline-block;"></i> 顺畅<br>
        <i style="background:orange; width:20px; height:10px; display:inline-block;"></i> 缓慢<br>
        <i style="background:red; width:20px; height:10px; display:inline-block;"></i> 拥堵<br>
        <i style="background:blue; width:20px; height:10px; display:inline-block;"></i> 未知
    </div>
    '''
    m.get_root().html.add_child(folium.Element(legend_html))

    m.save(MAP_HTML_PATH)
    print(f"新地图已保存到: {MAP_HTML_PATH}")

# ==================== 3. 自动截图 ====================
def take_screenshot():
    from selenium import webdriver
    from selenium.webdriver.edge.options import Options
    from selenium.webdriver.edge.service import Service
    from webdriver_manager.microsoft import EdgeChromiumDriverManager
    import os

    edge_options = Options()
    edge_options.add_argument('--headless')
    edge_options.add_argument('--disable-gpu')
    edge_options.add_argument('--window-size=1200,800')
    edge_options.add_argument('--no-sandbox')
    edge_options.add_argument('--disable-dev-shm-usage')
    edge_options.add_argument('--disable-blink-features=AutomationControlled')

    driver = None
    try:
        service = Service(EdgeChromiumDriverManager().install())
        driver = webdriver.Edge(service=service, options=edge_options)
        driver.get(f'file:///{os.path.abspath(MAP_HTML_PATH)}')

        import time
        time.sleep(5)

        driver.save_screenshot(MAP_PNG_PATH)
        print(f"截图已保存到: {MAP_PNG_PATH}")
    except Exception as e:
        raise Exception(f"截图失败: {str(e)}")
    finally:
        if driver:
            driver.quit()

# ==================== 4. 发送邮件 ====================
def send_email(duration, distance):
    today = datetime.now()
    date_str = today.strftime('%Y年%m月%d日')
    weekday = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][today.weekday()]

    msg = MIMEMultipart()
    msg['From'] = SENDER
    msg['To'] = RECEIVER
    msg['Subject'] = f'{date_str} 通勤 {duration}分钟'

    body = f'''您好！

今日通勤信息（{date_str} 周{weekday}）：

🚗 起点：你的起点地址
🏁 终点：你的终点地址

⏱ 预计驾车时间：{duration}分钟
📏 路程距离：{distance}公里

请合理安排出行时间！

---
此邮件由通勤助手自动发送'''

    msg.attach(MIMEText(body, 'plain', 'utf-8'))

    with open(MAP_PNG_PATH, 'rb') as f:
        img = MIMEImage(f.read())
        img.add_header('Content-Disposition', 'attachment', filename='route_map.png')
        msg.attach(img)

    server = smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT)
    server.login(SENDER, PASSWORD)
    server.sendmail(SENDER, RECEIVER, msg.as_string())
    server.quit()

    print('邮件发送成功！')

# ==================== 主函数 ====================
def main():
    print('=' * 50)
    print('开始查询通勤信息...')
    print('=' * 50)

    # 0. 清理旧文件
    print('\n[0/4] 清理旧文件...')
    clean_old_files()

    # 1. 查询通勤路线
    print('\n[1/4] 查询通勤路线...')
    duration, distance, steps = get_commute_info()
    print(f'     驾车时间：{duration}分钟')
    print(f'     路程距离：{distance}公里')

    # 2. 生成路线地图
    print('\n[2/4] 生成路线地图...')
    generate_route_map(steps)

    # 3. 自动截图
    print('\n[3/4] 自动截图...')
    take_screenshot()

    # 4. 发送邮件
    print('\n[4/4] 发送邮件...')
    send_email(duration, distance)

    print('\n' + '=' * 50)
    print('任务完成！')
    print('=' * 50)

if __name__ == '__main__':
    main()
