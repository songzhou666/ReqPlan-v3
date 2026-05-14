# State Lock Schema (v1)
# 状态锁数据结构

## 概述
定义 ReqPlan-v3 的状态锁（State Lock）数据结构，用于防止多会话并发写入导致的状态不一致。

## 问题背景
```
场景：用户在会话A和会话B中同时操作同一个项目

会话A: 更新需求 → 写入 state.yaml      会话B: 更新任务 → 写入 state.yaml
              ↓                                    ↓
        写入成功（版本X）                      写入成功（版本X，覆盖了A的更新）
              ↓                                    ↓
         ❌ A的更新丢失                    ✅ B的更新存在
```

状态锁机制通过**乐观锁 + 锁文件**的组合策略解决此问题。

## 锁数据结构

### 锁文件 (.lock)
```yaml
# .trae/reqplan/projects/<projectId>/state.lock
lock:
  status: "locked" | "unlocked" | "stale"
  
  # 当前持有者
  holder:
    session_id: string              # 会话ID
    user_id: string                 # 用户标识
    acquired_at: datetime           # 获取锁的时间
    expires_at: datetime            # 锁自动过期时间

  # 操作信息
  operation:
    type: string                    # 操作类型 (update/snapshot/reset/sync)
    target: string                  # 操作目标 (state/requirements/tasks/config)
    description: string             # 操作描述

  # 统计
  stats:
    acquired_count: number          # 累计获取次数
    last_released_at: datetime      # 最近释放时间
    contention_count: number        # 冲突次数
```

### state.yaml 中的版本字段
```yaml
# 在 state.yaml 中新增以下字段
# 版本管理
state_version: 3
lock_version: 5                    # 乐观锁版本号（每次写入+1）
lock_status: "locked" | "unlocked" | "stale"
last_lock_session: string          # 最近锁持有会话ID
last_lock_time: datetime           # 最近锁获取时间
```

## 锁操作协议

### 获取锁 (Acquire)
```yaml
action: acquire_lock
流程:
  1. 检查 lock 文件是否存在
  2. 如果不存在 → 创建 lock 文件，标记 locked
  3. 如果存在且 unlocked → 更新为 locked，记录 holder
  4. 如果存在且 locked:
     4.1 检查 holder.expires_at 是否过期
     4.2 如果过期 → 标记为 stale，重新获取（清除原holder）
     4.3 如果未过期 → 拒绝获取，提示"其他会话正在操作"

  获取成功条件:
    - 锁文件中 status = locked
    - holder.session_id = 当前会话ID
    - lock_version 已读取

  获取失败策略:
    - 返回 "E801: 锁已被 {holder.session_id} 持有"
    - 提供强制获取选项（会中断其他会话）
```

### 释放锁 (Release)
```yaml
action: release_lock
流程:
  1. 验证当前会话是否持有锁
  2. 如果有 pending 写入，先完成写入
  3. 更新 lock_version
  4. 设置 status = unlocked
  5. 清除 holder 信息
  6. 记录释放时间

  释放时机:
    - 写入操作完成后自动释放
    - 会话结束时（检测到会话断开）
    - 用户手动输入 /reqplan lock release
    - 锁持有超过 max_hold_time（默认10分钟）
```

### 写入时校验 (Write Validation)
```yaml
action: write_with_lock
流程:
  1. 读取 state.yaml 的 lock_version（记为 version_read）
  2. 读取 lock 文件的 status 和 holder
  3. 校验:
     3.1 status = locked and holder.session_id = 当前会话 → 允许写入
     3.2 否则 → 拒绝写入，提示"未持有锁"
  4. 写入 state.yaml 时，设置 lock_version = version_read + 1
  5. 写入成功后，释放锁

  并发写入冲突检测:
    - 写入前检查 lock_version 是否变化
    - 如果变化（其他会话已更新），说明本会话持有的版本已过时
    - 返回 "E802: 版本冲突，请重新读取后重试"
```

### 强制获取 (Force Acquire)
```yaml
action: force_acquire_lock
流程:
  1. 检查当前锁持有者的 expires_at
  2. 如果已过期 → 接管锁（更新 holder）
  3. 如果未过期:
     3.1 记录 contention_count + 1
     3.2 提示用户"当前锁由 {holder} 持有，强制获取将中断其操作"
     3.3 用户确认后
     3.4 设置 status = stale
     3.5 创建锁文件备份: state.lock.backup.<timestamp>
     3.6 重新获取锁（更新 holder 为当前会话）

  风险:
    - 强制获取可能导致其他会话的写入丢失
    - 仅建议在"确认其他会话已断开"时使用
```

