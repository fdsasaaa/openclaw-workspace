# MT5 EA 修改实施计划

## 📋 目标
让 MT5 EA 和 TradingView 策略的交易逻辑完全一致

---

## 🔍 关键发现

### 1. EA 当前架构
```cpp
// EA 依赖外部指标 (nengliang.mq5)
string 指标名称 = "nengliang";
string 指标前缀 = "Rectangle";

// EA 通过 ObjectFind() 查找指标画出的 Rectangle 对象
// 然后读取箱体参数进行交易
```

**问题：**
- EA 不是自己识别箱体，而是读取指标画出的对象
- 指标和 EA 的参数可能不同步
- 回测时依赖图表对象，不够准确

---

## 🎯 修改方案

### 方案 A：EA 内置箱体识别（推荐）

**优点：**
1. 回测准确（不依赖图表对象）
2. 参数完全可控
3. 逻辑与 TradingView 完全一致

**缺点：**
1. 需要大量代码移植
2. 测试工作量大

---

### 方案 B：同步指标和 EA 参数（快速方案）

**优点：**
1. 改动较小
2. 保持现有架构

**缺点：**
1. 回测仍依赖图表对象
2. 参数同步容易出错

---

## 📝 推荐：方案 A（内置箱体识别）

### 实施步骤

#### 第一阶段：移植箱体识别逻辑

**1. 移植 Pivot 识别函数**
```cpp
// 从 nengliang.mq5 移植
double GetDarvasPivot(int index, bool isHigh, 
                      const double &high[], 
                      const double &low[], 
                      const double &close[]);
```

**2. 移植箱体状态机**
```cpp
// 状态机变量（已存在，需要确认逻辑）
struct StrategyState {
    int    startState;      // 0:Idle, 1:FoundTop, -1:FoundBtm
    int    confirmState;    // 0:Waiting, 1:Confirmed
    double boxTop_v;
    double boxBottom_v;
    datetime boxStartTime;
    bool   box_active;
    double box_top;
    double box_bottom;
    int    box_start_idx;
};
```

**3. 移植评分系统**
```cpp
// 7个评分函数（已存在，需要确认参数）
double ScoreFlatness(double aspectRatio, double heightATR);
double ScoreIndependence(...);
double ScoreSmoothness(double topR2, double btmR2, double spikeRatio);
double ScoreSpace(double atr, double height);
double ScoreVolume(...);
double ScoreTime(int bars);
double ScoreMicro(...);
```

---

#### 第二阶段：同步过滤条件

**1. 智能入场过滤（TradingView 有，EA 缺失）**
```cpp
// 需要添加
bool IsSmartEntryValid(double boxTop, double boxBottom) {
    // 成交量过滤
    double avgVolume = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, VOLUME_TICK);
    bool volumeOK = (volume[0] >= avgVolume * 1.3);  // MinVolumeRatio = 1.3
    
    // 箱体年龄过滤
    bool ageOK = (g_boxBars <= 30);  // MaxBoxAgeBars = 30
    
    // 波动率过滤
    double atr = iATR(_Symbol, PERIOD_CURRENT, 14, 0);
    double avgPrice = (boxTop + boxBottom) / 2.0;
    bool volatilityOK = (atr <= avgPrice * 0.02);  // ATR不超过价格的2%
    
    return volumeOK && ageOK && volatilityOK;
}
```

**2. 箱体高度过滤（TradingView 有，EA 缺失）**
```cpp
// 需要添加
bool IsBoxHeightValid(double boxHeight, int lookbackBars, double multiplierLimit) {
    // 计算箱体之前N根K线的平均高度
    double totalKlineHeight = 0.0;
    int validBars = 0;
    
    for(int i = 0; i < lookbackBars; i++) {
        int idx = g_boxBars + i;  // 从箱体外开始
        if(idx < Bars(_Symbol, PERIOD_CURRENT)) {
            double klineHeight = iHigh(_Symbol, PERIOD_CURRENT, idx) - 
                                 iLow(_Symbol, PERIOD_CURRENT, idx);
            totalKlineHeight += klineHeight;
            validBars++;
        }
    }
    
    if(validBars == 0) return true;
    
    double avgKlineHeight = totalKlineHeight / validBars;
    double maxAllowedBoxHeight = avgKlineHeight * multiplierLimit;  // 3.0
    
    return (boxHeight < maxAllowedBoxHeight);
}
```

**3. 冷却期机制（需要确认 EA 实现）**
```cpp
// EA 已有 g_nextTradeBar，需要确认逻辑是否与 TV 一致
// TradingView:
// CooldownBars = 6
// nextTradeBar = bar_index + CooldownBars
// bool inCooldown = bar_index <= nextTradeBar

// EA 需要确认：
// 1. 冷却期是否在马丁爆仓后触发？
// 2. 冷却期长度是否为 6 根K线？
```

---

#### 第三阶段：同步止损/止盈参数

