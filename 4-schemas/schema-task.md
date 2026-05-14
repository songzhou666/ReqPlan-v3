# Task Schema

## 概述

定义任务（Task）的数据结构和验证规则。

## 数据结构

### Task 对象

```yaml
id: string              # 任务ID，格式：TASK-XXX
title: string          # 任务标题
description: string     # 任务描述
requirementId: string   # 关联的需求ID
status: TaskStatus     # 当前状态
estimated_hours: number # 预估工时（小时）
actual_hours?: number   # 实际工时（可选）
assignee?: string      # 负责人（可选）
dependencies: string[]  # 依赖的任务ID列表
created_at: string    # 创建时间
updated_at: string   # 更新时间
completed_at?: string  # 完成时间（可选）
priority?: Priority    # 优先级（v3新增，可选）
tags?: string[]        # 标签（v3新增，可选）
notes?: string          # 备注（v3新增，可选）
```

### TaskStatus 枚举

```yaml
TODO: 待开始
IN_PROGRESS: 进行中
DONE: 已完成
BLOCKED: 已阻塞
```

### Priority 枚举

```yaml
P0: 紧急
P1: 重要
P2: 一般
```

## 验证规则

### 必填字段
- `id`: 非空，符合格式 `TASK-\d{3}`
- `title`: 非空，长度1-200字符
- `requirementId`: 非空，符合需求ID格式
- `status`: 非空，必须是有效的TaskStatus值
- `estimated_hours`: 非空，必须是正数
- `created_at`: 非空，ISO格式时间戳
- `updated_at`: 非空，ISO格式时间戳

### 可选字段
- `actual_hours`: 必须大于等于0
- `assignee`: 长度1-100字符
- `completed_at`: 仅当status为DONE时必填
- `priority`: 必须是有效的Priority值
- `tags`: 字符串数组
- `notes`: 长度不限

## 示例

```yaml
id: "TASK-001"
title: "创建订单数据模型"
description: "设计并实现订单实体类，包括数据库表结构和ORM映射"
requirementId: "REQ-001"
status: "DONE"
estimated_hours: 2
actual_hours: 2.5
assignee: "张三"
dependencies: []
created_at: "2026-05-14T10:00:00Z"
updated_at: "2026-05-14T12:30:00Z"
completed_at: "2026-05-14T12:30:00Z"
priority: "P1"
tags: ["数据库", "模型"]
notes: "已完成初步设计，等待评审"
```

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "Task Schema v3",
  "required": ["id", "title", "requirementId", "status", "estimated_hours", "created_at", "updated_at"],
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^TASK-\\d{3}$"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 200
    },
    "description": {
      "type": "string"
    },
    "requirementId": {
      "type": "string",
      "pattern": "^REQ-\\d{3}$"
    },
    "status": {
      "type": "string",
      "enum": ["TODO", "IN_PROGRESS", "DONE", "BLOCKED"]
    },
    "estimated_hours": {
      "type": "number",
      "minimum": 0.1
    },
    "actual_hours": {
      "type": "number",
      "minimum": 0
    },
    "assignee": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "dependencies": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^TASK-\\d{3}$"
      }
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "updated_at": {
      "type": "string",
      "format": "date-time"
    },
    "completed_at": {
      "type": "string",
      "format": "date-time"
    },
    "priority": {
      "type": "string",
      "enum": ["P0", "P1", "P2"]
    },
    "tags": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "notes": {
      "type": "string"
    }
  }
}
```

---

**Schema版本**: 3.2.0  
**更新时间**: 2026-05-14  
**引用**: 3-core/core-task-management.md, 3-core/core-task-pipeline.md, 4-schemas/schema-state.md
