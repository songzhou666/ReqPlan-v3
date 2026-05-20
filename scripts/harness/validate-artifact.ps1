# ReqPlan-v3 产物校验脚本
# 用途：验证各阶段产物是否符合模板要求
# 调用方式：validate-artifact.ps1 -ProjectPath <路径> -Artifact <analysis|design|implementation|verification>
# 位置：scripts/harness/validate-artifact.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [Parameter(Mandatory=$true)]
    [ValidateSet("analysis", "design", "implementation", "verification")]
    [string]$Artifact
)

$ArtifactPath = Join-Path $ProjectPath ".agent/harness/_${Artifact}.md"

# 输出格式遵循 Harness 脚本规范
function Write-Pass($msg) { Write-Host "[PASS] $msg" }
function Write-Fail($msg) { Write-Host "[FAIL] $msg" }
function Write-Warn($msg) { Write-Host "[WARN] $msg" }
function Write-Error($msg) { Write-Host "[ERROR] $msg" }

# 检查产物是否存在
if (-not (Test-Path $ArtifactPath)) {
    Write-Fail "产物不存在: $ArtifactPath"
    exit 1
}

Write-Pass "产物文件存在: _${Artifact}.md"

# 读取产物内容
$content = Get-Content $ArtifactPath -Raw

# 根据产物类型定义检查规则
$requiredSections = @{}
$requiredTitle = ""

switch ($Artifact) {
    "analysis" {
        $requiredTitle = "需求分析报告"
        $requiredSections = @{
            "基本信息" = $true
            "需求理解" = $true
            "技术栈" = $true
            "涉及文件" = $true
            "约束条件" = $true
        }
    }
    "design" {
        $requiredTitle = "技术设计文档"
        $requiredSections = @{
            "技术方案概述" = $true
            "模块划分" = $true
            "任务列表" = $true
            "验证方案" = $true
        }
    }
    "implementation" {
        $requiredTitle = "实现摘要"
        $requiredSections = @{
            "基本信息" = $true
            "完成的任务" = $true
            "涉及的文件" = $true
        }
    }
    "verification" {
        $requiredTitle = "验证报告"
        $requiredSections = @{
            "Layer 1" = $true
            "Layer 2" = $true
            "Layer 3" = $true
            "Layer 4" = $true
            "Layer 5" = $true
            "综合判定" = $true
        }
    }
}

# 检查标题
if ($content -match "#\s+${requiredTitle}") {
    Write-Pass "标题正确: ${requiredTitle}"
} else {
    Write-Fail "标题不正确或缺失"
    Write-Error "期望标题: # ${requiredTitle}"
    exit 1
}

# 检查必需章节
$missingSections = @()
foreach ($section in $requiredSections.Keys) {
    $pattern = "#{2,3}\s+.*${section}"
    if ($content -notmatch $pattern) {
        $missingSections += $section
    }
}

if ($missingSections.Count -gt 0) {
    Write-Fail "产物缺少必需章节: $($missingSections -join ', ')"
    exit 1
}

Write-Pass "产物包含所有必需章节"

# 特殊检查：验证报告必须有明确的 PASS/FAIL
if ($Artifact -eq "verification") {
    if ($content -match "PASS|FAIL") {
        Write-Pass "验证报告包含明确的 PASS/FAIL 判定"
    } else {
        Write-Fail "验证报告缺少明确的 PASS/FAIL 判定"
        exit 1
    }
}

# 特殊检查：设计文档的任务列表必须有涉及文件和验证方式
if ($Artifact -eq "design") {
    $taskListMatch = [regex]::Match($content, "##\s+任务列表(.*?)##", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($taskListMatch.Success) {
        $taskListContent = $taskListMatch.Groups[1].Value

        # 检查是否有"涉及文件"列
        if ($taskListContent -match "涉及文件") {
            Write-Pass "任务列表包含'涉及文件'列"
        } else {
            Write-Fail "任务列表缺少'涉及文件'列"
            exit 1
        }

        # 检查是否有"验证方式"列
        if ($taskListContent -match "验证方式") {
            Write-Pass "任务列表包含'验证方式'列"
        } else {
            Write-Fail "任务列表缺少'验证方式'列"
            exit 1
        }
    }
}

Write-Host "---"
Write-Host "Result: 0 failed, 0 warning"
exit 0
