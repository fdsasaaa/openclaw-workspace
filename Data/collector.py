"""
数据采集器 - 从 MT5 采集市场数据
"""

import MetaTrader5 as mt5
import pandas as pd
from datetime import datetime
import time

class DataCollector:
    def __init__(self):
        """初始化数据采集器"""
        self.initialized = False
        
    def initialize(self):
        """初始化 MT5 连接"""
        if not mt5.initialize():
            print(f"MT5 初始化失败，错误码: {mt5.last_error()}")
            return False
        
        print("MT5 连接成功")
        print(f"MT5 版本: {mt5.version()}")
        print(f"账户信息: {mt5.account_info()}")
        
        self.initialized = True
        return True
    
    def shutdown(self):
        """关闭 MT5 连接"""
        mt5.shutdown()
        print("MT5 连接已关闭")
    
    def get_klines(self, symbol, timeframe, count=100):
        """
        获取 K 线数据
        
        参数:
            symbol: 交易品种（如 "EURUSD"）
            timeframe: 时间周期（如 mt5.TIMEFRAME_H1）
            count: K 线数量
        
        返回:
            DataFrame: K 线数据
        """
        if not self.initialized:
            print("MT5 未初始化")
            return None
        
        # 获取 K 线数据
        rates = mt5.copy_rates_from_pos(symbol, timeframe, 0, count)
        
        if rates is None:
            print(f"获取 K 线失败: {symbol}, 错误码: {mt5.last_error()}")
            return None
        
        # 转换为 DataFrame
        df = pd.DataFrame(rates)
        df['time'] = pd.to_datetime(df['time'], unit='s')
        
        print(f"获取 {symbol} K 线数据: {len(df)} 根")
        return df
    
    def get_current_price(self, symbol):
        """
        获取当前价格
        
        返回:
            dict: {bid, ask, spread, time}
        """
        if not self.initialized:
            print("MT5 未初始化")
            return None
        
        tick = mt5.symbol_info_tick(symbol)
        
        if tick is None:
            print(f"获取价格失败: {symbol}")
            return None
        
        return {
            'symbol': symbol,
            'bid': tick.bid,
            'ask': tick.ask,
            'spread': tick.ask - tick.bid,
            'time': datetime.fromtimestamp(tick.time)
        }
    
    def calculate_atr(self, df, period=14):
        """
        计算 ATR（平均真实波幅）
        
        参数:
            df: K 线数据 DataFrame
            period: 周期
        
        返回:
            Series: ATR 值
        """
        high = df['high']
        low = df['low']
        close = df['close']
        
        # 计算真实波幅
        tr1 = high - low
        tr2 = abs(high - close.shift())
        tr3 = abs(low - close.shift())
        
        tr = pd.concat([tr1, tr2, tr3], axis=1).max(axis=1)
        
        # 计算 ATR
        atr = tr.rolling(window=period).mean()
        
        return atr
    
    def calculate_rsi(self, df, period=14):
        """
        计算 RSI（相对强弱指数）
        
        参数:
            df: K 线数据 DataFrame
            period: 周期
        
        返回:
            Series: RSI 值
        """
        close = df['close']
        
        # 计算价格变化
        delta = close.diff()
        
        # 分离上涨和下跌
        gain = delta.where(delta > 0, 0)
        loss = -delta.where(delta < 0, 0)
        
        # 计算平均上涨和下跌
        avg_gain = gain.rolling(window=period).mean()
        avg_loss = loss.rolling(window=period).mean()
        
        # 计算 RS 和 RSI
        rs = avg_gain / avg_loss
        rsi = 100 - (100 / (1 + rs))
        
        return rsi
    
    def calculate_ma(self, df, period=20):
        """
        计算移动平均线
        
        参数:
            df: K 线数据 DataFrame
            period: 周期
        
        返回:
            Series: MA 值
        """
        return df['close'].rolling(window=period).mean()
    
    def get_market_data(self, symbol, timeframe=mt5.TIMEFRAME_H1, count=100):
        """
        获取完整的市场数据（K线 + 指标）
        
        返回:
            DataFrame: 包含 K 线和指标的完整数据
        """
        # 获取 K 线
        df = self.get_klines(symbol, timeframe, count)
        
        if df is None:
            return None
        
        # 计算指标
        df['atr'] = self.calculate_atr(df)
        df['rsi'] = self.calculate_rsi(df)
        df['ma20'] = self.calculate_ma(df, 20)
        df['ma50'] = self.calculate_ma(df, 50)
        
        print(f"计算指标完成: ATR, RSI, MA20, MA50")
        
        return df

# 测试代码
if __name__ == "__main__":
    collector = DataCollector()
    
    if collector.initialize():
        # 测试获取 K 线数据
        df = collector.get_market_data("EURUSD", mt5.TIMEFRAME_H1, 100)
        
        if df is not None:
            print("\n最新 5 根 K 线:")
            print(df[['time', 'open', 'high', 'low', 'close', 'atr', 'rsi']].tail())
        
        # 测试获取当前价格
        price = collector.get_current_price("EURUSD")
        if price:
            print(f"\n当前价格: Bid={price['bid']}, Ask={price['ask']}, Spread={price['spread']:.5f}")
        
        collector.shutdown()
