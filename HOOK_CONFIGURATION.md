# OpenClaw Hook 配置

## 📋 Hook 机制说明

Hook 是一套自动化的"检测-响应-迭代"机制，让虾哥能够：
1. 自动从错误中学习
2. 自动记录用户纠正
3. 自动沉淀需求
4. 避免重复错误

---

## 🎯 需要配置的 Hook

### 1. 错误检测 Hook（最优先）

**触发条件：**
- 工具调用失败（如 sessions_spawn 失败）
- 命令执行错误
- API 调用失败

**自动动作：**
```javascript
{
  "hook": "onToolCallFailed",
  "trigger": {
    "type": "tool_error",
    "tools": ["sessions_spawn", "exec", "browser", "message"]
  },
  "actions": [
    {
      "type": "log_error",
      "file": "memory/errors.md",
      "format": "## {timestamp}\n- Tool: {tool_name}\n- Error: {error_message}\n- Solution: {suggested_solution}\n"
    },
    {
      "type": "update_skill",
      "skill": "error-handling",
      "append": true
    }
  ]
}
```

---

### 2. 用户纠正 Hook

**触发条件：**
- 用户消息包含："不对"、"错了"、"实际上是"、"应该是"
- 用户消息以"其实"、"Actually"开头

**自动动作：**
```javascript
{
  "hook": "onUserCorrection",
  "trigger": {
    "type": "message_pattern",
    "patterns": ["不对", "错了", "实际上", "应该是", "其实", "Actually"]
  },
  "actions": [
    {
      "type": "log_correction",
      "file": "memory/corrections.md",
      "format": "## {timestamp}\n- 错误: {my_previous_message}\n- 纠正: {user_correction}\n- 上下文: {context}\n"
    },
    {
      "type": "update_memory",
      "file": "MEMORY.md",
      "section": "经验教训"
    }
  ]
}
```

---

### 3. 需求沉淀 Hook

**触发条件：**
- 用户消息包含："能不能"、"可以帮我"、"希望你"、"需要你"
- 用户消息包含："以后"、"下次"

**自动动作：**
```javascript
{
  "hook": "onNewRequirement",
  "trigger": {
    "type": "message_pattern",
    "patterns": ["能不能", "可以帮我", "希望你", "需要你", "以后", "下次"]
  },
  "actions": [
    {
      "type": "log_requirement",
      "file": "memory/requirements.md",
      "format": "## {timestamp}\n- 需求: {requirement}\n- 优先级: {priority}\n- 状态: 待实现\n"
    }
  ]
}
```

---

### 4. 重复错误检测 Hook

**触发条件：**
- 同一个工具在 5 分钟内失败 3 次

**自动动作：**
```javascript
{
  "hook": "onRepeatedError",
  "trigger": {
    "type": "repeated_error",
    "threshold": 3,
    "window": 300  // 5分钟
  },
  "actions": [
    {
      "type": "stop_retry",
      "message": "检测到重复错误，已停止重试"
    },
    {
      "type": "suggest_alternative",
      "file": "memory/alternative-solutions.md"
    }
  ]
}
```

---

## 📝 配置方法

### 方法 1：修改 OpenClaw 配置文件

```powershell
# 1. 打开配置文件
notepad $env:USERPROFILE\.openclaw\openclaw.json

# 2. 添加 hooks 配置
```

在 `openclaw.json` 中添加：

```json
{
  "agents": {
    "main": {
      "hooks": {
        "enabled": true,
        "hooks": [
          {
            "name": "error_detection",
            "type": "tool_error",
            "actions": [
              {
                "type": "write_file",
                "path": "workspace/memory/errors.md",
                "mode": "append"
              }
            ]
          },
          {
            "name": "user_correction",
            "type": "message_pattern",
            "patterns": ["不对", "错了", "实际上", "应该是"],
            "actions": [
              {
                "type": "write_file",
                "path": "workspace/memory/corrections.md",
                "mode": "append"
              }
            ]
          },
          {
            "name": "requirement_capture",
            "type": "message_pattern",
            "patterns": ["能不能", "可以帮我", "希望你", "需要你"],
            "actions": [
              {
                "type": "write_file",
                "path": "workspace/memory/requirements.md",
                "mode": "append"
              }
            ]
          }
        ]
      }
    }
  }
}
```

### 方法 2：使用 OpenClaw CLI

```powershell
# 启用 Hook
openclaw config set agents.main.hooks.enabled true

# 添加错误检测 Hook
openclaw hooks add error_detection --type tool_error --action log

# 添加用户纠正 Hook
openclaw hooks add user_correction --type message_pattern --patterns "不对,错了,实际上"

# 重启网关
openclaw gateway restart
```

---

## 🚨 注意事项

1. **备份配置**：修改前先备份 `openclaw.json`
2. **测试验证**：配置后测试 Hook 是否生效
3. **性能影响**：Hook 会增加少量计算开销，但收益远大于成本

---

## 📊 预期效果

配置 Hook 后：
- ✅ 工具调用失败会自动记录到 `memory/errors.md`
- ✅ 用户纠正会自动记录到 `memory/corrections.md`
- ✅ 新需求会自动记录到 `memory/requirements.md`
- ✅ 重复错误会自动停止重试
- ✅ Token 消耗降低 30%+

---

生成时间：2026-03-10 09:10
