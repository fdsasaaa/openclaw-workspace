# 业务前最小验收清单

**生成时间**: 2026-03-05  
**验收目标**: 确认当前环境具备启动业务的基础条件  
**验收原则**: 只记录现状，不虚构完成状态

---

## A. 模型可用性

### 检查项
- [ ] 使用当前模型（kimi-coding/k2p5）完成一次最小对话测试
- [ ] 确认无 401 Unauthorized 错误
- [ ] 确认无 429 Too Many Requests 限流
- [ ] 确认响应时间在可接受范围（<30秒）

### 当前状态
**已完成** - 当前对话使用 kimi-coding/k2p5 正常进行，无 401/429 错误，响应正常。

### 验收结果
- [x] 模型可用性验证通过
- [x] 无 401 Unauthorized 错误
- [x] 无 429 Too Many Requests 限流
- [x] 响应时间正常

---

## B. 网关状态确认

### 检查项
- [ ] `openclaw gateway status` 返回正常状态
- [ ] Gateway 进程在运行
- [ ] 本地端口 18789 可连接
- [ ] Token 认证有效

### 当前状态
**已完成** - Gateway 运行正常，RPC probe: ok，端口 18789 监听中。

### 验收结果
- [x] `openclaw gateway status` 返回正常
- [x] Gateway 进程运行中（node 进程）
- [x] 本地端口 18789 可连接
- [x] Token 认证有效

### 实际检查结果
```
Service: Scheduled Task (registered)
Gateway: bind=loopback (127.0.0.1), port=18789
RPC probe: ok
Dashboard: http://127.0.0.1:18789/
Listening: 127.0.0.1:18789
```

---

## C. 连续运行保护规范

### 检查项
- [ ] 3条保护规范已写入执行规则文件
- [ ] 规范文件位置明确
- [ ] 规范内容易查阅、可引用

### 当前状态
**已完成** - 执行规则文件已创建，包含 5 条核心规则。

### 验收结果
- [x] 5条保护规范已写入执行规则文件
- [x] 规范文件位置明确: `C:\OpenClaw_Workspace\configs\execution-rules.md`
- [x] 规范内容易查阅、可引用

### 文件内容概要
- 规则1: 任务拆分与小步验证
- 规则2: 检查点保存与续跑
- 规则3: 失败处理与退避
- 规则4: Token 与上下文控制
- 规则5: 双区并行输出规范

---

## D. 脚本可运行性缺口

### 检查项
- [ ] `step02\01-ea-optimize.ps1` 路径问题已识别
- [ ] Python 环境已确认
- [ ] backtrader 库已确认
- [ ] 数据源可用性已确认

### 当前状态
**已完成路径修复与数据准备，backtrader 待安装**

### 缺口修复情况

| 缺口 | 状态 | 备注 |
|------|------|------|
| 路径硬编码 | ✅ 已修复 | 已替换为 `C:\OpenClaw_Workspace` |
| 变量未定义 | ✅ 已修复 | 已添加 `$WorkspaceRoot` 定义 |
| 数据文件不存在 | ✅ 已修复 | 已生成 `market_data.csv` (6883行) |
| Python 环境 | ✅ 已确认 | Python 3.11.9 可用 |
| pandas | ✅ 已确认 | 3.0.0 已安装 |
| numpy | ✅ 已确认 | 2.4.1 已安装 |
| backtrader | ⏸️ 待安装 | 未安装，如需运行 EA 优化需安装 |

### 当前结论
脚本路径问题已全部修复，数据文件已准备就绪。如需实际运行 EA 优化，需安装 backtrader (`pip install backtrader`)。

---

## E. 输出落点确认

### 检查项
- [ ] 数据文件落点明确
- [ ] 报告输出落点明确
- [ ] 脚本存放落点明确
- [ ] 检查点/进度保存落点明确

### 当前状态
**已确定（双区并行策略）**

### 落点清单

| 内容类型 | 落点目录 | 当前状态 |
|----------|----------|----------|
| **数据文件** | `C:\OpenClaw_Workspace\Data\` | ✅ 已存在，含 XAUUSDH1.xlsx |
| **报告输出** | `C:\OpenClaw_Workspace\reports\` | ✅ 已存在，含阶段1报告 |
| **脚本文件** | `C:\OpenClaw_Workspace\step02\` | ✅ 已存在，含 01-ea-optimize.ps1 |
| **检查点/进度** | `C:\OpenClaw_Workspace\memory\` | ✅ 目录存在，待首次写入 |
| **项目代码** | `C:\OpenClaw_Workspace\projects\` | ✅ 目录存在，待创建项目 |
| **用户日志** | `C:\OpenClaw_Workspace\logs\` | ✅ 目录存在，待首次写入 |
| **临时文件** | `C:\OpenClaw_Workspace\temp\` | ✅ 目录存在，待使用 |
| **配置规则** | `C:\OpenClaw_Workspace\configs\` | ✅ 目录存在，待创建规则文件 |

### 暂不写入的区域

| 区域 | 路径 | 原因 |
|------|------|------|
| OpenClaw 核心配置 | `C:\Users\ME\.openclaw\workspace\` | 运行区，保持只读 |
| 会话状态 | `C:\Users\ME\.openclaw\agents\main\sessions\` | 系统管理，不手动写入 |
| Auth 配置 | `C:\Users\ME\.openclaw\agents\main\agent\` | 敏感配置，不手动修改 |

### 验收动作
确认以上落点符合预期，无需调整。

### 通过标准
落点明确，与双区并行策略一致。

---

## 验收总览

| 检查项 | 当前状态 | 是否通过 | 阻塞业务？ |
|--------|----------|----------|------------|
| A. 模型可用性 | 已完成 | ✅ 通过 | - |
| B. 网关状态 | 已完成 | ✅ 通过 | - |
| C. 保护规范 | 已完成 | ✅ 通过 | - |
| D. 脚本可运行性 | 路径/数据已修复 | 🟡 部分通过 | backtrader 待装 |
| E. 输出落点 | 已确定 | ✅ 通过 | - |

**当前结论**: 4 项通过，1 项部分通过（仅缺 backtrader）。

**阶段1状态**: ✅ **业务前最小验收已完成**，可进入阶段2。

**待办**: 如需实际运行 EA 优化，请在阶段4执行层能力建设时安装 backtrader。
