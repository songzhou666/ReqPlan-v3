<#
.SYNOPSIS
  检查 Harness 目录结构完整性
.DESCRIPTION
  验证所有 12 个 Landing Zone 是否就位，输出缺失项清单。
  对应 Task Pipeline Stage 1 门控：确认 landing zone 就绪。
  注意：本脚本检查的是 v3.3 路径体系，v4.x 已改用 .agent/harness/
.EXAMPLE
  .\check-structure.ps1
  输出每个 landing zone 的检查状态和最终结果。
#>

# 定义所有 Landing Zone 的预期位置
$landingZones = @(
    @{ Name = "AGENTS.md"; Path = "AGENTS.md"; Type = "file"; Required = $true },
    @{ Name = "PLANS.md"; Path = ".agent/PLANS.md"; Type = "file"; Required = $true },
    @{ Name = "plans/"; Path = ".agent/plans/"; Type = "dir"; Required = $true },
    @{ Name = "control-plane.md"; Path = "docs/harness/control-plane.md"; Type = "file"; Required = $false },
    @{ Name = "project-constraints.md"; Path = "docs/harness/project-constraints.md"; Type = "file"; Required = $false },
    @{ Name = "test/"; Path = "docs/test/"; Type = "dir"; Required = $false },
    @{ Name = "harness_scripts/"; Path = "scripts/harness/"; Type = "dir"; Required = $true },
    @{ Name = "agent_prompts/"; Path = ".agent/prompts/"; Type = "dir"; Required = $false },
    @{ Name = "agent_guides/"; Path = ".agent/guides/"; Type = "dir"; Required = $false },
    @{ Name = "state.yaml"; Path = ".trae/reqplan/state.yaml"; Type = "file"; Required = $false },
    @{ Name = "snapshots/"; Path = ".trae/reqplan/snapshots/"; Type = "dir"; Required = $false },
    @{ Name = "project_root"; Path = "."; Type = "dir"; Required = $true }
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$failCount = 0
$warnCount = 0

Write-Host "=== Harness 目录结构检查 (v3.3 遗留) ==="
Write-Host "项目根目录: $projectRoot"
Write-Host ""

foreach ($zone in $landingZones) {
    $fullPath = Join-Path $projectRoot $zone.Path
    $exists = if ($zone.Type -eq "dir") { Test-Path $fullPath -PathType Container } else { Test-Path $fullPath -PathType Leaf }

    if ($exists) {
        Write-Host "[PASS] 已存在: $($zone.Name) ($($zone.Path))"
    } elseif ($zone.Required) {
        Write-Host "[FAIL] 缺失必需: $($zone.Name) ($($zone.Path))"
        $failCount++
    } else {
        Write-Host "[WARN] 建议补充: $($zone.Name) ($($zone.Path))"
        $warnCount++
    }
}

Write-Host ""
Write-Host "---"
Write-Host "Result: $failCount failed, $warnCount warning"

if ($failCount -gt 0) {
    Write-Host "建议: 运行 /reqplan init 创建缺失的必需结构"
}

exit $failCount
