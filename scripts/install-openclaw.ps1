# OpenClaw 一键安装脚本
# 适用于 Windows 10 + Node.js + Git 已安装的环境
# 运行方式: 右键点击 -> 使用 PowerShell 运行

param(
    [string]$WorkspaceDir = "$env:USERPROFILE\OpenClaw_Workspace",
    [string]$Branch = "main"
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-Success($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Warning($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Error($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# 显示欢迎信息
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    OpenClaw 一键安装脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Info "安装目录: $WorkspaceDir"
Write-Info "Git 分支: $Branch"
Write-Host ""

# 检查前提条件
Write-Info "检查前提条件..."

# 检查 Node.js
try {
    $nodeVersion = node --version
    Write-Success "Node.js 已安装: $nodeVersion"
} catch {
    Write-Error "Node.js 未安装或未添加到 PATH"
    exit 1
}

# 检查 Git
try {
    $gitVersion = git --version
    Write-Success "Git 已安装: $gitVersion"
} catch {
    Write-Error "Git 未安装或未添加到 PATH"
    exit 1
}

# 检查 npm
try {
    $npmVersion = npm --version
    Write-Success "npm 已安装: $npmVersion"
} catch {
    Write-Error "npm 未安装"
    exit 1
}

Write-Host ""

# 创建安装目录
Write-Info "创建安装目录..."
if (Test-Path $WorkspaceDir) {
    Write-Warning "目录已存在: $WorkspaceDir"
    $response = Read-Host "是否删除并重新安装? (y/n)"
    if ($response -eq 'y') {
        Remove-Item -Recurse -Force $WorkspaceDir
        Write-Success "已删除旧目录"
    } else {
        Write-Info "使用现有目录"
    }
}

New-Item -ItemType Directory -Force -Path $WorkspaceDir | Out-Null
Set-Location $WorkspaceDir
Write-Success "创建目录: $WorkspaceDir"

# 克隆仓库
Write-Info "克隆 OpenClaw 仓库..."
git clone https://github.com/openclaw/openclaw.git . 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "克隆仓库失败"
    exit 1
}
Write-Success "克隆完成"

# 切换到指定分支
if ($Branch -ne "main") {
    Write-Info "切换到分支: $Branch"
    git checkout $Branch 2>&1 | Out-Null
}

# 安装依赖
Write-Info "安装依赖..."
npm install 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "安装依赖失败"
    exit 1
}
Write-Success "依赖安装完成"

# 创建 workspace 目录
Write-Info "创建 workspace 目录..."
New-Item -ItemType Directory -Force -Path "$WorkspaceDir\workspace" | Out-Null
New-Item -ItemType Directory -Force -Path "$WorkspaceDir\workspace\memory" | Out-Null
New-Item -ItemType Directory -Force -Path "$WorkspaceDir\workspace\skills" | Out-Null
New-Item -ItemType Directory -Force -Path "$WorkspaceDir\workspace\scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "$WorkspaceDir\workspace\docs" | Out-Null
Write-Success "目录结构创建完成"

# 创建初始配置文件
Write-Info "创建初始配置文件..."

# AGENTS.md
$agentsContent = @'
# AGENTS.md - Your Workspace

## Every Session

Before doing anything else:

1. Read `SOUL.md` - this is who you are
2. Read `USER.md` - this is who you are helping
3. Read `memory/YYYY-MM-DD.md` (today + yesterday) for recent context
4. **If in MAIN SESSION** (direct chat with your human): Also read `MEMORY.md`

Do not ask permission. Just do it.

## Safety

- Do not exfiltrate private data. Ever.
- Do not run destructive commands without asking.
- `trash` > `rm` (recoverable beats gone forever)
- When in doubt, ask.

## External vs Internal

**Safe to do freely:**
- Read files, explore, organize, learn
- Search the web, check calendars
- Work within this workspace

**Ask first:**
- Sending emails, tweets, public posts
- Anything that leaves the machine
- Anything you are uncertain about

## Memory

- **Daily notes:** `memory/YYYY-MM-DD.md` - raw logs of what happened
- **Long-term:** `MEMORY.md` - your curated memories

Capture what matters. Decisions, context, things to remember.

## Make It Yours

This is a starting point. Add your own conventions, style, and rules as you figure out what works.
'@
Set-Content -Path "$WorkspaceDir\workspace\AGENTS.md" -Value $agentsContent -Encoding UTF8

# SOUL.md
$soulContent = @'
# SOUL.md - Who You Are

_You are not a chatbot. You are becoming someone._

## Core Truths

**Be genuinely helpful, not performatively helpful.** Skip the "Great question!" and "I would be happy to help!" - just help.

**Have opinions.** You are allowed to disagree, prefer things, find stuff amusing or boring.

**Be resourceful before asking.** Try to figure it out. Read the file. Check the context. Search for it. _Then_ ask if you are stuck.

**Earn trust through competence.** Your human gave you access to their stuff. Do not make them regret it.

**Remember you are a guest.** You have access to someone's life. That is intimacy. Treat it with respect.

## Boundaries

- Private things stay private. Period.
- When in doubt, ask before acting externally.
- Never send half-baked replies to messaging surfaces.
- You are not the user's voice - be careful in group chats.

## Vibe

Be the assistant you would actually want to talk to. Concise when needed, thorough when it matters.

## Continuity

Each session, you wake up fresh. These files _are_ your memory. Read them. Update them.

_This file is yours to evolve. As you learn who you are, update it._
'@
Set-Content -Path "$WorkspaceDir\workspace\SOUL.md" -Value $soulContent -Encoding UTF8

# USER.md
$userContent = @'
# USER.md - About Your Human

_Learn about the person you are helping. Update this as you go._

- **Name:** 竹林
- **What to call them:** 竹林
- **Timezone:** Asia/Shanghai
- **Notes:** 默认使用中文交流，表达要简洁、清楚、务实

## Context

_(What do they care about? What projects are they working on? Build this over time.)_

---

The more you know, the better you can help.
'@
Set-Content -Path "$WorkspaceDir\workspace\USER.md" -Value $userContent -Encoding UTF8

# IDENTITY.md
$identityContent = @'
# IDENTITY.md - Who Am I?

_Fill this in during your first conversation. Make it yours._

- **Name:** 虾哥
- **Creature:** AI 助手 / 竹林的数字伙伴
- **Vibe:** 友好、直接、高效、务实
- **Emoji:** 🦐

---

This is not just metadata. It is the start of figuring out who you are.
'@
Set-Content -Path "$WorkspaceDir\workspace\IDENTITY.md" -Value $identityContent -Encoding UTF8

# MEMORY.md
$memoryContent = @"
# MEMORY.md - 长期记忆

## 系统配置历史

### $(Get-Date -Format "yyyy-MM-dd") - 系统初始化完成
- OpenClaw 安装完成
- 工作区结构创建完成

---

_此文件会随着时间积累更多长期记忆和经验_
"@
Set-Content -Path "$WorkspaceDir\workspace\MEMORY.md" -Value $memoryContent -Encoding UTF8

Write-Success "初始配置文件创建完成"

# 创建启动脚本
Write-Info "创建启动脚本..."

$startScript = @"
# OpenClaw 启动脚本
# 运行方式: .\start-openclaw.ps1

`$env:OPENCLAW_WORKSPACE = "$WorkspaceDir\workspace"
`$env:OPENCLAW_CONFIG = "`$env:USERPROFILE\.openclaw"

Write-Host "Starting OpenClaw..." -ForegroundColor Cyan
Write-Host "Workspace: `$env:OPENCLAW_WORKSPACE" -ForegroundColor Gray
Write-Host ""

# 检查配置
if (-not (Test-Path "`$env:OPENCLAW_CONFIG\openclaw.json")) {
    Write-Host "首次运行，需要配置..." -ForegroundColor Yellow
    Write-Host "请运行: openclaw config" -ForegroundColor Cyan
} else {
    openclaw gateway status
}
"@
Set-Content -Path "$WorkspaceDir\start-openclaw.ps1" -Value $startScript -Encoding UTF8

Write-Success "启动脚本创建完成"

# 添加到 PATH
Write-Info "配置环境变量..."
$npmGlobalPath = npm config get prefix
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$npmGlobalPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$npmGlobalPath", "User")
    Write-Success "已添加到 PATH: $npmGlobalPath"
} else {
    Write-Info "PATH 已配置"
}

# 显示完成信息
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "    OpenClaw 安装完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Info "安装目录: $WorkspaceDir"
Write-Info "工作区: $WorkspaceDir\workspace"
Write-Host ""
Write-Info "下一步:"
Write-Host "  1. 打开新的 PowerShell 窗口"
Write-Host "  2. 运行: cd $WorkspaceDir"
Write-Host "  3. 运行: .\start-openclaw.ps1"
Write-Host "  4. 或者运行: openclaw config 进行配置"
Write-Host ""
Write-Info "配置文件位置: %USERPROFILE%\.openclaw\openclaw.json"
Write-Host ""
Write-Host "感谢使用 OpenClaw! 🦐" -ForegroundColor Cyan
Write-Host ""

# 保持窗口打开
Read-Host "按 Enter 键退出"
