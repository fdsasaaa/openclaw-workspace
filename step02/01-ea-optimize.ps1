#!/usr/bin/env pwsh
<#
EA优化核心脚本：基于Backtrader的参数迭代优化
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# 工作区根目录
$WorkspaceRoot = "C:\OpenClaw_Workspace"

Write-Host "🔄 启动EA参数优化..." -ForegroundColor Cyan

# 生成Backtrader优化模板（保存为py文件）
$optimizePy = @"
import backtrader as bt
import pandas as pd

# 1. 加载行情数据（替换为你的CSV路径）
data = bt.feeds.GenericCSVData(
    dataname='C:\OpenClaw_Workspace\Data\market_data.csv',
    dtformat='%Y-%m-%d %H:%M:%S',
    datetime=0, open=1, high=2, low=3, close=4, volume=5
)

# 2. 定义EA策略（替换为你的策略逻辑）
class EAStrategy(bt.Strategy):
    params = (
        ('ema_period', 20),
        ('rsi_period', 14),
        ('stop_loss', 0.02),
    )

    def __init__(self):
        self.ema = bt.indicators.EMA(self.data.close, period=self.p.ema_period)
        self.rsi = bt.indicators.RSI(self.data.close, period=self.p.rsi_period)

    def next(self):
        if not self.position:
            if self.data.close > self.ema and self.rsi < 30:
                self.buy()
        else:
            if self.data.close < self.ema or self.rsi > 70:
                self.sell()
            # 止损
            if self.data.close < self.position.price * (1 - self.p.stop_loss):
                self.close()

# 3. 初始化回测引擎
cerebro = bt.Cerebro()
cerebro.adddata(data)
cerebro.addstrategy(EAStrategy)

# 4. 参数优化（EMA周期：10-30，RSI周期：10-20）
strats = cerebro.optstrategy(
    EAStrategy,
    ema_period=range(10, 31),
    rsi_period=range(10, 21),
    stop_loss=[0.01, 0.02, 0.03]
)

# 5. 运行优化
cerebro.broker.setcash(100000)
cerebro.broker.setcommission(commission=0.001)  # 手续费
results = cerebro.run()

# 6. 输出最优参数
print("`n📊 优化结果（按收益排序）:")
for res in results:
    for strat in res:
        p = strat.params
        value = cerebro.broker.getvalue()
        print(f"EMA:{p.ema_period} | RSI:{p.rsi_period} | 止损:{p.stop_loss} | 最终资产:{value:.2f}")
"@

# 保存Python优化脚本
$optimizePy | Out-File -Path "$WorkspaceRoot\step02\ea_optimize.py" -Encoding UTF8

# 执行优化
Write-Host "✅ 生成优化脚本: ea_optimize.py" -ForegroundColor Green
Write-Host "🔧 开始执行EA参数优化（耗时可能较长）..." -ForegroundColor Cyan
python "$WorkspaceRoot\step02\ea_optimize.py"

Write-Host "`n🎉 EA优化完成！最优参数已输出到控制台" -ForegroundColor Green