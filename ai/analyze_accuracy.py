"""
完整的信号匹配和准确率分析
"""

import sys
import os
import pandas as pd
import json

sys.path.append(os.path.dirname(__file__))

from backtest import Backtester
from config import get_config
from rule_engine import RuleEngine
from signal_matcher import SignalMatcher
import MetaTrader5 as mt5

def main():
    print("=" * 60)
    print("完整信号匹配分析")
    print("=" * 60)
    
    # 1. 运行回测，生成信号和 AI 决策
    print("\n阶段 1: 运行 AI 回测")
    print("-" * 60)
    
    backtester = Backtester()
    xauusd_config = get_config("XAUUSD")
    backtester.rule_engine = RuleEngine(xauusd_config)
    
    symbol = "XAUUSD"
    timeframe = mt5.TIMEFRAME_H1
    days = 365  # 增加到 365 天，覆盖历史交易时间
    
    # 准备历史数据
    df = backtester.prepare_historical_data(symbol, timeframe, days)
    
    if df is None:
        print("❌ 无法获取历史数据")
        return
    
    # 生成箱体信号
    signals = backtester.generate_box_signals(df, symbol)
    
    # 运行回测
    df_results = backtester.run_backtest(signals)
    
    # 保存信号数据到 JSON（供匹配器使用）
    signals_file = "signals_data.json"
    with open(signals_file, 'w', encoding='utf-8') as f:
        json.dump(signals, f, indent=2, default=str)
    
    print(f"[OK] 信号数据已保存: {signals_file}")
    
    # 保存回测结果
    results_file = "backtest_results.csv"
    df_results.to_csv(results_file, index=False, encoding='utf-8-sig')
    print(f"[OK] 回测结果已保存: {results_file}")
    
    # 关闭 MT5
    backtester.collector.shutdown()
    
    # 2. 加载历史交易记录
    print("\n阶段 2: 加载历史交易记录")
    print("-" * 60)
    
    matcher = SignalMatcher()
    csv_path = r"G:\其他计算机\租用笔记本\能量块\能量块龙虾进化\Tradingview策略\能量块V11_激进型]_ICMARKETS_XAUUSD_2026-03-10.csv"
    trades = matcher.load_historical_trades(csv_path)
    
    # 3. 匹配信号和交易
    print("\n阶段 3: 匹配信号和交易")
    print("-" * 60)
    
    matches = matcher.match_signals_to_trades(signals, trades)
    
    if len(matches) == 0:
        print("[ERROR] 没有找到匹配的信号和交易")
        print("\n可能原因:")
        print("1. 时间范围不重叠（回测 90 天 vs 历史交易时间）")
        print("2. 价格匹配容差太小")
        print("3. 箱体信号生成逻辑与实际策略不同")
        return
    
    # 保存匹配结果
    matches_file = "signal_trade_matches.csv"
    matches.to_csv(matches_file, index=False, encoding='utf-8-sig')
    print(f"[OK] 匹配结果已保存: {matches_file}")
    
    # 4. 分析 AI 过滤准确率
    print("\n阶段 4: 分析 AI 过滤准确率")
    print("-" * 60)
    
    stats, merged = matcher.analyze_ai_filter_accuracy(matches, df_results)
    
    # 打印分析结果
    print("\n" + "=" * 60)
    print("AI 过滤准确率分析")
    print("=" * 60)
    
    print(f"\n总匹配数: {stats['total_matches']}")
    
    print(f"\n【AI 保留的信号】")
    print(f"  数量: {stats['kept_signals']}")
    print(f"  盈利: {stats['kept_wins']}")
    print(f"  亏损: {stats['kept_losses']}")
    print(f"  胜率: {stats['kept_win_rate']:.2f}%")
    
    print(f"\n【AI 拒绝的信号】")
    print(f"  数量: {stats['rejected_signals']}")
    print(f"  盈利: {stats['rejected_wins']} (误删)")
    print(f"  亏损: {stats['rejected_losses']} (正确拒绝)")
    print(f"  亏损率: {stats['rejected_loss_rate']:.2f}%")
    
    print(f"\n【AI 过滤效果】")
    print(f"  准确率: {stats['accuracy']:.2f}%")
    print(f"    (保留盈利 + 拒绝亏损) / 总数")
    print(f"  误删率: {stats['false_rejection_rate']:.2f}%")
    print(f"    (拒绝了盈利信号)")
    print(f"  误留率: {stats['false_keep_rate']:.2f}%")
    print(f"    (保留了亏损信号)")
    
    # 保存分析结果
    analysis_file = "ai_filter_analysis.json"
    with open(analysis_file, 'w', encoding='utf-8') as f:
        json.dump(stats, f, indent=2)
    print(f"\n[OK] 分析结果已保存: {analysis_file}")
    
    # 保存合并数据
    merged_file = "merged_analysis.csv"
    merged.to_csv(merged_file, index=False, encoding='utf-8-sig')
    print(f"[OK] 合并数据已保存: {merged_file}")
    
    # 5. 生成详细报告
    print("\n阶段 5: 生成详细报告")
    print("-" * 60)
    
    report = []
    report.append("=" * 60)
    report.append("AI 过滤准确率分析报告")
    report.append("=" * 60)
    report.append("")
    report.append(f"生成时间: {pd.Timestamp.now()}")
    report.append(f"回测周期: {days} 天")
    report.append(f"交易品种: {symbol}")
    report.append("")
    
    report.append("## 1. 数据概览")
    report.append(f"- 箱体信号数: {len(signals)}")
    report.append(f"- 历史交易数: {len(trades)}")
    report.append(f"- 成功匹配数: {stats['total_matches']}")
    report.append("")
    
    report.append("## 2. AI 决策分布")
    report.append(f"- 保留信号: {stats['kept_signals']} ({stats['kept_signals']/stats['total_matches']*100:.1f}%)")
    report.append(f"- 拒绝信号: {stats['rejected_signals']} ({stats['rejected_signals']/stats['total_matches']*100:.1f}%)")
    report.append("")
    
    report.append("## 3. 保留信号质量")
    report.append(f"- 盈利交易: {stats['kept_wins']}")
    report.append(f"- 亏损交易: {stats['kept_losses']}")
    report.append(f"- 胜率: {stats['kept_win_rate']:.2f}%")
    report.append("")
    
    report.append("## 4. 拒绝信号质量")
    report.append(f"- 盈利交易 (误删): {stats['rejected_wins']}")
    report.append(f"- 亏损交易 (正确): {stats['rejected_losses']}")
    report.append(f"- 亏损率: {stats['rejected_loss_rate']:.2f}%")
    report.append("")
    
    report.append("## 5. AI 过滤效果评估")
    report.append(f"- 准确率: {stats['accuracy']:.2f}%")
    report.append(f"- 误删率: {stats['false_rejection_rate']:.2f}%")
    report.append(f"- 误留率: {stats['false_keep_rate']:.2f}%")
    report.append("")
    
    report.append("## 6. 结论")
    if stats['accuracy'] >= 70:
        report.append("[OK] AI 过滤效果优秀 (准确率 >= 70%)")
    elif stats['accuracy'] >= 60:
        report.append("[WARN] AI 过滤效果良好 (准确率 60-70%)")
    else:
        report.append("[ERROR] AI 过滤效果需要改进 (准确率 < 60%)")
    
    if stats['false_rejection_rate'] <= 20:
        report.append("[OK] 误删率可接受 (<= 20%)")
    else:
        report.append("[ERROR] 误删率过高 (> 20%)")
    
    report.append("")
    report.append("=" * 60)
    
    report_text = "\n".join(report)
    print("\n" + report_text)
    
    # 保存报告
    report_file = "AI_FILTER_ACCURACY_REPORT.txt"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report_text)
    print(f"\n[OK] 详细报告已保存: {report_file}")
    
    print("\n" + "=" * 60)
    print("完整信号匹配分析完成")
    print("=" * 60)

if __name__ == "__main__":
    main()
