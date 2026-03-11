# 一键恢复脚本（新电脑使用）
# 功能：自动完成环境准备和配置
# 使用方法：在新电脑上运行此脚本

param(
    [string]$GitRepo = "https://github.com/fdsasaaa/openclaw-workspace.git",
    [string]$WorkspacePath = "C:\OpenClaw_Workspace\workspace",
    [switch]$SkipNodeCheck,
    [switch]$SkipOpenClawInstall
)

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "虾哥一键恢复脚本" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "这个脚本会自动完成：" -ForegroundColor Yellow
Write-Host "1. 检查 Node.js 环境" -ForegroundColor White
Write-Host "2. 安装 OpenClaw" -ForegroundColor White
Write-Host "3. 克隆 Git 仓库" -ForegroundColor White
Write-Host "4. 验证文件完整性" -ForegroundColor White
Write-Host "5. 提供下一步指引" -ForegroundColor White
Write-Host ""

# 1. 检查 Node.js
Write-Host "[1/5] 检查 Node.js..." -ForegroundColor Yellow

if (-not $SkipNodeCheck) {
    try {
        $nodeVersion = node --version
        $npmVersion = npm --version
        Write-Host "  [OK] Node.js: $nodeVersion" -ForegroundColor Green
        Write-Host "  [OK] npm: $npmVersion" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] Node.js 未安装" -ForegroundColor Red
        Write-Host ""
        Write-Host "请先安装 Node.js (v18+)：" -ForegroundColor Yellow
        Write-Host "下载地址：https://nodejs.org/" -ForegroundColor White
        Write-Host ""
        Write-Host "安装完成后，重新运行此脚本" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "  [SKIP] 跳过 Node.js 检查" -ForegroundColor Yellow
}

Write-Host ""

# 2. 安装 OpenClaw
Write-Host "[2/5] 安装 OpenClaw..." -ForegroundColor Yellow

if (-not $SkipOpenClawInstall) {
    try {
        $openclawVersion = openclaw --version
        Write-Host "  [OK] OpenClaw 已安装：$openclawVersion" -ForegroundColor Green
    } catch {
        Write-Host "  OpenClaw 未安装，正在安装..." -ForegroundColor Cyan
        npm install -g openclaw
        Write-Host "  [OK] OpenClaw 安装完成" -ForegroundColor Green
    }
} else {
    Write-Host "  [SKIP] 跳过 OpenClaw 安装" -ForegroundColor Yellow
}

Write-Host ""

# 3. 克隆 Git 仓库
Write-Host "[3/5] 克隆 Git 仓库..." -ForegroundColor Yellow

