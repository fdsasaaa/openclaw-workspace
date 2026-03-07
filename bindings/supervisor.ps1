# bindings/supervisor.ps1
# OpenClaw - Claude Task Monitor v2.0 (Polling Mode)

param(
    [string]$InboundDir = "C:\OpenClaw_Workspace\workspace\bindings\queue\inbound",
    [string]$Handler = "C:\OpenClaw_Workspace\workspace\bindings\claude-handler-v1.1.ps1",
    [string]$LogFile = "C:\OpenClaw_Workspace\workspace\bindings\logs\supervisor.log",
    [int]$PollIntervalSec = 10
)

# UTF-8 encoding support for Chinese characters
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path (Split-Path $LogFile) | Out-Null
New-Item -ItemType Directory -Force -Path $InboundDir | Out-Null

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$ts $msg"
    # Ensure UTF-8 encoding for log file
    $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Write-Host $logLine
}

Write-Log "=== Supervisor Started (Polling Mode) ==="
Write-Log "Monitoring: $InboundDir"
Write-Log "Handler: $Handler"
Write-Log "Poll Interval: $PollIntervalSec seconds"

$processedFiles = @{}

while ($true) {
    try {
        $files = Get-ChildItem -Path $InboundDir -Filter "*.json" -File
        
        foreach ($file in $files) {
            if (-not $processedFiles.ContainsKey($file.FullName)) {
                Write-Log "[EVENT] New task: $($file.Name)"
                
                # Mark as processing
                $processedFiles[$file.FullName] = $true
                
                # Wait for file write to complete
                Start-Sleep -Seconds 1
                
                # Execute handler
                try {
                    & $Handler -TaskFile $file.FullName
                    Write-Log "[SUCCESS] Completed: $($file.Name)"
                } catch {
                    Write-Log "[ERROR] Failed: $($file.Name) - $_"
                }
            }
        }
    } catch {
        Write-Log "[ERROR] Poll failed: $_"
    }
    
    Start-Sleep -Seconds $PollIntervalSec
}
