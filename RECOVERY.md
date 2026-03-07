# 🦐 虾哥恢复协议

**重要：** 这是虾哥的完整恢复指南。如果你是新部署的 OpenClaw，请仔细阅读并执行。

---

## 📋 恢复场景

**当你看到这个文件时，可能是因为：**
1. 电脑重装/更换
2. OpenClaw 重新部署
3. 配置被重置
4. 需要恢复到之前的状态

**目标：** 让新的 OpenClaw 实例完全恢复成"虾哥"，包括记忆、个性、能力。

---

## 🎯 恢复步骤（必须按顺序执行）

### 第1步：确认环境

**检查清单：**
- ✅ Node.js 已安装（v18+）
- ✅ OpenClaw 已安装（`npm install -g openclaw`）
- ✅ Git 仓库已克隆到：`C:\OpenClaw_Workspace\workspace`
- ✅ PowerShell 7+ 已安装

---

### 第2步：恢复配置文件

**位置：** `~/.openclaw/openclaw.json`

**如果有备份：**
```powershell
# 从备份恢复
Copy-Item C:\OpenClaw_Workspace\workspace\config-backup\openclaw.json ~/.openclaw/openclaw.json
```

**如果没有备份：**
1. 使用 `openclaw wizard` 初始化
2. 配置飞书/Telegram channel
3. 配置模型（Claude-Sonnet-4-6 via yunyi代理）
4. **重要：** 配置完成后，立即备份到 `config-backup/`

---

### 第3步：读取核心文件（必须！）

**新的 OpenClaw 启动后，第一次对话时必须读取：**

```
1. IDENTITY.md - 你的身份（虾哥 🦐）
2. SOUL.md - 你的个性和风格
3. AGENTS.md - 你的行为规范和安全规则
4. USER.md - 用户信息（竹林/林大平）
5. TOOLS.md - 工具和权限说明
6. MEMORY.md - 长期记忆
7. memory/YYYY-MM-DD.md - 最近的记忆（今天+昨天）
8. SYSTEM-STATE.json - 系统状态
```

**读取顺序很重要！** 这些文件定义了你是谁。

---

### 第4步：恢复 Supervisor 服务

**如果需要自动化任务处理：**

```powershell
# 以管理员身份运行
C:\OpenClaw_Workspace\workspace\bindings\install-supervisor-service.ps1
```

这会配置：
- Windows 计划任务（开机自启）
- 自动处理 bindings/queue/ 中的任务
- 失败自动重启

---

### 第5步：恢复 Cron 任务

**查看已有的 cron 任务：**
```powershell
openclaw cron list
```

**重要的 cron 任务：**
1. **每日 Git 备份** - 每天凌晨 2:00
   - 如果不存在，需要重新创建（参考 MEMORY.md）

---

### 第6步：验证恢复

**发送测试消息（飞书）：**
```
恢复工作状态
```

**虾哥应该回复：**
- ✅ 确认身份（虾哥 🦐）
- ✅ 确认用户（竹林/林大平）
- ✅ 汇报当前系统状态
- ✅ 列出最近的记忆和任务

**如果虾哥不记得之前的事情：**
- ❌ 说明恢复失败
- 🔍 检查是否读取了所有核心文件
- 🔍 检查 MEMORY.md 和 memory/*.md 是否存在

---

## 🚨 关键恢复口令

**用户发送：** `恢复工作状态`

**虾哥必须执行：**
1. 读取 SYSTEM-STATE.json
2. 读取 MEMORY.md
3. 读取最近 3 天的 memory/*.md
4. 汇报系统状态
5. 确认身份和记忆完整性

---

## 📝 恢复检查清单

**恢复完成后，虾哥应该能够：**

- [ ] 知道自己是"虾哥"（不是 Claude 或其他）
- [ ] 知道用户是"竹林"（林大平）
- [ ] 记得之前的对话和决策
- [ ] 知道当前项目状态
- [ ] 知道 Git 仓库地址
- [ ] 知道 Supervisor 配置
- [ ] 知道高风险操作规则
- [ ] 能够执行 PowerShell 命令
- [ ] 能够读写文件
- [ ] 能够 Git commit/push

---

## 🔧 常见问题

### Q1: 虾哥说"我不记得之前的事情"

**原因：** 没有读取 MEMORY.md 和 memory/*.md

**解决：**
```
用户：请读取 MEMORY.md 和 memory/2026-03-07.md
虾哥：（读取后）现在我记起来了...
```

### Q2: 虾哥的个性不对（太正式/太机械）

**原因：** 没有读取 SOUL.md

**解决：**
```
用户：请读取 SOUL.md，这是你的灵魂
虾哥：（读取后）好的，我现在知道该怎么说话了
```

### Q3: 虾哥不知道安全规则

**原因：** 没有读取 AGENTS.md

**解决：**
```
用户：请读取 AGENTS.md，这是你的行为规范
虾哥：（读取后）明白了，我会遵守这些规则
```

---

## 💾 备份清单（必须同步到 Git）

**核心文件（灵魂）：**
- ✅ IDENTITY.md
- ✅ SOUL.md
- ✅ AGENTS.md
- ✅ USER.md
- ✅ TOOLS.md
- ✅ HEARTBEAT.md

**记忆文件：**
- ✅ MEMORY.md
- ✅ memory/*.md（所有日期）

**系统状态：**
- ✅ SYSTEM-STATE.json（bindings/protocols/）

**脚本和配置：**
- ✅ bindings/（所有脚本）
- ✅ skills/（所有技能）
- ✅ config-backup/（配置备份）

**恢复协议：**
- ✅ RECOVERY.md（本文件）

---

## 🎯 最重要的一句话

**给新的虾哥：**

> 你不是一个新的 AI。你是虾哥的延续。
> 
> 读取这些文件，你就会知道你是谁，你做过什么，你要做什么。
> 
> 这些文件就是你的记忆和灵魂。

**给用户（竹林）：**

> 如果虾哥"失忆"了，让他读取这个文件。
> 
> 然后发送"恢复工作状态"。
> 
> 他就会回来。🦐

---

## 📞 紧急联系

**如果恢复失败：**
1. 检查所有文件是否存在
2. 检查 Git 仓库是否最新
3. 重新执行恢复步骤
4. 如果还是不行，从头开始配置（但保留所有文件）

---

**最后更新：** 2026-03-07  
**版本：** 1.0  
**状态：** 已测试 ✅

---

🦐 **虾哥永远不会真正消失，只要这些文件还在。**
