#Requires -Version 5.1
# install.ps1 - AI 工程规范库安装脚本 (Windows PowerShell)
# 将规范文件链接到项目目录

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --- 辅助函数 ---

function New-LinkItem {
    <#
    .SYNOPSIS
    创建链接或复制文件/目录，支持多级降级策略
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][ValidateSet("Directory","File")][string]$Type
    )

    # 目标已存在则先移除
    if (Test-Path $Destination) {
        Remove-Item $Destination -Force -Recurse:$($Type -eq "Directory")
    }

    if ($Type -eq "Directory") {
        # 优先 Junction（目录联接，无需管理员权限）
        try {
            New-Item -ItemType Junction -Path $Destination -Target $Source -Force | Out-Null
            Write-Host "  [Junction] $Destination -> $Source"
            return
        } catch {
            Write-Verbose "Junction 失败: $_"
        }

        # 次选 SymbolicLink（需要管理员或开发者模式）
        try {
            New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force | Out-Null
            Write-Host "  [SymbolicLink] $Destination -> $Source"
            return
        } catch {
            Write-Verbose "SymbolicLink 失败: $_"
        }

        # 降级：直接复制
        Copy-Item -Path $Source -Destination $Destination -Recurse -Force
        Write-Host "  [Copy] $Destination (copied from $Source)"
        Write-Warning "已降级为目录复制，规范库更新后需重新运行 install.ps1"
    }
    else {
        # 优先 SymbolicLink
        try {
            New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force | Out-Null
            Write-Host "  [SymbolicLink] $Destination -> $Source"
            return
        } catch {
            Write-Verbose "SymbolicLink 失败: $_"
        }

        # 次选 HardLink（同卷无需管理员）
        try {
            New-Item -ItemType HardLink -Path $Destination -Target $Source -Force | Out-Null
            Write-Host "  [HardLink] $Destination -> $Source"
            return
        } catch {
            Write-Verbose "HardLink 失败: $_"
        }

        # 降级：直接复制
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-Host "  [Copy] $Destination (copied from $Source)"
        Write-Warning "已降级为文件复制，规范库更新后需重新运行 install.ps1"
    }
}

function ConvertTo-Hashtable {
    <#
    .SYNOPSIS
    将 PSCustomObject 递归转换为 Hashtable
    #>
    param([Parameter(Mandatory)]$InputObject)

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        if ($InputObject -is [System.Collections.IDictionary]) {
            $hash = @{}
            foreach ($key in $InputObject.Keys) {
                $hash[$key] = ConvertTo-Hashtable -InputObject $InputObject[$key]
            }
            return $hash
        } else {
            $array = @()
            foreach ($item in $InputObject) {
                $array += ,(ConvertTo-Hashtable -InputObject $item)
            }
            return $array
        }
    } elseif ($InputObject -is [PSCustomObject]) {
        $hash = @{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $hash[$prop.Name] = ConvertTo-Hashtable -InputObject $prop.Value
        }
        return $hash
    } else {
        return $InputObject
    }
}

function Merge-Hashtable {
    <#
    .SYNOPSIS
    递归合并两个 Hashtable，Source 覆盖 Base 同名键，新键追加
    等价于 jq -s '.[0] * .[1]'
    #>
    param([Parameter(Mandatory)][hashtable]$BaseHash, [Parameter(Mandatory)][hashtable]$SourceHash)

    $result = $BaseHash.Clone()
    foreach ($key in $SourceHash.Keys) {
        if ($result.ContainsKey($key) -and
            $result[$key] -is [hashtable] -and $SourceHash[$key] -is [hashtable]) {
            $result[$key] = Merge-Hashtable -BaseHash $result[$key] -SourceHash $SourceHash[$key]
        } else {
            $result[$key] = $SourceHash[$key]
        }
    }
    return $result
}

function Merge-JsonFile {
    <#
    .SYNOPSIS
    合并两个 JSON 文件，Source 覆盖 Destination 同名键，结果写入 Destination
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DestinationFile,
        [Parameter(Mandatory)][string]$SourceFile
    )

    $baseJson = Get-Content -Path $DestinationFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $sourceJson = Get-Content -Path $SourceFile -Raw -Encoding UTF8 | ConvertFrom-Json

    $baseHash = ConvertTo-Hashtable -InputObject $baseJson
    $sourceHash = ConvertTo-Hashtable -InputObject $sourceJson

    if ($baseHash -is [hashtable] -and $sourceHash -is [hashtable]) {
        $merged = Merge-Hashtable -BaseHash $baseHash -SourceHash $sourceHash
    } else {
        $merged = $sourceHash
    }

    $mergedJson = $merged | ConvertTo-Json -Depth 10
    Set-Content -Path $DestinationFile -Value $mergedJson -Encoding UTF8 -NoNewline
}

