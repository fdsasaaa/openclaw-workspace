#!/usr/bin/env pwsh
# SubAgent浠诲姟鎵ц鍣?# 鐢ㄤ簬鍚庡彴杩愯SubAgent浠诲姟锛屼笉闃诲涓讳細璇?
param(
    [Parameter(Mandatory=$true)]
    [string]$AgentName,
    
    [Parameter(Mandatory=$true)]
    [string]$Task,
    
    [Parameter(Mandatory=$false)]
    [string]$TaskId = (New-Guid).ToString().Substring(0,8)
)

$ErrorActionPreference = "Stop"
$WorkDir = "C:\OpenClaw_Workspace\agents\$AgentName"
$LogDir = "$WorkDir\memory\logs"

# 纭繚鐩綍瀛樺湪
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

# 璁板綍浠诲姟寮€濮?$startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$startTime] Task $TaskId started: $Task" | Out-File "$LogDir\$TaskId.log" -Append

# 鍒涘缓浠诲姟鏂囦欢
$taskFile = @{
    taskId = $TaskId
    agent = $AgentName
    task = $Task
    status = "running"
    startedAt = $startTime
    workspace = $WorkDir
} | ConvertTo-Json

$taskFile | Out-File "$LogDir\$TaskId.json" -Encoding UTF8

try {
    # 鍒囨崲鍒癝ubAgent宸ヤ綔鐩綍
    Set-Location $WorkDir
    
    # 杩欓噷妯℃嫙SubAgent澶勭悊
    # 瀹為檯搴旇皟鐢∣penClaw API鎴栧惎鍔ㄦ柊杩涚▼
    "Processing..." | Out-File "$LogDir\$TaskId.log" -Append
    
    # 妯℃嫙闀挎椂闂翠换鍔?    # Start-Sleep -Seconds 5
    
    # 浠诲姟瀹屾垚
    $endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $result = @{
        taskId = $TaskId
        status = "completed"
        completedAt = $endTime
        result = "Task completed by $AgentName"
    } | ConvertTo-Json
    
    $result | Out-File "$LogDir\$TaskId-result.json" -Encoding UTF8
    "[$endTime] Task $TaskId completed" | Out-File "$LogDir\$TaskId.log" -Append
    
    # Notify main agent (via file trigger)
    $notification = @{
        type = "task_complete"
        taskId = $TaskId
        agent = $AgentName
        summary = "Task $TaskId completed"
        timestamp = $endTime
    } | ConvertTo-Json
    
    $notification | Out-File "C:\OpenClaw_Workspace\bindings\notifications\$TaskId.json" -Encoding UTF8
    
} catch {
    $errorMsg = $_.Exception.Message
    "[ERROR] $errorMsg" | Out-File "$LogDir\$TaskId.log" -Append
    
    $errorResult = @{
        taskId = $TaskId
        status = "failed"
        error = $errorMsg
        failedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    } | ConvertTo-Json
    
    $errorResult | Out-File "$LogDir\$TaskId-result.json" -Encoding UTF8
}
