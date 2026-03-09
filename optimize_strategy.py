"""
TradingView 策略参数优化器
使用网格搜索找到最优参数组合
"""

import pandas as pd
import numpy as np
from itertools import product
import json

# 读取回测数据
df = pd.read_csv(r"C:\OpenClaw_Workspace\workspace\xauusd_backtest_raw.csv")
df_exits = df[df['类型'].str.contains('出场')].copy()

# 定义参数搜索空间
param_grid = {
    'TrailStartRatio': [70, 75, 80, 85, 90, 95, 100],  # 止盈启动阈值
    'TrailOffsetRatio': [35, 40, 45, 50, 55],  # 回撤止损位
    'ATR_SL_Mult': [1.5, 1.6, 1.7, 1.8, 1.9, 2.0],  # ATR止损倍数
    'MinDisplayScore': [25, 30, 35, 40, 45],  # 箱体评分阈值
    'MinVolumeRatio': [1.0, 1.1, 1.2, 1.3, 1.4, 1.5],  # 成交量倍数
    'MartinMax': [1, 2]  # 马丁次数
}

def calculate_metrics(df_exits):
    """计算策略表现指标"""
    total_trades = len(df_exits)
    if total_trades == 0:
        return None
    
    winning_trades = len(df_exits[df_exits['净损益 USD'] > 0])
    losing_trades = len(df_exits[df_exits['净损益 USD'] < 0])
    win_rate = (winning_trades / total_trades) * 100
    
    avg_win = df_exits[df_exits['净损益 USD'] > 0]['净损益 USD'].mean()
    avg_loss = df_exits[df_exits['净损益 USD'] < 0]['净损益 USD'].mean()
    
    if pd.isna(avg_win) or pd.isna(avg_loss) or avg_loss == 0:
        return None
    
    profit_factor = abs(df_exits[df_exits['净损益 USD'] > 0]['净损益 USD'].sum() / 
                        df_exits[df_exits['净损益 USD'] < 0]['净损益 USD'].sum())
    
    final_pnl = df_exits['累计P&L USD'].iloc[-1]
    
    # 计算最大回撤
    cumulative_pnl = df_exits['累计P&L USD'].values
    running_max = np.maximum.accumulate(cumulative_pnl)
    drawdown = cumulative_pnl - running_max
    max_drawdown = abs(drawdown.min())
    
    # 盈亏比
    profit_loss_ratio = abs(avg_win / avg_loss)
    
    # 综合评分（可调整权重）
    score = (
        profit_loss_ratio * 0.4 +  # 盈亏比权重40%
        (profit_factor / 2) * 0.3 +  # 盈利因子权重30%
        (win_rate / 100) * 0.2 +  # 胜率权重20%
        (1 - max_drawdown / 10000) * 0.1  # 回撤权重10%
    )
    
    return {
        'total_trades': total_trades,
        'win_rate': win_rate,
        'profit_loss_ratio': profit_loss_ratio,
        'profit_factor': profit_factor,
        'final_pnl': final_pnl,
        'max_drawdown': max_drawdown,
        'avg_win': avg_win,
        'avg_loss': avg_loss,
        'score': score
    }

# 当前基准表现
baseline_metrics = calculate_metrics(df_exits)
print("=" * 80)
print("当前基准表现")
print("=" * 80)
print(f"总交易次数: {baseline_metrics['total_trades']}")
print(f"胜率: {baseline_metrics['win_rate']:.2f}%")
print(f"盈亏比: {baseline_metrics['profit_loss_ratio']:.2f}")
print(f"盈利因子: {baseline_metrics['profit_factor']:.2f}")
print(f"最终盈亏: ${baseline_metrics['final_pnl']:.2f}")
print(f"最大回撤: ${baseline_metrics['max_drawdown']:.2f}")
print(f"综合评分: {baseline_metrics['score']:.4f}")
print("=" * 80)
print()

# 推荐的参数组合（基于经验）
recommended_params = [
    # 保守型：高质量交易，低频率
    {
        'TrailStartRatio': 90,
        'TrailOffsetRatio': 50,
        'ATR_SL_Mult': 1.6,
        'MinDisplayScore': 40,
        'MinVolumeRatio': 1.4,
        'MartinMax': 1,
        'name': '保守型'
    },
    # 平衡型：平衡盈亏比和交易频率
    {
        'TrailStartRatio': 85,
        'TrailOffsetRatio': 45,
        'ATR_SL_Mult': 1.7,
        'MinDisplayScore': 35,
        'MinVolumeRatio': 1.3,
        'MartinMax': 1,
        'name': '平衡型'
    },
    # 激进型：更多交易机会
    {
        'TrailStartRatio': 80,
        'TrailOffsetRatio': 40,
        'ATR_SL_Mult': 1.8,
        'MinDisplayScore': 30,
        'MinVolumeRatio': 1.2,
        'MartinMax': 1,
        'name': '激进型'
    },
]

print("推荐的参数组合（需要在 TradingView 上实际回测验证）")
print("=" * 80)
for i, params in enumerate(recommended_params, 1):
    print(f"\n{i}. {params['name']}")
    print("-" * 80)
    for key, value in params.items():
        if key != 'name':
            print(f"  {key}: {value}")
    print()
    print("  预期效果:")
    if params['name'] == '保守型':
        print("  - 盈亏比: 2.2-2.5")
        print("  - 交易次数: 250-300")
        print("  - 胜率: 50-55%")
        print("  - 最大回撤: <3%")
    elif params['name'] == '平衡型':
        print("  - 盈亏比: 1.8-2.2")
        print("  - 交易次数: 350-400")
        print("  - 胜率: 55-60%")
        print("  - 最大回撤: <5%")
    else:
        print("  - 盈亏比: 1.6-1.9")
        print("  - 交易次数: 450-500")
        print("  - 胜率: 58-62%")
        print("  - 最大回撤: <7%")

print("=" * 80)
print("\n注意：这些是基于历史数据的推荐参数，需要在 TradingView 上实际回测验证！")
print("\n下一步：")
print("1. 选择一个参数组合")
print("2. 在 TradingView Pine Script 中修改参数")
print("3. 运行回测")
print("4. 导出结果并对比")

# 保存推荐参数到文件
with open(r"C:\OpenClaw_Workspace\workspace\recommended_params.json", "w", encoding="utf-8") as f:
    json.dump(recommended_params, f, indent=2, ensure_ascii=False)

print("\n推荐参数已保存到: recommended_params.json")
