# Landing Zone Schema (v3.1)

## 概述

定义信息落点规范（Landing Zone），明确 ReqPlan 各类产出应放置在项目中的固定位置。

**核心原则**：每类信息都有固定的落点位置，Agent 和工程师都能沿同一套路径找到依据、边界、验证和结果记录。

## 信息落点总览

```yaml
landing_zones:
  entry_map:
    type: "AGENTS.md"
    purpose: "项目入口地图。告诉Agent和工程师项目是什么、入口在哪、验证命令是什么"
    location: "项目根目录"
    responsibility: "导航和边界说明"
    generated_by: "reqplan init"

  plan_protocol:
    type: ".agent/PLANS.md"
    purpose: "复杂任务的计划协议。定义计划编写规范、Scope/Non-Goals/Validation/Rollback要求"
    location: ".agent/"
    responsibility: "约束复杂任务的计划编写"
    generated_by: "reqplan init"

  plan_files:
    type: ".agent/plans/"
    purpose: "具体的计划文档存放位置"
    location: ".agent/plans/"
    responsibility: "存放每次复杂任务的计划文件"
    generated_by: "reqplan plan"

  control_plane:
    type: "docs/harness/control-plane.md"
    purpose: "说明任务如何收集、冻结、切分、实现、验证、评审和回写"
    location: "docs/harness/"
    responsibility: "控制面说明"
    generated_by: "reqplan init"

  constraints:
    type: "docs/harness/project-constraints.md"
    purpose: "登记项目级规则和检查状态，区分文档说明、命令检查和CI gate"
    location: "docs/harness/"
    responsibility: "项目约束登记和升级跟踪"
    generated_by: "reqplan init"

  test_verification:
    type: "docs/test/"
    purpose: "测试runbook、验证摘要、脱敏结果"
    location: "docs/test/"
    responsibility: "复用验证步骤、记录副作用和结果"
    generated_by: "reqplan verify"

  harness_scripts:
    type: "scripts/harness/"
    purpose: "结构检查、计划检查、review gate等可执行脚本"
    location: "scripts/harness/"
    responsibility: "将规则逐步从提醒升级为可执行检查"
    generated_by: "reqplan init"

  agent_prompts:
    type: ".agent/prompts/"
    purpose: "标准prompt、维护循环、review口径、linter接入建议"
    location: ".agent/prompts/"
    responsibility: "Agent行为标准和约束"
    generated_by: "reqplan init"

  agent_guides:
    type: ".agent/guides/"
    purpose: "Agent行为指导、review标准"
    location: ".agent/guides/"
    responsibility: "Agent行为规范"
    generated_by: "reqplan init"

  pr_mr:
    type: "PR/MR描述"
    purpose: "变更记录、评审讨论、CI结果、合并和留痕"
    location: "代码托管平台（GitHub/GitLab等）"
    responsibility: "承接diff、review、CI、讨论、合并和留痕"
    generated_by: "reqplan"

  snapshots:
    type: ".trae/reqplan/snapshots/"
    purpose: "状态快照，用于上下文恢复和历史追溯"
    location: ".trae/reqplan/snapshots/"
    responsibility: "状态追溯和回滚"
    generated_by: "reqplan snapshot"

  state_file:
    type: "state.yaml"
    purpose: "全局状态文件，记录项目阶段、进度、任务、里程碑"
    location: ".trae/reqplan/"
    responsibility: "全局状态管理"
    generated_by: "reqplan start/init"
```

## 落点分类说明

### 按信息类型分类

```yaml
classification:
  task_info:
    - "任务系统（目标/范围/状态/责任/反馈）"
    landing_zones: ["plan_protocol", "plan_files"]

  repository_info:
    - "设计依据、计划、验证入口、项目约束、结果记录"
    landing_zones: ["entry_map", "control_plane", "constraints", "test_verification", "harness_scripts"]

  pr_mr_info:
    - "代码变更、评审讨论、CI结果、合并和留痕"
    landing_zones: ["pr_mr"]

  agent_tools:
    - "搜索、修改、执行、验证和回写"
    landing_zones: ["agent_prompts", "agent_guides"]
```

### 按使用时机分类

```yaml
usage_timing:
  agent_entry:
    - "Agent进入项目时读取"
    files: ["AGENTS.md", "docs/harness/control-plane.md", "docs/harness/project-constraints.md"]

  complex_task:
    - "复杂任务启动时使用"
    files: [".agent/PLANS.md", ".agent/plans/"]

  execution:
    - "执行过程中输出"
    files: [".agent/plans/", "docs/test/"]

  verification:
    - "验证时使用"
    files: ["scripts/harness/", "docs/test/"]

  writeback:
    - "收口时回写"
    files: ["PR/MR", "任务系统", "docs/"]
```

## 落点验证规则

```yaml
validation_rules:
  - rule: "每个落点必须包含 purpose 和 location"
    severity: "error"
  - rule: "AGENTS.md 必须位于项目根目录"
    severity: "error"
  - rule: ".agent/ 目录必须包含 PLANS.md"
    severity: "warning"
  - rule: "docs/harness/ 目录应包含 control-plane.md 和 project-constraints.md"
    severity: "warning"
  - rule: "scripts/harness/ 目录文件应为可执行脚本"
    severity: "info"
```

## 与 ReqPlan 流程的映射

```yaml
flow_landing_mapping:
  full_project:
    - step: "需求分析"
      outputs: ["docs/req.md"]
      landing_zone: "docs/"
    - step: "规划阶段"
      outputs: [".agent/plans/plan-full.md"]
      landing_zone: "plan_files"
    - step: "验收"
      outputs: ["docs/test/verify-summary.md"]
      landing_zone: "test_verification"

  design_review:
    - step: "设计评审"
      outputs: ["docs/harness/design-review-report.md"]
      landing_zone: "docs/harness/"

  audit:
    - step: "代码审计"
      outputs: ["docs/harness/audit-report.md"]
      landing_zone: "docs/harness/"
```

---

**Schema版本**: 3.2.0
**更新时间**: 2026-05-14
**引用**: 3-core/core-file-sync.md, 7-flows/ 下所有流程文件
