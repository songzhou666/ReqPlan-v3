<#
.SYNOPSIS
  验证验证报告是否覆盖全部5层验证体系
.DESCRIPTION
  读取指定路径下的验证报告或验证摘要文件，检查是否覆盖5层：
  - Static (静态检查)
  - Unit (单元验证)
  - Integration (链路验证)
  - Failure (失败场景验证)
  - Writeback (回写验证)
  对应 Action: action_verify 的后置校验。
  注意：本脚本检查的是 v3.3 格式，v4.x 已改用 .agent/harness/_verification.md
.PARAMETER Path
  验证报告目录或文件路径。默认搜索 docs/test/ 下的 verification-*.yaml 或 summary 文件。
.EXAMPLE
  .\validate-verification.ps1
  自动查找最新的验证报告并校验5层覆盖。

  .\validate-verification.ps1 -Path "docs/test/verification-summary.yaml"
  校验指定验证报告。
#>

param(
    [string]$Path = ""
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$failCount = 0
$warnCount = 0

Write-Host "=== 验证报告5层全覆盖校验 (v3.3 遗留) ==="
Write-Host ""

# 5层验证定义 (对应 core-verification.md)
$layers = @(
    @{ Layer = "Static";     Aliases = @("Static", "静态检查", "static check", "lint", "typecheck", "编译检查"); Description = "代码结构、类型、lint、编译" }
    @{ Layer = "Unit";       Aliases = @("Unit", "单元验证", "unit test", "单测", "unittest"); Description = "核心函数和边界条件" }
    @{ Layer = "Integration"; Aliases = @("Integration", "链路验证", "integration", "集成", "入口"); Description = "入口到输出的完整链路" }
    @{ Layer = "Failure";    Aliases = @("Failure", "失败验证", "failure", "异常", "重试", "回滚"); Description = "异常、超时、重试、停止策略" }
    @{ Layer = "Writeback";  Aliases = @("Writeback", "回写验证", "writeback", "回写", "结果记录"); Description = "结果同步到任务系统/PR/文档" }
)

# 确定目标文件
$targetFiles = @()

if ($Path -ne "" -and (Test-Path $Path -PathType Leaf)) {
    $targetFiles += Get-Item $Path
} elseif ($Path -ne "" -and (Test-Path $Path -PathType Container)) {
    $targetFiles = Get-ChildItem -Path $Path -Include "verification-*.yaml", "verification-*.yml", "*summary*" | Sort-Object LastWriteTime -Descending
    if ($targetFiles.Count -eq 0) {
        $targetFiles = Get-ChildItem -Path $Path -Filter "*.yaml" -Recurse | Where-Object { $_.Name -match "verif|summary|report" } | Sort-Object LastWriteTime -Descending
    }
} elseif ($Path -ne "") {
    Write-Host "[ERROR] 指定路径不存在: $Path"
    Write-Host "---"
    Write-Host "Result: 1 error"
    exit 10
} else {
    # 默认路径: 项目的 docs/test/ 和 .trae/reqplan/
    $searchPaths = @(
        Join-Path $projectRoot "docs\test"
        Join-Path $projectRoot ".trae\reqplan"
    )
    $foundFiles = @()
    foreach ($sp in $searchPaths) {
        if (Test-Path $sp -PathType Container) {
            $candidates = Get-ChildItem -Path $sp -Include "verification-*.yaml", "verification-*.yml", "*summary*" -ErrorAction SilentlyContinue
            if ($candidates) {
                $foundFiles += $candidates
            }
        }
    }
    if ($foundFiles.Count -gt 0) {
        $targetFiles = $foundFiles | Sort-Object LastWriteTime -Descending
    }
}

if ($targetFiles.Count -eq 0) {
    Write-Host "[WARN] 未找到验证报告文件"
    Write-Host "[WARN] 请确保已执行验证并生成了验证摘要文件"
    Write-Host "[WARN] 可通过 -Path 指定验证文件或目录"
    Write-Host "---"
    Write-Host "Result: 0 failed, 1 warning"
    exit 0
}

# 逐文件检查
foreach ($file in $targetFiles) {
    Write-Host "检查文件: $($file.Name)"
    Write-Host "路径: $($file.FullName)"
    Write-Host "修改时间: $($file.LastWriteTime)"
    Write-Host ""

    $content = Get-Content $file.FullName -Raw

    Write-Host "-- 5层验证覆盖检查 --"
    $layerResults = @{}
    foreach ($layer in $layers) {
        $found = $false
        foreach ($alias in $layer.Aliases) {
            if ($content -match "(?i)$alias") {
                $found = $true
                break
            }
        }
        $layerResults[$layer.Layer] = $found
        if ($found) {
            Write-Host "[PASS] 已覆盖: $($layer.Layer) - $($layer.Description)"
        } else {
            Write-Host "[FAIL] 未覆盖: $($layer.Layer) - $($layer.Description)"
            $failCount++
        }
    }

    # 额外检查：验证结果是否有明确的 pass/fail 判定
    Write-Host ""
    Write-Host "-- 结果判定完整性 --"
    $hasPassFail = $content -match "(?i)(PASS|FAIL|通过|失败|passed|failed|✅|❌)"
    if ($hasPassFail) {
        Write-Host "[PASS] 包含通过/失败判定"
    } else {
        Write-Host "[WARN] 缺少明确的通过/失败判定，建议标记每层结果"
        $warnCount++
    }

    # 检查是否包含测试命令或验证命令引用
    $hasCommands = $content -match "(?i)(命令|command|run|执行|exec|\.ps1|npm test|pytest|go test)"
    if ($hasCommands) {
        Write-Host "[PASS] 包含验证命令引用"
    } else {
        Write-Host "[WARN] 建议引用具体的验证命令以便复现"
        $warnCount++
    }

    Write-Host ""
}

Write-Host "---"
Write-Host "Result: $failCount failed, $warnCount warning"

if ($failCount -gt 0) {
    Write-Host "建议: 补充缺失的验证层，确保验证报告覆盖全部5层"
    Write-Host "  5层: Static(静态) → Unit(单元) → Integration(链路) → Failure(失败) → Writeback(回写)"
}

exit $failCount
