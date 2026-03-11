# ZeroMQ 桥接测试指南

## 📋 测试目标

验证 MT5 和 Python 之间的 ZeroMQ 通信是否正常，延迟是否满足 < 10ms 的要求。

---

## 🔧 前置准备

### 1. 安装 Python 依赖

```bash
pip install pyzmq
```

✅ 已完成

### 2. 安装 MQL5 ZeroMQ 库

**下载地址：** https://github.com/dingmaotu/mql-zmq

**安装步骤：**
1. 下载 `mql-zmq` 仓库
2. 将 `MQL5/Include/Zmq` 文件夹复制到：
   ```
   C:\Users\ME\AppData\Roaming\MetaQuotes\Terminal\010E047102812FC0C18890992854220E\MQL5\Include\
   ```
3. 将 `MQL5/Libraries` 中的 DLL 文件复制到：
   ```
   C:\Users\ME\AppData\Roaming\MetaQuotes\Terminal\010E047102812FC0C18890992854220E\MQL5\Libraries\
   ```

---

## 🚀 测试步骤

### 步骤 1：启动 Python ZeroMQ 服务器

```bash
cd C:\OpenClaw_Workspace\workspace\bridge
python zeromq_bridge.py
```

**预期输出：**
```
✅ ZeroMQ 服务器启动成功，监听端口 5555
🚀 ZeroMQ 桥接服务器运行中...
等待 MT5 信号...
```

---

### 步骤 2：编译并运行 MT5 测试 EA

1. 打开 MetaEditor
2. 打开 `ZeroMQ_Sender_Test.mq5`
3. 编译（F7）
4. 在 MT5 中加载 EA 到任意图表

**预期输出（MT5 日志）：**
```
✅ ZeroMQ 测试 EA 初始化...
✅ 成功连接到 ZeroMQ 服务器: tcp://localhost:5555
📤 发送信号: {"event":"BOX_NEW",...}
📥 收到响应: {"decision":"BOTH",...}
⏱️  延迟: 2.35 ms
✅ 延迟合格 (< 10ms)
```

**预期输出（Python 日志）：**
```
📨 收到消息: {"event":"BOX_NEW",...}
🤖 AI 决策: event=BOX_NEW, box_id=1234567890
✅ 返回决策: BOTH
⏱️  延迟: 2.35 ms
```

---

## ✅ 验收标准

- [ ] Python 服务器成功启动
- [ ] MT5 EA 成功连接到 Python 服务器
- [ ] MT5 能够发送 JSON 消息
- [ ] Python 能够接收并解析 JSON
- [ ] Python 能够返回决策结果
- [ ] MT5 能够接收并解析响应
- [ ] **通信延迟 < 10ms**

---

## 🐛 常见问题

### 问题 1：MT5 无法连接到 ZeroMQ 服务器

**可能原因：**
- Python 服务器未启动
- 端口被占用
- 防火墙阻止

**解决方案：**
1. 确认 Python 服务器正在运行
2. 检查端口 5555 是否被占用：`netstat -ano | findstr 5555`
3. 临时关闭防火墙测试

---

### 问题 2：编译错误 - 找不到 Zmq.mqh

**原因：** MQL5 ZeroMQ 库未正确安装

**解决方案：**
1. 重新下载 `mql-zmq` 库
2. 确认文件路径正确
3. 重启 MetaEditor

---

### 问题 3：延迟超过 10ms

**可能原因：**
- 系统负载过高
- Python 代码效率低
- 网络问题（如果不是 localhost）

**解决方案：**
1. 关闭其他占用 CPU 的程序
2. 优化 Python 代码
3. 确认使用 localhost（不要用远程服务器）

---

## 📊 测试结果记录

| 测试项 | 状态 | 延迟 | 备注 |
|--------|------|------|------|
| Python 服务器启动 | ⏳ | - | 待测试 |
| MT5 连接成功 | ⏳ | - | 待测试 |
| 发送消息 | ⏳ | - | 待测试 |
| 接收响应 | ⏳ | - | 待测试 |
| 延迟测试 | ⏳ | - | 目标 < 10ms |

---

## 🎯 下一步

测试通过后：
1. 将 ZeroMQ 逻辑集成到主 EA（`Tradingview策略AI配合EA.mq5`）
2. 实现真正的 AI 决策逻辑（替换占位符）
3. 开始 Phase 1 的第二个任务：数据采集管道

---

*创建时间：2026-03-12 05:56*
*创建者：虾哥 🦐*
