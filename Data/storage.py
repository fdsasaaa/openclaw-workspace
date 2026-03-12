"""
数据存储 - 将市场数据存储到 SQLite
"""

import sqlite3
import pandas as pd
from datetime import datetime

class DataStorage:
    def __init__(self, db_path="market_data.db"):
        """初始化数据存储"""
        self.db_path = db_path
        self.conn = None
        self.create_tables()
    
    def connect(self):
        """连接数据库"""
        self.conn = sqlite3.connect(self.db_path)
        return self.conn
    
    def close(self):
        """关闭数据库连接"""
        if self.conn:
            self.conn.close()
    
    def create_tables(self):
        """创建数据表"""
        conn = self.connect()
        cursor = conn.cursor()
        
        # K 线数据表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS klines (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                symbol TEXT NOT NULL,
                timeframe TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                open REAL NOT NULL,
                high REAL NOT NULL,
                low REAL NOT NULL,
                close REAL NOT NULL,
                volume INTEGER NOT NULL,
                tick_volume INTEGER,
                spread INTEGER,
                UNIQUE(symbol, timeframe, timestamp)
            )
        ''')
        
        # 指标数据表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS indicators (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                symbol TEXT NOT NULL,
                timeframe TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                atr REAL,
                rsi REAL,
                ma20 REAL,
                ma50 REAL,
                UNIQUE(symbol, timeframe, timestamp)
            )
        ''')
        
        # 市场状态表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS market_state (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                symbol TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                bid REAL NOT NULL,
                ask REAL NOT NULL,
                spread REAL NOT NULL
            )
        ''')
        
        conn.commit()
        self.close()
        print("数据表创建完成")
    
    def save_klines(self, df, symbol, timeframe):
        """
        保存 K 线数据
        
        参数:
            df: K 线数据 DataFrame
            symbol: 交易品种
            timeframe: 时间周期
        """
        conn = self.connect()
        
        for _, row in df.iterrows():
            try:
                conn.execute('''
                    INSERT OR REPLACE INTO klines 
                    (symbol, timeframe, timestamp, open, high, low, close, volume, tick_volume, spread)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    symbol,
                    timeframe,
                    int(row['time'].timestamp()),
                    row['open'],
                    row['high'],
                    row['low'],
                    row['close'],
                    row['real_volume'],
                    row['tick_volume'],
                    row['spread']
                ))
            except Exception as e:
                print(f"保存 K 线失败: {e}")
        
        conn.commit()
        self.close()
        print(f"保存 {len(df)} 根 K 线到数据库")
    
    def save_indicators(self, df, symbol, timeframe):
        """
        保存指标数据
        
        参数:
            df: 包含指标的 DataFrame
            symbol: 交易品种
            timeframe: 时间周期
        """
        conn = self.connect()
        
        for _, row in df.iterrows():
            try:
                conn.execute('''
                    INSERT OR REPLACE INTO indicators 
                    (symbol, timeframe, timestamp, atr, rsi, ma20, ma50)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ''', (
                    symbol,
                    timeframe,
                    int(row['time'].timestamp()),
                    row.get('atr'),
                    row.get('rsi'),
                    row.get('ma20'),
                    row.get('ma50')
                ))
            except Exception as e:
                print(f"保存指标失败: {e}")
        
        conn.commit()
        self.close()
        print(f"保存 {len(df)} 条指标数据到数据库")
    
    def get_latest_klines(self, symbol, timeframe, count=100):
        """
        获取最新的 K 线数据
        
        返回:
            DataFrame: K 线数据
        """
        conn = self.connect()
        
        query = '''
            SELECT * FROM klines 
            WHERE symbol = ? AND timeframe = ?
            ORDER BY timestamp DESC
            LIMIT ?
        '''
        
        df = pd.read_sql_query(query, conn, params=(symbol, timeframe, count))
        self.close()
        
        return df
    
    def get_latest_indicators(self, symbol, timeframe, count=100):
        """
        获取最新的指标数据
        
        返回:
            DataFrame: 指标数据
        """
        conn = self.connect()
        
        query = '''
            SELECT * FROM indicators 
            WHERE symbol = ? AND timeframe = ?
            ORDER BY timestamp DESC
            LIMIT ?
        '''
        
        df = pd.read_sql_query(query, conn, params=(symbol, timeframe, count))
        self.close()
        
        return df

# 测试代码
if __name__ == "__main__":
    storage = DataStorage("test_market_data.db")
    print("数据存储模块测试完成")
