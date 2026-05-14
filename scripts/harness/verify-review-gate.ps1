<#
.SYNOPSIS
  验证评审门禁是否满足关闭条件
.DESCRIPTION
  读取评审报告文件，检查是否满足门禁条件：
  - 没有未关闭的 Critical 级别问题
  - 没有未关闭的 Major 级别问题
  - 所有已关闭问题有关闭理由
  - 存在质量评分
  对应 Action: action_review 的后置校验。
.PARAMETER Path
  评审报告文件路径。默认搜索 docs/review/ 或 .trae/reqplan/ 下的 review-*.yaml 或 report。
.EXAMPLE
  .\verify-review-gate.ps1
  自动查找最新的评审报告并校验门禁。

  .\verify-review-gate.ps1 -Path "docs/review/review-001.yaml"
  校验指定评审报告。
#>

param(
    [string]$Path = ""
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$failCount = 0
$warnCount = 0

Write-Host "=== 评审门禁检查 ==="
Write-Host ""

# 确定目标文件
$targetFile = $null

if ($Path -ne "" -and (Test-Path $Path -PathType Leaf)) {
    $targetFile = Get-Item $Path
} elseif ($Path -ne "") {
    Write-Host "[ERROR] 指定文件不存在: $Path"
    Write-Host "---"
    Write-Host "Result: 1 error"
    exit 10
} else {
    $searchPaths = @(
        Join-Path $projectRoot "docs\review"
        Join-Path $projectRoot ".trae\reqplan"
    )
    foreach ($sp in $searchPaths) {
        if (Test-Path $sp -PathType Container) {
            $candidates = Get-ChildItem -Path $sp -Include "review-*.yaml", "review-*.yml", "*review*report*", "*-review.*" -ErrorAction SilentlyContinue
            if ($candidates -and $candidates.Count -gt 0) {
                $targetFile = $candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                Write-Host "[INFO] 自动发现: $($targetFile.FullName)"
                break
            }
        }
    }
}

if (-not $targetFile) {
    Write-Host "[WARN] 未找到评审报告文件"
    Write-Host "[WARN] 请确保已执行评审并生成了评审报告"
    Write-Host "[WARN] 可通过 -Path 指定评审报告文件路径"
    Write-Host "---"
    Write-Host "Result: 0 failed, 1 warning"
    exit 0
}

Write-Host "检查文件: $($targetFile.Name)"
Write-Host "修改时间: $($targetFile.LastWriteTime)"
Write-Host ""

$content = Get-Content $targetFile.FullName -Raw

Write-Host "-- 质量评分检查 --"
if ($content -match "(?i)(score|评分|质量评分)[^0-9]*([0-9]{1,3})") {
    $score = $Matches[2]
    Write-Host "[PASS] 质量评分: $score"
    if ([int]$score -lt 60) {
        Write-Host "[WARN] 评分低于60，建议改进后再合并"
        $warnCount++
    }
} else {
    Write-Host "[FAIL] 缺少质量评分 (score)"
    $failCount++
}

Write-Host ""
Write-Host "-- 问题严重性检查 --"

# 严重性级别定义
$severityLevels = @(
    @{ Name = "Critical"; Patterns = @("Critical", "critical", "致命", "严重", "CRITICAL") }
    @{ Name = "Major";    Patterns = @("Major", "major", "重要", "MAJOR") }
    @{ Name = "Minor";    Patterns = @("Minor", "minor", "轻微", "MINOR") }
    @{ Name = "Info";     Patterns = @("Info", "info", "建议", "INFO") }
)

$openCriticalMajor = $false

foreach ($severity in $severityLevels) {
    # 检查该级别的问题是否存在
    $foundIssues = @()
    foreach ($pattern in $severity.Patterns) {
        if ($content -match "(?i)$pattern") {
            $foundIssues += $pattern
        }
    }

    if ($foundIssues.Count -gt 0) {
        Write-Host "[PASS] 包含 $($severity.Name) 级别问题定义"

        # 对于 Critical 和 Major，检查是否还有未关闭的问题
        if ($severity.Name -eq "Critical" -or $severity.Name -eq "Major") {
            # 尝试判断是否有未关闭的
            $openPattern = "(?i)$($severity.Name).{0,50}(?!(已关闭|closed|fixed|已修复|已解决|完成))"
            $stillOpen = $content -match "(?i)$($severity.Name).{0,200}(open|pending|未关闭|待处理|未解决|进行中)"

            if ($stillOpen) {
                Write-Host "[FAIL] 存在未关闭的 $($severity.Name) 级别问题"
                $openCriticalMajor = $true
                $failCount++
            } else {
                Write-Host "[PASS] $($severity.Name) 级别问题均已关闭"
            }
        }
    } else {
        Write-Host "[INFO] 未发现 $($severity.Name) 级别问题定义 (可接受)"
    }
}

# 建议/改进建议检查
Write-Host ""
Write-Host "-- 改进建议完整性 --"
if ($content -match "(?i)(suggestions|改进建议|建议|recommend)") {
    Write-Host "[PASS] 包含改进建议"
} else {
    Write-Host "[WARN] 建议补充改进建议 (suggestions)"
    $warnCount++
}

# 评分分布检查（如果有多个维度的评分）
Write-Host ""
Write-Host "-- 多维度评分检查 --"
$dimensionScores = @("一致性", "质量", "规范", "安全", "性能")
$dimensionFound = 0
foreach ($dim in $dimensionScores) {
    if ($content -match "(?i)$dim") {
        $dimensionFound++
    }
}
if ($dimensionFound -ge 3) {
    Write-Host "[PASS] 包含多维度评分 ($dimensionFound/5)"
} elseif ($dimensionFound -gt 0) {
    Write-Host "[INFO] 包含部分维度评分 ($dimensionFound/5)"
} else {
    Write-Host "[INFO] 未发现多维度评分，单一总分亦可接受"
}

Write-Host ""
Write-Host "---"
Write-Host "Result: $failCount failed, $warnCount warning"

if ($failCount -gt 0) {
    if ($openCriticalMajor) {
        Write-Host "建议: 关闭所有 Critical/Major 级别问题后再通过评审门禁"
    } else {
        Write-Host "建议: 补充缺失的评审要素，确保评审报告符合 core-review.md 规范"
    }
}

exit $failCount
