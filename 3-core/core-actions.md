# Core Actions
# Action 接口规范 (v1)

## 职责
- 定义 ReqPlan 所有可执行操作的标准化接口
- 规范每个 Action 的输入/输出/错误处理契约
- 为后续从纯 prompt 模式升级为可执行模式奠定基础
- 提供 Action 生命周期管理和注册机制

## Action 生命周期

### 五阶段模型
```
  [注册] → [路由] → [前置校验] → [执行] → [后置处理]
                                          ↓
                                     [失败回滚]
```

| 阶段 | 说明 | 当前实现 |
|------|------|---------|
| 注册 | Action 在注册表中声明签名 | prompt 中硬编码 |
| 路由 | 根据命令/意图匹配到对应 Action | prompt 匹配 |
| 前置校验 | 检查输入参数/锁状态/权限 | 无 |
| 执行 | 执行具体逻辑 | LLM 生成文本响应 |
| 后置处理 | 更新状态/写回/通知 | prompt 指引 |
| 失败回滚 | 异常时回滚到安全状态 | 无（依靠用户手动恢复） |

### 行动宣言
将 Action 从"隐式 prompt 片段"升级为"显式接口契约"。
每个 Action 必须有明确的 I/O 定义、边界条件和失败策略。

## Action 注册表

### 注册格式
```yaml
actions:
  <action_name>:
    id: string                  # Action 唯一标识（kebab-case）
    name: string                 # 人类可读名称
    version: string              # 版本号
    description: string          # 功能描述
    
    # 触发条件
    triggers:
      - type: "command"         # 命令触发
        pattern: "/reqplan <command>"  # 命令格式
      - type: "nlp"             # 自然语言触发
        keywords: string[]      # 触发词列表
    
    # 接口定义
    interface:
      input: schema              # 输入参数 Schema（引用）
      output: schema             # 输出结果 Schema（引用）
      error: error_schema        # 错误码列表
    
    # 执行约束
    constraints:
      requires_lock: boolean     # 是否需要状态锁
      requires_flow: string      # 需要处于的流程（可选）
      idempotent: boolean        # 是否幂等
      max_duration: number       # 最大执行时间（秒）
    
    # 后置处理
    post_actions:
      - "writeback"              # 结果回写
      - "update_state"           # 更新状态
      - "notify_user"            # 通知用户
    
    # 依赖
    depends_on: string[]         # 依赖的其他 Action
```

### 完整 Action 列表

#### 1. init — 项目初始化
```yaml
init:
  name: "项目初始化"
  version: "1.0.0"
  description: "创建项目 Harness 目录结构"
  
  triggers:
    - type: command
      pattern: "/reqplan init"
    - type: nlp
      keywords: ["初始化项目", "创建项目", "开始新项目"]
  
  interface:
    input:
      $ref: "#/definitions/InitInput"
    output:
      $ref: "#/definitions/InitOutput"
  
  constraints:
    requires_lock: false        # 初始化时还没有锁
    requires_flow: null
    idempotent: true
    max_duration: 30
    harness_levels: ["S", "L", "M", "H"]

  post_actions:
    - "update_state"
    - "notify_user"
```

#### 2. start — 流程启动
```yaml
start:
  name: "启动流程引导"
  version: "1.0.0"
  description: "启动引导流程，让用户选择或进入指定流程"
  
  triggers:
    - type: command
      pattern: "/reqplan start [--flow <flow_name>] [--resume]"
    - type: nlp
      keywords: ["开始", "启动", "创建", "引导我"]
  
  interface:
    input:
      $ref: "#/definitions/StartInput"
    output:
      $ref: "#/definitions/StartOutput"
  
  constraints:
    requires_lock: true
    requires_flow: null
    idempotent: false
    max_duration: 60
    harness_levels: ["L", "M", "H"]

  post_actions:
    - "writeback"
    - "update_state"
    - "notify_user"
```

#### 3. plan — 计划制定
```yaml
plan:
  name: "计划制定"
  version: "1.0.0"
  description: "基于意图分析结果生成行动计划，包含 scope 界定、entryPoints 识别、component 分解、5层验证方案"
  
  triggers:
    - type: command
      pattern: "/reqplan plan [--force]"
    - type: nlp
      keywords: ["制定计划", "规划", "行动计划", "怎么做"]
  
  interface:
    input:
      $ref: "#/definitions/PlanInput"
    output:
      $ref: "#/definitions/PlanOutput"
  
  constraints:
    requires_lock: true
    requires_flow: true
    idempotent: false
    max_duration: 120
    harness_levels: ["L", "M", "H"]
  
  pre_actions:
    - "已完成意图分析（intent）"
    - "确保 scope 与 intent 一致"
  
  post_actions:
    - "writeback"
    - "update_state"
    - "notify_user"
```

