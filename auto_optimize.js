const { chromium } = require('playwright');
const fs = require('fs');

async function autoOptimize() {
    console.log('🚀 连接到浏览器...');
    
    try {
        // 连接到远程调试端口
        const browser = await chromium.connectOverCDP('http://localhost:9222');
        console.log('✅ 已连接到浏览器');
        
        // 获取所有上下文和页面
        const contexts = browser.contexts();
        if (contexts.length === 0) {
            console.log('❌ 没有找到浏览器上下文');
            return;
        }
        
        const context = contexts[0];
        const pages = context.pages();
        
        if (pages.length === 0) {
            console.log('❌ 没有找到打开的页面');
            return;
        }
        
        // 找到 TradingView 页面
        let tvPage = null;
        for (const page of pages) {
            const url = page.url();
            if (url.includes('tradingview.com')) {
                tvPage = page;
                break;
            }
        }
        
        if (!tvPage) {
            console.log('❌ 未找到 TradingView 页面');
            console.log('当前打开的页面：');
            for (const page of pages) {
                console.log('  -', page.url());
            }
            return;
        }
        
        console.log('✅ 找到 TradingView 页面');
        console.log('📍 URL:', tvPage.url());
        
        // 等待页面加载
        await tvPage.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {
            console.log('⚠️  页面未完全加载，继续尝试...');
        });
        
        // 截图确认
        await tvPage.screenshot({ path: 'tradingview_before.png' });
        console.log('📸 已截图：tradingview_before.png');
        
        // 查找编辑器
        console.log('🔍 查找 Pine Editor...');
        
        // 尝试多种选择器
        const editorSelectors = [
            '.monaco-editor textarea',
            '.ace_text-input',
            'textarea[class*="editor"]',
            '[data-name="pine-editor"] textarea',
            '.chart-markup-table textarea'
        ];
        
        let editor = null;
        for (const selector of editorSelectors) {
            try {
                editor = await tvPage.locator(selector).first();
                const count = await editor.count();
                if (count > 0) {
                    console.log('✅ 找到编辑器:', selector);
                    break;
                }
            } catch (e) {
                // 继续尝试下一个
            }
        }
        
        if (!editor || await editor.count() === 0) {
            console.log('❌ 未找到编辑器');
            console.log('请确保 Pine Editor 已打开');
            
            // 保存页面 HTML 用于调试
            const html = await tvPage.content();
            fs.writeFileSync('tradingview_page.html', html);
            console.log('📄 已保存页面 HTML：tradingview_page.html');
            return;
        }
        
        // 读取质量优先型代码
        const code = fs.readFileSync('tradingview_strategy_v11_quality.pine', 'utf8');
        
        console.log('📝 开始替换代码...');
        
        // 聚焦编辑器
        await editor.click();
        await tvPage.waitForTimeout(500);
        
        // 全选
        await tvPage.keyboard.press('Control+A');
        await tvPage.waitForTimeout(300);
        
        // 粘贴新代码
        await tvPage.keyboard.insertText(code);
        await tvPage.waitForTimeout(500);
        
        // 保存
        await tvPage.keyboard.press('Control+S');
        console.log('✅ 代码已保存');
        
        // 等待回测完成
        console.log('⏳ 等待回测完成（30秒）...');
        await tvPage.waitForTimeout(30000);
        
        // 截图结果
        await tvPage.screenshot({ path: 'tradingview_after.png', fullPage: true });
        console.log('📸 已截图：tradingview_after.png');
        
        // 尝试提取回测结果
        console.log('📊 尝试提取回测结果...');
        
        const resultSelectors = [
            '[data-name="backtesting-content"]',
            '.report-data',
            '[class*="performance"]',
            '[class*="backtest"]'
        ];
        
        for (const selector of resultSelectors) {
            try {
                const result = await tvPage.locator(selector).first();
                if (await result.count() > 0) {
                    const text = await result.textContent();
                    console.log('📊 回测结果：');
                    console.log(text);
                    
                    // 保存结果
                    fs.writeFileSync('backtest_result.txt', text);
                    break;
                }
            } catch (e) {
                // 继续尝试
            }
        }
        
        console.log('✅ 自动化完成！');
        console.log('请查看截图：tradingview_after.png');
        
    } catch (error) {
        console.error('❌ 错误：', error.message);
        console.error(error.stack);
    }
}

autoOptimize();
