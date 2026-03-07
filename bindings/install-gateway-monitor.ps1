# install-gateway-monitor.ps1
# 安装 OpenClaw Gateway Monitor 为 Windows 计划任务

$ErrorActionPreference = "Stop"

Write-Host "=== 安装 OpenClaw Gateway Monitor ===" -ForegroundColor Cyan

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "错误: 需要管理员权限" -ForegroundColor Red
    Write-Host "请右键点击 PowerShell，选择 '以管理员身份运行'" -ForegroundColor Yellow
    exit 1
}

# 配置
$TaskName = "OpenClaw-Gateway-Monitor"
$ScriptPath = "C:\OpenClaw_Workspace\workspace\bindings\gateway-monitor.ps1"
$Description = "监控 OpenClaw 网关状态，自动重启崩溃的网关"

# 检查脚本是否存在
if (-not (Test-Path $ScriptPath)) {
    Write-Host "错误: 找不到监控脚本: $ScriptPath" -ForegroundColor Red
    exit 1
}

# 删除旧任务（如果存在）
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "删除旧任务..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# 创建任务动作
$Action = New-ScheduledTaskAction `
    -Execute "pwsh.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$ScriptPath`""

# 创建触发器（开机启动）
$Trigger = New-ScheduledTaskTrigger -AtStartup

# 创建任务设置
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Days 365)

# 创建任务主体（使用 SYSTEM 账户，后台运行）
$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

# 注册任务
Write-Host "注册计划任务..." -ForegroundColor Green
Register-ScheduledTask `
    -TaskName $TaskName `
    -Description $Description `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal `
    -Force | Out-Null

# 立即启动任务
Write-Host "启动监控任务..." -ForegroundColor Green
Start-ScheduledTask -TaskName $TaskName

# 等待几秒
Start-Sleep -Seconds 3

# 验证任务状态
$task = Get-ScheduledTask -TaskName $TaskName
Write-Host ""
Write-Host "=== 安装完成 ===" -ForegroundColor Cyan
Write-Host "任务名称: $TaskName" -ForegroundColor White
Write-Host "状态: $($task.State)" -ForegroundColor White
Write-Host "触发器: 开机自动启动" -ForegroundColor White
Write-Host "检查间隔: 30秒" -ForegroundColor White
Write-Host "日志位置: C:\OpenClaw_Workspace\workspace\bindings\logs\gateway-monitor.log" -ForegroundColor White
Write-Host ""
Write-Host "监控已启动！网关崩溃时会自动重启。" -ForegroundColor Green
