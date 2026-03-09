# 策略优化分析 - 2026-03-09

## 当前问题

原始策略表现：
- 盈亏比: 1.21（目标 >2.0）
- 胜率: 59.83%
- 交易次数: 575
- 最大回撤: 0.03%

## 优化尝试 1：平衡型（失败）

参数调整：
- TrailStartRatio: 65% → 85%
- TrailOffsetRatio: 32% → 45%
- ATR_SL_Mult: 2.0 → 1.7
- MinDisplayScore: 20 → 35
- MinVolumeRatio: 0.8 → 1.3
- MartinMax: 2 → 1

结果：效果更差

**失败原因分析**：
1. 入场过滤太严格（MinDisplayScore 35 + MinVolumeRatio 1.3）→ 错过好机会
2. 止损太紧（ATR 1.7）→ 被频繁扫损
3. 止盈启动太晚（85%）→ 利润回吐

## 优化尝试 2：激进型（新方案）

**核心思路**：
- 保持交易频率（不要过度过滤）
- 放宽止损（给趋势空间）
- 提前锁定利润（降低止盈启动阈值）

**参数调整**：
- TrailStartRatio: 65% → **55%**（更早启动止盈）
- TrailOffsetRatio: 32% → **25%**（更紧跟趋势）
- ATR_SL_Mult: 2.0 → **2.2**（放宽止损）
- MinDisplayScore: 20 → **25**（轻微提高质量）
- MinVolumeRatio: 0.8 → **1.0**（轻微过滤）
- MartinMax: 2 → **1**（禁用马丁）

**预期效果**：
- 盈亏比: 1.5-1.8（提升 25-50%）
- 交易次数: 500-550（减少 5-15%）
- 胜率: 58-62%（保持）
- 最大回撤: <5%

## 优化尝试 3：保守型（备选）

如果激进型还是不行，尝试：
- TrailStartRatio: 65% → **70%**
- TrailOffsetRatio: 32% → **35%**
- ATR_SL_Mult: 2.0 → **1.9**
- MinDisplayScore: 20 → **30**
- MinVolumeRatio: 0.8 → **1.1**
- MartinMax: 2 → **1**
