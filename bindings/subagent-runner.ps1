#!/usr/bin/env pwsh
# SubAgent任务执行器
# 用于后台运行SubAgent任务，不阻塞主会话

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

# 确保目录存在
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

# 记录任务开始
$startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$startTime] Task $TaskId started: $Task" | Out-File "$LogDir\$TaskId.log" -Append

# 创建任务文件
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
    # 切换到SubAgent工作目录
    Set-Location $WorkDir
    
    # 这里模拟SubAgent处理
    # 实际应调用OpenClaw API或启动新进程
    "Processing..." | Out-File "$LogDir\$TaskId.log" -Append
    
    # 模拟长时间任务
    # Start-Sleep -Seconds 5
    
    # 任务完成
    $endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $result = @{
        taskId = $TaskId
        status = "completed"
        completedAt = $endTime
        result = "Task completed by $AgentName"
    } | ConvertTo-Json
    
    $result | Out-File "$LogDir\$TaskId-result.json" -Encoding UTF8
    "[$endTime] Task $TaskId completed" | Out-File "$LogDir\$TaskId.log" -Append
    
    # 通知主Agent（通过文件触发器或消息）
    $notification = @{
        type = "task_complete"
        taskId = $TaskId
        agent = $AgentName
        summary = "任务 $TaskId 已完成"
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
