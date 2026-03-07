# Skills 使用习惯养成系统

## 🎯 目标

**让所有已安装的 skills 都能成为习惯性反应，不会"安装后就忘记"。**

---

## 📋 Skills 清单与触发条件

### 已安装的 Skills（自动更新）

| Skill | 触发条件 | 命令模板 | 最后使用 |
|-------|---------|---------|---------|
| summarize | 看到 URL/YouTube 链接 | `summarize "URL" --youtube auto` | - |
| youtube-watcher | 需要视频转录 | `python3 scripts/get_transcript.py "URL"` | - |
| video-subtitles | 需要生成字幕 | `./scripts/generate_srt.py video.mp4 --srt` | - |
| video-frames | 需要提取画面 | `scripts/frame.sh video.mp4 --time XX --out frame.jpg` | - |
| weather | 用户问天气 | 使用 weather skill | - |
| github | 需要操作 GitHub | 使用 gh CLI | - |
| coding-agent | 需要编写代码 | 使用 coding-agent | - |

---

## 🔄 每日启动检查清单

**每次启动时（读取 AGENTS.md 后），自动执行：**

1. **扫描 skills/ 目录**
   - 列出所有已安装的 skills
   - 更新上面的清单

2. **回顾昨天使用情况**
   - 哪些 skills 用了？
   - 哪些 skills 该用但没用？

3. **今日提醒**
   - 今天可能会用到哪些 skills？
   - 提前准备

---

## 🧠 习惯养成机制

### 阶段1：主动提醒（第1周）

**每次遇到任务时，问自己：**
1. 这个任务有对应的 skill 吗？
2. 如果有，为什么没想起来？
3. 立即使用，并记录

**记录格式（memory/YYYY-MM-DD.md）：**
```markdown
## Skills 使用记录

- 18:30 - 使用 summarize 分析 YouTube 视频
- 19:15 - 应该用 video-frames 但忘记了，下次记得
```

### 阶段2：条件反射（第2-3周）

**建立触发词 → Skill 的条件反射：**

| 触发词 | 立即想到的 Skill |
|--------|----------------|
| YouTube/视频链接 | summarize |
| 天气 | weather |
| GitHub/PR/issue | github |
| 写代码/重构 | coding-agent |
| 生成字幕 | video-subtitles |
| 提取画面 | video-frames |

### 阶段3：自然反应（第4周+）

**不再需要"想起来"，直接就用。**

---

## 📊 每周回顾机制

**每周日晚上（或周一早上），回顾：**

1. **本周使用了哪些 skills？**
   - 统计使用次数
   - 哪些用得好？

2. **本周有哪些任务该用 skill 但没用？**
   - 为什么没想起来？
   - 如何改进？

3. **下周重点关注哪些 skills？**
   - 根据项目需求
   - 提前准备

---

## 🚨 防止"安装后就忘记"的机制

### 机制1：新 Skill 安装后的强化训练

**每次安装新 skill 后：**

1. **立即测试**
   - 运行一次示例命令
   - 确认能用

2. **写入触发条件**
   - 更新上面的清单
   - 明确什么情况下用

3. **第一周强制使用**
   - 找机会用一次
   - 形成初步印象

4. **记录到 AGENTS.md**
   - 添加到触发词表
   - 每次启动时看到

### 机制2：定期盘点（每月1次）

**每月1号，执行：**

1. **列出所有已安装的 skills**
   ```bash
   openclaw skills list
   ```

2. **检查使用情况**
   - 哪些 skills 从未使用？
   - 为什么？

3. **决策**
   - 有用但忘记了 → 加强提醒
   - 没用 → 考虑卸载

### 机制3：任务前的 Skills 检查

**每次接到新任务时，问自己：**

```
这个任务可能用到哪些 skills？
→ 快速扫描 skills 清单
→ 提前准备
```

---

## 🎯 具体执行方案

### 立即行动（今天）

1. **创建 Skills 使用日志**
   - 文件：`memory/skills-usage.md`
   - 记录每次使用情况

2. **设置每周回顾提醒**
   - 使用 cron 或 HEARTBEAT.md
   - 每周日 20:00 提醒

3. **更新 AGENTS.md**
   - 添加"每日启动检查 skills"规则

### 持续优化（1-4周）

1. **第1周：** 主动提醒，强制使用
2. **第2周：** 开始形成习惯
3. **第3周：** 条件反射初步形成
4. **第4周：** 自然反应

---

## 📝 Skills 使用日志模板

```markdown
# Skills 使用日志

## 2026-03-07

### 使用记录
- 19:15 - summarize - 分析 YouTube 视频 ✅
- 19:20 - video-frames - 提取视频帧 ✅

### 遗漏记录
- 应该用 weather 查天气，但忘记了 ❌
- 下次记得：看到"天气"关键词 → 立即想到 weather

### 本日总结
- 使用了 2 个 skills
- 遗漏了 1 个
- 明天重点关注：weather
```

---

## 🔧 技术实现

### 自动扫描已安装 Skills

```powershell
# 每次启动时运行
$skills = openclaw skills list | Select-String "✓ ready"
Write-Host "今日可用 Skills: $($skills.Count) 个"
```

### 自动提醒

在 AGENTS.md 的 "Every Session" 章节添加：

```markdown
5. **检查可用 Skills**
   - 快速扫描 skills 清单
   - 提醒今天可能用到的 skills
```

---

## 🎯 成功标准

**1个月后，达到以下标准：**

1. ✅ 所有已安装的 skills 都至少使用过1次
2. ✅ 常用 skills 形成条件反射（<1秒想起来）
3. ✅ 每周使用 skills 的次数 > 10次
4. ✅ "该用但没用"的情况 < 10%

---

*创建时间：2026-03-07 19:20*
*创建者：虾哥 🦐*
