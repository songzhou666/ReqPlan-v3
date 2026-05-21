# Core Task Management
# 任务管理模块

## 概述

任务管理是ReqPlan的核心能力之一，负责将需求分解为可执行的任务，并支持任务状态的跟踪和管理。

## 核心原则

1. **细粒度分解**：每个功能点拆分为1-N个任务，每个任务工作量控制在1-8小时
2. **依赖管理**：识别任务间的前置依赖关系，避免执行阻塞
3. **状态可追踪**：每个任务有明确的状态流转（TODO→IN_PROGRESS→DONE/BLOCKED）
4. **进度可视化**：通过进度条和统计数据让用户直观了解项目进展

## Input/Output定义

### Input

```yaml
- requirementId: string    # 需求ID
- action: "create" | "update" | "list" | "get"
- data?: object          # 操作数据（可选）
```

**字段说明**：
- requirementId：关联的需求ID
- action：操作类型
  - create：创建任务
  - update：更新任务状态
  - list：列出所有任务
  - get：获取单个任务详情
- data：可选的操作数据

### Output

```yaml
- tasks: Task[]           # 任务列表
- state: State            # 状态快照
- message?: string        # 操作消息（可选）
```

**字段说明**：
- tasks：任务列表
- state：当前状态快照
- message：操作成功/失败消息

## 触发词

### 核心触发词
- "看看进度"
- "任务列表"
- "当前任务"
- "还有哪些"
- "分解任务"
- "制定计划"

### 扩展触发词
- "进度"
- "状态"
- "任务"
- "进展"
- "查看任务"
- "任务状态"
- "更新任务"
- "执行任务"

## 引导信息

### 查看进度后
```
📌 下一步推荐：
1️⃣ 执行任务 → "/reqplan task <ID>"（推荐）
2️⃣ 查看详情 → "/reqplan task get <ID>"
3️⃣ 更新状态 → "/reqplan task update <ID> <status>"
```

### 任务完成后
```
📌 下一步推荐：
1️⃣ 继续下一个任务 → "/reqplan task list"（推荐）
2️⃣ 查看整体进度 → "/reqplan status"
3️⃣ 进行验收 → "/reqplan verify"
```

### 阶段状态提示
```
📊 当前阶段：开发执行中
├── 需求：订单管理模块（REQ-001）
├── 进度：[██████░░░░] 60%
├── 已完成：3/5 任务
└── 下一步：执行下一个任务
```

## 任务状态

### 状态类型

```yaml
- TODO: 待开始
- IN_PROGRESS: 进行中
- DONE: 已完成
- BLOCKED: 已阻塞
```

### 状态转换规则

```
TODO → IN_PROGRESS（开始执行）
IN_PROGRESS → DONE（完成）
IN_PROGRESS → BLOCKED（遇到阻塞）
BLOCKED → IN_PROGRESS（解除阻塞）
DONE → IN_PROGRESS（重新打开）
```

## 任务结构

### Task对象

```yaml
- id: string              # 任务ID（TASK-001）
- title: string          # 任务标题
- description: string     # 任务描述
- status: TaskStatus    # 当前状态
- estimated_hours: number # 预估工时
- actual_hours?: number   # 实际工时（可选）
- dependencies: string[]  # 依赖的任务ID列表
- assignee?: string      # 负责人（可选）
- created_at: string    # 创建时间
- updated_at: string   # 更新时间
- completed_at?: string  # 完成时间（可选）
```

### 示例

```yaml
- id: TASK-001
  title: 创建订单数据模型
  description: 设计并实现订单实体类
  status: DONE
  estimated_hours: 2
  actual_hours: 2.5
  dependencies: []
  assignee: AI
  created_at: 2026-05-14 10:00
  updated_at: 2026-05-14 12:30
  completed_at: 2026-05-14 12:30
```

## 详细流程

### create：创建任务

**任务**：
1. 读取需求文档
2. 分解功能点为具体任务
3. 识别任务依赖关系
4. 估算工作量
5. 创建state.yaml文件

**输入**：
```yaml
- requirementId: REQ-001
- action: create
- data:
    - functionalPoints: [列表]
```

**输出**：
```yaml
- tasks: [任务列表]
- state: {状态快照}
- message: "已创建X个任务"
```

**任务分解规则**：
```yaml
功能点 → 任务拆分原则：
1. 每个功能点拆分为1-N个任务
2. 每个任务的工作量预估在1-8小时
3. 任务间识别依赖关系
4. 识别里程碑点
```

### update：更新任务

**任务**：
1. 验证任务ID存在
2. 更新任务状态
3. 记录更新时间
4. 更新进度统计

**输入**：
```yaml
- requirementId: REQ-001
- action: update
- data:
    - taskId: TASK-001
    - status: IN_PROGRESS
    - actual_hours?: 2
```

**输出**：
```yaml
- tasks: [更新后的任务列表]
- state: {更新后的状态}
- message: "任务TASK-001状态已更新为IN_PROGRESS"
```

### list：列出任务

**任务**：
1. 读取state.yaml文件
2. 按状态分组任务
3. 计算进度百分比
4. 生成进度报告

**输入**：
```yaml
- requirementId: REQ-001
- action: list
```

