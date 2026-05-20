# ReqPlan-v3 接力棒校验脚本
# 用途：验证接力棒格式和状态是否合法
# 调用方式：validate-baton.ps1 -ProjectPath <路径>
# 位置：scripts/harness/validate-baton.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$BatonPath = Join-Path $ProjectPath ".agent/harness/_baton.md"

# 输出格式遵循 Harness 脚本规范
# [PASS] / [FAIL] / [WARN] / [ERROR]

function Write-Pass($msg) { Write-Host "[PASS] $msg" }
function Write-Fail($msg) { Write-Host "[FAIL] $msg" }
function Write-Warn($msg) { Write-Host "[WARN] $msg" }
function Write-Error($msg) { Write-Host "[ERROR] $msg" }

# 检查接力棒是否存在
if (-not (Test-Path $BatonPath)) {
    Write-Fail "接力棒不存在: $BatonPath"
    Write-Error "请先执行 /reqplan init 初始化"
    exit 10
}

Write-Pass "接力棒文件存在"

# 读取接力棒内容
$content = Get-Content $BatonPath -Raw

# 检查必需字段
$requiredFields = @(
    "当前状态",
    "模式",
    "重试计数",
    "design_fix_retry"
)

$missingFields = @()
foreach ($field in $requiredFields) {
    if ($content -notmatch $field) {
        $missingFields += $field
    }
}

if ($missingFields.Count -gt 0) {
    Write-Fail "接力棒缺少必需字段: $($missingFields -join ', ')"
    exit 1
}

Write-Pass "接力棒包含所有必需字段"

# 检查状态值是否合法
$validStates = @("START", "ANALYZE", "CONFIRM", "DESIGN", "IMPLEMENT", "VERIFY", "JUDGE", "DONE", "ABORT", "FAILED")
$stateMatch = [regex]::Match($content, "当前状态\s*[:|]\s*(\w+)")

if ($stateMatch.Success) {
    $currentState = $stateMatch.Groups[1].Value.Trim()
    if ($validStates -contains $currentState) {
        Write-Pass "当前状态合法: $currentState"
    } else {
        Write-Fail "当前状态不合法: $currentState"
        Write-Error "合法状态: $($validStates -join ', ')"
        exit 1
    }
} else {
    Write-Fail "无法解析当前状态"
    exit 1
}

# 检查模式值是否合法
$validModes = @("NORMAL", "DESIGN_FIX", "REVIEW_FIX", "RETRY_FIX")
$modeMatch = [regex]::Match($content, "模式\s*[:|]\s*(\w+)")

if ($modeMatch.Success) {
    $currentMode = $modeMatch.Groups[1].Value.Trim()
    if ($validModes -contains $currentMode) {
        Write-Pass "当前模式合法: $currentMode"
    } else {
        Write-Fail "当前模式不合法: $currentMode"
        Write-Error "合法模式: $($validModes -join ', ')"
        exit 1
    }
}

# 检查重试计数是否在范围内
$retryMatch = [regex]::Match($content, "重试计数\s*[:|]\s*(\d+)")
if ($retryMatch.Success) {
    $retryCount = [int]$retryMatch.Groups[1].Value
    if ($retryCount -ge 0 -and $retryCount -le 2) {
        Write-Pass "重试计数合法: $retryCount"
    } else {
        Write-Fail "重试计数超出范围: $retryCount (应为 0-2)"
        exit 1
    }
}

# 检查 design_fix_retry 是否在范围内
$designFixMatch = [regex]::Match($content, "design_fix_retry\s*[:|]\s*(\d+)")
if ($designFixMatch.Success) {
    $designFixCount = [int]$designFixMatch.Groups[1].Value
    if ($designFixCount -ge 0 -and $designFixCount -le 2) {
        Write-Pass "design_fix_retry 合法: $designFixCount"
    } else {
        Write-Fail "design_fix_retry 超出范围: $designFixCount (应为 0-2)"
        exit 1
    }
}

Write-Host "---"
Write-Host "Result: 0 failed, 0 warning"
exit 0
