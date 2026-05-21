<#
.SYNOPSIS
  检查最新计划文件是否包含实现路径格式的必需章节
.DESCRIPTION
  读取 .agent/plans/ 中最新的计划文件，验证其是否包含：
  - 范围冻结四要素（Scope/Non-Goals/Validation/Rollback）
  - 实现路径核心章节（Entry Points/组件职责/验证命令/回写目标）
  对应 Task Pipeline Stage 2 门控：计划格式完整合规。
  注意：本脚本检查的是 v3.3 的 .agent/plans/ 路径，v4.x 已改用 .agent/harness/_design.md
.EXAMPLE
  .\check-plan.ps1
  输出计划文件各章节的检查状态和最终结果。
#>

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$plansDir = Join-Path $projectRoot ".agent\plans"

Write-Host "=== 计划文件格式检查 (v3.3 遗留) ==="
Write-Host ""

# 查找最新的计划文件
if (-not (Test-Path $plansDir -PathType Container)) {
    Write-Host "[ERROR] 计划目录不存在: $plansDir"
    Write-Host "---"
    Write-Host "Result: 1 error"
    exit 10
}

$latestPlan = Get-ChildItem -Path $plansDir -Filter "*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $latestPlan) {
    Write-Host "[INFO] 暂无计划文件，跳过检查"
    Write-Host "---"
    Write-Host "Result: 0 failed"
    exit 0
}

Write-Host "检查文件: $($latestPlan.Name)"
Write-Host "修改时间: $($latestPlan.LastWriteTime)"
Write-Host ""

$planContent = Get-Content $latestPlan.FullName -Raw
$failCount = 0

# 定义必需章节和对应的检查模式
$requiredSections = @(
    @{ Name = "本轮目标(Scope)"; Patterns = @("本轮目标", "Scope") }
    @{ Name = "明确不做的(Non-Goals)"; Patterns = @("明确不做的", "Non-Goals") }
    @{ Name = "验收口径(Validation)"; Patterns = @("验收口径", "Validation") }
    @{ Name = "失败回滚策略(Rollback)"; Patterns = @("回滚策略", "Rollback") }
    @{ Name = "真实入口(Entry Points)"; Patterns = @("真实入口", "Entry Points") }
    @{ Name = "组件职责(Component Responsibilities)"; Patterns = @("组件职责", "Component Responsibilities") }
    @{ Name = "关键时序(Key Sequence)"; Patterns = @("关键时序", "Key Sequence") }
    @{ Name = "失败处理策略(Failure Strategy)"; Patterns = @("失败处理策略", "Failure Strategy") }
    @{ Name = "验证命令(Verification Commands)"; Patterns = @("验证命令", "Verification Commands") }
    @{ Name = "回写目标(Writeback Targets)"; Patterns = @("回写目标", "Writeback Targets") }
)

foreach ($section in $requiredSections) {
    $found = $false
    foreach ($pattern in $section.Patterns) {
        if ($planContent -match $pattern) {
            $found = $true
            break
        }
    }
    if ($found) {
        Write-Host "[PASS] 包含: $($section.Name)"
    } else {
        Write-Host "[FAIL] 缺失: $($section.Name)"
        $failCount++
    }
}

# 额外检查：新模板特有的章节
$advancedSections = @(
    @{ Name = "决策日志(Decision Log)"; Pattern = "决策日志" }
    @{ Name = "管道状态映射(Pipeline State)"; Pattern = "管道状态映射" }
    @{ Name = "信息落点(Landing Zones)"; Pattern = "信息落点" }
)

Write-Host ""
Write-Host "--- 可选章节检查 ---"

foreach ($section in $advancedSections) {
    if ($planContent -match $section.Pattern) {
        Write-Host "[PASS] 包含: $($section.Name)"
    } else {
        Write-Host "[WARN] 未包含: $($section.Name)"
    }
}

Write-Host ""
Write-Host "---"
if ($failCount -eq 0) {
    Write-Host "Result: 0 failed - 计划格式完整合规"
} else {
    Write-Host "Result: $failCount failed - 计划格式不完整"
    Write-Host "建议: 使用 template-plan.md(v3.2) 重新生成计划"
}

exit $failCount
