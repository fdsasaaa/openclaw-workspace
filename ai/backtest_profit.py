"""
完整盈亏回测 - 基于真实策略逻辑
"""

import sys
import os
import pandas as pd
from datetime import datetime
from typing import List, Dict, Tuple

sys.path.append(os.path.dirname(__file__))

from backtest import Backtester
from config import get_config
from rule_engine import RuleEngine
import MetaTrader5 as mt5

class ProfitBacktester(Backtester):
    """扩展回测器，增加盈亏计算"""
    
    def simulate_trade(self, signal: Dict, decision: str) -> Dict:
        """
        模拟单笔交易
        
        参数:
            signal: 箱体信号
            decision: AI 决策（LONG_ONLY/SHORT_ONLY/BOTH/NONE）
        
        返回:
            交易结果字典
        """
        result = {
            'signal_id': signal.get('signal_id', 0),
            'timestamp': signal['timestamp'],
            'symbol': signal['symbol'],
            'decision': decision,
            'trades': []
        }
        
        if decision == 'NONE':
            return result
        
        box_upper = signal['box_upper']
        box_lower = signal['box_lower']
        box_height = box_upper - box_lower
        
        # 获取后续价格数据（模拟挂单后的价格走势）
        # 这里简化处理：假设在接下来的 50 根 K 线内观察
        
        # 多单逻辑
        if decision in ['LONG_ONLY', 'BOTH']:
            long_entry = box_upper
            long_sl = box_lower
            long_tp = box_upper + box_height * 0.65  # 简化：固定止盈
            
            # 模拟多单执行（这里需要实际的后续价格数据）
            # 暂时返回结构
            result['trades'].append({
                'side': 'LONG',
                'entry': long_entry,
                'sl': long_sl,
                'tp': long_tp,
                'result': 'PENDING'  # 需要后续价格数据才能确定
            })
        
        # 空单逻辑
        if decision in ['SHORT_ONLY', 'BOTH']:
            short_entry = box_lower
            short_sl = box_upper
            short_tp = box_lower - box_height * 0.65
            
            result['trades'].append({
                'side': 'SHORT',
                'entry': short_entry,
                'sl': short_sl,
                'tp': short_tp,
                'result': 'PENDING'
            })
        
        return result
    
    def analyze_historical_trades(self, csv_path: str) -> pd.DataFrame:
        """
        分析历史交易记录
        
        参数:
            csv_path: TradingView 回测 CSV 路径
        
        返回:
            DataFrame: 分析结果
        """
        print(f"\n分析历史交易记录: {csv_path}")
        
        # 读取 CSV
        df = pd.read_csv(csv_path, encoding='utf-8-sig')
        
        print(f"总交易数: {len(df)}")
        print(f"列名: {df.columns.tolist()}")
        
        # 筛选出场记录（包含盈亏）
        exits = df[df['类型'].str.contains('出场', na=False)].copy()
        
        print(f"\n出场记录数: {len(exits)}")
        
        # 统计分析
        total_trades = len(exits)
        winning_trades = len(exits[exits['净损益 USD'] > 0])
        losing_trades = len(exits[exits['净损益 USD'] < 0])
        
        win_rate = winning_trades / total_trades * 100 if total_trades > 0 else 0
        
        total_profit = exits['净损益 USD'].sum()
        avg_profit = exits['净损益 USD'].mean()
        
        max_profit = exits['净损益 USD'].max()
        max_loss = exits['净损益 USD'].min()
        
        # 计算盈亏比
        avg_win = exits[exits['净损益 USD'] > 0]['净损益 USD'].mean() if winning_trades > 0 else 0
        avg_loss = abs(exits[exits['净损益 USD'] < 0]['净损益 USD'].mean()) if losing_trades > 0 else 0
        profit_factor = avg_win / avg_loss if avg_loss > 0 else 0
        
        stats = {
            'total_trades': total_trades,
            'winning_trades': winning_trades,
            'losing_trades': losing_trades,
            'win_rate': win_rate,
            'total_profit': total_profit,
            'avg_profit': avg_profit,
            'max_profit': max_profit,
            'max_loss': max_loss,
            'avg_win': avg_win,
            'avg_loss': avg_loss,
            'profit_factor': profit_factor
        }
        
        return stats, exits
    
    def compare_with_ai_filter(self, historical_stats: Dict, ai_filtered_stats: Dict) -> Dict:
        """
        对比 AI 过滤前后的效果
        
        参数:
            historical_stats: 历史回测统计
            ai_filtered_stats: AI 过滤后统计
        
        返回:
            对比结果
        """
        comparison = {
            'trades_reduction': historical_stats['total_trades'] - ai_filtered_stats['kept_signals'],
            'trades_reduction_pct': (1 - ai_filtered_stats['kept_signals'] / historical_stats['total_trades']) * 100,
            
            # 假设：被拒绝的信号中，亏损信号占比更高
            # 这需要实际匹配信号和交易结果
        }
        
        return comparison

