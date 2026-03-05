# 创建OpenClaw管理员权限系统服务脚本
# 此脚本将OpenClaw Gateway配置为以SYSTEM权限运行

# 需要以管理员身份运行此脚本

# 1. 停止现有Gateway
openclaw gateway stop 2>$null

# 2. 删除现有计划任务
schtasks /Delete /TN "OpenClaw Gateway" /F 2>$null

# 3. 创建新的计划任务（SYSTEM权限，开机启动）
$Action = New-ScheduledTaskAction -Execute "node" -Argument "$env:APPDATA\npm\node_modules\openclaw\dist\index.js gateway"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

Register-ScheduledTask -TaskName "OpenClaw Gateway Service" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force

# 4. 立即启动
Start-ScheduledTask -TaskName "OpenClaw Gateway Service"

Write-Host "OpenClaw Gateway 已配置为系统服务" -ForegroundColor Green
Write-Host "运行身份: SYSTEM (最高权限)" -ForegroundColor Yellow
Write-Host "启动方式: 开机自动" -ForegroundColor Green
