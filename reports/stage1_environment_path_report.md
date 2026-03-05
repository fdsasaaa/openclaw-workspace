# 阶段1：环境与路径迁移报告（正式版）

**生成时间**: 2026-03-05  
**生成模型**: kimi-coding/k2p5  
**报告状态**: 阶段1验收版（可回滚）

---

## 一、当前真实路径清单

### 1.1 OpenClaw 系统路径

| 类别 | 实际路径 | 状态 | 是否可迁移 |
|------|----------|------|-----------|
| 安装目录 | `C:\Users\ME\AppData\Roaming\npm\node_modules\openclaw` | 正常运行 | ❌ 否 |
| 配置目录 | `C:\Users\ME\.openclaw` | 正常运行 | ⚠️ 高风险 |
| 主配置文件 | `C:\Users\ME\.openclaw\openclaw.json` | 已配置 | ⚠️ 需人工确认后修改 |
| Agent 运行时 | `C:\Users\ME\.openclaw\agents\main` | 活跃会话 | ❌ 否 |
| Auth 配置 | `C:\Users\ME\.openclaw\agents\main\agent\auth-profiles.json` | 已配置 | ⚠️ 敏感 |
| 模型配置 | `C:\Users\ME\.openclaw\agents\main\agent\models.json` | 已配置 | ✅ 可修改 |
| 会话存储 | `C:\Users\ME\.openclaw\agents\main\sessions\` | 活跃中 | ❌ 否 |
| Gateway 配置 | `C:\Users\ME\.openclaw\gateway.cmd` | 正常 | ⚠️ 需确认 |
| 系统日志 | `C:\Users\ME\.openclaw\logs\` | 正常 | ✅ 可清理 |
| Canvas | `C:\Users\ME\.openclaw\canvas\` | 未使用 | ✅ 可忽略 |
| Cron | `C:\Users\ME\.openclaw\cron\` | 空 | ✅ 可配置 |
| Devices | `C:\Users\ME\.openclaw\devices\` | 已配对 | ⚠️ 敏感 |
| Identity | `C:\Users\ME\.openclaw\identity\` | 已配置 | ⚠️ 敏感 |

### 1.2 工作区路径（双区并行）

| 区域 | 路径 | 用途 | 当前状态 |
|------|------|------|----------|
| **运行区** | `C:\Users\ME\.openclaw\workspace` | OpenClaw 核心运行、会话、身份配置 | ✅ 活跃使用 |
| **项目主目录** | `C:\OpenClaw_Workspace` | 数据、报告、脚本、项目存储 | ✅ 已就绪 |

### 1.3 项目主目录结构

```
C:\OpenClaw_Workspace\
├── backup/                    # 历史备份（保留，暂不清理）
│   ├── openclaw-config-20260304-160820/     # 旧配置备份
│   └── workspace-20260304-131412/           # 旧工作区备份
├── cache/                     # 缓存目录（空）
├── configs/                   # 配置目录（空）
├── Data/                      # 数据目录
│   └── XAUUSDH1.xlsx         # 黄金1小时行情数据（6882行）
├── logs/                      # 用户日志目录（空）
├── memory/                    # 记忆目录（空）
├── projects/                  # 项目目录（空）
├── reports/                   # 报告目录
│   └── （含历史报告文件）
├── skills/                    # 技能目录（空）
├── step02/                    # EA优化脚本目录
│   └── 01-ea-optimize.ps1    # EA优化脚本（含旧路径）
├── temp/                      # 临时目录（空）
├── workspace/                 # 工作区副本
│   ├── AGENTS.md
│   ├── BOOTSTRAP.md
│   ├── HEARTBEAT.md
│   ├── IDENTITY.md
│   ├── SOUL.md
│   ├── TOOLS.md
│   └── USER.md
├── OPENCLAW_MASTER.ps1       # 环境初始化脚本（含旧路径）
└── README-DIRECTORIES.md     # 目录说明文档（含旧路径）
```

---

## 二、双区并行策略说明

### 2.1 策略定义

**方案**: 运行区与项目主目录分离（双区并行模式）

| 区域 | 路径 | 用途 | 操作权限 |
|------|------|------|----------|
| 运行区 | `C:\Users\ME\.openclaw\workspace` | OpenClaw 核心配置文件（AGENTS/SOUL/USER/IDENTITY/TOOLS/HEARTBEAT） | 只读保护 |
| 项目主目录 | `C:\OpenClaw_Workspace` | 数据、脚本、报告、项目、检查点 | 读写操作 |

### 2.2 采用理由

1. **零中断风险**: 不改 `openclaw.json`，不触发 Gateway 重启，当前会话不中断
2. **即时可用**: `C:\OpenClaw_Workspace` 已存在，立即可作为项目入口
3. **可回滚**: 随时可放弃双区策略，回退到单区模式
4. **渐进式**: 后续如需完全迁移，可在系统重启后执行

### 2.3 边界约定

| 内容类型 | 存放位置 | 示例 |
|----------|----------|------|
| OpenClaw 核心配置 | 运行区 | `AGENTS.md`, `SOUL.md`, `HEARTBEAT.md` |
| 身份/用户定义 | 运行区 | `IDENTITY.md`, `USER.md` |
| 会话/状态数据 | 运行区 | `.openclaw/workspace-state.json` |
| 数据文件 | 项目主目录 | `Data/XAUUSDH1.xlsx` |
| 脚本文件 | 项目主目录 | `step02/01-ea-optimize.ps1` |
| 报告输出 | 项目主目录 | `reports/` |
| 进度检查点 | 项目主目录 | `memory/progress-*.json` |
| 项目代码 | 项目主目录 | `projects/` |
| 自定义技能 | 项目主目录 | `skills/` |

### 2.4 回滚方式

如需回滚到单区模式：
1. 停止所有新任务写入 `C:\OpenClaw_Workspace`
2. 将 `C:\OpenClaw_Workspace\workspace\` 内容同步回运行区（如有变更）
3. 恢复 `openclaw.json` 中的 `agents.defaults.workspace` 配置（如曾修改）
4. 重启 OpenClaw Gateway

**当前状态**: 无需回滚，双区并行运行正常。

---

## 三、旧路径 E:\ 引用清单

### 3.1 命中文件统计

共定位 **9 个文件**包含旧路径 `E:\OpenClaw_Workspace` 或相关旧环境引用：

| 序号 | 文件路径 | 命中类型 | 风险等级 | 当前处理建议 |
|------|----------|----------|----------|--------------|
| 1 | `backup\openclaw-config-20260304-160820\agents\main\sessions\sessions.json` | 历史备份 | 🟢 低 | 保留，暂不处理 |
| 2 | `backup\openclaw-config-20260304-160820\exec-approvals.json` | 历史备份 | 🟢 低 | 保留，暂不处理 |
| 3 | `backup\openclaw-config-20260304-160820\openclaw.json` | 历史备份 | 🟢 低 | 保留，暂不处理 |
| 4 | `backup\workspace-20260304-131412\migrate-openclaw-workspace.ps1` | 历史备份脚本 | 🟢 低 | 保留，暂不处理 |
| 5 | `OPENCLAW_MASTER.ps1` | 脚本硬编码 | 🟡 中 | **建议修复** |
| 6 | `README-DIRECTORIES.md` | 文档说明 | 🟢 低 | 延后处理 |
| 7 | `reports\阶段1-环境与路径迁移报告.md`（文件名乱码） | 历史报告 | 🟢 低 | 保留参考 |
| 8 | `reports\阶段2-...`（文件名乱码） | 历史报告 | 🟢 低 | 保留参考 |
| 9 | `step02\01-ea-optimize.ps1` | 脚本硬编码 | 🟡 中 | **建议修复** |

### 3.2 需优先修复的文件

#### `OPENCLAW_MASTER.ps1`
- **问题**: 硬编码 `$WorkspaceRoot = "E:\OpenClaw_Workspace"`
- **影响**: 脚本无法在当前环境运行
- **修复**: 替换为 `C:\OpenClaw_Workspace`

#### `step02\01-ea-optimize.ps1`
- **问题**: 
  1. Python 模板中硬编码 `dataname='E:\OpenClaw_Workspace\Data\market_data.csv'`
  2. 变量 `$WorkspaceRoot` 未定义
- **影响**: 
  1. Python 脚本运行时找不到数据文件
  2. PowerShell 执行时路径解析失败
- **修复**:
  1. 替换 `E:\` 为 `C:\`
  2. 在脚本开头定义 `$WorkspaceRoot`
  3. 或修改数据源引用为实际存在的 `XAUUSDH1.xlsx`

---

## 四、当前未完成项列表

### 4.1 阶段1未完成（环境与路径）

| 序号 | 未完成项 | 原因 | 建议处理时机 |
|------|----------|------|--------------|
| 1 | 修复 `OPENCLAW_MASTER.ps1` 路径 | 低风险，需人工确认后执行 | 阶段1收尾 |
| 2 | 修复 `01-ea-optimize.ps1` 路径 | 需同步确认数据转换方案 | 阶段1收尾 |
| 3 | 清理/归档 `backup/` 目录 | 非紧急，需确认无依赖后执行 | 阶段2+ |
| 4 | 更新 `README-DIRECTORIES.md` | 纯文档，非功能依赖 | 延后 |

### 4.2 业务前必须完成

| 序号 | 未完成项 | 阻塞业务？ | 紧急度 |
|------|----------|------------|--------|
| 1 | 模型可用性确认（对话测试） | 是 | 🔴 高 |
| 2 | Gateway 状态确认 | 是 | 🔴 高 |
| 3 | 连续运行保护规范落地（写入文件） | 是 | 🟡 中 |
| 4 | 脚本可运行性评估（依赖检查） | 是（如需运行EA优化） | 🟡 中 |
| 5 | 数据转换（XAUUSDH1.xlsx → CSV） | 是（如需运行EA优化） | 🟡 中 |

### 4.3 阶段2-5前置依赖

| 阶段 | 前置依赖 | 当前状态 |
|------|----------|----------|
| 阶段2：技能调研 | 阶段1验收完成 | ⏸️ 等待 |
| 阶段3：安全/记忆/备份 | 连续运行保护规范落地 | ⏸️ 等待 |
| 阶段4：执行层能力 | Python环境 + 依赖库确认 | ⏸️ 等待 |
| 阶段5：协作架构 | 单实例稳定运行验证 | ⏸️ 等待 |

---

## 五、风险项与不确定项

### 5.1 风险项

| 风险 | 等级 | 说明 | 缓解措施 |
|------|------|------|----------|
| API 密钥有效性未验证 | 🟡 中 | 密钥已配置但未实际测试对话 | 业务前必须完成对话测试 |
| Gateway 状态未确认 | 🟡 中 | `openclaw status` 未返回有效结果 | 需人工检查 Gateway 进程 |
| 脚本依赖未确认 | 🟡 中 | Python + backtrader 是否已安装未知 | 业务前需检查或准备安装方案 |
| 身份一致性 | 🟢 低 | `USER.md` 写"竹林"但路径是 `ME` | 确认后决定是否更新 |

### 5.2 不确定项

| 不确定项 | 说明 | 确认方式 |
|----------|------|----------|
| 历史备份是否可删除 | `backup/` 中的旧配置是否还需参考 | 需人工确认 |
| 双区策略是否长期适用 | 是否未来需完全迁移到 `C:\OpenClaw_Workspace` | 观察使用情况后决定 |
| `XAUUSDH1.xlsx` 数据来源 | 是否为最新数据，更新频率如何 | 需人工确认 |

---

## 六、下一步建议（3项最优先）

### 1. 模型可用性验证 ⭐⭐⭐
**动作**: 完成一次最小对话测试，确认 kimi-coding/k2p5 可用  
**验收标准**: 能正常回复，无 401/429 错误  
**阻塞**: 阶段2-5全部，业务启动

### 2. Gateway 状态确认 ⭐⭐⭐
**动作**: 人工检查 `openclaw gateway status` 或进程状态  
**验收标准**: Gateway 进程正常运行，端口 18789 可连接  
**阻塞**: 外部客户端连接（如需要）

### 3. 连续运行保护规范落地 ⭐⭐
**动作**: 将3条保护规范写入执行规则文件  
**建议文件**: `C:\OpenClaw_Workspace\configs\execution-rules.md`  
**验收标准**: 规范文件存在，内容可查阅，后续任务可引用  
**阻塞**: 长任务启动（阶段3+）

---

## 七、阶段1验收结论

| 验收项 | 状态 | 说明 |
|--------|------|------|
| 环境路径清单 | ✅ 已完成 | 全部真实路径已记录 |
| 双区并行策略 | ✅ 已确定 | 运行区 + 项目主目录分离 |
| 旧路径定位 | ✅ 已完成 | 9个文件已定位，2个需修复 |
| 未完成项清单 | ✅ 已完成 | 已分类记录 |
| 风险识别 | ✅ 已完成 | 3项风险、3项不确定已记录 |

**阶段1状态**: 基本完成，待完成业务前最小验收后可进入阶段2。

---

*报告生成完毕，等待业务前验收清单完成。*