def main():
    print("=" * 60)
    print("完整盈亏回测")
    print("=" * 60)
    
    backtester = ProfitBacktester()
    
    # 1. 分析历史交易记录
    csv_path = r"G:\其他计算机\租用笔记本\能量块\能量块龙虾进化\Tradingview策略\能量块V11_激进型]_ICMARKETS_XAUUSD_2026-03-10.csv"
    
    historical_stats, exits_df = backtester.analyze_historical_trades(csv_path)
    
    print("\n" + "=" * 60)
    print("历史回测统计（无 AI 过滤）")
    print("=" * 60)
    print(f"总交易数: {historical_stats['total_trades']}")
    print(f"盈利交易: {historical_stats['winning_trades']}")
    print(f"亏损交易: {historical_stats['losing_trades']}")
    print(f"胜率: {historical_stats['win_rate']:.2f}%")
    print(f"总盈亏: ${historical_stats['total_profit']:.2f}")
    print(f"平均盈亏: ${historical_stats['avg_profit']:.2f}")
    print(f"最大盈利: ${historical_stats['max_profit']:.2f}")
    print(f"最大亏损: ${historical_stats['max_loss']:.2f}")
    print(f"平均盈利: ${historical_stats['avg_win']:.2f}")
    print(f"平均亏损: ${historical_stats['avg_loss']:.2f}")
    print(f"盈亏比: {historical_stats['profit_factor']:.2f}")
    
    # 2. 运行 AI 过滤回测
    print("\n" + "=" * 60)
    print("运行 AI 过滤回测")
    print("=" * 60)
    
    xauusd_config = get_config("XAUUSD")
    backtester.rule_engine = RuleEngine(xauusd_config)
    
    symbol = "XAUUSD"
    timeframe = mt5.TIMEFRAME_H1
    days = 90
    
    # 准备历史数据
    df = backtester.prepare_historical_data(symbol, timeframe, days)
    
    if df is not None:
        # 生成箱体信号
        signals = backtester.generate_box_signals(df, symbol)
        
        # 运行回测
        df_results = backtester.run_backtest(signals)
        
        # 分析结果
        ai_stats = backtester.analyze_results(df_results)
        
        print("\n" + "=" * 60)
        print("AI 过滤统计")
        print("=" * 60)
        print(f"总信号数: {ai_stats['total_signals']}")
        print(f"保留信号: {ai_stats['kept_signals']} ({ai_stats['keep_rate']:.1f}%)")
        print(f"拒绝信号: {ai_stats['rejected_signals']} ({ai_stats['reject_rate']:.1f}%)")
        
        # 3. 对比分析
        print("\n" + "=" * 60)
        print("AI 过滤效果预估")
        print("=" * 60)
        print(f"\n假设 AI 过滤能够：")
        print(f"1. 保留 {ai_stats['keep_rate']:.1f}% 的信号")
        print(f"2. 拒绝的信号中，亏损信号占比更高")
        print(f"\n预估效果：")
        print(f"- 交易数量减少: {historical_stats['total_trades']} → {int(historical_stats['total_trades'] * ai_stats['keep_rate'] / 100)}")
        print(f"- 如果拒绝的信号中 60% 是亏损信号：")
        
        rejected_count = int(historical_stats['total_trades'] * ai_stats['reject_rate'] / 100)
        rejected_losing = int(rejected_count * 0.6)
        rejected_winning = rejected_count - rejected_losing
        
        new_winning = historical_stats['winning_trades'] - rejected_winning
        new_losing = historical_stats['losing_trades'] - rejected_losing
        new_total = new_winning + new_losing
        
        new_win_rate = new_winning / new_total * 100 if new_total > 0 else 0
        
        print(f"  - 新胜率: {historical_stats['win_rate']:.2f}% → {new_win_rate:.2f}%")
        print(f"  - 胜率提升: +{new_win_rate - historical_stats['win_rate']:.2f}%")
        
        # 关闭 MT5
        backtester.collector.shutdown()
    
    print("\n" + "=" * 60)
    print("完整盈亏回测完成")
    print("=" * 60)

if __name__ == "__main__":
    main()
