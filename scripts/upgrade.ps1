#Requires -Version 5.1
# upgrade.ps1 - 规范库升级脚本 (Windows PowerShell)
# 检查版本变更并提示用户

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$StandardsDir = Split-Path -Parent $ScriptDir
$VersionFile = Join-Path $StandardsDir "VERSION"

# 读取当前规范库版本
$CurrentVersion = (Get-Content -Path $VersionFile -Raw).Trim()
Write-Host "Current standards version: $CurrentVersion"

# 检查是否有版本变更
$OldVersionFile = ".ai-standards-version"
if (Test-Path $OldVersionFile) {
    $OldVersion = (Get-Content -Path $OldVersionFile -Raw).Trim()
    if ($OldVersion -ne $CurrentVersion) {
        Write-Host "Version changed from $OldVersion to $CurrentVersion"

        $OldMajor = ($OldVersion -split '\.')[0]
        $CurrentMajor = ($CurrentVersion -split '\.')[0]

        if ($OldMajor -ne $CurrentMajor) {
            Write-Warning "主版本升级! 请检查 BREAKING_CHANGES.md (如果存在)"
        }
    }
}

# 更新版本记录
Set-Content -Path $OldVersionFile -Value $CurrentVersion -Encoding UTF8 -NoNewline

# 提示重新运行 install
Write-Host "Consider running install.ps1 again to update links"
Write-Host "  .ai-standards/scripts/install.ps1 -Tool claude-code -Merge"

Write-Host "Upgrade check complete"