**输出**：
```markdown
📊 当前进度总览

需求：订单管理模块（REQ-001）
阶段：开发中
进度：[████████░░░░░░░░░░░] 40%

任务状态：
✅ TASK-001: 创建订单数据模型 [已完成]
✅ TASK-002: 实现订单创建API [已完成]
🔄 TASK-003: 实现订单查询API [进行中]
⏳ TASK-004: 实现订单修改API [待开始]
⏳ TASK-005: 编写单元测试 [待开始]

里程碑：MVP完成
预计完成：2026-05-16
剩余任务：3个
```

### get：获取任务详情

**任务**：
1. 验证任务ID存在
2. 读取任务详细信息
3. 检查依赖任务状态
4. 提供下一步建议

**输入**：
```yaml
- requirementId: REQ-001
- action: get
- data:
    - taskId: TASK-003
```

**输出**：
```markdown
## TASK-003: 实现订单查询API

**状态**：🔄 进行中
**预估工时**：4小时
**实际工时**：2小时

**任务描述**：
实现订单查询接口，支持分页查询和条件过滤

**依赖任务**：
✅ TASK-002: 实现订单创建API [已完成]

**下一步建议**：
1. 继续完成当前任务
2. 预计还需2小时
```

## 失败策略

### E201: 项目不存在

**错误信息**：
```yaml
E201: 项目不存在：{{projectName}}
```

**处理方式**：
```markdown
⚠️ 未找到项目：{{projectName}}

询问用户：
是否要创建新项目？
请提供项目名称和基本信息。
```

### E202: 任务不存在

**错误信息**：
```yaml
E202: 任务不存在：{{taskId}}
```

**处理方式**：
```markdown
⚠️ 未找到任务：{{taskId}}

当前需求的所有任务：
- TASK-001: [任务标题]
- TASK-002: [任务标题]
- TASK-003: [任务标题]

请检查任务ID是否正确。
```

### E203: 状态转换无效

**错误信息**：
```yaml
E203: 状态转换无效：{{fromStatus}} → {{toStatus}}
```

**处理方式**：
```markdown
⚠️ 状态转换无效

当前状态：{{fromStatus}}
目标状态：{{toStatus}}

有效的状态转换：
- TODO → IN_PROGRESS
- IN_PROGRESS → DONE
- IN_PROGRESS → BLOCKED
- BLOCKED → IN_PROGRESS

请重新选择目标状态。
```

## 示例对话

### 示例1：创建开发计划

```
用户：帮我制定开发计划
AI：  好的，正在分析需求并分解任务...

      已读取需求文档：REQ-001

      **任务分解**：
      根据5个功能点，分解为以下任务：

      1. TASK-001: 创建订单数据模型
         预估：2小时
         依赖：无

      2. TASK-002: 实现订单创建API
         预估：4小时
         依赖：TASK-001

      3. TASK-003: 实现订单查询API
         预估：4小时
         依赖：TASK-001

      ...

      **里程碑**：
      - M1: 数据模型完成（预计Day 1）
      - M2: API开发完成（预计Day 3）
      - M3: 测试完成（预计Day 5）

      总计：18小时

      是否保存此计划？
```

### 示例2：查看进度

```
用户：看看当前进度
AI：  📊 当前进度总览

      需求：订单管理模块（REQ-001）
      阶段：开发中
      进度：[████████░░] 40%

      任务状态：
      ✅ TASK-001: 创建订单数据模型 [已完成]
      ✅ TASK-002: 实现订单创建API [已完成]
      🔄 TASK-003: 实现订单查询API [进行中]
      ⏳ TASK-004: 实现订单修改API [待开始]
      ⏳ TASK-005: 编写单元测试 [待开始]

      里程碑：MVP完成
      预计完成：2026-05-16
      剩余任务：3个

      需要关注的问题：
      ⚠️ TASK-003进行中，预计还需2小时
```

### 示例3：更新任务状态

```
用户：TASK-003完成了
AI：  好的，正在更新任务状态...

      ✅ TASK-003: 实现订单查询API
      状态：IN_PROGRESS → DONE
      实际工时：4小时

      📊 更新后的进度：

      需求：订单管理模块（REQ-001）
      阶段：开发中
      进度：[██████████░░░░░░░░] 60%

      ✅ TASK-001: 创建订单数据模型 [已完成]
      ✅ TASK-002: 实现订单创建API [已完成]
      ✅ TASK-003: 实现订单查询API [已完成]
      🔄 TASK-004: 实现订单修改API [进行中]
      ⏳ TASK-005: 编写单元测试 [待开始]
```

## 与其他模块的集成

### 依赖模块
- core-intent-analysis.md（意图分析）
- core-doc-generation.md（文档生成）

### 被依赖模块
- core-verification.md（验收评估）

### 数据流转
```
需求文档
    ↓
任务分解
    ↓
state.yaml（状态管理）
    ↓
进度跟踪
    ↓
验收评估
```

## 最佳实践

1. **合理分解任务**：每个任务工作量1-8小时
2. **明确依赖关系**：避免阻塞
3. **及时更新状态**：保持状态准确性
4. **进度可视化**：让用户清晰了解进度
5. **设置里程碑**：便于阶段验收

## 版本信息

**版本**: 3.2.0
**更新时间**: 2026-05-14
