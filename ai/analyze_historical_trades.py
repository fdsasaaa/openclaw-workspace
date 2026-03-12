"""
直接分析 AI 过滤规则对历史交易的影响
不需要匹配信号，直接对每笔历史交易应用 AI 规则
"""

import sys
import os
import pandas as pd
import json

# 添加父目录到路径
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from ai.config import get_config
from ai.rule_engine import RuleEngine
import MetaTrader5 as mt5

def main():
    print("=" * 60)
    print("AI 过滤规则对历史交易的影响分析")
    print("=" * 60)
    
    # 1. 加载历史交易记录
    print("\n阶段 1: 加载历史交易记录")
    print("-" * 60)
    
    csv_path = r"G:\其他计算机\租用笔记本\能量块\能量块龙虾进化\Tradingview策略\能量块V11_激进型]_ICMARKETS_XAUUSD_2026-03-10.csv"
    df = pd.read_csv(csv_path, encoding='utf-8-sig')
    
    # 筛选进场记录
    entries = df[df['类型'].str.contains('进场', na=False)].copy()
    entries['时间'] = pd.to_datetime(entries['日期和时间'], format='%Y-%m-%d %H:%M')
    entries['方向'] = entries['类型'].apply(lambda x: 'LONG' if '多头' in x else 'SHORT')
    
    # 筛选出场记录
    exits = df[df['类型'].str.contains('出场', na=False)].copy()
    exits['时间'] = pd.to_datetime(exits['日期和时间'], format='%Y-%m-%d %H:%M')
    
    # 合并入场和出场
    trades = []
    for i, entry_row in entries.iterrows():
        trade_num = entry_row['交易 #']
        exit_row = exits[exits['交易 #'] == trade_num]
        
        if not exit_row.empty:
            exit_row = exit_row.iloc[0]
            trades.append({
                'trade_num': trade_num,
                'direction': entry_row['方向'],
                'entry_time': entry_row['时间'],
                'entry_price': entry_row['价格 USD'],
                'exit_time': exit_row['时间'],
                'exit_price': exit_row['价格 USD'],
                'profit': exit_row['净损益 USD'],
                'is_win': exit_row['净损益 USD'] > 0
            })
    
    trades_df = pd.DataFrame(trades)
    
    print(f"总交易数: {len(trades_df)}")
    print(f"盈利交易: {len(trades_df[trades_df['is_win']])}")
    print(f"亏损交易: {len(trades_df[~trades_df['is_win']])}")
    print(f"胜率: {len(trades_df[trades_df['is_win']]) / len(trades_df) * 100:.2f}%")
    
    # 2. 初始化 AI 规则引擎
    print("\n阶段 2: 初始化 AI 规则引擎")
    print("-" * 60)
    
    xauusd_config = get_config("XAUUSD")
    rule_engine = RuleEngine(xauusd_config)
    
    # 初始化 MT5
    if not mt5.initialize():
        print("[ERROR] 无法初始化 MT5")
        return
    
    print("MT5 连接成功")
    
    # 3. 对每笔交易应用 AI 规则
    print("\n阶段 3: 对每笔交易应用 AI 规则")
    print("-" * 60)
    
    results = []
    
    for idx, trade in trades_df.iterrows():
        # 获取入场时刻的市场数据
        entry_time = trade['entry_time']
        
        # 获取入场前的 K 线数据（用于计算指标）
        rates = mt5.copy_rates_range("XAUUSD", mt5.TIMEFRAME_H1, 
                                      entry_time - pd.Timedelta(days=7), 
                                      entry_time)
        
        if rates is None or len(rates) < 50:
            print(f"[WARN] 交易 #{trade['trade_num']} 无法获取足够的历史数据")
            continue
        
        # 转换为 DataFrame
        df_rates = pd.DataFrame(rates)
        df_rates['time'] = pd.to_datetime(df_rates['time'], unit='s')
        
        # 计算指标
        df_rates['atr'] = df_rates['high'] - df_rates['low']  # 简化 ATR
        df_rates['rsi'] = 50  # 简化 RSI（实际需要计算）
        df_rates['ma20'] = df_rates['close'].rolling(20).mean()
        df_rates['ma50'] = df_rates['close'].rolling(50).mean()
        df_rates['volume_ma'] = df_rates['tick_volume'].rolling(20).mean()
        
        # 获取最后一根 K 线的数据
        last_bar = df_rates.iloc[-1]
        
        # 构造信号（模拟箱体信号）
        signal = {
            'timestamp': entry_time.isoformat(),
            'symbol': 'XAUUSD',
            'box_upper': trade['entry_price'] + 10,  # 假设箱体高度 20 美元
            'box_lower': trade['entry_price'] - 10,
            'box_score': 80,  # 假设箱体质量
            'current_price': trade['entry_price'],
            'atr': last_bar['atr'],
            'rsi': last_bar['rsi'],
            'ma20': last_bar['ma20'],
            'ma50': last_bar['ma50'],
            'volume': last_bar['tick_volume'],
            'volume_ma': last_bar['volume_ma']
        }
        
        # 应用 AI 规则
        decision_result = rule_engine.decide(signal)
        decision = decision_result['decision']
        
        # 判断是否会被保留
        kept = False
        if trade['direction'] == 'LONG' and decision in ['LONG_ONLY', 'BOTH']:
            kept = True
        elif trade['direction'] == 'SHORT' and decision in ['SHORT_ONLY', 'BOTH']:
            kept = True
        
        results.append({
            'trade_num': trade['trade_num'],
            'direction': trade['direction'],
            'entry_time': trade['entry_time'],
            'entry_price': trade['entry_price'],
            'profit': trade['profit'],
            'is_win': trade['is_win'],
            'ai_decision': decision,
            'kept': kept
        })
        
        if (idx + 1) % 20 == 0:
            print(f"已处理 {idx + 1}/{len(trades_df)} 笔交易")
    
    results_df = pd.DataFrame(results)
    
    # 关闭 MT5
    mt5.shutdown()
    
    # 4. 分析结果
    print("\n阶段 4: 分析 AI 过滤效果")
    print("-" * 60)
    
    total = len(results_df)
    kept = results_df[results_df['kept'] == True]
    rejected = results_df[results_df['kept'] == False]
    
    kept_wins = len(kept[kept['is_win'] == True])
    kept_losses = len(kept[kept['is_win'] == False])
    kept_win_rate = kept_wins / len(kept) * 100 if len(kept) > 0 else 0
    
    rejected_wins = len(rejected[rejected['is_win'] == True])
    rejected_losses = len(rejected[rejected['is_win'] == False])
    rejected_loss_rate = rejected_losses / len(rejected) * 100 if len(rejected) > 0 else 0
    
    accuracy = (kept_wins + rejected_losses) / total * 100 if total > 0 else 0
    false_rejection_rate = rejected_wins / total * 100 if total > 0 else 0
    false_keep_rate = kept_losses / total * 100 if total > 0 else 0
    
    print(f"\n总交易数: {total}")
    print(f"\n[AI 保留的交易]")
    print(f"  数量: {len(kept)} ({len(kept)/total*100:.1f}%)")
    print(f"  盈利: {kept_wins}")
    print(f"  亏损: {kept_losses}")
    print(f"  胜率: {kept_win_rate:.2f}%")
    
    print(f"\n[AI 拒绝的交易]")
    print(f"  数量: {len(rejected)} ({len(rejected)/total*100:.1f}%)")
    print(f"  盈利: {rejected_wins} (误删)")
    print(f"  亏损: {rejected_losses} (正确拒绝)")
    print(f"  亏损率: {rejected_loss_rate:.2f}%")
    
    print(f"\n[AI 过滤效果]")
    print(f"  准确率: {accuracy:.2f}%")
    print(f"  误删率: {false_rejection_rate:.2f}%")
    print(f"  误留率: {false_keep_rate:.2f}%")
    
    # 5. 保存结果
    results_df.to_csv("ai_filter_on_historical_trades.csv", index=False, encoding='utf-8-sig')
    print(f"\n[OK] 结果已保存: ai_filter_on_historical_trades.csv")
    
    # 6. 生成报告
    stats = {
        'total': total,
        'kept': len(kept),
        'kept_wins': kept_wins,
        'kept_losses': kept_losses,
        'kept_win_rate': kept_win_rate,
        'rejected': len(rejected),
        'rejected_wins': rejected_wins,
        'rejected_losses': rejected_losses,
        'rejected_loss_rate': rejected_loss_rate,
        'accuracy': accuracy,
        'false_rejection_rate': false_rejection_rate,
        'false_keep_rate': false_keep_rate
    }
    
    with open("ai_filter_stats.json", 'w', encoding='utf-8') as f:
        json.dump(stats, f, indent=2)
    
    print(f"[OK] 统计数据已保存: ai_filter_stats.json")
    
    print("\n" + "=" * 60)
    print("分析完成")
    print("=" * 60)

if __name__ == "__main__":
    main()
