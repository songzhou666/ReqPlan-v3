# Context Schema (v3)
# 上下文数据结构

## 概述
定义ReqPlan-v3的全局上下文数据结构，用于状态追溯、流程管理和全局任务协调。

## 上下文数据结构

```yaml
context:
  # 基础信息
  project_id: string                    # 项目唯一标识
  project_name: string                  # 项目名称
  created_at: datetime                  # 创建时间
  updated_at: datetime                  # 最后更新时间

  # 当前流程状态
  current_flow: string                  # 当前流程ID (full/iteration/design-review/audit/testing/docs/refactor)
  current_flow_name: string             # 当前流程名称
  current_step: number                  # 当前流程步骤
  flow_progress: number                 # 流程进度 (0-100)

  # 流程历史
  flow_history:
    - flow_id: string                   # 流程ID
      flow_name: string                 # 流程名称
      start_time: datetime              # 开始时间
      end_time: datetime                # 结束时间（如果已完成）
      final_step: number                # 完成时的步骤
      status: string                    # 状态 (completed/interrupted/switched)

  # 全局任务
  global_tasks:
    - task_id: string                   # 任务ID
      title: string                     # 任务标题
      description: string               # 任务描述
      priority: string                  # 优先级 (high/medium/low)
      status: string                    # 状态 (todo/in-progress/done/blocked)
      assigned_to: string               # 负责人
      related_flows: string[]           # 关联的流程ID列表
      created_at: datetime              # 创建时间
      updated_at: datetime              # 更新时间
      due_date: datetime                # 截止日期（可选）

  # 上下文快照
  snapshots:
    - snapshot_id: string               # 快照ID
      created_at: datetime              # 创建时间
      description: string               # 快照描述
      state_ref: string                 # 关联的状态文件引用

  # 上下文有效期管理
  context_expiry:
    created_at: datetime                # 上下文创建时间
    last_activity: datetime             # 最后活动时间
    expiry_minutes: number              # 有效期（分钟），默认30
    is_expired: boolean                 # 是否已过期

  # 元数据
  metadata:
    version: string                     # 上下文版本
    skill_version: string               # Skill版本
    tags: string[]                      # 自定义标签
    notes: string                       # 备注信息
```

## 流程常量定义

### 可用流程
```yaml
flows:
  full:
    id: "full"
    name: "完整项目流程"
    description: "从零开始到上线的完整项目生命周期"
    steps: 9
    default_start: true

  iteration:
    id: "iteration"
    name: "需求迭代流程"
    description: "现有项目的功能迭代和优化"
    steps: 7

  design-review:
    id: "design-review"
    name: "设计评审流程"
    description: "架构设计和接口评审"
    steps: 7

  audit:
    id: "audit"
    name: "代码审计流程"
    description: "代码质量审查"
    steps: 7

  testing:
    id: "testing"
    name: "测试优化流程"
    description: "测试策略和用例优化"
    steps: 7

  docs:
    id: "docs"
    name: "文档完善流程"
    description: "技术文档和用户文档生成"
    steps: 7

  refactor:
    id: "refactor"
    name: "架构重构流程"
    description: "系统架构优化和技术债务清理"
    steps: 8
```

## 示例数据

