# Core Task Pipeline
# 任务完整链路规范 (v1)

## 职责

- 定义任务从"入口"到"收口"的完整流转链路
- 串联分散的组件（落点/Action/流程/验证/回写）为统一的任务模型
- 每个环节有明确的输入来源、产出物、判断条件和失败处理

## 核心思想

任务不应只停留在一次对话中。一个任务从进入项目到完成收口，需要经过 5 个明确的阶段：

```
任务入口 → 计划冻结 → Agent执行 → 验证评审 → 回写收口
```

每个阶段回答一个核心问题：

| 阶段 | 核心问题 | 产出物 |
|------|---------|--------|
| 任务入口 | 为什么做，做什么，不做什么 | 目标 + 范围 + 非目标 + 验收口径 |
| 计划冻结 | 真实入口在哪，怎么改，怎么停 | Scope + Non-Goals + Validation + Rollback |
| Agent执行 | 按什么路径搜索、修改、运行、修复 | 代码变更 + 测试结果 + 过程记录 |
| 验证评审 | 结果是否可信，风险是否可接受 | verify摘要 + review结论 + 剩余问题 |
| 回写收口 | 后续如何追踪，经验如何复用 | PR/MR说明 + 任务状态 + 文档更新 |

---

## 五阶段管道模型

```
                  ┌─────────────────────────────────────────────────────┐
                  │                任务完整链路 (Task Pipeline)            │
                  └─────────────────────────────────────────────────────┘

  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
  │ Stage 1  │   │ Stage 2  │   │ Stage 3  │   │ Stage 4  │   │ Stage 5  │
  │ 任务入口   │──▶│ 计划冻结   │──▶│ Agent执行 │──▶│ 验证评审   │──▶│ 回写收口   │
  └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
       │              │              │              │              │
       ▼              ▼              ▼              ▼              ▼
  入口地图/任务系统    PLANS.md      代码/脚本       verify摘要     PR/MR/文档
  AGENTS.md          计划文件       测试结果        review结论      任务状态
```

### 阶段间门控

每个阶段完成后，必须满足出口条件才能进入下一阶段：

```
Stage N 完成条件:
  ✅ 本阶段产出物完整
  ✅ 本阶段判断条件满足
  ✅ 无阻塞性问题
  ⏭️ 可跳过（需记录原因到 decision_log）
  🔄 可回退（需保留当前阶段保存点）
```

---

## 阶段 1：任务入口

### 目的
明确"为什么做、做什么、不做什么"，确保 Agent 和工程师在任务启动前对齐目标。

### 入口条件
- 任务来源已明确（需求池/Issue/直接沟通/用户请求）
- 项目入口地图（AGENTS.md）已就位

### 输入来源
| 来源 | 说明 |
|------|------|
| 项目入口地图 AGENTS.md | 项目基本信息、技术栈、验证命令 |
| 任务系统（Linear/JIRA/Issue） | 目标、范围、优先级、责任人 |
| 用户自然语言描述 | 原始需求文本 |
| 控制面文档 docs/harness/control-plane.md | 任务推进方式和验收标准说明 |

### 处理流程
1. 解析任务来源，提取目标描述
2. 识别任务类型（新功能/Bug修复/重构/文档/审计）
3. 评估任务复杂度（L1 轻量 / L2 标准 / L3 完整）
4. 输出结构化的任务声明

### 产出物
```yaml
task_entry:
  task_id: "TASK-001"              # 任务唯一标识
  title: "实现订单列表页面"           # 任务标题
  type: "feature" | "bugfix" | "refactor" | "docs" | "audit"
  
  scope:                           # 本轮目标
    - "实现订单列表页，包含分页"
    - "支持按状态筛选"
  
  nonGoals:                       # 明确不做的
    - "不做订单详情页面"
    - "不做退款功能"
  
  validationCriteria:             # 验收口径
    - "分页每页20条"
    - "筛选支持待支付/已支付/已取消"
  
  complexity: "L2"                 # L1轻量 / L2标准 / L3完整
  priority: "P0"                   # P0紧急 / P1重要 / P2一般
```

### 判断条件
```yaml
stage_1_complete:
  - "scope 已定义，至少包含一条目标"
  - "nonGoals 已定义（可为空，但必须显式声明）"
  - "validationCriteria 已定义"
  - "task_type 和 complexity 已识别"
  
  block_reasons:
    - "scope 未定义或模糊"
    - "validationCriteria 缺失"
    - "与已有任务冲突"
```

