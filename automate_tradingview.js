const { chromium } = require('playwright');
const fs = require('fs');

async function automateTradingView() {
    console.log('🚀 启动浏览器自动化...');
    
    // 读取优化后的代码
    const code = fs.readFileSync('tradingview_strategy_v11_aggressive.pine', 'utf8');
    
    // 启动浏览器（连接到已打开的百分浏览器）
    const browser = await chromium.launch({
        headless: false,
        executablePath: 'C:\\Users\\ME\\AppData\\Local\\CentBrowser\\Application\\chrome.exe',
        args: ['--remote-debugging-port=9222']
    });
    
    const context = await browser.newContext();
    const page = await context.newPage();
    
    // 等待用户手动打开 TradingView 页面
    console.log('⏳ 请在浏览器中打开 TradingView Pine Editor 页面...');
    console.log('   然后按回车继续...');
    
    // 等待 30 秒让用户准备
    await new Promise(resolve => setTimeout(resolve, 30000));
    
    console.log('📝 开始自动化操作...');
    
    try {
        // 查找 Pine Editor 的代码编辑区域
        const editor = await page.locator('.monaco-editor, .ace_editor, textarea[class*="editor"]').first();
        
        if (editor) {
            console.log('✅ 找到编辑器');
            
            // 点击编辑器
            await editor.click();
            await page.waitForTimeout(500);
            
            // 全选
            await page.keyboard.press('Control+A');
            await page.waitForTimeout(300);
            
            // 粘贴新代码
            await page.keyboard.insertText(code);
            await page.waitForTimeout(500);
            
            // 保存
            await page.keyboard.press('Control+S');
            
            console.log('✅ 代码已更新并保存！');
            console.log('⏳ 等待回测完成...');
            
            // 等待 10 秒让回测运行
            await page.waitForTimeout(10000);
            
            // 尝试读取回测结果
            const results = await page.locator('[class*="report"], [class*="performance"]').first().textContent();
            console.log('📊 回测结果：');
            console.log(results);
            
        } else {
            console.log('❌ 未找到编辑器，请确保 TradingView Pine Editor 已打开');
        }
        
    } catch (error) {
        console.error('❌ 错误：', error.message);
    }
    
    console.log('✅ 自动化完成！');
    await browser.close();
}

automateTradingView().catch(console.error);
