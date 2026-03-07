# test-monitor-fix.ps1
# 测试 Monitor 修复是否有效

# UTF-8 编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=== 测试 Monitor 修复 ===" -ForegroundColor Cyan
Write-Host ""

# 1. 测试 Node 路径
Write-Host "1. 测试 Node.js 路径..." -ForegroundColor Yellow
$nodePath = "C:\Program Files\nodejs\node.exe"
if (Test-Path $nodePath) {
    Write-Host "✅ Node.js 存在: $nodePath" -ForegroundColor Green
    $nodeVersion = & $nodePath --version
    Write-Host "   版本: $nodeVersion" -ForegroundColor White
} else {
    Write-Host "❌ Node.js 不存在: $nodePath" -ForegroundColor Red
}
Write-Host ""

# 2. 测试 OpenClaw 路径
Write-Host "2. 测试 OpenClaw 路径..." -ForegroundColor Yellow
$openclawMjs = "C:\Users\ME\AppData\Roaming\npm\node_modules\openclaw\openclaw.mjs"
if (Test-Path $openclawMjs) {
    Write-Host "✅ OpenClaw 存在: $openclawMjs" -ForegroundColor Green
} else {
    Write-Host "❌ OpenClaw 不存在: $openclawMjs" -ForegroundColor Red
}
Write-Host ""

# 3. 测试启动命令
Write-Host "3. 测试启动命令..." -ForegroundColor Yellow
Write-Host "命令: node openclaw.mjs gateway status" -ForegroundColor Gray

try {
    $result = & $nodePath $openclawMjs gateway status 2>&1
    Write-Host "✅ 命令执行成功" -ForegroundColor Green
    Write-Host "输出:" -ForegroundColor White
    $result | Select-Object -First 10
} catch {
    Write-Host "❌ 命令执行失败: $_" -ForegroundColor Red
}
Write-Host ""

# 4. 检查当前 Monitor 状态
Write-Host "4. 当前 Monitor 状态..." -ForegroundColor Yellow
$monitorProcess = Get-Process -Name "pwsh" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CommandLine -like "*gateway-monitor*" }
if ($monitorProcess) {
    Write-Host "✅ Monitor 运行中 (PID: $($monitorProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "❌ Monitor 未运行" -ForegroundColor Red
}
Write-Host ""

# 5. 检查网关状态
Write-Host "5. 网关状态..." -ForegroundColor Yellow
$gatewayProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CommandLine -like "*openclaw*" }
if ($gatewayProcess) {
    Write-Host "✅ 网关运行中 (PID: $($gatewayProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "❌ 网关未运行" -ForegroundColor Red
}
Write-Host ""

# 6. 建议
Write-Host "=== 建议 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Monitor 脚本已修复，但当前运行的是旧版本。" -ForegroundColor Yellow
Write-Host ""
Write-Host "要应用修复，请执行以下操作之一：" -ForegroundColor White
Write-Host "  1. 重启电脑（推荐）" -ForegroundColor Gray
Write-Host "  2. 手动重启 Monitor 任务" -ForegroundColor Gray
Write-Host ""
Write-Host "下次网关崩溃时，Monitor 将能够自动重启网关。" -ForegroundColor Green
