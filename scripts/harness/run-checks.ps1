<#
.SYNOPSIS
  ReqPlan-v3 综合检查入口：阶段转换前的强制检查点
.DESCRIPTION
  在阶段转换前执行所有必要校验：
  1. 接力棒格式校验（validate-baton.ps1）
  2. 前置产物校验（validate-artifact.ps1）
  3. 阶段转换合法性检查
  任何单项检查失败都会阻断流程。
.EXAMPLE
  .\run-checks.ps1 -ProjectPath {项目路径} -Stage DESIGN
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [Parameter(Mandatory=$true)]
    [ValidateSet("START", "ANALYZE", "CONFIRM", "DESIGN", "IMPLEMENT", "VERIFY", "JUDGE", "DONE", "ABORT", "FAILED")]
    [string]$Stage
)

$ScriptDir = $PSScriptRoot

# 输出格式遵循 Harness 脚本规范
function Write-Pass($msg) { Write-Host "[PASS] $msg" }
function Write-Fail($msg) { Write-Host "[FAIL] $msg" }
function Write-Warn($msg) { Write-Host "[WARN] $msg" }
function Write-Error($msg) { Write-Host "[ERROR] $msg" }

Write-Host "========================================="
Write-Host "  ReqPlan-v3 阶段检查点: $Stage"
Write-Host "========================================="

$allPassed = $true

# 检查 1: 接力棒校验
Write-Host ""
Write-Host ">>> [接力棒校验] validate-baton.ps1"
Write-Host "-----------------------------------------"
$batonScript = Join-Path $ScriptDir "validate-baton.ps1"
if (Test-Path $batonScript) {
    & $batonScript -ProjectPath $ProjectPath
    if ($LASTEXITCODE -ne 0) {
        $allPassed = $false
    }
} else {
    Write-Fail "接力棒校验脚本不存在: $batonScript"
    $allPassed = $false
}

# 检查 2: 前置产物检查（根据阶段）
Write-Host ""
Write-Host ">>> [前置产物检查] validate-artifact.ps1"
Write-Host "-----------------------------------------"

$requiredArtifacts = @{}
switch ($Stage) {
    "ANALYZE" {
        Write-Pass "ANALYZE 阶段不需要前置产物"
    }
    "CONFIRM" {
        $requiredArtifacts["analysis"] = "_analysis.md"
    }
    "DESIGN" {
        $requiredArtifacts["analysis"] = "_analysis.md"
    }
    "IMPLEMENT" {
        $requiredArtifacts["design"] = "_design.md"
    }
    "VERIFY" {
        $requiredArtifacts["design"] = "_design.md"
        $requiredArtifacts["implementation"] = "_implementation.md"
    }
    "JUDGE" {
        $requiredArtifacts["verification"] = "_verification.md"
    }
}

foreach ($artifactType in $requiredArtifacts.Keys) {
    $artifactFile = $requiredArtifacts[$artifactType]
    $artifactPath = Join-Path $ProjectPath ".agent/harness/$artifactFile"

    if (Test-Path $artifactPath) {
        Write-Pass "前置产物存在: $artifactFile"

        # 进一步校验产物格式
        $artifactScript = Join-Path $ScriptDir "validate-artifact.ps1"
        if (Test-Path $artifactScript) {
            & $artifactScript -ProjectPath $ProjectPath -Artifact $artifactType
            if ($LASTEXITCODE -ne 0) {
                $allPassed = $false
            }
        }
    } else {
        Write-Fail "前置产物缺失: $artifactFile"
        Write-Error "必须先完成 $($artifactType.ToUpper()) 阶段"
        $allPassed = $false
    }
}

# 检查 3: 阶段跳跃检查
Write-Host ""
Write-Host ">>> [阶段转换合法性检查]"
Write-Host "-----------------------------------------"

$BatonPath = Join-Path $ProjectPath ".agent/harness/_baton.md"
if (Test-Path $BatonPath) {
    $batonContent = Get-Content $BatonPath -Raw
    $stateMatch = [regex]::Match($batonContent, "当前状态\s*[:|]\s*(\w+)")

    if ($stateMatch.Success) {
        $currentState = $stateMatch.Groups[1].Value.Trim()

        # 定义合法的阶段转换
        $validTransitions = @{
            "START" = @("ANALYZE")
            "ANALYZE" = @("CONFIRM")
            "CONFIRM" = @("DESIGN", "ANALYZE", "ABORT")
            "DESIGN" = @("IMPLEMENT")
            "IMPLEMENT" = @("VERIFY")
            "VERIFY" = @("JUDGE")
            "JUDGE" = @("DONE", "DESIGN", "IMPLEMENT", "FAILED")
        }

        if ($validTransitions.ContainsKey($currentState)) {
            $allowedNext = $validTransitions[$currentState]
            if ($allowedNext -contains $Stage) {
                Write-Pass "阶段转换合法: $currentState → $Stage"
            } else {
                Write-Fail "阶段转换非法: $currentState → $Stage"
                Write-Error "从 $currentState 只能进入: $($allowedNext -join ', ')"
                $allPassed = $false
            }
        } else {
            Write-Fail "未知当前状态: $currentState"
            $allPassed = $false
        }
    }
}

# 最终判定
Write-Host ""
Write-Host "========================================="
Write-Host "  检查点判定"
Write-Host "========================================="

if ($allPassed) {
    Write-Pass "所有检查通过，可以进入 $Stage 阶段"
    Write-Host "========================================="
    exit 0
} else {
    Write-Fail "检查未通过，禁止进入 $Stage 阶段"
    Write-Error "请修复上述错误后重试"
    Write-Host "========================================="
    exit 1
}
