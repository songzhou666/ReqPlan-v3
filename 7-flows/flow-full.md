# Full Project Flow
# 完整项目超级流程 (v4.0)

## 职责
- 从零到验收的全流程编排器
- 串联多个子任务为统一的"超级流程"
- 阶段间门控（Phase Gate）自动衔接
- 分支路由将具体执行委托给标准 7 阶段 Harness 管道
- 全流程进度追踪和里程碑管理

## 层级关系说明 ⚠️ 重要

**核心架构**：
```
┌─────────────────────────────────────────┐
│  flow-full (超级流程 - 项目级)           │
│  - 5个里程碑阶段                        │
│  - 每个里程碑包含多个子任务              │
└──────────────┬──────────────────────────┘
               │ 每个子任务
               ▼
┌─────────────────────────────────────────┐
│  标准 7 阶段 Harness 管道 (任务级)      │
│  START → ANALYZE → CONFIRM → ...       │
│  (单个功能/模块的执行)                  │
└─────────────────────────────────────────┘
```

**关键区别**：
- **flow-full**：项目级编排，管理整个项目的里程碑和多个子任务
- **标准 7 阶段**：任务级执行，单个功能/模块的具体实现管道

**Harness 适配**：H — 完整项目使用 flow-full 作为超级编排；每个子任务走标准 7 阶段管道。

## 适用边界

### 适用场景
- 新项目从零启动
- 需要完整走完所有阶段的端到端项目
- 各阶段之间有明确的交付物依赖关系

### 不适用场景（应切换到其他流程）
- 已有项目需求变更 → [flow-iteration](7-flows/flow-iteration.md)
- 独立审查现有代码 → [flow-audit](7-flows/flow-audit.md)
- 仅完善测试覆盖 → [flow-testing](7-flows/flow-testing.md)

## 超级流程架构

### 五阶段里程碑模型
flow-full 将项目生命周期划分为 **5个里程碑阶段（Milestone Phase）**，每个阶段包含多个子任务。**每个子任务独立走标准 7 阶段 Harness 管道**。

```
Phase 1: 需求分析 (M1)
  │
  ├── 子任务1: 收集用户需求 → [标准7阶段管道]
  ├── 子任务2: 编写需求文档 → [标准7阶段管道]
  ├── 子任务3: 需求评审     → [标准7阶段管道]
  │
  ├── [里程碑 M1: 需求基线确定]
  │   交付物: 需求文档、用户故事、验收标准
  ▼

Phase 2: 架构设计 (M2)
  │
  ├── 子任务1: 技术选型      → [标准7阶段管道]
  ├── 子任务2: 架构设计      → [标准7阶段管道]
  ├── 子任务3: 接口定义      → [标准7阶段管道]
  │
  ├── [里程碑 M2: 设计基线确定]
  │   交付物: 架构设计文档、API定义、数据库Schema
  ▼

Phase 3: 开发实现 (M3)
  │
  ├── 子任务1: 模块A开发    → [标准7阶段管道]
  ├── 子任务2: 模块B开发    → [标准7阶段管道]
  ├── 子任务3: 模块C开发    → [标准7阶段管道]
  │      (可并行执行)
  │
  ├── [里程碑 M3: 核心功能完成]
  │   交付物: 代码库、测试结果
  ▼

Phase 4: 测试验证 (M4)
  │
  ├── 子任务1: 单元测试     → [标准7阶段管道]
  ├── 子任务2: 集成测试     → [标准7阶段管道]
  ├── 子任务3: 性能测试     → [标准7阶段管道]
  │
  ├── [里程碑 M4: 测试通过]
  │   交付物: 测试报告、覆盖率报告
  ▼

Phase 5: 文档完善 (M5)
  │
  ├── 子任务1: API文档      → [标准7阶段管道]
  ├── 子任务2: 用户手册     → [标准7阶段管道]
  ├── 子任务3: 部署文档     → [标准7阶段管道]
  │
  ├── [里程碑 M5: 交付完成]
  │   交付物: 完整文档集、部署脚本
  ▼

[验收 & 归档]
```

