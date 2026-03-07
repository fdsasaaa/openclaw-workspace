# OpenClaw 目录结构规范

## 快速参考

| 目录 | 路径 | 用途 | 可迁移 |
|-----|------|------|-------|
| **安装目录** | `C:\Users\Administrator\AppData\Roaming\npm\node_modules\openclaw` | OpenClaw 核心程序、官方技能 | ❌ 否 |
| **配置目录** | `C:\Users\Administrator\.openclaw` | 主配置、网关、日志、Agent 运行时 | ⚠️ 部分 |
| **用户工作区** | `E:\OpenClaw_Workspace\workspace` | SOUL.md, AGENTS.md, USER.md 等 | ✅ 是 |
| **记忆目录** | `E:\OpenClaw_Workspace\memory` | 记忆文件 (YYYY-MM-DD.md) | ✅ 是 |
| **项目目录** | `E:\OpenClaw_Workspace\projects` | 项目代码 | ✅ 是 |
| **自定义技能** | `E:\OpenClaw_Workspace\skills` | 用户自定义技能 | ✅ 是 |
| **日志目录** | `E:\OpenClaw_Workspace\logs` | 用户日志（系统日志仍在 C 盘） | ✅ 是 |
| **缓存目录** | `E:\OpenClaw_Workspace\cache` | 临时缓存 | ✅ 是 |
| **临时目录** | `E:\OpenClaw_Workspace\temp` | 临时文件 | ✅ 是 |
| **备份目录** | `E:\OpenClaw_Workspace\backup` | 自动备份 | ✅ 是 |
| **配置目录** | `E:\OpenClaw_Workspace\configs` | 用户配置/项目配置 | ✅ 是 |
| **报告目录** | `E:\OpenClaw_Workspace\reports` | 输出报告/文档 | ✅ 是 |

---

## 详细说明

### 🔒 必须保留在 C 盘（系统级）

```
C:\Users\Administrator\AppData\Roaming\npm\node_modules\openclaw\
├── dist/              # 编译后的程序
├── skills/            # 官方技能（不要手动修改）
├── docs/              # 官方文档
└── node_modules/      # 依赖

C:\Users\Administrator\.openclaw\
├── openclaw.json      # 主配置文件
├── gateway.cmd        # 网关启动脚本
├── logs/              # 系统日志
├── agents/            # Agent 运行时数据
├── devices/           # 设备配置
├── identity/          # 身份配置
├── canvas/            # Canvas 数据
└── cron/              # 定时任务配置
```

**原因：** 这些是 OpenClaw 的核心运行文件，移动会导致程序无法启动。

---

### ✅ 已迁移/可迁移到 E 盘（用户数据）

```
E:\OpenClaw_Workspace\
├── workspace/         # 主工作区
│   ├── SOUL.md
│   ├── AGENTS.md
│   ├── USER.md
│   ├── IDENTITY.md
│   ├── TOOLS.md
│   └── HEARTBEAT.md
├── memory/            # 记忆文件
│   ├── 2026-03-04.md
│   └── ...
├── projects/          # 项目代码
│   └── (你的项目)
├── skills/            # 自定义技能
│   └── (你的技能)
├── logs/              # 用户日志
├── cache/             # 缓存
├── temp/              # 临时文件
└── backup/            # 备份
    └── workspace-YYYYMMDD-HHMMSS/
```

**当前配置状态：**
- 工作区路径：`C:\Users\Administrator\.openclaw\workspace`（仍指向 C 盘）
- 如需完全迁移到 E 盘，需修改 `C:\Users\Administrator\.openclaw\openclaw.json`

---

## 迁移状态

| 项目 | 状态 | 说明 |
|-----|------|------|
| E 盘目录结构 | ✅ 已完成 | 所有标准目录已创建 |
| 工作区迁移 | ⏸️ 待执行 | 配置仍指向 C 盘 |
| 记忆目录 | ⏸️ 待执行 | 当前在 C 盘 workspace 内 |
| 项目目录 | ✅ 就绪 | E 盘 projects/ 已创建 |

---

## 下一步建议

### 方案 A：完全迁移到 E 盘（推荐）

1. 修改 `C:\Users\Administrator\.openclaw\openclaw.json`：
   ```json
   "agents": {
     "defaults": {
       "workspace": "E:\\OpenClaw_Workspace\\workspace"
     }
   }
   ```

2. 将 C 盘 workspace 内容同步到 E 盘

3. 重启 OpenClaw Gateway

### 方案 B：保持现状，仅规范新文件

- 新记忆文件写到 `E:\OpenClaw_Workspace\memory\`
- 新项目放到 `E:\OpenClaw_Workspace\projects\`
- C 盘 workspace 仅保留核心配置文件

---

## 快捷引用

如需快速访问，可在桌面创建快捷方式：
- `E:\OpenClaw_Workspace\workspace` → 工作区
- `E:\OpenClaw_Workspace\projects` → 项目
- `E:\OpenClaw_Workspace\memory` → 记忆

---

_最后更新：2026-03-04_
