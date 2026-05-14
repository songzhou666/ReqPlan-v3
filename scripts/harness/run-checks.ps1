<#
.SYNOPSIS
  综合检查入口：依次运行所有 check-* 和 validate-* 脚本
.DESCRIPTION
  按管道阶段的顺序依次运行所有检查脚本，汇总结果。
  任务收口前应运行此脚本执行全量检查。
  任何单项检查失败都会导致整体失败。
.EXAMPLE
  .\run-checks.ps1
#>

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$totalFail = 0
$totalWarn = 0
$errorCount = 0

$scripts = @(
    @{ Name = "结构完整性";  Path = "check-structure.ps1" },
    @{ Name = "计划格式";    Path = "check-plan.ps1" },
    @{ Name = "入口点验证";   Path = "validate-entry-points.ps1" },
    @{ Name = "意图分析校验";  Path = "validate-intent-analysis.ps1" },
    @{ Name = "验证报告校验";  Path = "validate-verification.ps1" },
    @{ Name = "评审门禁校验";  Path = "verify-review-gate.ps1" }
)

Write-Host "========================================="
Write-Host "  Harness 全量检查套件"
Write-Host "========================================="
Write-Host ""

$results = @()

foreach ($script in $scripts) {
    $scriptPath = Join-Path $PSScriptRoot $script.Path
    if (-not (Test-Path $scriptPath)) {
        Write-Host "[WARN] 脚本不存在，已跳过: $($script.Path)"
        $totalWarn++
        continue
    }

    Write-Host ">>> [$($script.Name)] $($script.Path)"
    Write-Host "-----------------------------------------"

    $output = & $scriptPath 2>&1
    $exitCode = $LASTEXITCODE

    foreach ($line in $output) {
        Write-Host "$line"
        if ($line -match '^\[FAIL\]') { $totalFail++ }
        if ($line -match '^\[WARN\]') { $totalWarn++ }
        if ($line -match '^\[ERROR\]') { $errorCount++ }
    }

    if ($exitCode -ne 0) {
        Write-Host "[FAIL] $($script.Name) 未通过"
    } else {
        Write-Host "[PASS] $($script.Name) 通过"
    }
    Write-Host ""
}

Write-Host "========================================="
Write-Host "  全量检查汇总"
Write-Host "========================================="
Write-Host "  Failed : $totalFail"
Write-Host "  Warning: $totalWarn"
Write-Host "  Errors : $errorCount"
Write-Host "========================================="

if ($totalFail -gt 0 -or $errorCount -gt 0) {
    Write-Host "  结果: 部分检查未通过，请修复后重试"
} else {
    Write-Host "  结果: 全部通过"
}
Write-Host "========================================="

exit ($totalFail + $errorCount)
