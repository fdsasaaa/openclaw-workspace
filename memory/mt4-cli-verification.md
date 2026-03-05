# MT4命令行回测可行性验证报告

**验证时间**: 2026-03-05  
**验证者**: OpenClaw中枢协调器  
**验证目标**: 确认MT4是否支持命令行回测

---

## 一、MT4安装检查

### 1.1 常见路径检查

| 路径 | 存在 | 说明 |
|------|:----:|------|
| `C:\Program Files\MetaTrader 4\terminal64.exe` | ❌ | 未安装 |
| `C:\Program Files (x86)\MetaTrader 4\terminal.exe` | ❌ | 未安装 |
| `C:\Program Files\FXCM MetaTrader 4\terminal.exe` | ❌ | 未安装 |

### 1.2 程序目录扫描

在 `C:\Program Files\` 下未找到 MetaTrader 相关目录。

### 1.3 结论

**MT4 未在当前系统安装。**

---

## 二、命令行回测可行性分析

### 2.1 MT4命令行参数文档

根据MetaQuotes官方文档，MT4/MT5支持以下命令行参数：

```
terminal.exe [配置文件] [选项]

常用选项:
/portable     便携模式
/config:路径  指定配置文件
```

**关键发现**: MT4 **不原生支持** `/backtest` 或类似参数进行命令行回测。

### 2.2 可行方案对比

| 方案 | 可行性 | 复杂度 | 推荐度 |
|------|:------:|:------:|:------:|
| **MT4命令行回测** | ❌ 不可行 | - | 不推荐 |
| **MT5命令行回测** | ⚠️ 有限支持 | 中 | 有条件推荐 |
| **Python回测框架** | ✅ 可行 | 低 | **推荐** |
| **第三方EA测试工具** | ⚠️ 需调研 | 中 | 待定 |

### 2.3 推荐方案：Python回测

**理由**:
1. 当前已具备 Python 3.11.9
2. 已安装 pandas/numpy
3. 需安装 backtrader 即可
4. 无需额外安装MT4/MT5
5. 与当前EA优化脚本兼容

---

## 三、Python回测实施方案

### 3.1 安装依赖

```powershell
pip install backtrader
```

### 3.2 回测流程

```
1. AI生成MQL4 EA脚本
2. 人工或自动转换为Python策略
3. 使用backtrader回测
4. 生成回测报告
```

### 3.3 目录对应

| 目录 | 用途 |
|------|------|
| `ea-scripts/` | 存放生成的MQL4脚本 |
| `ea-backtests/` | 存放Python回测脚本和结果 |
| `ea-reports/` | 存放回测报告（HTML/CSV） |

---

## 四、实施建议

### 4.1 立即执行

1. **安装 backtrader**
   ```powershell
   pip install backtrader
   ```

2. **创建Python回测模板**
   - 路径: `C:\OpenClaw_Workspace\templates\ea-backtest-template.py`
   - 功能: 读取market_data.csv，执行回测，输出报告

### 4.2 业务闭环流程

```
AI生成EA (MQL4)
    ↓
保存到 ea-scripts/
    ↓
[可选] 人工转换为Python策略
    ↓
运行Python回测
    ↓
生成报告到 ea-reports/
```

### 4.3 后续优化

- 研究MQL4到Python的自动转换
- 或直接使用Python策略生成（而非MQL4）

---

## 五、结论

| 验证项 | 结果 |
|--------|------|
| MT4命令行回测 | ❌ **不可行** |
| MT4安装状态 | ❌ **未安装** |
| Python回测可行性 | ✅ **可行** |
| 推荐方案 | **使用backtrader进行Python回测** |

**阶段8调整**: 放弃MT4命令行回测，改用Python backtrader回测框架。

---

*验证完成，建议立即安装backtrader。*
