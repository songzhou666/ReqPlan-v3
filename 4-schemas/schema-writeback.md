# Writeback Schema (v3.1)

## 概述

定义结果回写机制，明确 ReqPlan 每个阶段的产出应该写回到项目的哪个位置。

**核心原则**：
- 验证摘要、评审结论、剩余风险不能只存在于一次对话中
- 回写位置固定，Agent 和工程师都能找到
- 回写格式统一，便于后续复用

## 回写目标总览

```yaml
writeback_targets:
  repository:
    docs:
      - type: "需求文档"
        destination: "docs/req/{{taskId}}.md"
        format: "markdown"
        content: ["需求描述", "验收标准", "范围约束"]
      - type: "设计文档"
        destination: "docs/design/{{taskId}}.md"
        format: "markdown"
        content: ["架构设计", "接口定义", "数据结构"]
      - type: "计划文档"
        destination: ".agent/plans/plan-{{taskId}}.md"
        format: "markdown"
        content: ["Scope/Non-Goals", "Validation/Rollback", "实现路径"]
      - type: "验证摘要"
        destination: "docs/test/verify-{{taskId}}.md"
        format: "markdown"
        content: ["验证结果", "剩余风险", "后续事项"]
      - type: "评审报告"
        destination: "docs/harness/review-{{taskId}}.md"
        format: "markdown"
        content: ["评审结论", "问题列表", "改进建议"]

    harness_files:
      - type: "入口地图更新"
        destination: "AGENTS.md"
        format: "markdown"
        condition: "新增验证命令或项目结构变更时"
      - type: "项目约束更新"
        destination: "docs/harness/project-constraints.md"
        format: "markdown"
        condition: "发现新的项目级约束时"
      - type: "控制面更新"
        destination: "docs/harness/control-plane.md"
        format: "markdown"
        condition: "任务推进方式变更时"

  task_system:
    - type: "任务状态"
      destination: "项目任务系统（Linear/JIRA/其他）"
      format: "标题/描述/状态/责任人"
      fields:
        - "任务状态：进行中 / 待评审 / 已完成"
        - "反馈摘要：主要结论和风险"
        - "下一步：后续操作建议"

  pr_mr:
    - type: "PR/MR 描述"
      destination: "代码托管平台（GitHub/GitLab）"
      format: "markdown"
      sections:
        - "变更说明：本次改动的目标和范围"
        - "验证结果：已通过的验证层级"
        - "风险说明：已知风险和处理方式"
        - "回滚方式：失败时如何恢复"
```

## 流程回写映射

```yaml
flow_writeback_mapping:
  full_project:
    - step: "需求分析"
      writeback:
        - target: "docs/req/req-{{taskId}}.md"
        - target: "任务系统（创建任务）"
    - step: "规划阶段"
      writeback:
        - target: ".agent/plans/plan-full-{{taskId}}.md"
    - step: "开发实现"
      writeback:
        - target: "PR/MR（提交代码变更）"
    - step: "验收测试"
      writeback:
        - target: "docs/test/verify-{{taskId}}.md"
    - step: "交付收口"
      writeback:
        - target: "AGENTS.md（更新验证命令）"
        - target: "任务系统（更新状态）"
        - target: "docs/harness/project-constraints.md（如有新增约束）"

  iteration:
    - step: "迭代计划"
      writeback:
        - target: ".agent/plans/plan-iteration-{{taskId}}.md"
    - step: "迭代开发"
      writeback:
        - target: "PR/MR"
    - step: "迭代验收"
      writeback:
        - target: "docs/test/verify-{{taskId}}.md"
    - step: "收口"
      writeback:
        - target: "任务系统（更新状态）"

  design_review:
    - step: "设计审查"
      writeback:
        - target: "docs/harness/review-design-{{taskId}}.md"
    - step: "结论记录"
      writeback:
        - target: "任务系统（反馈评审结论）"

  audit:
    - step: "审计扫描"
      writeback:
        - target: "docs/harness/audit-{{taskId}}.md"
    - step: "报告输出"
      writeback:
        - target: "docs/harness/audit-report-{{taskId}}.md"
        - target: "docs/harness/project-constraints.md（如有新增规则）"

  testing:
    - step: "测试执行"
      writeback:
        - target: "docs/test/results-{{taskId}}.md"
    - step: "报告输出"
      writeback:
        - target: "docs/test/report-{{taskId}}.md"
        - target: "docs/harness/project-constraints.md"

  docs:
    - step: "文档编写"
      writeback:
        - target: "docs/（各文档目录）"
    - step: "发布确认"
      writeback:
        - target: "AGENTS.md（更新文档入口）"

  refactor:
    - step: "重构实施"
      writeback:
        - target: "PR/MR"
    - step: "回归验证"
      writeback:
        - target: "docs/test/regression-{{taskId}}.md"
    - step: "收口确认"
      writeback:
        - target: "AGENTS.md（更新结构说明）"
        - target: "docs/harness/project-constraints.md"
        - target: "任务系统（更新状态）"
```

## 回写格式规范

### 验证摘要模板

```markdown
# 验证摘要 - {{taskId}}

## 验证结果总览

- **整体状态**：{{overallStatus}}（pass / warning / fail）
- **已验证层级**：{{verifiedLayers}}
- **验证时间**：{{timestamp}}

## 逐层验证结果

| 层级 | 状态 | 说明 |
|------|------|------|
{{#each layerResults}}
| Layer {{layer}} | {{status}} | {{summary}} |
{{/each}}

## 剩余风险

{{#each remainingRisks}}
- **风险**：{{risk}}
- **影响**：{{impact}}
- **处理计划**：{{plan}}
{{/each}}

## 后续事项

{{#each nextSteps}}
- [ ] {{action}}（责任人：{{owner}}）
{{/each}}
```

### PR/MR 描述模板

```markdown
## 变更说明

{{changeDescription}}

## 验证结果

- **静态检查**：{{staticCheckResult}}
- **单元验证**：{{unitTestResult}}
- **链路验证**：{{integrationResult}}
- **失败验证**：{{failureResult}}

## 风险说明

{{#each risks}}
- {{risk}}
{{/each}}

## 回滚方式

{{rollbackMethod}}
```

### 评审报告模板

```markdown
# 评审报告 - {{taskId}}

## 基本信息

- **评审类型**：{{reviewType}}（设计/代码/文档）
- **评审范围**：{{scope}}
- **评审人**：{{reviewer}}

## 评审结论

{{conclusion}}

## 发现的问题

| 严重级别 | 问题描述 | 建议修复方式 |
|---------|---------|-------------|
{{#each issues}}
| {{severity}} | {{description}} | {{fixSuggestion}} |
{{/each}}

## 改进建议

{{#each improvements}}
- {{suggestion}}
{{/each}}
```

## 回写验证规则

```yaml
writeback_validation:
  - rule: "验证摘要必须包含验证结果、剩余风险和后续事项"
    severity: "error"
  - rule: "PR/MR 描述必须包含变更说明、验证结果和回滚方式"
    severity: "warning"
  - rule: "评审报告必须包含评审结论和问题列表"
    severity: "error"
  - rule: "任务状态更新必须包含状态变化和反馈摘要"
    severity: "info"
```

## 版本信息

**版本**: 3.2.0
**更新时间**: 2026-05-14
**引用**: 3-core/core-verification.md, 7-flows/ 下所有流程文件, 5-templates/ 下所有模板