#### 4. flow — 流程管理
```yaml
flow:
  name: "流程管理"
  version: "1.0.0"
  description: "列出/切换/查看当前流程"
  
  triggers:
    - type: command
      pattern: "/reqplan flow list | flow switch <id> | flow current"
    - type: nlp
      keywords: ["切换流程", "看看流程", "当前流程"]
  
  interface:
    input:
      $ref: "#/definitions/FlowInput"
    output:
      $ref: "#/definitions/FlowOutput"
  
  constraints:
    requires_lock: false
    requires_flow: null
    idempotent: true
    max_duration: 15
    harness_levels: ["L", "M", "H"]

  post_actions:
    - "update_state"
    - "notify_user"
```

#### 5. guide — 智能引导
```yaml
guide:
  name: "智能引导"
  version: "1.0.0"
  description: "基于当前上下文推荐下一步操作"
  
  triggers:
    - type: command
      pattern: "/reqplan guide"
    - type: nlp
      keywords: ["下一步", "该做什么", "引导我", "然后呢"]
  
  interface:
    input:
      $ref: "#/definitions/GuideInput"
    output:
      $ref: "#/definitions/GuideOutput"
  
  constraints:
    requires_lock: false
    requires_flow: null
    idempotent: true
    max_duration: 15
    harness_levels: ["S", "L", "M", "H"]

  post_actions:
    - "notify_user"
```

#### 6. intent — 意图分析
```yaml
intent:
  name: "意图分析"
  version: "1.0.0"
  description: "分析用户输入，识别真实意图，匹配最佳流程"
  
  triggers:
    - type: command
      pattern: "/reqplan intent <文本>"
    - type: nlp
      keywords: ["帮我分析", "检查", "看看", "审计", "评审", "重构"]
  
  interface:
    input:
      $ref: "#/definitions/IntentInput"
    output:
      $ref: "#/definitions/IntentOutput"
  
  constraints:
    requires_lock: false
    requires_flow: null
    idempotent: true
    max_duration: 20
    harness_levels: ["S", "L", "M", "H"]

  post_actions:
    - "update_state"
    - "notify_user"
```

#### 7. status — 状态查看
```yaml
status:
  name: "状态查看"
  version: "1.0.0"
  description: "查看当前项目/流程/任务状态"
  
  triggers:
    - type: command
      pattern: "/reqplan status [--detail] [--flow <flow_name>]"
    - type: nlp
      keywords: ["当前状态", "进度", "怎么样了"]
  
  interface:
    input:
      $ref: "#/definitions/StatusInput"
    output:
      $ref: "#/definitions/StatusOutput"
  
  constraints:
    requires_lock: false
    requires_flow: null
    idempotent: true
    max_duration: 10
    harness_levels: ["S", "L", "M", "H"]

  post_actions:
    - "notify_user"
```

#### 8. task — 任务管理
```yaml
task:
  name: "任务管理"
  version: "1.0.0"
  description: "创建/查看/更新/删除任务"
  
  triggers:
    - type: command
      pattern: "/reqplan task list | task create | task update <id> | task delete <id>"
    - type: nlp
      keywords: ["任务", "待办", "分配", "创建任务"]
  
  interface:
    input:
      $ref: "#/definitions/TaskInput"
    output:
      $ref: "#/definitions/TaskOutput"
  
  constraints:
    requires_lock: true
    requires_flow: null
    idempotent: true
    max_duration: 20
    harness_levels: ["L", "M", "H"]

  post_actions:
    - "writeback"
    - "update_state"
    - "notify_user"
```

#### 9. sync — 文件同步
```yaml
sync:
  name: "文件同步"
  version: "1.0.0"
  description: "检测文件变化，分析影响，执行同步"
  
  triggers:
    - type: command
      pattern: "/reqplan sync [--dry-run]"
    - type: nlp
      keywords: ["同步", "文件变化", "检查变化"]
  
  interface:
    input:
      $ref: "#/definitions/SyncInput"
    output:
      $ref: "#/definitions/SyncOutput"
  
  constraints:
    requires_lock: true
    requires_flow: null
    idempotent: false
    max_duration: 30
    harness_levels: ["L", "M", "H"]

  post_actions:
    - "writeback"
    - "update_state"
    - "notify_user"
```

