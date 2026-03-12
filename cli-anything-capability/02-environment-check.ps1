# CLI-Anything 环境检查脚本 (Windows)
Write-Host "=== CLI-Anything 环境检查 ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. 操作系统信息:" -ForegroundColor Yellow
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber | Format-List

Write-Host "2. Node.js 版本:" -ForegroundColor Yellow
node --version
Write-Host ""

Write-Host "3. npm 版本:" -ForegroundColor Yellow
npm --version
Write-Host ""

Write-Host "4. Python 版本:" -ForegroundColor Yellow
python --version 2>$null || python3 --version 2>$null || Write-Host "Python not found"
Write-Host ""

Write-Host "5. Git 版本:" -ForegroundColor Yellow
git --version
Write-Host ""

Write-Host "6. 常用 CLI 工具检查:" -ForegroundColor Yellow
$tools = @(
    @{Name="curl"; Cmd="curl"},
    @{Name="wget"; Cmd="wget"},
    @{Name="jq"; Cmd="jq"},
    @{Name="ffmpeg"; Cmd="ffmpeg"},
    @{Name="ImageMagick"; Cmd="convert"},
    @{Name="pandoc"; Cmd="pandoc"},
    @{Name="7zip"; Cmd="7z"},
    @{Name="PowerShell"; Cmd="powershell"}
)

foreach ($tool in $tools) {
    $exists = Get-Command $tool.Cmd -ErrorAction SilentlyContinue
    if ($exists) {
        Write-Host "  - $($tool.Name): ✓" -ForegroundColor Green
    } else {
        Write-Host "  - $($tool.Name): ✗" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "7. 磁盘空间 (C:):" -ForegroundColor Yellow
Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object @{N="Size(GB)";E={[math]::Round($_.Size/1GB,2)}}, @{N="Free(GB)";E={[math]::Round($_.FreeSpace/1GB,2)}}, @{N="Used%";E={[math]::Round((($_.Size-$_.FreeSpace)/$_.Size)*100,2)}} | Format-List

Write-Host "8. 内存信息:" -ForegroundColor Yellow
Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{N="Total(GB)";E={[math]::Round($_.Sum/1GB,2)}} | Format-List

Write-Host "=== 检查完成 ===" -ForegroundColor Cyan
