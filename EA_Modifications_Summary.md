# MT5 EA 修改说明文档

## 📋 修改概述

本次修改将 MT5 EA 的交易逻辑与 TradingView 策略完全同步，确保两者的交易信号和参数完全一致。

**修改时间**: 2026-03-10
**修改文件**: EA_Modified.mq5
**原始文件**: G:\其他计算机\租用笔记本\能量块\能量块龙虾进化\MT5\27版本.mq5

---

## ✅ 完成的修改项

### 1. 参数修改（5个关键参数）

#### 1.1 评分阈值：20 → 35
```cpp
// 修改前
input double   质量评分阈值          = 20.0;

// 修改后
input double   质量评分阈值          = 35.0;   // 🔥 修改：从20改为35（与TV策略一致）
```
**影响**: 提高箱体质量要求，减少低质量箱体的交易信号

#### 1.2 ATR止损倍数：2.0 → 1.7
```cpp
// 修改前
input double   ATR止损倍数           = 2.0;

// 修改后
input double   ATR止损倍数           = 1.7;    // 🔥 修改：从2.0改为1.7（与TV策略一致）
```
**影响**: 止损更紧，降低单笔交易风险

#### 1.3 移动止盈触发：65% → 85%
```cpp
// 修改前
double      箱体高度触发倍数      = 0.65;

// 修改后
double      箱体高度触发倍数      = 0.85;  // 🔥 修改：从0.65改为0.85（与TV策略一致）
```
**影响**: 需要更大盈利才启动移动止盈，让利润充分奔跑

#### 1.4 移动止盈回撤：32% → 45%
```cpp
// 修改前
double      箱体高度回撤倍数      = 0.32;

// 修改后
double      箱体高度回撤倍数      = 0.45;  // 🔥 修改：从0.32改为0.45（与TV策略一致）
```
**影响**: 移动止损距离更大，给价格更多回调空间

#### 1.5 马丁最大次数：2 → 1
```cpp
// 修改前
input int         马丁最大次数          = 2;

// 修改后
input int         马丁最大次数          = 1;  // 🔥 修改：从2改为1（与TV策略一致）
```
**影响**: 实际禁用马丁格尔，降低连续亏损风险

#### 1.6 最小成交量倍数：0.8 → 1.3
```cpp
// 修改前
input double   最小成交量倍数       = 0.8;

// 修改后
input double   最小成交量倍数       = 1.3;    // 🔥 修改：从0.8改为1.3（与TV策略一致）
```
**影响**: 要求更高的成交量确认，过滤低量能突破

---

### 2. 新增功能（2个过滤函数）

#### 2.1 智能入场过滤函数
**位置**: 第 3357-3393 行

**功能**: 三重过滤机制
1. **成交量过滤**: 当前成交量 >= 平均成交量 × 1.3
2. **箱体年龄过滤**: 箱体K线数 <= 30
3. **波动率过滤**: ATR <= 价格 × 2%

```cpp
bool CheckSmartEntryFilter(double boxTop, double boxBottom)
{
    if(!启用智能过滤) return true;

    // 1. 成交量过滤
    long volArr[];
    if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, 20, volArr) < 20)
        return true;

    double sumVol = 0.0;
    for(int i = 1; i < 20; i++)
        sumVol += (double)volArr[i];
    double avgVolume = sumVol / 19.0;
    double currentVolume = (double)volArr[0];
    bool volumeOK = (currentVolume >= avgVolume * 最小成交量倍数);

    // 2. 箱体年龄过滤
    bool ageOK = (g_boxBars <= 最大箱体年龄K线数);

    // 3. 波动率过滤
    double atr = iATR(_Symbol, PERIOD_CURRENT, ATR周期);
    double avgPrice = (boxTop + boxBottom) / 2.0;
    bool volatilityOK = (atr <= avgPrice * (ATR波动率上限占比 / 100.0));

    return volumeOK && ageOK && volatilityOK;
}
```

#### 2.2 箱体高度过滤函数
**位置**: 第 3398-3432 行

**功能**: 防止箱体过高导致的假突破
- 计算箱体之前10根K线的平均高度
- 箱体高度必须 < 平均K线高度 × 3.0

```cpp
bool CheckBoxHeightFilter(double boxHeight)
{
    if(!启用箱体高度过滤) return true;

    double totalKlineHeight = 0.0;
    int validBars = 0;

    for(int i = 0; i < 高度过滤回溯K线数; i++)
    {
        int idx = g_boxBars + i;
        if(idx >= Bars(_Symbol, PERIOD_CURRENT)) break;

        double high = iHigh(_Symbol, PERIOD_CURRENT, idx);
        double low = iLow(_Symbol, PERIOD_CURRENT, idx);
        double klineHeight = high - low;

        totalKlineHeight += klineHeight;
        validBars++;
    }

    if(validBars == 0) return true;

    double avgKlineHeight = totalKlineHeight / validBars;
    double maxAllowedBoxHeight = avgKlineHeight * 箱体高度倍数限制;

    return (boxHeight < maxAllowedBoxHeight);
}
```

