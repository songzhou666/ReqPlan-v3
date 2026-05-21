---
template:
  name: template-req
  version: "3.2"
  type: requirement
  usage: 用于生成标准化的需求文档（v3）
---

# {{title}}

## 基本信息

| 字段 | 值 |
|------|-----|
| 需求ID | {{requirementId}} |
| 标题 | {{title}} |
| 优先级 | {{priority}} |
| 状态 | {{status}} |
| 关联流程 | {{currentFlow}} |
| 创建时间 | {{createdAt}} |
| 更新时间 | {{updatedAt}} |

## 利益相关者

{{#each stakeholders}}
- **{{role}}**：{{description}}
{{/each}}

## 功能需求

{{#each functionalRequirements}}
### {{id}}: {{title}}

**优先级**：{{priority}}

**描述**：
{{description}}

**验收标准**：
{{#each acceptanceCriteria}}
- {{this}}
{{/each}}

{{#if technicalNotes}}
**技术备注**：
{{technicalNotes}}
{{/if}}

---

{{/each}}

## 非功能需求

{{#if nonFunctionalRequirements}}

### 性能

{{#each nonFunctionalRequirements.performance}}
- {{requirement}}：{{value}}
{{/each}}

### 安全

{{#each nonFunctionalRequirements.security}}
- {{requirement}}：{{value}}
{{/each}}

### 可用性

{{#each nonFunctionalRequirements.availability}}
- {{requirement}}：{{value}}
{{/each}}

{{/if}}

## 数据需求

{{#if dataRequirements}}

### 输入数据

{{#each dataRequirements.input}}
- **{{name}}**（{{type}}）：
  - 来源：{{source}}
  - 格式：{{format}}
  - 约束：{{constraints}}
{{/each}}

### 输出数据

{{#each dataRequirements.output}}
- **{{name}}**（{{type}}）：
  - 去向：{{destination}}
  - 格式：{{format}}
  - 约束：{{constraints}}
{{/each}}

{{/if}}

## 接口需求

{{#if interfaceRequirements}}

### API接口

{{#each interfaceRequirements}}
#### {{method}} {{path}}

**功能**：{{description}}

**请求参数**：
{{#each requestParameters}}
- **{{name}}**（{{type}}{{#if required}}，必填{{/if}}）：{{description}}
{{/each}}

**响应格式**：
`json
{{responseExample}}
`

{{/each}}

{{/if}}

## 约束条件

{{#if constraints}}
{{#each constraints}}
- **{{type}}**：{{description}}
{{/each}}
{{else}}
- 无特殊约束
{{/if}}

## 风险与假设

{{#if risks}}
{{#each risks}}
### {{id}}: {{title}}

- **风险**：{{description}}
- **影响**：{{impact}}
- **缓解措施**：{{mitigation}}
{{/each}}
{{else}}
- 无已知风险
{{/if}}

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
**引用**：4-schemas/schema-landing-zone.md, 3-core/core-intent-analysis.md, 3-core/core-doc-generation.md