### 失败处理
```yaml
stage_1_failure:
  E101 "任务入口定义不完整":
    - "缺少 scope → 提示用户补全目标"
    - "缺少 validationCriteria → 建议至少写一条验收条件"
    - "complexity 识别失败 → 默认 L2 标准级"
  
  E102 "任务类型不可识别":
    - "提示用户手动选择任务类型"
    - "默认以"feature"处理"
  
  recovery:
    - "不阻塞流程，允许在 Stage 2 补充"
    - "缺失信息记录到 decision_log"
```

### 关联组件
```yaml
component_mapping:
  landing_zone: ["entry_map (AGENTS.md)", "control_plane"]
  action: ["/reqplan intent", "/reqplan start", "/reqplan guide"]
  flow: ["所有 flow 的 Step 1 / 2"]
  state: ["task / scope / priority 写入 state.yaml"]
```

---

## 阶段 2：计划冻结

### 目的
将"任务入口"的意图转化为**可执行的实现路径**，冻结本轮的范围、入口、边界和退出策略。

### 入口条件
- Stage 1 产出物（task_entry）已就位
- 任务复杂度已评估

### 输入来源
| 来源 | 说明 |
|------|------|
| Stage 1 产出的 task_entry | scope / nonGoals / validationCriteria |
| 项目代码结构 | 真实代码入口、模块分布 |
| 已有计划模板 .agent/PLANS.md | 计划编写规范 |
| 项目约束 docs/harness/project-constraints.md | 已知的项目级规则 |

### 处理流程
1. 读取 task_entry，确认 scope 和 nonGoals
2. 分析项目代码结构，确定真实实现入口
3. 编写实现路径（非流程图，而是具体入口和职责）
4. 评估风险并编写回滚策略
5. 验证计划的完整性

### 产出物
```yaml
plan:
  task_id: "TASK-001"
  
  ## 实现路径（非流程步骤，而是真实入口）
  entryPoints:                    # 真实入口
    - command: "npm run dev"       # 运行命令
    - file: "src/pages/OrderList.tsx"  # 主文件入口
    - api: "GET /api/orders"       # 接口入口
  
  inputSources:                   # 输入来源
    - type: "API参数"
      details: "page, pageSize, status"
    - type: "配置文件"
      details: "src/config/pagination.ts"
  
  componentResponsibilities:      # 组件职责
    OrderListPage:
      - "渲染订单列表"
      - "管理分页状态"
    OrderFilter:
      - "状态筛选UI"
      - "筛选逻辑"
    orderService:
      - "调用 API"
      - "数据转换"
  
  keySequence:                    # 关键时序
    - "先确认 API 接口可用"
    - "再实现 OrderFilter 组件"
    - "再实现 OrderListPage 组件"
    - "最后联调"
  
  failureStrategies:                # 失败策略
    on_error: "重试 3 次后跳过该模块"
    on_blocker: "回滚到上一个稳定版本"
    rollback_command: "git revert HEAD"
  
  verificationCommands:           # 验证命令
    - "npm run lint"
    - "npm run typecheck"
    - "npm test -- --run OrderList"
  
  writebackTargets:               # 回写目标
    - "PR/MR 描述"
    - "docs/test/verify-summary.md"
```

### 判断条件
```yaml
stage_2_complete:
  - "entryPoints 已定义（至少一个真实入口）"
  - "componentResponsibilities 已定义"
  - "failureStrategies 已定义"
  - "verificationCommands 已定义"
  - "scope 和 nonGoals 保持不变（未膨胀）"
  
  block_reasons:
    - "entryPoints 为空或只写了流程名"
    - "failureStrategies 未定义"
    - "scope 比 task_entry 扩大但未说明"
```

### 失败处理
```yaml
stage_2_failure:
  E201 "计划只写流程步骤，未写实现路径":
    - "要求补全 entryPoints 和 componentResponsibilities"
    - "提示：计划应回答'入口在哪'而不是'先做什么'"
  
  E202 "scope 膨胀未经确认":
    - "标记膨胀内容"
    - "要求用户确认是否扩大范围"
    - "确认后更新 task_entry 的 scope"
  
  E203 "验证命令缺失":
    - "建议从 AGENTS.md 获取标准验证命令"
    - "允许在下一阶段补充"
  
  recovery:
    - "计划不完整时不允许进入 Stage 3"
    - "用户可按 '--force' 跳过检查"
```

