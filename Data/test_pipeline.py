"""
数据采集测试 - 完整流程测试
"""

import MetaTrader5 as mt5
from collector import DataCollector
from storage import DataStorage

def main():
    print("=" * 50)
    print("数据采集管道测试")
    print("=" * 50)
    
    # 初始化采集器
    collector = DataCollector()
    if not collector.initialize():
        print("MT5 初始化失败")
        return
    
    # 初始化存储
    storage = DataStorage("market_data.db")
    
    # 测试品种和周期
    symbol = "EURUSD"
    timeframe = mt5.TIMEFRAME_H1
    timeframe_name = "H1"
    
    print(f"\n测试品种: {symbol}")
    print(f"时间周期: {timeframe_name}")
    
    # 1. 采集市场数据
    print("\n[1/3] 采集市场数据...")
    df = collector.get_market_data(symbol, timeframe, 100)
    
    if df is None:
        print("数据采集失败")
        collector.shutdown()
        return
    
    print(f"采集完成: {len(df)} 根 K 线")
    
    # 2. 保存到数据库
    print("\n[2/3] 保存到数据库...")
    storage.save_klines(df, symbol, timeframe_name)
    storage.save_indicators(df, symbol, timeframe_name)
    
    # 3. 验证数据
    print("\n[3/3] 验证数据...")
    saved_klines = storage.get_latest_klines(symbol, timeframe_name, 5)
    saved_indicators = storage.get_latest_indicators(symbol, timeframe_name, 5)
    
    print(f"\n数据库中的 K 线数量: {len(saved_klines)}")
    print(f"数据库中的指标数量: {len(saved_indicators)}")
    
    # 显示最新数据
    print("\n最新 K 线数据:")
    print(saved_klines[['symbol', 'timeframe', 'timestamp', 'close']].head())
    
    print("\n最新指标数据:")
    print(saved_indicators[['symbol', 'timeframe', 'timestamp', 'atr', 'rsi']].head())
    
    # 关闭连接
    collector.shutdown()
    
    print("\n" + "=" * 50)
    print("测试完成!")
    print("=" * 50)

if __name__ == "__main__":
    main()
