# 任务：修改 MT5 EA 使其与 TradingView 策略完全一致

## 🎯 任务目标

修改 MT5 EA 代码，使其交易逻辑与 TradingView Pine Script 策略完全一致。

---

## 📁 相关文件

1. **TradingView 策略**：`C:\OpenClaw_Workspace\workspace\tradingview_strategy_v11.pine`
2. **MT5 EA**：`G:\其他计算机\租用笔记本\能量块\能量块龙虾进化\MT5\27版本.mq5`
3. **MT5 指标**：`G:\其他计算机\租用笔记本\能量块\能量块龙虾进化\MT5\nengliang.mq5`
4. **差异分析**：`C:\OpenClaw_Workspace\workspace\EA_vs_TV_Strategy_Analysis.md`
5. **修改计划**：`C:\OpenClaw_Workspace\workspace\EA_Modification_Plan.md`

---

## 🔧 核心修改任务

### 1. 架构改造：EA 内置箱体识别

**当前问题：**
EA 依赖外部指标 `nengliang.mq5` 画出的 Rectangle 对象，通过 `ObjectFind()` 读取箱体参数。

**目标：**
将 `nengliang.mq5` 的箱体识别逻辑完整移植到 EA 内部，让 EA 自己计算箱体。

**需要移植的代码：**

#### 1.1 Pivot 识别函数
```cpp
// 从 nengliang.mq5 移植
double GetDarvasPivot(int index, bool isHigh, 
                      const double &high[], 
                      const double &low[], 
                      const double &close[]);
```

#### 1.2 箱体状态机
```cpp
// 状态机逻辑（参考 TradingView 和 nengliang.mq5）
// 状态：0=Idle, 1=FoundTop, -1=FoundBtm
// 确认状态：0=Waiting, 1=Confirmed
```

#### 1.3 箱体参数计算
```cpp
// 计算箱体的：
// - box_top, box_bottom
// - box_bars (K线数量)
// - box_height (高度)
// - box_touchesTop, box_touchesBottom (触碰次数)
// - box_spikeRatio (刺透比例)
// - box_topR2, box_bottomR2 (R2值)
```

#### 1.4 评分系统（7个维度）
```cpp
// 确保这7个函数与 TradingView 完全一致
double ScoreFlatness(double aspectRatio, double heightATR);
double ScoreIndependence(...);
double ScoreSmoothness(double topR2, double btmR2, double spikeRatio);
double ScoreSpace(double atr, double height);
double ScoreVolume(...);
double ScoreTime(int bars);
double ScoreMicro(...);

// 总分计算
totalScore = flatness * 0.25 + independence * 0.20 + 
             smoothness * 0.12 + space * 0.13 + 
             volume * 0.12 + time * 0.10 + micro * 0.08;
```

---

### 2. 添加缺失的过滤条件

#### 2.1 智能入场过滤
```cpp
bool IsSmartEntryValid(double boxTop, double boxBottom) {
    // 1. 成交量过滤
    double avgVolume = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, VOLUME_TICK);
    bool volumeOK = (volume[0] >= avgVolume * 1.3);  // MinVolumeRatio = 1.3
    
    // 2. 箱体年龄过滤
    bool ageOK = (g_boxBars <= 30);  // MaxBoxAgeBars = 30
    
    // 3. 波动率过滤
    double atr = iATR(_Symbol, PERIOD_CURRENT, 14, 0);
    double avgPrice = (boxTop + boxBottom) / 2.0;
    bool volatilityOK = (atr <= avgPrice * 0.02);  // ATR不超过价格的2%
    
    return volumeOK && ageOK && volatilityOK;
}
```

#### 2.2 箱体高度过滤
```cpp
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

#### 2.3 冷却期机制
```cpp
// 确保冷却期逻辑与 TradingView 一致
// TradingView:
// CooldownBars = 6
// nextTradeBar = bar_index + CooldownBars
// bool inCooldown = bar_index <= nextTradeBar

// 马丁爆仓后触发冷却期
if (martinCount >= MartinMax) {
    nextTradeBar = bar_index + 6;  // 休息6根K线
}
```

---

### 3. 修改参数（与 TradingView 同步）

#### 3.1 评分阈值
```cpp
// 修改前
input double 箱体最低评分 = 20.0;

// 修改后
input double 箱体最低评分 = 35.0;  // 🔥 从20提升到35
```

#### 3.2 ATR 止损倍数
```cpp
// 修改前
input double ATR止损倍数 = 2.0;

// 修改后
input double ATR止损倍数 = 1.7;  // 🔥 从2.0降到1.7（更紧止损）
```

#### 3.3 移动止盈参数
```cpp
// 修改前
double 箱体高度触发倍数 = 0.65;
double 箱体高度回撤倍数 = 0.32;