### 关联组件
```yaml
component_mapping:
  landing_zone: ["plan_protocol (.agent/PLANS.md)", "plan_files (.agent/plans/)"]
  action: ["/reqplan plan", "/reqplan task create"]
  flow: ["所有 flow 的规划步骤"]
  state: ["plan 路径写入 state.yaml"]
```

---

## 阶段 3：Agent 执行

### 目的
按照冻结后的计划，由 Agent 执行搜索、修改、运行和修复，产出可交付的代码变更。

### 入口条件
- Stage 2 产出的 plan 已冻结
- scope 和 nonGoals 已确认
- 状态锁已获取（如需）

### 输入来源
| 来源 | 说明 |
|------|------|
| Stage 2 产出的 plan | 完整实现路径 |
| 项目代码仓库 | 需修改的源文件 |
| 验证命令 | 执行过程中的反馈 |
| 已有测试 | 回归验证基础 |

### 处理流程
1. 按 plan 的 entryPoints 依次进入对应模块
2. 按 componentResponsibilities 实现各组件
3. 每完成一个组件，执行对应 verificationCommands
4. 遇到问题按 failureStrategies 处理
5. 超出 scope 时暂停并询问

### 产出物
```yaml
execution_result:
  task_id: "TASK-001"
  status: "completed" | "partial" | "blocked"
  
  changes:
    - file: "src/pages/OrderList.tsx"
      type: "modified"
      summary: "实现订单列表主页面"
    - file: "src/components/OrderFilter.tsx"
      type: "created"
      summary: "新增状态筛选组件"
    - file: "src/services/orderService.ts"
      type: "modified"
      summary: "新增分页参数支持"
  
  test_results:
    static_check: "0 errors, 0 warnings"
    unit_test: "15 passed, coverage 82%"
    integration: "3 scenarios passed"
  
  issues_found:
    - description: "分页组件在1000+数据时性能下降"
      severity: "low"
      resolution: "暂不影响，已记录到 decision_log"
  
  scope_changes: []
  deviation_log: []
```

### 判断条件
```yaml
stage_3_complete:
  - "所有 P0 功能已实现"
  - "静态检查通过（lint + typecheck）"
  - "单元测试覆盖核心逻辑"
  - "无超出 scope 的变更"
  
  block_reasons:
    - "P0 功能未全部实现"
    - "静态检查未通过"
    - "出现未预期的 scope 膨胀"
```

### 失败处理
```yaml
stage_3_failure:
  E301 "执行超过计划范围":
    - "暂停执行"
    - "列出超出 scope 的部分"
    - "询问用户：回退 或 更新 scope"
  
  E302 "实现与计划路径偏离":
    - "记录偏离原因到 decision_log"
    - "询问用户是否接受新路径"
  
  E303 "关键验证失败":
    - "按 failureStrategies 处理"
    - "如果 strategy 是 retry → 重试后仍失败则标记为 blocker"
    - "如果 strategy 是 skip → 记录到 issues_found"
  
  recovery:
    - "partial 状态允许进入 Stage 4，但必须在 Stage 5 前修复"
    - "blocked 状态不允许前进"
```

### 关联组件
```yaml
component_mapping:
  landing_zone: ["代码仓库", "PR/MR"]
  action: ["/reqplan sync", "/reqplan task update"]
  flow: ["flow-audit (开发实现)", "flow-iteration (增量开发)"]
  lock: ["schema-state-lock.md (获取锁)"]
  state: ["changes / test_results 写入 state.yaml"]
```

---

## 阶段 4：验证评审

### 目的
系统地验证产出结果，确保质量可信、风险可控、评审结论有据可依。

### 入口条件
- Stage 3 产出物 execution_result 已就位
- 基础验证（lint + typecheck）已通过

### 输入来源
| 来源 | 说明 |
|------|------|
| Stage 3 产出的 execution_result | 变更列表、测试结果、问题记录 |
| 5 层验证规范 core-verification.md | 验证层次定义和检查项 |
| 项目约束 docs/harness/project-constraints.md | 已知规则检查 |
| review 口径 .agent/prompts/ | 审查标准和检查列表 |

