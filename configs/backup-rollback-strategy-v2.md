# OpenClaw 备份与回滚策略（增强版）

**版本**: v2.0  
**更新**: 2026-03-05  
**适用**: 完全自动化模式

---

## 一、三层备份体系

### 1.1 第一层：Git版本控制（代码/文档）

**范围**:
- configs/ (规范文档)
- reports/ (阶段报告)
- ea-scripts/, ea-backtests/, ea-reports/ (EA业务)
- memory/ (记忆记录)
- scripts/ (工具脚本)
- templates/ (模板文件)

**频率**: 每日凌晨 2:00 自动推送
**保留**: GitHub无限历史
**回滚**: `git reset --hard <commit>`

### 1.2 第二层：文件快照（完整状态）

**触发条件**:
- 重大变更前自动创建
- 手动执行 `scripts/backup-before-change.ps1`
- 每周日自动完整备份

**保存位置**: `C:\OpenClaw_Workspace\backup\`
**命名格式**: `snapshot-yyyyMMdd_HHmmss\`
**保留数量**: 最近10个快照

### 1.3 第三层：配置备份（OpenClaw核心）

**范围**:
- `openclaw.json` (主配置)
- `auth-profiles.json` (密钥)
- `models.json` (模型配置)

**频率**: 
- 每次修改前自动备份
- 每日自动备份

**保存位置**: 
- `C:\Users\ME\.openclaw\*.bak`
- `C:\OpenClaw_Workspace\backup\config\`

---

## 二、回滚机制

### 2.1 自动回滚触发条件

| 场景 | 自动动作 | 通知方式 |
|------|----------|----------|
| 配置损坏 | 恢复最近配置备份 | Telegram消息 |
| 关键文件丢失 | 从GitHub拉取 | Telegram消息 |
| 系统无法启动 | 恢复最近快照 | 启动时提示 |

### 2.2 手动回滚命令

```powershell
# 查看所有可回滚点
.\scripts\emergency-rollback.ps1 -List

# 回滚到最近一次备份
.\scripts\emergency-rollback.ps1 -Mode last

# 回滚Git到指定提交
.\scripts\emergency-rollback.ps1 -Mode git -Timestamp "abc1234"

# 恢复配置
.\scripts\emergency-rollback.ps1 -Mode config

# 完整系统恢复（危险！）
.\scripts\emergency-rollback.ps1 -Mode full -Force
```

### 2.3 回滚前自动保护

每次回滚前自动执行：
1. 创建当前状态快照（`pre-rollback-xxx`）
2. 记录回滚原因到日志
3. 通知用户（Telegram）

---

## 三、紧急恢复流程

### 场景1: 项目文件损坏

```powershell
# 1. 查看备份点
.\scripts\emergency-rollback.ps1 -List

# 2. 回滚到最近正常状态
.\scripts\emergency-rollback.ps1 -Mode last

# 或从GitHub恢复
cd C:\OpenClaw_Workspace
git fetch origin
git reset --hard origin/master
```

### 场景2: OpenClaw配置错误

```powershell
# 1. 停止Gateway
openclaw gateway stop

# 2. 恢复配置
.\scripts\emergency-rollback.ps1 -Mode config

# 3. 重启Gateway
openclaw gateway start
```

### 场景3: 完整系统崩溃

1. 从U盘启动备份系统
2. 恢复Windows系统镜像
3. 重新安装OpenClaw
4. 从GitHub克隆仓库：`git clone https://github.com/fdsasaaa/openclaw-workspace`
5. 恢复配置备份

---

## 四、定期检查清单

### 每周检查（建议周日）

- [ ] 运行审计脚本：`python scripts��audit_all_stages.py`
- [ ] 检查GitHub同步状态
- [ ] 验证备份完整性（随机抽取恢复测试）
- [ ] 清理过期备份（保留10份）

### 每月检查

- [ ] 测试完整回滚流程
- [ ] 更新紧急恢复文档
- [ ] 检查磁盘空间（备份占用）

---

## 五、与U盘系统备份的配合

### 建议U盘备份内容

1. **Windows系统镜像**（完整系统）
2. **OpenClaw安装程序**（快速重装）
3. **本备份策略文档**（恢复指南）
4. **GitHub仓库地址**（代码恢复）

### 恢复优先级

```
1. 优先: Git版本控制（代码/文档）
2. 其次: 文件快照（完整状态）
3. 最后: U盘系统镜像（完全重装）
```

---

## 六、联系与支持

**紧急情况下**:
1. 查看日志: `C:\OpenClaw_Workspace\logs\`
2. 运行回滚: `scripts\emergency-rollback.ps1`
3. 检查GitHub: https://github.com/fdsasaaa/openclaw-workspace

---

*本策略已生效，所有配置已按此执行。*
