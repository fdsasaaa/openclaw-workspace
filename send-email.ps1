# 发送邮件脚本
# 使用方法：配置 Gmail 应用专用密码后运行

param(
    [string]$GmailAppPassword = ""  # Gmail 应用专用密码
)

# 如果没有提供密码，提示用户
if ([string]::IsNullOrEmpty($GmailAppPassword)) {
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "Gmail 邮件发送配置" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "需要 Gmail 应用专用密码才能发送邮件。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "获取步骤：" -ForegroundColor White
    Write-Host "1. 访问：https://myaccount.google.com/apppasswords" -ForegroundColor Gray
    Write-Host "2. 登录你的 Google 账号" -ForegroundColor Gray
    Write-Host "3. 选择'邮件'和'Windows 电脑'" -ForegroundColor Gray
    Write-Host "4. 点击'生成'" -ForegroundColor Gray
    Write-Host "5. 复制生成的 16 位密码（格式：xxxx xxxx xxxx xxxx）" -ForegroundColor Gray
    Write-Host ""
    
    $GmailAppPassword = Read-Host "请输入 Gmail 应用专用密码（16位，可以有空格）"
    
    if ([string]::IsNullOrEmpty($GmailAppPassword)) {
        Write-Host "❌ 未提供密码，退出。" -ForegroundColor Red
        exit 1
    }
}

# 移除空格
$GmailAppPassword = $GmailAppPassword -replace '\s', ''

# 邮件配置
$From = "fdsasaaa@gmail.com"  # 发件人（你的 Gmail）
$To = "fdsasaaa@gmail.com"    # 收件人（你的 Gmail）
$Subject = "🦐 虾哥完整恢复指南 - 重要备份 ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
$SMTPServer = "smtp.gmail.com"
$SMTPPort = 587

# 读取邮件内容
$emailContent = Get-Content C:\OpenClaw_Workspace\workspace\EMAIL-BACKUP.md -Raw -Encoding UTF8

Write-Host ""
Write-Host "正在发送邮件..." -ForegroundColor Cyan
Write-Host "发件人：$From" -ForegroundColor White
Write-Host "收件人：$To" -ForegroundColor White
Write-Host "主题：$Subject" -ForegroundColor White
Write-Host ""

try {
    # 创建凭据
    $SecurePassword = ConvertTo-SecureString $GmailAppPassword -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($From, $SecurePassword)
    
    # 发送邮件
    Send-MailMessage `
        -From $From `
        -To $To `
        -Subject $Subject `
        -Body $emailContent `
        -SmtpServer $SMTPServer `
        -Port $SMTPPort `
        -UseSsl `
        -Credential $Credential `
        -Encoding UTF8
    
    Write-Host "✅ 邮件发送成功！" -ForegroundColor Green
    Write-Host ""
    Write-Host "请检查你的邮箱：$To" -ForegroundColor White
    
} catch {
    Write-Host "❌ 邮件发送失败：$($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "常见问题：" -ForegroundColor Yellow
    Write-Host "1. 应用专用密码是否正确？" -ForegroundColor Gray
    Write-Host "2. Gmail 账号是否开启了两步验证？（必须开启）" -ForegroundColor Gray
    Write-Host "3. 网络是否正常？" -ForegroundColor Gray
    Write-Host "4. 是否能访问 Gmail？" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
