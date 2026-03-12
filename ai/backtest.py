"""
回测框架 - 验证规则引擎效果
"""

import sys
import os
from datetime import datetime, timedelta
from typing import List, Dict
import pandas as pd

# 添加路径
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'data'))
sys.path.append(os.path.join(os.path.dirname(__file__)))

from collector import DataCollector
from storage import DataStorage
from rule_engine import RuleEngine
import MetaTrader5 as mt5

class Backtester:
    def __init__(self):
        """初始化回测器"""
        self.collector = DataCollector()
        self.storage = DataStorage("backtest_data.db")
        self.rule_engine = RuleEngine()
        
    def prepare_historical_data(self, symbol: str, timeframe, days: int = 90):
        """
        准备历史数据
        
        参数:
            symbol: 交易品种
            timeframe: 时间周期
            days: 天数
        
        返回:
            DataFrame: 历史数据
        """
        print(f"\n准备历史数据: {symbol}, {days} 天")
        
        # 初始化 MT5
        if not self.collector.initialize():
            print("MT5 初始化失败")
            return None
        
        # 计算需要的 K 线数量（每天约 24 根 H1 K 线）
        count = days * 24
        
        # 获取历史数据
        df = self.collector.get_market_data(symbol, timeframe, count)
        
        if df is None:
            print("获取历史数据失败")
            return None
        
        print(f"获取 {len(df)} 根 K 线")
        print(f"时间范围: {df['time'].min()} 到 {df['time'].max()}")
        
        # 保存到数据库
        timeframe_name = "H1"  # 简化处理
        self.storage.save_klines(df, symbol, timeframe_name)
        self.storage.save_indicators(df, symbol, timeframe_name)
        
        print("历史数据已保存到数据库")
        
        return df
    
    def generate_box_signals(self, df: pd.DataFrame, symbol: str) -> List[Dict]:
        """
        模拟箱体信号生成
        
        参数:
            df: 历史数据
            symbol: 交易品种
        
        返回:
            信号列表
        """
        print(f"\n生成箱体信号...")
        
        signals = []
        
        # 简化版：每 20 根 K 线生成一个箱体信号
        for i in range(20, len(df), 20):
            # 获取最近 20 根 K 线
            window = df.iloc[i-20:i]
            
            # 计算箱体上下边界
            upper = window['high'].max()
            lower = window['low'].min()
            
            # 计算箱体评分（简化版：基于波动率）
            atr = window['atr'].mean()
            box_height = upper - lower
            
            if atr > 0:
                score = min(100, (box_height / atr) * 20)
            else:
                score = 50
            
            # 创建信号
            signal = {
                'timestamp': df.iloc[i]['time'].timestamp(),
                'symbol': symbol,
                'event': 'BOX_NEW',
                'box_upper': upper,
                'box_lower': lower,
                'box_score': score,
                'price': df.iloc[i]['close'],
                'ma20': df.iloc[i]['ma20'],
                'ma50': df.iloc[i]['ma50'],
                'atr': df.iloc[i]['atr'],
                'atr_avg': window['atr'].mean(),
                'rsi': df.iloc[i]['rsi'],
                'volume': df.iloc[i]['real_volume'],
                'volume_avg': window['real_volume'].mean()
            }
            
            signals.append(signal)
        
        print(f"生成 {len(signals)} 个箱体信号")
        
        return signals
    
    def run_backtest(self, signals: List[Dict]) -> pd.DataFrame:
        """
        运行回测
        
        参数:
            signals: 信号列表
        
        返回:
            DataFrame: 回测结果
        """
        print(f"\n运行回测...")
        
        results = []
        
        for i, signal in enumerate(signals):
            # 应用规则引擎
            decision_result = self.rule_engine.decide(signal)
            
            # 记录结果
            result = {
                'signal_id': i,
                'timestamp': signal['timestamp'],
                'symbol': signal['symbol'],
                'decision': decision_result['decision'],
                'coarse_result': decision_result['coarse_result'],
                'fine_result': decision_result['fine_result'],
                'coarse_reason': decision_result['coarse_reason'],
                'fine_reason': decision_result['fine_reason'],
                'box_score': signal['box_score'],
                'rsi': signal['rsi'],
                'atr': signal['atr']
            }
            
            results.append(result)
            
            if (i + 1) % 10 == 0:
                print(f"已处理 {i + 1}/{len(signals)} 个信号")
        
        df_results = pd.DataFrame(results)
        
        print(f"回测完成，共处理 {len(results)} 个信号")
        
        return df_results
    
    def analyze_results(self, df_results: pd.DataFrame) -> Dict:
        """
        分析回测结果
        
        参数:
            df_results: 回测结果 DataFrame
        
        返回:
            统计数据字典
        """
        print(f"\n分析回测结果...")
        
        total = len(df_results)
        
        # 决策分布
        decision_counts = df_results['decision'].value_counts().to_dict()
        
        # 保留率
        kept = len(df_results[df_results['decision'] != 'NONE'])
        keep_rate = kept / total * 100 if total > 0 else 0
        
        # 拒绝率
        rejected = len(df_results[df_results['decision'] == 'NONE'])
        reject_rate = rejected / total * 100 if total > 0 else 0
        
        # 粗筛拒绝率
        coarse_rejected = len(df_results[df_results['coarse_result'] == 'NONE'])
        coarse_reject_rate = coarse_rejected / total * 100 if total > 0 else 0
        
        # 精筛拒绝率（粗筛通过但精筛拒绝）
        fine_rejected = len(df_results[
            (df_results['coarse_result'] != 'NONE') & 
            (df_results['fine_result'] == 'NONE')
        ])
        fine_reject_rate = fine_rejected / total * 100 if total > 0 else 0
        
        stats = {
            'total_signals': total,
            'decision_counts': decision_counts,
            'kept_signals': kept,
            'keep_rate': keep_rate,
            'rejected_signals': rejected,
            'reject_rate': reject_rate,
            'coarse_rejected': coarse_rejected,
            'coarse_reject_rate': coarse_reject_rate,
            'fine_rejected': fine_rejected,
            'fine_reject_rate': fine_reject_rate
        }
        
        return stats
    
    def generate_report(self, stats: Dict, df_results: pd.DataFrame, output_file: str = "backtest_report.txt"):
        """
        生成回测报告
        
        参数:
            stats: 统计数据
            df_results: 回测结果
            output_file: 输出文件名
        """
        print(f"\n生成回测报告...")
        
        report = []
        report.append("=" * 60)
        report.append("回测报告")
        report.append("=" * 60)
        report.append(f"\n生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        report.append(f"\n\n总信号数: {stats['total_signals']}")
        report.append(f"保留信号: {stats['kept_signals']} ({stats['keep_rate']:.1f}%)")
        report.append(f"拒绝信号: {stats['rejected_signals']} ({stats['reject_rate']:.1f}%)")
        
        report.append(f"\n\n决策分布:")
        for decision, count in stats['decision_counts'].items():
            percentage = count / stats['total_signals'] * 100
            report.append(f"  {decision}: {count} ({percentage:.1f}%)")
        
        report.append(f"\n\n过滤层级分析:")
        report.append(f"  粗筛拒绝: {stats['coarse_rejected']} ({stats['coarse_reject_rate']:.1f}%)")
        report.append(f"  精筛拒绝: {stats['fine_rejected']} ({stats['fine_reject_rate']:.1f}%)")
        
        report.append(f"\n\n拒绝原因分析:")
        
        # 粗筛拒绝原因
        coarse_rejected_df = df_results[df_results['coarse_result'] == 'NONE']
        if len(coarse_rejected_df) > 0:
            report.append(f"\n  粗筛拒绝原因 TOP 5:")
            reason_counts = coarse_rejected_df['coarse_reason'].value_counts().head(5)
            for reason, count in reason_counts.items():
                report.append(f"    {reason}: {count}")
        
        # 精筛拒绝原因
        fine_rejected_df = df_results[
            (df_results['coarse_result'] != 'NONE') & 
            (df_results['fine_result'] == 'NONE')
        ]
        if len(fine_rejected_df) > 0:
            report.append(f"\n  精筛拒绝原因 TOP 5:")
            reason_counts = fine_rejected_df['fine_reason'].value_counts().head(5)
            for reason, count in reason_counts.items():
                report.append(f"    {reason}: {count}")
        
        report.append("\n\n" + "=" * 60)
        
        # 写入文件
        report_text = "\n".join(report)
        
        output_path = os.path.join(os.path.dirname(__file__), output_file)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(report_text)
        
        print(f"回测报告已保存: {output_path}")
        
        # 同时打印到控制台
        print(report_text)
        
        return report_text

# 测试代码
if __name__ == "__main__":
    backtester = Backtester()
    
    print("=" * 60)
    print("回测框架测试")
    print("=" * 60)
    
    # 1. 准备历史数据
    symbol = "EURUSD"
    timeframe = mt5.TIMEFRAME_H1
    days = 90
    
    df = backtester.prepare_historical_data(symbol, timeframe, days)
    
    if df is not None:
        # 2. 生成箱体信号
        signals = backtester.generate_box_signals(df, symbol)
        
        # 3. 运行回测
        df_results = backtester.run_backtest(signals)
        
        # 4. 分析结果
        stats = backtester.analyze_results(df_results)
        
        # 5. 生成报告
        backtester.generate_report(stats, df_results)
        
        # 关闭 MT5
        backtester.collector.shutdown()
    
    print("\n" + "=" * 60)
    print("回测框架测试完成")
    print("=" * 60)
