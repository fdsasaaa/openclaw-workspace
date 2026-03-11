# Add Claude Opus 4-6 API Configuration
# Usage: Run this script directly

$configPath = "$env:USERPROFILE\.openclaw\openclaw.json"

Write-Host "Starting Claude Opus 4-6 API configuration..." -ForegroundColor Cyan

# 1. Backup current config
$backupPath = "$configPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $configPath $backupPath
Write-Host "Config backed up to: $backupPath" -ForegroundColor Green

# 2. Read current config
$config = Get-Content $configPath -Raw | ConvertFrom-Json

# 3. Add new provider
if (-not $config.models.providers.PSObject.Properties['claude-opus-api123']) {
    $newProvider = @{
        baseUrl = "https://api123.icu/v1"
        apiKey = "sk-TnJW2DqNNsqFkfwAZNmKDiWIRD1k0kLLtKQdFefR9USTNR30"
        auth = "api-key"
        api = "anthropic-messages"
        headers = @{}
        authHeader = "x-api-key"
        models = @(
            @{
                id = "claude-opus-4-6"
                name = "Claude Opus 4.6 (api123)"
                contextWindow = 200000
                maxTokens = 8192
            }
        )
    }
    
    $config.models.providers | Add-Member -MemberType NoteProperty -Name "claude-opus-api123" -Value $newProvider
    Write-Host "Added claude-opus-api123 provider" -ForegroundColor Green
} else {
    Write-Host "Provider already exists, skipping" -ForegroundColor Yellow
}

# 4. Add to agents.defaults.models
if (-not $config.agents.defaults.models.PSObject.Properties['claude-opus-api123/claude-opus-4-6']) {
    $config.agents.defaults.models | Add-Member -MemberType NoteProperty -Name "claude-opus-api123/claude-opus-4-6" -Value @{
        alias = "opus"
    }
    Write-Host "Added model alias: opus" -ForegroundColor Green
} else {
    Write-Host "Model alias already exists, skipping" -ForegroundColor Yellow
}

# 5. Save config
$config | ConvertTo-Json -Depth 100 | Set-Content $configPath -Encoding UTF8
Write-Host "Configuration saved" -ForegroundColor Green

# 6. Next steps
Write-Host ""
Write-Host "Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart gateway: openclaw gateway restart" -ForegroundColor White
Write-Host "2. Use new model: /model opus" -ForegroundColor White
Write-Host ""
Write-Host "To rollback:" -ForegroundColor Yellow
Write-Host "Copy-Item '$backupPath' '$configPath' -Force" -ForegroundColor White
Write-Host "openclaw gateway restart" -ForegroundColor White
