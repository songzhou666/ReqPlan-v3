<#
.SYNOPSIS
  验证意图分析产出物是否符合接口规范
.DESCRIPTION
  读取指定的意图分析结果文件（YAML 格式），验证其是否包含：
  - functionalPoints: 功能点列表
  - userRoles: 用户角色列表
  - dataFlow: 数据流程描述
  - summary: 意图摘要
  对应 Action: action_intent_analyze 的后置校验。
  注意：本脚本检查的是 v3.3 格式，v4.x 已改用 .agent/harness/_analysis.md
.PARAMETER Path
  意图分析结果文件路径。默认搜索 .trae/reqplan/ 下最新的 intent-*.yaml 或 state.yaml。
.EXAMPLE
  .\validate-intent-analysis.ps1
  自动查找最新的意图分析结果并校验。

  .\validate-intent-analysis.ps1 -Path "docs/analysis/intent-001.yaml"
  校验指定文件。
#>

param(
    [string]$Path = ""
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$failCount = 0
$warnCount = 0

Write-Host "=== 意图分析结果校验 (v3.3 遗留) ==="
Write-Host ""

# 确定目标文件
$targetFile = $null

if ($Path -ne "" -and (Test-Path $Path)) {
    $targetFile = Get-Item $Path
} elseif ($Path -ne "") {
    Write-Host "[ERROR] 指定文件不存在: $Path"
    Write-Host "---"
    Write-Host "Result: 1 error"
    exit 10
} else {
    $reqplanDir = Join-Path $projectRoot ".trae\reqplan"
    if (Test-Path $reqplanDir -PathType Container) {
        $intentFiles = Get-ChildItem -Path $reqplanDir -Filter "intent-*.yaml" | Sort-Object LastWriteTime -Descending
        if ($intentFiles -and $intentFiles.Count -gt 0) {
            $targetFile = $intentFiles[0]
            Write-Host "[INFO] 自动发现: $($targetFile.FullName)"
        } else {
            $stateFile = Join-Path $reqplanDir "state.yaml"
            if (Test-Path $stateFile) {
                $targetFile = Get-Item $stateFile
                Write-Host "[INFO] 使用 state.yaml (将从中提取意图分析字段): $stateFile"
            }
        }
    }
}

if (-not $targetFile) {
    Write-Host "[WARN] 未找到意图分析结果文件"
    Write-Host "[WARN] 请确保已执行意图分析，或通过 -Path 指定文件路径"
    Write-Host "---"
    Write-Host "Result: 0 failed, 1 warning"
    exit 0
}

Write-Host "检查文件: $($targetFile.Name)"
Write-Host "修改时间: $($targetFile.LastWriteTime)"
Write-Host ""

# 读取文件内容
$content = Get-Content $targetFile.FullName -Raw

# 标准意图分析必含字段
$requiredFields = @(
    @{ Name = "functionalPoints"; Patterns = @("functionalPoints", "functional_points", "功能点") }
    @{ Name = "userRoles"; Patterns = @("userRoles", "user_roles", "用户角色") }
    @{ Name = "dataFlow"; Patterns = @("dataFlow", "data_flow", "数据流") }
    @{ Name = "summary"; Patterns = @("summary", "意图摘要") }
)

Write-Host "-- 必需字段检查 --"
foreach ($field in $requiredFields) {
    $found = $false
    foreach ($pattern in $field.Patterns) {
        if ($content -match $pattern) {
            $found = $true
            break
        }
    }
    if ($found) {
        Write-Host "[PASS] 包含: $($field.Name)"
    } else {
        Write-Host "[FAIL] 缺失必需字段: $($field.Name)"
        $failCount++
    }
}

# 可选字段检查：置信度、备选推荐
$optionalFields = @(
    @{ Name = "confidence/置信度"; Patterns = @("confidence", "置信度") }
    @{ Name = "alternatives/备选推荐"; Patterns = @("alternatives", "备选推荐", "备选") }
)

Write-Host ""
Write-Host "-- 可选字段检查 --"
foreach ($field in $optionalFields) {
    $found = $false
    foreach ($pattern in $field.Patterns) {
        if ($content -match $pattern) {
            $found = $true
            break
        }
    }
    if ($found) {
        Write-Host "[PASS] 包含: $($field.Name)"
    } else {
        Write-Host "[WARN] 建议补充: $($field.Name)"
        $warnCount++
    }
}

# 结构完整性：验证 functionalPoints 是否为列表格式
if ($content -match "(?ms)functionalPoints[:\[]") {
    $fpMatch = $null
    if ($content -match "(?ms)functionalPoints[:\s]*\n(\s*[-]\s+.+)") {
        Write-Host "[PASS] functionalPoints 为列表格式"
    } elseif ($content -match 'functionalPoints.*\[.*\]') {
        Write-Host "[PASS] functionalPoints 包含数组定义"
    } else {
        Write-Host "[WARN] functionalPoints 存在但格式不明确，建议使用列表格式"
        $warnCount++
    }
}

Write-Host ""
Write-Host "---"
Write-Host "Result: $failCount failed, $warnCount warning"

if ($failCount -gt 0) {
    Write-Host "建议: 补充缺失的意图分析字段，确保产出物符合 core-intent-analysis.md 规范"
}

exit $failCount
