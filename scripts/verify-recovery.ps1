# 恢复系统验证脚本
# 功能：验证恢复系统的完整性和可用性
# 使用方法：直接运行

$ErrorActionPreference = "Stop"
$workspacePath = "C:\OpenClaw_Workspace\workspace"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "恢复系统完整性验证" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

# 1. 检查核心文件
Write-Host "[1/5] 检查核心文件..." -ForegroundColor Yellow
Write-Host ""

$coreFiles = @{
    "MASTER-RECOVERY-GUIDE.md" = "主恢复指南"
    "FIRST-RUN.md" = "首次启动指令"
    "RESTORE-COMMAND.md" = "恢复口令"
    "RECOVERY.md" = "恢复协议"
    "IDENTITY.md" = "身份定义"
    "SOUL.md" = "个性和风格"
    "AGENTS.md" = "行为规范"
    "USER.md" = "用户信息"
    "TOOLS.md" = "工具和权限"
    "HEARTBEAT.md" = "心跳任务"
    "MEMORY.md" = "长期记忆"
    "SYSTEM-STATE.json" = "系统状态"
    "RECOVERY-VERSION.json" = "恢复系统版本"
}

$missingFiles = @()
foreach ($file in $coreFiles.Keys) {
    $filePath = Join-Path $workspacePath $file
    if (Test-Path $filePath) {
        $fileSize = (Get-Item $filePath).Length
        Write-Host "  [OK] $file ($fileSize bytes) - $($coreFiles[$file])" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $file - 文件不存在" -ForegroundColor Red
        $missingFiles += $file
        $allPassed = $false
    }
}

Write-Host ""

# 2. 检查记忆文件
Write-Host "[2/5] 检查记忆文件..." -ForegroundColor Yellow
Write-Host ""

$memoryPath = Join-Path $workspacePath "memory"
if (Test-Path $memoryPath) {
    $memoryFiles = Get-ChildItem $memoryPath -Filter "*.md" | Sort-Object LastWriteTime -Descending
    if ($memoryFiles.Count -gt 0) {
        Write-Host "  [OK] 找到 $($memoryFiles.Count) 个记忆文件" -ForegroundColor Green
        Write-Host "  最新记忆：" -ForegroundColor Cyan
        $memoryFiles | Select-Object -First 3 | ForEach-Object {
            Write-Host "    - $($_.Name) ($(Get-Date $_.LastWriteTime -Format 'yyyy-MM-dd HH:mm'))" -ForegroundColor White
        }
    } else {
        Write-Host "  [WARNING] memory/ 目录为空" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [FAIL] memory/ 目录不存在" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""

# 3. 检查 Git 仓库
Write-Host "[3/5] 检查 Git 仓库..." -ForegroundColor Yellow
Write-Host ""

cd $workspacePath
if (Test-Path ".git") {
    Write-Host "  [OK] Git 仓库存在" -ForegroundColor Green
    
    # 检查远程仓库
    $remoteUrl = git config --get remote.origin.url
    if ($remoteUrl) {
        Write-Host "  [OK] 远程仓库：$remoteUrl" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] 未配置远程仓库" -ForegroundColor Yellow
    }
    
    # 检查最后提交
    $lastCommit = git log -1 --pretty=format:"%h - %s (%cr)"
    Write-Host "  最后提交：$lastCommit" -ForegroundColor Cyan
} else {
    Write-Host "  [FAIL] 不是 Git 仓库" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""

# 4. 检查恢复系统版本
Write-Host "[4/5] 检查恢复系统版本..." -ForegroundColor Yellow
Write-Host ""

$versionFile = Join-Path $workspacePath "RECOVERY-VERSION.json"
if (Test-Path $versionFile) {
    $version = Get-Content $versionFile -Raw | ConvertFrom-Json
    
    Write-Host "  [OK] 恢复系统版本：$($version.version)" -ForegroundColor Green
    Write-Host "  最后更新：$($version.lastUpdated)" -ForegroundColor Cyan
    Write-Host "  更新原因：$($version.updateReason)" -ForegroundColor Cyan
    Write-Host "  系统健康：$($version.systemStatus.recoverySystemHealthy)" -ForegroundColor Cyan
    Write-Host "  自动更新：$($version.autoUpdate.enabled)" -ForegroundColor Cyan
    
    # 检查版本号是否合理
    if ($version.version -match '^\d+\.\d+$') {
        Write-Host "  [OK] 版本号格式正确" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] 版本号格式异常：$($version.version)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [FAIL] RECOVERY-VERSION.json 不存在" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""

# 5. 检查恢复口令
Write-Host "[5/5] 检查恢复口令..." -ForegroundColor Yellow
Write-Host ""

$restoreCommandFile = Join-Path $workspacePath "RESTORE-COMMAND.md"
if (Test-Path $restoreCommandFile) {
    $content = Get-Content $restoreCommandFile -Raw
    
    # 检查关键内容
    $checks = @{
        "恢复工作状态" = $content -match "恢复工作状态"
        "RECOVER SYSTEM STATE" = $content -match "RECOVER SYSTEM STATE"
        "立即执行" = $content -match "立即执行"
        "读取核心文件" = $content -match "读取核心文件"
        "汇报恢复状态" = $content -match "汇报恢复状态"
    }
    
    foreach ($check in $checks.Keys) {
        if ($checks[$check]) {
            Write-Host "  [OK] 包含关键内容：$check" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] 缺少关键内容：$check" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  [FAIL] RESTORE-COMMAND.md 不存在" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""

# 总结
Write-Host "==================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "验证通过！恢复系统完整可用 ✅" -ForegroundColor Green
} else {
    Write-Host "验证失败！恢复系统不完整 ❌" -ForegroundColor Red
}
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

if ($missingFiles.Count -gt 0) {
    Write-Host "缺失文件：" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "建议：从 Git 仓库恢复缺失文件" -ForegroundColor Yellow
    Write-Host "命令：git checkout -- [文件名]" -ForegroundColor White
}

Write-Host ""
Write-Host "下一步：" -ForegroundColor Cyan
Write-Host "1. 如果验证通过，可以测试恢复流程" -ForegroundColor White
Write-Host "2. 在飞书发送：读取 workspace\FIRST-RUN.md" -ForegroundColor White
Write-Host "3. 等待虾哥汇报恢复状态" -ForegroundColor White
Write-Host ""

if ($allPassed) {
    exit 0
} else {
    exit 1
}