## 阶段门控（Phase Gate）

### 门控定义
每个阶段完成后，必须通过门控条件才能进入下一阶段。

```yaml
# 通用的阶段门控协议

gate:
  id: "phase-{N}-gate"
  name: "阶段{N}门控"
  check_items:
    - description: "交付物完整性检查"
      method: "verify_artifacts"
      required: true
    - description: "质量门禁（通过率≥80%）"
      method: "verify_quality_gate"
      required: true
    - description: "变更影响评估"
      method: "verify_impact"
      required: false  # 可选，建议执行

# 门控结果输出
gate_result:
  status: "passed" | "blocked" | "conditional_pass"
  items: 
    - name: "交付物完整性"
      status: "pass" | "warn" | "fail"
      details: "各交付物状态..."
    
    - name: "质量门禁"
      status: "pass" | "warn" | "fail"
      details: "通过率 85%，所有P0用例通过"
    
    - name: "变更影响"
      status: "pass"
      details: "无跨阶段影响"
  
  summary: |
    "✅ 阶段1门控通过"
    "---"
    "交付物: 需求文档 ✅ | 用户故事 ✅ | 验收标准 ⚠️"
    "质量: 通过率 85% ✅"
    "影响: 无 ✅"
    "---"
    "进入阶段2: 架构设计"
  
  next_step: "启动设计评审流程"
```

### 各阶段门控要点

#### Phase 1 → Phase 2 门控
```yaml
gate_m1:
  name: "需求基线门控"
  artifacts_required:
    - "需求文档（最少涵盖核心功能80%）"
    - "用户故事/用例（优先级P0+P1覆盖）"
    - "验收标准（每个故事至少一条）"
  quality_gate:
    min_pass_rate: 80
    required_tests:
      - "需求可追溯性检查"
      - "需求无二义性检查"
  
  block_reasons:
    - "核心需求未确定（优先级P0未全部定义）"
    - "验收标准覆盖不足（<50%的故事有验收标准）"
    - "需求之间存在冲突未解决"
    - "干系人未对需求基线达成一致"
  
  pass_message: |
    "✅ 阶段1门控通过 → 进入架构设计"
    "里程碑 M1 达成！需求基线已确定。"
    "下一步: 启动设计评审流程"
```

#### Phase 2 → Phase 3 门控
```yaml
gate_m2:
  name: "设计基线门控"
  artifacts_required:
    - "架构设计文档（含技术选型依据）"
    - "核心模块接口定义"
    - "数据库Schema（如适用）"
    - "风险评估报告"
  quality_gate:
    min_pass_rate: 80
    required_tests:
      - "设计逻辑一致性检查"
      - "技术选型合理性评估"
  
  pass_message: |
    "✅ 阶段2门控通过 → 进入开发实现"
    "里程碑 M2 达成！设计基线已确定。"
    "下一步: 启动代码审计流程"
```

#### Phase 3 → Phase 4 门控
```yaml
gate_m3:
  name: "开发完成门控"
  artifacts_required:
    - "所有P0功能代码"
    - "代码审计报告"
    - "单元测试覆盖率报告"
  quality_gate:
    min_pass_rate: 80
    required_tests:
      - "功能完整性检查（P0全部实现）"
      - "代码规范检查"
      - "安全审查（无高危漏洞）"
  
  pass_message: |
    "✅ 阶段3门控通过 → 进入测试验证"
    "里程碑 M3 达成！核心功能已完成。"
    "下一步: 启动测试优化流程"
```

## 分支路由（Branch Routing）

### 路由协议
当 flow-full 的当前阶段需要执行具体工作时，通过路由协议将控制权交给对应的子流程。

```yaml
route_to_subflow:
  protocol:
    enter:
      action: "flow.switch"
      target: "<subflow_name>"
      context:
        parent_flow: "flow-full"
        current_phase: "<phase_N>"
        handoff_artifact: "<交付物ID或文件路径>"
        parent_state:
          - "flow-full 的全局状态快照"
          - "已完成的里程碑"
          - "活跃的全局任务"
    
    exit:
      condition: "子流程完成（所有步骤标记为 done）"
      action: "flow.switch"
      target: "flow-full"
      return_data:
        completed_phase: "<phase_N>"
        artifacts: ["生成的交付物列表"]
        issues: ["子流程中发现的遗留问题"]
    
    interrupt:
      condition: "用户在子流程中需要切换回主流程"
      action: "flow.switch"
      target: "flow-full"
      save_point:
        subflow_state: "子流程当前位置和进度"
        pending_items: ["未完成项列表"]
```

