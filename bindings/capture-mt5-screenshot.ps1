# capture-mt5-screenshot.ps1
# 捕获 MT5 窗口截图（用于调试和验证）

param(
    [string]$OutputPath = "C:\OpenClaw_Workspace\workspace\screenshots\mt5_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
)

# UTF-8 编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

Write-Host "=== MT5 窗口截图 ===" -ForegroundColor Cyan
Write-Host ""

# 创建输出目录
$outputDir = Split-Path $OutputPath
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

# 查找 MT5 窗口
$mt5Process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue | 
    Where-Object { $_.MainWindowHandle -ne 0 } | 
    Select-Object -First 1

if (-not $mt5Process) {
    Write-Host "❌ MT5 未运行" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 找到 MT5 窗口 (PID: $($mt5Process.Id))" -ForegroundColor Green
Write-Host "标题: $($mt5Process.MainWindowTitle)" -ForegroundColor White
Write-Host ""

# 获取窗口位置和大小
Add-Type @"
using System;
using System.Runtime.InteropServices;

public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public class Win32API {
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, ref RECT rect);
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

$rect = New-Object RECT
[Win32API]::GetWindowRect($mt5Process.MainWindowHandle, [ref]$rect) | Out-Null

$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top

Write-Host "窗口位置: X=$($rect.Left), Y=$($rect.Top)" -ForegroundColor Gray
Write-Host "窗口大小: W=$width, H=$height" -ForegroundColor Gray
Write-Host ""

# 激活窗口
Write-Host "激活窗口..." -ForegroundColor Yellow
[Win32API]::SetForegroundWindow($mt5Process.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 500

# 截图
Write-Host "正在截图..." -ForegroundColor Yellow

$bitmap = New-Object System.Drawing.Bitmap($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

try {
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    $fileSize = (Get-Item $OutputPath).Length / 1KB
    
    Write-Host ""
    Write-Host "✅ 截图成功" -ForegroundColor Green
    Write-Host "保存位置: $OutputPath" -ForegroundColor White
    Write-Host "文件大小: $([math]::Round($fileSize, 2)) KB" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "❌ 截图失败: $_" -ForegroundColor Red
    exit 1
} finally {
    $graphics.Dispose()
    $bitmap.Dispose()
}
