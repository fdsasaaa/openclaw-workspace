# MEMORY.md - 长期记忆

## 系统配置历史

### 2026-03-07 - 系统初始化完成
- ✅ OpenClaw 网关配置完成（飞书 + Telegram）
- ✅ Supervisor 自动化服务配置完成（Windows 计划任务）
- ✅ 中文编码问题修复（UTF-8 支持）
- ✅ ACPX Runtime 插件已安装（但需要官方 Anthropic API key 才能使用）

### 关键决策
- **通信通道**: 飞书作为主通道，Telegram 作为备用
- **模型选择**: Claude-Sonnet-4-6 通过 yunyi 代理
- **Supervisor 方案**: Windows 计划任务（开机自启 + 失败自动重启）

### 已知问题
1. **Memory Search 不可用** - embedding API 配置错误（OpenAI API key 无效）
2. **ACP Runtime 不可用** - claude-agent-acp 需要官方 Anthropic API，无法使用第三方代理

### 工作区结构
- `/bindings/` - Supervisor 和任务处理脚本
- `/memory/` - 每日记忆文件
- `/skills/` - 技能包
- `AGENTS.md` - 代理行为规范
- `SOUL.md` - 个性和风格定义
- `USER.md` - 用户信息
- `IDENTITY.md` - 身份定义

---

## 经验教训

### 网页分析（2026-03-06）
- 永远基于实时获取的证据，不依赖记忆或间接信息
- 使用 browser 工具获取实际内容

---

_此文件会随着时间积累更多长期记忆和经验_

### 定时备份配置（2026-03-07）
- ✅ 配置每日 Git 自动备份（凌晨 2:00）
- 任务ID: ee6614fe-f515-4929-98dd-a7b6424e42ca
- 自动检查变更、commit、push

### 完整恢复协议（2026-03-07）
- ✅ 创建 RECOVERY.md - 完整的恢复指南
- 包含 6 步恢复流程
- 关键恢复口令："恢复工作状态"
- 解决了上次"失忆"问题
- 确保任何新环境都能完整恢复虾哥的记忆和能力
