"""
XAUUSD 回测脚本
"""

import sys
import os

# 添加路径
sys.path.append(os.path.dirname(__file__))

from backtest import Backtester
from config import get_config
from rule_engine import RuleEngine
import MetaTrader5 as mt5

def main():
    print("=" * 60)
    print("XAUUSD 回测")
    print("=" * 60)
    
    # 创建回测器
    backtester = Backtester()
    
    # 使用 XAUUSD 配置
    xauusd_config = get_config("XAUUSD")
    backtester.rule_engine = RuleEngine(xauusd_config)
    
    print("\n使用 XAUUSD 专用配置:")
    print(f"  ATR 阈值: {xauusd_config['coarse']['atr_min_ratio']}x - {xauusd_config['coarse']['atr_max_ratio']}x")
    print(f"  成交量阈值: {xauusd_config['coarse']['volume_min_ratio']}x")
    print(f"  RSI 阈值: {xauusd_config['fine']['rsi_oversold']} - {xauusd_config['fine']['rsi_overbought']}")
    print(f"  箱体质量阈值: {xauusd_config['fine']['min_box_score']}")
    
    # 1. 准备历史数据
    symbol = "XAUUSD"
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
        backtester.generate_report(stats, df_results, "backtest_report_XAUUSD.txt")
        
        # 关闭 MT5
        backtester.collector.shutdown()
    
    print("\n" + "=" * 60)
    print("XAUUSD 回测完成")
    print("=" * 60)

if __name__ == "__main__":
    main()
