const { chromium } = require('playwright');
const fs = require('fs');

async function autoOptimizeWithRefresh() {
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
        
        console.log('📝 替换代码...');
        
        // 通过剪贴板注入
        await tvPage.evaluate((newCode) => {
            const textarea = document.querySelector('.monaco-editor textarea');
            if (textarea) textarea.focus();
            
            const temp = document.createElement('textarea');
            temp.value = newCode;
            document.body.appendChild(temp);
            temp.select();
            document.execCommand('copy');
            document.body.removeChild(temp);
        }, code);
        
        await tvPage.waitForTimeout(500);
        
        // 聚焦编辑器
        await tvPage.evaluate(() => {
            const textarea = document.querySelector('.monaco-editor textarea');
            if (textarea) textarea.focus();
        });
        
        await tvPage.waitForTimeout(300);
        
        // 全选 + 粘贴
        await tvPage.keyboard.press('Control+A');
        await tvPage.waitForTimeout(300);
        await tvPage.keyboard.press('Control+V');
        await tvPage.waitForTimeout(1000);
        
        // 保存
        console.log('💾 保存...');
        await tvPage.keyboard.press('Control+S');
        await tvPage.waitForTimeout(2000);
        
        console.log('✅ 代码已保存');
        
        // 🔑 关键步骤：查找并点击刷新按钮
        console.log('🔍 查找刷新按钮...');
        
        // 尝试多种选择器
        const refreshSelectors = [
            'button[data-name="refresh"]',
            'button[title*="刷新"]',
            'button[title*="Refresh"]',
            'button[aria-label*="刷新"]',
            'button[aria-label*="Refresh"]',
            '[data-name="refresh-button"]',
            'button.refresh-button',
            'button svg[data-icon="refresh"]'
        ];
        
        let refreshButton = null;
        for (const selector of refreshSelectors) {
            try {
                const btn = tvPage.locator(selector);
                const count = await btn.count();
                if (count > 0) {
                    refreshButton = btn.first();
                    console.log('✅ 找到刷新按钮:', selector);
                    break;
                }
            } catch (e) {
                // 继续尝试
            }
        }
        
        if (!refreshButton) {
            console.log('⚠️  未找到刷新按钮，尝试通过截图定位...');
            await tvPage.screenshot({ path: 'find_refresh_button.png', fullPage: true });
            console.log('📸 已截图：find_refresh_button.png');
            console.log('请手动点击刷新按钮，或告诉我按钮的位置');
            return;
        }
        
        // 检查按钮是否可点击（是否变白）
        const isEnabled = await refreshButton.isEnabled();
        console.log('🔍 刷新按钮状态:', isEnabled ? '可点击（白色）' : '不可点击（灰色）');
        
        if (!isEnabled) {
            console.log('⚠️  刷新按钮未激活，说明代码未修改或未保存成功');
            return;
        }
        
        // 点击刷新按钮
        console.log('🔄 点击刷新按钮...');
        await refreshButton.click();
        
        console.log('⏳ 等待策略加载到K线（30秒）...');
        await tvPage.waitForTimeout(30000);
        
        // 截图回测结果
        console.log('📸 截图回测结果...');
        await tvPage.screenshot({ path: 'backtest_result_quality.png', fullPage: true });
        console.log('✅ 已截图：backtest_result_quality.png');
        
        // 尝试提取回测数据
        console.log('📊 尝试提取回测数据...');
        
        const resultSelectors = [
            '[data-name="backtesting-content"]',
            '.report-data',
            '[class*="performance"]',
            '[class*="backtest"]',
            '[class*="strategy-report"]'
        ];
        
        let resultText = '';
        for (const selector of resultSelectors) {
            try {
                const result = tvPage.locator(selector);
                const count = await result.count();
                if (count > 0) {
                    resultText = await result.first().textContent();
                    break;
                }
            } catch (e) {
                // 继续尝试
            }
        }
        
        if (resultText) {
            console.log('📊 回测结果：');
            console.log(resultText);
            
            // 保存结果
            fs.writeFileSync('backtest_result_quality.txt', resultText);
            
            // 尝试提取盈利因子
            const profitFactorMatch = resultText.match(/盈利因子|Profit Factor[:\s]+([0-9.]+)/i);
            if (profitFactorMatch) {
                const profitFactor = parseFloat(profitFactorMatch[1]);
                console.log('');
                console.log('=' .repeat(60));
                console.log(`🎯 盈利因子: ${profitFactor}`);
                console.log(`📊 目标: 1.889`);
                console.log(`${profitFactor > 1.889 ? '✅ 超越目标！' : '❌ 未达到目标'}`);
                console.log('=' .repeat(60));
            }
        } else {
            console.log('⚠️  未能自动提取回测数据');
            console.log('请查看截图：backtest_result_quality.png');
        }
        
        console.log('');
        console.log('✅ 完整闭环测试完成！');
        
    } catch (error) {
        console.error('❌ 错误：', error.message);
        console.error(error.stack);
    }
}

autoOptimizeWithRefresh();