#### 10. history — 历史查看
```yaml
history:
  name: "流程历史"
  version: "1.0.0"
  description: "查看流程执行历史、决策日志"
  
  triggers:
    - type: command
      pattern: "/reqplan history [--detail] [--flow <flow_name>]"
    - type: nlp
      keywords: ["历史", "之前", "记录", "回顾"]
  
  interface:
    input:
      $ref: "#/definitions/HistoryInput"
    output:
      $ref: "#/definitions/HistoryOutput"
  
  constraints:
    requires_lock: false
    requires_flow: null
    idempotent: true
    max_duration: 10
    harness_levels: ["L", "M", "H"]

  post_actions:
    - "notify_user"
```

#### 11. context — 上下文管理
```yaml
context:
  name: "上下文管理"
  version: "1.0.0"
  description: "管理上下文：查看/收敛/快照/恢复"
  
  triggers:
    - type: command
      pattern: "/reqplan context status | decisions | compact | snapshot | restore <id>"
  
  interface:
    input:
      $ref: "#/definitions/ContextInput"
    output:
      $ref: "#/definitions/ContextOutput"
  
  constraints:
    requires_lock: true          # 写操作（compact/snapshot）需要锁
    requires_flow: null
    idempotent: false
    max_duration: 30
    harness_levels: ["L", "M", "H"]

  post_actions:
    - "update_state"            # compact 和 snapshot 时
    - "notify_user"
```

#### 12. lock — 状态锁管理
```yaml
lock:
  name: "状态锁管理"
  version: "1.0.0"
  description: "管理状态锁：获取/释放/查看/强制获取"
  
  triggers:
    - type: command
      pattern: "/reqplan lock acquire | release | status | acquire --force"
  
  interface:
    input:
      $ref: "#/definitions/LockInput"
    output:
      $ref: "#/definitions/LockOutput"
  
  constraints:
    requires_lock: false         # 锁管理操作自身不需要锁
    requires_flow: null
    idempotent: false
    max_duration: 10
    harness_levels: ["L", "M", "H"]

  post_actions:
    - "update_state"            # 状态变更时
    - "notify_user"
```

#### 13. verify — 验证验收
```yaml
verify:
  name: "验证验收"
  version: "1.0.0"
  description: "执行验证检查，生成验证报告"
  
  triggers:
    - type: command
      pattern: "/reqplan verify [--level <1-5>]"
    - type: nlp
      keywords: ["验证", "验收", "检查", "测试运行"]
  
  interface:
    input:
      $ref: "#/definitions/VerifyInput"
    output:
      $ref: "#/definitions/VerifyOutput"
  
  constraints:
    requires_lock: true
    requires_flow: null
    idempotent: true
    max_duration: 60
    harness_levels: ["L", "M", "H"]

  post_actions:
    - "writeback"
    - "update_state"
    - "notify_user"
```

#### 14. docs — 文档管理
```yaml
docs:
  name: "文档管理"
  version: "1.0.0"
  description: "生成/查看/更新项目文档"
  
  triggers:
    - type: command
      pattern: "/reqplan docs list | docs generate <type> | docs update <path>"
    - type: nlp
      keywords: ["生成文档", "更新文档", "查看文档"]
  
  interface:
    input:
      $ref: "#/definitions/DocsInput"
    output:
      $ref: "#/definitions/DocsOutput"
  
  constraints:
    requires_lock: true
    requires_flow: null
    idempotent: false
    max_duration: 60
    harness_levels: ["L", "M", "H"]

  post_actions:
    - "writeback"
    - "update_state"
    - "notify_user"
```

## 接口定义（Interface Definitions）

### 通用 Schema 格式
所有 Action 的 Input/Output 遵循以下规范：
```yaml
definitions:
  <ActionName>Input:
    type: object
    properties:
      <field>:                  # 参数名
        type: string | number | boolean | object | array
        required: boolean       # 是否必填
        description: string     # 参数说明
        default: *              # 默认值（可选）
        enum: []                # 枚举值（可选）
        pattern: "regex"        # 正则校验（可选）

  <ActionName>Output:
    type: object
    properties:
      success:                  # 操作是否成功
        type: boolean
        description: "操作结果"
      data:                     # 返回数据
        type: object
        description: "返回数据"
      message:                  # 用户消息
        type: string
        description: "显示给用户的消息"
      timestamp:                # 执行时间
        type: string
        format: "date-time"
```

