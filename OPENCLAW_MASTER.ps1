#!/usr/bin/env pwsh
<#
OPENCLAW_MASTER.ps1 核心版（适配E盘/管理员/UTF-8）
功能：环境检查 + Python库安装 + EA优化前置准备
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ====================== 配置项 ======================
$WorkspaceRoot = "E:\OpenClaw_Workspace"
$PythonLibs = @("backtrader", "pandas", "numpy", "matplotlib", "pytz")
# ====================================================

# 1. 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ 请以管理员身份运行此脚本！" -ForegroundColor Red
    exit 1
}

# 2. 创建工作区目录
if (-not (Test-Path $WorkspaceRoot)) {
    New-Item -Path $WorkspaceRoot -ItemType Directory -Force | Out-Null
    New-Item -Path "$WorkspaceRoot\step01" -ItemType Directory -Force | Out-Null
    New-Item -Path "$WorkspaceRoot\step02" -ItemType Directory -Force | Out-Null
    Write-Host "✅ 工作区创建完成: $WorkspaceRoot" -ForegroundColor Green
}

# 3. 检查Python是否安装
$pythonPath = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonPath) {
    Write-Host "⚠️ 未找到Python，正在提示安装..." -ForegroundColor Yellow
    Write-Host "请先安装Python 3.9+，下载地址：https://www.python.org/downloads/" -ForegroundColor Cyan
    exit 1
}
Write-Host "✅ Python已安装: $($pythonPath.Source)" -ForegroundColor Green

# 4. 升级pip并安装核心库
Write-Host "🔧 开始安装/升级Python依赖库..." -ForegroundColor Cyan
python -m pip install --upgrade pip --quiet
foreach ($lib in $PythonLibs) {
    try {
        python -m pip install --upgrade $lib --quiet
        Write-Host "✅ 安装成功: $lib" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ 安装失败: $lib（可忽略，继续执行）" -ForegroundColor Yellow
    }
}

# 5. 验证Backtrader（EA优化核心库）
try {
    python -c "import backtrader; print(f'✅ Backtrader版本: {backtrader.__version__}')"
    Write-Host "`n🎉 所有前置准备完成！" -ForegroundColor Green
    Write-Host "下一步：将EA源码放入 $WorkspaceRoot\EA 目录，执行step02\01-ea-optimize.ps1 启动优化" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Backtrader验证失败: $_" -ForegroundColor Red
    exit 1
}

exit 0