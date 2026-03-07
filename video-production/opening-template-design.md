# 视频开场模板设计

## 视频信息

**目标频道：** 量化交易频道（英文）
**目标受众：** 初学者或经验有限的交易者
**视频类型：** 实盘结果展示 + 策略讲解
**视频时长：** 10-15分钟
**视频质量：** 1080p

---

## 开场设计（0:00-0:30，30秒）

### 视觉元素

**背景：**
- 深蓝色渐变背景 (#0a0e27 → #1a1e3a)
- 或使用交易图表模糊背景

**Logo/标题：**
```
┌─────────────────────────────────────┐
│                                     │
│         [LOGO/图标]                 │
│                                     │
│    Semi-Automated Box Strategy     │
│         Daily Results              │
│                                     │
│         Day 1 - March 7, 2026      │
│                                     │
└─────────────────────────────────────┘
```

**字体：**
- 标题：Montserrat Bold, 48px, 白色
- 副标题：Montserrat Regular, 24px, 浅蓝色 (#3498DB)
- 日期：Montserrat Light, 18px, 灰色

**动画效果：**
- Logo淡入（0.5秒）
- 标题从下方滑入（0.5秒）
- 日期淡入（0.5秒）

---

### 配音脚本（英文）

**版本1：友好轻松（推荐）**
```
"Hey traders! Welcome back to my channel. 
Today I'm showing you the results of my semi-automated box strategy on MT5. 
This is Day 1, and I'm excited to share what happened."
```

**版本2：专业严肃**
```
"Good day, traders. This is the daily results report for my semi-automated box strategy. 
Today is March 7th, 2026, and we'll be reviewing the performance metrics."
```

**版本3：激情澎湃**
```
"What's up, traders! You're not going to believe what happened today! 
My semi-automated box strategy just crushed it, and I'm going to show you everything!"
```

**推荐：版本1（友好轻松）**

---

### 背景音乐

**风格：** 轻快、专业、不抢戏

**推荐音乐：**
1. "Corporate Success" - 轻快的企业风格
2. "Tech Innovation" - 科技感
3. "Upbeat Corporate" - 积极向上

**音量：** -20dB（背景音乐，不影响配音）

**来源：**
- YouTube Audio Library（免费）
- Epidemic Sound（付费，高质量）
- Artlist（付费，高质量）

---

## 结果展示设计（0:30-10:00，9.5分钟）

### 布局方案

**方案A：全屏MT5（推荐）**
```
┌─────────────────────────────────────┐
│                                     │
│         MT5 屏幕录制                │
│         (全屏显示)                  │
│                                     │
│  [左上角：日期和时间]               │
│  [右上角：当前盈亏]                 │
│                                     │
└─────────────────────────────────────┘
```

**方案B：分屏布局**
```
┌──────────────────┬──────────────────┐
│                  │                  │
│   MT5 图表       │   数据面板       │
│   (70%)          │   (30%)          │
│                  │   - 总盈亏       │
│                  │   - 胜率         │
│                  │   - 交易次数     │
│                  │   - 最大回撤     │
│                  │                  │
└──────────────────┴──────────────────┘
```

**推荐：方案A（全屏MT5）**
- 更清晰
- 更专业
- 更容易制作

---

### 标注样式

**文字标注：**
- 字体：Montserrat Bold
- 大小：36px
- 颜色：白色，带黑色描边（2px）
- 背景：半透明黑色矩形（opacity: 0.7）

**箭头标注：**
- 颜色：绿色（买入）/ 红色（卖出）
- 粗细：4px
- 样式：实线箭头

**示例标注：**
```
┌─────────────────────────┐
│  Entry: 1.3900          │
│  Exit: 1.3950           │
│  Profit: +50 pips       │
└─────────────────────────┘
```

---

## 结尾设计（10:00-10:30，30秒）

### 视觉元素

**背景：**
- 与开场相同的深蓝色渐变

**CTA（Call to Action）：**
```
┌─────────────────────────────────────┐
│                                     │
│    Want to use this strategy?       │
│                                     │
│    ✓ TradingView Signals            │
│    ✓ Semi-Auto EA                   │
│    ✓ Full Support                   │
│                                     │
│    Link in Description ↓            │
│                                     │
│    [Subscribe] [Like] [Comment]     │
│                                     │
└─────────────────────────────────────┘
```

**按钮样式：**
- 背景：蓝色 (#3498DB)
- 文字：白色
- 圆角：8px
- 阴影：0 4px 8px rgba(0,0,0,0.3)

---

### 配音脚本（英文）

**版本1：友好轻松（推荐）**
```
"So that's it for today! If you're interested in using this strategy, 
check out the link in the description below. 
You can get access to my TradingView signals or the semi-automated EA. 
Don't forget to subscribe, like, and leave a comment. 
See you tomorrow with Day 2 results!"
```

**版本2：专业严肃**
```
"This concludes today's performance report. 
For access to the strategy signals or the expert advisor, 
please refer to the link provided in the video description. 
Thank you for watching."
```

**推荐：版本1（友好轻松）**

---

## 技术实现

### 工具清单

**视频编辑：**
- FFmpeg（已安装）
- DaVinci Resolve（可选，更强大）

**配音生成：**
- ElevenLabs（推荐，高质量）
- Edge TTS（免费，质量较低）

**图形设计：**
- Canva（在线，简单）
- Photoshop（专业）

**字幕生成：**
- video-subtitles skill（已安装）

---

### FFmpeg 命令示例

**1. 添加开场画面（3秒）**
```bash
ffmpeg -loop 1 -i opening.jpg -t 3 -vf "scale=1920:1080" opening.mp4
```

**2. 添加文字标注**
```bash
ffmpeg -i input.mp4 -vf "drawtext=text='Entry: 1.3900':x=50:y=50:fontsize=36:fontcolor=white:box=1:boxcolor=black@0.7" output.mp4
```

**3. 合成配音**
```bash
ffmpeg -i video.mp4 -i voiceover.mp3 -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 output.mp4
```

**4. 添加背景音乐**
```bash
ffmpeg -i video.mp4 -i music.mp3 -filter_complex "[1:a]volume=0.1[a1];[0:a][a1]amix=inputs=2[a]" -map 0:v -map "[a]" output.mp4
```

---

## 配色方案

### 主色调（蓝色系，推荐）

**主色：** #3498DB（明亮蓝）
**辅助色：** #1ABC9C（青绿色）
**背景色：** #0a0e27（深蓝黑）
**文字色：** #FFFFFF（白色）
**强调色：** #E67E22（橙色，用于重要数据）

**盈利/亏损：**
- 盈利：#2ECC71（绿色）
- 亏损：#E74C3C（红色）

---

## 下一步

**今晚完成：**
1. ✅ 开场模板设计（已完成）
2. ⏳ 创建开场图片
3. ⏳ 准备配音脚本
4. ⏳ 测试FFmpeg命令

**明天完成：**
1. 测试配音生成
2. 测试视频剪辑
3. 合成示例视频

---

*设计时间: 2026-03-07 20:50*
*设计者: 虾哥 🦐*
*状态: 开场模板设计完成*
