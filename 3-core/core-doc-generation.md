# Core Doc Generation
# 文档生成模块

## 概述

文档生成是ReqPlan的核心能力之一，负责根据意图分析的结果，使用标准模板生成结构化的文档。

## 核心原则

1. **模板驱动**：所有文档基于标准模板生成，保证格式统一、结构完整
2. **数据驱动**：文档内容由数据层决定，模板只负责呈现格式
3. **渐进生成**：支持按需生成单篇文档，也支持批量生成全套文档
4. **可追溯性**：生成的每篇文档都记录版本、依赖关系和生成时间

## Input/Output定义

### Input

```yaml
- type: "req" | "design" | "plan"  # 文档类型
- content: object                   # 内容数据
- template: string                # 模板名称
```

**字段说明**：
- type：文档类型，可选值为req（需求文档）、design（设计文档）、plan（开发计划）
- content：基于意图分析的内容数据
- template：使用的模板名称（可选，默认根据type自动选择）

### Output

```yaml
- filePath: string    # 生成的文件路径
- content: string    # 文档内容
```

**字段说明**：
- filePath：生成的文件路径，相对于项目根目录
- content：生成的完整文档内容

## 触发词

### 核心触发词
- "生成需求文档"
- "创建设计文档"
- "制定开发计划"
- "输出文档"
- "生成文档"

### 扩展触发词
- "生成文档"
- "创建文档"
- "查看文档"
- "需求文档"
- "设计文档"
- "开发计划"
- "文档生成"

## 引导信息

### 完成文档生成后
```
📌 下一步推荐：
1️⃣ 制定开发计划 → "/reqplan plan"（推荐）
2️⃣ 审核文档 → "/reqplan review"
3️⃣ 修改文档 → "/reqplan docs update"
```

### 阶段状态提示
```
📊 当前阶段：文档生成完成
├── 文档类型：需求文档
├── 路径：.trae/reqplan/projects/xxx/requirements/REQ-001/req.md
└── 下一步：制定开发计划
```

## 支持的文档类型

### 1. 需求文档（REQ）

**模板**：template-req.md

**内容要求**：
```yaml
- requirementId: string        # 需求ID
- title: string                  # 需求标题
- functionalPoints: string[]     # 功能点列表
- userRoles: string[]          # 用户角色
- acceptanceCriteria: string[] # 验收标准
- priority: "P0" | "P1" | "P2" # 优先级
- nonFunctionalRequirements?: object # 非功能需求（可选）
```

### 2. 设计文档（DESIGN）

**模板**：template-design.md

**内容要求**：
```yaml
- requirementId: string      # 需求ID
- title: string            # 设计标题
- apiDesign: object        # API设计
- dataModel: object        # 数据模型
- architecture: string     # 架构说明
```

### 3. 开发计划（PLAN）

**模板**：template-plan.md（v3.2 — 实现路径格式）

**内容要求**：
```yaml
# 必填：核心实现路径
- planId: string              # 计划ID
- taskId: string              # 关联任务ID
- title: string               # 计划标题
- scope: string               # 本轮目标描述
- nonGoals: string[]          # 明确不做的清单
- validationCriteria: string[] # 验收口径清单
- rollbackStrategy: []        # 回滚策略（condition/action/verification）
- entryPoints: []             # 真实入口列表（type/path/description）
- componentResponsibilities: [] # 组件职责矩阵（component/type/responsibility/input/output）
- keySequence: string         # 关键时序说明
- failureStrategies: []       # 失败策略列表（scenario/strategy/retries/escalation/note）
- verificationCommands: []    # 验证命令列表（layer/command/expected/onFailure）
- writebackTargets: []        # 回写目标列表（target/content/format/timing）
- landingZones: []            # 信息落点列表（output/location/description）

# 可选
- complexity: "L1" | "L2" | "L3"  # 任务复杂度
- frontendStates: []          # 前端状态覆盖（如适用）
- tasks: []                   # 子任务分解（仅L3使用）
- decisionLog: []             # 决策日志
- pipeline: {}                # 管道状态映射
```

## 详细流程

### Step 1: 读取需求文档

**任务**：
1. 确认需求文档已存在
2. 读取意图分析结果
3. 确认需求范围

