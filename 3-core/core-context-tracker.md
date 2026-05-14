# Core Context Tracker
# 上下文追踪核心模块 (v3.2)

## 职责
- 多层级上下文管理（全局/项目/会话）
- 上下文生命周期与过期策略
- 跨会话恢复与桥接
- 上下文收敛与溢出管理
- 决策日志记录与追溯
- 全局任务机制关联

## 数据结构
引用: 4-schemas/schema-context.md, 4-schemas/schema-state.md, 4-schemas/schema-writeback.md

## 上下文层级体系

### 三层模型
ReqPlan 的上下文分为三个层级，每层独立拥有生命周期：

```
Global Context （全局）
  └── Project Context （项目）
       └── Session Context （会话）
```

| 层级 | 范围 | 存储位置 | 有效期 |
|------|------|---------|--------|
| 全局 | 跨项目、跨用户 | `.trae/reqplan/global-context.yaml` | 永久 |
| 项目 | 单个项目内 | `.trae/reqplan/projects/<projectId>/state.yaml` | 项目生命周期 |
| 会话 | 单次对话 | 内存 + `context_expires_at` | 默认30分钟 |

### 全局上下文
```yaml
# .trae/reqplan/global-context.yaml
global_context:
  last_project_id: string           # 最近使用的项目
  project_history:                  # 项目访问历史（最多10条）
    - projectId: string
      last_accessed: datetime
      current_flow: string
      overall_progress: number
  skill_version: string
  last_upgrade_check: datetime      # 版本升级检查时间
```

### 项目上下文（扩展自 state.yaml）
```yaml
# 在 state.yaml 中扩展以下字段
context:
  # 上下文有效期管理
  expiry:
    created_at: datetime
    last_activity: datetime
    expiry_minutes: 30
    is_expired: boolean
    expiry_action: "warn" | "restore" | "reset"
    # warn   = 仅警告，保留全部状态
    # restore = 保留项目级状态，清空会话级细节
    # reset   = 重置为初始状态

  # 决策日志
  decision_log:
    - timestamp: datetime
      decision: string               # 决策内容
      context: string                # 决策背景
      alternatives: string[]         # 备选方案
      chosen: string                 # 最终选择
      reason: string                 # 选择理由

  # 上下文收敛
  convergence:
    last_compacted: datetime         # 最近一次收敛压缩
    compaction_count: number         # 收敛次数
    overflow_threshold: 100          # 触发收敛的记录数阈值
```

### 会话上下文（运行时内存）
```yaml
# 不持久化，仅 LLM 运行时维护
session_context:
  session_id: string
  started_at: datetime
  last_activity: datetime
  conversation_turns: number        # 对话轮次计数
  active_flow: string               # 当前对话激活的流程
  pending_decisions:                # 待确认的决策
    - question: string
      options: string[]
      expires_at: datetime
  recent_actions: string[]          # 本会话最近执行的操作（最多20条）
  context_size_estimate: number     # 上下文大小估算（token数）
```

## 上下文有效期管理

### 有效期计算规则
```yaml
TTL 策略：
  默认有效期: 30 分钟（1800秒）
  最大有效期: 24 小时
  最短有效期: 5 分钟

  延长规则:
    - 用户输入命令时 → 全额续期（+30分钟）
    - 完成一个流程步骤 → 全额续期
    - 上下文内活动 → 每轮对话 +15分钟，不超过最大有效期

  降级规则:
    - 无活动10分钟 → 降级为"低活跃"状态
    - 低活跃状态下再10分钟 → 标记为"过期"
    - 过期后状态保留，但会话细节被收敛

  过期动作执行序列:
    1. 标记 context_expiry.is_expired = true
    2. 根据 expiry_action 执行对应策略
    3. 在恢复时提示用户上下文状态
    4. 记录过期事件到 decision_log
```

### 过期状态处理
```yaml
# 上下文过期时，系统行为：
E703 (上下文过期):
  症状: context_expiry.is_expired = true

  恢复流程:
    1. 读取 state.yaml 中的项目级上下文
    2. 读取 global_context.yaml 中的项目历史
    3. 向用户展示上下文摘要：
       """
       📋 恢复会话：
       ├── 项目：订单管理系统
       ├── 上次活动：1小时前
       ├── 当前流程：完整项目流程（步骤3/9）
       ├── 最近决策：选择了Spring Boot技术栈
       └── 待办任务：3个（P0:1, P1:2）

       是否继续上次工作？
       [1] 继续（推荐）
       [2] 查看最近操作
       [3] 重新开始
       """
    4. 用户选择后更新 last_activity

  收敛策略:
    - 过期后，会话级细节被收敛为摘要
    - 收拢后的数据量减少约 70%
    - 保留所有决策日志和状态变更记录
```

