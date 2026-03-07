import re
import sys

# 设置输出编码为 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

# 读取OCR结果
with open('mt5-video-full-ocr-analysis.txt', 'r', encoding='utf-8') as f:
    content = f.read()

# 分析关键信息
print("=== MT5 视频操作流程分析 ===")
print()

# 1. 识别的交易品种
print("1. 识别到的交易品种：")
symbols = set(re.findall(r'\b(EURUSD|GBPUSD|USDCHF|USDJPY|USDCAD|AUDUSD|EURGBP|EURAUD|EURCHF|EURJPY|GBPCHF|CADJPY|XAUUSD|US500|USTEC|IT40)\b', content))
for symbol in sorted(symbols):
    print(f"  - {symbol}")
print()

# 2. 识别的账户信息
print("2. 识别到的账户信息：")
accounts = set(re.findall(r'ICMarkets[^\s]+', content))
for account in sorted(accounts)[:5]:
    print(f"  - {account}")
print()

# 3. 识别的时间周期
print("3. 识别到的时间周期：")
timeframes = set(re.findall(r'\.(H[1-4]|M[1-9][0-9]?|D1|W1|MN)\b', content))
for tf in sorted(timeframes):
    print(f"  - {tf}")
print()

# 4. 按时间段分析内容变化
print("4. 视频阶段分析：")
print()

# 提取所有帧的信息
frames = re.findall(r'帧: (frame_\d+\.jpg) \| 时间: (\d+:\d+)', content)

# 分析不同阶段
stages = {
    "启动阶段 (0:00-1:00)": [],
    "配置阶段 (1:00-5:00)": [],
    "执行阶段 (5:00-20:00)": [],
    "结果阶段 (20:00-32:00)": []
}

for frame, timestamp in frames:
    minutes = int(timestamp.split(':')[0])
    
    if minutes < 1:
        stages["启动阶段 (0:00-1:00)"].append((frame, timestamp))
    elif minutes < 5:
        stages["配置阶段 (1:00-5:00)"].append((frame, timestamp))
    elif minutes < 20:
        stages["执行阶段 (5:00-20:00)"].append((frame, timestamp))
    else:
        stages["结果阶段 (20:00-32:00)"].append((frame, timestamp))

for stage, frames_list in stages.items():
    print(f"{stage}: {len(frames_list)} 帧")

print()

# 5. 搜索关键词
print("5. 关键操作词识别：")
keywords = {
    "策略测试器": ["Strategy", "Tester", "测试", "回测"],
    "EA/专家": ["Expert", "EA", "专家"],
    "参数设置": ["Parameter", "Setting", "参数", "设置"],
    "开始/停止": ["Start", "Stop", "Begin", "开始", "停止"],
    "结果/报告": ["Result", "Report", "结果", "报告"]
}

for category, words in keywords.items():
    found = []
    for word in words:
        if word in content:
            found.append(word)
    if found:
        print(f"  {category}: {', '.join(found)}")

print()
print("分析完成！")
