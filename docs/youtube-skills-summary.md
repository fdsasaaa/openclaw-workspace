# YouTube Skills 总结

## 已安装的 Skills

### 1. **summarize** 🧾
- **功能：** 总结 URLs、本地文件、YouTube 视频
- **用途：** 
  - 直接分析 YouTube 视频内容
  - 提取关键信息
  - 生成摘要
- **命令示例：**
  ```bash
  summarize "https://youtu.be/VIDEO_ID" --youtube auto
  ```
- **优点：** 支持多种模型（Gemini、OpenAI、Anthropic）

### 2. **youtube-watcher** 📺
- **功能：** 获取 YouTube 视频字幕/转录
- **用途：**
  - 提取视频文字内容
  - 分析视频主题
  - 回答关于视频的问题
- **命令示例：**
  ```bash
  python3 scripts/get_transcript.py "https://www.youtube.com/watch?v=VIDEO_ID"
  ```
- **要求：** 需要安装 yt-dlp

### 3. **video-subtitles** 📝
- **功能：** 生成视频字幕（SRT格式）
- **用途：**
  - 为我们的视频生成字幕
  - 支持翻译（希伯来语 ↔ 英语）
  - 可以将字幕烧录到视频中
- **命令示例：**
  ```bash
  ./scripts/generate_srt.py video.mp4 --srt --burn
  ```
- **优点：** 支持 Whisper large-v3，质量高

### 4. **video-frames** 🎞️
- **功能：** 从视频中提取帧
- **用途：**
  - 提取关键帧进行分析
  - 生成缩略图
- **命令示例：**
  ```bash
  scripts/frame.sh /path/to/video.mp4 --time 00:00:10 --out frame.jpg
  ```

---

## 对我们项目的价值

### 竞品分析阶段
1. **使用 summarize** 快速分析竞品视频内容
2. **使用 youtube-watcher** 获取视频转录文本
3. **使用 video-frames** 提取关键画面进行视觉分析

### 视频制作阶段
1. **使用 video-subtitles** 为我们的视频生成英文字幕
2. **使用 video-frames** 提取 MT5 回测结果的关键帧

### 未来扩展
- 监控竞品频道更新
- 自动分析新发布的交易策略视频
- 学习成功视频的内容结构

---

## 下一步行动

1. **安装 yt-dlp**（youtube-watcher 依赖）
2. **测试 summarize** 分析一个竞品视频
3. **测试 video-subtitles** 为测试视频生成字幕

---

*创建时间：2026-03-07 19:12*
*创建者：虾哥 🦐*