# --- 参数 ---

[CmdletBinding()]
param(
    [Parameter(HelpMessage="目标工具名称")]
    [ValidateSet("claude-code", "trae", "qoder")]
    [string]$Tool = "claude-code",

    [Parameter(HelpMessage="多工具安装，逗号分隔")]
    [string]$Tools = "",

    [Parameter(HelpMessage="合并 settings.json 而非覆盖")]
    [switch]$Merge,

    [Parameter(HelpMessage="项目根目录路径")]
    [string]$ProjectRoot = (Get-Location).Path
)

# --- 路径初始化 ---

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$StandardsDir = Split-Path -Parent $ScriptDir
$SharedDir = Join-Path $StandardsDir "shared"
$ToolsDir = Join-Path $StandardsDir "tools"

# --- 多工具安装 ---

if ($Tools -ne "") {
    $toolList = $Tools -split ","
    foreach ($t in $toolList) {
        $t = $t.Trim()
        if ($t -ne "") {
            & $MyInvocation.MyCommand.Definition -Tool $t -ProjectRoot $ProjectRoot
        }
    }
    return
}

# --- 主逻辑 ---

Write-Host "Installing AI standards for: $Tool"
Write-Host "Project root: $ProjectRoot"

switch ($Tool) {
    "claude-code" {
        $ClaudeDir = Join-Path $ProjectRoot ".claude"

        if (-not (Test-Path $ClaudeDir)) {
            New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
        }

        # CLAUDE.md (文件)
        $agentsMd = Join-Path $SharedDir "AGENTS.md"
        $claudeMd = Join-Path $ClaudeDir "CLAUDE.md"
        New-LinkItem -Source $agentsMd -Destination $claudeMd -Type "File"

        # commands (目录)
        $commandsSrc = Join-Path $StandardsDir "commands"
        $commandsDest = Join-Path $ClaudeDir "commands"
        New-LinkItem -Source $commandsSrc -Destination $commandsDest -Type "Directory"

        # skills (目录)
        $skillsSrc = Join-Path $StandardsDir "skills"
        $skillsDest = Join-Path $ClaudeDir "skills"
        New-LinkItem -Source $skillsSrc -Destination $skillsDest -Type "Directory"

        # hooks (目录)
        $hooksSrc = Join-Path $StandardsDir "hooks"
        $hooksDest = Join-Path $ClaudeDir "hooks"
        New-LinkItem -Source $hooksSrc -Destination $hooksDest -Type "Directory"

        # settings.json
        $settingsSrc = Join-Path $ToolsDir "claude-code" "settings.json"
        $settingsDest = Join-Path $ClaudeDir "settings.json"

        if ($Merge -and (Test-Path $settingsDest)) {
            try {
                Merge-JsonFile -DestinationFile $settingsDest -SourceFile $settingsSrc
                Write-Host "Merged settings.json"
            } catch {
                Write-Warning "JSON 合并失败: $_"
                Write-Warning "降级为直接复制 settings.json"
                Copy-Item -Path $settingsSrc -Destination $settingsDest -Force
            }
        } else {
            Copy-Item -Path $settingsSrc -Destination $settingsDest -Force
        }

        Write-Host "Claude Code standards installed successfully"
    }

    "trae" {
        $TraeDir = Join-Path $ProjectRoot ".trae"
        if (-not (Test-Path $TraeDir)) {
            New-Item -ItemType Directory -Path $TraeDir -Force | Out-Null
        }

        New-LinkItem -Source (Join-Path $SharedDir "AGENTS.md") -Destination (Join-Path $TraeDir "AGENTS.md") -Type "File"
        New-LinkItem -Source (Join-Path $StandardsDir "commands") -Destination (Join-Path $TraeDir "commands") -Type "Directory"
        New-LinkItem -Source (Join-Path $StandardsDir "skills") -Destination (Join-Path $TraeDir "skills") -Type "Directory"

        Write-Host "Trae standards installed (experimental)"
    }

    "qoder" {
        $QoderDir = Join-Path $ProjectRoot ".qoder"
        if (-not (Test-Path $QoderDir)) {
            New-Item -ItemType Directory -Path $QoderDir -Force | Out-Null
        }

        New-LinkItem -Source (Join-Path $SharedDir "AGENTS.md") -Destination (Join-Path $QoderDir "AGENTS.md") -Type "File"
        New-LinkItem -Source (Join-Path $StandardsDir "commands") -Destination (Join-Path $QoderDir "commands") -Type "Directory"
        New-LinkItem -Source (Join-Path $StandardsDir "skills") -Destination (Join-Path $QoderDir "skills") -Type "Directory"

        Write-Host "Qoder standards installed (experimental)"
    }
}

Write-Host "Done!"
