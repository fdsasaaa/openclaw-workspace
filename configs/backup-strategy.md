# 备份策略与目录使用规范

**生效日期**: 2026-03-05  
**版本**: v1.0  

---

## 一、备份策略总览

### 1.1 备份分类

| 类别 | 内容 | 频率 | 保留版本 | 存储位置 |
|------|------|------|----------|----------|
| **配置备份** | openclaw.json, auth-profiles.json | 修改前自动 | 10个 | `backup/config-YYYYMMDD-HHMMSS/` |
| **工作区备份** | workspace核心文件 | 每周 | 4个 | `backup/workspace-YYYYMMDD-HHMMSS/` |
| **记忆备份** | memory/ 目录 | 每日 | 30天 | `backup/memory-YYYYMMDD/` |
| **完整快照** | 整个 `.openclaw/` | 每月 | 3个 | 外部存储 |

### 1.2 当前已有备份

```
C:\OpenClaw_Workspace\backup\
├── openclaw-config-20260304-160820/     # 历史配置备份
│   ├── openclaw.json
│   ├── agents/main/agent/auth-profiles.json
│   └── ...
└── workspace-20260304-131412/           # 历史工作区备份
    ├── AGENTS.md
    ├── SOUL.md
    └── ...
```

**状态**: 历史备份保留，暂不清理。

---

## 二、目录使用规范

### 2.1 目录职责矩阵

| 目录 | 用途 | 写入权限 | 清理策略 |
|------|------|----------|----------|
| **`memory/`** | 每日记忆、检查点、token用量 | 自动+人工 | 90天后归档 |
| **`logs/`** | 操作日志、运行日志 | 自动 | 30天后清理 |
| **`reports/`** | 阶段报告、分析报告 | 人工 | 长期保留 |
| **`temp/`** | 临时文件、缓存 | 自动+人工 | 7天后自动清理 |
| **`configs/`** | 配置文件、规范文档 | 人工 | 长期保留，版本控制 |
| **`Data/`** | 数据文件、输入源 | 人工 | 长期保留 |
| **`projects/`** | 项目代码 | 人工 | 长期保留，Git管理 |
| **`skills/`** | 自定义技能 | 人工 | 长期保留 |

### 2.2 写入规则

**必须写入 `memory/`**:
- 每日记忆文件 (`YYYY-MM-DD.md`)
- 长任务检查点 (`progress-*.json`)
- Token用量统计 (`usage-*.json`)

**必须写入 `logs/`**:
- 操作日志 (`operations-*.log`)
- 脚本执行日志
- 错误日志

**必须写入 `reports/`**:
- 阶段报告 (`stage*-*.md`)
- 分析报告
- 调研报告

**必须写入 `configs/`**:
- 执行规范 (`execution-rules.md`)
- 安全提醒 (`security-reminder.md`)
- 记忆规范 (`memory-spec.md`)

### 2.3 禁止写入区域

**禁止写入运行区** (`C:\Users\ME\.openclaw\workspace\`):
- 每日记忆（改写入 `memory/`）
- 日志文件（改写入 `logs/`）
- 临时文件（改写入 `temp/`）
- 大数据文件（改写入 `Data/`）

例外：核心配置文件（AGENTS.md, SOUL.md等）更新需人工确认。

---

## 三、自动备份脚本（参考）

### 3.1 配置备份

```powershell
# 备份 openclaw.json
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = "C:\OpenClaw_Workspace\backup\config-$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force
Copy-Item "~\.openclaw\openclaw.json" "$backupDir\"
Copy-Item "~\.openclaw\agents\main\agent\auth-profiles.json" "$backupDir\"
```

### 3.2 工作区备份

```powershell
# 备份 workspace
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = "C:\OpenClaw_Workspace\backup\workspace-$timestamp"
Copy-Item "C:\OpenClaw_Workspace\workspace" "$backupDir" -Recurse
```

### 3.3 清理旧备份

```powershell
# 保留最近10个配置备份
Get-ChildItem "C:\OpenClaw_Workspace\backup\config-*" |
    Sort-Object CreationTime -Descending |
    Select-Object -Skip 10 |
    Remove-Item -Recurse -Force
```

---

## 四、灾难恢复预案

### 4.1 场景1: OpenClaw配置损坏

**恢复步骤**:
1. 停止 Gateway: `openclaw gateway stop`
2. 从 `backup/config-*/` 复制 `openclaw.json` 到 `~/.openclaw/`
3. 重启 Gateway: `openclaw gateway start`
4. 验证: `openclaw gateway status`

### 4.2 场景2: 工作区丢失

**恢复步骤**:
1. 从 `backup/workspace-*/` 复制文件到 `C:\OpenClaw_Workspace\workspace\`
2. 检查 Git 状态: `git status`
3. 恢复未提交更改（如有）

### 4.3 场景3: 记忆文件丢失

**恢复步骤**:
1. 从 `backup/memory-*/` 恢复
2. 如无备份，依赖长期记忆 `MEMORY.md` 重建上下文

---

## 五、修订记录

| 版本 | 日期 | 修订内容 |
|------|------|----------|
| v1.0 | 2026-03-05 | 初始版本 |

---

*本规范由 OpenClaw 中枢协调器制定。*
