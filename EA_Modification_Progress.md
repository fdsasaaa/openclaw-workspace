# MT5 EA 修改实施记录

## 📋 修改概览

由于 ACP runtime 暂时不可用，我将采用手动分析和修改的方式。

---

## 🎯 修改策略

考虑到 EA 文件较大（150KB），我将采用以下策略：

### 方案调整：参数同步 + 过滤条件添加

**原计划：** 完全移植箱体识别逻辑到 EA 内部
**调整后：** 
1. 保持 EA 依赖指标的架构（短期方案）
2. 同步所有参数
3. 添加缺失的过滤条件
4. 确保交易逻辑一致

**原因：**
- EA 代码量大，完全重构风险高
- 参数同步和过滤条件添加可以快速见效
- 后续可以逐步迁移到内置箱体识别

---

## 📝 具体修改清单

### 第一优先级：参数同步（立即见效）

#### 1. 评分阈值
```cpp
// 位置：输入参数区域
// 修改前
input double 箱体最低评分 = 20.0;

// 修改后
input double 箱体最低评分 = 35.0;  // 🔥 与 TradingView 同步
```

#### 2. ATR 止损倍数
```cpp
// 位置：输入参数区域
// 修改前
input double ATR止损倍数 = 2.0;

// 修改后
input double ATR止损倍数 = 1.7;  // 🔥 更紧止损
```

#### 3. 移动止盈参数
```cpp
// 位置：全局变量区域
// 修改前
double 箱体高度触发倍数 = 0.65;
double 箱体高度回撤倍数 = 0.32;

// 修改后
double 箱体高度触发倍数 = 0.85;  // 🔥 从65%提升到85%
double 箱体高度回撤倍数 = 0.45;  // 🔥 从32%提升到45%
```

#### 4. 马丁格尔参数
```cpp
// 位置：输入参数区域
// 修改前
input int 马丁最大次数 = 2;

// 修改后
input int 马丁最大次数 = 1;  // 🔥 实际禁用马丁
```

---

### 第二优先级：添加过滤条件

#### 1. 智能入场过滤
```cpp
// 新增函数
bool IsSmartEntryValid(double boxTop, double boxBottom) {
    if (!启用智能入场过滤) return true;
    
    // 成交量过滤
    double avgVolume[1];
    int volHandle = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, VOLUME_TICK);
    CopyBuffer(volHandle, 0, 0, 1, avgVolume);
    long currentVolume = iVolume(_Symbol, PERIOD_CURRENT, 0);
    bool volumeOK = (currentVolume >= avgVolume[0] * 最小成交量倍数);
    
    // 箱体年龄过滤
    bool ageOK = (g_boxBars <= 最大箱体年龄);
    
    // 波动率过滤
    double atr[1];
    int atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
    CopyBuffer(atrHandle, 0, 0, 1, atr);
    double avgPrice = (boxTop + boxBottom) / 2.0;
    bool volatilityOK = (atr[0] <= avgPrice * 0.02);
    
    return volumeOK && ageOK && volatilityOK;
}

// 新增输入参数
input bool     启用智能入场过滤 = true;
input double   最小成交量倍数 = 1.3;
input int      最大箱体年龄 = 30;
```

#### 2. 箱体高度过滤
```cpp
// 新增函数
bool IsBoxHeightValid(double boxHeight, int lookbackBars, double multiplierLimit) {
    if (!启用箱体高度过滤) return true;
    
    double totalKlineHeight = 0.0;
    int validBars = 0;
    
    for(int i = 0; i < lookbackBars; i++) {
        int idx = g_boxBars + i;
        if(idx < Bars(_Symbol, PERIOD_CURRENT)) {
            double high = iHigh(_Symbol, PERIOD_CURRENT, idx);
            double low = iLow(_Symbol, PERIOD_CURRENT, idx);
            double klineHeight = high - low;
            totalKlineHeight += klineHeight;
            validBars++;
        }
    }
    
    if(validBars == 0) return true;
    
    double avgKlineHeight = totalKlineHeight / validBars;
    double maxAllowedBoxHeight = avgKlineHeight * multiplierLimit;
    
    return (boxHeight < maxAllowedBoxHeight);
}

// 新增输入参数
input bool     启用箱体高度过滤 = true;
input double   箱体高度倍数限制 = 3.0;
input int      高度过滤回溯K线数 = 10;
```

#### 3. 冷却期机制验证
```cpp
// 确认现有代码中的冷却期逻辑
// 应该在马丁爆仓后触发：
if (g_martinCount >= 马丁最大次数) {
    g_nextTradeBar = bar_index + 6;  // 休息6根K线
}

// 在入场前检查：
bool inCooldown = (bar_index <= g_nextTradeBar);
if (inCooldown) return;
```

---

### 第三优先级：修改入场逻辑