if (Test-Path $WorkspacePath) {
    Write-Host "  [WARNING] 目标路径已存在：$WorkspacePath" -ForegroundColor Yellow
    Write-Host "  检查是否为 Git 仓库..." -ForegroundColor Cyan
    
    cd $WorkspacePath
    if (Test-Path ".git") {
        Write-Host "  [OK] 已是 Git 仓库，拉取最新代码..." -ForegroundColor Green
        git pull origin master
    } else {
        Write-Host "  [ERROR] 目标路径存在但不是 Git 仓库" -ForegroundColor Red
        Write-Host "  请手动删除或重命名该目录，然后重新运行脚本" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "  正在克隆仓库..." -ForegroundColor Cyan
    Write-Host "  仓库地址：$GitRepo" -ForegroundColor White
    Write-Host "  目标路径：$WorkspacePath" -ForegroundColor White
    
    # 创建父目录
    $parentPath = Split-Path $WorkspacePath -Parent
    if (-not (Test-Path $parentPath)) {
        New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
    }
    
    git clone $GitRepo $WorkspacePath
    Write-Host "  [OK] 仓库克隆完成" -ForegroundColor Green
}

Write-Host ""

# 4. 验证文件完整性
Write-Host "[4/5] 验证文件完整性..." -ForegroundColor Yellow

cd $WorkspacePath

$coreFiles = @(
    "MASTER-RECOVERY-GUIDE.md",
    "FIRST-RUN.md",
    "RESTORE-COMMAND.md",
    "RECOVERY.md",
    "IDENTITY.md",
    "SOUL.md",
    "AGENTS.md",
    "USER.md",
    "TOOLS.md",
    "HEARTBEAT.md",
    "MEMORY.md",
    "SYSTEM-STATE.json",
    "RECOVERY-VERSION.json"
)

$missingFiles = @()
foreach ($file in $coreFiles) {
    if (Test-Path $file) {
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $file - 缺失" -ForegroundColor Red
        $missingFiles += $file
    }
}

Write-Host ""

if ($missingFiles.Count -gt 0) {
    Write-Host "[ERROR] 文件完整性验证失败" -ForegroundColor Red
    Write-Host "缺失文件：$($missingFiles -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "建议：" -ForegroundColor Yellow
    Write-Host "1. 检查 Git 仓库是否完整" -ForegroundColor White
    Write-Host "2. 尝试重新克隆仓库" -ForegroundColor White
    exit 1
}

Write-Host "[OK] 文件完整性验证通过" -ForegroundColor Green
Write-Host ""

# 5. 下一步指引
Write-Host "[5/5] 环境准备完成！" -ForegroundColor Green
Write-Host ""

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "下一步操作" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. 配置 OpenClaw" -ForegroundColor Yellow
Write-Host ""
Write-Host "   方法 A：使用配置向导（推荐）" -ForegroundColor Cyan
Write-Host "   openclaw wizard" -ForegroundColor White
Write-Host ""
Write-Host "   方法 B：手动配置" -ForegroundColor Cyan
Write-Host "   编辑：~/.openclaw/openclaw.json" -ForegroundColor White
Write-Host "   参考：$WorkspacePath\config-backup\openclaw.json.template" -ForegroundColor White
Write-Host ""

Write-Host "2. 启动 OpenClaw 网关" -ForegroundColor Yellow
Write-Host "   openclaw gateway start" -ForegroundColor White
Write-Host ""

Write-Host "3. 在飞书发送恢复指令" -ForegroundColor Yellow
Write-Host "   读取 workspace\FIRST-RUN.md" -ForegroundColor White
Write-Host ""

Write-Host "4. 等待虾哥自动恢复（约 30 秒）" -ForegroundColor Yellow
Write-Host ""

Write-Host "5. 验证恢复成功" -ForegroundColor Yellow
Write-Host "   发送：恢复工作状态" -ForegroundColor White
Write-Host ""

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "重要提示" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "配置 OpenClaw 时需要：" -ForegroundColor Yellow
Write-Host "1. API Key（yunyi 代理或其他）" -ForegroundColor White
Write-Host "2. 飞书 App ID 和 App Secret" -ForegroundColor White
Write-Host "3. Telegram Bot Token（可选）" -ForegroundColor White
Write-Host ""

Write-Host "如果没有这些信息，请联系管理员获取" -ForegroundColor Yellow
Write-Host ""

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "快速参考" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "查看完整恢复指南：" -ForegroundColor Yellow
Write-Host "  notepad $WorkspacePath\MASTER-RECOVERY-GUIDE.md" -ForegroundColor White
Write-Host ""

Write-Host "验证恢复系统：" -ForegroundColor Yellow
Write-Host "  powershell -File $WorkspacePath\scripts\verify-recovery.ps1" -ForegroundColor White
Write-Host ""

Write-Host "查看 OpenClaw 状态：" -ForegroundColor Yellow
Write-Host "  openclaw status" -ForegroundColor White
Write-Host ""

Write-Host "查看 OpenClaw 日志：" -ForegroundColor Yellow
Write-Host "  openclaw logs" -ForegroundColor White
Write-Host ""

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "一键恢复完成！🦐" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "工作区路径：$WorkspacePath" -ForegroundColor Cyan
Write-Host "Git 仓库：$GitRepo" -ForegroundColor Cyan
Write-Host ""

Write-Host "祝你好运！虾哥很快就会回来了 🦐" -ForegroundColor Green