### 处理流程
1. 执行 5 层验证（静态 → 单元 → 链路 → 失败 → 回写）
2. 根据 task_entry 的 validationCriteria 逐条验收
3. 执行项目约束检查
4. 汇总验证结果，生成验证摘要
5. 执行 review 检查（scope 合规、nonGoals 合规）

### 产出物
```yaml
verification_result:
  task_id: "TASK-001"
  overall: "pass" | "warning" | "fail"
  
  layers:
    static_check:
      status: "pass"
      details: "lint 0 error, typecheck 0 error, format OK"
    
    unit_test:
      status: "pass"
      details: "15 tests passed, coverage 82%"
    
    integration:
      status: "pass"
      details: "3 E2E scenarios passed, API 响应 < 200ms"
    
    failure_scenarios:
      status: "pass"
      details: "超时重试验证通过, 空数据处理正常"
    
    writeback_check:
      status: "completed"
      details: "验证摘要已生成, 回写目标已识别"
  
  validationCriteriaCheck:
    - criterion: "分页每页20条"
      status: "pass"
    - criterion: "筛选支持待支付/已支付/已取消"
      status: "pass"
  
  constraint_check:
    - "commit message 格式规范 ✅"
    - "无敏感信息泄露 ✅"
  
  review_summary:
    scope_compliance: "✅ 符合"
    nonGoalsCompliance: "✅ 未越界"
    risk_level: "low"
    remaining_issues:
      - "分页组件在大数据量下的性能优化（建议后续迭代）"
```

### 判断条件
```yaml
stage_4_complete:
  - "5 层验证全部完成"
  - "validationCriteria 全部 pass"
  - "constraint_check 无 error"
  - "review 确认 scope 未越界"
  
  block_reasons:
    - "任意一层验证 fail（非 warning）"
    - "validationCriteria 超过 50% 未通过"
    - "scope 越界且未更新 task_entry"
    - "存在高危安全/权限问题"
  
  conditional_pass:               # 条件通过
    - "warning 级别的验证失败允许通过"
    - "但必须记录到 remaining_issues"
    - "必须在 Stage 5 前修复"
```

### 失败处理
```yaml
stage_4_failure:
  E401 "验证层失败（非 warning）":
    - "定位失败层和具体原因"
    - "返回 Stage 3 修复"
    - "保留当前验证结果作为基线"
  
  E402 "validationCriteria 未达标":
    - "标记未达标项"
    - "判断是否属于 nonGoals 范围内"
    - "属于 → 记录为 valid；不属于 → 返回 Stage 3"
  
  E403 "constraint_check 发现违反":
    - "区分 error 和 warning 级别"
    - "error → 立即修复，不允许通过"
    - "warning → 记录到 remaining_issues"
  
  recovery:
    - "验证摘要即使 fail 也应完整记录"
    - "fail 后回退到 Stage 3 的保存点"
```

### 关联组件
```yaml
component_mapping:
  landing_zone: ["test_verification (docs/test/)"]
  action: ["/reqplan verify", "/reqplan status"]
  flow: ["flow-testing (测试优化)", "flow-audit (代码审计)"]
  core: ["core-verification.md (5层验证规范)"]
  state: ["verification_result 写入 state.yaml"]
```

---

## 阶段 5：回写收口

### 目的
将任务的全链路结果写回项目仓库、任务系统和 PR/MR，让经验可复用、后续可追踪。

### 入口条件
- Stage 4 产出的 verification_result 已就位
- 验证状态为 pass 或 conditional_pass

### 输入来源
| 来源 | 说明 |
|------|------|
| Stage 1-4 全部产出物 | task_entry / plan / execution / verification |
| 回写规范 schema-writeback.md | 回写目标定义和格式模板 |
| 任务系统 | 当前任务状态 |

### 处理流程
1. 检查 plan 中定义的 writebackTargets
2. 生成验证摘要文件 → docs/test/verify-{taskId}.md
3. 生成 PR/MR 描述（变更说明 + 验证结果 + 回滚方式）
4. 更新任务系统状态（已完成 / 部分完成 / 阻塞）
5. 更新项目约束（如有新增规则）
6. 更新 decision_log（关键决策和异常记录）