### 路由示例

```yaml
# 示例: 从 Phase 1 路由到 flow-iteration
route_m1:
  用户: "/reqplan start --flow full"
  系统: "已启动完整项目流程 → 阶段1: 需求分析"
  系统: "正在路由到 flow-iteration..."
  
  输出:
    """
    🔀 路由通知
    主流程: 完整项目流程 (Phase 1/5)
    子流程: 需求迭代流程
    
    上下文传递:
    - 项目类型: 电商平台
    - 需求来源: 从零开始
    - 全局任务: 为空（新项目）
    
    输入下面的命令进入需求环节:
    /reqplan flow switch iteration
    """
  
  完成子流程后的返回:
    """
    🔄 子流程完成
    子流程: 需求迭代流程
    完成状态: 全部8步已完成 ✅
    
    交付物:
    - docs/requirement.md
    - docs/user-stories.md
    
    里程碑 M1 检查:
    - 需求基线确定 ✅ → 门控通过
    - 请确认是否进入 Phase 2: 架构设计?
    
    [1] 进入 Phase 2（推荐）
    [2] 查看阶段1详细报告
    [3] 暂停流程
    """
```

## 流程状态管理

### 完整流程状态
```yaml
# 在 state.yaml 中
flow-full:
  status: "active" | "paused" | "completed" | "cancelled"
  
  phases:
    phase_1:
      name: "需求分析"
      status: "pending" | "active" | "completed" | "skipped"
      subflow: "flow-iteration"
      gate_status: "pending" | "passed" | "blocked"
      milestone: "M1"
      artifacts: []
    
    phase_2:
      name: "架构设计"
      status: "pending"
      subflow: "flow-design-review"
      gate_status: "pending"
      milestone: "M2"
      artifacts: []
    
    phase_3:
      name: "开发实现"
      status: "pending"
      subflow: "flow-audit"
      gate_status: "pending"
      milestone: "M3"
      artifacts: []
    
    phase_4:
      name: "测试验证"
      status: "pending"
      subflow: "flow-testing"
      gate_status: "pending"
      milestone: "M4"
      artifacts: []
    
    phase_5:
      name: "文档完善"
      status: "pending"
      subflow: "flow-docs"
      gate_status: "pending"
      milestone: "M5"
      artifacts: []
  
  overall_progress: 0    # 总体进度 0-100
  current_phase: 1
  milestones_reached: []
  branch_history:
    - timestamp: "..."
      action: "route_to"
      target: "flow-iteration"
      phase: 1
```

### 进度计算规则
```yaml
progress_calculation:
  # 每个阶段权重（总权重=100）
  phase_weights:
    phase_1: 20    # 需求分析
    phase_2: 20    # 架构设计
    phase_3: 30    # 开发实现（最重）
    phase_4: 20    # 测试验证
    phase_5: 10    # 文档完善
  
  # 阶段性进度
  phase_progress:
    phase_1: 100%  # 已完成 → 贡献 weight * 100% = 20
    phase_2: 50%   # 进行中 → 贡献 weight * 50% = 10
    phase_3-5: 0%  # 未开始
  
  # 总体进度
  overall: (20*100% + 20*50% + 30*0% + 20*0% + 10*0%) / 100 = 30%
```

## 流程步骤（9步）

### Step 1: 需求收集
**目标**：收集和整理项目需求，明确业务目标和用户场景。详细步骤由 flow-iteration 流程执行。
**引导**：
```
🔄 需求收集阶段（Phase 1/5）

请选择需求来源：
1. 使用已有需求文档（直接进入评审）
2. 从零开始需求分析
3. 参考类似项目需求模板

输入 /reqplan flow switch iteration 启动子流程
```
**输出**：需求文档
**writeback_target**：`docs/requirement.md`
**完成检查**：
- 需求文档已生成，覆盖所有P0功能
- 用户故事已完成
- 验收标准已定义

