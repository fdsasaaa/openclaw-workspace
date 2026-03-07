param(
  [int]$IntervalSeconds = 10,
  [string]$Runner = "C:\OpenClaw_Workspace\bindings\queue-runner.ps1",
  [string]$LogFile = "C:\OpenClaw_Workspace\bindings\logs\queue-daemon.log"
)



# ---- single instance mutex ----
Add-Type -AssemblyName System
$mutexName = "Global\OpenClaw_QueueDaemon"
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) {
  Write-Host "[queue-daemon] Another instance is running (mutex=$mutexName). Exit."
  exit 0
}
Register-EngineEvent PowerShell.Exiting -Action { try { $mutex.ReleaseMutex() } catch {} } | Out-Null
# ---- end mutex ----
$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path (Split-Path $LogFile -Parent) | Out-Null

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] queue-daemon START (interval=${IntervalSeconds}s)" | Out-File $LogFile -Append -Encoding UTF8
Write-Host "[queue-daemon] START. Interval = $IntervalSeconds sec. Ctrl+C to stop."

while ($true) {
  try {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$ts] tick" | Out-File $LogFile -Append -Encoding UTF8

    # 跑一次队列消费（无任务也会输出提示）
    powershell -ExecutionPolicy Bypass -File $Runner 2>&1 |
      ForEach-Object { "[$ts] $_" } |
      Out-File $LogFile -Append -Encoding UTF8
  }
  catch {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$ts] ERROR: $($_.Exception.Message)" | Out-File $LogFile -Append -Encoding UTF8
  }

  Start-Sleep -Seconds $IntervalSeconds
}