## 锁状态机
```yaml
状态转换图:

  [初始化] → unlocked
  unlocked → locked    (acquire_lock)
  locked → unlocked    (release_lock)
  locked → stale       (force acquire / 超时)
  stale → unlocked     (锁清理)
  stale → locked       (强制获取后接管)

状态说明:
  unlocked: 无会话持有锁，可正常获取
  locked:   有会话持有锁，正在写入
  stale:    锁持有者已断开或超时，可被接管
```

## 锁超时配置
```yaml
config:
  # 锁超时设置
  lock:
    default_hold_time: 300          # 默认持有时间（秒）= 5分钟
    max_hold_time: 600              # 最大持有时间（秒）= 10分钟
    acquire_retry_interval: 5       # 获取重试间隔（秒）
    max_acquire_retries: 3          # 最大重试次数
    stale_check_interval: 60        # 脏锁检查间隔（秒）

  # 自动清理
  cleanup:
    stale_lock_cleanup: true        # 是否自动清理脏锁
    stale_lock_threshold: 900       # 脏锁清理阈值（秒）= 15分钟
```

## 锁文件目录结构
```yaml
.trae/reqplan/projects/<projectId>/
├── state.yaml              # 当前状态
├── state.lock              # 锁文件
├── state.lock.backup.*     # 锁文件备份（强制获取时创建）
├── state.backup.yaml       # 状态文件备份
└── snapshots/
    └── ...                 # 快照目录
```

## 示例

### 正常流程
```yaml
# 会话A 获取锁
→ /reqplan task update TASK-001 --status DONE
action: acquire_lock
result: success (holder: session-A)

# 会话A 写入状态
action: write_with_lock
写入前 lock_version: 5
写入后 lock_version: 6

# 会话A 释放锁
action: release_lock
result: success (status: unlocked, lock_version: 4)
```

### 冲突场景
```yaml
# 会话A 持有锁
lock.status: locked
lock.holder.session_id: session-A

# 会话B 尝试获取锁
→ /reqplan task update TASK-002 --status IN_PROGRESS
action: acquire_lock
result: failed
error: "E801: 锁已被 session-A 持有（剩余时间：4分32秒）"
suggestion: 
  - 等待锁释放
  - 输入 /reqplan lock force 强制获取
```

### 脏锁恢复
```yaml
# 会话A 异常断开，锁未释放
lock.status: locked
lock.holder.session_id: session-A
lock.holder.expires_at: 2026-05-14T10:05:00Z  # 已过期

# 会话B 尝试获取
action: acquire_lock
检测到锁已过期（stale）
自动清理脏锁
result: success (holder: session-B)
notification: "已清理来自 session-A 的脏锁（会话已断开）"
```

## JSON Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "State Lock Schema v1",
  "required": ["lock"],
  "properties": {
    "lock": {
      "type": "object",
      "required": ["status", "holder", "stats"],
      "properties": {
        "status": {
          "type": "string",
          "enum": ["locked", "unlocked", "stale"]
        },
        "holder": {
          "type": "object",
          "required": ["session_id", "acquired_at", "expires_at"],
          "properties": {
            "session_id": { "type": "string" },
            "user_id": { "type": "string" },
            "acquired_at": { "type": "string", "format": "date-time" },
            "expires_at": { "type": "string", "format": "date-time" }
          }
        },
        "operation": {
          "type": "object",
          "properties": {
            "type": {
              "type": "string",
              "enum": ["update", "snapshot", "reset", "sync"]
            },
            "target": { "type": "string" },
            "description": { "type": "string" }
          }
        },
        "stats": {
          "type": "object",
          "required": ["acquired_count", "contention_count"],
          "properties": {
            "acquired_count": { "type": "integer", "minimum": 0 },
            "last_released_at": { "type": "string", "format": "date-time" },
            "contention_count": { "type": "integer", "minimum": 0 }
          }
        }
      }
    }
  }
}
```

## 引用
- 3-core/core-state-management.md
- 3-core/core-context-tracker.md
- 4-schemas/schema-state.md
