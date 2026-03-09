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
        
        console.log('📝 使用剪贴板方式替换代码...');
        
        // 方法：通过剪贴板注入（更快更稳定）
        await tvPage.evaluate((newCode) => {
            // 聚焦编辑器
            const textarea = document.querySelector('.monaco-editor textarea');
            if (textarea) {
                textarea.focus();
            }
            
            // 创建临时 textarea 用于复制
            const temp = document.createElement('textarea');
            temp.value = newCode;
            document.body.appendChild(temp);
            temp.select();
            document.execCommand('copy');
            document.body.removeChild(temp);
            
            return true;
        }, code);
        
        console.log('✅ 代码已复制到剪贴板');
        await tvPage.waitForTimeout(500);
        
        // 聚焦编辑器
        await tvPage.evaluate(() => {
            const textarea = document.querySelector('.monaco-editor textarea');
            if (textarea) {
                textarea.focus();
            }
        });
        
        await tvPage.waitForTimeout(300);
        
        // 全选
        console.log('📋 全选...');
        await tvPage.keyboard.press('Control+A');
        await tvPage.waitForTimeout(300);
        
        // 粘贴
        console.log('📋 粘贴...');
        await tvPage.keyboard.press('Control+V');
        await tvPage.waitForTimeout(1000);
        
        // 保存
        console.log('💾 保存...');
        await tvPage.keyboard.press('Control+S');
        
        console.log('✅ 代码已保存');
        
        // 等待回测完成
        console.log('⏳ 等待回测完成（30秒）...');
        await tvPage.waitForTimeout(30000);
        
        // 截图结果
        console.log('📸 截图...');
        await tvPage.screenshot({ path: 'tradingview_quality_result.png', fullPage: true });
        console.log('✅ 已截图：tradingview_quality_result.png');
        
        console.log('');
        console.log('=' .repeat(60));
        console.log('✅ 质量优先型回测完成！');
        console.log('=' .repeat(60));
        console.log('');
        console.log('参数变化：');
        console.log('  • MartinMax: 2 → 0 (完全禁用马丁)');
        console.log('  • MinDisplayScore: 20 → 30 (提高箱体质量)');
        console.log('  • MinVolumeRatio: 0.8 → 1.2 (提高成交量过滤)');
        console.log('  • 止盈止损保持不变 (65% / 32%)');
        console.log('');
        console.log('请查看截图并告诉我回测结果！');
        
    } catch (error) {
        console.error('❌ 错误：', error.message);
        console.error(error.stack);
    }
}

autoOptimize();
