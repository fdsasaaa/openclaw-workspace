"""
ZeroMQ Bridge - Python 端接收器
接收 MT5 发送的信号，调用 AI 决策模块，返回决策结果
"""

import zmq
import json
import time
from datetime import datetime

class ZeroMQBridge:
    def __init__(self, port=5555):
        """初始化 ZeroMQ 桥接"""
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.REP)  # REP = Reply (服务端)
        self.socket.bind(f"tcp://*:{port}")
        print(f"✅ ZeroMQ 服务器启动成功，监听端口 {port}")
        
    def ai_decision(self, signal_data):
        """
        AI 决策模块（占位符）
        
        输入：信号数据（箱体信息、市场状态等）
        输出：决策结果（LONG_ONLY/SHORT_ONLY/BOTH/NONE）
        """
        # TODO: 实现真正的 AI 决策逻辑
        # 目前返回默认值 BOTH（允许双边挂单）
        
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
    
    def run(self):
        """运行 ZeroMQ 服务器"""
        print("🚀 ZeroMQ 桥接服务器运行中...")
        print("等待 MT5 信号...")
        
        while True:
            try:
                # 接收 MT5 发送的消息
                message = self.socket.recv_string()
                receive_time = time.time()
                
                print(f"\n📨 收到消息: {message[:100]}...")
                
                # 解析 JSON
                signal_data = json.loads(message)
                
                # 调用 AI 决策
                decision_result = self.ai_decision(signal_data)
                
                # 返回决策结果
                response = json.dumps(decision_result)
                self.socket.send_string(response)
                
                send_time = time.time()
                latency = (send_time - receive_time) * 1000  # 转换为毫秒
                
                print(f"✅ 返回决策: {decision_result['decision']}")
                print(f"⏱️  延迟: {latency:.2f} ms")
                
            except KeyboardInterrupt:
                print("\n⚠️  收到中断信号，正在关闭...")
                break
            except Exception as e:
                print(f"❌ 错误: {e}")
                # 返回错误响应
                error_response = json.dumps({
                    "decision": "NONE",
                    "error": str(e),
                    "timestamp": datetime.now().isoformat()
                })
                self.socket.send_string(error_response)
        
        # 清理资源
        self.socket.close()
        self.context.term()
        print("✅ ZeroMQ 服务器已关闭")

if __name__ == "__main__":
    bridge = ZeroMQBridge(port=5555)
    bridge.run()
