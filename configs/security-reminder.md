# 安全提醒与敏感信息处理规范

**生效日期**: 2026-03-05  
**版本**: v1.0  
**适用范围**: 所有 OpenClaw 操作

---

## 一、敏感信息定义

以下信息属于**敏感信息**，需特殊处理：

| 类别 | 示例 |
|------|------|
| **API密钥** | `sk-kimi-...`, `ghp_...`, `ntn_...` |
| **访问令牌** | OAuth tokens, JWT, session cookies |
| **密码/凭证**  | 数据库密码、SSH密钥、私钥文件 |
| **个人身份信息** | 真实姓名、身份证号、银行卡号 |
| **系统路径** | 含用户名的绝对路径（如 `C:\Users\ME\...`） |
| **网络配置** | IP地址、端口映射、内网拓扑 |

---

## 二、敏感信息存储规范

### 2.1 API密钥存储

**正确方式**:
```bash
# 1. 专用配置文件（推荐）
~/.config/openclaw/api_keys
~/.config/moonshot/api_key

# 2. 环境变量（会话级）
$env:MOONSHOT_API_KEY = "sk-..."

# 3. OpenClaw auth系统（已集成）
~/.openclaw/agents/main/agent/auth-profiles.json
```

**禁止方式**:
- ❌ 写入普通文本文件
- ❌ 写入Git仓库
- ❌ 写入聊天记录/记忆文件（明文）
- ❌ 硬编码在脚本中

### 2.2 记忆文件处理

**脱敏规则**:
- API密钥：只保留前8位，其余用 `...` 代替（如 `sk-kimi-UMyv...`）
- 路径中的用户名：用 `[USER]` 代替（如 `C:\Users\[USER]\...`）
- IP地址：用 `[IP]` 或 `[LAN]` 代替

**示例**:
```markdown
# 正确
今日配置了 Moonshot API（`sk-kimi-UMyv...`），存储于 `C:\Users\[USER]\.openclaw\...`

# 错误
今日配置了 Moonshot API（`sk-kimi-UMyvUJYDdfb6xPlWpJsGVoBwXCMffpwVXnCQiTVnvuh3E4KiZ0JBLzzRPMve2OZc`）
```

---

## 三、外部操作安全规范

### 3.1 需人工确认的操作

以下操作**必须**先停下汇报，等待确认：

| 操作类型 | 示例 |
|----------|------|
| **删除/覆盖** | `rm -rf`, `Remove-Item -Recurse`, 文件覆盖 |
| **系统配置修改** | 修改注册表、环境变量、系统服务 |
| **网络暴露** | 开放端口、修改防火墙规则、启动对外服务 |
| **凭证操作** | 生成新密钥、修改密码、授权第三方 |
| **外网敏感操作** | 公开发布、邮件外发、社交媒体发帖 |
| **大规模安装** | 安装系统级软件、修改全局Python包 |

### 3.2 低风险操作（可直接执行）

| 操作类型 | 示例 |
|----------|------|
| **只读检查** | 文件读取、目录列出、状态查询 |
| **创建新文件** | 在指定目录新建文件（不覆盖） |
| **写入报告/日志** | 写入 `reports/`, `logs/`, `memory/` |
| **Python包安装** | `pip install` 到用户目录（非系统） |

---

## 四、备份与恢复

### 4.1 自动备份内容

以下目录**应**定期备份：

| 目录 | 备份频率 | 保留版本 |
|------|----------|----------|
| `~/.openclaw/openclaw.json` | 每次修改前 | 10个版本 |
| `~/.openclaw/agents/main/agent/auth-profiles.json` | 每月 | 3个版本 |
| `C:\OpenClaw_Workspace\workspace\` | 每周 | 4个版本 |
| `C:\OpenClaw_Workspace\memory\` | 每日 | 30天 |

### 4.2 备份存储位置

- **本地**: `C:\OpenClaw_Workspace\backup\`
- **异地**: 建议云存储（OneDrive/Dropbox）同步

---

## 五、审计与日志

### 5.1 操作日志

关键操作应记录：
- 操作时间
- 操作类型
- 影响文件/目录
- 执行结果

**日志位置**: `C:\OpenClaw_Workspace\logs\operations-YYYY-MM-DD.log`

### 5.2 敏感操作审计

以下操作写入专用审计日志：
- 密钥查看/修改
- 授权操作
- 系统配置变更

**审计日志**: `~/.openclaw/logs/config-audit.jsonl`（系统自带）

---

## 六、紧急处理

### 6.1 密钥泄露应急

如发现密钥可能泄露：
1. 立即撤销/轮换密钥（通过服务商控制台）
2. 更新 `auth-profiles.json`
3. 检查近期操作日志
4. 记录事件到 `memory/security-incident-YYYY-MM-DD.md`

### 6.2 误删除恢复

优先使用 `trash` 而非 `rm`：
```powershell
# 推荐（可恢复）
trash put file.txt

# 避免（不可恢复）
Remove-Item file.txt
```

---

## 七、修订记录

| 版本 | 日期 | 修订内容 |
|------|------|----------|
| v1.0 | 2026-03-05 | 初始版本 |

---

*本规范由 OpenClaw 中枢协调器制定，所有操作必须遵守。*
