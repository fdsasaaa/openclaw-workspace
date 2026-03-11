# HEARTBEAT.md - 系统巡检清单

## 巡检任务（每30分钟轮询一次）

### 每日轮换检查（避免每次都检查所有项）

**周一、三、五：**
- [ ] 检查磁盘空间（C盘 < 20GB 时告警）
- [ ] 检查 OpenClaw 网关状态（`openclaw status`）
- [ ] 检查最近的 Git 备份是否成功

**周二、四、六：**
- [ ] 检查系统更新（Windows Update 待安装项）
- [ ] 检查 workspace 文件数量（超过1000个文件时提醒整理）
- [ ] 检查 memory/ 目录大小（超过50MB时提醒归档）

**每天：**
- [ ] 检查是否有未读的重要通知（飞书/Telegram）
- [ ] 检查今天的工作日志是否已创建（memory/YYYY-MM-DD.md）

### 静默规则

- 所有检查正常 → 返回 `HEARTBEAT_OK`
- 发现问题 → 主动汇报，不包含 `HEARTBEAT_OK`
- 深夜时段（23:00-08:00）→ 仅 P0 级别问题才打断

### 状态追踪

在 `memory/heartbeat-state.json` 记录上次检查时间：

```json
{
  "lastChecks": {
    "disk": 1773189288,
    "gateway": 1773189288,
    "git_backup": 1773189288,
    "system_update": null,
    "workspace_files": null,
    "memory_size": null,
    "notifications": 1773189288,
    "daily_log": 1773189288
  }
}
```
