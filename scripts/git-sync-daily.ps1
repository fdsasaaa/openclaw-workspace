#!/usr/bin/env pwsh
# OpenClaw 每日Git同步脚本
# 自动提交并推送到GitHub

Set-Location "C:\OpenClaw_Workspace"

# 获取当前日期
date

# 检查是否有变更
$status = git status --porcelain
if (-not $status) {
    Write-Host "[$(Get-Date)] 无变更，跳过同步" -ForegroundColor Gray
    exit 0
}

# 添加所有变更
git add .

# 提交
date

# 推送
git push origin master

if ($LASTEXITCODE -eq 0) {
    Write-Host "[$(Get-Date)] 同步成功" -ForegroundColor Green
} else {
    Write-Host "[$(Get-Date)] 同步失败" -ForegroundColor Red
}
