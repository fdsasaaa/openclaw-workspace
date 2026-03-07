# test-screen-record.ps1
# 测试 Windows 屏幕录制

param(
    [int]$DurationSeconds = 5,
    [string]$OutputPath = "C:\OpenClaw_Workspace\workspace\test-recording.mp4"
)

Write-Host "=== 测试屏幕录制 ===" -ForegroundColor Cyan
Write-Host "时长: $DurationSeconds 秒" -ForegroundColor White
Write-Host "输出: $OutputPath" -ForegroundColor White
Write-Host ""

# 刷新环境变量
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 使用 FFmpeg 录制屏幕
Write-Host "开始录制..." -ForegroundColor Green

$ffmpegArgs = @(
    "-f", "gdigrab",
    "-framerate", "30",
    "-i", "desktop",
    "-t", $DurationSeconds,
    "-c:v", "libx264",
    "-preset", "ultrafast",
    "-pix_fmt", "yuv420p",
    "-y",
    $OutputPath
)

& ffmpeg $ffmpegArgs 2>&1 | Out-Null

if (Test-Path $OutputPath) {
    $fileSize = (Get-Item $OutputPath).Length / 1MB
    Write-Host ""
    Write-Host "✅ 录制成功！" -ForegroundColor Green
    Write-Host "文件: $OutputPath" -ForegroundColor White
    Write-Host "大小: $([math]::Round($fileSize, 2)) MB" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ 录制失败" -ForegroundColor Red
}
