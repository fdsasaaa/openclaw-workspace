# mt5-auto-open-tester.ps1
# 自动打开 MT5 策略测试器（非交互式）

param(
    [string]$MT5Path = "C:\Program Files\MetaTrader 5 IC Markets Global\terminal64.exe"
)

# UTF-8 编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

Write-Host "=== 自动打开 MT5 策略测试器 ===" -ForegroundColor Cyan
Write-Host ""

# 检查 MT5 是否运行
$mt5 = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1

if (-not $mt5) {
    Write-Host "启动 MT5..." -ForegroundColor Yellow
    Start-Process $MT5Path
    Start-Sleep -Seconds 10
    
    $mt5 = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    
    if (-not $mt5) {
        Write-Host "❌ MT5 启动失败" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ MT5 已启动 (PID: $($mt5.Id))" -ForegroundColor Green
} else {
    Write-Host "✅ MT5 已运行 (PID: $($mt5.Id))" -ForegroundColor Green
}

Write-Host "标题: $($mt5.MainWindowTitle)" -ForegroundColor White
Write-Host ""

# 激活窗口
Write-Host "激活 MT5 窗口..." -ForegroundColor Yellow

$signature = @'
[DllImport("user32.dll")]
public static extern bool SetForegroundWindow(IntPtr hWnd);
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@

$type = Add-Type -MemberDefinition $signature -Name WinAPI -Namespace Win32 -PassThru

# SW_RESTORE = 9
$type::ShowWindow($mt5.MainWindowHandle, 9) | Out-Null
Start-Sleep -Milliseconds 500
$type::SetForegroundWindow($mt5.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 1000

Write-Host "✅ 窗口已激活" -ForegroundColor Green
Write-Host ""

# 打开策略测试器 (Ctrl+R)
Write-Host "打开策略测试器 (Ctrl+R)..." -ForegroundColor Yellow
[System.Windows.Forms.SendKeys]::SendWait("^r")
Start-Sleep -Milliseconds 1000

Write-Host "✅ 完成" -ForegroundColor Green
Write-Host ""
Write-Host "MT5 策略测试器应该已打开" -ForegroundColor Cyan