### 上下文恢复流程 (跨会话恢复协议)
```yaml
# 当用户在新会话中触发 ReqPlan 时
Cross-Session Recovery Protocol:

  阶段1: 检测
    1. 读取 global_context.yaml 获取 last_project_id
    2. 读取 projects/<projectId>/state.yaml
    3. 检查 context_expiry.is_expired
    4. 比较 last_updated 与当前时间

  阶段2: 重建
    1. 如果未过期 → 直接恢复全部上下文
    2. 如果已过期但未超24h → 恢复摘要上下文
    3. 如果已超24h → 重置会话，保留项目状态

  阶段3: 验证
    1. 验证 state.yaml 完整性（Hash校验）
    2. 验证锁状态（检查是否有未释放的锁）
    3. 验证决策日志连续性
    4. 报告恢复状态给用户

  阶段4: 确认
    1. 向用户展示恢复摘要
    2. 确认用户是否接受
    3. 如果不接受，提供"重新开始"选项
    4. 记录恢复事件到 decision_log

  # 恢复消息示例:
  """
  🔄 跨会话恢复完成
  ├── 项目：订单管理系统
  ├── 恢复模式：摘要恢复（上次会话已过期）
  ├── 流程进度：完整项目流程 步骤3/9
  ├── 关键决策：已记录2条
  └── 一致性校验：通过 ✅

  从 [设计评审] 步骤继续
  """
```

## 上下文收敛机制

### 触发条件
```yaml
收敛触发条件（任一满足即触发）:
  1. decision_log 条目数超过 overflow_threshold（默认100条）
  2. context_size_estimate 超过阈值（默认4000 token）
  3. flow_history 中包含超过 20 次流程切换
  4. 手动触发: /reqplan context compact
```

### 收敛策略
```yaml
收敛四步法:

  步骤1: 分类
    - 高价值记录: 决策日志、里程碑达成、状态变更
    - 中价值记录: 流程切换、任务状态更新
    - 低价值记录: 用户确认、中间性选择

  步骤2: 压缩
    - 高价值: 保留完整内容
    - 中价值: 压缩为摘要（保留时间戳+结果）
    - 低价值: 合并为计数统计

  步骤3: 聚合
    示例输出:
    """
    [收敛摘要]
    流程执行记录：full 流程执行中，切换3次子流程
    关键决策：5条（已保留详情）
    任务管理：3个全局任务（2完成/1进行中）
    用户确认：12次确认操作（已合并）
    """

  步骤4: 归档
    - 被收敛的原始记录移动到归档文件:
      `.trae/reqplan/projects/<projectId>/archive/context-<date>.yaml`
    - 收敛后的记录压缩到 state.yaml 中
    - 记录收敛事件到 decision_log
```

### 收敛后数据完整性
```
收敛不应该丢失任何决策的可追溯性。
每次收敛后，被压缩的记录可通过归档文件回溯。
用户可通过 /reqplan history --detail 查看归档历史。
```

## 决策日志

### 记录时机
```yaml
需要记录决策的场景:
  - 技术选型（如"选择Spring Boot而非Quarkus"）
  - 架构决策（如"使用微服务而非单体"）
  - 范围决策（如"推迟用户权限模块到v2"）
  - 优先级决策（如"将登录功能提升为P0"）
  - 流程决策（如"从完整项目切换到设计评审"）
```

### 记录格式
```yaml
decision:
  timestamp: "2026-05-15T14:30:00Z"
  decision: "选择Spring Boot作为后端框架"
  context: "需要快速开发REST API，团队熟悉Java生态"
  alternatives:
    - "Quarkus - 启动快但生态不够成熟"
    - "Node.js - 团队不熟悉"
  chosen: "Spring Boot 3.x"
  reason: "团队经验最丰富，生态最完善，满足性能需求"
  impact: "开发效率提升30%，但启动时间比Quarkus慢2s"
  author: "架构师"
  status: "confirmed"          # proposed | confirmed | superseded
  superseded_by: null          # 如果被新决策覆盖，指向新决策ID
```

## 上下文大小估算

### Token估算规则
```yaml
# 用于判断是否需要收敛
context_size_estimate:
  每轮对话: ~200 tokens
  每个决策日志: ~80 tokens  
  每个全局任务: ~100 tokens
  每个流程步骤: ~50 tokens
  状态文件元数据: ~300 tokens base

  计算: base + conversation_turns * 200 + decisions * 80 + tasks * 100 + steps * 50
  警告阈值: 3000 tokens
  收敛阈值: 4000 tokens
  紧急阈值: 5000 tokens（强制收敛）
```

### Token预算分配
```yaml
# 当需要精打细算上下文时
budget_allocation:
  # 优先级由高到低
  priority_1: "当前流程状态和下一步"     # 30% 预算
  priority_2: "活跃的全局任务"            # 20% 预算
  priority_3: "最近的决策日志（10条）"     # 20% 预算
  priority_4: "项目元信息"                # 15% 预算
  priority_5: "历史流程记录（摘要）"        # 10% 预算
  budget_reserve: 5%                     # 预留buffer
```

