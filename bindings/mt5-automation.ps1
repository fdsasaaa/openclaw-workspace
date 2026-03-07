# mt5-automation.ps1
# MT5 UI 自动化控制

param(
    [string]$Action = "test",
    [string]$MT5Path = "C:\Program Files\MetaTrader 5\terminal64.exe"
)

# UTF-8 编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

Write-Host "=== MT5 UI 自动化 ===" -ForegroundColor Cyan
Write-Host ""

function Get-MT5Window {
    $processes = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
    if ($processes) {
        foreach ($proc in $processes) {
            if ($proc.MainWindowHandle -ne 0) {
                return $proc
            }
        }
    }
    return $null
}

function Start-MT5 {
    if (Test-Path $MT5Path) {
        Write-Host "启动 MT5..." -ForegroundColor Yellow
        Start-Process $MT5Path
        Start-Sleep -Seconds 10
        
        $mt5 = Get-MT5Window
        if ($mt5) {
            Write-Host "✅ MT5 已启动 (PID: $($mt5.Id))" -ForegroundColor Green
            return $mt5
        } else {
            Write-Host "❌ MT5 启动失败" -ForegroundColor Red
            return $null
        }
    } else {
        Write-Host "❌ 找不到 MT5: $MT5Path" -ForegroundColor Red
        return $null
    }
}

function Focus-MT5Window {
    param($Process)
    
    Write-Host "激活 MT5 窗口..." -ForegroundColor Yellow
    
    # 使用 Windows API 激活窗口
    $signature = @'
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
    
    $type = Add-Type -MemberDefinition $signature -Name WinAPI -Namespace Win32 -PassThru
    
    # SW_RESTORE = 9
    $type::ShowWindow($Process.MainWindowHandle, 9) | Out-Null
    Start-Sleep -Milliseconds 500
    $type::SetForegroundWindow($Process.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 500
    
    Write-Host "✅ 窗口已激活" -ForegroundColor Green
}

function Send-KeyToMT5 {
    param(
        [string]$Key,
        [int]$DelayMs = 500
    )
    
    Write-Host "发送按键: $Key" -ForegroundColor Gray
    [System.Windows.Forms.SendKeys]::SendWait($Key)
    Start-Sleep -Milliseconds $DelayMs
}

function Navigate-ToStrategyTester {
    Write-Host "导航到策略测试器..." -ForegroundColor Yellow
    
    # Ctrl+R 打开策略测试器
    Send-KeyToMT5 "^r" 1000
    
    Write-Host "✅ 已打开策略测试器" -ForegroundColor Green
}

function Get-MT5WindowInfo {
    param($Process)
    
    Write-Host "MT5 窗口信息:" -ForegroundColor Cyan
    Write-Host "  PID: $($Process.Id)" -ForegroundColor White
    Write-Host "  标题: $($Process.MainWindowTitle)" -ForegroundColor White
    Write-Host "  句柄: $($Process.MainWindowHandle)" -ForegroundColor White
    
    $rect = New-Object RECT
    [Win32API]::GetWindowRect($Process.MainWindowHandle, [ref]$rect) | Out-Null
    Write-Host "  位置: X=$($rect.Left), Y=$($rect.Top)" -ForegroundColor White
    Write-Host "  大小: W=$($rect.Right - $rect.Left), H=$($rect.Bottom - $rect.Top)" -ForegroundColor White
}

# 定义 RECT 结构
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
}
"@

# 主逻辑
switch ($Action) {
    "test" {
        Write-Host "测试模式" -ForegroundColor Cyan
        Write-Host ""
        
        # 检查 MT5
        $mt5 = Get-MT5Window
        if (-not $mt5) {
            Write-Host "MT5 未运行，正在启动..." -ForegroundColor Yellow
            $mt5 = Start-MT5
            if (-not $mt5) {
                exit 1
            }
        } else {
            Write-Host "✅ MT5 已运行 (PID: $($mt5.Id))" -ForegroundColor Green
        }
        
        Write-Host ""
        Get-MT5WindowInfo $mt5
        
        Write-Host ""
        Write-Host "按任意键测试窗口激活..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        Focus-MT5Window $mt5
        
        Write-Host ""
        Write-Host "按任意键测试导航到策略测试器..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        Navigate-ToStrategyTester
        
        Write-Host ""
        Write-Host "✅ 测试完成" -ForegroundColor Green
    }
    
    "open-tester" {
        $mt5 = Get-MT5Window
        if (-not $mt5) {
            $mt5 = Start-MT5
            if (-not $mt5) { exit 1 }
        }
        
        Focus-MT5Window $mt5
        Navigate-ToStrategyTester
    }
    
    default {
        Write-Host "未知操作: $Action" -ForegroundColor Red
        Write-Host "可用操作: test, open-tester" -ForegroundColor Yellow
    }
}
