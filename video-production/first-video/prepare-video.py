import os
import sys

# 设置输出编码为 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

print("=== 创建视频制作自动化脚本 ===")
print()

# 创建音频目录
audio_dir = r"C:\OpenClaw_Workspace\workspace\video-production\first-video\audio"
os.makedirs(audio_dir, exist_ok=True)
print(f"✓ 创建音频目录: {audio_dir}")

# 创建输出目录
output_dir = r"C:\OpenClaw_Workspace\workspace\video-production\first-video\output"
os.makedirs(output_dir, exist_ok=True)
print(f"✓ 创建输出目录: {output_dir}")

print()
print("=== 视频制作流程 ===")
print()

print("步骤1: 生成配音")
print("  - 访问 ElevenLabs: https://elevenlabs.io/")
print("  - 使用 elevenlabs-script.md 中的文本")
print("  - 选择 Voice: Adam")
print("  - 逐段生成并下载到 audio/ 目录")
print()

print("步骤2: 使用 FFmpeg 创建基础视频")
print("  - 将关键帧转换为视频片段")
print("  - 添加转场效果")
print("  - 合成配音")
print()

print("步骤3: 添加文字和标注")
print("  - 使用 FFmpeg drawtext")
print("  - 添加数据面板")
print("  - 添加交易标注")
print()

print("步骤4: 导出最终视频")
print("  - 1080p分辨率")
print("  - H.264编码")
print("  - 高质量设置")
print()

print("=== 创建 FFmpeg 脚本 ===")
print()

# 创建 FFmpeg 脚本
ffmpeg_script = r"""# FFmpeg 视频制作脚本

## 步骤1: 将关键帧转换为视频片段

# 开场（3秒）
ffmpeg -loop 1 -i frames/frame_0001.jpg -t 3 -vf "scale=1920:1080" -c:v libx264 -pix_fmt yuv420p output/segment_01_opening.mp4

# 今日概览（5秒）
ffmpeg -loop 1 -i frames/frame_0006.jpg -t 5 -vf "scale=1920:1080" -c:v libx264 -pix_fmt yuv420p output/segment_02_overview.mp4

# 策略简介（5秒）
ffmpeg -loop 1 -i frames/frame_0012.jpg -t 5 -vf "scale=1920:1080" -c:v libx264 -pix_fmt yuv420p output/segment_03_strategy.mp4

# 交易1（5秒）
ffmpeg -loop 1 -i frames/frame_0030.jpg -t 5 -vf "scale=1920:1080" -c:v libx264 -pix_fmt yuv420p output/segment_04_trade1.mp4

# 交易2-4（10秒）
ffmpeg -loop 1 -i frames/frame_0060.jpg -t 3 -vf "scale=1920:1080" -c:v libx264 -pix_fmt yuv420p output/segment_05a.mp4
ffmpeg -loop 1 -i frames/frame_0090.jpg -t 3 -vf "scale=1920:1080" -c:v libx264 -pix_fmt yuv420p output/segment_05b.mp4
ffmpeg -loop 1 -i frames/frame_0120.jpg -t 4 -vf "scale=1920:1080" -c:v libx264 -pix_fmt yuv420p output/segment_05c.mp4

# EA设置（5秒）
ffmpeg -loop 1 -i frames/frame_0150.jpg -t 5 -vf "scale=1920:1080" -c:v libx264 -pix_fmt yuv420p output/segment_06_settings.mp4

# 结尾（3秒）
ffmpeg -loop 1 -i frames/frame_0180.jpg -t 3 -vf "scale=1920:1080" -c:v libx264 -pix_fmt yuv420p output/segment_07_cta.mp4

## 步骤2: 合并所有片段

# 创建文件列表
echo "file 'segment_01_opening.mp4'" > output/filelist.txt
echo "file 'segment_02_overview.mp4'" >> output/filelist.txt
echo "file 'segment_03_strategy.mp4'" >> output/filelist.txt
echo "file 'segment_04_trade1.mp4'" >> output/filelist.txt
echo "file 'segment_05a.mp4'" >> output/filelist.txt
echo "file 'segment_05b.mp4'" >> output/filelist.txt
echo "file 'segment_05c.mp4'" >> output/filelist.txt
echo "file 'segment_06_settings.mp4'" >> output/filelist.txt
echo "file 'segment_07_cta.mp4'" >> output/filelist.txt

# 合并视频
ffmpeg -f concat -safe 0 -i output/filelist.txt -c copy output/video_base.mp4

## 步骤3: 添加配音（如果有音频文件）

# 合并所有音频片段
# ffmpeg -i audio/segment_01_opening.mp3 -i audio/segment_02_overview.mp3 ... -filter_complex "[0:a][1:a]...[a]" -map "[a]" output/audio_full.mp3

# 将音频添加到视频
# ffmpeg -i output/video_base.mp4 -i output/audio_full.mp3 -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 output/video_with_audio.mp4

## 步骤4: 添加文字标注

# 添加标题
ffmpeg -i output/video_base.mp4 -vf "drawtext=text='Semi-Automated Box Strategy':x=(w-text_w)/2:y=100:fontsize=48:fontcolor=white:box=1:boxcolor=black@0.7:boxborderw=10" output/video_with_text.mp4

## 步骤5: 导出最终视频

# 高质量导出
ffmpeg -i output/video_with_text.mp4 -c:v libx264 -preset slow -crf 18 -c:a aac -b:a 192k output/final_video.mp4
"""

script_path = r"C:\OpenClaw_Workspace\workspace\video-production\first-video\ffmpeg-commands.txt"
with open(script_path, 'w', encoding='utf-8') as f:
    f.write(ffmpeg_script)

print(f"✓ FFmpeg 脚本已创建: {script_path}")
print()

print("=== 准备工作完成 ===")
print()
print("下一步:")
print("1. 生成配音（使用 ElevenLabs）")
print("2. 运行 FFmpeg 命令创建基础视频")
print("3. 使用 DaVinci Resolve 添加高级特效（可选）")
print()
