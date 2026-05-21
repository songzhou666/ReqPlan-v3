<#
.SYNOPSIS
  验证计划文件中定义的真实入口点是否可达
.DESCRIPTION
  读取 .agent/plans/ 中最新的计划文件，提取 Entry Points 表格中的文件路径和命令，
  逐一验证文件是否存在、命令是否可执行。
  对应 Task Pipeline Stage 2 门控：入口点真实可触达。
  注意：本脚本检查的是 v3.3 的 .agent/plans/ 路径，v4.x 已改用 .agent/harness/ 产物
.EXAMPLE
  .\validate-entry-points.ps1
  输出每个入口点的验证状态和最终结果。
#>

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$plansDir = Join-Path $projectRoot ".agent\plans"

Write-Host "=== 入口点有效性验证 (v3.3 遗留) ==="
Write-Host ""

# 查找最新的计划文件
if (-not (Test-Path $plansDir -PathType Container)) {
    Write-Host "[INFO] 计划目录不存在，跳过验证"
    Write-Host "---"
    Write-Host "Result: 0 failed"
    exit 0
}

$latestPlan = Get-ChildItem -Path $plansDir -Filter "*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $latestPlan) {
    Write-Host "[INFO] 暂无计划文件，跳过验证"
    Write-Host "---"
    Write-Host "Result: 0 failed"
    exit 0
}

Write-Host "检查文件: $($latestPlan.Name)"
Write-Host ""

$planContent = Get-Content $latestPlan.FullName -Raw
$lines = $planContent -split "`r`n|`n"
$failCount = 0
$warnCount = 0

# 状态跟踪
$inEntryTable = $false
$inCommandBlock = $false
$commandBlockLines = @()

# 辅助函数：检查 npm/yarn 脚本
function Test-NpmScript {
    param([string]$cmdName)
    $pkgPath = Join-Path $projectRoot "package.json"
    if (Test-Path $pkgPath) {
        $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
        if ($pkg.scripts.PSObject.Properties.Name -contains $cmdName) {
            return $true
        }
    }
    return $false
}

# 辅助函数：检查 Python 模块路径
function Test-PythonModule {
    param([string]$modulePath)
    $parts = $modulePath -split '\.'
    $pyPaths = @()
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $pyPaths += "$( Join-Path $projectRoot ($parts[0..$i] -join '\') ).py"
    }
    $pyPaths += Join-Path $projectRoot ($parts -join '\')
    foreach ($p in $pyPaths) {
        if (Test-Path $p) { return $true }
    }
    return $false
}

# 辅助函数：检查命令是否存在（系统命令或 npm/yarn 脚本）
function Test-AnyCommand {
    param([string]$cmdName)
    if (Get-Command $cmdName -ErrorAction SilentlyContinue) { return $true }
    if (Test-NpmScript $cmdName) { return $true }
    return $false
}

# 解析 Entry Points 表格和命令块
foreach ($line in $lines) {
    if ($line -match '^```\w*$' -and $inCommandBlock) {
        $inCommandBlock = $false
        continue
    }
    if ($line -match '^```\w*$' -and -not $inCommandBlock) {
        $inCommandBlock = $true
        continue
    }
    if ($inCommandBlock -and $line -notmatch '^```') {
        $trimmed = $line.Trim()
        if ($trimmed -ne "") {
            $commandBlockLines += $trimmed
        }
    }

    if ($line -match '^\|\s*(command|file|api|config|script)\s*\|') {
        $parts = $line -split '\|' | ForEach-Object { $_.Trim() }
        if ($parts.Count -ge 3) {
            $entryType = $parts[1]
            $entryPath = $parts[2]
            if ($entryType -eq "file") {
                $fullPath = Join-Path $projectRoot $entryPath
                if (Test-Path $fullPath) {
                    Write-Host "[PASS] 文件入口可达: $entryPath"
                } else {
                    Write-Host "[FAIL] 文件入口不可达: $entryPath"
                    $failCount++
                }
            } elseif ($entryType -eq "command") {
                $cmd = $entryPath.Split(' ')[0]
                if (Test-AnyCommand $cmd) {
                    Write-Host "[PASS] 命令可用: $cmd ($entryPath)"
                } else {
                    Write-Host "[WARN] 命令不可直接验证: $entryPath (可能在容器或远程环境)"
                    $warnCount++
                }
            } elseif ($entryType -eq "api") {
                Write-Host "[WARN] API 入口需运行时验证: $entryPath"
                $warnCount++
            } else {
                Write-Host "[WARN] 入口类型 '$entryType' 跳过验证: $entryPath"
                $warnCount++
            }
        }
    }
}

# 验证命令块中的命令
foreach ($cmdLine in $commandBlockLines) {
    $cmd = $cmdLine.Split(' ')[0]
    if (Test-AnyCommand $cmd) {
        Write-Host "[PASS] 命令块命令可用: $cmdLine"
    } else {
        Write-Host "[WARN] 命令块命令不可直接验证: $cmdLine"
        $warnCount++
    }
}
# Python import 风格检查
$commandBlockLines | Where-Object { $_ -match '^(from |import )' } | ForEach-Object {
    if ($_ -match 'from\s+(\S+)\s+import') {
        if (Test-PythonModule $matches[1]) {
            Write-Host "[PASS] Python 模块路径: $_"
        } else {
            Write-Host "[WARN] Python 模块路径不可达: $_"
            $warnCount++
        }
    }
}

Write-Host ""
Write-Host "---"
Write-Host "Result: $failCount failed, $warnCount warning"

if ($failCount -gt 0) {
    Write-Host "建议: 更新计划中的入口路径，确保文件路径正确"
}

exit $failCount