### 产出物
```yaml
writeback_result:
  task_id: "TASK-001"
  
  repository_writebacks:
    - target: "docs/test/verify-TASK-001.md"
      status: "written"
    - target: "AGENTS.md"
      status: "unchanged"
      reason: "无新增验证命令"
  
  task_system_update:
    status: "已完成"
    feedback: "订单列表页面完成，分页和筛选功能正常，API响应<200ms"
    remaining: "大数据量下分页性能待优化"
  
  pr_mr:
    title: "feat: 实现订单列表页面（分页+筛选）"
    sections:
      change_description: "实现订单列表页面...（参见 plan）"
      verification_results: "5层验证全部通过"
      known_risks: "无"
      rollback: "git revert HEAD"
  
  decision_log_entries:
    - type: "scope_change"
      description: "无"
    - type: "deviation"
      description: "无"
    - type: "exception"
      description: "分页组件性能问题已记录"
```

### 判断条件
```yaml
stage_5_complete:
  - "验证摘要已生成并写入 docs/test/"
  - "任务系统状态已同步"
  - "PR/MR 描述已生成（如适用）"
  - "关键决策已记录到 decision_log"
  
  block_reasons:
    - "验证摘要未生成（最小必需产出）"
    - "任务系统状态未同步"
    - "scope 变更未记录到 decision_log"
```

### 失败处理
```yaml
stage_5_failure:
  E501 "回写目标不存在或无法写入":
    - "记录 failed_writeback 到 decision_log"
    - "提示用户手动回写"
    - "不影响任务完成状态"
  
  E502 "任务系统同步失败":
    - "保持本地状态"
    - "提供手动同步的步骤"
  
  recovery:
    - "回写失败不影响其他 stages 的成果"
    - "任务仍标记为 completed，但标注 writeback_pending"
```

### 关联组件
```yaml
component_mapping:
  landing_zone: ["pr_mr", "test_verification (docs/test/)", "控制面文档"]
  action: ["/reqplan docs generate", "/reqplan task update"]
  core: ["schema-writeback.md (回写规范)", "core-context-tracker.md (decision_log)"]
  state: ["writeback_result 写入 state.yaml"]
```

---

## 管道状态管理

### 全局管道状态

```yaml
pipeline_state:
  task_id: "TASK-001"
  status: "active" | "paused" | "completed" | "cancelled"
  
  stages:
    stage_1_entry:
      status: "completed"
      artifacts: ["TASK-001 entry"]
      completed_at: "2026-05-14T10:00:00"
    
    stage_2_plan:
      status: "completed"
      artifacts: [".agent/plans/plan-TASK-001.md"]
      completed_at: "2026-05-14T10:30:00"
    
    stage_3_execute:
      status: "completed"
      artifacts: ["git diff", "test results"]
      completed_at: "2026-05-14T12:00:00"
    
    stage_4_verify:
      status: "completed"
      artifacts: ["docs/test/verify-TASK-001.md"]
      completed_at: "2026-05-14T12:30:00"
    
    stage_5_writeback:
      status: "pending"
      artifacts: []
  
  overall_progress: 80       # 4/5 阶段完成
  current_stage: 5
  rollback_savepoints: []
```

### 阶段间数据传递

每个阶段产出物通过 `artifacts` 字段传递给下一阶段：

```yaml
data_flow:
  stage_1 → stage_2:
    handoff: ["task_entry (scope / nonGoals / validationCriteria)"]
  
  stage_2 → stage_3:
    handoff: ["plan (entryPoints / componentResponsibilities / verificationCommands)"]
  
  stage_3 → stage_4:
    handoff: ["execution_result (changes / test_results / issues_found)"]
  
  stage_4 → stage_5:
    handoff: ["verification_result (layers / review_summary / remaining_issues)"]
  
  stage_1-4 → stage_5:
    handoff: ["全部产出物 (用于回写)"]
```

---

## 管道流控制

### 标准流
```
Stage 1 → Stage 2 → Stage 3 → Stage 4 → Stage 5 → 完成
```

### 回退流
```
Stage 3 (发现问题) → Stage 2 (更新计划) → Stage 3 (重新执行) → Stage 4
```
回退时保留当前阶段的 save_point，返回时从保存点恢复。

### 跳过流
```
Stage 1 → Stage 2 → Stage 3 → Stage 5 (跳过 Stage 4)
```
跳过时记录 reason 到 decision_log。适用于验证在 Stage 3 已完成的简单任务。

### 中断流
```
Stage 3 → [用户中断] → Stage 1 (新任务)
中断时保存 State 3 的进度到 save_point，新任务完成后可选择恢复。
```

