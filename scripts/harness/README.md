# Harness 可执行脚本规范

## 职责

将人工提醒的规则转化为可执行检查，让机器自动兜底。

## 目录用途

`scripts/harness/` 是 Harness Engineering 的自动化检查层。

## 脚本清单

| 脚本 | 状态 | 说明 |
|------|:----:|------|
| `run-checks.ps1` | ✅ v4.2 兼容 | 阶段转换前的强制检查点 |
| `validate-baton.ps1` | ✅ v4.2 兼容 | 校验 `.agent/harness/_baton.md` |
| `validate-artifact.ps1` | ✅ v4.2 兼容 | 校验 `.agent/harness/_*.md` 产物 |

> v4.x 核心校验使用 `run-checks.ps1`、`validate-baton.ps1`、`validate-artifact.ps1` 三个脚本。
> 其他 v3.3 遗留脚本（check-structure.ps1、check-plan.ps1、validate-entry-points.ps1、validate-intent-analysis.ps1、validate-verification.ps1、verify-review-gate.ps1）已移至 `legacy/scripts/` 作为历史参考，v4.x 流程中不再使用。

## 脚本命名规范

| 命名模式 | 用途 | 示例 |
|---------|------|------|
| `check-*.ps1` | 检查类脚本，返回通过/失败 | `run-checks.ps1` |
| `validate-*.ps1` | 验证类脚本，返回详细验证结果 | `validate-baton.ps1` |
| `sync-*.ps1` | 同步类脚本，执行数据同步操作 | `sync-landing-zones.ps1` |
| `report-*.ps1` | 报告类脚本，生成汇总报告 | `report-status.ps1` |

## 输出格式规范

所有脚本必须遵循统一的输出格式：

### 成功输出
```
[PASS] 检查项描述
[PASS] 检查项描述
---
Result: 0 failed, 0 warning
```

### 失败输出
```
[FAIL] 缺失文件: _baton.md
[WARN] 建议补充: docs/harness/
[PASS] 已存在: .agent/harness/
---
Result: 1 failed, 1 warning
```

## 退出码约定

| 退出码 | 含义 | 后续动作 |
|--------|------|---------|
| 0 | 全部通过 | 继续下一阶段 |
| 1-9 | N 项检查失败 | 阻断流程，根据策略处理 |
| 10+ | 严重错误 | 需人工介入 |
| 127 | 脚本依赖缺失 | 检查运行环境 |

## v4.1 核心脚本说明

### run-checks.ps1
阶段转换前的强制检查点。运行接力棒校验 + 前置产物检查 + 阶段跳跃检查。
```powershell
.\run-checks.ps1 -ProjectPath {项目路径} -Stage DESIGN
```

### validate-baton.ps1
校验 `.agent/harness/_baton.md` 格式是否完整。
```powershell
.\validate-baton.ps1 -ProjectPath {项目路径}
```

### validate-artifact.ps1
校验指定产物的格式完整性。
```powershell
.\validate-artifact.ps1 -ProjectPath {项目路径} -Artifact analysis
```

## CI 集成示例

### GitHub Actions
```yaml
name: Harness Check
on: [pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Harness Checks
        run: |
          pwsh -File scripts/harness/run-checks.ps1 -ProjectPath . -Stage VERIFY
```

## 跨平台说明

本目录提供 PowerShell (.ps1) 示例脚本，适用于 Windows 环境。

转换规则：
- `Write-Host` → `echo`
- `Test-Path` → `[ -f path ]`
- `exit $failCount` → `exit $failCount`

---

**版本**: 1.3.0
**更新时间**: 2026-05-21
**更新内容**: 移除 6 个 v3.3 遗留脚本（已移至 legacy/scripts/），精简脚本清单为 3 个 v4.x 核心脚本