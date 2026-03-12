"""
信号匹配器 - 将历史交易记录与箱体信号匹配
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import List, Dict, Tuple
import sys
import os

sys.path.append(os.path.dirname(__file__))

class SignalMatcher:
    """匹配历史交易记录和箱体信号"""
    
    def __init__(self):
        self.tolerance_pips = 20.0  # 价格匹配容差（20 美元）
        self.time_window_hours = 48  # 时间窗口（48 小时）
    
    def load_historical_trades(self, csv_path: str) -> pd.DataFrame:
        """
        加载历史交易记录
        
        参数:
            csv_path: TradingView 回测 CSV 路径
        
        返回:
            DataFrame: 交易记录
        """
        print(f"\n加载历史交易记录: {csv_path}")
        
        # 读取 CSV
        df = pd.read_csv(csv_path, encoding='utf-8-sig')
        
        # 筛选出场记录（包含盈亏）
        exits = df[df['类型'].str.contains('出场', na=False)].copy()
        
        # 解析时间
        exits['时间'] = pd.to_datetime(exits['日期和时间'], format='%Y-%m-%d %H:%M')
        
        # 提取方向（多头/空头）
        exits['方向'] = exits['类型'].apply(lambda x: 'LONG' if '多头' in x else 'SHORT')
        
        # 提取入场价格（从前一行获取）
        entries = df[df['类型'].str.contains('进场', na=False)].copy()
        entries['时间'] = pd.to_datetime(entries['日期和时间'], format='%Y-%m-%d %H:%M')
        
        # 合并入场和出场
        result = []
        for i, exit_row in exits.iterrows():
            # 找到对应的入场记录（同一交易编号）
            trade_num = exit_row['交易 #']
            entry_row = entries[entries['交易 #'] == trade_num]
            
            if not entry_row.empty:
                entry_row = entry_row.iloc[0]
                result.append({
                    'trade_num': trade_num,
                    'direction': exit_row['方向'],
                    'entry_time': entry_row['时间'],
                    'entry_price': entry_row['价格 USD'],
                    'exit_time': exit_row['时间'],
                    'exit_price': exit_row['价格 USD'],
                    'profit': exit_row['净损益 USD'],
                    'is_win': exit_row['净损益 USD'] > 0
                })
        
        trades_df = pd.DataFrame(result)
        
        print(f"加载完成: {len(trades_df)} 笔交易")
        print(f"多头交易: {len(trades_df[trades_df['direction'] == 'LONG'])}")
        print(f"空头交易: {len(trades_df[trades_df['direction'] == 'SHORT'])}")
        
        return trades_df
    
    def match_signals_to_trades(self, signals: List[Dict], trades: pd.DataFrame) -> pd.DataFrame:
        """
        匹配信号和交易
        
        参数:
            signals: 箱体信号列表
            trades: 历史交易记录
        
        返回:
            DataFrame: 匹配结果
        """
        print(f"\n开始匹配 {len(signals)} 个信号和 {len(trades)} 笔交易...")
        
        matches = []
        
        for signal in signals:
            signal_time = pd.to_datetime(signal['timestamp'])
            box_upper = signal['box_upper']
            box_lower = signal['box_lower']
            
            # 在时间窗口内查找交易
            time_mask = (
                (trades['entry_time'] >= signal_time - timedelta(hours=self.time_window_hours)) &
                (trades['entry_time'] <= signal_time + timedelta(hours=self.time_window_hours))
            )
            
            nearby_trades = trades[time_mask]
            
            # 匹配多单（入场价格接近箱体上边界）
            long_trades = nearby_trades[nearby_trades['direction'] == 'LONG']
            for _, trade in long_trades.iterrows():
                price_diff = abs(trade['entry_price'] - box_upper)
                if price_diff <= self.tolerance_pips:
                    matches.append({
                        'signal_id': signal.get('signal_id', 0),
                        'signal_time': signal_time,
                        'box_upper': box_upper,
                        'box_lower': box_lower,
                        'trade_num': trade['trade_num'],
                        'direction': 'LONG',
                        'entry_time': trade['entry_time'],
                        'entry_price': trade['entry_price'],
                        'exit_time': trade['exit_time'],
                        'exit_price': trade['exit_price'],
                        'profit': trade['profit'],
                        'is_win': trade['is_win'],
                        'price_diff': price_diff,
                        'time_diff_hours': (trade['entry_time'] - signal_time).total_seconds() / 3600
                    })
            
            # 匹配空单（入场价格接近箱体下边界）
            short_trades = nearby_trades[nearby_trades['direction'] == 'SHORT']
            for _, trade in short_trades.iterrows():
                price_diff = abs(trade['entry_price'] - box_lower)
                if price_diff <= self.tolerance_pips:
                    matches.append({
                        'signal_id': signal.get('signal_id', 0),
                        'signal_time': signal_time,
                        'box_upper': box_upper,
                        'box_lower': box_lower,
                        'trade_num': trade['trade_num'],
                        'direction': 'SHORT',
                        'entry_time': trade['entry_time'],
                        'entry_price': trade['entry_price'],
                        'exit_time': trade['exit_time'],
                        'exit_price': trade['exit_price'],
                        'profit': trade['profit'],
                        'is_win': trade['is_win'],
                        'price_diff': price_diff,
                        'time_diff_hours': (trade['entry_time'] - signal_time).total_seconds() / 3600
                    })
        
        matches_df = pd.DataFrame(matches)
        
        print(f"匹配完成: {len(matches_df)} 个匹配")
        
        return matches_df
    
    def analyze_ai_filter_accuracy(self, matches: pd.DataFrame, backtest_results: pd.DataFrame) -> Dict:
        """
        分析 AI 过滤准确率
        
        参数:
            matches: 信号-交易匹配结果
            backtest_results: AI 回测结果
        
        返回:
            分析结果字典
        """
        print("\n分析 AI 过滤准确率...")
        
        # 合并匹配结果和 AI 决策
        merged = matches.merge(
            backtest_results[['signal_id', 'decision', 'kept']],
            on='signal_id',
            how='left'
        )
        
        # 统计
        total_matches = len(merged)
        
        # AI 保留的信号
        kept_signals = merged[merged['kept'] == True]
        kept_wins = len(kept_signals[kept_signals['is_win'] == True])
        kept_losses = len(kept_signals[kept_signals['is_win'] == False])
        kept_win_rate = kept_wins / len(kept_signals) * 100 if len(kept_signals) > 0 else 0
        
        # AI 拒绝的信号
        rejected_signals = merged[merged['kept'] == False]
        rejected_wins = len(rejected_signals[rejected_signals['is_win'] == True])
        rejected_losses = len(rejected_signals[rejected_signals['is_win'] == False])
        rejected_loss_rate = rejected_losses / len(rejected_signals) * 100 if len(rejected_signals) > 0 else 0
        
        # 计算准确率
        # 准确率 = (保留的盈利信号 + 拒绝的亏损信号) / 总信号数
        correct_decisions = kept_wins + rejected_losses
        accuracy = correct_decisions / total_matches * 100 if total_matches > 0 else 0
        
        # 误删率（拒绝了盈利信号）
        false_rejection_rate = rejected_wins / total_matches * 100 if total_matches > 0 else 0
        
        # 误留率（保留了亏损信号）
        false_keep_rate = kept_losses / total_matches * 100 if total_matches > 0 else 0
        
        stats = {
            'total_matches': total_matches,
            'kept_signals': len(kept_signals),
            'kept_wins': kept_wins,
            'kept_losses': kept_losses,
            'kept_win_rate': kept_win_rate,
            'rejected_signals': len(rejected_signals),
            'rejected_wins': rejected_wins,
            'rejected_losses': rejected_losses,
            'rejected_loss_rate': rejected_loss_rate,
            'accuracy': accuracy,
            'false_rejection_rate': false_rejection_rate,
            'false_keep_rate': false_keep_rate
        }
        
        return stats, merged

def main():
    print("=" * 60)
    print("信号匹配分析")
    print("=" * 60)
    
    matcher = SignalMatcher()
    
    # 1. 加载历史交易记录
    csv_path = r"G:\其他计算机\租用笔记本\能量块\能量块龙虾进化\Tradingview策略\能量块V11_激进型]_ICMARKETS_XAUUSD_2026-03-10.csv"
    trades = matcher.load_historical_trades(csv_path)
    
    # 2. 加载回测信号（需要从 backtest.py 获取）
    # 这里暂时使用模拟数据
    print("\n⚠️ 需要运行 backtest.py 生成信号数据")
    print("请先运行: python backtest_xauusd.py")
    
    # TODO: 实际实现需要从数据库或文件加载信号

if __name__ == "__main__":
    main()
