#!/usr/bin/env pwsh
# OpenClaw 紧急回滚脚本
# 提供多层级回滚能力

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("last", "timestamp", "git", "config", "full")]
    [string]$Mode = "last",
    
    [Parameter(Mandatory=$false)]
    [string]$Timestamp,
    
    [Parameter(Mandatory=$false)]
    [switch]$List,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = "C:\OpenClaw_Workspace"
$BackupDir = "$WorkspaceRoot\backup"
$ConfigDir = "C:\Users\ME\.openclaw"

function Show-Help {
    Write-Host @"
OpenClaw 紧急回滚脚本

用法:
  .\emergency-rollback.ps1 -Mode <模式> [选项]

模式:
  last      - 回滚到最近一次备份 (默认)
  timestamp - 回滚到指定时间点 (-Timestamp "20260305_143000")
  git       - 回滚Git仓库到指定commit
  config    - 恢复OpenClaw配置文件
  full      - 完整系统恢复（需确认）

选项:
  -List     - 列出所有可用备份点
  -Force    - 跳过确认提示
  -Timestamp <时间戳> - 指定回滚时间点

示例:
  .\emergency-rollback.ps1 -Mode last
  .\emergency-rollback.ps1 -Mode timestamp -Timestamp "20260305_143000"
  .\emergency-rollback.ps1 -List
"@
}

function Get-BackupPoints {
    $backups = @()
    
    # 文件备份
    if (Test-Path $BackupDir) {
        Get-ChildItem $BackupDir -Directory | ForEach-Object {
            $backups += [PSCustomObject]@{
                Type = "文件备份"
                Name = $_.Name
                Path = $_.FullName
                Time = $_.CreationTime
                Size = (Get-ChildItem $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
            }
        }
    }
    
    # Git历史
    Push-Location $WorkspaceRoot
    $gitLog = git log --oneline -10 2>$null | ForEach-Object {
        $parts = $_ -split ' ', 2
        [PSCustomObject]@{
            Type = "Git提交"
            Name = $parts[1]
            Path = $parts[0]
            Time = "N/A"
            Size = "N/A"
        }
    }
    Pop-Location
    
    # 配置备份
    $configBackups = Get-ChildItem "$ConfigDir\openclaw.json.bak*" -ErrorAction SilentlyContinue | ForEach-Object {
        [PSCustomObject]@{
            Type = "配置备份"
            Name = $_.Name
            Path = $_.FullName
            Time = $_.CreationTime
            Size = $_.Length
        }
    }
    
    return @($backups; $gitLog; $configBackups) | Sort-Object Time -Descending
}

function Rollback-ToLast {
    Write-Host "准备回滚到最近一次备份..." -ForegroundColor Yellow
    
    $latestBackup = Get-ChildItem $BackupDir -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
    if (-not $latestBackup) {
        Write-Error "未找到任何备份！"
        return
    }
    
    Write-Host "将回滚到: $($latestBackup.Name)" -ForegroundColor Cyan
    Write-Host "备份时间: $($latestBackup.CreationTime)" -ForegroundColor Cyan
    
    if (-not $Force) {
        $confirm = Read-Host "确认回滚? [Y/N]"
        if ($confirm -ne 'Y') { return }
    }
    
    # 创建当前状态快照
    $snapshotDir = "$BackupDir\pre-rollback-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host "创建当前状态快照: $snapshotDir" -ForegroundColor Gray
    Copy-Item -Recurse "$WorkspaceRoot\configs", "$WorkspaceRoot\reports", "$WorkspaceRoot\memory" $snapshotDir -ErrorAction SilentlyContinue
    
    # 执行回滚
    Write-Host "正在恢复文件..." -ForegroundColor Yellow
    Copy-Item -Recurse "$($latestBackup.FullName)\*" $WorkspaceRoot -Force
    
    Write-Host "回滚完成！当前状态已保存到: $snapshotDir" -ForegroundColor Green
}

function Rollback-Config {
    Write-Host "准备恢复OpenClaw配置..." -ForegroundColor Yellow
    
    $latestConfig = Get-ChildItem "$ConfigDir\openclaw.json.bak*" | Sort-Object CreationTime -Descending | Select-Object -First 1
    if (-not $latestConfig) {
        Write-Error "未找到配置备份！"
        return
    }
    
    Write-Host "将恢复配置: $($latestConfig.Name)" -ForegroundColor Cyan
    
    if (-not $Force) {
        $confirm = Read-Host "确认恢复配置? [Y/N]"
        if ($confirm -ne 'Y') { return }
    }
    
    # 备份当前配置
    Copy-Item "$ConfigDir\openclaw.json" "$ConfigDir\openclaw.json.pre-rollback.$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
    
    # 恢复
    Copy-Item $latestConfig.FullName "$ConfigDir\openclaw.json" -Force
    
    Write-Host "配置已恢复！请重启OpenClaw Gateway生效" -ForegroundColor Green
    Write-Host "重启命令: openclaw gateway restart" -ForegroundColor Cyan
}

function Rollback-Git {
    param([string]$Commit)
    
    Push-Location $WorkspaceRoot
    
    if (-not $Commit) {
        Write-Host "最近的Git提交:" -ForegroundColor Cyan
        git log --oneline -10
        $Commit = Read-Host "输入要回滚到的commit hash (前7位即可)"
    }
    
    Write-Host "准备回滚Git到: $Commit" -ForegroundColor Yellow
    
    if (-not $Force) {
        $confirm = Read-Host "确认回滚? 此操作会丢失后续提交! [Y/N]"
        if ($confirm -ne 'Y') { Pop-Location; return }
    }
    
    # 创建分支保存当前状态
    $branchName = "pre-rollback-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    git branch $branchName
    
    # 强制回滚
    git reset --hard $Commit
    
    Pop-Location
    
    Write-Host "Git已回滚到: $Commit" -ForegroundColor Green
    Write-Host "原状态已保存到分支: $branchName" -ForegroundColor Cyan
}

# 主逻辑
if ($List) {
    Write-Host "\n可用回滚点:" -ForegroundColor Green
    Write-Host "="*70
    Get-BackupPoints | Format-Table -AutoSize
    exit 0
}

switch ($Mode) {
    "last" { Rollback-ToLast }
    "config" { Rollback-Config }
    "git" { Rollback-Git -Commit $Timestamp }
    "timestamp" { 
        if (-not $Timestamp) {
            Write-Error "使用timestamp模式需要提供 -Timestamp 参数"
            exit 1
        }
        # 查找最接近的备份
        $targetBackup = Get-ChildItem $BackupDir -Directory | Where-Object { $_.Name -like "*$Timestamp*" } | Select-Object -First 1
        if ($targetBackup) {
            Rollback-ToSpecific -Backup $targetBackup
        } else {
            Write-Error "未找到时间戳包含 '$Timestamp' 的备份"
        }
    }
    "full" {
        Write-Host "完整系统恢复" -ForegroundColor Red
        Write-Host "这将恢复所有配置、项目和Git状态" -ForegroundColor Red
        if (-not $Force) {
            $confirm = Read-Host "确认执行完整恢复? [输入 'YES' 确认]"
            if ($confirm -ne 'YES') { return }
        }
        # 执行完整恢复逻辑
        Rollback-ToLast
        Rollback-Config
        Write-Host "完整恢复完成！请重启系统确保所有变更生效" -ForegroundColor Green
    }
    default { Show-Help }
}
