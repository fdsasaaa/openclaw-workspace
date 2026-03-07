#!/usr/bin/env pwsh
# 变更前自动备份脚本
# 在执行危险操作前自动调用

param(
    [Parameter(Mandatory=$true)]
    [string]$Reason,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipGit
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = "C:\OpenClaw_Workspace"
$BackupDir = "$WorkspaceRoot\backup\auto"

# 确保备份目录存在
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

# 生成备份名称
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupName = "pre-change-${timestamp}-$(($Reason -replace '\s+', '_').Substring(0,[Math]::Min(30,$Reason.Length)))"
$backupPath = "$BackupDir\$backupName"

Write-Host "[$(Get-Date)] 创建变更前备份..." -ForegroundColor Cyan
Write-Host "原因: $Reason" -ForegroundColor Gray
Write-Host "位置: $backupPath" -ForegroundColor Gray

# 创建备份
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

# 备份关键目录
$dirsToBackup = @('configs', 'memory', 'reports')
foreach ($dir in $dirsToBackup) {
    $source = "$WorkspaceRoot\$dir"
    if (Test-Path $source) {
        Copy-Item -Recurse $source "$backupPath\$dir" -Force
    }
}

# Git提交（如未跳过）
if (-not $SkipGit) {
    Push-Location $WorkspaceRoot
    git add . 2>$null
    git commit -m "Auto: $Reason [pre-change backup]" 2>$null | Out-Null
    Pop-Location
}

# 记录到日志
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $backupName | $Reason"
Add-Content "$BackupDir\backup-history.log" $logEntry

Write-Host "[$(Get-Date)] 备份完成: $backupName" -ForegroundColor Green

# 返回备份路径（供调用者使用）
return $backupPath