**输出**：
```markdown
已读取需求文档：REQ-001.md

需求范围：
- 功能点：[列表]
- 用户角色：[列表]
- 优先级：[优先级]
```

### Step 2: 收集内容数据

**任务**：
1. 根据文档类型收集必要数据
2. 验证数据完整性
3. 补充缺失信息（如需要）

**需求文档数据收集**：
```markdown
1. 基本信息
   - 需求ID：[自动生成]
   - 标题：[用户提供]
   - 优先级：[P0/P1/P2]

2. 功能需求
   - 功能点1：[描述]
   - 功能点2：[描述]

3. 验收标准
   - 标准1：[描述]
   - 标准2：[描述]
```

### Step 3: 选择模板

**任务**：
1. 根据文档类型选择对应模板
2. 加载模板内容
3. 准备填充数据

**模板选择规则**：
```yaml
type = "req" → template = "template-req.md"
type = "design" → template = "template-design.md"
type = "plan" → template = "template-plan.md"
```

### Step 4: 生成文档

**任务**：
1. 使用模板填充内容
2. 格式化输出
3. 保存到指定路径

**输出格式**：
```yaml
filePath: .trae/reqplan/projects/<project>/requirements/<req-id>/<doc-type>.md
content: <完整文档内容>
```

## 模板使用规范

### YAML Frontmatter

每个模板都必须包含YAML frontmatter：

```yaml
---
template:
  name: <模板名称>
  version: "3.1"
  type: <文档类型>
  usage: <使用说明>
---
```

### 变量替换

使用双花括号进行变量替换：

```markdown
{{requirementId}}
{{title}}
{{functionalPoints}}
```

### 条件渲染

使用YAML配置条件渲染：

```yaml
conditional:
  - field: nonFunctionalRequirements
    render: true
```

## 失败策略

### E101: 模板不存在

**错误信息**：
```yaml
E101: 模板不存在：{{templateName}}
```

**处理方式**：
```markdown
⚠️ 警告：模板 {{templateName}} 不存在

将使用默认Markdown格式生成文档。

默认格式：
# {{title}}

## 基本信息
- ID: {{requirementId}}
- 优先级: {{priority}}

## 内容
{{content}}
```

### E102: 内容不完整

**错误信息**：
```yaml
E102: 内容不完整，缺少必填字段
```

**处理方式**：
```markdown
⚠️ 无法生成文档：缺少以下必填信息

1. [缺失字段1]
2. [缺失字段2]

请补充：
```

**必需字段清单**：

需求文档：
- requirementId
- title
- functionalPoints
- acceptanceCriteria

设计文档：
- requirementId
- apiDesign

开发计划：
- requirementId
- tasks

## 示例对话

### 示例1：生成需求文档

```
用户：帮我生成需求文档
AI：  请提供以下信息：
      1. 需求标题（用于文档名称）
      2. 核心功能点（我将列出已识别的功能供您确认）
      3. 验收标准（什么是"完成"的标准？）
      4. 优先级（P0/P1/P2）

用户：标题是"订单管理模块"，功能点是CRUD加统计，验收标准是功能正常可用，优先级P1
AI：  好的，正在生成需求文档...

      📄 需求文档已生成：
      路径：.trae/reqplan/projects/my-project/requirements/REQ-001/req.md

      **文档预览**：

      # 订单管理模块

      ## 基本信息
      - ID: REQ-001
      - 标题: 订单管理模块
      - 优先级: P1
      - 状态: 已确认

      ## 功能需求

      ### FR-001: 订单创建
      ...

      是否需要查看完整文档？
```

## 与其他模块的集成

### 依赖模块
- core-intent-analysis.md（意图分析）

### 被依赖模块
- 无

### 数据流转
```
意图分析
    ↓
文档生成（req.md）
    ↓
┌──────────────┐
│ 设计文档    │ → design.md
│ 开发计划    │ → plan.md
└──────────────┘
```

## 最佳实践

1. **先读取再生成**：确保有完整的输入数据
2. **验证数据完整性**：缺失数据时及时询问
3. **使用标准模板**：保证文档格式统一
4. **提供预览**：让用户确认后再保存
5. **记录生成路径**：便于后续查找和使用

## 版本信息

**版本**: 3.2.0
**更新时间**: 2026-05-14
