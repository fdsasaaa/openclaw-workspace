const { chromium } = require('playwright');
const fs = require('fs');

async function autoOptimize() {
    console.log('🚀 连接到浏览器...');
    
    try {
        const browser = await chromium.connectOverCDP('http://localhost:9222');
        console.log('✅ 已连接到浏览器');
        
        const contexts = browser.contexts();
        const context = contexts[0];
        const pages = context.pages();
        
        let tvPage = null;
        for (const page of pages) {
            if (page.url().includes('tradingview.com')) {
                tvPage = page;
                break;
            }
        }
        
        if (!tvPage) {
            console.log('❌ 未找到 TradingView 页面');
            return;
        }
        
        console.log('✅ 找到 TradingView 页面');
        
        // 读取质量优先型代码
        const code = fs.readFileSync('tradingview_strategy_v11_quality.pine', 'utf8');
        
        console.log('📝 开始替换代码...');
        
        // 方法1：直接用 JavaScript 聚焦编辑器
        await tvPage.evaluate(() => {
            const textarea = document.querySelector('.monaco-editor textarea');
            if (textarea) {
                textarea.focus();
                return true;
            }
            return false;
        });
        
        console.log('✅ 已聚焦编辑器');
        await tvPage.waitForTimeout(500);
        
        // 全选
        await tvPage.keyboard.press('Control+A');
        await tvPage.waitForTimeout(300);
        
        // 删除
        await tvPage.keyboard.press('Delete');
        await tvPage.waitForTimeout(300);
        
        // 输入新代码
        console.log('⌨️  输入新代码...');
        await tvPage.keyboard.type(code, { delay: 0 });
        await tvPage.waitForTimeout(500);
        
        // 保存
        console.log('💾 保存...');
        await tvPage.keyboard.press('Control+S');
        
        console.log('✅ 代码已保存');
        
        // 等待回测完成
        console.log('⏳ 等待回测完成（30秒）...');
        await tvPage.waitForTimeout(30000);
        
        // 截图结果
        await tvPage.screenshot({ path: 'tradingview_result.png', fullPage: true });
        console.log('📸 已截图：tradingview_result.png');
        
        console.log('✅ 自动化完成！');
        console.log('');
        console.log('请查看截图并告诉我回测结果：');
        console.log('  • 盈亏比（Profit Factor）');
        console.log('  • 交易次数（Total Trades）');
        console.log('  • 胜率（Win Rate %）');
        console.log('  • 最大回撤（Max Drawdown）');
        
    } catch (error) {
        console.error('❌ 错误：', error.message);
    }
}

autoOptimize();