### Step 2: 需求评审
**目标**：评审需求的完整性、一致性和可执行性。
**引导**：
```
📋 需求评审阶段（Phase 1/5）

选择评审结果：
1. 需求通过 → 进入 Phase 2
2. 需求需调整 → 返回 Step 1
3. 需求变更 → 记录变更到 decision_log

输入 /reqplan verify 提交评审结果
```
**输出**：评审后的需求文档
**writeback_target**：`docs/requirement-reviewed.md`
**完成检查**：
- 评审通过
- 需求基线已确定
**门控**：gate_m1（需求基线门控）

### Step 3: 架构设计
**目标**：基于需求基线进行系统架构设计。详细步骤由 flow-design-review 流程执行。
**引导**：
```
🏗️ 架构设计阶段（Phase 2/5）

请确认以下设计决策：
1. 确认技术选型
2. 定义高层次的系统模块
3. 定义接口和数据流

输入 /reqplan flow switch design-review 启动子流程
```
**输出**：架构设计文档、API定义
**writeback_targets**：`docs/architecture.md`, `docs/api-definition.md`
**完成检查**：
- 架构设计文档完成
- API/接口定义完成
- 风险评估完成

### Step 4: 设计评审
**目标**：评审架构设计的合理性和完整性。
**引导**：
```
📋 设计评审阶段（Phase 2/5）

选择评审结果：
1. 设计通过 → 进入 Phase 3
2. 设计需调整 → 返回 Step 3
3. 需求问题 → 返回 Phase 1

输入 /reqplan verify 提交评审结果
```
**输出**：设计评审报告
**writeback_target**：`docs/design-review-report.md`
**完成检查**：
- 设计评审通过
- 技术选型确认
**门控**：gate_m2（设计基线门控）

### Step 5: 代码实现
**目标**：按照开发规范进行编码实现。详细步骤由 flow-audit 流程执行。
**引导**：
```
💻 代码实现阶段（Phase 3/5）

选择实现策略：
1. 按照功能模块拆分和实现
2. 先核心后外围（P0 → P1 → P2）
3. 并行开发（多个开发者同时进行）

输入 /reqplan flow switch audit 启动子流程
```
**输出**：代码库变更
**writeback_target**：`src/`
**完成检查**：
- P0功能全部完成
- 单元测试覆盖核心逻辑
- 代码审查通过

### Step 6: 代码审计
**目标**：审计代码质量、安全性和规范性。
**引导**：
```
🔍 代码审计阶段（Phase 3/5）

选择审计结果：
1. 审计通过 → 进入 Phase 4
2. 发现问题 → 记录到 task 并返回 Step 5
3. 安全漏洞 → 立即修复

输入 /reqplan verify 提交审计结果
```
**输出**：代码审计报告
**writeback_target**：`docs/audit-report.md`
**完成检查**：
- 审计报告生成
- 无高危安全漏洞
- 代码规范检查通过
**门控**：gate_m3（开发完成门控）

### Step 7: 测试执行
**目标**：执行测试计划，覆盖功能、集成、性能等。详细步骤由 flow-testing 流程执行。
**引导**：
```
🧪 测试执行阶段（Phase 4/5）

选择测试策略：
1. 完整测试执行
2. 冒烟测试 + 核心功能测试
3. 自动化回归测试

输入 /reqplan flow switch testing 启动子流程
```
**输出**：测试报告
**writeback_target**：`docs/test-report.md`
**完成检查**：
- 功能测试全部通过
- 集成测试通过
- 性能测试达标

### Step 8: 文档生成
**目标**：生成和完善项目各个维度的文档。详细步骤由 flow-docs 流程执行。
**引导**：
```
📚 文档生成阶段（Phase 5/5）

将生成以下文档：
- API 文档 → docs/api-manual.md
- 部署文档 → docs/deployment-guide.md
- 用户手册 → docs/user-manual.md

输入 /reqplan flow switch docs 启动子流程
```
**输出**：完整文档集
**writeback_targets**：`docs/api-manual.md`, `docs/deployment-guide.md`, `docs/user-manual.md`
**完成检查**：
- 所有必需文档已生成
- 文档内容与实际一致