**1. ATR 动态止损**
```cpp
// TradingView 参数
ATR_Period = 14
ATR_SL_Mult = 1.7  // 🔥 从2.0降到1.7（更紧止损）

// EA 当前参数（需要确认）
ATR周期 = 14
ATRֹ损倍数 = 2.0  // ❌ 需要改为 1.7

// 修改函数
double CalculateATRStopLoss(double entryPrice, double boxTop, double boxBottom, bool isLong) {
    double atr = iATR(_Symbol, PERIOD_CURRENT, 14, 0);
    double boxHeight = MathAbs(boxTop - boxBottom);
    double atrSL = atr * 1.7;  // 🔥 改为 1.7
    
    // 使用较大的止损距离
    double slDistance = MathMax(boxHeight, atrSL);
    
    return isLong ? entryPrice - slDistance : entryPrice + slDistance;
}
```

**2. 移动止盈参数**
```cpp
// TradingView 参数
TrailStartRatio = 85%   // 🔥 从65%提升到85%
TrailStepRatio  = 32%
TrailOffsetRatio= 45%   // 🔥 从32%提升到45%

// EA 当前参数（需要确认）
箱体高度触发倍数 = 0.65  // ❌ 需要改为 0.85
箱体高度步长倍数 = 0.32  // ✅ 一致
箱体高度回撤倍数 = 0.32  // ❌ 需要改为 0.45

// 修改移动止损函数
void CheckTrailingStop() {
    // ... 现有代码 ...
    
    // 修改触发条件
    double profitRatio = currentProfit / g_boxHeight;
    if(profitRatio >= 0.85) {  // 🔥 改为 85%
        // 计算新止损位
        double trailOffset = g_boxHeight * 0.45;  // 🔥 改为 45%
        // ... 其他逻辑 ...
    }
}
```

**3. 马丁格尔参数**
```cpp
// TradingView 参数
MartinMax = 1   // 🔥 最多1次（实际禁用马丁）
MartinMult = 1.4

// EA 当前参数
马丁最大次数 = 2  // ❌ 需要改为 1
马丁倍数 = 1.4    // ✅ 一致（但如果禁用马丁，这个参数无意义）

// 修改输入参数
input int MartinMax = 1;  // 🔥 改为 1
```

---

#### 第四阶段：同步评分阈值

**1. 最小评分阈值**
```cpp
// TradingView 参数
MinDisplayScore = 35  // 🔥 从20提升到35

// EA 当前参数
input double 箱体最低评分 = 20.0;  // ❌ 需要改为 35.0

// 修改
input double 箱体最低评分 = 35.0;  // 🔥 改为 35
```

---

#### 第五阶段：同步时间过滤

**1. 交易时间限制**
```cpp
// TradingView 默认
StratStartHour = 0
StratStartMin  = 0
StratEndHour   = 0
StratEndMin    = 0
// 00:00-00:00 代表 24/7 无限制

// EA 需要确认时间过滤逻辑是否一致
```

---

## 🧪 测试计划

### 第一步：单元测试
1. 测试箱体识别逻辑（对比指标画出的箱体）
2. 测试评分系统（对比 TradingView 评分）
3. 测试过滤条件（成交量、箱体高度、冷却期）

### 第二步：回测对比
1. 使用相同历史数据
2. 对比 EA 和 TradingView 的：
   - 入场点
   - 止损位
   - 止盈位
   - 交易次数
   - 盈亏结果

### 第三步：实盘验证
1. 小资金测试
2. 监控差异
3. 逐步调整

---

## 📊 参数对比表（需要修改的）

| 参数 | TradingView | EA 当前值 | 需要改为 |
|------|------------|----------|---------|
| 最小评分阈值 | 35 | 20 | 35 |
| ATR止损倍数 | 1.7 | 2.0 | 1.7 |
| 移动止盈触发 | 85% | 65% | 85% |
| 移动止盈回撤 | 45% | 32% | 45% |
| 马丁最大次数 | 1 | 2 | 1 |
| 成交量倍数 | 1.3 | 缺失 | 添加 |
| 箱体年龄限制 | 30 | 缺失 | 添加 |
| 箱体高度限制 | 3.0倍 | 缺失 | 添加 |

---

## 🤖 是否调用 Claude Code？

**建议：调用 Claude Code 协助**

原因：
1. 需要移植大量代码（箱体识别、评分系统）
2. 需要添加多个过滤函数
3. 需要修改多个参数
4. 代码量大，容易出错

**Claude Code 可以：**
1. 分析 EA 代码结构
2. 移植 TradingView 逻辑到 MQL5
3. 添加缺失的过滤条件
4. 同步所有参数
5. 生成测试代码

---

## 📝 下一步

**选择：**
- [ ] 我自己手动修改 EA 代码
- [ ] 调用 Claude Code 协助修改

**如果调用 Claude Code，我会：**
1. 准备完整的需求文档
2. 提供 TradingView 策略代码
3. 提供 MT5 EA 代码
4. 让 Claude Code 生成修改后的 EA

**你的决定？**

---

生成时间：2026-03-10 07:40
