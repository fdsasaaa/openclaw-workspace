const { chromium } = require('playwright');
const fs = require('fs');

async function autoOptimizeWithCoordinates() {
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
        await tvPage.waitForTimeout(3000);
        
        console.log('✅ 代码已保存');
        
        // 截图查看当前状态
        await tvPage.screenshot({ path: 'before_refresh.png', fullPage: true });
        console.log('📸 已截图：before_refresh.png');
        
        // 方法2：通过页面内部查找所有按钮
        console.log('🔍 通过 DOM 查找刷新按钮...');
        
        const refreshButtonInfo = await tvPage.evaluate(() => {
            // 查找所有可能的刷新按钮
            const buttons = Array.from(document.querySelectorAll('button'));
            
            for (const btn of buttons) {
                const text = btn.textContent || '';
                const title = btn.getAttribute('title') || '';
                const ariaLabel = btn.getAttribute('aria-label') || '';
                const dataName = btn.getAttribute('data-name') || '';
                
                // 检查是否包含"刷新"相关文字
                if (text.includes('刷新') || text.includes('Refresh') ||
                    title.includes('刷新') || title.includes('Refresh') ||
                    ariaLabel.includes('刷新') || ariaLabel.includes('Refresh') ||
                    dataName.includes('refresh')) {
                    
                    const rect = btn.getBoundingClientRect();
                    return {
                        found: true,
                        x: rect.x + rect.width / 2,
                        y: rect.y + rect.height / 2,
                        text: text,
                        title: title,
                        ariaLabel: ariaLabel,
                        dataName: dataName,
                        disabled: btn.disabled,
                        className: btn.className
                    };
                }
            }
            
            return { found: false };
        });
        
        if (refreshButtonInfo.found) {
            console.log('✅ 找到刷新按钮！');
            console.log('   位置:', refreshButtonInfo.x, refreshButtonInfo.y);
            console.log('   标题:', refreshButtonInfo.title);
            console.log('   状态:', refreshButtonInfo.disabled ? '禁用（灰色）' : '启用（白色）');
            
            if (refreshButtonInfo.disabled) {
                console.log('⚠️  刷新按钮是灰色的，说明代码未修改');
                console.log('可能原因：');
                console.log('  1. 代码替换失败');
                console.log('  2. 新代码和旧代码完全一样');
                return;
            }
            
            // 点击刷新按钮
            console.log('🔄 点击刷新按钮...');
            await tvPage.mouse.click(refreshButtonInfo.x, refreshButtonInfo.y);
            
            console.log('⏳ 等待策略加载（30秒）...');
            await tvPage.waitForTimeout(30000);
            
            // 截图结果
            await tvPage.screenshot({ path: 'after_refresh.png', fullPage: true });
            console.log('📸 已截图：after_refresh.png');
            
            console.log('');
            console.log('✅ 完整闭环测试完成！');
            console.log('请查看截图并告诉我盈利因子是否超过 1.889');
            
        } else {
            console.log('❌ 未找到刷新按钮');
            console.log('请手动点击刷新按钮，或告诉我按钮的具体位置');
        }
        
    } catch (error) {
        console.error('❌ 错误：', error.message);
        console.error(error.stack);
    }
}

autoOptimizeWithCoordinates();