### Step 9: 验收交付
**目标**：最终验收，确保所有交付物满足要求。
**引导**：
```
✅ 验收交付阶段（Phase 5/5）

选择验收结果：
1. 验收通过 → 归档项目
2. 发现问题 → 创建任务修复
3. 需要架构重构 → 启动 flow-refactor 子流程

输入 /reqplan verify 完成最终验收
```
**输出**：验收报告
**writeback_target**：`docs/acceptance-report.md`
**完成检查**：
- 5层验证通过
- 所有 P0/P1 任务完成
- 验收报告生成

**流程完成确认**：
```
🎉 完整项目流程执行完成！

里程统计:
├── 完成阶段: 5/5
├── 里程碑: M1 M2 M3 M4 M5
├── 总进度: 100%
├── 交付物: 需求文档、架构设计、代码库、测试报告、文档集
└── 子流程调用: 5次

后续行动（可选）:
1. 启动架构重构流程 → /reqplan start --flow refactor
2. 查看项目总结 → /reqplan status --detail
3. 归档项目 → /reqplan archive
```

**状态更新**：
- flow-full.status: "completed"
- overall_progress: 100

## 非线性路径

### 回退（Rollback）
```yaml
rollback:
  trigger: "子流程中发现致命问题"
  
  策略:
    - "问题影响当前阶段 → 在原地修复，不退回"
    - "问题影响前一阶段交付物 → 回退到前一阶段"
    - "需求变更 → 回退到 Phase 1"
  
  示例:
    """
    场景: Phase 3 代码实现中发现需求遗漏
    操作: 回退到 Phase 1 补充需求
    流程:
      1. 暂停 Phase 3（记录保存点）
      2. 路由到 Phase 1
      3. 执行 flow-iteration 更新需求
      4. 门控检查通过后回到 Phase 3
      5. 从保存点继续
    """
  
  save_point:
    - "暂停时记录当前子流程位置"
    - "回退后保留待办任务列表"
    - "返回时提示用户上下文摘要"
```

### 跳过（Skip）
```yaml
skip:
  trigger: "某阶段在当前项目中不适用"
  
  策略:
    - "跳过阶段仍记录 reason 到 decision_log"
    - "跳过后自动执行对应门控（门控视为 pass）"
    - "进度权重重新分配"
  
  示例:
    """
    场景: 纯后端项目，没有前端文档需要完善
    操作: Phase 5（文档完善）部分跳过
    跳过: 用户手册章节
    保留: API 文档、部署文档
    进度: 文档阶段按已完成的章节比例计算
    """
  
  skip_record:
    timestamp: "..."
    skipped_phase: "phase_5_docs"
    skipped_items: ["用户手册", "前端样式指南"]
    reason: "纯后端项目，无前端界面"
    authorized: true
```

### 并行（Parallel）
```yaml
parallel:
  trigger: "大型项目，多个子流程可同时执行"
  
  策略:
    - "Phase 3 可按模块拆分为多个 flow-audit 实例"
    - "Phase 4 测试可与 Phase 5 文档部分并行"
    - "并行实例各自维护独立进度"
  
  约束:
    - "并行阶段不能共享相同的状态锁（需要子锁）"
    - "并行完成后等待所有分支到达后再走门控"
  
  示例:
    """
    场景: 大型电商平台，3个模块并行开发
    并行:
      - Module A (商品): flow-audit
      - Module B (订单): flow-audit
      - Module C (支付): flow-audit
    同步点: 三个模块都完成代码审计后走门控 gate_m3
    """
```

## 完整流程引导示例

