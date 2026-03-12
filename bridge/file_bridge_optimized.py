"""
文件桥接 - Python 端（优化版）
使用 watchdog 实时监听文件变化，降低延迟
"""

import os
import json
import time
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# MT5 文件目录
MT5_FILES_DIR = r"C:\Users\ME\AppData\Roaming\MetaQuotes\Terminal\010E047102812FC0C18890992854220E\MQL5\Files"
REQUEST_FILE = os.path.join(MT5_FILES_DIR, "bridge_request.json")
RESPONSE_FILE = os.path.join(MT5_FILES_DIR, "bridge_response.json")

def ai_decision(signal_data):
    """
    AI 决策模块（占位符）
    """
    event_type = signal_data.get("event", "")
    box_id = signal_data.get("box_id", 0)
    
    print(f"🤖 AI 决策: event={event_type}, box_id={box_id}")
    
    # 默认决策：允许双边挂单
    decision = "BOTH"
    
    return {
        "decision": decision,
        "box_id": box_id,
        "timestamp": datetime.now().isoformat()
    }

def process_request():
    """处理请求文件"""
    try:
        # 等待文件完全写入（避免读取不完整）
        time.sleep(0.001)  # 1ms
        
        # 读取请求文件
        with open(REQUEST_FILE, 'r', encoding='ansi') as f:
            request_data = f.read()
        
        print(f"\n📨 收到消息: {request_data}")
        
        # 删除请求文件
        os.remove(REQUEST_FILE)
        
        # 解析 JSON
        signal_data = json.loads(request_data)
        
        # 调用 AI 决策
        decision_result = ai_decision(signal_data)
        
        # 写入响应文件
        with open(RESPONSE_FILE, 'w', encoding='ansi') as f:
            f.write(json.dumps(decision_result))
        
        print(f"✅ 返回决策: {decision_result['decision']}")
        
    except Exception as e:
        print(f"❌ 错误: {e}")
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
            print(f"⚡ 检测到请求文件")
            process_request()

def main():
    print("✅ 文件桥接服务器启动成功（优化版 - 实时监听）")
    print(f"📁 监听目录: {MT5_FILES_DIR}")
    print("🚀 等待 MT5 信号...")
    
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
        print("\n⚠️  收到中断信号，正在关闭...")
        observer.stop()
    
    observer.join()
    print("✅ 文件桥接服务器已关闭")

if __name__ == "__main__":
    main()
