# State Schema

## 概述

定义状态（State）的数据结构和验证规则。
state.yaml 存储索引摘要数据；详细内容与制品存储在目录层级中（参见 `core-state-management.md`）。

## 数据结构

### State 对象

```yaml
project: string             # 项目名称
projectId: string          # 项目ID
version: string            # 版本号
created_at: string        # 创建时间
last_updated: string     # 最后更新时间

# 上下文管理
context_expires_at: string  # 上下文过期时间
current_user?: string      # 当前用户（可选）

# 当前流程
current_flow?: string      # 当前流程（v3新增）
flow_history?: string[]    # 流程历史（v3新增）

# 当前阶段
current_phase: PhaseType   # 当前阶段
current_requirement?: string # 当前需求ID（可选）

# 进度追踪
progress: Progress         # 进度信息

# 需求列表
requirements: Requirement[] # 需求列表

# 任务列表
tasks: Task[]             # 任务列表

# 里程碑
milestones: Milestone[]   # 里程碑列表

# 配置
config: Config            # 配置信息
```

### PhaseType 枚举

```yaml
requirements: 需求分析阶段
design: 设计阶段
development: 开发阶段
verification: 验收阶段
completed: 已完成
```

### Progress 对象

```yaml
requirements: number       # 需求阶段进度（0-100）
design: number             # 设计阶段进度（0-100）
development: number        # 开发阶段进度（0-100）
verification: number       # 验收阶段进度（0-100）
overall: number            # 综合进度（0-100）
current_flow?: number      # 当前流程进度（v3新增，0-100）
```

### Requirement 对象（索引摘要，存储于 state.yaml）

```yaml
id: string              # 需求ID，格式：REQ-XXX
title: string          # 需求标题
description: string     # 需求描述
status: RequirementStatus # 状态
priority: Priority      # 优先级
created_at: string    # 创建时间
updated_at: string   # 更新时间
```
需求详细内容（设计文档、计划、验证结果等）存储在 `requirements/<req-id>/` 目录层级中各独立文件内。state.yaml 中的 requirements 数组仅作为索引摘要，两者保持同步。

### RequirementStatus 枚举

```yaml
pending: 待确认
active: 进行中
completed: 已完成
cancelled: 已取消
```

### Priority 枚举

```yaml
P0: 紧急
P1: 重要
P2: 一般
```

### Milestone 对象

```yaml
id: string              # 里程碑ID
title: string          # 里程碑标题
deadline: string      # 截止日期
completed: boolean     # 是否已完成
```

### Config 对象

```yaml
auto_save: boolean      # 是否自动保存
backup_interval: number # 备份间隔（秒）
context_timeout: number # 上下文超时（秒）
```

## 验证规则

### 必填字段
- `project`: 非空，长度1-100字符
- `projectId`: 非空，长度1-50字符
- `version`: 非空，符合语义化版本格式
- `created_at`: 非空，ISO格式时间戳
- `last_updated`: 非空，ISO格式时间戳
- `context_expires_at`: 非空，ISO格式时间戳
- `current_phase`: 非空，必须是有效的PhaseType值

### 可选字段
- `current_user`: 长度1-100字符
- `current_requirement`: 符合需求ID格式
- `current_flow`: 符合流程名称格式

### 进度验证
- 所有进度值必须在0-100范围内
- `overall` 应为其他进度的加权平均值

## 示例

```yaml
project: "我的项目"
projectId: "my-project"
version: "3.1.0"
created_at: "2026-05-14T09:00:00Z"
last_updated: "2026-05-14T10:30:00Z"
context_expires_at: "2026-05-14T11:00:00Z"
current_user: "user-001"

current_flow: "full-project"
flow_history: ["full-project", "requirement-update"]
current_phase: "development"
current_requirement: "REQ-001"

progress:
  requirements: 100
  design: 100
  development: 50
  verification: 0
  overall: 60
  current_flow: 50

requirements:
  - id: "REQ-001"
    title: "订单管理模块"
    description: "订单的CRUD功能"
    status: "active"
    priority: "P1"
    created_at: "2026-05-14T09:00:00Z"
    updated_at: "2026-05-14T10:00:00Z"

tasks:
  - id: "TASK-001"
    title: "创建订单数据模型"
    status: "DONE"
    estimated_hours: 2

milestones:
  - id: "MILESTONE-001"
    title: "MVP完成"
    deadline: "2026-05-16T18:00:00Z"
    completed: false

config:
  auto_save: true
  backup_interval: 300
  context_timeout: 1800
```

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "State Schema v3",
  "required": ["project", "projectId", "version", "created_at", "last_updated", "context_expires_at", "current_phase", "progress"],
  "properties": {
    "project": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "projectId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 50
    },
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$"
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "last_updated": {
      "type": "string",
      "format": "date-time"
    },
    "context_expires_at": {
      "type": "string",
      "format": "date-time"
    },
    "current_user": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "current_flow": {
      "type": "string"
    },
    "flow_history": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "current_phase": {
      "type": "string",
      "enum": ["requirements", "design", "development", "verification", "completed"]
    },
    "current_requirement": {
      "type": "string",
      "pattern": "^REQ-\\d{3}$"
    },
    "progress": {
      "type": "object",
      "required": ["requirements", "design", "development", "verification", "overall"],
      "properties": {
        "requirements": { "type": "number", "minimum": 0, "maximum": 100 },
        "design": { "type": "number", "minimum": 0, "maximum": 100 },
        "development": { "type": "number", "minimum": 0, "maximum": 100 },
        "verification": { "type": "number", "minimum": 0, "maximum": 100 },
        "overall": { "type": "number", "minimum": 0, "maximum": 100 },
        "current_flow": { "type": "number", "minimum": 0, "maximum": 100 }
      }
    },
    "requirements": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "title", "status", "priority", "created_at", "updated_at"],
        "properties": {
          "id": { "type": "string", "pattern": "^REQ-\\d{3}$" },
          "title": { "type": "string", "minLength": 1 },
          "description": { "type": "string" },
          "status": { "type": "string", "enum": ["pending", "active", "completed", "cancelled"] },
          "priority": { "type": "string", "enum": ["P0", "P1", "P2"] },
          "created_at": { "type": "string", "format": "date-time" },
          "updated_at": { "type": "string", "format": "date-time" }
        }
      }
    },
    "tasks": {
      "type": "array",
      "items": {
        "$ref": "schema-task.md"
      }
    },
    "milestones": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "title", "deadline", "completed"],
        "properties": {
          "id": { "type": "string", "pattern": "^MILESTONE-\\d{3}$" },
          "title": { "type": "string", "minLength": 1 },
          "deadline": { "type": "string", "format": "date-time" },
          "completed": { "type": "boolean" }
        }
      }
    },
    "config": {
      "type": "object",
      "properties": {
        "auto_save": { "type": "boolean" },
        "backup_interval": { "type": "number", "minimum": 60 },
        "context_timeout": { "type": "number", "minimum": 60 }
      }
    }
  }
}
```

---

**Schema版本**: 3.2.0  
**更新时间**: 2026-05-14  
**引用**: 3-core/core-state-management.md, 3-core/core-file-sync.md, 4-schemas/schema-task.md
