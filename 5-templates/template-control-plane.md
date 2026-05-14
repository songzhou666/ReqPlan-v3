---
template:
  name: template-control-plane
  version: "3.1"
  type: control-plane
  usage: 用于定义项目的协作协议（Control Plane），包括任务收集、切分、验证和回写规则
---

# Control Plane 模板

## 概述

控制面文档（Control Plane）说明在当前项目中，任务如何收集、冻结、切分、实现、验证、评审和回写。

**核心目标**：让 Agent 和工程师理解当前项目的协作协议，不需要每次从头沟通。

## 模板内容

```markdown
# 控制面文档 - {{projectName}}

## 1. 任务入口

### 1.1 任务来源

{{#each taskSources}}
- **{{source}}**：{{description}}
{{/each}}

### 1.2 任务规范

- **任务标题格式**：{{titleFormat}}
- **任务描述要求**：{{descriptionRequirements}}
- **优先级定义**：{{priorityDefinition}}

## 2. 范围冻结（Scope Freeze）

### 2.1 何时需要写计划

{{planTriggerCondition}}

### 2.2 计划必须包含的内容

- **Scope（目标）**：本次任务要做什么
- **Non-Goals（不做什么）**：明确不包含的范围
- **Validation（验收条件）**：如何判断完成
- **Rollback（回滚方式）**：失败时如何恢复

### 2.3 计划存放位置

```
.agent/plans/plan-{{taskId}}.md
```

## 3. 任务切分

### 3.1 切分原则

{{#each splittingPrinciples}}
- {{this}}
{{/each}}

### 3.2 任务粒度

{{taskGranularityGuide}}

## 4. 实现规范

### 4.1 实现前

- {{beforeImplementationRules}}

### 4.2 实现中

- {{duringImplementationRules}}

### 4.3 实现后

- {{afterImplementationRules}}

## 5. 验证规范

### 5.1 验证层级

本项目的验证采用 5 层验证金字塔：

| 层级 | 名称 | 说明 |
|------|------|------|
| Layer 1 | 静态检查 | lint、类型检查、格式 |
| Layer 2 | 单元验证 | 单测、边界条件 |
| Layer 3 | 链路验证 | 入口→处理→输出 |
| Layer 4 | 失败验证 | 异常、超时、回滚 |
| Layer 5 | 回写验证 | 结果同步到文档/任务 |

### 5.2 验证命令

| 验证类型 | 命令 | 说明 |
|---------|------|------|
{{#each verificationCommands}}
| {{type}} | `{{command}}` | {{description}} |
{{/each}}

### 5.3 验证摘要存放位置

```
docs/test/verify-{{taskId}}.md
```

## 6. 评审规范

### 6.1 评审类型

{{#each reviewTypes}}
- **{{type}}**：{{description}}
  - 触发条件：{{trigger}}
  - 评审人：{{reviewer}}
{{/each}}

### 6.2 评审标准

| 维度 | 标准 |
|------|------|
{{#each reviewCriteria}}
| {{dimension}} | {{standard}} |
{{/each}}

## 7. 回写规范

### 7.1 回写目标

| 产出物 | 落点位置 | 条件 |
|-------|---------|------|
{{#each writebackTargets}}
| {{output}} | {{location}} | {{condition}} |
{{/each}}

### 7.2 状态同步

- **任务系统**：{{taskSyncMethod}}
- **PR/MR**：{{prSyncMethod}}

## 8. 交接与归档

### 8.1 任务完成条件

- [ ] 代码已合并
- [ ] 验证摘要已写入 docs/test/
- [ ] 任务状态已更新
- [ ] 关键决策已记录到 docs/harness/ 或 AGENTS.md

### 8.2 经验归档

- 新增约束登记到：docs/harness/project-constraints.md
- 关键决策记录到：docs/harness/decision-log.md
```

## 生成规则

```yaml
generation_rules:
  - rule: "控制面文档必须真实反映项目的实际流程"
    severity: "error"
  - rule: "验证命令必须真实可用"
    severity: "error"
  - rule: "不要只写流程名，要写实际判断条件"
    severity: "warning"
  - rule: "回写目标的位置必须是项目内真实路径"
    severity: "error"
```

## 常见误用

| 误用方式 | 正确做法 |
|---------|---------|
| 只写流程名，不写实际判断条件 | 写清具体如何判断、谁负责、何时触发 |
| 验证命令是占位符 | 验证命令必须可执行 |
| 回写目标路径不存在 | 确保路径存在或说明由哪个步骤创建 |
| 包含过多细节（如具体 API 定义） | 只写协作协议，具体设计在 plan 中 |


## 版本信息

**版本**: 3.2.0
**更新时间**: 2026-05-14
**引用**: 4-schemas/schema-landing-zone.md, 4-schemas/schema-writeback.md, 3-core/core-verification.md