// 修改后
double 箱体高度触发倍数 = 0.85;  // 🔥 从65%提升到85%
double 箱体高度回撤倍数 = 0.45;  // 🔥 从32%提升到45%
```

#### 3.4 马丁格尔参数
```cpp
// 修改前
input int 马丁最大次数 = 2;

// 修改后
input int 马丁最大次数 = 1;  // 🔥 从2降到1（实际禁用马丁）
```

#### 3.5 新增参数
```cpp
// 智能入场过滤参数
input bool     启用智能入场过滤 = true;
input double   最小成交量倍数 = 1.3;
input int      最大箱体年龄 = 30;

// 箱体高度过滤参数
input bool     启用箱体高度过滤 = true;
input double   箱体高度倍数限制 = 3.0;
input int      高度过滤回溯K线数 = 10;
```

---

### 4. 修改入场逻辑

**TradingView 的入场条件：**
```pine
if stratState == 0 and strategy.position_size == 0
    bool inCooldown = bar_index <= nextTradeBar
    
    if not inCooldown
        // 检查所有条件
        if isQualified and box_valid and f_inTime() and smartEntryOK
            stratState := 1
            lockBoxTop := box_top
            lockBoxBtm := box_bottom
            // 下单
            strategy.entry("Break_Long", strategy.long, stop=lockBoxTop, ...)
            strategy.entry("Break_Short", strategy.short, stop=lockBoxBtm, ...)
```

**EA 需要同步：**
```cpp
// 在 OnTick() 中
if (stratState == 0 && PositionSelect(_Symbol) == false) {
    // 1. 检查冷却期
    bool inCooldown = (bar_index <= g_nextTradeBar);
    if (inCooldown) return;
    
    // 2. 计算箱体（内置逻辑）
    CalculateBox();
    
    // 3. 检查所有条件
    bool isQualified = (g_boxTotalScore >= 35.0);
    bool boxValid = g_box_valid;
    bool timeOK = IsInTime();
    bool smartEntryOK = IsSmartEntryValid(g_box_top, g_box_bottom);
    bool boxHeightOK = IsBoxHeightValid(g_boxHeight, 10, 3.0);
    
    if (isQualified && boxValid && timeOK && smartEntryOK && boxHeightOK) {
        // 锁定箱体
        g_isBoxLocked = true;
        g_lockedBoxTop = g_box_top;
        g_lockedBoxBot = g_box_bottom;
        
        // 下挂单
        PlacePendingOrders();
    }
}
```

---

### 5. 修改止损/止盈逻辑

#### 5.1 ATR 动态止损
```cpp
double CalculateATRStopLoss(double entryPrice, double boxTop, double boxBottom, bool isLong) {
    double atr = iATR(_Symbol, PERIOD_CURRENT, 14, 0);
    double boxHeight = MathAbs(boxTop - boxBottom);
    double atrSL = atr * 1.7;  // 🔥 改为 1.7
    
    // 使用较大的止损距离
    double slDistance = MathMax(boxHeight, atrSL);
    
    return isLong ? entryPrice - slDistance : entryPrice + slDistance;
}
```

#### 5.2 移动止盈
```cpp
void CheckTrailingStop() {
    // ... 现有代码 ...
    
    // 修改触发条件
    double profitRatio = currentProfit / g_boxHeight;
    if(profitRatio >= 0.85) {  // 🔥 改为 85%
        // 计算新止损位
        double trailOffset = g_boxHeight * 0.45;  // 🔥 改为 45%
        
        if(isLong) {
            double newSL = currentPrice - trailOffset;
            if(newSL > oldSL) {
                // 修改止损
                g_Trade.PositionModify(ticket, newSL, tp);
            }
        } else {
            double newSL = currentPrice + trailOffset;
            if(newSL < oldSL) {
                g_Trade.PositionModify(ticket, newSL, tp);
            }
        }
    }
}
```

---

## 📋 完整参数对比表

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
| 冷却期K线数 | 6 | 需确认 | 6 |

---

## ✅ 验证要求

修改完成后，请确保：

1. **编译通过**：无错误、无警告
2. **逻辑一致**：箱体识别、评分、过滤条件与 TradingView 完全一致
3. **参数同步**：所有参数值与 TradingView 一致
4. **代码注释**：关键修改处添加注释说明

---

## 📝 输出要求

1. **修改后的完整 EA 代码**（保存为新文件）
2. **修改说明文档**（列出所有修改点）
3. **测试建议**（如何验证修改是否正确）

---

## 🚨 注意事项

1. **保留原有功能**：不要删除 EA 的其他功能（如马丁格尔、移动止损等）
2. **兼容性**：确保代码在 MT5 上可以正常编译和运行
3. **性能**：箱体识别逻辑不要过于复杂，避免影响 EA 性能
4. **可读性**：代码结构清晰，变量命名规范

---

生成时间：2026-03-10 07:42