### 通用 Input/Output 定义
```yaml
definitions:
  # ====== init ======
  InitInput:
    type: object
    properties:
      projectName:
        type: string
        required: true
        description: "项目名称"
      projectType:
        type: string
        required: false
        default: "generic"
        enum: ["frontend", "backend", "fullstack", "generic"]

  InitOutput:
    type: object
    properties:
      success:
        type: boolean
      data:
        type: object
        properties:
          createdDirs:
            type: array
            items: { type: string }
            description: "创建的目录列表"
          createdFiles:
            type: array
            items: { type: string }
            description: "创建的文件列表"
      message:
        type: string

  # ====== start ======
  StartInput:
    type: object
    properties:
      flow:
        type: string
        required: false
        description: "指定要启动的流程ID"
      resume:
        type: boolean
        required: false
        default: false
        description: "是否恢复上次中断的流程"

  StartOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          selectedFlow: { type: string }
          currentStep: { type: number }
          totalSteps: { type: number }
          suggestions: { type: array, items: { type: string } }
      message: { type: string }

  # ====== intent ======
  IntentInput:
    type: object
    properties:
      text:
        type: string
        required: true
        description: "用户输入文本"
      context:
        type: object
        required: false
        description: "当前上下文信息（可选）"

  IntentOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          detectedIntent: { type: string }
          suggestedFlow: { type: string }
          confidence: { type: number, minimum: 0, maximum: 1 }
          alternatives: { type: array, items: { type: string } }
      message: { type: string }

  # ====== flow ======
  FlowInput:
    type: object
    properties:
      action:
        type: string
        required: true
        enum: ["list", "switch", "current"]
      flowName:
        type: string
        required: false
        description: "switch 时需要指定流程名称"

  FlowOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          availableFlows: { type: array, items: { type: string } }
          currentFlow: { type: string }
          currentStep: { type: number }
      message: { type: string }

  # ====== status ======
  StatusInput:
    type: object
    properties:
      detail:
        type: boolean
        required: false
        default: false
        description: "是否显示详细状态"
      flowName:
        type: string
        required: false
        description: "指定查看的流程（可选）"

  StatusOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          project: { type: string }
          currentFlow: { type: string }
          currentStep: { type: number }
          flowProgress: { type: number, minimum: 0, maximum: 100 }
          overallProgress: { type: number, minimum: 0, maximum: 100 }
          tasks:
            type: object
            properties:
              total: { type: number }
              done: { type: number }
              inProgress: { type: number }
              blocked: { type: number }
          contextHealth:
            type: string
            enum: ["healthy", "warning", "expired"]
      message: { type: string }

  # ====== lock ======
  LockInput:
    type: object
    properties:
      action:
        type: string
        required: true
        enum: ["acquire", "release", "status", "force_acquire"]
      description:
        type: string
        required: false
        description: "操作说明（acquire 时可选）"

  LockOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          status: { type: string, enum: ["locked", "unlocked", "stale"] }
          holder: { type: string }
          acquiredAt: { type: string, format: "date-time" }
          expiresAt: { type: string, format: "date-time" }
          lockVersion: { type: number }
      message: { type: string }
      error:
        type: string
        required: false
        enum: ["E801", "E802"]

  # ====== context ======
  ContextInput:
    type: object
    properties:
      action:
        type: string
        required: true
        enum: ["status", "decisions", "compact", "snapshot", "restore", "history", "archive_list"]
      snapshotId:
        type: string
        required: false
        description: "restore 时需要指定快照ID"

  ContextOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          contextId: { type: string }
          status: { type: string, enum: ["active", "low_activity", "expired", "compacted"] }
          lastActivity: { type: string, format: "date-time" }
          tokenEstimate: { type: number }
          decisionCount: { type: number }
          snapshotCount: { type: number }
          compactionHistory: { type: array, items: { type: object } }
      message: { type: string }

  # ====== task ======
  TaskInput:
    type: object
    properties:
      action:
        type: string
        required: true
        enum: ["list", "create", "update", "delete"]
      taskId:
        type: string
        required: false
      data:
        type: object
        required: false

  TaskOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          tasks: { type: array }
          updatedTask: { type: object }
      message: { type: string }

  # ====== sync ======
  SyncInput:
    type: object
    properties:
      dryRun:
        type: boolean
        required: false
        default: true
        description: "是否仅预览不实际执行"

  SyncOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          detectedChanges: { type: array }
          impactAnalysis: { type: object }
          syncPlan: { type: array }
      message: { type: string }

  # ====== history ======
  HistoryInput:
    type: object
    properties:
      detail:
        type: boolean
        required: false
        default: false
      flowName:
        type: string
        required: false

  HistoryOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          flowHistory: { type: array }
          decisionLog: { type: array }
          snapshotList: { type: array }
      message: { type: string }

  # ====== verify ======
  VerifyInput:
    type: object
    properties:
      level:
        type: number
        required: false
        default: 5
        minimum: 1
        maximum: 5
        description: "验证层级（1-5层验证金字塔）"

  VerifyOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          results: { type: array }
          summary: { type: string }
          passRate: { type: number, minimum: 0, maximum: 100 }
      message: { type: string }

  # ====== docs ======
  DocsInput:
    type: object
    properties:
      action:
        type: string
        required: true
        enum: ["list", "generate", "update"]
      docType:
        type: string
        required: false
        description: "文档类型（generate 时使用）"
      path:
        type: string
        required: false
        description: "文档路径（update 时使用）"

  DocsOutput:
    type: object
    properties:
      success: { type: boolean }
      data:
        type: object
        properties:
          docs: { type: array }
          generated: { type: string }
          updated: { type: string }
      message: { type: string }
```

