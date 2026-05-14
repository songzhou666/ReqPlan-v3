---
template:
  name: template-plan
  version: "3.2"
  type: plan
  usage: 用于生成实现路径格式的开发计划（v3.2），聚焦真实入口、组件职责、失败策略、验证命令和回写目标
---

# {{title}}

## 基本信息

| 字段 | 值 |
|------|-----|
| 计划ID | {{planId}} |
| 关联任务 | {{taskId}} |
| 关联流程 | {{currentFlow}} |
| 标题 | {{title}} |
| 复杂度 | {{complexity}} |
| 状态 | {{status}} |
| 创建时间 | {{createdAt}} |
| 更新时间 | {{updatedAt}} |

---

## 范围冻结（Scope Freeze）

范围冻结是每轮任务的"宪法"，在计划阶段必须明确四条边界。

### 本轮目标（Scope）

```
{{scope}}
```

### 明确不做的（Non-Goals）

{{#each nonGoals}}
- {{this}}
{{/each}}

### 验收口径（Validation）

{{#each validationCriteria}}
- [ ] {{this}}
{{/each}}

### 失败回滚策略（Rollback）

| 触发条件 | 回滚操作 | 恢复验证 |
|---------|---------|---------|
{{#each rollbackStrategy}}
| {{condition}} | {{action}} | {{verification}} |
{{/each}}

---

## 实现路径

这是本模板的核心变更——**不写流程步骤，只写实现路径**。路径回答的不是"先做什么后做什么"，而是"真实入口在哪、谁来负责、失败了怎么办、怎么验证、往哪回写"。

### 真实入口（Entry Points）

```
{{entryPoints.commands}}
```

| 入口类型 | 位置/路径 | 说明 |
|---------|----------|------|
{{#each entryPoints}}
| {{type}} | {{path}} | {{description}} |
{{/each}}

入口类型说明：
- `command`：运行/构建/测试命令
- `file`：源代码文件的绝对或相对路径
- `api`：后端 API 端点
- `config`：配置文件路径
- `script`：自动化脚本路径

### 输入来源（Input Sources）

| 来源类型 | 格式 | 示例 | 说明 |
|---------|------|------|------|
{{#each inputSources}}
| {{type}} | {{format}} | {{example}} | {{description}} |
{{/each}}

### 组件职责（Component Responsibilities）

| 组件 | 类型 | 职责 | 输入 | 输出 |
|------|------|------|------|------|
{{#each componentResponsibilities}}
| {{component}} | {{type}} | {{responsibility}} | {{input}} | {{output}} |
{{/each}}

组件类型说明：
- `page`：页面组件，负责 UI 渲染
- `service`：服务层，负责业务逻辑和数据访问
- `api`：API 端点，负责请求/响应处理
- `util`：工具函数，通用能力
- `config`：配置定义
- `hook`：自定义 Hook（前端）
- `middleware`：中间件（后端）

### 关键时序（Key Sequence）

```
{{keySequence}}
```

时序说明：这不是流程图，而是**真实的操作顺序**。每步应具体到文件或命令级别。

### 失败处理策略（Failure Strategy）

| 场景 | 策略 | 重试次数 | 升级条件 | 说明 |
|------|------|---------|---------|------|
{{#each failureStrategies}}
| {{scenario}} | {{strategy}} | {{retries}} | {{escalation}} | {{note}} |
{{/each}}

策略类型说明：
- `retry`：自动重试 N 次
- `skip`：跳过该步骤（需记录到 decision_log）
- `rollback`：回退到上一个稳定版本
- `fallback`：使用备选方案
- `block`：阻塞等待人工介入

### 验证命令（Verification Commands）

| 验证层次 | 验证命令 | 预期结果 | 失败处理 |
|---------|---------|---------|---------|
{{#each verificationCommands}}
| {{layer}} | `{{command}}` | {{expected}} | {{onFailure}} |
{{/each}}

验证层次说明：
- `static`：静态检查（lint、typecheck、format）
- `unit`：单元测试
- `integration`：集成测试/链路测试/E2E
- `failure`：异常场景/失败模式验证
- `writeback`：回写验证（检查产出物落点）

### 回写目标（Writeback Targets）

| 目标位置 | 回写内容 | 格式 | 时机 |
|---------|---------|------|------|
{{#each writebackTargets}}
| {{target}} | {{content}} | {{format}} | {{timing}} |
{{/each}}

---

## 信息落点（Landing Zones）

| 产出物 | 落点位置 | 说明 |
|-------|---------|------|
{{#each landingZones}}
| {{output}} | {{location}} | {{description}} |
{{/each}}

---

## 决策日志（Decision Log）

任务执行过程中的关键决策记录，供后续回溯和经验复用。

| 时间 | 类型 | 决策内容 | 原因 | 影响 |
|------|------|---------|------|------|
{{#each decisionLog}}
| {{timestamp}} | {{type}} | {{decision}} | {{reason}} | {{impact}} |
{{/each}}

决策类型说明：
- `scope_change`：范围变更
- `path_change`：实现路径偏离
- `failure_handled`：失败处理记录
- `blocker_escalated`：阻塞升级
- `recovery`：恢复操作

---

## 管道状态映射（Pipeline State Reference）

| 管道阶段 | 状态 | 产出物路径 | 完成时间 |
|---------|------|-----------|---------|
| Stage 1 任务入口 | {{pipeline.stage1.status}} | {{pipeline.stage1.artifact}} | {{pipeline.stage1.completedAt}} |
| Stage 2 计划冻结 | {{pipeline.stage2.status}} | {{pipeline.stage2.artifact}} | {{pipeline.stage2.completedAt}} |
| Stage 3 Agent执行 | {{pipeline.stage3.status}} | {{pipeline.stage3.artifact}} | {{pipeline.stage3.completedAt}} |
| Stage 4 验证评审 | {{pipeline.stage4.status}} | {{pipeline.stage4.artifact}} | {{pipeline.stage4.completedAt}} |
| Stage 5 回写收口 | {{pipeline.stage5.status}} | {{pipeline.stage5.artifact}} | {{pipeline.stage5.completedAt}} |

---

## 前端实现说明（如适用）

### 页面结构

```
{{pageStructure}}
```

### 状态覆盖

| 状态 | 覆盖方式 | 当前阶段 |
|------|---------|---------|
{{#each frontendStates}}
| {{stateName}} | {{coverageType}}（{{coverageMethod}}） | {{status}} |
{{/each}}

---

## 任务分解（可选）

仅在 L3 复杂度任务中需要对大型实现路径做进一步拆分时使用。

{{#if tasks}}

{{#each tasks}}
### {{id}}: {{title}}

**状态**：{{status}}
**优先级**：{{priority}}
**组件**：{{component}}

**任务描述**：
{{description}}

**验收标准**：
{{#each acceptanceCriteria}}
- {{this}}
{{/each}}

{{/each}}

{{/if}}

---

## 附录

{{#if appendix}}
{{appendix}}
{{else}}
- 无
{{/if}}

---

**文档版本**：{{version}}
**最后更新**：{{updatedAt}}
**维护人**：songzhou
**引用**：4-schemas/schema-landing-zone.md, 4-schemas/schema-writeback.md, 3-core/core-task-pipeline.md
