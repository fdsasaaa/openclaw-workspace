# configure-admin-mode.ps1
# 配置 OpenClaw 以管理员权限运行

$ErrorActionPreference = "Stop"

Write-Host "=== 配置 OpenClaw 管理员模式 ===" -ForegroundColor Cyan

# 检查当前是否有管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "错误: 需要管理员权限运行此脚本" -ForegroundColor Red
    Write-Host "请右键点击 PowerShell，选择 '以管理员身份运行'" -ForegroundColor Yellow
    exit 1
}

# 找到 OpenClaw Gateway 任务
$taskName = "OpenClaw Gateway"
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if (-not $task) {
    Write-Host "错误: 找不到任务 '$taskName'" -ForegroundColor Red
    exit 1
}

Write-Host "找到任务: $taskName" -ForegroundColor Green

# 修改任务，使用 SYSTEM 账户运行（最高权限）
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Set-ScheduledTask -TaskName $taskName -Principal $principal | Out-Null

Write-Host ""
Write-Host "=== 配置完成 ===" -ForegroundColor Cyan
Write-Host "OpenClaw 现在将以 SYSTEM 账户运行（最高权限）" -ForegroundColor Green
Write-Host "重启网关后生效" -ForegroundColor Yellow
Write-Host ""
Write-Host "运行以下命令重启网关：" -ForegroundColor White
Write-Host "  openclaw gateway restart" -ForegroundColor Cyan
