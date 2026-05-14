# Harness 可执行脚本规范

## 职责

将人工提醒的规则转化为可执行检查，让机器自动兜底。

## 目录用途

`scripts/harness/` 是 Harness Engineering 的自动化检查层。所有在此目录下的脚本应：

1. **可重复执行**：多次运行结果一致
2. **自包含**：不依赖外部配置文件（读取 landing zone 标准位置除外）
3. **结构化输出**：输出格式统一，可被 Agent 和 CI 系统解析
4. **退出码语义化**：0=通过，N=失败项数量

## 脚本命名规范

| 命名模式 | 用途 | 示例 |
|---------|------|------|
| `check-*.ps1` | 检查类脚本，返回通过/失败 | `check-structure.ps1` |
| `validate-*.ps1` | 验证类脚本，返回详细验证结果 | `validate-entry-points.ps1` |
| `sync-*.ps1` | 同步类脚本，执行数据同步操作 | `sync-landing-zones.ps1` |
| `report-*.ps1` | 报告类脚本，生成汇总报告 | `report-status.ps1` |

## 输出格式规范

所有脚本必须遵循统一的输出格式，确保 Agent 和 CI 均可解析：

### 成功输出
```
[PASS] 检查项描述
[PASS] 检查项描述
---
Result: 0 failed, 0 warning
```

### 失败输出
```
[FAIL] 缺失文件: AGENTS.md
[WARN] 建议补充: .agent/guides/
[PASS] 已存在: .agent/PLANS.md
---
Result: 1 failed, 1 warning
```

### 错误输出
```
[ERROR] 无法读取计划文件: .agent/plans/plan-001.md
---
Result: 1 error
```

## 退出码约定

| 退出码 | 含义 | 后续动作 |
|--------|------|---------|
| 0 | 全部通过 | 继续下一阶段 |
| 1-9 | N 项检查失败 | 记录到 decision_log，根据策略处理 |
| 10+ | 严重错误（无法读取输入等） | 阻塞流程，需人工介入 |
| 127 | 脚本依赖缺失 | 检查运行环境 |

## 标准检查清单

以下脚本按执行时机排列：

| 脚本 | 执行时机 | 检查内容 |
|------|---------|---------|
| `check-structure.ps1` | 任务入口/初始化后 | Harness 目录结构完整性 |
| `check-plan.ps1` | 计划冻结后 | 计划文件格式合规性 |
| `validate-entry-points.ps1` | 计划冻结后 | 计划中入口点的有效性 |
| `validate-intent-analysis.ps1` | 意图分析完成后 | 意图分析产出物必含字段完整性 |
| `validate-verification.ps1` | 验证评估完成后 | 5层验证全覆盖检查 |
| `verify-review-gate.ps1` | 评审完成后/收口前 | 评审门禁条件（无未关闭的Critical/Major问题） |
| `run-checks.ps1` | 任务收口前（综合检查） | 依次运行所有 check-* 和 validate-* 脚本 |

### 执行建议

- **每个 Action 完成后** → 运行对应的 validate-* 脚本验证产出物
- **任务收口前** → 运行 `run-checks.ps1` 执行全量检查
- **仅当你需要确认当前状态时** → 运行单项脚本（如 `validate-verification.ps1`）
- 校验失败后，请修正问题再进入下一阶段，不要带着未验证的产出物前进

## 跨平台说明

本目录提供 PowerShell (.ps1) 示例脚本，适用于 Windows 环境。
对于 Linux/macOS 项目，应提供对应的 Bash (.sh) 版本。

转换规则：
- `Write-Host` → `echo`
- `Test-Path` → `[ -f path ]`
- `Get-ChildItem` → `ls`
- `Select-String` → `grep`
- `exit $failCount` → `exit $failCount`

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
          pwsh -File scripts/harness/check-structure.ps1
          pwsh -File scripts/harness/check-plan.ps1
```

### GitLab CI
```yaml
harness-check:
  stage: test
  script:
    - pwsh -File scripts/harness/check-structure.ps1
    - pwsh -File scripts/harness/check-plan.ps1
```

## 与管道模型的集成

每个脚本对应 Task Pipeline 的特定阶段门控：

| 脚本 | 管道阶段 | 门控条件 |
|------|---------|---------|
| `check-structure.ps1` | Stage 1 入口 | 确认 landing zone 就绪 |
| `check-plan.ps1` | Stage 2 冻结 | 计划格式完整合规 |
| `validate-entry-points.ps1` | Stage 2 冻结 | 入口点真实可触达 |
| `validate-intent-analysis.ps1` | Stage 2 冻结 | 意图分析产出物格式完整 |
| `validate-verification.ps1` | Stage 4 验证 | 5层验证全覆盖 |
| `verify-review-gate.ps1` | Stage 4→5 过渡 | 评审门禁通过 |
| `run-checks.ps1` | Stage 5 回写前 | 全量检查通过 |

## 添加新脚本的步骤

1. 确定脚本类型（check/validate/sync/report）
2. 按命名规范命名文件
3. 实现功能，遵守输出格式规范
4. 在 README.md 的标准检查清单中添加条目
5. **将新脚本同时注册到 run-checks.ps1 的综合检查套件中**

---

**版本**: 1.1.0
**更新时间**: 2026-05-14
**更新内容**: 新增3个validate-*脚本 + 执行建议 + 管道集成扩展
**引用**: schema-landing-zone.md, adoption-guide.md, core-task-pipeline.md
