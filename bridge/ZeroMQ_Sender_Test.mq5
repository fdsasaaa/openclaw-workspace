//+------------------------------------------------------------------+
//|                                        ZeroMQ_Sender_Test.mq5    |
//|                                  MT5 端 ZeroMQ 发送器（测试版）  |
//+------------------------------------------------------------------+
#property copyright "虾哥"
#property version   "1.00"
#property strict

// ZeroMQ 库引入
// 注意：需要先安装 MQL5 ZeroMQ 库
// 下载地址：https://github.com/dingmaotu/mql-zmq
#include <Zmq/Zmq.mqh>

//--- 输入参数
input string ZMQ_Server = "tcp://localhost:5555";  // ZeroMQ 服务器地址

//--- 全局变量
Context context("zeromq_test");
Socket socket(context, ZMQ_REQ);  // REQ = Request (客户端)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("✅ ZeroMQ 测试 EA 初始化...");
    
    // 连接到 Python ZeroMQ 服务器
    if(!socket.connect(ZMQ_Server))
    {
        Print("❌ 无法连接到 ZeroMQ 服务器: ", ZMQ_Server);
        return INIT_FAILED;
    }
    
    Print("✅ 成功连接到 ZeroMQ 服务器: ", ZMQ_Server);
    
    // 发送测试消息
    SendTestSignal();
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    socket.disconnect(ZMQ_Server);
    Print("✅ ZeroMQ 连接已关闭");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 每 10 秒发送一次测试信号
    static datetime last_send_time = 0;
    datetime current_time = TimeCurrent();
    
    if(current_time - last_send_time >= 10)
    {
        SendTestSignal();
        last_send_time = current_time;
    }
}

//+------------------------------------------------------------------+
//| 发送测试信号                                                      |
//+------------------------------------------------------------------+
void SendTestSignal()
{
    // 构造测试 JSON 消息
    string json_message = StringFormat(
        "{\"event\":\"BOX_NEW\",\"box_id\":%d,\"symbol\":\"%s\",\"upper\":%.2f,\"lower\":%.2f,\"score\":%.1f,\"timestamp\":\"%s\"}",
        (int)TimeCurrent(),  // 使用时间戳作为 box_id
        _Symbol,
        SymbolInfoDouble(_Symbol, SYMBOL_ASK) + 50 * _Point,  // 上边界
        SymbolInfoDouble(_Symbol, SYMBOL_BID) - 50 * _Point,  // 下边界
        85.0,  // 评分
        TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
    );
    
    Print("📤 发送信号: ", json_message);
    
    // 记录发送时间
    ulong send_time = GetMicrosecondCount();
    
    // 发送消息
    ZmqMsg request(json_message);
    if(!socket.send(request))
    {
        Print("❌ 发送失败");
        return;
    }
    
    // 接收响应
    ZmqMsg reply;
    if(!socket.recv(reply, true))  // true = 阻塞等待
    {
        Print("❌ 接收响应失败");
        return;
    }
    
    // 计算延迟
    ulong receive_time = GetMicrosecondCount();
    double latency_ms = (receive_time - send_time) / 1000.0;
    
    // 解析响应
    string response = reply.getData();
    Print("📥 收到响应: ", response);
    Print("⏱️  延迟: ", DoubleToString(latency_ms, 2), " ms");
    
    // 检查延迟是否满足要求
    if(latency_ms < 10.0)
    {
        Print("✅ 延迟合格 (< 10ms)");
    }
    else
    {
        Print("⚠️  延迟超标 (>= 10ms)");
    }
}

//+------------------------------------------------------------------+
