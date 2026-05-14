# Core State Management
# 状态管理核心模块

## 概述

状态管理模块负责管理ReqPlan的全局状态，包括项目状态、任务状态、进度追踪和上下文保持。

## Input

```yaml
- projectId: string           # 项目ID（必填）
- action: string              # 操作类型：get | set | update | reset | snapshot
- data?: object               # 更新数据（可选）
- options?: object            # 选项参数（可选）
```

### action类型说明

| action | 说明 | 参数要求 |
|------|------|----------|
| get | 获取状态 | projectId |
| set | 设置状态（覆盖） | projectId, data |
| update | 更新状态（合并） | projectId, data |
| reset | 重置状态 | projectId |
| snapshot | 创建快照 | projectId |

## Output

```yaml
- success: boolean           # 操作是否成功
- state: object              # 当前状态对象
- filePath: string          # 状态文件路径
- message: string           # 操作结果消息
- timestamp: string         # 操作时间戳
```

## 状态文件结构

### 目录结构
```
.trae/reqplan/projects/<projectId>/
├── config.yaml             # 项目配置
├── state.yaml              # 当前状态
├── state.backup.yaml       # 状态备份
└── requirements/
    └── <req-id>/
        ├── intent.md
        ├── req.md
        ├── design.md
        ├── plan.md
        └── verification/
```

### state.yaml格式

```yaml
# 项目信息
project: <project-name>
projectId: <project-id>
version: 3.1.0
created_at: <timestamp>
last_updated: <timestamp>

# 上下文有效期（完整策略参见 core-context-tracker.md）
context_expires_at: <timestamp>
current_user: <user-id>

# 当前阶段
current_phase: requirements | design | development | verification
current_requirement: <req-id>

# 进度追踪
progress:
  requirements: <percentage>      # 0-100
  design: <percentage>            # 0-100
  development: <percentage>       # 0-100
  verification: <percentage>      # 0-100
  overall: <percentage>           # 综合进度

# 需求列表
requirements:
  - id: <req-id>
    title: <req-title>
    description: <req-description>
    status: pending | active | completed | cancelled
    priority: P0 | P1 | P2
    created_at: <timestamp>
    updated_at: <timestamp>

# 任务列表（状态定义参见 core-task-management.md）
tasks:
  - id: <task-id>
    title: <task-title>
    description: <task-description>
    requirementId: <req-id>
    status: TODO | IN_PROGRESS | DONE | BLOCKED
    estimated_hours: <number>
    actual_hours: <number>
    assignee: <user-id>
    dependencies: [<task-id>]
    created_at: <timestamp>
    updated_at: <timestamp>
    due_date: <timestamp>

# 里程碑
milestones:
  - id: <milestone-id>
    title: <milestone-title>
    deadline: <timestamp>
    completed: boolean

# 配置
config:
  auto_save: true
  backup_interval: 300          # 备份间隔（秒）
  context_timeout: 1800         # 上下文超时（秒）
```

## 状态转换规则

### 阶段转换
```
requirements → design → development → verification → completed
     ↓            ↓            ↓             ↓
   ←────←────←────←────←────←────←────←────←
```

**转换条件**：
- `requirements → design`：需求文档已审核通过
- `design → development`：设计文档已审核通过
- `development → verification`：所有开发任务完成
- `verification → completed`：验收通过

### 任务状态转换
```
TODO → IN_PROGRESS → DONE
  ↓        ↓         ↓
BLOCKED ←──←────←──←
```

**转换条件**：
- `TODO → IN_PROGRESS`：任务开始执行
- `IN_PROGRESS → DONE`：任务完成
- `IN_PROGRESS → BLOCKED`：任务阻塞
- `BLOCKED → IN_PROGRESS`：阻塞解除
- `BLOCKED/TODO → DONE`：跳过执行（直接标记完成）

## 进度计算

### 需求阶段进度
```
requirements_progress = (已完成需求数 / 总需求数) * 100
```

### 设计阶段进度
```
design_progress = (已审核设计文档数 / 总需求数) * 100
```

### 开发阶段进度
```
development_progress = (已完成任务数 / 总任务数) * 100
```

### 验收阶段进度
```
verification_progress = (已验收任务数 / 总任务数) * 100
```

### 综合进度
```
overall_progress = 
  (requirements_weight * requirements_progress +
   design_weight * design_progress +
   development_weight * development_progress +
   verification_weight * verification_progress) / 100

默认权重：
- requirements_weight: 20
- design_weight: 20
- development_weight: 40
- verification_weight: 20
```

## 上下文保持（参见 core-context-tracker.md 完整策略）

- 状态文件中记录 `context_expires_at` 时间戳
- 上下文 TTL、刷新时机、过期恢复等完整策略由 core-context-tracker.md 统一定义
- `config.context_timeout` 已废弃，以 core-context-tracker.md 的三层 TTL 策略为准
```

## 快照机制

### 创建快照
```yaml
action: snapshot
options:
  reason: string    # 快照原因（可选）
  version: string   # 版本标识（可选）
```

### 快照文件结构
```
.trae/reqplan/projects/<projectId>/snapshots/
├── snapshot-20260514-100000.yaml
├── snapshot-20260514-110000.yaml
└── snapshot-20260514-120000.yaml
```

### 快照恢复
```yaml
action: restore
data:
  snapshotPath: string    # 快照文件路径
