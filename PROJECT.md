# PROJECT.md - 项目状态

## 🎯 当前主线任务

**AI 辅助交易信号过滤系统 - Phase 1 基础设施**

**下一步行动**：实现 MT5-Python ZeroMQ 桥接

---

## 📊 项目概览

### 核心目标
通过 AI 过滤 TradingView 策略信号，提升交易质量和盈利能力

### 当前阶段
**Phase 1: 基础设施搭建** - 实现 MT5-Python 通信和数据采集

### 进度
- ✅ TradingView → EA 桥接完成（Webhook）
- ✅ EA AI 决策框架完成
- ⏳ MT5-Python ZeroMQ 桥接（进行中）
- ⏸️ 数据采集管道（待开始）
- ⏸️ 决策日志系统（待开始）

---

## 🔥 当前能力

### 已完成
- ✅ TradingView Webhook → EA 通信
- ✅ EA 状态维护（box, pending）
- ✅ AI 决策逻辑框架（LONG_ONLY/SHORT_ONLY/BOTH/NONE）
- ✅ JSON 解析和编码统一（ANSI）
- ✅ 完整测试流程验证

### 进行中
- ⏳ MT5-Python ZeroMQ 桥接

### 待开始
- ⏸️ 数据采集管道
- ⏸️ 决策日志系统
- ⏸️ 规则引擎 V1
- ⏸️ 机器学习 V2

---

## 🚀 5 阶段实施计划

### Phase 1: 基础设施（2周）⏳ 30%

**目标：** 搭建 MT5-Python 通信桥梁和数据采集系统

**核心任务：**
1. MT5-Python 桥接（ZeroMQ）
2. 数据采集管道
3. 决策日志系统

**验收标准：**
- ✅ 通信延迟 < 10ms
- ✅ 日志完整记录

---

### Phase 2: 规则引擎 V1（3周）⏸️ 0%

**目标：** 实现基于规则的信号过滤

**核心任务：**
1. 粗筛规则（趋势、波动率、成交量）
2. 精筛规则（支撑阻力、形态识别）
3. 离线回测框架

**验收标准：**
- ✅ 过滤准确率 > 60%
- ✅ 误删率 < 20%

---

### Phase 3: 模拟盘验证（2周）⏸️ 0%

**目标：** 在模拟环境验证系统稳定性

**核心任务：**
1. EA 集成
2. 实时监控
3. 异常处理

**验收标准：**
- ✅ 稳定运行 2 周
- ✅ 无系统故障

---

### Phase 4: 机器学习 V2（4周）⏸️ 0%

**目标：** 用机器学习替代规则引擎

**核心任务：**
1. 特征工程
2. XGBoost 训练
3. A/B 测试

**验收标准：**
- ✅ 过滤准确率 > 70%
- ✅ 净利润提升 > 20%

---

### Phase 5: 系统增强（持续）⏸️ 0%

**目标：** 持续优化和功能扩展

**核心任务：**
1. 订单流接入
2. 动态仓位
3. 组合风控

**验收标准：**
- ✅ 胜率 > 60%
- ✅ 回撤 < 15%

---

## 📁 项目文件

### 核心文档
- `AI_TRADING_ROADMAP.md` - 5 阶段实施路线图
- `TASKS.md` - 任务清单
- `PROJECT.md` - 本文件

### 代码文件
- `bridge/webhook_receiver.py` - Webhook 接收器（已完成）
- `bridge/zeromq_bridge.py` - ZeroMQ 桥接（待实现）
- `Tradingview策略AI配合EA.mq5` - EA 文件（已完成）

### 测试文件
- `bridge/test_single_event.py` - 单次测试
- `bridge/test_pending.py` - PENDING 事件测试

---

## 🎯 最近完成事项

### 2026-03-12
- ✅ 创建 AI 交易系统实施路线图
- ✅ 更新 TASKS.md 和 PROJECT.md
- ✅ 明确 Phase 1 任务

### 2026-03-11
- ✅ TradingView + MT5 EA 集成完成
- ✅ 桥接层打通（Webhook + JSON）
- ✅ AI 决策逻辑框架实现

### 2026-03-10
- ✅ MT5 EA 与 TradingView 策略同步
- ✅ EA 参数修改和回测验证

---

## 🚧 当前阻塞点

**无阻塞** - Phase 1 任务清晰，可以立即开始

---

## 💡 下一步建议

**立即开始（Phase 1）：**

1. **安装 ZeroMQ**
   ```bash
   pip install pyzmq
   ```

2. **创建 MT5 ZeroMQ 发送器**
   - 修改 EA，添加 ZeroMQ 发送逻辑
   - 发送箱体信号、挂单信号、市场数据

3. **创建 Python ZeroMQ 接收器**
   - 接收 MT5 信号
   - 调用 AI 决策模块
   - 返回决策结果

4. **测试通信延迟**
   - 目标：< 10ms

---

## 📊 技术栈

**已确定：**
- TradingView Pine Script（策略）
- MT5 MQL5（EA）
- Python（AI 决策）
- ZeroMQ（通信）
- SQLite（数据存储）
- XGBoost（机器学习）

**待确定：**
- 特征工程方案
- 回测框架选择
- 监控工具

---

*最后更新：2026-03-12 05:56*
*更新者：虾哥 🦐*
