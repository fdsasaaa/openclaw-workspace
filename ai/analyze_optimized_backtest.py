"""
分析优化后的回测结果
对比优化前后的表现
"""

import pandas as pd
import json

def analyze_optimized_backtest(csv_path):
    """分析优化后的回测结果"""
    
    # 读取CSV
    df = pd.read_csv(csv_path, encoding='utf-8-sig')
    
    # 筛选出场记录
    exits = df[df['类型'].str.contains('出场', na=False)].copy()
    
    # 基本统计
    total_trades = len(exits)
    winning_trades = len(exits[exits['净损益 USD'] > 0])
    losing_trades = len(exits[exits['净损益 USD'] <= 0])
    
    win_rate = (winning_trades / total_trades * 100) if total_trades > 0 else 0
    
    total_profit = exits['净损益 USD'].sum()
    avg_profit = exits['净损益 USD'].mean()
    
    # 盈利和亏损统计
    wins = exits[exits['净损益 USD'] > 0]['净损益 USD']
    losses = exits[exits['净损益 USD'] <= 0]['净损益 USD']
    
    avg_win = wins.mean() if len(wins) > 0 else 0
    avg_loss = losses.mean() if len(losses) > 0 else 0
    
    profit_factor = abs(wins.sum() / losses.sum()) if losses.sum() != 0 else 0
    
    # 最大回撤
    exits['累计P&L USD'] = exits['净损益 USD'].cumsum()
    exits['最高点'] = exits['累计P&L USD'].cummax()
    exits['回撤'] = exits['累计P&L USD'] - exits['最高点']
    max_drawdown = exits['回撤'].min()
    
    # 时间分布
    exits['时间'] = pd.to_datetime(exits['日期和时间'], format='%Y-%m-%d %H:%M')
    exits['小时'] = exits['时间'].dt.hour
    
    # 按小时统计
    hourly_stats = exits.groupby('小时').agg({
        '净损益 USD': ['count', 'sum', 'mean']
    }).round(2)
    
    # 输出结果
    print("=" * 60)
    print("优化后回测结果分析")
    print("=" * 60)
    
    print(f"\n总交易数: {total_trades}")
    print(f"盈利交易: {winning_trades}")
    print(f"亏损交易: {losing_trades}")
    print(f"胜率: {win_rate:.2f}%")
    print(f"\n总盈亏: ${total_profit:.2f}")
    print(f"平均盈亏: ${avg_profit:.2f}")
    print(f"\n平均盈利: ${avg_win:.2f}")
    print(f"平均亏损: ${avg_loss:.2f}")
    print(f"盈亏比: {profit_factor:.2f}")
    print(f"\n最大回撤: ${max_drawdown:.2f}")
    
    # 时间分布
    print(f"\n交易时间分布:")
    print(f"最早交易: {exits['时间'].min()}")
    print(f"最晚交易: {exits['时间'].max()}")
    
    # 按小时统计（只显示有交易的时段）
    print(f"\n按小时统计（有交易的时段）:")
    for hour in sorted(exits['小时'].unique()):
        hour_data = exits[exits['小时'] == hour]
        hour_count = len(hour_data)
        hour_wins = len(hour_data[hour_data['净损益 USD'] > 0])
        hour_win_rate = (hour_wins / hour_count * 100) if hour_count > 0 else 0
        hour_profit = hour_data['净损益 USD'].sum()
        print(f"  {hour:02d}:00 - 交易数: {hour_count}, 胜率: {hour_win_rate:.1f}%, 盈亏: ${hour_profit:.2f}")
    
    # 对比优化前
    print("\n" + "=" * 60)
    print("对比优化前后")
    print("=" * 60)
    
    # 优化前数据（从之前的分析）
    before_trades = 138
    before_win_rate = 64.49
    before_profit = 1467.97
    
    print(f"\n优化前:")
    print(f"  交易数: {before_trades}")
    print(f"  胜率: {before_win_rate:.2f}%")
    print(f"  总盈利: ${before_profit:.2f}")
    
    print(f"\n优化后:")
    print(f"  交易数: {total_trades}")
    print(f"  胜率: {win_rate:.2f}%")
    print(f"  总盈利: ${total_profit:.2f}")
    
    print(f"\n变化:")
    trade_change = total_trades - before_trades
    trade_change_pct = (trade_change / before_trades * 100) if before_trades > 0 else 0
    win_rate_change = win_rate - before_win_rate
    profit_change = total_profit - before_profit
    profit_change_pct = (profit_change / before_profit * 100) if before_profit > 0 else 0
    
    print(f"  交易数: {trade_change:+d} ({trade_change_pct:+.1f}%)")
    print(f"  胜率: {win_rate_change:+.2f}%")
    print(f"  总盈利: ${profit_change:+.2f} ({profit_change_pct:+.1f}%)")
    
    # 评估优化效果
    print("\n" + "=" * 60)
    print("优化效果评估")
    print("=" * 60)
    
    if win_rate > before_win_rate and total_profit > before_profit:
        print("\n✅ 优化成功！")
        print(f"  - 胜率提升 {win_rate_change:.2f}%")
        print(f"  - 盈利提升 ${profit_change:.2f}")
        print(f"  - 交易数量减少 {abs(trade_change)} 笔（过滤掉低质量信号）")
    elif win_rate > before_win_rate:
        print("\n⚠️ 部分成功")
        print(f"  - 胜率提升 {win_rate_change:.2f}%")
        print(f"  - 但盈利下降 ${abs(profit_change):.2f}")
        print(f"  - 可能过滤掉了一些大盈利交易")
    else:
        print("\n❌ 优化效果不佳")
        print(f"  - 胜率下降 {abs(win_rate_change):.2f}%")
        print(f"  - 盈利下降 ${abs(profit_change):.2f}")
        print(f"  - 需要重新调整参数")
    
    # 保存结果
    result = {
        'optimized': {
            'total_trades': int(total_trades),
            'winning_trades': int(winning_trades),
            'losing_trades': int(losing_trades),
            'win_rate': float(win_rate),
            'total_profit': float(total_profit),
            'avg_profit': float(avg_profit),
            'avg_win': float(avg_win),
            'avg_loss': float(avg_loss),
            'profit_factor': float(profit_factor),
            'max_drawdown': float(max_drawdown)
        },
        'before': {
            'total_trades': before_trades,
            'win_rate': before_win_rate,
            'total_profit': before_profit
        },
        'changes': {
            'trade_change': int(trade_change),
            'trade_change_pct': float(trade_change_pct),
            'win_rate_change': float(win_rate_change),
            'profit_change': float(profit_change),
            'profit_change_pct': float(profit_change_pct)
        }
    }
    
    with open('optimized_backtest_analysis.json', 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    
    print("\n结果已保存到: optimized_backtest_analysis.json")
    
    return result

if __name__ == "__main__":
    csv_path = r"C:\OpenClaw_Workspace\workspace\ai\能量块V11_全自动策略]_ICMARKETS_XAUUSD_2026-03-12.csv"
    analyze_optimized_backtest(csv_path)