### 启动引导
```yaml
用户: "/reqplan start --flow full"
系统: "已启动完整项目超级流程"

# 输出
"""
📋 完整项目流程已启动

当前阶段: Phase 1/5 — 需求分析
子流程: 需求迭代流程（flow-iteration）
进度: 0%

📌 下一步:
1️⃣ 开始需求收集 → 输入 /reqplan guide
2️⃣ 直接启动子流程 → /reqplan flow switch iteration
3️⃣ 查看完整路线 → /reqplan status --detail
"""
```

### 阶段过渡引导
```yaml
用户在 Phase 2 完成后:

"""
📋 阶段门控检查

门控: 设计基线门控（gate_m2）
检查结果:
  - 架构设计文档: ✅
  - API定义: ✅
  - 风险评估: ✅

状态: PASSED ✅

📌 进入 Phase 3: 开发实现
当前进度: 40% (Phase 1+2 完成)

推荐行动:
1️⃣ 启动代码审计流程 → /reqplan flow switch audit
2️⃣ 查看开发规范 → /reqplan guide
3️⃣ 创建开发任务 → /reqplan task create
"""
```

### 分支确认引导
```yaml
用户在 Phase 4 测试中发现问题:

"""
🔍 测试发现设计缺陷

问题: 性能测试发现订单查询接口响应 > 5秒
根本原因: 数据库索引设计不合理
影响范围: Phase 2 设计的索引策略

推荐操作:
[1] 在当前阶段修复 → 更新索引后重新测试（推荐）
[2] 回退到 Phase 2 → 重新设计索引策略
[3] 创建高优任务 → 记录为 P0 待修复
"""
```

## 与各子流程的接口定义

### flow-full 供给子流程的信息
```yaml
handoff_to_subflow:
  type: "上下文传递"
  
  供给信息:
    - project_name: string
    - current_phase: number
    - artifacts_from_prev_phase: string[]
    - constraints: string[]
    - global_tasks: Task[]
    - parent_flow_id: "flow-full"
    - save_point_id: string | null  # 如果是从回退/恢复进入
```

### 子流程返回给 flow-full 的信息
```yaml
return_from_subflow:
  type: "上下文返回"
  
  返回信息:
    - subflow_id: string
    - completion_status: "completed" | "partial" | "interrupted"
    - generated_artifacts: string[]
    - issues_found: string[]
    - new_tasks: Task[]
    - decisions_made: Decision[]
    - remaining_items: string[]
```

## 失败策略

### E701 - 阶段进度不一致
```yaml
E701 (超级流程阶段不一致):
  error: "阶段进度与子流程状态不匹配"
  example: "state.yaml 记录 Phase 2 已完成，但 flow-design-review 报告未完成"
  
  recovery:
    1. 读取子流程的完成状态
    2. 比较与 flow-full 的阶段记录
    3. 以子流程实际状态为准（子流程更权威）
    4. 修正 flow-full 的阶段记录
    5. 记录修正到 decision_log
```

### E702 - 子流程路由失败
```yaml
E702 (子流程路由失败):
  error: "无法路由到子流程"
  message: "流程切换请求失败，目标子流程未找到或不可用"
  
  recovery:
    1. 列出可用子流程（/reqplan flow list）
    2. 提示用户手动选择
    3. 如果目标子流程文件缺失，提示创建
    4. 保留当前阶段状态，不丢失进度
```

### E704 - 门控检查失败
```yaml
E704 (门控检查失败):
  error: "阶段门控未通过"
  message: "当前阶段的交付物未满足进入下一阶段的条件"
  
  recovery:
    1. 列出未通过的具体检查项
    2. 提供修复建议
    3. 提供"条件通过"选项（记录例外但允许前进）
    4. 记录门控异常到 decision_log
  
  conditional_pass:
    - 适用于非关键检查项未通过
    - 必须记录"需要后续修复"的任务
    - 下一阶段启动时需关注这些遗留问题
```

## 版本信息
**版本**: 3.3
**更新时间**: 2026-05-20
**引用**: 7-flows/flow-iteration.md, 7-flows/flow-design-review.md, 7-flows/flow-audit.md, 7-flows/flow-testing.md, 7-flows/flow-docs.md, 7-flows/flow-refactor.md, 3-core/core-actions.md, 3-core/core-state-management.md
