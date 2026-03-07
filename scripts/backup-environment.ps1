#!/usr/bin/env pwsh
# EnergyBlock 环境打包备份脚本 - 简化版

param(
    [string]$BackupDir = "C:\EnergyBlock-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    [switch]$IncludeSecrets,
    [switch]$CreateArchive
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EnergyBlock Environment Backup Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 创建备份目录
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
Write-Host "`n备份目录: $BackupDir" -ForegroundColor Yellow

# 1. 推送GitHub
Write-Host "`n[1/5] 推送工作区到GitHub..." -ForegroundColor Yellow
Set-Location "C:\OpenClaw_Workspace"
git add . 2>$null
git commit -m "Backup: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 2>$null
git push origin master
Write-Host "  GitHub同步完成" -ForegroundColor Green

# 2. 导出配置文件（脱敏）
Write-Host "`n[2/5] 导出配置文件..." -ForegroundColor Yellow
$openclawConfig = Get-Content "$env:USERPROFILE\.openclaw\openclaw.json" | ConvertFrom-Json
if ($openclawConfig.auth) { $openclawConfig.auth.token = "PLACEHOLDER_TOKEN" }
$openclawConfig | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\openclaw.json.template"
Write-Host "  配置模板已创建" -ForegroundColor Green

# 3. 导出环境信息
Write-Host "`n[3/5] 导出环境信息..." -ForegroundColor Yellow
$envInfo = @{
    backupDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    machineName = $env:COMPUTERNAME
    userName = $env:USERNAME
}
$envInfo | ConvertTo-Json | Out-File "$BackupDir\environment-info.json"
Write-Host "  环境信息已导出" -ForegroundColor Green

# 4. 创建简单恢复脚本
Write-Host "`n[4/5] 创建恢复脚本..." -ForegroundColor Yellow
$restoreScript = @"
# 恢复脚本
git clone https://github.com/fdsasaaa/openclaw-workspace.git C:\OpenClaw_Workspace
npm install -g openclaw
pip install backtrader pandas numpy
Write-Host '恢复完成！请手动配置API密钥'
"@
$restoreScript | Out-File "$BackupDir\restore.ps1" -Encoding UTF8
Write-Host "  恢复脚本已创建" -ForegroundColor Green

# 5. 创建压缩包
if ($CreateArchive) {
    Write-Host "`n[5/5] 创建压缩包..." -ForegroundColor Yellow
    $archivePath = "$BackupDir.zip"
    Compress-Archive -Path $BackupDir -DestinationPath $archivePath -Force
    Write-Host "  压缩包已创建: $archivePath" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "备份完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "GitHub仓库已更新" -ForegroundColor Gray
Write-Host "本地备份: $BackupDir" -ForegroundColor Gray
if ($CreateArchive) { Write-Host "压缩包: $BackupDir.zip" -ForegroundColor Gray }
