---
template:
  name: template-design
  version: "3.2"
  type: design
  usage: 用于生成标准化的技术设计文档（v3）
---

# {{title}}

## 基本信息

| 字段 | 值 |
|------|-----|
| 设计ID | {{designId}} |
| 关联需求 | {{requirementId}} |
| 关联流程 | {{currentFlow}} |
| 标题 | {{title}} |
| 状态 | {{status}} |
| 创建时间 | {{createdAt}} |
| 更新时间 | {{updatedAt}} |

## 概述

{{overview}}

## 系统架构

{{#if architecture}}

### 整体架构

{{architecture.description}}

{{#if architecture.components}}
### 组件

{{#each architecture.components}}
#### {{name}}

- **类型**：{{type}}
- **职责**：{{responsibility}}
- **依赖**：{{#each dependencies}}{{this}}{{#unless @last}}、{{/unless}}{{/each}}
{{/each}}
{{/if}}

{{#if architecture.dataFlow}}
### 数据流

{{architecture.dataFlow}}
{{/if}}

{{/if}}

## API设计

{{#if apiDesign}}

{{#each apiDesign}}
### {{method}} {{path}}

**功能**：{{description}}

**认证**：{{authentication}}

**请求参数**：

{{#if requestHeaders}}
**请求头**：
{{#each requestHeaders}}
- **{{name}}**（{{type}}{{#if required}}，必填{{/if}}）：{{description}}
{{/each}}
{{/if}}

{{#if requestParameters}}
**URL参数**：
{{#each requestParameters}}
- **{{name}}**（{{type}}{{#if required}}，必填{{/if}}）：{{description}}{{#if defaultValue}}，默认：{{defaultValue}}{{/if}}
{{/each}}
{{/if}}

{{#if requestBody}}
**请求体**：
`json
{{requestBody.example}}
`
{{/if}}

**响应**：

**成功响应**（{{successCode}}）：
`json
{{successResponse}}
`

{{#if errorResponses}}
**错误响应**：
{{#each errorResponses}}
- **{{code}}**{{#if description}}：{{description}}{{/if}}
{{/each}}
{{/if}}

{{#if examples}}
**示例**：

{{#each examples}}
*场景*：{{scenario}}

*请求*：
`bash
{{request}}
`

*响应*：
`json
{{response}}
`
{{/each}}
{{/if}}

---

{{/each}}

{{/if}}

## 数据模型

{{#if dataModels}}

{{#each dataModels}}
### {{entityName}}

**表名**：{{tableName}}

**字段**：

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
{{#each fields}}
| {{name}} | {{type}} | {{constraints}} | {{description}} |
{{/each}}

{{#if relationships}}
**关系**：
{{#each relationships}}
- {{relationshipType}}：{{targetEntity}}
{{/each}}
{{/if}}

{{#if indexes}}
**索引**：
{{#each indexes}}
- {{type}}：{{fields}}
{{/each}}
{{/if}}

{{/each}}

{{/if}}

## 模块设计

{{#if modules}}

{{#each modules}}
### {{name}}

**路径**：{{path}}

**职责**：{{responsibility}}

{{#if publicAPI}}
**公开API**：
{{#each publicAPI}}
- {{method}} {{path}}：{{description}}
{{/each}}
{{/if}}

{{#if dependencies}}
**依赖**：
{{#each dependencies}}
- {{this}}
{{/each}}
{{/if}}

{{#if implementation}}
**实现要点**：
{{implementation}}
{{/if}}

{{/each}}

{{/if}}

## 错误处理

{{#if errorHandling}}

{{#each errorHandling}}
### {{code}}

- **HTTP状态码**：{{httpStatus}}
- **错误码**：{{errorCode}}
- **描述**：{{description}}
- **处理建议**：{{suggestion}}
{{/each}}

{{/if}}

## 安全设计

{{#if security}}

{{#if security.authentication}}
### 认证

{{security.authentication}}
{{/if}}

{{#if security.authorization}}
### 授权

{{security.authorization}}
{{/if}}

{{#if security.dataProtection}}
### 数据保护

{{security.dataProtection}}
{{/if}}

{{/if}}

## 性能考虑

{{#if performance}}
{{performance}}
{{else}}
- 无特殊性能要求
{{/if}}

## 兼容性

{{#if compatibility}}
{{compatibility}}
{{else}}
- 无特殊兼容性要求
{{/if}}

## 部署架构

{{#if deployment}}
{{deployment}}
{{else}}
- 暂无部署架构信息
{{/if}}

## 测试策略

{{#if testingStrategy}}
{{testingStrategy}}
{{else}}
- 暂无测试策略
{{/if}}

---

**文档版本**：{{version}}
**最后更新**：{{updatedAt}}
**维护人**：songzhou
**引用**：4-schemas/schema-landing-zone.md, 3-core/core-workflow-engine.md, 7-flows/flow-design-review.md
