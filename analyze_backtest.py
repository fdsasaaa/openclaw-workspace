import pandas as pd
import numpy as np

# 读取数据
df = pd.read_csv(r"C:\OpenClaw_Workspace\workspace\xauusd_backtest_raw.csv")

# 只保留出场记录（每笔交易的结果）
df_exits = df[df['类型'].str.contains('出场')].copy()

# 基本统计
total_trades = len(df_exits)
winning_trades = len(df_exits[df_exits['净损益 USD'] > 0])
losing_trades = len(df_exits[df_exits['净损益 USD'] < 0])
win_rate = (winning_trades / total_trades) * 100

# 盈亏统计
avg_win = df_exits[df_exits['净损益 USD'] > 0]['净损益 USD'].mean()
avg_loss = df_exits[df_exits['净损益 USD'] < 0]['净损益 USD'].mean()
profit_factor = abs(df_exits[df_exits['净损益 USD'] > 0]['净损益 USD'].sum() / 
                    df_exits[df_exits['净损益 USD'] < 0]['净损益 USD'].sum())

# 最终收益
final_pnl = df_exits['累计P&L USD'].iloc[-1]
final_return = df_exits['累计P&L %'].iloc[-1]

# 最大回撤
cumulative_pnl = df_exits['累计P&L USD'].values
running_max = np.maximum.accumulate(cumulative_pnl)
drawdown = cumulative_pnl - running_max
max_drawdown = abs(drawdown.min())
max_drawdown_pct = (max_drawdown / 1000000) * 100

# 连续亏损
df_exits['is_loss'] = df_exits['净损益 USD'] < 0
consecutive_losses = []
current_streak = 0
for is_loss in df_exits['is_loss']:
    if is_loss:
        current_streak += 1
    else:
        if current_streak > 0:
            consecutive_losses.append(current_streak)
        current_streak = 0
max_consecutive_losses = max(consecutive_losses) if consecutive_losses else 0

# 输出报告
print("=" * 60)
print("XAUUSD 回测分析报告 (2022-01-05 至 2026-03-09)")
print("=" * 60)
print(f"总交易次数: {total_trades}")
print(f"盈利交易: {winning_trades} ({win_rate:.2f}%)")
print(f"亏损交易: {losing_trades} ({100-win_rate:.2f}%)")
print(f"")
print(f"最终盈亏: ${final_pnl:.2f} USD ({final_return:.2f}%)")
print(f"平均盈利: ${avg_win:.2f} USD")
print(f"平均亏损: ${avg_loss:.2f} USD")
print(f"盈亏比: {abs(avg_win/avg_loss):.2f}")
print(f"盈利因子: {profit_factor:.2f}")
print(f"")
print(f"最大回撤: ${max_drawdown:.2f} USD ({max_drawdown_pct:.2f}%)")
print(f"最大连续亏损: {max_consecutive_losses} 笔")
print("=" * 60)

# 保存详细分析
with open(r"C:\OpenClaw_Workspace\workspace\xauusd_analysis.txt", "w", encoding="utf-8") as f:
    f.write(f"XAUUSD 回测分析报告\n")
    f.write(f"=" * 60 + "\n")
    f.write(f"总交易次数: {total_trades}\n")
    f.write(f"胜率: {win_rate:.2f}%\n")
    f.write(f"最终收益: ${final_pnl:.2f} ({final_return:.2f}%)\n")
    f.write(f"盈亏比: {abs(avg_win/avg_loss):.2f}\n")
    f.write(f"盈利因子: {profit_factor:.2f}\n")
    f.write(f"最大回撤: ${max_drawdown:.2f} ({max_drawdown_pct:.2f}%)\n")
    f.write(f"最大连续亏损: {max_consecutive_losses} 笔\n")

print("\n分析报告已保存到: C:\\OpenClaw_Workspace\\workspace\\xauusd_analysis.txt")
