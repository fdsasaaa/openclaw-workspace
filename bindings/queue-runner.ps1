param(
  [Parameter(Mandatory=$false)]
  [string]$QueueDir = "C:\OpenClaw_Workspace\bindings\queue",
  [Parameter(Mandatory=$false)]
  [string]$DoneDir  = "C:\OpenClaw_Workspace\bindings\queue\done",
  [Parameter(Mandatory=$false)]
  [string]$FailDir  = "C:\OpenClaw_Workspace\bindings\queue\failed",
  [Parameter(Mandatory=$false)]
  [string]$Runner   = "C:\OpenClaw_Workspace\bindings\subagent-runner.ps1"
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $QueueDir,$DoneDir,$FailDir | Out-Null

$tasks = Get-ChildItem $QueueDir -File -Filter "*.json" -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch "\\(done|failed)\\" } |
         Sort-Object LastWriteTime

if(-not $tasks){
  Write-Host "[queue-runner] No tasks in queue."
  exit 0
}

foreach($t in $tasks){
  try{
    $raw = Get-Content $t.FullName -Raw -Encoding UTF8
    $job = $raw | ConvertFrom-Json

    $taskId = [string]$job.taskId
    $agent  = [string]$job.target
    $prompt = [string]$job.prompt

    if([string]::IsNullOrWhiteSpace($taskId) -or [string]::IsNullOrWhiteSpace($agent) -or [string]::IsNullOrWhiteSpace($prompt)){
      throw "Invalid task json fields (taskId/target/prompt required)."
    }

    Write-Host ("[queue-runner] RUN taskId={0} target={1}" -f $taskId,$agent)

    # 调用单任务执行器（你已验收通过）
    powershell -ExecutionPolicy Bypass -File $Runner -AgentName $agent -Task $prompt -TaskId $taskId

    # 成功：移入 done
    $dest = Join-Path $DoneDir $t.Name
    Move-Item -Force $t.FullName $dest
    Write-Host ("[queue-runner] DONE taskId={0} -> {1}" -f $taskId,$dest)

    # 【优化B】合并结果摘要到通知
    $resultFile = "C:\OpenClaw_Workspace\agents\$agent\memory\logs\$taskId-result.json"
    $notifFile  = "C:\OpenClaw_Workspace\bindings\notifications\$taskId.json"
    
    if ((Test-Path $resultFile) -and (Test-Path $notifFile)) {
      try {
        $resultJson = Get-Content $resultFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $notifJson  = Get-Content $notifFile -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # 合并结果字段
        $notifJson | Add-Member -NotePropertyName "result" -NotePropertyValue $resultJson.result -Force
        $notifJson | Add-Member -NotePropertyName "status" -NotePropertyValue $resultJson.status -Force
        $notifJson | Add-Member -NotePropertyName "completedAt" -NotePropertyValue $resultJson.completedAt -Force
        $notifJson | Add-Member -NotePropertyName "summary_detail" -NotePropertyValue $resultJson.result -Force
        
        # 写回通知文件
        $notifJson | ConvertTo-Json -Depth 3 | Set-Content $notifFile -Encoding UTF8
        Write-Host ("[queue-runner] ENRICHED notification with result for taskId={0}" -f $taskId)
      }
      catch {
        Write-Host ("[queue-runner] WARN: Failed to enrich notification for taskId={0}: {1}" -f $taskId, $_.Exception.Message)
      }
    }
  }
  catch{
    $msg = $_.Exception.Message
    Write-Host ("[queue-runner] FAIL file={0} err={1}" -f $t.FullName,$msg)`n    try { Set-Content -Path ($t.FullName + ".err.txt") -Value $msg -Encoding UTF8 } catch {}
    $dest = Join-Path $FailDir $t.Name
    Move-Item -Force $t.FullName $dest -ErrorAction SilentlyContinue
  }
}

