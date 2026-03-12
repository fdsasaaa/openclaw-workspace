"""
文件桥接 - Python 端（集成规则引擎）
使用 watchdog 实时监听文件变化，降低延迟
"""

import os
import json
import time
import sys
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# 添加路径
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'logs'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'ai'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'data'))

from decision_logger import DecisionLogger
from rule_engine import RuleEngine
from collector import DataCollector
import MetaTrader5 as mt5

# MT5 文件目录
MT5_FILES_DIR = r"C:\Users\ME\AppData\Roaming\MetaQuotes\Terminal\010E047102812FC0C18890992854220E\MQL5\Files"
REQUEST_FILE = os.path.join(MT5_FILES_DIR, "bridge_request.json")
RESPONSE_FILE = os.path.join(MT5_FILES_DIR, "bridge_response.json")

# 初始化组件
logger = DecisionLogger(os.path.join(os.path.dirname(__file__), '..', 'logs', 'decision_log.db'))
rule_engine = RuleEngine()
data_collector = DataCollector()

def get_market_data(symbol, timeframe=mt5.TIMEFRAME_H1):
    """
    获取市场数据
    
    参数:
        symbol: 交易品种
        timeframe: 时间周期
    
    返回:
        市场数据字典
    """
    try:
        # 获取完整市场数据
        df = data_collector.get_market_data(symbol, timeframe, 100)
        
        if df is None or len(df) == 0:
            return None
        
        # 获取最新数据
        latest = df.iloc[-1]
        
        # 计算平均值
        atr_avg = df['atr'].mean()
        volume_avg = df['real_volume'].mean()
        
        return {
            'symbol': symbol,
            'close': latest['close'],
            'price': latest['close'],
            'ma20': latest['ma20'],
            'ma50': latest['ma50'],
            'atr': latest['atr'],
            'atr_avg': atr_avg,
            'rsi': latest['rsi'],
            'volume': latest['real_volume'],
            'volume_avg': volume_avg,
            'timestamp': latest['time'].timestamp()
        }
    except Exception as e:
        print(f"获取市场数据失败: {e}")
        return None

def ai_decision(signal_data):
    """
    AI 决策模块（使用规则引擎）
    """
    event_type = signal_data.get("event", "")
    box_id = signal_data.get("box_id", 0)
    symbol = signal_data.get("symbol", "")
    
    print(f"\nAI 决策: event={event_type}, box_id={box_id}, symbol={symbol}")
    
    # 获取市场数据
    market_data = get_market_data(symbol)
    
    if market_data is None:
        print("市场数据获取失败，使用默认决策")
        decision = "BOTH"
        reason = "市场数据不可用"
    else:
        # 添加箱体信息
        market_data['box_upper'] = signal_data.get('upper', 0)
        market_data['box_lower'] = signal_data.get('lower', 0)
        market_data['box_score'] = signal_data.get('score', 0)
        
        # 应用规则引擎
        result = rule_engine.decide(market_data)
        decision = result['decision']
        reason = f"粗筛: {result['coarse_reason']}, 精筛: {result['fine_reason']}"
        
        print(f"规则引擎决策: {decision}")
        print(f"决策原因: {reason}")
    
    # 记录决策日志
    logger.log_decision(
        box_id=box_id,
        symbol=symbol,
        event_type=event_type,
        market_data=market_data,
        ai_decision=decision,
        decision_reason=reason
    )
    
    return {
        "decision": decision,
        "box_id": box_id,
        "timestamp": datetime.now().isoformat()
    }, reason

def process_request():
    """处理请求文件"""
    start_time = time.time()
    
    try:
        # 等待文件完全写入
        time.sleep(0.001)
        
        # 读取请求文件
        with open(REQUEST_FILE, 'r', encoding='ansi') as f:
            request_data = f.read()
        
        print(f"\n收到消息: {request_data}")
        
        # 删除请求文件
        os.remove(REQUEST_FILE)
        
        # 解析 JSON
        signal_data = json.loads(request_data)
        
        # 调用 AI 决策
        decision_result, reason = ai_decision(signal_data)
        
        # 写入响应文件
        with open(RESPONSE_FILE, 'w', encoding='ansi') as f:
            f.write(json.dumps(decision_result))
        
        # 计算延迟
        latency_ms = (time.time() - start_time) * 1000
        
        print(f"返回决策: {decision_result['decision']}")
        print(f"处理延迟: {latency_ms:.2f} ms")
        
    except Exception as e:
        print(f"错误: {e}")
        # 写入错误响应
        try:
            error_response = {
                "decision": "NONE",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            with open(RESPONSE_FILE, 'w', encoding='ansi') as f:
                f.write(json.dumps(error_response))
        except:
            pass

class RequestFileHandler(FileSystemEventHandler):
    """文件监听处理器"""
    
    def on_created(self, event):
        """文件创建时触发"""
        if event.src_path.endswith("bridge_request.json"):
            print(f"检测到请求文件")
            process_request()

def main():
    print("=" * 60)
    print("文件桥接服务器启动（集成规则引擎）")
    print("=" * 60)
    print(f"监听目录: {MT5_FILES_DIR}")
    
    # 初始化 MT5 连接
    if data_collector.initialize():
        print("MT5 连接成功")
    else:
        print("警告: MT5 连接失败，将使用默认决策")
    
    print("等待 MT5 信号...")
    print("=" * 60)
    
    # 确保目录存在
    os.makedirs(MT5_FILES_DIR, exist_ok=True)
    
    # 清理旧文件
    if os.path.exists(REQUEST_FILE):
        os.remove(REQUEST_FILE)
    if os.path.exists(RESPONSE_FILE):
        os.remove(RESPONSE_FILE)
    
    # 创建文件监听器
    event_handler = RequestFileHandler()
    observer = Observer()
    observer.schedule(event_handler, MT5_FILES_DIR, recursive=False)
    observer.start()
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n收到中断信号，正在关闭...")
        observer.stop()
        data_collector.shutdown()
    
    observer.join()
    print("文件桥接服务器已关闭")

if __name__ == "__main__":
    main()