```yaml
context:
  project_id: "PROJ-2024-001"
  project_name: "订单管理系统"
  created_at: "2024-05-15T10:00:00Z"
  updated_at: "2024-05-15T14:30:00Z"

  current_flow: "full"
  current_flow_name: "完整项目流程"
  current_step: 3
  flow_progress: 33

  flow_history:
    - flow_id: "full"
      flow_name: "完整项目流程"
      start_time: "2024-05-15T10:00:00Z"
      end_time: null
      final_step: 3
      status: "in-progress"

  global_tasks:
    - task_id: "GLOBAL-TASK-001"
      title: "搭建CI/CD流水线"
      description: "配置自动化构建和部署流程"
      priority: "high"
      status: "todo"
      assigned_to: "devops"
      related_flows: ["full", "iteration"]
      created_at: "2024-05-15T10:15:00Z"
      updated_at: "2024-05-15T10:15:00Z"

  snapshots:
    - snapshot_id: "SNAP-001"
      created_at: "2024-05-15T10:00:00Z"
      description: "项目初始化完成"
      state_ref: ".trae/reqplan/snapshots/snap-001.yaml"

  context_expiry:
    created_at: "2024-05-15T10:00:00Z"
    last_activity: "2024-05-15T14:30:00Z"
    expiry_minutes: 30
    is_expired: false

  metadata:
    version: "3.3"
    skill_version: "3.3"
    tags: ["ecommerce", "order-management"]
    notes: "这是一个示例项目"
```

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "Context Schema v3",
  "required": ["project_id", "project_name", "created_at", "updated_at", "current_flow", "current_step", "flow_progress", "metadata"],
  "properties": {
    "project_id": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "project_name": {
      "type": "string",
      "minLength": 1
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "updated_at": {
      "type": "string",
      "format": "date-time"
    },
    "current_flow": {
      "type": "string",
      "enum": ["full", "iteration", "design-review", "audit", "testing", "docs", "refactor"]
    },
    "current_flow_name": {
      "type": "string"
    },
    "current_step": {
      "type": "number",
      "minimum": 1
    },
    "flow_progress": {
      "type": "number",
      "minimum": 0,
      "maximum": 100
    },
    "flow_history": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["flow_id", "flow_name", "start_time", "status"],
        "properties": {
          "flow_id": { "type": "string" },
          "flow_name": { "type": "string" },
          "start_time": { "type": "string", "format": "date-time" },
          "end_time": { "type": "string", "format": "date-time" },
          "final_step": { "type": "number", "minimum": 1 },
          "status": { "type": "string", "enum": ["completed", "interrupted", "switched", "in-progress"] }
        }
      }
    },
    "global_tasks": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["task_id", "title", "description", "priority", "status", "assigned_to", "related_flows", "created_at", "updated_at"],
        "properties": {
          "task_id": { "type": "string" },
          "title": { "type": "string", "minLength": 1 },
          "description": { "type": "string" },
          "priority": { "type": "string", "enum": ["high", "medium", "low"] },
          "status": { "type": "string", "enum": ["todo", "in-progress", "done", "blocked"] },
          "assigned_to": { "type": "string" },
          "related_flows": { "type": "array", "items": { "type": "string" } },
          "created_at": { "type": "string", "format": "date-time" },
          "updated_at": { "type": "string", "format": "date-time" },
          "due_date": { "type": "string", "format": "date-time" }
        }
      }
    },
    "snapshots": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["snapshot_id", "created_at", "description", "state_ref"],
        "properties": {
          "snapshot_id": { "type": "string" },
          "created_at": { "type": "string", "format": "date-time" },
          "description": { "type": "string" },
          "state_ref": { "type": "string" }
        }
      }
    },
    "context_expiry": {
      "type": "object",
      "required": ["created_at", "last_activity", "expiry_minutes", "is_expired"],
      "properties": {
        "created_at": { "type": "string", "format": "date-time" },
        "last_activity": { "type": "string", "format": "date-time" },
        "expiry_minutes": { "type": "number", "minimum": 1, "default": 30 },
        "is_expired": { "type": "boolean" }
      }
    },
    "metadata": {
      "type": "object",
      "required": ["version", "skill_version"],
      "properties": {
        "version": { "type": "string", "pattern": "^\\d+\\.\\d+$" },
        "skill_version": { "type": "string", "pattern": "^\\d+\\.\\d+$" },
        "tags": { "type": "array", "items": { "type": "string" } },
        "notes": { "type": "string" }
      }
    }
  }
}
```

---

## 引用
- 4-schemas/schema-state.md
- 4-schemas/schema-task.md
- 3-core/core-context-tracker.md
