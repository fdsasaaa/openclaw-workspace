# 恢复系统自动更新脚本
# 功能：检测核心文件变化，自动更新恢复系统
# 使用方法：直接运行或配置为 Cron 任务

param(
    [switch]$Force,  # 强制更新
    [switch]$DryRun  # 仅检查，不实际更新
)

$ErrorActionPreference = "Stop"
$workspacePath = "C:\OpenClaw_Workspace\workspace"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "恢复系统自动更新" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 1. 检查核心文件是否存在
Write-Host "[1/6] 检查核心文件..." -ForegroundColor Yellow

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
    $filePath = Join-Path $workspacePath $file
    if (-not (Test-Path $filePath)) {
        $missingFiles += $file
        Write-Host "  [MISSING] $file" -ForegroundColor Red
    } else {
        Write-Host "  [OK] $file" -ForegroundColor Green
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "[ERROR] 缺失核心文件，无法更新恢复系统" -ForegroundColor Red
    Write-Host "缺失文件：$($missingFiles -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 2. 检查 Git 状态
Write-Host "[2/6] 检查 Git 状态..." -ForegroundColor Yellow

cd $workspacePath
$gitStatus = git status --porcelain

if ($gitStatus) {
    Write-Host "  检测到文件变化：" -ForegroundColor Cyan
    $gitStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
    $hasChanges = $true
} else {
    Write-Host "  没有文件变化" -ForegroundColor Green
    $hasChanges = $false
}

Write-Host ""

# 3. 决定是否需要更新
Write-Host "[3/6] 决定是否需要更新..." -ForegroundColor Yellow

$needsUpdate = $false
$updateReason = ""

if ($Force) {
    $needsUpdate = $true
    $updateReason = "用户强制更新"
    Write-Host "  强制更新模式" -ForegroundColor Cyan
} elseif ($hasChanges) {
    # 检查是否有核心文件变化
    $changedCoreFiles = @()
    foreach ($line in $gitStatus) {
        $fileName = ($line -split '\s+')[1]
        if ($coreFiles -contains $fileName) {
            $changedCoreFiles += $fileName
        }
    }
    
    if ($changedCoreFiles.Count -gt 0) {
        $needsUpdate = $true
        $updateReason = "核心文件变化: $($changedCoreFiles -join ', ')"
        Write-Host "  需要更新：$updateReason" -ForegroundColor Cyan
    } else {
        Write-Host "  核心文件无变化，跳过更新" -ForegroundColor Green
    }
} else {
    Write-Host "  没有变化，跳过更新" -ForegroundColor Green
}

if (-not $needsUpdate) {
    Write-Host ""
    Write-Host "[SKIP] 恢复系统无需更新" -ForegroundColor Green
    exit 0
}

Write-Host ""

# 4. 更新 RECOVERY-VERSION.json
Write-Host "[4/6] 更新版本信息..." -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "  [DRY RUN] 跳过实际更新" -ForegroundColor Yellow
} else {
    $versionFile = Join-Path $workspacePath "RECOVERY-VERSION.json"
    $version = Get-Content $versionFile -Raw | ConvertFrom-Json
    
    # 递增版本号
    $currentVersion = [version]$version.version
    $newVersion = "$($currentVersion.Major).$($currentVersion.Minor + 1)"
    
    # 更新版本信息
    $version.version = $newVersion
    $version.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    $version.updateReason = $updateReason
    
    # 添加到变更日志
    $newChange = @{
        version = $newVersion
        date = (Get-Date).ToString("yyyy-MM-dd")
        changes = @($updateReason)
        author = "虾哥 🦐 (自动更新)"
        tested = $false
    }
    
    $version.changelog = @($newChange) + $version.changelog
    
    # 更新系统状态
    $version.systemStatus.lastRecoveryTest = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    $version.autoUpdate.lastAutoUpdate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    $version.autoUpdate.nextScheduledCheck = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:sszzz")
    
    # 保存
    $version | ConvertTo-Json -Depth 10 | Set-Content $versionFile -Encoding UTF8
    
    Write-Host "  版本号：$currentVersion -> $newVersion" -ForegroundColor Green
    Write-Host "  更新原因：$updateReason" -ForegroundColor Green
}

Write-Host ""

# 5. 更新 SYSTEM-STATE.json
Write-Host "[5/6] 更新系统状态..." -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "  [DRY RUN] 跳过实际更新" -ForegroundColor Yellow
} else {
    $stateFile = Join-Path $workspacePath "SYSTEM-STATE.json"
    if (Test-Path $stateFile) {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        $state.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        $state.recoverySystemVersion = $newVersion
        $state | ConvertTo-Json -Depth 10 | Set-Content $stateFile -Encoding UTF8
        Write-Host "  系统状态已更新" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] SYSTEM-STATE.json 不存在" -ForegroundColor Yellow
    }
}

Write-Host ""

# 6. Git 备份
Write-Host "[6/6] Git 备份..." -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "  [DRY RUN] 跳过 Git 备份" -ForegroundColor Yellow
} else {
    cd $workspacePath
    git add -A
    $commitMessage = "恢复系统自动更新 v$newVersion - $updateReason"
    git commit -m $commitMessage
    
    Write-Host "  已提交：$commitMessage" -ForegroundColor Green
    
    # 尝试推送（如果失败不影响流程）
    try {
        git push origin master
        Write-Host "  已推送到远程仓库" -ForegroundColor Green
    } catch {
        Write-Host "  [WARNING] 推送失败（可能网络问题）" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "恢复系统更新完成！" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

if (-not $DryRun) {
    Write-Host "新版本：$newVersion" -ForegroundColor Cyan
    Write-Host "更新原因：$updateReason" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "建议：测试恢复流程，确保一切正常" -ForegroundColor Yellow
    Write-Host "测试命令：.\scripts\verify-recovery.ps1" -ForegroundColor White
}
