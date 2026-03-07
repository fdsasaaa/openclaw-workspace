# 阶段6-10建议评估与优化实施计划

**评估时间**: 2026-03-05  
**评估者**: OpenClaw中枢协调器  
**评估对象**: 外部6-10阶段部署建议

---

## 一、建议整体评估

### 1.1 价值认可

| 阶段 | 建议内容 | 实际价值 | 必要性 |
|------|----------|----------|--------|
| 阶段6 PM2部署 | 后台常驻运行 | ⭐⭐⭐ 高 | 确实需要 |
| 阶段7 自动化运维 | 密钥检测/定时任务 | ⭐⭐ 中 | 部分需要 |
| 阶段8 EA业务适配 | 模板/回测闭环 | ⭐⭐⭐ 高 | 业务核心 |
| 阶段9 日志监控 | 状态可视化 | ⭐⭐ 中 | 运维需要 |
| 阶段10 性能优化 | 资源限制 | ⭐⭐ 中 | 按需实施 |

### 1.2 发现的问题

| 问题类别 | 具体问题 | 风险等级 |
|----------|----------|----------|
| **路径错误** | 多处使用`E:\OpenClaw_Workspace`，与当前C盘主路径冲突 | 🔴 高 |
| **安全隐患** | 密钥硬编码在PowerShell脚本中(`check-kimi-key.ps1`) | 🔴 高 |
| **配置存疑** | `/config set`命令可能不存在或行为不一致 | 🟡 中 |
| **过度工程** | Windows任务计划+PM2+OpenClaw cron三重调度 | 🟡 中 |
| **未经测试** | 假设MT4支持命令行回测，未验证 | 🟡 中 |
| **资源冲突** | `--max-old-space-size`与OpenClaw内部管理可能冲突 | 🟢 低 |

### 1.3 核心结论

**建议采纳率**: 约60%

**可直接采用**:
- PM2后台部署思路（需修正路径）
- EA业务模板概念
- 状态监控脚本思路

**需要大幅修改**:
- 所有E盘路径改为C盘
- 密钥检测改为从auth-profiles.json读取
- 移除/OpenClaw CLI配置方式，改用文件配置

**建议延后或废弃**:
- Windows任务计划程序（与OpenClaw cron重复）
- MT4命令行回测（未经证实）
- 部分性能优化参数（风险不明）

---

## 二、优化后的6-10阶段实施计划

### 阶段6优化：后台常驻部署（高优先级）

**目标**: 实现OpenClaw后台运行，不依赖前台窗口

**实施方案**:

1. **评估OpenClaw原生服务化方案**（优先尝试）
   ```powershell
   # 检查是否已有服务注册
   openclaw gateway status
   # 或检查Windows服务
   Get-Service | Where-Object {$_.Name -like "*openclaw*"}
   ```

2. **如原生不支持，再考虑PM2方案**（修正路径）
   ```powershell
   # 安装PM2
   npm install pm2 -g
   
   # 配置文件路径修正为C盘
   C:\OpenClaw_Workspace\configs\pm2-openclaw.json
   
   # 日志路径修正
   C:\OpenClaw_Workspace\logs\pm2-gateway-out.log
   C:\OpenClaw_Workspace\logs\pm2-gateway-error.log
   ```

3. **验证标准**
   - 关闭所有窗口后Gateway仍在运行
   - 重启后自动启动

**风险**: 🟢 低（可回滚）

---

### 阶段7优化：关键监控与自愈（中优先级）

**目标**: 核心异常检测，非全面运维

**实施方案**:

1. **简化密钥检测**（从文件读取，不硬编码）
   ```powershell
   # 读取已配置的密钥
   $authFile = "C:\Users\ME\.openclaw\agents\main\agent\auth-profiles.json"
   $auth = Get-Content $authFile | ConvertFrom-Json
   $key = $auth.profiles.'moonshot:default'.key
   # 然后检测...
   ```

2. **使用OpenClaw cron替代Windows任务计划**
   ```bash
   # 统一使用OpenClaw原生cron
   openclaw cron add --name check:health --command "..." --schedule "0 */6 * * *"
   ```

3. **移除内存自动重启**（与阶段10冲突，保留一个）

**风险**: 🟢 低

---

### 阶段8优化：EA业务模板（高优先级）

**目标**: 建立EA生成-保存-回测闭环

**实施方案**:

1. **创建EA提示词模板**（纯文本，不依赖/config）
   ```
   C:\OpenClaw_Workspace\templates\ea-prompt-gold-intraday.txt
   ```

2. **建立目录结构**
   ```
   C:\OpenClaw_Workspace\ea-scripts\        # 生成脚本存放
   C:\OpenClaw_Workspace\ea-backtests\      # 回测结果
   C:\OpenClaw_Workspace\ea-reports\        # 分析报告
   ```

3. **验证MT4命令行回测可行性**
   - 先测试MT4是否支持`/backtest`参数
   - 如不支持，改用其他回测方案

**风险**: 🟡 中（依赖MT4能力）

---

### 阶段9优化：轻量级监控（中优先级）

**目标**: 关键状态可查看

**实施方案**:

1. **简化状态看板脚本**
   ```powershell
   # 只检查：PM2状态、网关端口、最新EA脚本
   # 不引入Process Explorer（太重）
   ```

