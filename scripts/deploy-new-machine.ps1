#!/usr/bin/env pwsh
<#
EnergyBlock OpenClaw 一键部署脚本
用途：在新电脑上快速部署完整的OpenClaw环境
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "https://github.com/fdsasaaa/openclaw-workspace.git",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkspaceDir = "C:\OpenClaw_Workspace",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipGitHubSetup,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTelegramSetup
)

$ErrorActionPreference = "Stop"

Write-Host @"
========================================
EnergyBlock OpenClaw Deployment Tool
========================================
"@ -ForegroundColor Cyan

# 1. 检查前提条件
Write-Host "`n[1/8] 检查前提条件..." -ForegroundColor Yellow

# 检查Node.js
$nodeVersion = node --version 2>$null
if (-not $nodeVersion) {
    Write-Error "Node.js未安装！请先安装: https://nodejs.org/"
    exit 1
}
Write-Host "  ✓ Node.js: $nodeVersion"

# 检查Python
$pythonVersion = python --version 2>$null
if (-not $pythonVersion) {
    Write-Error "Python未安装！请先安装: https://python.org/"
    exit 1
}
Write-Host "  ✓ Python: $pythonVersion"

# 检查Git
$gitVersion = git --version 2>$null
if (-not $gitVersion) {
    Write-Error "Git未安装！请先安装: https://git-scm.com/"
    exit 1
}
Write-Host "  ✓ Git: $gitVersion"

# 2. 安装OpenClaw
Write-Host "`n[2/8] 安装OpenClaw..." -ForegroundColor Yellow
npm install -g openclaw@latest
Write-Host "  ✓ OpenClaw安装完成"

# 3. 创建工作区目录
Write-Host "`n[3/8] 创建工作区..." -ForegroundColor Yellow
if (Test-Path $WorkspaceDir) {
    Write-Host "  目录已存在，备份旧目录..." -ForegroundColor Gray
    Rename-Item $WorkspaceDir "$WorkspaceDir.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
}
New-Item -ItemType Directory -Path $WorkspaceDir -Force | Out-Null
Write-Host "  ✓ 工作区目录创建: $WorkspaceDir"

# 4. 克隆GitHub仓库
Write-Host "`n[4/8] 克隆工作区仓库..." -ForegroundColor Yellow
Set-Location (Split-Path $WorkspaceDir -Parent)
git clone $GitHubRepo (Split-Path $WorkspaceDir -Leaf)
Write-Host "  ✓ 仓库克隆完成"

# 5. 安装Python依赖
Write-Host "`n[5/8] 安装Python依赖..." -ForegroundColor Yellow
$requirements = @"
backtrader
pandas
numpy
matplotlib
"@
$reqFile = "$env:TEMP\energyblock-requirements.txt"
$requirements | Out-File $reqFile -Encoding UTF8
python -m pip install -r $reqFile
Write-Host "  ✓ Python依赖安装完成"

# 6. 配置OpenClaw
Write-Host "`n[6/8] 配置OpenClaw..." -ForegroundColor Yellow
$openclawDir = "$env:USERPROFILE\.openclaw"
if (-not (Test-Path $openclawDir)) {
    New-Item -ItemType Directory -Path $openclawDir -Force | Out-Null
}

# 创建基础配置
$baseConfig = @"
{
  "meta": {
    "lastTouchedVersion": "2026.3.2",
    "lastTouchedAt": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')"
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "kimi-coding/k2p5",
        "fallbacks": ["moonshot/kimi-k2.5"]
      }
    }
  },
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "$(-join ((48..57) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ }))"
    }
  },
  "channels": {
    "telegram": {
      "enabled": false
    }
  }
}
"@

$baseConfig | Out-File "$openclawDir\openclaw.json" -Encoding UTF8
Write-Host "  ✓ 基础配置创建完成"
Write-Host "  ⚠️  请手动配置：" -ForegroundColor Yellow
Write-Host "     - Telegram Bot Token" -ForegroundColor Gray
Write-Host "     - Brave API Key" -ForegroundColor Gray
Write-Host "     - API密钥 (auth-profiles.json)" -ForegroundColor Gray

# 7. 设置环境变量
Write-Host "`n[7/8] 设置环境变量..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("BRAVE_API_KEY", "", "User")
Write-Host "  ✓ 环境变量框架设置完成"

# 8. 创建计划任务
Write-Host "`n[8/8] 创建自动化任务..." -ForegroundColor Yellow

# Git同步任务
$gitSyncAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$WorkspaceDir\scripts\git-sync-daily.ps1`""
$gitSyncTrigger = New-ScheduledTaskTrigger -Daily -At "02:00"
$gitSyncPrincipal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
$gitSyncSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName "EnergyBlock-Git-Sync" -Action $gitSyncAction -Trigger $gitSyncTrigger -Principal $gitSyncPrincipal -Settings $gitSyncSettings -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ Git同步任务创建完成"

# 完成
Write-Host @"

========================================
部署完成！
========================================

工作区位置: $WorkspaceDir
GitHub仓库: $GitHubRepo

下一步操作:
1. 配置API密钥:
   - Moonshot/Kimi API Key
   - Telegram Bot Token (可选)
   - Brave API Key (可选)

2. 启动Gateway:
   openclaw gateway start

3. 验证安装:
   openclaw status

4. 运行审计:
   python $WorkspaceDir\scripts\audit_all_stages.py

详细配置指南: $WorkspaceDir\README.md
========================================
"@ -ForegroundColor Green
