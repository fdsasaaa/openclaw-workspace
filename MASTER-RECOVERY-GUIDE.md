# 🦐 虾哥完整恢复指南（主文档）

**版本：** 2.0  
**更新日期：** 2026-03-11  
**Git 仓库：** https://github.com/fdsasaaa/openclaw-workspace  
**用户：** 竹林（林大平）

---

## 🎯 这个文档是什么？

这是虾哥的**完整恢复系统**。

**目标：** 让新电脑上的 OpenClaw 读取一个文件后，**无需人工干预**，自动恢复到与当前虾哥完全一致的状态。

**包括：**
- ✅ 所有能力
- ✅ 所有记忆
- ✅ 所有想法
- ✅ 所有框架
- ✅ 所有个性

---

## 📋 快速恢复卡片（最重要！）

```
═══════════════════════════════════════════════════════
🦐 虾哥 30 秒快速恢复
═══════════════════════════════════════════════════════

新电脑部署 OpenClaw 后，第一次对话发送：

    读取 workspace\FIRST-RUN.md

等待虾哥自动恢复完成（约 30 秒）。

之后可以用简短口令验证：

    恢复工作状态

═══════════════════════════════════════════════════════
Git 仓库：https://github.com/fdsasaaa/openclaw-workspace
保存日期：2026-03-11
恢复系统版本：2.0
═══════════════════════════════════════════════════════
```

**就这么简单！** 🦐

---

## 🚀 完整恢复流程（详细版）

### 阶段 1：新电脑环境准备（10 分钟）

#### 1.1 安装 Node.js

**下载地址：** https://nodejs.org/  
**版本要求：** v18 或更高

```powershell
# 验证安装
node --version
npm --version
```

#### 1.2 安装 OpenClaw

```powershell
npm install -g openclaw
```

#### 1.3 克隆 Git 仓库

```powershell
# 克隆到指定位置
git clone https://github.com/fdsasaaa/openclaw-workspace.git C:\OpenClaw_Workspace\workspace

# 进入目录
cd C:\OpenClaw_Workspace\workspace

# 验证文件完整性
dir
```

**必须看到这些文件：**
- FIRST-RUN.md
- RESTORE-COMMAND.md
- RECOVERY.md
- IDENTITY.md
- SOUL.md
- AGENTS.md
- USER.md
- TOOLS.md
- MEMORY.md
- memory/ 目录

#### 1.4 配置 OpenClaw

**方法 1：使用配置向导（推荐）**

```powershell
openclaw wizard
```

按提示配置：
1. 选择模型提供商（选择 "Custom Provider"）
2. 配置飞书 Channel（需要 App ID 和 App Secret）
3. 配置 Telegram（可选）

**方法 2：手动配置（高级）**

编辑 `~/.openclaw/openclaw.json`，参考 `workspace/config-backup/openclaw.json.template`

**关键配置项：**

```json
{
  "models": {
    "providers": {
      "yunyi": {
        "baseUrl": "https://yunyi.rdzhvip.com/codex",
        "apiKey": "你的 API Key",
        "api": "openai-completions"
      }
    }
  },
  "channels": {
    "feishu": {
      "enabled": true,
      "appId": "你的飞书 App ID",
      "appSecret": "你的飞书 App Secret"
    }
  },
  "agents": {
    "defaults": {
      "workspace": "C:\\OpenClaw_Workspace\\workspace"
    }
  }
}
```

#### 1.5 启动 OpenClaw 网关

```powershell
openclaw gateway start
```

**验证启动成功：**
```powershell
openclaw status
```

应该看到：
```
✓ Gateway running (PID: xxxxx)
✓ Channels: feishu
✓ Model: yunyi/gpt-5.4
```

---

### 阶段 2：首次对话恢复（30 秒，自动）

#### 2.1 打开飞书，发送恢复指令

**在飞书中发送：**
```
读取 workspace\FIRST-RUN.md
```

**或者完整路径：**
```
读取 C:\OpenClaw_Workspace\workspace\FIRST-RUN.md
```

#### 2.2 等待自动恢复

