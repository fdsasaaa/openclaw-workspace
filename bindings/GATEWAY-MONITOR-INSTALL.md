# 网关监控安装指南

## 问题
网关有时会崩溃，导致无法通过飞书交流。

## 解决方案
安装一个**后台监控程序**，每30秒检查一次网关状态，如果发现网关崩溃就自动重启。

## 安装步骤

### 方法1：自动安装（推荐）

1. **右键点击 PowerShell 图标**
2. **选择 "以管理员身份运行"**
3. **复制并运行以下命令：**

```powershell
C:\OpenClaw_Workspace\workspace\bindings\install-gateway-monitor.ps1
```

4. **等待几秒，看到 "安装完成" 即可**

### 方法2：手动安装

如果方法1不行，运行以下命令：

```powershell
Start-Process pwsh.exe -ArgumentList '-ExecutionPolicy Bypass -File C:\OpenClaw_Workspace\workspace\bindings\install-gateway-monitor.ps1' -Verb RunAs
```

## 验证安装

安装后，运行以下命令验证：

```powershell
Get-ScheduledTask -TaskName "OpenClaw-Gateway-Monitor"
```

应该看到：
- **TaskName**: OpenClaw-Gateway-Monitor
- **State**: Running
- **Triggers**: MSFT_TaskBootTrigger（开机启动）

## 查看日志

监控日志位置：
```
C:\OpenClaw_Workspace\workspace\bindings\logs\gateway-monitor.log
```

查看最近的日志：
```powershell
Get-Content "C:\OpenClaw_Workspace\workspace\bindings\logs\gateway-monitor.log" -Tail 20
```

## 工作原理

1. **每30秒检查一次**网关是否运行
2. **如果网关崩溃**，连续检查3次确认
3. **自动重启网关**
4. **记录所有操作**到日志文件

## 测试

安装后，你可以测试一下：

1. 手动停止网关：
   ```powershell
   openclaw gateway stop
   ```

2. 等待1-2分钟

3. 检查日志，应该看到监控程序自动重启了网关：
   ```powershell
   Get-Content "C:\OpenClaw_Workspace\workspace\bindings\logs\gateway-monitor.log" -Tail 10
   ```

4. 在飞书发消息给我，确认可以正常交流

## 卸载

如果需要卸载监控程序：

```powershell
Unregister-ScheduledTask -TaskName "OpenClaw-Gateway-Monitor" -Confirm:$false
```

---

**安装完成后，即使网关崩溃，也会在1-2分钟内自动恢复，保持我们之间的持续联系！** 🦐