```

## 失败策略

### E701 - 状态文件损坏
```yaml
E701:
  error: "状态文件损坏"
  message: "检测到状态文件损坏，正在尝试恢复..."
  recovery:
    - 尝试从备份文件恢复
    - 如果备份也损坏，询问用户是否重新初始化
    - 提供手动恢复选项
```

### E702 - 项目未初始化
```yaml
E702:
  error: "项目未初始化"
  message: "项目尚未初始化，请先创建项目"
  recovery:
    - 提示用户使用 /reqplan start 创建新项目
    - 提供创建项目的流程
```

### E703 - 上下文过期
```yaml
E703:
  error: "上下文已过期"
  message: "您的会话已过期，请重新选择需求"
  recovery:
    - 列出最近的需求供用户选择
    - 提供创建新需求的选项
```

### E704 - 状态版本不兼容
```yaml
E704:
  error: "状态版本不兼容"
  message: "状态文件版本与当前版本不兼容"
  recovery:
    - 尝试自动升级状态文件
    - 如果升级失败，提示手动迁移
```

## 示例

### 示例1：获取状态
```yaml
Input:
- projectId: "my-project"
- action: "get"

Output:
- success: true
- state:
    project: "我的项目"
    current_phase: "development"
    progress:
      overall: 50
- message: "状态获取成功"
```

### 示例2：更新进度
```yaml
Input:
- projectId: "my-project"
- action: "update"
- data:
    current_phase: "verification"
    progress:
      development: 100
      verification: 0

Output:
- success: true
- message: "状态更新成功"
```

### 示例3：创建快照
```yaml
Input:
- projectId: "my-project"
- action: "snapshot"
- options:
    reason: "发布前备份"

Output:
- success: true
- filePath: ".trae/reqplan/projects/my-project/snapshots/snapshot-20260514-100000.yaml"
- message: "快照创建成功"
```

## 状态锁机制（v3.2新增）

### 问题背景
多会话并发操作同一项目时，可能出现写入覆盖导致的数据丢失：
```
会话A: 更新需求 → 写入 state.yaml      会话B: 更新任务 → 写入 state.yaml
       ↓                                    ↓
  写入成功（版本X）                      写入成功（版本X，覆盖了A的更新）
```

### 锁文件协议
```yaml
# 锁文件位置: .trae/reqplan/projects/<projectId>/state.lock
# 详细数据结构见: 4-schemas/schema-state-lock.md

锁操作三步法:
  /reqplan lock acquire [--description "<操作说明>"]
  # 执行操作（读取 → 修改 → 写入）
  /reqplan lock release [--force]

  # 查看锁状态
  /reqplan lock status

  # 强制获取（仅在确认旧会话已断开时使用）
  /reqplan lock acquire --force
```

### state.yaml 锁相关字段
```yaml
# 在 state.yaml 中新增的锁字段
state_version: 3                   # 状态模型版本号
lock_version: 5                    # 乐观锁版本号
lock_status: "locked" | "unlocked" | "stale"
last_lock_session: "session-abc123"
last_lock_time: "2026-05-14T10:30:00Z"
```

### 写入流程（加锁版）
```yaml
# 所有写操作必须遵循以下流程
1. acquire_lock → 获取锁
2. 读取 state.yaml，记录 lock_version（记为 V）
3. 执行修改
4. 检查 lock_version 是否仍是 V（未被其他会话修改）
5. 是 → 写入 state.yaml，设置 lock_version = V+1
6. 否 → 返回 E802 版本冲突，提示重新读取
7. release_lock → 释放锁
```

### 并发错误处理

#### E801 - 锁被占用
```yaml
E801:
  error: "状态锁被占用"
  message: "当前项目状态锁已被其他会话持有"
  recovery:
    - 提示持有者和剩余时间
    - 提供等待选项
    - 提供强制获取选项（/reqplan lock acquire --force）
```

#### E802 - 版本冲突
```yaml
E802:
  error: "状态版本冲突"
  message: "自读取后状态已被其他会话修改，无法提交"
  recovery:
    - 重新读取最新状态
    - 手动合并变更
    - 重新获取锁后再次尝试
```

### 自动锁清理
- 锁持有超过 max_hold_time（默认10分钟）自动标记为 stale
- 跨会话恢复时自动检查并清理脏锁
- 每次成功写入后自动释放锁

## 最佳实践

1. **定期备份**：建议每5分钟自动备份一次状态
2. **事务性更新**：确保状态更新的原子性（获取锁 → 读取 → 修改 → 写入 → 释放锁）
3. **上下文管理**：及时清理过期的上下文
4. **版本兼容**：处理不同版本的状态文件
5. **错误恢复**：提供清晰的错误信息和恢复路径
6. **锁规范（v3.2）**：长操作间拆为"预检 → 操作 → 提交"三步，减少锁持有时间

## 版本信息

**版本**: 3.2.0
**更新时间**: 2026-05-14
**引用**: 4-schemas/schema-state.md, 4-schemas/schema-context.md, 4-schemas/schema-state-lock.md, 3-core/core-context-tracker.md