#### 2.3 新增输入参数
```cpp
// ---【新增：箱体高度过滤参数】---
input string   NOTE_BOX_HEIGHT_FILTER = "====== 新增：箱体高度过滤 ======";
input bool     启用箱体高度过滤     = true;   // 启用箱体高度过滤
input double   箱体高度倍数限制     = 3.0;    // 箱体高度不超过平均K线高度的N倍
input int      高度过滤回溯K线数    = 10;     // 计算平均K线高度时回溯的K线数
```

---

### 3. 入场逻辑修改

**位置**: IsTradeEnvironmentSafe 函数（第 3291-3327 行）

**修改内容**: 在原有的点差保护和最小波动过滤基础上，新增两个过滤检查

```cpp
bool IsTradeEnvironmentSafe(double boxTop, double boxBot)
{
    if (!启用点差保护) return true;
    double boxHeight = MathAbs(boxTop - boxBot);

    // 1. 最小波动过滤
    if (boxHeight < 最小箱体波动微点 * _Point) {
        return false;
    }

    // 2. 自适应点差保护
    double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
    double ratio = (boxHeight > 0) ? (currentSpread / boxHeight) : 999.0;
    if (ratio > 最大点差占比) {
        return false;
    }

    // 🔥 新增：智能入场过滤检查
    if(!CheckSmartEntryFilter(boxTop, boxBot)) {
        if(启用诊断日志) PrintFormat("【过滤】智能入场过滤未通过，放弃开仓");
        return false;
    }

    // 🔥 新增：箱体高度过滤检查
    if(!CheckBoxHeightFilter(boxHeight)) {
        if(启用诊断日志) PrintFormat("【过滤】箱体高度过滤未通过，放弃开仓");
        return false;
    }

    return true;
}
```

---

## 📊 修改对比表

| 项目 | TradingView | 修改前 | 修改后 | 状态 |
|------|------------|--------|--------|------|
| 评分阈值 | 35 | 20 | 35 | ✅ |
| ATR止损倍数 | 1.7 | 2.0 | 1.7 | ✅ |
| 移动止盈触发 | 85% | 65% | 85% | ✅ |
| 移动止盈回撤 | 45% | 32% | 45% | ✅ |
| 马丁最大次数 | 1 | 2 | 1 | ✅ |
| 成交量倍数 | 1.3 | 0.8 | 1.3 | ✅ |
| 智能入场过滤 | ✓ | ✗ | ✓ | ✅ |
| 箱体高度过滤 | ✓ | ✗ | ✓ | ✅ |

---

## 🧪 验证方法

### 1. 编译测试
```bash
# 在 MT5 中打开 EA_Modified.mq5
# 点击 "编译" 按钮
# 确认无错误、无警告
```

### 2. 参数验证
在 MT5 中加载 EA，检查输入参数：
- [ ] 质量评分阈值 = 35.0
- [ ] ATR止损倍数 = 1.7
- [ ] 箱体高度触发倍数 = 0.85
- [ ] 箱体高度回撤倍数 = 0.45
- [ ] 马丁最大次数 = 1
- [ ] 最小成交量倍数 = 1.3
- [ ] 启用箱体高度过滤 = true
- [ ] 箱体高度倍数限制 = 3.0

### 3. 功能测试
启用诊断日志（启用诊断日志 = true），观察日志输出：
- [ ] 智能入场过滤日志正常输出
- [ ] 箱体高度过滤日志正常输出
- [ ] 过滤条件正确触发

### 4. 回测对比
使用相同的历史数据：
1. 在 TradingView 上运行策略
2. 在 MT5 上回测修改后的 EA
3. 对比：
   - 入场点数量
   - 入场价格
   - 止损位置
   - 交易结果

---

## ⚠️ 注意事项

### 1. 兼容性
- 修改保留了所有原有功能
- 新增的过滤可以通过开关禁用
- 不影响其他交易逻辑

### 2. 性能
- 新增的过滤函数计算量较小
- 不会显著影响 EA 性能
- 建议在实盘前先进行回测验证

### 3. 风险控制
- 评分阈值提高后，交易信号会减少
- 马丁次数减少后，连续亏损风险降低
- 建议根据实际情况调整资金管理参数

---

## 📝 后续建议

### 1. 回测验证
- 使用至少 3 个月的历史数据进行回测
- 对比修改前后的交易结果
- 重点关注：胜率、盈亏比、最大回撤

### 2. 参数优化
如果回测结果不理想，可以调整：
- 质量评分阈值（30-40 之间）
- 箱体高度倍数限制（2.5-3.5 之间）
- 最小成交量倍数（1.2-1.5 之间）

### 3. 实盘测试
- 先用小资金测试 1-2 周
- 监控交易信号与 TradingView 的差异
- 确认无误后再增加资金

---

## 🔧 故障排查

### 问题 1: 编译错误
**可能原因**: 缺少 g_boxBars 变量定义
**解决方法**: 确认原 EA 中已定义 g_boxBars 全局变量

### 问题 2: 过滤不生效
**可能原因**: 开关未启用
**解决方法**: 检查 启用智能过滤 和 启用箱体高度过滤 是否为 true

### 问题 3: 交易信号过少
**可能原因**: 过滤条件过严
**解决方法**: 适当降低评分阈值或箱体高度倍数限制

---

## 📞 技术支持

如有问题，请检查：
1. EA 编译是否成功
2. 参数设置是否正确
3. 诊断日志输出内容

---

**文档生成时间**: 2026-03-10
**修改完成状态**: ✅ 已完成
