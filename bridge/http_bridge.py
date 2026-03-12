"""
HTTP Bridge - Python 端接收器（替代 ZeroMQ）
接收 MT5 通过 HTTP POST 发送的信号，调用 AI 决策模块，返回决策结果
"""

from flask import Flask, request, jsonify
from datetime import datetime
import time

app = Flask(__name__)

def ai_decision(signal_data):
    """
    AI 决策模块（占位符）
    
    输入：信号数据（箱体信息、市场状态等）
    输出：决策结果（LONG_ONLY/SHORT_ONLY/BOTH/NONE）
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

@app.route('/signal', methods=['POST'])
def receive_signal():
    """接收 MT5 信号的 HTTP 端点"""
    try:
        receive_time = time.time()
        
        # 解析 JSON
        signal_data = request.get_json()
        
        print(f"\n📨 收到消息: {signal_data}")
        
        # 调用 AI 决策
        decision_result = ai_decision(signal_data)
        
        send_time = time.time()
        latency = (send_time - receive_time) * 1000  # 转换为毫秒
        
        print(f"✅ 返回决策: {decision_result['decision']}")
        print(f"⏱️  延迟: {latency:.2f} ms")
        
        return jsonify(decision_result), 200
        
    except Exception as e:
        print(f"❌ 错误: {e}")
        return jsonify({
            "decision": "NONE",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

if __name__ == "__main__":
    print("✅ HTTP 服务器启动成功，监听端口 5556")
    print("🚀 HTTP 桥接服务器运行中...")
    print("等待 MT5 信号...")
    app.run(host='0.0.0.0', port=5556, debug=False)
