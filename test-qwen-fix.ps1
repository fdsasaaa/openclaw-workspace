Write-Host "测试Qwen的JSON输出格式..." -ForegroundColor Yellow
Write-Host ""

cd C:\OpenClaw_Workspace\workspace

# 设置环境变量，添加格式约束
$env:MIDSCENE_SYSTEM_PROMPT = @"
### 格式强制要求 ###
1. 所有返回结果中，JSON 数据必须使用 **纯英文双引号（"）**，严禁使用中文引号（""）、中文单引号（''）；
2. JSON 必须是标准可解析格式，无多余换行、注释、无关文字；
3. 若需要返回操作指令，仅返回 JSON 字符串，不添加任何解释、说明、标点符号；
4. 示例正确格式：{"action":"click","x":100,"y":200}，错误格式：{"action":"click","x":100,"y":200}。
"@

Write-Host "✓ 已设置格式约束Prompt" -ForegroundColor Green
Write-Host ""
Write-Host "现在测试简单操作..." -ForegroundColor White

# 测试简单操作
npx @midscene/computer@1 act --prompt "Click MT4 window" 2>&1