## 全局任务关联

### 跨会话任务同步
```yaml
# 当全局任务在跨会话场景下更新时
task_sync_protocol:
  1. 更新任务状态时，同时更新 state.yaml 中的对应任务
  2. 记录变更到 decision_log
  3. 如果任务有关联的其他流程，标记这些流程为"需刷新"
  4. 当前会话恢复时，检查"需刷新"标记并提示用户

  # 提示示例:
  """
  🔔 任务状态更新提示
  任务 TASK-002「实现用户注册」状态已变更为 DONE
  该任务关联的流程: [需求迭代]
  流程「需求迭代」需要刷新状态。
  """
```

## 引导信息

### 上下文提示模板
```yaml
# 正常状态
"""
📋 当前上下文（会话已保持25分钟）：
├── 项目：订单管理系统
├── 流程：完整项目流程（子流程: 设计评审）
├── 阶段：设计评审 - 问题识别（步骤2/7）
├── 决策待确认：1条
├── 全局任务：3个（P0:1, P1:1, P2:1）
├── 上下文健康度：良好（1200/4000 tokens）
└── 最后活动：2分钟前
"""

# 低活跃状态
"""
📋 当前上下文（低活跃 - 12分钟未活动）：
├── 项目：订单管理系统
├── 流程：设计评审
├── ⏰ 上下文将于约18分钟后过期
└── 输入任意命令续期
"""

# 已过期恢复
"""
📋 上下文已恢复（上次会话已过期）
├── 项目：订单管理系统
├── 恢复模式：摘要恢复
├── 收敛记录：已压缩5条低价值记录
├── 已归档：10条旧记录（可查看 /reqplan history --detail）
└── 上次活动：45分钟前
"""
```

### 下一步智能建议
```yaml
"""
📌 基于上下文的下一步建议：
1️⃣ 继续当前流程 → "/reqplan guide"（推荐）
2️⃣ 查看全局任务 → "/reqplan task list"
3️⃣ 查看决策日志 → "/reqplan context decisions"
4️⃣ 手动收敛上下文 → "/reqplan context compact"
5️⃣ 创建上下文快照 → "/reqplan context snapshot"
6️⃣ 切换流程 → "/reqplan flow list"
"""
```

## 上下文命令
```yaml
# 上下文管理专用命令
/reqplan context status         # 查看上下文状态和健康度
/reqplan context decisions      # 查看决策日志
/reqplan context compact        # 手动触发上下文收敛
/reqplan context snapshot       # 创建上下文快照
/reqplan context history        # 查看上下文历史
/reqplan context restore <id>   # 恢复到指定快照
/reqplan context archive_list   # 查看归档记录
```

## 失败策略

### E703 - 上下文过期
```yaml
E703 (上下文过期):
  error: "上下文已过期"
  message: "当前会话上下文已过期，正在执行恢复流程"
  
  recovery:
    - 读取 global_context.yaml 恢复项目级上下文
    - 计算过期时长（<24h 摘要恢复 / >24h 项目级仅保留状态）
    - 执行收敛策略（如果上次会话有大量记录）
    - 验证 state.yaml 完整性
    - 向用户展示恢复摘要
    - 记录恢复事件到 decision_log

  prevention:
    - 最后活动前5分钟提示即将过期
    - 提供立即续期选项
```

### E803 - 状态追溯失败
```yaml
E803 (状态追溯失败):
  error: "状态无法追溯"
  message: "无法从 context_expires_at 推导完整上下文链"

  recovery:
    1. 尝试从最近的 context snapshot 恢复
    2. 如果无快照，从 state.yaml 的基础字段重建
    3. 如果 state.yaml 也损坏，执行 E701 恢复流程
    4. 清除不完整的会话数据
    5. 提示用户必要信息需要重新提供

  fallback:
    - 保留项目名称和当前阶段
    - 重置上下文过期时间
    - 提示用户"部分上下文丢失，请确认当前状态"
```

### E804 - 收敛失败
```yaml
E804 (收敛失败):
  error: "上下文收敛失败"
  message: "收敛过程中出现异常，上下文处于不一致状态"

  recovery:
    1. 中止当前收敛
    2. 从最近快照恢复收敛前状态
    3. 检查 archive 目录是否可写
    4. 缩小收敛范围（仅压缩决策日志）
    5. 记录收敛失败原因到日志

  prevention:
    - 收敛前自动创建快照
    - 收敛操作带有截止时间（超过30秒中止）
```

## 版本信息
**版本**: 3.2.0
**更新时间**: 2026-05-14
**引用**: 4-schemas/schema-context.md, 4-schemas/schema-state.md, 4-schemas/schema-state-lock.md, 4-schemas/schema-writeback.md, 3-core/core-state-management.md, 3-core/core-actions.md
