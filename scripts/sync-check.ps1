#!/usr/bin/env pwsh
<#
EnergyBlock 环境同步检查脚本
用途：检查当前环境是否与GitHub仓库同步
#>

Write-Host @"
========================================
EnergyBlock Environment Sync Check
========================================
"@ -ForegroundColor Cyan

Set-Location "C:\OpenClaw_Workspace"

# 检查Git状态
Write-Host "`n检查Git状态..." -ForegroundColor Yellow
$status = git status --porcelain

if ($status) {
    Write-Host "  ⚠️  发现未提交的变更:" -ForegroundColor Yellow
    $status | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    
    $commit = Read-Host "`n是否立即提交并推送? [Y/N]"
    if ($commit -eq 'Y') {
        git add .
        git commit -m "Auto sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git push origin master
        Write-Host "  ✓ 同步完成" -ForegroundColor Green
    }
} else {
    Write-Host "  ✓ 工作区与GitHub同步" -ForegroundColor Green
}

# 检查远程更新
Write-Host "`n检查远程更新..." -ForegroundColor Yellow
git fetch origin
$behind = git rev-list HEAD..origin/master --count

if ($behind -gt 0) {
    Write-Host "  ⚠️  远程仓库有 $behind 个新提交" -ForegroundColor Yellow
    $pull = Read-Host "是否拉取更新? [Y/N]"
    if ($pull -eq 'Y') {
        git pull origin master
        Write-Host "  ✓ 更新已拉取" -ForegroundColor Green
    }
} else {
    Write-Host "  ✓ 本地已是最新版本" -ForegroundColor Green
}

# 检查关键文件
Write-Host "`n检查关键文件..." -ForegroundColor Yellow
$keyFiles = @(
    "README.md",
    "configs/execution-rules.md",
    "scripts/audit_all_stages.py",
    "scripts/emergency-rollback.ps1"
)

$missingFiles = @()
foreach ($file in $keyFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles) {
    Write-Host "  ⚠️  缺少关键文件:" -ForegroundColor Yellow
    $missingFiles | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
} else {
    Write-Host "  ✓ 所有关键文件存在" -ForegroundColor Green
}

# 检查结果
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "同步检查完成" -ForegroundColor Green
