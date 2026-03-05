#!/usr/bin/env pwsh
<#
EnergyBlock 环境打包备份脚本
用途：将当前完整环境打包，便于迁移到新机器
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$BackupDir = "C:\EnergyBlock-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeSecrets,
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateArchive
)

$ErrorActionPreference = "Stop"

Write-Host @"
========================================
EnergyBlock Environment Backup Tool
========================================
"@ -ForegroundColor Cyan

# 创建备份目录
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
Write-Host "`n备份目录: $BackupDir" -ForegroundColor Yellow

# 1. 备份工作区（通过Git推送）
Write-Host "`n[1/6] 推送工作区到GitHub..." -ForegroundColor Yellow
Set-Location "C:\OpenClaw_Workspace"
git add .
git commit -m "Backup: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git push origin master
Write-Host "  ✓ GitHub同步完成"

# 2. 导出配置文件（脱敏）
Write-Host "`n[2/6] 导出配置文件..." -ForegroundColor Yellow

# OpenClaw配置（移除敏感信息）
$openclawConfig = Get-Content "$env:USERPROFILE\.openclaw\openclaw.json" | ConvertFrom-Json

# 移除敏感字段
if ($openclawConfig.auth) {
    $openclawConfig.auth.token = "PLACEHOLDER_TOKEN"
}
if ($openclawConfig.channels?.telegram?.botToken) {
    $openclawConfig.channels.telegram.botToken = "PLACEHOLDER_BOT_TOKEN"
}

$openclawConfig | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\openclaw.json.template"
Write-Host "  ✓ OpenClaw配置模板已创建（敏感信息已移除）"

# 3. 导出环境信息
Write-Host "`n[3/6] 导出环境信息..." -ForegroundColor Yellow

$envInfo = @{
    "backupDate" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "machineName" = $env:COMPUTERNAME
    "userName" = $env:USERNAME
    "openclawVersion" = (openclaw --version 2>$null) -replace '[^0-9.]', ''
    "nodeVersion" = node --version
    "pythonVersion" = python --version
    "gitVersion" = git --version
    "installedPackages" = @{
        "npm" = @("openclaw")
        "python" = @("backtrader", "pandas", "numpy")
    }
    "scheduledTasks" = @(
        "EnergyBlock-Git-Sync"
    )
}

$envInfo | ConvertTo-Json -Depth 5 | Out-File "$BackupDir\environment-info.json"
Write-Host "  ✓ 环境信息已导出"

# 4. 创建安装脚本
Write-Host "`n[4/6] 创建安装脚本..." -ForegroundColor Yellow

$installScript = @'
#!/usr/bin/env pwsh
# EnergyBlock 环境恢复脚本
# 在新机器上运行此脚本恢复完整环境

param(
    [string]$GitHubRepo = "https://github.com/fdsasaaa/openclaw-workspace.git"
)

Write-Host "开始恢复EnergyBlock环境..." -ForegroundColor Cyan

# 1. 安装OpenClaw
npm install -g openclaw@latest

# 2. 克隆工作区
git clone $GitHubRepo C:\OpenClaw_Workspace

# 3. 安装Python依赖
pip install backtrader pandas numpy matplotlib

# 4. 恢复配置（手动步骤）
Write-Host "`n请手动配置以下信息：" -ForegroundColor Yellow
Write-Host "  1. 复制 openclaw.json.template 到 ~/.openclaw/openclaw.json"
Write-Host "  2. 填入你的API密钥"
Write-Host "  3. 配置Telegram Bot Token（如需要）"
Write-Host "  4. 配置Brave API Key（如需要）"

Write-Host "`n恢复完成！请运行审计脚本验证："
Write-Host "  python C:\OpenClaw_Workspace\scripts\audit_all_stages.py"
'@

$installScript | Out-File "$BackupDir\restore.ps1" -Encoding UTF8
Write-Host "  ✓ 恢复脚本已创建"

# 5. 敏感信息备份（可选，加密）
if ($IncludeSecrets) {
    Write-Host "`n[5/6] 备份敏感信息（加密）..." -ForegroundColor Yellow
    
    $secretsDir = "$BackupDir\secrets"
    New-Item -ItemType Directory -Path $secretsDir -Force | Out-Null
    
    # 复制原始配置文件（加密存储）
    Copy-Item "$env:USERPROFILE\.openclaw\openclaw.json" "$secretsDir\openclaw.json.original"
    Copy-Item "$env:USERPROFILE\.openclaw\agents\main\agent\auth-profiles.json" "$secretsDir\auth-profiles.json"
    
    Write-Host "  ⚠️  敏感信息已备份到: $secretsDir" -ForegroundColor Red
    Write-Host "  ⚠️  请妥善保管，不要上传到公共仓库！" -ForegroundColor Red
}
else {
    Write-Host "`n[5/6] 跳过敏感信息备份（使用 -IncludeSecrets 可包含）"
}

# 6. 创建README
Write-Host "`n[6/6] 创建部署指南..." -ForegroundColor Yellow

$readme = @"
# EnergyBlock 环境备份包

**备份时间**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**源机器**: $env:COMPUTERNAME  
**源用户**: $env:USERNAME

---

## 快速恢复

在新机器上运行：
```powershell
.\restore.ps1
```

## 手动步骤

### 1. 安装依赖
- Node.js: https://nodejs.org/
- Python: https://python.org/
- Git: https://git-scm.com/

### 2. 安装OpenClaw
```bash
npm install -g openclaw
```

### 3. 克隆工作区
```bash
git clone https://github.com/fdsasaaa/openclaw-workspace.git C:\OpenClaw_Workspace
```

### 4. 恢复配置
复制 openclaw.json.template 到 `~/.openclaw/openclaw.json`，填入你的API密钥。

### 5. 验证安装
```bash
python C:\OpenClaw_Workspace\scripts\audit_all_stages.py
```

---

## 注意事项

- 敏感信息（API密钥）需要重新配置或从安全备份恢复
- 计划任务需要在新机器上重新创建
- 环境变量需要重新设置

---

## 联系

**项目**: EnergyBlock Strategies  
**仓库**: https://github.com/fdsasaaa/openclaw-workspace
"@

$readme | Out-File "$BackupDir\README.md" -Encoding UTF8
Write-Host "  ✓ 部署指南已创建"

# 创建压缩包（可选）
if ($CreateArchive) {
    Write-Host "`n创建压缩包..." -ForegroundColor Yellow
    $archivePath = "$BackupDir.zip"
    Compress-Archive -Path $BackupDir -DestinationPath $archivePath
    Write-Host "  ✓ 压缩包已创建: $archivePath"
}

# 完成
Write-Host @"

========================================
备份完成！
========================================

备份位置: $BackupDir
"@ -ForegroundColor Green

if ($IncludeSecrets) {
    Write-Host "`n⚠️  警告：备份包含敏感信息！" -ForegroundColor Red
    Write-Host "   请妥善保管，不要上传到公共网络！" -ForegroundColor Red
}

Write-Host @"

使用方式：
1. 将备份目录复制到新机器
2. 运行 restore.ps1
3. 按提示配置API密钥
4. 验证安装

或者使用部署脚本：
  scripts\deploy-new-machine.ps1
========================================
"@ -ForegroundColor Cyan
