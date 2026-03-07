# Install OpenClaw Supervisor as Windows Scheduled Task
# Run this script as Administrator

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Right-click this file and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "=== Installing OpenClaw Supervisor Service ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$supervisorScript = "C:\OpenClaw_Workspace\workspace\bindings\supervisor.ps1"
$taskName = "OpenClaw-Supervisor"

# Verify supervisor script exists
if (-not (Test-Path $supervisorScript)) {
    Write-Host "❌ Supervisor script not found: $supervisorScript" -ForegroundColor Red
    pause
    exit 1
}

# Remove existing task if present
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "⚠️  Removing existing task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create scheduled task
Write-Host "📝 Creating scheduled task..." -ForegroundColor Cyan

$action = New-ScheduledTaskAction `
    -Execute "pwsh.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$supervisorScript`""

$trigger = New-ScheduledTaskTrigger -AtStartup

$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType S4U `
    -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Days 0)

try {
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Description "OpenClaw Supervisor - Monitors and processes tasks automatically" `
        -ErrorAction Stop | Out-Null
    
    Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Display task info
    $task = Get-ScheduledTask -TaskName $taskName
    Write-Host "Task Name: $($task.TaskName)" -ForegroundColor White
    Write-Host "State: $($task.State)" -ForegroundColor White
    Write-Host "Trigger: At system startup" -ForegroundColor White
    Write-Host ""
    
    # Ask if user wants to start now
    $start = Read-Host "Start the task now? (Y/N)"
    if ($start -eq "Y" -or $start -eq "y") {
        Start-ScheduledTask -TaskName $taskName
        Start-Sleep -Seconds 2
        
        # Check if running
        $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
        Write-Host ""
        Write-Host "✅ Task started!" -ForegroundColor Green
        Write-Host "Last Run Time: $($taskInfo.LastRunTime)" -ForegroundColor White
        Write-Host "Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "=== Installation Complete ===" -ForegroundColor Green
    Write-Host "The supervisor will now start automatically on system boot." -ForegroundColor White
    Write-Host ""
    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host "  Start:   Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
    Write-Host "  Stop:    Stop-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
    Write-Host "  Status:  Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
    Write-Host "  Remove:  Unregister-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
pause