2. **日志级别调整**
   ```powershell
   # 如OpenClaw支持环境变量调整日志级别
   $env:OPENCLAW_LOG_LEVEL = "debug"
   ```

3. **使用现有日志位置**
   ```
   C:\Users\ME\.openclaw\logs\  # 系统日志
   C:\OpenClaw_Workspace\logs\ # 业务日志
   ```

**风险**: 🟢 低

---

### 阶段10优化：保守性能调优（低优先级）

**目标**: 资源占用可控

**实施方案**:

1. **先观察，后调整**
   - 运行一周，记录内存/CPU基线
   - 再决定是否需要限制

2. **保守参数**
   ```json
   // PM2配置中仅设置最大内存重启
   "max_memory_restart": "512M"
   // 不设置Node.js参数（避免冲突）
   ```

3. **模型选择**
   - 保持当前kimi-coding/k2p5
   - 如需速度，可测试kimi-k1-mini

**风险**: 🟢 低

---

## 三、实施优先级与步骤

### 立即执行（本周）

| 步骤 | 动作 | 产出 |
|------|------|------|
| 1 | 验证OpenClaw原生服务化能力 | 确定是否需PM2 |
| 2 | 如需要，部署PM2（修正路径为C盘） | 后台常驻运行 |
| 3 | 创建EA业务模板 | ea-prompt-*.txt |
| 4 | 建立ea-scripts/ea-backtests/目录 | 业务目录结构 |

### 随后执行（下周）

| 步骤 | 动作 | 产出 |
|------|------|------|
| 5 | 创建简化状态看板脚本 | status-dashboard.ps1 |
| 6 | 配置OpenClaw cron定时任务 | 自动备份/健康检查 |
| 7 | 验证MT4命令行回测 | 确定回测方案 |

### 按需执行

| 步骤 | 动作 | 触发条件 |
|------|------|----------|
| 8 | 性能调优 | 观察内存>500MB或响应>30s |
| 9 | 高级监控 | 需要详细排查问题时 |

---

## 四、风险防控

### 4.1 回滚方案

每个阶段实施前创建检查点：

```powershell
# 阶段6前备份
C:\OpenClaw_Workspace\backup\pre-stage6\gateway-config.json

# PM2配置验证失败时回滚
pm2 delete openclaw-gateway
pm2 delete openclaw-tui
# 恢复手动启动
```

### 4.2 验证检查点

每个阶段必须验证：

| 阶段 | 验证动作 | 通过标准 |
|------|----------|----------|
| 6 | 关闭窗口后`openclaw gateway status` | 仍显示running |
| 7 | 等待定时任务触发 | 日志文件更新 |
| 8 | 使用模板生成EA | 脚本符合模板要求 |
| 9 | 执行看板脚本 | 所有状态正常显示 |
| 10 | 观察一周资源占用 | 内存<512MB,响应<30s |

### 4.3 停止条件

以下情况立即停止并汇报：
- Gateway无法启动
- TUI无法连接
- API调用失败率>10%
- 系统资源占用异常

---

## 五、学习经验与记录机制

### 5.1 每阶段记录内容

写入`C:\OpenClaw_Workspace\memory\evolution-6-10.md`:

```markdown
## 阶段6实施记录

### 实施时间
2026-03-XX

### 采用方案
- [ ] OpenClaw原生服务化
- [x] PM2部署（修正路径后）

### 遇到的问题
- 问题1: XXX → 解决方案: XXX

### 验证结果
- [x] 后台常驻: 通过
- [x] 重启自启: 通过

### 经验教训
- 原建议的E盘路径需改为C盘
- PM2配置中`cwd`参数很重要

### 回滚方式
```powershell
pm2 delete all
# 恢复手动启动
```
```

### 5.2 经验沉淀

阶段6-10完成后更新`MEMORY.md`:

```markdown
## 部署经验

### 后台运行
- 推荐方式: PM2 + 修正路径
- 避免: Windows服务（复杂）、原生服务（不稳定）

### 监控原则
- 优先OpenClaw原生能力
- 次选轻量级脚本
- 避免: 多重调度系统并存
```

---

## 六、总结与建议

### 6.1 对外部建议的总体评价

| 维度 | 评分 | 说明 |
|------|:----:|------|
| 完整性 | ⭐⭐⭐⭐⭐ | 覆盖部署、运维、业务、监控、优化 |
| 可行性 | ⭐⭐⭐ | 部分配置方式存疑，路径需修正 |
| 安全性 | ⭐⭐ | 密钥硬编码问题严重 |
| 适配性 | ⭐⭐⭐ | 需适配当前C盘环境 |
| 工程化 | ⭐⭐⭐⭐ | 有一定过度设计 |

### 6.2 核心改进点

1. **路径统一**: 所有`E:>`改为`C:>`
2. **密钥安全**: 从auth文件读取，不硬编码
3. **配置简化**: 移除存疑的`/config`命令，改用文件配置
4. **调度统一**: 优先OpenClaw cron，减少Windows任务计划
5. **风险降低**: 先观察后优化，不预设性能问题

### 6.3 实施建议

**立即开始阶段6（后台常驻）**，这是当前最需要的。

其他阶段按需逐步实施，不追求一次性完成。

---

*评估完成，等待启动阶段6实施。*