### L 级别 3 阶段管道
L 级别（低复杂度任务）使用简化的 3 阶段管道，跳过了完整的计划冻结和验证阶段，适用于单文件修改、Bug 修复等任务。

```
Stage 1 (任务入口) → Stage 3 (直接执行) → Stage 5 (快速回写)
```

**跳过阶段说明**：

| 跳过阶段 | 原因 | 补偿机制 |
|---------|------|---------|
| Stage 2 (计划冻结) | 无需正式计划文件，scope 已在 task_entry 中定义 | 直接在 task_entry 中声明 entryPoints 和验证方式 |
| Stage 4 (完整验证) | 仅做轻量检查，不执行 5 层完整验证 | 在 Stage 5 回写前执行快速验证（至少 1 层） |

**数据流**：
```yaml
stage_1 → stage_3:
  handoff: ["task_entry (scope / entryPoints / verificationCheck)"]

stage_3 → stage_5:
  handoff: ["execution_result (changes / quick_test_result)"]
```

**约束**：
- 最大执行时间：15 分钟
- 不可跨模块变更
- 不需要多轮验证

---

## 任务复杂度与管道选择

根据 Stage 1 评估的复杂度，选择不同的管道路径：

```yaml
complexity_levels:
  L1 (轻量):
    description: "修变量名/改样式/补日志"
    
    pipeline: "简化的 3 阶段"
    stages: ["Stage 1 (快速入口)" → "Stage 3 (直接执行)" → "Stage 5 (快速回写)"]
    
    skip: ["Stage 2 (计划冻结)", "Stage 4 (完整验证)"]
    
    max_duration: "15 分钟"
  
  L2 (标准):
    description: "新增小功能/修改 API/更新模块"
    
    pipeline: "完整 5 阶段"
    stages: ["Stage 1" → "Stage 2" → "Stage 3" → "Stage 4" → "Stage 5"]
    
    optional:
      - "Stage 2 的 componentResponsibilities 可简写"
      - "Stage 4 的 failure_scenarios 层可跳过"
    
    max_duration: "2 小时"
  
  L3 (完整):
    description: "跨模块新功能/重构/新项目"
    
    pipeline: "完整 5 阶段 + super-flow 编排"
    stages: ["Stage 1" → "Stage 2" → "super-flow (多轮 Stage 3-4)" → "Stage 5"]
    
    required:
      - "所有组件必须完整"
      - "多轮验证"
      - "阶段门控检查"
    
    max_duration: "不限"
```

---

## 与现有组件的完整映射

### 整体架构中的位置

```
core-task-pipeline.md (本文件)
    │
    ├── 信息落点 ← schema-landing-zone.md (在哪放)
    ├── Action 接口 ← core-actions.md (怎么做)
    ├── 流程编排 ← flow-full.md + 子 flow (走什么流程)
    ├── 验证验收 ← core-verification.md (怎么检查)
    ├── 结果回写 ← schema-writeback.md (怎么记录)
    ├── 状态管理 ← core-state-management.md (怎么保持状态)
    ├── 上下文管理 ← core-context-tracker.md (怎么跟踪上下文)
    └── 状态锁 ← schema-state-lock.md (怎么防冲突)
```

### 按阶段映射

| 阶段 | 信息落点 | 核心 Action | 关联 Flow | 关键 Schema |
|------|---------|------------|-----------|-------------|
| Stage 1 任务入口 | AGENTS.md, control-plane | intent, start, guide | 所有 flow Step 1-2 | landing-zone |
| Stage 2 计划冻结 | .agent/PLANS.md, .agent/plans/ | plan, task create | 所有 flow 规划步骤 | landing-zone |
| Stage 3 Agent执行 | 代码仓库, PR/MR | sync, task update | flow-audit, flow-iteration | state-lock |
| Stage 4 验证评审 | docs/test/, prompts/ | verify, status | flow-testing, flow-audit | verification |
| Stage 5 回写收口 | PR/MR, 任务系统, docs/ | docs generate, task update | 全部 flow | writeback |

---

## 版本信息
**版本**: 1.0.0
**更新时间**: 2026-05-14
**引用**: 3-core/core-actions.md, 3-core/core-verification.md, 3-core/core-state-management.md, 3-core/core-context-tracker.md, 4-schemas/schema-landing-zone.md, 4-schemas/schema-writeback.md, 4-schemas/schema-state-lock.md, 7-flows/flow-full.md, 6-docs/adoption-guide.md