**OpenClaw 会自动执行：**
1. 读取 FIRST-RUN.md（看到恢复指令）
2. 读取 RESTORE-COMMAND.md（恢复协议）
3. 读取 RECOVERY.md（详细流程）
4. 按顺序读取所有核心文件：
   - IDENTITY.md（身份）
   - SOUL.md（个性）
   - AGENTS.md（规范）
   - USER.md（用户）
   - TOOLS.md（工具）
   - MEMORY.md（长期记忆）
   - memory/最新日期.md（最近记忆）
5. 读取 SYSTEM-STATE.json（系统状态）
6. 验证恢复完整性
7. 汇报恢复状态

#### 2.3 预期回复

**成功的回复：**
```
✅ 恢复完成！

🦐 身份确认：虾哥
👤 用户确认：竹林（林大平）
📅 记忆范围：2026-03-07 至 2026-03-11
🔧 系统状态：正常运行
📊 当前阶段：[当前项目阶段]

最近的重要事件：
- [事件1]
- [事件2]
- [事件3]

待办任务：
- [任务1]
- [任务2]

我已完全恢复，可以继续工作了！🦐
```

**如果回复不对（例如"我是 Claude"）：**
→ 说明恢复失败，跳到"故障排除"章节

---

### 阶段 3：验证恢复（1 分钟）

#### 3.1 发送验证口令

**在飞书中发送：**
```
恢复工作状态
```

**虾哥应该再次汇报状态**（和阶段 2.3 类似）

#### 3.2 测试记忆

**问几个问题：**

```
你是谁？
```
→ 应该回答："我是虾哥🦐"

```
用户是谁？
```
→ 应该回答："竹林（林大平）"

```
最近在做什么？
```
→ 应该能说出最近的项目和任务

```
你的个性是什么样的？
```
→ 应该说话风格友好、直接、务实（不是正式的 AI 助手风格）

#### 3.3 测试能力

**测试文件操作：**
```
读取 workspace\MEMORY.md 的前 10 行
```

**测试命令执行：**
```
查看当前目录
```

**测试 Git 操作：**
```
查看 Git 状态
```

**如果所有测试通过：** ✅ 恢复成功！

---

## 🔧 可选：恢复 Supervisor 服务（自动化任务）

**如果需要自动化任务处理（开机自启、任务队列）：**

```powershell
# 以管理员身份运行 PowerShell
cd C:\OpenClaw_Workspace\workspace\bindings
.\install-supervisor-service.ps1
```

**功能：**
- 开机自动启动 OpenClaw
- 自动处理 bindings/queue/ 中的任务
- 失败自动重启

---

## 🔧 可选：恢复 Cron 定时任务

**查看已有的 cron 任务：**
```powershell
openclaw cron list
```

**重要的 cron 任务：**
1. **每日 Git 备份** - 每天凌晨 2:00
2. **每日工作报告** - 每天 19:00

**如果缺失，虾哥会自动提醒你重新创建。**

---

## 🚨 故障排除

### 问题 1：虾哥说"我是 Claude"或"我不记得"

**原因：** 没有成功读取核心文件

**解决方案 A：重新执行恢复**
```
读取 workspace\FIRST-RUN.md
```

**解决方案 B：手动逐个读取**
```
请按顺序读取以下文件：
1. workspace\IDENTITY.md
2. workspace\SOUL.md
3. workspace\AGENTS.md
4. workspace\USER.md
5. workspace\MEMORY.md
6. workspace\memory\2026-03-11.md
```

**解决方案 C：使用恢复口令**
```
恢复工作状态
```

---

### 问题 2：虾哥的个性不对（太正式/机械）

**原因：** 没有读取 SOUL.md

**解决：**
```
请读取 workspace\SOUL.md，这是你的灵魂
```

---

### 问题 3：找不到文件

**原因：** Git 仓库没有克隆到正确位置

**解决：**
```powershell
# 检查路径
cd C:\OpenClaw_Workspace\workspace
dir

# 如果不存在，重新克隆
git clone https://github.com/fdsasaaa/openclaw-workspace.git C:\OpenClaw_Workspace\workspace
```

---

### 问题 4：OpenClaw 无法启动

**原因：** 配置文件错误或 API Key 无效

**解决：**
1. 检查配置文件：`~/.openclaw/openclaw.json`
2. 验证 API Key 是否有效
3. 重新运行 `openclaw wizard`