```cpp
// 在 OnTick() 或相关函数中
// 修改前：只检查箱体评分
if (g_boxTotalScore >= 箱体最低评分) {
    // 下单
}

// 修改后：添加所有过滤条件
if (g_boxTotalScore >= 箱体最低评分) {
    // 1. 检查冷却期
    bool inCooldown = (bar_index <= g_nextTradeBar);
    if (inCooldown) return;
    
    // 2. 检查智能入场
    bool smartEntryOK = IsSmartEntryValid(g_lockedBoxTop, g_lockedBoxBot);
    if (!smartEntryOK) return;
    
    // 3. 检查箱体高度
    double boxHeight = g_lockedBoxTop - g_lockedBoxBot;
    bool boxHeightOK = IsBoxHeightValid(boxHeight, 高度过滤回溯K线数, 箱体高度倍数限制);
    if (!boxHeightOK) return;
    
    // 4. 检查时间过滤
    bool timeOK = IsInTime();
    if (!timeOK) return;
    
    // 所有条件通过，下单
    PlacePendingOrders();
}
```

---

### 第四优先级：修改止损/止盈逻辑

#### 1. ATR 动态止损
```cpp
// 修改 CalculateATRStopLoss 函数
double CalculateATRStopLoss(double entryPrice, double boxTop, double boxBottom, bool isLong) {
    double atr[1];
    int atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
    CopyBuffer(atrHandle, 0, 0, 1, atr);
    
    double boxHeight = MathAbs(boxTop - boxBottom);
    double atrSL = atr[0] * 1.7;  // 🔥 改为 1.7
    
    double slDistance = MathMax(boxHeight, atrSL);
    
    return isLong ? entryPrice - slDistance : entryPrice + slDistance;
}
```

#### 2. 移动止盈
```cpp
// 修改 CheckTrailingStop 函数中的触发条件
void CheckTrailingStop() {
    // ... 获取持仓信息 ...
    
    double currentProfit = PositionGetDouble(POSITION_PROFIT);
    double boxHeight = g_lockedBoxTop - g_lockedBoxBot;
    double profitRatio = currentProfit / (boxHeight * PositionGetDouble(POSITION_VOLUME));
    
    // 🔥 修改触发条件：从 0.65 改为 0.85
    if(profitRatio >= 0.85) {
        // 🔥 修改回撤倍数：从 0.32 改为 0.45
        double trailOffset = boxHeight * 0.45;
        
        double currentPrice = isLong ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                                       SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        if(isLong) {
            double newSL = currentPrice - trailOffset;
            if(newSL > oldSL) {
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

## 🔧 实施步骤

### 步骤 1：备份原文件
```powershell
Copy-Item "G:\其他计算机\租用笔记本\能量块\能量块龙虾进化\MT5\27版本.mq5" `
          "G:\其他计算机\租用笔记本\能量块\能量块龙虾进化\MT5\27版本_backup.mq5"
```

### 步骤 2：修改参数（最简单，立即见效）
- 修改 4 个关键参数
- 编译测试

### 步骤 3：添加过滤函数
- 添加 2 个新函数
- 添加对应的输入参数
- 编译测试

### 步骤 4：修改入场逻辑
- 在入场判断处添加过滤条件调用
- 编译测试

### 步骤 5：修改止损/止盈
- 修改 ATR 倍数
- 修改移动止盈参数
- 编译测试

### 步骤 6：回测验证
- 使用相同历史数据
- 对比 EA 和 TradingView 结果

---

## 📊 预期效果

修改完成后，EA 应该：
1. ✅ 评分阈值提高到 35（减少低质量箱体）
2. ✅ 止损更紧（1.7倍ATR）
3. ✅ 移动止盈更宽松（85%触发，45%回撤）
4. ✅ 马丁格尔禁用（最多1次）
5. ✅ 智能入场过滤（成交量、年龄、波动率）
6. ✅ 箱体高度过滤（不超过3倍平均K线高度）

---

## 🚨 注意事项

1. **同步指标参数**：确保 nengliang.mq5 的评分阈值也改为 35
2. **测试环境**：先在模拟账户测试
3. **监控差异**：对比 EA 和 TradingView 的交易信号
4. **逐步调整**：如果效果不理想，可以微调参数

---

## 📝 下一步

由于我无法直接修改 150KB 的 EA 文件，我建议：

**选项 1：我提供详细的修改指导**
- 我告诉你每个参数在哪一行
- 你手动修改
- 我帮你验证

**选项 2：你把 EA 文件分段发给我**
- 我逐段分析
- 找到需要修改的位置
- 提供精确的修改代码

**选项 3：等待 ACP runtime 恢复**
- 稍后重试 Claude Code
- 自动化修改

你选择哪个方案？

---

生成时间：2026-03-10 07:45
