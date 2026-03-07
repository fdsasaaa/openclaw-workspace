# gateway-monitor.ps1
# OpenClaw Gateway Monitor - 监控网关状态并自动重启

param(
    [int]$CheckIntervalSec = 30,  # 每30秒检查一次
    [string]$LogFile = "C:\OpenClaw_Workspace\workspace\bindings\logs\gateway-monitor.log"
)

# UTF-8 encoding support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$ErrorActionPreference = "Continue"

# 创建日志目录
New-Item -ItemType Directory -Force -Path (Split-Path $LogFile) | Out-Null

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$ts $msg"
    $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Write-Host $logLine
}

function Test-GatewayRunning {
    try {
        # 检查 openclaw gateway 进程是否存在
        $process = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
            Where-Object { $_.CommandLine -like "*openclaw*gateway*" }
        
        if ($process) {
            return $true
        }
        
        # 备用检查：尝试连接网关端口
        $port = 8080
        $connection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        
        if ($connection.TcpTestSucceeded) {
            return $true
        }
        
        return $false
    } catch {
        Write-Log "[ERROR] 检查网关状态失败: $_"
        return $false
    }
}

function Start-Gateway {
    try {
        Write-Log "[ACTION] 正在启动网关..."
        
        # 使用完整路径启动网关（SYSTEM 账户没有 PATH）
        # 直接调用 node + openclaw.mjs
        $nodePath = "C:\Program Files\nodejs\node.exe"
        $openclawMjs = "C:\Users\ME\AppData\Roaming\npm\node_modules\openclaw\openclaw.mjs"
        
        # 检查文件是否存在
        if (-not (Test-Path $nodePath)) {
            Write-Log "[ERROR] Node.js 未找到: $nodePath"
            return $false
        }
        
        if (-not (Test-Path $openclawMjs)) {
            Write-Log "[ERROR] OpenClaw 未找到: $openclawMjs"
            return $false
        }
        
        # 启动网关
        $result = & $nodePath $openclawMjs gateway start 2>&1
        Write-Log "[INFO] 启动命令输出: $result"
        
        # 等待启动
        Start-Sleep -Seconds 10
        
        # 验证启动成功
        if (Test-GatewayRunning) {
            Write-Log "[SUCCESS] 网关启动成功"
            return $true
        } else {
            Write-Log "[ERROR] 网关启动失败"
            return $false
        }
    } catch {
        Write-Log "[ERROR] 启动网关时出错: $_"
        return $false
    }
}

Write-Log "=== Gateway Monitor Started ==="
Write-Log "检查间隔: $CheckIntervalSec 秒"

$consecutiveFailures = 0
$maxConsecutiveFailures = 3

while ($true) {
    try {
        $isRunning = Test-GatewayRunning
        
        if ($isRunning) {
            if ($consecutiveFailures -gt 0) {
                Write-Log "[INFO] 网关已恢复正常"
                $consecutiveFailures = 0
            }
            # 网关正常运行，不输出日志（避免日志过多）
        } else {
            $consecutiveFailures++
            Write-Log "[WARNING] 网关未运行 (连续失败: $consecutiveFailures/$maxConsecutiveFailures)"
            
            if ($consecutiveFailures -ge $maxConsecutiveFailures) {
                Write-Log "[ALERT] 网关持续未运行，尝试重启..."
                
                $started = Start-Gateway
                
                if ($started) {
                    $consecutiveFailures = 0
                } else {
                    Write-Log "[ERROR] 重启失败，将在下次检查时重试"
                }
            }
        }
    } catch {
        Write-Log "[ERROR] 监控循环出错: $_"
    }
    
    Start-Sleep -Seconds $CheckIntervalSec
}
