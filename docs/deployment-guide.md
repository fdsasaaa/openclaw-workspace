# EnergyBlock 环境打包与部署指南

**版本**: v1.0  
**创建时间**: 2026-03-05  
**用途**: 实现OpenClaw环境的可移植部署

---

## 核心设计原则

### 可移植性策略

```
┌─────────────────────────────────────────────────────────┐
│                三层备份架构                              │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  第一层: GitHub仓库 (代码/配置/文档)                      │
│  ├── 公开部分: 工作区、脚本、文档                         │
│  └── 自动同步: 每日2:00                                  │
│                                                          │
│  第二层: 本地备份 (环境信息/模板)                         │
│  ├── 配置文件模板 (脱敏)                                 │
│  ├── 环境信息导出                                        │
│  └── 恢复脚本                                           │
│                                                          │
│  第三层: 安全存储 (敏感信息)                              │
│  ├── API密钥 (加密)                                     │
│  ├── Auth配置                                           │
│  └── 手动迁移                                           │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 打包方式

### 方式1: GitHub仓库（推荐）

**适用场景**: 日常备份、团队协作

**已配置**: ✅
- 仓库: https://github.com/fdsasaaa/openclaw-workspace
- 自动同步: 每日2:00
- 包含内容: 工作区所有文件（除敏感信息）

**使用方法**:
```bash
# 新机器上克隆
git clone https://github.com/fdsasaaa/openclaw-workspace.git C:\OpenClaw_Workspace
```

### 方式2: 完整环境备份

**适用场景**: 离线迁移、完整环境复制

**创建备份**:
```powershell
cd C:\OpenClaw_Workspace
.\scripts\backup-environment.ps1
```

**备份内容**:
- GitHub仓库链接
- 配置文件模板（脱敏）
- 环境信息（版本/依赖）
- 恢复脚本
- 部署指南

**可选**: `-IncludeSecrets` 包含敏感信息（加密存储）

### 方式3: 一键部署包

**适用场景**: 全新机器快速部署

**创建部署包**:
```powershell
.\scripts\backup-environment.ps1 -CreateArchive
```

**生成文件**:
```
EnergyBlock-Backup-YYYYMMDD-HHMMSS.zip
├── README.md
├── restore.ps1
├── openclaw.json.template
├── environment-info.json
└── secrets/ (如果包含敏感信息)
```

---

## 部署方式

### 方式A: 一键部署脚本（推荐）

**适用**: 有网络连接的新机器

```powershell
# 下载部署脚本
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/fdsasaaa/openclaw-workspace/main/scripts/deploy-new-machine.ps1" -OutFile "deploy.ps1"

# 运行部署
.\deploy.ps1
```

**自动完成**:
- ✅ 安装OpenClaw
- ✅ 克隆工作区
- ✅ 安装Python依赖
- ✅ 创建基础配置
- ✅ 设置计划任务

**手动配置**（必需）:
- Moonshot/Kimi API Key
- Telegram Bot Token（可选）
- Brave API Key（可选）

### 方式B: 手动部署

**步骤**:

1. **安装依赖**
   ```bash
   npm install -g openclaw
   pip install backtrader pandas numpy matplotlib
   ```

2. **克隆仓库**
   ```bash
   git clone https://github.com/fdsasaaa/openclaw-workspace.git C:\OpenClaw_Workspace
   ```

3. **配置OpenClaw**
   ```bash
   # 复制模板
   copy C:\OpenClaw_Workspace\configs\openclaw.json.template %USERPROFILE%\.openclaw\openclaw.json
   
   # 编辑配置，填入API密钥
   notepad %USERPROFILE%\.openclaw\openclaw.json
   ```

4. **启动服务**
   ```bash
   openclaw gateway start
   ```

5. **验证安装**
   ```bash
   python C:\OpenClaw_Workspace\scripts\audit_all_stages.py
   ```

### 方式C: 从备份包恢复

**步骤**:

1. **解压备份包**
   ```powershell
   Expand-Archive EnergyBlock-Backup-YYYYMMDD-HHMMSS.zip C:\Temp\EnergyBlock-Restore
   ```

2. **运行恢复脚本**
   ```powershell
   cd C:\Temp\EnergyBlock-Restore
   .\restore.ps1
   ```

3. **恢复敏感信息**（如包含）
   ```powershell
   # 从secrets目录复制配置文件
   copy secrets\auth-profiles.json %USERPROFILE%\.openclaw\agents\main\agent\
   ```

---

## 同步检查

**定期检查环境同步状态**:
```powershell
.\scripts\sync-check.ps1
```

**检查内容**:
- Git未提交变更
- 远程仓库更新
- 关键文件完整性

---

## 敏感信息处理

### 不包含在Git中的敏感信息

| 文件 | 位置 | 处理方式 |
|------|------|----------|
| API密钥 | `~\.openclaw\agents\main\agents-profiles.json` | 手动复制或重新配置 |
| Telegram Token | `~\.openclawopenclaw.json` | 手动配置 |
| Brave API Key | 环境变量 | 手动设置 |

### 安全备份敏感信息

```powershell
# 加密备份（需要密码）
$password = Read-Host "输入加密密码" -AsSecureString
$files = @(
    "$env:USERPROFILE\.openclawopenclaw.json",
    "$env:USERPROFILE\.openclawgentsrainrgentth-profiles.json"
)
Compress-Archive -Path $files -DestinationPath "secrets-backup.zip" -Password $password
```

---

## 常见问题

### Q1: 部署后API密钥失效？
**A**: API密钥与机器绑定，新机器需要重新配置。在OpenClaw中运行 `/auth add` 重新添加。

### Q2: Telegram Bot需要重新创建？
**A**: 不需要。Token不变，直接在新配置中使用相同Token即可。

### Q3: 计划任务未自动运行？
**A**: 检查用户权限，确保计划任务以当前用户身份运行，而非SYSTEM。

### Q4: 如何验证部署成功？
**A**: 运行审计脚本：
```powershell
python C:\OpenClaw_Workspace\scripts\audit_all_stages.py
```

---

## 最佳实践

1. **日常备份**: 依赖GitHub自动同步（已配置）
2. **重大变更前**: 手动运行 `backup-environment.ps1`
3. **定期验证**: 每周运行 `sync-check.ps1`
4. **敏感信息**: 单独加密备份，不要上传公共仓库
5. **文档更新**: 修改配置后更新部署指南

---

## 联系支持

**项目**: EnergyBlock Strategies  
**仓库**: https://github.com/fdsasaaa/openclaw-workspace  
**文档**: C:\OpenClaw_Workspace\docs\

---

*本指南随环境自动更新*
