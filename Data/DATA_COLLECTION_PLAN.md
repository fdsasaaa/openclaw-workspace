# Phase 1 任务 2：数据采集管道

## 🎯 目标

采集 MT5 市场数据，为 AI 决策提供输入。

---

## 📋 需要采集的数据

### 1. K 线数据（OHLCV）
- Open（开盘价）
- High（最高价）
- Low（最低价）
- Close（收盘价）
- Volume（成交量）
- 时间周期：M1, M5, M15, H1, H4, D1

### 2. 技术指标数据
- ATR（平均真实波幅）
- RSI（相对强弱指数）
- MACD（指数平滑异同移动平均线）
- MA（移动平均线）
- Bollinger Bands（布林带）

### 3. 市场状态
- 当前价格（Bid/Ask）
- 点差（Spread）
- 波动率
- 趋势方向

---

## 🔧 实现方案

### 方案 A：MT5 Python API（推荐）

**优点：**
- 直接访问 MT5 数据
- 实时数据
- 官方支持

**缺点：**
- 需要 MT5 运行
- 仅限本地

**实现：**
```python
import MetaTrader5 as mt5

# 初始化
mt5.initialize()

# 获取 K 线数据
rates = mt5.copy_rates_from_pos("EURUSD", mt5.TIMEFRAME_H1, 0, 100)

# 获取指标数据
atr = mt5.copy_buffer_from_pos("ATR", 0, "EURUSD", mt5.TIMEFRAME_H1, 0, 100)
```

---

### 方案 B：通过 EA 发送数据

**优点：**
- 与现有桥接集成
- 可以自定义数据格式

**缺点：**
- 需要修改 EA
- 数据量大时效率低

---

## 📊 数据存储

### SQLite 数据库

**表结构：**

```sql
-- K 线数据表
CREATE TABLE klines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    symbol TEXT NOT NULL,
    timeframe TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    open REAL NOT NULL,
    high REAL NOT NULL,
    low REAL NOT NULL,
    close REAL NOT NULL,
    volume INTEGER NOT NULL,
    UNIQUE(symbol, timeframe, timestamp)
);

-- 指标数据表
CREATE TABLE indicators (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    symbol TEXT NOT NULL,
    timeframe TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    indicator_name TEXT NOT NULL,
    value REAL NOT NULL,
    UNIQUE(symbol, timeframe, timestamp, indicator_name)
);

-- 市场状态表
CREATE TABLE market_state (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    symbol TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    bid REAL NOT NULL,
    ask REAL NOT NULL,
    spread REAL NOT NULL,
    volatility REAL,
    trend TEXT
);
```

---

## 🚀 实施步骤

1. **安装 MetaTrader5 Python 库**
   ```bash
   pip install MetaTrader5
   ```

2. **创建数据采集器**
   - `data/collector.py` - 主采集器
   - `data/storage.py` - 数据存储
   - `data/indicators.py` - 指标计算

3. **测试数据采集**
   - 采集 EURUSD H1 最近 100 根 K 线
   - 计算 ATR, RSI, MACD
   - 存储到 SQLite

4. **集成到桥接系统**
   - AI 决策时查询最新数据
   - 实时更新数据

---

## ✅ 验收标准

- [ ] 成功采集 K 线数据
- [ ] 成功计算技术指标
- [ ] 数据存储到 SQLite
- [ ] 数据质量检查通过
- [ ] 查询性能 < 100ms

---

*创建时间：2026-03-12 08:26*
*创建者：虾哥 🦐*
