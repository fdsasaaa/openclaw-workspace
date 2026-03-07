# check-consistency.ps1
# 检查 TASKS.md 和 PROJECT.md 的一致性（最小版本）
# 只检查：TASKS.md 第一个高优先级任务 vs PROJECT.md 第一个下一步行动

# UTF-8 编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=== 状态一致性检查 ===" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\OpenClaw_Workspace\workspace"
$tasksPath = Join-Path $workspaceRoot "TASKS.md"
$projectPath = Join-Path $workspaceRoot "PROJECT.md"

# 检查文件是否存在
if (-not (Test-Path $tasksPath)) {
    Write-Host "❌ 错误: TASKS.md 不存在" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $projectPath)) {
    Write-Host "❌ 错误: PROJECT.md 不存在" -ForegroundColor Red
    exit 1
}

# 读取 TASKS.md 的第一个高优先级任务
Write-Host "读取 TASKS.md..." -ForegroundColor Yellow
$tasksContent = Get-Content $tasksPath -Encoding UTF8 -Raw

if ($tasksContent -match '## 🔴 高优先级任务\s+### 视频自动化系统\s+- \[ \] \*\*(.+?)\*\*') {
    $tasksFirstTask = $matches[1]
    Write-Host "✅ TASKS.md 第一个高优先级任务:" -ForegroundColor Green
    Write-Host "   $tasksFirstTask" -ForegroundColor White
} else {
    Write-Host "❌ 错误: 无法解析 TASKS.md 的高优先级任务" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 读取 PROJECT.md 的第一个下一步行动
Write-Host "读取 PROJECT.md..." -ForegroundColor Yellow
$projectContent = Get-Content $projectPath -Encoding UTF8 -Raw

if ($projectContent -match '### 立即执行（本周）\s+1\. \*\*(.+?)\*\*') {
    $projectFirstAction = $matches[1]
    Write-Host "✅ PROJECT.md 第一个下一步行动:" -ForegroundColor Green
    Write-Host "   $projectFirstAction" -ForegroundColor White
} else {
    Write-Host "❌ 错误: 无法解析 PROJECT.md 的下一步行动" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== 一致性检查结果 ===" -ForegroundColor Cyan
Write-Host ""

# 对比是否一致
if ($tasksFirstTask -eq $projectFirstAction) {
    Write-Host "✅ 一致性检查通过" -ForegroundColor Green
    Write-Host ""
    Write-Host "两个文件的'下一步最优动作'完全一致：" -ForegroundColor White
    Write-Host "  $tasksFirstTask" -ForegroundColor Cyan
    Write-Host ""
    exit 0
} else {
    Write-Host "❌ 一致性检查失败" -ForegroundColor Red
    Write-Host ""
    Write-Host "两个文件的'下一步最优动作'不一致：" -ForegroundColor White
    Write-Host ""
    Write-Host "TASKS.md (主):" -ForegroundColor Yellow
    Write-Host "  $tasksFirstTask" -ForegroundColor White
    Write-Host ""
    Write-Host "PROJECT.md (从):" -ForegroundColor Yellow
    Write-Host "  $projectFirstAction" -ForegroundColor White
    Write-Host ""
    Write-Host "=== 修复建议 ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "根据主从关系，应该以 TASKS.md 为准。" -ForegroundColor White
    Write-Host "请更新 PROJECT.md 的'下一步行动'第1项为：" -ForegroundColor White
    Write-Host "  $tasksFirstTask" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "修复命令：" -ForegroundColor Yellow
    Write-Host "  1. 打开 PROJECT.md" -ForegroundColor Gray
    Write-Host "  2. 找到'### 立即执行（本周）'章节" -ForegroundColor Gray
    Write-Host "  3. 将第1项改为: **$tasksFirstTask**" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
