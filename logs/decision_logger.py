"""
决策日志系统 - 记录 AI 决策过程
"""

import json
import sqlite3
from datetime import datetime

class DecisionLogger:
    def __init__(self, db_path="decision_log.db"):
        """初始化决策日志系统"""
        self.db_path = db_path
        self.create_table()
    
    def create_table(self):
        """创建决策日志表"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS decision_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp INTEGER NOT NULL,
                box_id INTEGER NOT NULL,
                symbol TEXT NOT NULL,
                event_type TEXT NOT NULL,
                market_data TEXT,
                ai_decision TEXT NOT NULL,
                decision_reason TEXT,
                execution_result TEXT,
                latency_ms REAL
            )
        ''')
        
        conn.commit()
        conn.close()
        print("决策日志表创建完成")
    
    def log_decision(self, box_id, symbol, event_type, market_data, ai_decision, 
                     decision_reason=None, execution_result=None, latency_ms=None):
        """
        记录一次 AI 决策
        
        参数:
            box_id: 箱体 ID
            symbol: 交易品种
            event_type: 事件类型（BOX_NEW, PENDING_LONG_READY 等）
            market_data: 市场数据（dict）
            ai_decision: AI 决策结果（LONG_ONLY/SHORT_ONLY/BOTH/NONE）
            decision_reason: 决策原因
            execution_result: 执行结果
            latency_ms: 延迟（毫秒）
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO decision_log 
            (timestamp, box_id, symbol, event_type, market_data, ai_decision, 
             decision_reason, execution_result, latency_ms)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            int(datetime.now().timestamp()),
            box_id,
            symbol,
            event_type,
            json.dumps(market_data) if market_data else None,
            ai_decision,
            decision_reason,
            execution_result,
            latency_ms
        ))
        
        conn.commit()
        conn.close()
        print(f"决策已记录: box_id={box_id}, decision={ai_decision}")
    
    def get_recent_decisions(self, limit=10):
        """
        获取最近的决策记录
        
        返回:
            list: 决策记录列表
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT * FROM decision_log 
            ORDER BY timestamp DESC 
            LIMIT ?
        ''', (limit,))
        
        rows = cursor.fetchall()
        conn.close()
        
        return rows
    
    def get_statistics(self):
        """
        获取决策统计
        
        返回:
            dict: 统计数据
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # 总决策数
        cursor.execute('SELECT COUNT(*) FROM decision_log')
        total = cursor.fetchone()[0]
        
        # 各决策类型数量
        cursor.execute('''
            SELECT ai_decision, COUNT(*) 
            FROM decision_log 
            GROUP BY ai_decision
        ''')
        decision_counts = dict(cursor.fetchall())
        
        # 平均延迟
        cursor.execute('SELECT AVG(latency_ms) FROM decision_log WHERE latency_ms IS NOT NULL')
        avg_latency = cursor.fetchone()[0]
        
        conn.close()
        
        return {
            'total_decisions': total,
            'decision_counts': decision_counts,
            'avg_latency_ms': avg_latency
        }

# 测试代码
if __name__ == "__main__":
    logger = DecisionLogger("test_decision_log.db")
    
    # 测试记录决策
    logger.log_decision(
        box_id=12345,
        symbol="EURUSD",
        event_type="BOX_NEW",
        market_data={
            "price": 1.1540,
            "atr": 0.0016,
            "rsi": 45.5
        },
        ai_decision="BOTH",
        decision_reason="市场波动适中，允许双边挂单",
        latency_ms=20.5
    )
    
    # 获取统计
    stats = logger.get_statistics()
    print("\n决策统计:")
    print(f"总决策数: {stats['total_decisions']}")
    print(f"决策分布: {stats['decision_counts']}")
    print(f"平均延迟: {stats['avg_latency_ms']:.2f} ms")
    
    print("\n决策日志系统测试完成")
