# OpenClaw 一键安装脚本
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    OpenClaw 一键安装" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Node.js
try {
    $nodeVersion = node --version
    Write-Host "[OK] Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js 未安装" -ForegroundColor Red
    exit 1
}

# 检查 Git
try {
    $gitVersion = git --version
    Write-Host "[OK] Git: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Git 未安装" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 创建安装目录
$installDir = "$env:USERPROFILE\OpenClaw_Workspace"
Write-Host "[INFO] 安装目录: $installDir" -ForegroundColor Cyan

if (Test-Path $installDir) {
    Write-Host "[WARN] 目录已存在，删除中..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $installDir
}

New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Set-Location $installDir
Write-Host "[OK] 创建目录完成" -ForegroundColor Green

# 克隆仓库
Write-Host "[INFO] 克隆 OpenClaw 仓库（需要 1-2 分钟）..." -ForegroundColor Cyan
git clone https://github.com/openclaw/openclaw.git . 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] 克隆失败，请检查网络连接" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] 克隆完成" -ForegroundColor Green

# 安装依赖
Write-Host "[INFO] 安装依赖（需要 2-5 分钟）..." -ForegroundColor Cyan
npm install 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] 安装依赖失败" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] 依赖安装完成" -ForegroundColor Green

# 创建 workspace
Write-Host "[INFO] 创建工作区..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$installDir\workspace" | Out-Null
New-Item -ItemType Directory -Force -Path "$installDir\workspace\memory" | Out-Null
New-Item -ItemType Directory -Force -Path "$installDir\workspace\skills" | Out-Null
New-Item -ItemType Directory -Force -Path "$installDir\workspace\scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "$installDir\workspace\docs" | Out-Null

# 创建配置文件
'# AGENTS.md - Your Workspace
## Every Session
Before doing anything else:
1. Read `SOUL.md`
2. Read `USER.md`
3. Read `memory/YYYY-MM-DD.md`
4. **If in MAIN SESSION**: Also read `MEMORY.md`' | Set-Content -Path "$installDir\workspace\AGENTS.md" -Encoding UTF8

'# SOUL.md - Who You Are
_Be genuinely helpful, not performatively helpful._' | Set-Content -Path "$installDir\workspace\SOUL.md" -Encoding UTF8

'# USER.md - About Your Human
- **Name:** 竹林
- **Timezone:** Asia/Shanghai
- **Notes:** 默认使用中文交流' | Set-Content -Path "$installDir\workspace\USER.md" -Encoding UTF8

'# IDENTITY.md - Who Am I?
- **Name:** 虾哥
- **Emoji:** 🦐' | Set-Content -Path "$installDir\workspace\IDENTITY.md" -Encoding UTF8

'# MEMORY.md - 长期记忆
## 系统配置历史' | Set-Content -Path "$installDir\workspace\MEMORY.md" -Encoding UTF8

Write-Host "[OK] 配置文件创建完成" -ForegroundColor Green

# 添加到 PATH
$npmGlobal = npm config get prefix
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$npmGlobal*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$npmGlobal", "User")
    Write-Host "[OK] 已添加到 PATH" -ForegroundColor Green
}

# 完成
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "    OpenClaw 安装完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "安装目录: $installDir" -ForegroundColor Cyan
Write-Host "工作区: $installDir\workspace" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步:" -ForegroundColor Yellow
Write-Host "  1. 关闭此窗口" -ForegroundColor White
Write-Host "  2. 重新打开 PowerShell" -ForegroundColor White
Write-Host "  3. 运行: openclaw config" -ForegroundColor White
Write-Host "  4. 配置通信通道（飞书/Discord/Telegram）" -ForegroundColor White
Write-Host ""
Read-Host "按 Enter 退出"
