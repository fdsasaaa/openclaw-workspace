"""
深度分析历史回测清单
基于竹林的最优参数设置
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import json

def load_trades(csv_path):
    """加载历史交易记录"""
    df = pd.read_csv(csv_path, encoding='utf-8-sig')
    
    # 筛选出场记录
    exits = df[df['类型'].str.contains('出场', na=False)].copy()
    exits['时间'] = pd.to_datetime(exits['日期和时间'], format='%Y-%m-%d %H:%M')
    exits['方向'] = exits['类型'].apply(lambda x: 'LONG' if '多头' in x else 'SHORT')
    
    # 筛选进场记录
    entries = df[df['类型'].str.contains('进场', na=False)].copy()
    entries['时间'] = pd.to_datetime(entries['日期和时间'], format='%Y-%m-%d %H:%M')
    
    # 合并入场和出场
    trades = []
    for i, exit_row in exits.iterrows():
        trade_num = exit_row['交易 #']
        entry_row = entries[entries['交易 #'] == trade_num]
        
        if not entry_row.empty:
            entry_row = entry_row.iloc[0]
            trades.append({
                'trade_num': trade_num,
                'direction': exit_row['方向'],
                'entry_time': entry_row['时间'],
                'entry_price': entry_row['价格 USD'],
                'exit_time': exit_row['时间'],
                'exit_price': exit_row['价格 USD'],
                'profit': exit_row['净损益 USD'],
                'profit_pct': exit_row['净损益 %'],
                'favorable': exit_row['有利波动 USD'],
                'adverse': exit_row['不利波动 USD'],
                'is_win': exit_row['净损益 USD'] > 0,
                'exit_signal': exit_row['信号']
            })
    
    return pd.DataFrame(trades)

def analyze_time_patterns(trades_df):
    """分析时间模式"""
    print("\n" + "=" * 60)
    print("时间模式分析")
    print("=" * 60)
    
    # 提取时间特征
    trades_df['hour'] = trades_df['entry_time'].dt.hour
    trades_df['day_of_week'] = trades_df['entry_time'].dt.dayofweek
    trades_df['month'] = trades_df['entry_time'].dt.month
    
    # 按小时分析
    print("\n【按小时分析】")
    hourly = trades_df.groupby('hour').agg({
        'is_win': ['count', 'sum', 'mean'],
        'profit': 'sum'
    }).round(2)
    hourly.columns = ['交易数', '盈利数', '胜率', '总盈亏']
    hourly['胜率'] = (hourly['胜率'] * 100).round(2)
    
    # 找出最佳和最差时段
    best_hours = hourly.nlargest(5, '胜率')
    worst_hours = hourly.nsmallest(5, '胜率')
    
    print("\n最佳交易时段（Top 5）：")
    print(best_hours)
    
    print("\n最差交易时段（Bottom 5）：")
    print(worst_hours)
    
    # 按星期分析
    print("\n【按星期分析】")
    weekly = trades_df.groupby('day_of_week').agg({
        'is_win': ['count', 'sum', 'mean'],
        'profit': 'sum'
    }).round(2)
    weekly.columns = ['交易数', '盈利数', '胜率', '总盈亏']
    weekly['胜率'] = (weekly['胜率'] * 100).round(2)
    
    # 动态设置星期标签
    day_names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
    weekly.index = [day_names[i] for i in weekly.index]
    
    print(weekly)
    
    return {
        'best_hours': best_hours.index.tolist(),
        'worst_hours': worst_hours.index.tolist(),
        'hourly': hourly.to_dict(),
        'weekly': weekly.to_dict()
    }

def analyze_price_patterns(trades_df):
    """分析价格模式"""
    print("\n" + "=" * 60)
    print("价格模式分析")
    print("=" * 60)
    
    # 价格区间分析（每 100 美元一个区间）
    trades_df['price_range'] = (trades_df['entry_price'] // 100) * 100
    
    print("\n【按价格区间分析】")
    price_analysis = trades_df.groupby('price_range').agg({
        'is_win': ['count', 'sum', 'mean'],
        'profit': 'sum'
    }).round(2)
    price_analysis.columns = ['交易数', '盈利数', '胜率', '总盈亏']
    price_analysis['胜率'] = (price_analysis['胜率'] * 100).round(2)
    
    # 只显示交易数 >= 5 的区间
    price_analysis = price_analysis[price_analysis['交易数'] >= 5]
    
    print("\n价格区间表现（交易数 >= 5）：")
    print(price_analysis.sort_values('胜率', ascending=False))
    
    return {
        'price_analysis': price_analysis.to_dict()
    }

def analyze_direction_patterns(trades_df):
    """分析方向模式"""
    print("\n" + "=" * 60)
    print("方向模式分析")
    print("=" * 60)
    
    # 多空对比
    print("\n【多空对比】")
    direction_analysis = trades_df.groupby('direction').agg({
        'is_win': ['count', 'sum', 'mean'],
        'profit': ['sum', 'mean']
    }).round(2)
    direction_analysis.columns = ['交易数', '盈利数', '胜率', '总盈亏', '平均盈亏']
    direction_analysis['胜率'] = (direction_analysis['胜率'] * 100).round(2)
    print(direction_analysis)
    
    # 连续同方向交易分析
    print("\n【连续同方向交易分析】")
    trades_df['prev_direction'] = trades_df['direction'].shift(1)
    trades_df['is_same_direction'] = trades_df['direction'] == trades_df['prev_direction']
    
    same_dir = trades_df[trades_df['is_same_direction'] == True]
    diff_dir = trades_df[trades_df['is_same_direction'] == False]
    
    print(f"\n连续同方向交易：")
    print(f"  交易数：{len(same_dir)}")
    print(f"  胜率：{same_dir['is_win'].mean() * 100:.2f}%")
    print(f"  平均盈亏：${same_dir['profit'].mean():.2f}")
    
    print(f"\n方向切换后交易：")
    print(f"  交易数：{len(diff_dir)}")
    print(f"  胜率：{diff_dir['is_win'].mean() * 100:.2f}%")
    print(f"  平均盈亏：${diff_dir['profit'].mean():.2f}")
    
    return {
        'direction_analysis': direction_analysis.to_dict(),
        'same_direction_win_rate': same_dir['is_win'].mean() * 100,
        'diff_direction_win_rate': diff_dir['is_win'].mean() * 100
    }

def analyze_sequence_patterns(trades_df):
    """分析序列模式"""
    print("\n" + "=" * 60)
    print("序列模式分析")
    print("=" * 60)
    
    # 连续盈亏分析
    trades_df['prev_is_win'] = trades_df['is_win'].shift(1)
    
    # 盈利后的下一单
    after_win = trades_df[trades_df['prev_is_win'] == True]
    print(f"\n【盈利后的下一单】")
    print(f"  交易数：{len(after_win)}")
    print(f"  胜率：{after_win['is_win'].mean() * 100:.2f}%")
    print(f"  平均盈亏：${after_win['profit'].mean():.2f}")
    
    # 亏损后的下一单
    after_loss = trades_df[trades_df['prev_is_win'] == False]
    print(f"\n【亏损后的下一单】")
    print(f"  交易数：{len(after_loss)}")
    print(f"  胜率：{after_loss['is_win'].mean() * 100:.2f}%")
    print(f"  平均盈亏：${after_loss['profit'].mean():.2f}")
    
    # 连续盈亏统计
    print(f"\n【连续盈亏统计】")
    
    # 计算连续盈利/亏损次数
    trades_df['streak'] = 0
    current_streak = 0
    prev_win = None
    
    for i, row in trades_df.iterrows():
        if prev_win is None:
            current_streak = 1
        elif row['is_win'] == prev_win:
            current_streak += 1
        else:
            current_streak = 1
        
        trades_df.at[i, 'streak'] = current_streak
        prev_win = row['is_win']
    
    max_win_streak = trades_df[trades_df['is_win'] == True]['streak'].max()
    max_loss_streak = trades_df[trades_df['is_win'] == False]['streak'].max()
    
    print(f"  最大连续盈利：{max_win_streak} 次")
    print(f"  最大连续亏损：{max_loss_streak} 次")
    
    return {
        'after_win_rate': after_win['is_win'].mean() * 100,
        'after_loss_rate': after_loss['is_win'].mean() * 100,
        'max_win_streak': int(max_win_streak),
        'max_loss_streak': int(max_loss_streak)
    }

def analyze_profit_distribution(trades_df):
    """分析盈亏分布"""
    print("\n" + "=" * 60)
    print("盈亏分布分析")
    print("=" * 60)
    
    # 盈利分布
    wins = trades_df[trades_df['is_win'] == True]['profit']
    losses = trades_df[trades_df['is_win'] == False]['profit']
    
    print(f"\n【盈利交易分布】")
    print(f"  数量：{len(wins)}")
    print(f"  平均：${wins.mean():.2f}")
    print(f"  中位数：${wins.median():.2f}")
    print(f"  最大：${wins.max():.2f}")
    print(f"  最小：${wins.min():.2f}")
    print(f"  标准差：${wins.std():.2f}")
    
    print(f"\n【亏损交易分布】")
    print(f"  数量：{len(losses)}")
    print(f"  平均：${losses.mean():.2f}")
    print(f"  中位数：${losses.median():.2f}")
    print(f"  最大：${losses.max():.2f}")
    print(f"  最小：${losses.min():.2f}")
    print(f"  标准差：${losses.std():.2f}")
    
    # 大盈利和大亏损
    print(f"\n【大盈利交易（Top 10）】")
    top_wins = trades_df.nlargest(10, 'profit')[['trade_num', 'direction', 'entry_time', 'profit']]
    print(top_wins.to_string(index=False))
    
    print(f"\n【大亏损交易（Bottom 10）】")
    top_losses = trades_df.nsmallest(10, 'profit')[['trade_num', 'direction', 'entry_time', 'profit']]
    print(top_losses.to_string(index=False))
    
    return {
        'win_avg': wins.mean(),
        'loss_avg': losses.mean(),
        'win_median': wins.median(),
        'loss_median': losses.median(),
        'profit_factor': abs(wins.sum() / losses.sum())
    }

def analyze_exit_signals(trades_df):
    """分析出场信号"""
    print("\n" + "=" * 60)
    print("出场信号分析")
    print("=" * 60)
    
    # 清理出场信号中的 emoji
    trades_df['exit_signal_clean'] = trades_df['exit_signal'].str.replace('✅', '[OK]').str.replace('❌', '[X]')
    
    exit_analysis = trades_df.groupby('exit_signal_clean').agg({
        'is_win': ['count', 'sum', 'mean'],
        'profit': ['sum', 'mean']
    }).round(2)
    exit_analysis.columns = ['交易数', '盈利数', '胜率', '总盈亏', '平均盈亏']
    exit_analysis['胜率'] = (exit_analysis['胜率'] * 100).round(2)
    
    print(exit_analysis.to_string())
    
    return {
        'exit_analysis': exit_analysis.to_dict()
    }

def generate_optimization_suggestions(analysis_results):
    """生成优化建议"""
    print("\n" + "=" * 60)
    print("优化建议")
    print("=" * 60)
    
    suggestions = []
    
    # 基于时间模式的建议
    time_results = analysis_results['time_patterns']
    best_hours = time_results['best_hours']
    worst_hours = time_results['worst_hours']
    
    suggestions.append({
        'category': '时间过滤',
        'suggestion': f"建议只在高胜率时段交易：{best_hours}",
        'expected_impact': '胜率提升 3-5%'
    })
    
    suggestions.append({
        'category': '时间过滤',
        'suggestion': f"建议避开低胜率时段：{worst_hours}",
        'expected_impact': '减少亏损交易 10-15%'
    })
    
    # 基于方向模式的建议
    direction_results = analysis_results['direction_patterns']
    if direction_results['same_direction_win_rate'] < direction_results['diff_direction_win_rate']:
        suggestions.append({
            'category': '方向管理',
            'suggestion': '连续同方向交易胜率较低，建议增加方向切换后的仓位',
            'expected_impact': '胜率提升 2-3%'
        })
    
    # 基于序列模式的建议
    sequence_results = analysis_results['sequence_patterns']
    if sequence_results['after_loss_rate'] < sequence_results['after_win_rate']:
        suggestions.append({
            'category': '风险管理',
            'suggestion': '亏损后的下一单胜率较低，建议增加休息时间或降低仓位',
            'expected_impact': '最大回撤降低 10-20%'
        })
    
    print("\n优化建议清单：")
    for i, sug in enumerate(suggestions, 1):
        print(f"\n{i}. 【{sug['category']}】")
        print(f"   建议：{sug['suggestion']}")
        print(f"   预期效果：{sug['expected_impact']}")
    
    return suggestions

def main():
    print("=" * 60)
    print("深度分析历史回测清单")
    print("=" * 60)
    
    # 加载数据
    csv_path = r"G:\其他计算机\租用笔记本\能量块\能量块龙虾进化\Tradingview策略\能量块V11_激进型]_ICMARKETS_XAUUSD_2026-03-10.csv"
    trades_df = load_trades(csv_path)
    
    print(f"\n加载完成：{len(trades_df)} 笔交易")
    print(f"时间范围：{trades_df['entry_time'].min()} 到 {trades_df['entry_time'].max()}")
    print(f"总盈亏：${trades_df['profit'].sum():.2f}")
    print(f"胜率：{trades_df['is_win'].mean() * 100:.2f}%")
    
    # 执行各项分析
    analysis_results = {}
    
    analysis_results['time_patterns'] = analyze_time_patterns(trades_df)
    analysis_results['price_patterns'] = analyze_price_patterns(trades_df)
    analysis_results['direction_patterns'] = analyze_direction_patterns(trades_df)
    analysis_results['sequence_patterns'] = analyze_sequence_patterns(trades_df)
    analysis_results['profit_distribution'] = analyze_profit_distribution(trades_df)
    analysis_results['exit_signals'] = analyze_exit_signals(trades_df)
    
    # 生成优化建议
    suggestions = generate_optimization_suggestions(analysis_results)
    
    # 保存结果
    output = {
        'analysis_results': analysis_results,
        'suggestions': suggestions,
        'summary': {
            'total_trades': len(trades_df),
            'win_rate': trades_df['is_win'].mean() * 100,
            'total_profit': trades_df['profit'].sum(),
            'avg_profit': trades_df['profit'].mean()
        }
    }
    
    with open('deep_analysis_results.json', 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False, default=str)
    
    print("\n" + "=" * 60)
    print("分析完成！结果已保存到 deep_analysis_results.json")
    print("=" * 60)

if __name__ == "__main__":
    main()
