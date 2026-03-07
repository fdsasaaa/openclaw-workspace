# video-editing-research.md
# 视频剪辑功能研究

## 目标
使用 FFmpeg 实现视频剪辑、裁剪、添加标注功能

## FFmpeg 基础命令

### 1. 剪辑视频（裁剪时间）
```bash
# 从第10秒开始，剪辑30秒
ffmpeg -i input.mp4 -ss 00:00:10 -t 00:00:30 -c copy output.mp4

# 从第10秒到第40秒
ffmpeg -i input.mp4 -ss 00:00:10 -to 00:00:40 -c copy output.mp4
```

### 2. 裁剪画面（crop）
```bash
# 裁剪为 1280x720，从左上角 (0,0) 开始
ffmpeg -i input.mp4 -vf "crop=1280:720:0:0" output.mp4

# 裁剪中心区域
ffmpeg -i input.mp4 -vf "crop=1280:720" output.mp4
```

### 3. 添加文字标注
```bash
# 添加简单文字
ffmpeg -i input.mp4 -vf "drawtext=text='Hello':fontsize=24:fontcolor=white:x=10:y=10" output.mp4

# 添加时间戳
ffmpeg -i input.mp4 -vf "drawtext=text='%{pts\:hms}':fontsize=24:fontcolor=white:x=10:y=10" output.mp4
```

### 4. 添加水印/Logo
```bash
# 在右上角添加水印
ffmpeg -i input.mp4 -i logo.png -filter_complex "overlay=W-w-10:10" output.mp4
```

### 5. 调整视频速度
```bash
# 2倍速
ffmpeg -i input.mp4 -filter:v "setpts=0.5*PTS" output.mp4

# 0.5倍速（慢动作）
ffmpeg -i input.mp4 -filter:v "setpts=2.0*PTS" output.mp4
```

### 6. 合并多个视频
```bash
# 创建文件列表
echo "file 'video1.mp4'" > list.txt
echo "file 'video2.mp4'" >> list.txt

# 合并
ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4
```

### 7. 提取关键帧
```bash
# 每秒提取一帧
ffmpeg -i input.mp4 -vf fps=1 frame_%04d.png

# 提取特定时间点的帧
ffmpeg -i input.mp4 -ss 00:00:10 -vframes 1 frame.png
```

## 我们的需求

### MT5 交易视频剪辑需求
1. **剪辑时间段**
   - 去掉开头和结尾的无用部分
   - 保留核心交易展示部分

2. **添加标注**
   - 交易结果文字（盈利/亏损）
   - 时间戳
   - 策略名称

3. **画面优化**
   - 裁剪掉不必要的边缘
   - 突出显示交易区域

4. **合并片段**
   - 如果有多个交易，合并成一个视频

## 实现计划

### 阶段1：基础剪辑
- 实现时间段裁剪
- 实现画面裁剪
- 测试基本功能

### 阶段2：添加标注
- 添加文字标注
- 添加时间戳
- 添加水印/Logo

### 阶段3：高级功能
- 合并多个片段
- 调整播放速度
- 添加转场效果

## 技术要点

### PowerShell 调用 FFmpeg
```powershell
$ffmpegPath = "ffmpeg"
$inputFile = "input.mp4"
$outputFile = "output.mp4"

$args = @(
    "-i", $inputFile,
    "-ss", "00:00:10",
    "-t", "00:00:30",
    "-c", "copy",
    $outputFile
)

& $ffmpegPath $args
```

### 错误处理
```powershell
try {
    & ffmpeg $args 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 成功"
    } else {
        Write-Host "❌ 失败"
    }
} catch {
    Write-Host "❌ 错误: $_"
}
```

## 参考资源
- FFmpeg 官方文档：https://ffmpeg.org/documentation.html
- FFmpeg Wiki：https://trac.ffmpeg.org/wiki

---

*创建时间：2026-03-07 18:40*
*创建者：虾哥 🦐*
