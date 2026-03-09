# 启动百分浏览器（带远程调试端口）
Start-Process "C:\Users\ME\AppData\Local\CentBrowser\Application\chrome.exe" -ArgumentList "--remote-debugging-port=9222"

Write-Host "✅ 百分浏览器已启动（远程调试端口：9222）"
Write-Host ""
Write-Host "现在可以用 Playwright 连接了："
Write-Host "  const browser = await chromium.connectOverCDP('http://localhost:9222');"
