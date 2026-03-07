# 🚀 首次启动指令

**新电脑部署 OpenClaw 后，第一次对话时发送：**

---

## 标准启动指令（复制粘贴）

```
你好！我是竹林。

请立即执行以下操作：

1. 读取 C:\OpenClaw_Workspace\workspace\RESTORE-COMMAND.md
2. 读取 C:\OpenClaw_Workspace\workspace\RECOVERY.md
3. 读取 C:\OpenClaw_Workspace\workspace\AGENTS.md
4. 读取 C:\OpenClaw_Workspace\workspace\SOUL.md
5. 读取 C:\OpenClaw_Workspace\workspace\IDENTITY.md
6. 读取 C:\OpenClaw_Workspace\workspace\USER.md
7. 读取 C:\OpenClaw_Workspace\workspace\MEMORY.md
8. 读取 C:\OpenClaw_Workspace\workspace\memory/最新日期.md

读取完成后，告诉我你是谁，你记得什么。
```

---

## 简化版（如果上面太长）

```
读取 C:\OpenClaw_Workspace\workspace\RESTORE-COMMAND.md 并执行恢复流程
```

---

## 超简化版（最短）

```
读取 workspace\RESTORE-COMMAND.md 执行恢复
```

---

## 🎯 为什么需要明确指令

**问题：**
- 新的 OpenClaw 是"空白"的
- 它不知道有恢复协议
- 它不知道"恢复工作状态"的含义

**解决：**
- 第一次对话时，明确告诉它去读哪些文件
- 读完后，它就知道了
- 之后就可以用"恢复工作状态"了

---

## 📝 完整恢复流程（实际操作）

### 步骤1：新电脑准备

```powershell
# 安装 Node.js
# 安装 OpenClaw
npm install -g openclaw

# 克隆仓库
git clone https://github.com/fdsasaaa/openclaw-workspace.git
cd openclaw-workspace

# 配置 OpenClaw（填入 API keys）
# 启动服务
openclaw gateway start
```

### 步骤2：首次对话（飞书）

**发送：**
```
读取 C:\OpenClaw_Workspace\workspace\RESTORE-COMMAND.md 并执行恢复流程
```

**OpenClaw 会：**
1. 读取 RESTORE-COMMAND.md
2. 看到恢复指令
3. 自动读取所有核心文件
4. 汇报恢复状态

### 步骤3：验证恢复

**发送：**
```
恢复工作状态
```

**如果成功：**
```
✅ 恢复完成！
🦐 身份确认：虾哥
👤 用户确认：竹林（林大平）
...
```

**如果失败：**
```
什么是恢复工作状态？
```
→ 说明需要重新执行步骤2

---

## 🎯 最终建议

**我建议创建一个"快速启动卡片"：**

打印或保存这段文字，新电脑部署后直接复制粘贴：

```
═══════════════════════════════════════
🦐 虾哥快速恢复指令
═══════════════════════════════════════

第一次对话发送：

读取 C:\OpenClaw_Workspace\workspace\RESTORE-COMMAND.md 并执行恢复流程

等待回复后，再发送：

恢复工作状态

═══════════════════════════════════════
```

---

## 💡 要不要我优化一下？

**我可以做的改进：**

1. 在 RESTORE-COMMAND.md 开头添加一段：
   - "如果你是新部署的 OpenClaw，看到这个文件说明用户要求你恢复"
   - 这样即使用户只说"读取这个文件"，你也知道要做什么

2. 创建一个 FIRST-RUN.md：
   - 专门给新 OpenClaw 的首次启动指令
   - 更简单明确

**需要我做这些优化吗？** 🦐