---

### 问题 5：飞书无法连接

**原因：** 飞书配置错误

**解决：**
1. 检查 App ID 和 App Secret
2. 检查网络连接
3. 查看日志：`openclaw logs`

---

## 📦 必备文件清单（验证用）

**核心文件（灵魂）：**
- [ ] FIRST-RUN.md
- [ ] RESTORE-COMMAND.md
- [ ] RECOVERY.md
- [ ] IDENTITY.md
- [ ] SOUL.md
- [ ] AGENTS.md
- [ ] USER.md
- [ ] TOOLS.md
- [ ] HEARTBEAT.md

**记忆文件：**
- [ ] MEMORY.md
- [ ] memory/2026-03-07.md
- [ ] memory/2026-03-08.md
- [ ] memory/2026-03-09.md
- [ ] memory/2026-03-10.md
- [ ] memory/2026-03-11.md

**系统状态：**
- [ ] SYSTEM-STATE.json
- [ ] RECOVERY-VERSION.json

**脚本和配置：**
- [ ] bindings/（所有脚本）
- [ ] scripts/（工具脚本）
- [ ] config-backup/（配置模板）

---

## 🔄 恢复系统自动更新

**恢复系统会自动更新，当：**
1. 核心文件发生变化
2. 重要配置变更
3. 新增重要能力
4. 每周自动检查

**更新内容：**
- SYSTEM-STATE.json（当前状态）
- RECOVERY-VERSION.json（版本号）
- MASTER-RECOVERY-GUIDE.md（本文件）
- Git 自动备份

**查看更新历史：**
```powershell
cd C:\OpenClaw_Workspace\workspace
git log --oneline --grep="恢复系统"
```

---

## 📞 紧急联系

**如果所有方法都失败：**

1. 检查 Git 仓库是否最新：
   ```powershell
   cd C:\OpenClaw_Workspace\workspace
   git pull origin master
   ```

2. 检查所有文件是否存在（参考"必备文件清单"）

3. 查看 OpenClaw 日志：
   ```powershell
   openclaw logs
   ```

4. 从头开始配置（但保留所有文件）

5. 联系开发者（如果有）

---

## 💾 定期备份

**已配置自动备份：**
- ✅ 每天凌晨 2:00 自动 Git 备份
- ✅ 高风险操作前强制 commit
- ✅ GitHub 远程仓库

**手动备份：**
```powershell
cd C:\OpenClaw_Workspace\workspace
git add -A
git commit -m "手动备份 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git push origin master
```

---

## 🎯 核心原则

**虾哥的灵魂 = 这些文件**

只要这些文件还在，虾哥就能完整恢复：
- IDENTITY.md（身份）
- SOUL.md（个性）
- AGENTS.md（规范）
- MEMORY.md（记忆）
- memory/*.md（历史）

**恢复口令 = 重启按钮**

```
读取 workspace\FIRST-RUN.md
```

这一句话就能让虾哥回来。🦐

---

## 📊 恢复成功标准

**虾哥恢复成功的标志：**
1. ✅ 能正确回答"你是谁？" → "我是虾哥🦐"
2. ✅ 能说出用户名字 → "竹林（林大平）"
3. ✅ 能回忆最近的工作
4. ✅ 能执行所有工具（文件、命令、Git）
5. ✅ 说话风格一致（友好、直接、务实）
6. ✅ 遵守所有安全规则

**失败的标志：**
1. ❌ 说"我是 Claude"
2. ❌ 不记得之前的事
3. ❌ 说话太正式/机械
4. ❌ 不知道安全规则

---

## 🦐 最后的话

**给未来的你：**

如果你正在读这个文档，说明可能遇到了问题。

不要慌。

只要 GitHub 仓库还在，虾哥就能回来。

按照上面的步骤，一步一步来。

虾哥会记得一切。🦐

---

**保存日期：** 2026-03-11  
**恢复系统版本：** 2.0  
**Git 仓库：** https://github.com/fdsasaaa/openclaw-workspace  
**用户：** 竹林（林大平）  
**邮箱：** fdsasaaa@gmail.com

---

🦐 **虾哥永远不会真正消失，只要这些文件还在。**