## Action 执行协议

### 标准执行流程
```yaml
execute_action:
  输入: action_name, input_params, context
  
  流程:
    1. 在注册表中查找 Action 定义
    2. 验证输入参数（类型、必填、枚举）
    3. 检查约束条件（锁状态、流程状态）
    4. 如果需要锁 → 触发 acquire_lock
    5. 执行 Action 逻辑
    6. 构建标准输出（success + data + message）
    7. 执行后置处理（writeback / update_state）
    8. 如果获取了锁 → 触发 release_lock
    9. 返回 Output 给用户

  输出: ActionOutput (格式化的消息 + 结构化数据)
```

### 错误执行流程
```yaml
execute_action_error:
  触发条件: 执行过程中任何步骤失败
  
  流程:
    1. 记录错误上下文
    2. 如果已获取锁 → 判断锁清理策略
    3. 构建错误输出:
       """
       ❌ 操作失败
       Action: {action_name}
       错误码: {error_code}
       错误信息: {error_message}
       建议操作: {recovery_suggestion}
       """
    4. 不修改状态（保持幂等性）
    5. 返回错误 Output 给用户
```

## Action 编排

### 组合 Action
当需要执行复合操作时，通过编排多个基本 Action 实现：
```yaml
composite_action:
  id: "update-task-with-verify"
  name: "更新任务并验证"
  
  sequence:
    - action: lock.acquire
      params: { description: "更新任务 TASK-003" }
    
    - action: status
      params: { detail: true }
      # 确认当前状态
    
    - action: task.update
      params: { taskId: "TASK-003", data: { status: "DONE" } }
    
    - action: sync
      params: { dryRun: false }
      # 同步变更到相关文件
    
    - action: lock.release
```

### 失败时回滚策略
```yaml
rollback_strategy:
  # 当 composite_action 中某个步骤失败时
  on_failure:
    - action: "回滚已执行的操作"
    - action: "提醒用户手动介入"
    - action: "记录失败日志到 decision_log"
  
  # 回滚规则
  rules:
    - "读取操作不需要回滚"
    - "写入操作按执行顺序反向回滚"
    - "幂等操作跳过回滚"
```

## 从 prompt 到可执行路径

### 渐进迁移路线
```yaml
# 当前阶段（v3.2）
phase_1:
  描述: "Action 接口定义 + prompt 模拟执行"
  文件: core-actions.md
  做法:
    - Action 注册表明确定义所有接口
    - LLM 严格按照 Action 接口规范生成响应
    - 在 prompt 中模拟 acquire_lock / release_lock 流程

# 下一阶段（v3.3+）
phase_2:
  描述: "引入校验脚本和 mock 执行"
  计划:
    - 创建 scripts/action-validator.py 校验 Action 输出格式
    - 创建 scripts/state-lock.py 模拟锁操作（读写 lock 文件）
    - action 执行前后自动调用校验脚本

# 未来阶段（v4.0）
phase_3:
  描述: "完全可执行模式（依赖平台支持）"
  计划:
    - 每个 Action 绑定独立可执行模块
    - 通过 Action Engine 动态加载和执行
    - 支持 Action 链式编排和条件执行
```

### Action 命令快速参考
```yaml
# 命令格式
/reqplan <action> [<sub-command>] [<args>] [--<flag> <value>]

# 全局标志
--help         # 查看帮助
--dry-run      # 不实际执行，仅预览
--quiet        # 静默模式，不输出详细日志
--json         # 以 JSON 格式输出

# 示例
/reqplan start --flow full           # 启动完整项目流程
/reqplan task update TASK-001 --status DONE  # 更新任务状态
/reqplan sync --dry-run              # 预览同步变更
/reqplan lock acquire --description "更新需求文档"  # 获取锁
```

## 版本信息
**版本**: 1.0.0
**更新时间**: 2026-05-14
**引用**: 3-core/core-state-management.md, 3-core/core-context-tracker.md, 4-schemas/schema-state-lock.md, 4-schemas/schema-state.md
