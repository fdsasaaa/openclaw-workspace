# 记忆规范与每日记忆文件模板

**生效日期**: 2026-03-05  
**版本**: v1.0  
**适用范围**: 所有 OpenClaw 会话记忆记录

---

## 一、记忆文件分类

| 类别 | 位置 | 用途 | 保留周期 |
|------|------|------|----------|
| **每日记忆** | `memory/YYYY-MM-DD.md` | 当日操作记录、决策、问题 | 90天后归档 |
| **长期记忆** | `workspace/MEMORY.md` | 持久化偏好、重要决策、身份 | 长期保留 |
| **任务检查点** | `memory/progress-<taskid>.json` | 长任务状态、续跑信息 | 任务完成后30天 |
| **Token用量** | `memory/usage-YYYY-MM-DD.json` | 每日API调用统计 | 365天后清理 |
| **安全事件** | `memory/security-incident-YYYY-MM-DD.md` | 安全相关事件记录 | 长期保留 |

---

## 二、每日记忆文件规范

### 2.1 文件名格式

```
memory/YYYY-MM-DD.md

示例:
memory/2026-03-05.md
```

### 2.2 文件结构模板

```markdown
# 2026-03-05 记忆

## 今日概要
- 主要任务: [阶段1收口/阶段2调研/...]
- 完成状态: [完成/进行中/阻塞]
- 使用模型: [kimi-coding/k2p5]

## 关键决策
| 决策 | 原因 | 影响 |
|------|------|------|
| [决策内容] | [为什么这样决定] | [后续影响] |

## 执行记录

### 任务1: [任务名称]
- **目标**: [任务目标]
- **步骤**: [1/3, 2/3, 3/3]
- **结果**: [成功/失败/部分完成]
- **输出**: [生成的文件/报告]
- **问题**: [遇到的问题]

### 任务2: [任务名称]
...

## 新增/修改文件
| 文件路径 | 操作 | 说明 |
|----------|------|------|
| `reports/xxx.md` | 新增 | 阶段X报告 |
| `configs/xxx.md` | 新增 | 规范文件 |

## 风险与问题
- [风险1]: [描述] → [处理状态]
- [风险2]: [描述] → [处理状态]

## 待办事项
- [ ] [待办1]（优先级: 高/中/低）
- [ ] [待办2]（优先级: 高/中/低）

## 反思与改进
- 今日做得好的: [内容]
- 可以改进的: [内容]

---
*生成时间: 2026-03-05 14:XX*  
*生成者: 虾哥 (kimi-coding/k2p5)*
```

### 2.3 写作原则

1. **事实为主**: 记录实际做了什么，而非计划做什么
2. **可追溯**: 每个决策都要有原因
3. **可验证**: 提及的文件路径要准确
4. **脱敏**: 敏感信息按 `security-reminder.md` 处理
5. **简洁**: 避免冗长描述，要点清晰

---

## 三、长期记忆（MEMORY.md）规范

### 3.1 更新时机

- 重要决策确定后
- 偏好/习惯变化后
- 每日记忆归档前（提炼重要内容）
- 阶段完成后（提炼阶段经验）

### 3.2 内容结构

```markdown
# MEMORY.md - 长期记忆

## 身份与偏好
- 我的名字: [虾哥]
- 用户的名字: [竹林]
- 交流语言: [中文]
- 表达风格: [简洁、务实]

## 重要决策记录
| 日期 | 决策 | 原因 | 状态 |
|------|------|------|------|
| 2026-03-05 | 采用双区并行策略 | 零迁移风险 | 生效中 |

## 技术偏好
- 工作区路径: `C:\OpenClaw_Workspace`
- 运行区路径: `C:\Users\ME\.openclaw\workspace`
- 主模型: `kimi-coding/k2p5`
- Fallback: `moonshot/kimi-k2.5`

## 经验教训
- [经验1]: [描述]
- [教训1]: [描述]

## 待长期关注
- [关注项1]: [描述]
```

---

## 四、检查点文件规范

### 4.1 用途

长任务续跑时使用，记录任务进度。

### 4.2 文件名格式

```
memory/progress-<taskid>.json

示例:
memory/progress-ea-optimize-001.json
```

### 4.3 JSON结构

```json
{
  "taskId": "ea-optimize-001",
  "taskName": "EA参数优化",
  "createdAt": "2026-03-05T14:00:00",
  "updatedAt": "2026-03-05T15:30:00",
  "totalSteps": 5,
  "completedSteps": 3,
  "steps": [
    {
      "step": 1,
      "name": "数据加载",
      "status": "done",
      "result": "成功加载 6883 行数据",
      "completedAt": "2026-03-05T14:05:00"
    },
    {
      "step": 2,
      "name": "参数初始化",
      "status": "done",
      "result": "EMA周期: 10-30, RSI周期: 10-20",
      "completedAt": "2026-03-05T14:10:00"
    },
    {
      "step": 3,
      "name": "优化执行",
      "status": "in_progress",
      "checkpoint": "已完成 EMA=10 批次",
      "progressPercent": 45
    },
    {
      "step": 4,
      "name": "结果分析",
      "status": "pending"
    },
    {
      "step": 5,
      "name": "输出报告",
      "status": "pending"
    }
  ],
  "metadata": {
    "lastModel": "kimi-coding/k2p5",
    "contextTokens": 45000,
    "dataFile": "C:\\OpenClaw_Workspace\\Data\\market_data.csv"
  }
}
```

---

## 五、Token用量记录规范

### 5.1 文件名格式

```
memory/usage-YYYY-MM-DD.json

示例:
memory/usage-2026-03-05.json
```

### 5.2 JSON结构

```json
{
  "date": "2026-03-05",
  "sessions": [
    {
      "sessionId": "xxx",
      "model": "kimi-coding/k2p5",
      "inputTokens": 15000,
      "outputTokens": 8000,
      "totalTokens": 23000
    }
  ],
  "dailyTotal": {
    "inputTokens": 15000,
    "outputTokens": 8000,
    "totalTokens": 23000
  }
}
```

---

## 六、修订记录

| 版本 | 日期 | 修订内容 |
|------|------|----------|
| v1.0 | 2026-03-05 | 初始版本，定义记忆文件分类与模板 |

---

*本规范由 OpenClaw 中枢协调器制定。*
