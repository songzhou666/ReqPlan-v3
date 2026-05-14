# Core Harness Selector
# 轻量 vs 完整 Harness 判断指南 (v1)

## 职责

- 每轮任务启动时快速判定 Harness 工程能力级别
- 避免小任务过度工程（over-engineering），大任务偷工减料（under-engineering）
- `Stage 1 任务入口` 阶段完成级别选择

## 核心决策模型：三轴判断

每次任务都在三个轴上独立打分，综合决定 Harness 级别。

### 轴一：任务复杂度（X 轴）

| 分值 | 级别 | 典型场景 | 判断依据 |
|------|------|---------|---------|
| 1 | L1 轻量 | 修变量名、改文案、补注释、改样式 | 只涉及单文件/单行修改，无逻辑变化 |
| 2 | L2 标准 | 新增小功能、修改 API、更新模块 | 涉及 2-5 个文件，有明确逻辑变更 |
| 3 | L3 完整 | 跨模块新功能、重构、新建项目 | 涉及 5+ 文件或跨层（前端+后端+DB）变更 |

### 轴二：项目成熟度（Y 轴）

| 分值 | 级别 | 典型状态 | Landing Zone 状态 |
|------|------|---------|-------------------|
| 1 | Phase 1 入门 | 只有 AGENTS.md | 仅 AGENTS.md 存在 |
| 2 | Phase 2 标准 | 有完整的范围冻结流程 | AGENTS.md + .agent/plans/ + control-plane |
| 3 | Phase 3 完善 | 全部规则已机械化为脚本 | 12个 landing zone 全部就位 + CI 集成 |

### 轴三：任务风险（Z 轴）

| 分值 | 级别 | 风险特征 | 判断依据 |
|------|------|---------|---------|
| 1 | 低风险 | 纯前端/纯UI/纯文档变更 | 不影响数据、不影响已有功能、易于回滚 |
| 2 | 中风险 | API 变更/逻辑调整/配置修改 | 影响已有功能但影响范围可控 |
| 3 | 高风险 | 数据迁移/DB schema 变更/支付等核心链路 | 影响数据完整性、影响用户交易、难以回滚 |

## 综合评分与 Harness 级别映射

```
总分 = X(任务复杂度) × Y(项目成熟度) × Z(任务风险)

注意：乘法而非加法——任一轴为 3 就会显著提升总分。
```

### 级别映射表

| 总分范围 | Harness 级别 | 管道模式 | 说明 |
|---------|-------------|---------|------|
| 1 ~ 3 | **S 跳过** | 无管道 | Agent 自行判断、直接执行，不启动任何 harness |
| 4 ~ 8 | **L 轻量** | 3 阶段简化管道 | Stage 1 → Stage 3 → Stage 5，跳过计划冻结和完整验证 |
| 9 ~ 18 | **M 标准** | 5 阶段标准管道 | 完整 5 阶段，可对部分组件做简写（如组件职责矩阵简写） |
| 19 ~ 27 | **H 完整** | 5 阶段 + super-flow（详见 [7-flows/flow-full.md](file:///E:/Mytest_skill/.trae/skills/ReqPlan-v3/7-flows/flow-full.md)） | 强制所有组件完整、多轮验证、阶段门控 |

### 决策树速查

```
任务到达
    │
    ├─ X=1(轻量变更) ─── Y=1(入门项目) ─── → S 跳过
    │                   └─ Y≥2(有流程) ── → S 跳过（无需启动 harness）
    │
    ├─ X=2(标准变更) ─── Y=1(入门项目) ─── Z≤1(低风险) → L 轻量
    │                   │               └─ Z≥2(中高风险) → M 标准
    │                   └─ Y≥2(有流程) ─── Z≤1(低风险) → L 轻量
    │                                   └─ Z≥2(中高风险) → M 标准
    │
    └─ X=3(完整变更) ─── Z=1(低风险) ─── → M 标准
                        └─ Z≥2(中高风险) → H 完整
```

## 各级别需要的内容清单

### S 级别—跳过

```
什么都不需要。
Agent 直接执行，不创建任何文件、不启动任何流程。
```

### L 级别—轻量（3 阶段管道）

**必须执行**：
```
Stage 1: 任务入口
  - 产出：一句话任务描述（保存在会话上下文即可）
  - Action: intent（仅记录意图，不写文件）

Stage 3: Agent 执行
  - 产出：代码变更
  - Action: sync（文件同步）+ task update（状态更新）

Stage 5: 回写收口
  - 产出：git commit
  - Action: task close

无需执行：
  - 不写 AGENTS.md / PLANS.md
  - 不做范围冻结文档
  - 不做 5 层验证（仅运行 lint/typecheck）
  - 不写 writeback 文档
```

**可跳过验证**：
```
- static:   ✅ 必须跑 lint + typecheck（基础质量底线）
- unit:     ❌ 跳过（除非修改的是测试本身）
- integration: ❌ 跳过
- failure:  ❌ 跳过
- writeback: ❌ 跳过
```

### M 级别—标准（5 阶段管道）

**必须执行**：
```
Stage 1: 任务入口
  - 产出：任务描述 + 复杂度评估（写入会话或快速记录）
  - Action: intent + start

Stage 2: 计划冻结
  - 产出：范围冻结四要素（Scope/Non-Goals/Validation/Rollback）
  - 产出：Entry Points + 验证命令（可简写 component_responsibilities）
  - Action: plan

Stage 3: Agent 执行
  - 产出：代码变更
  - Action: sync + task update

Stage 4: 验证评审
  - 产出：5 层验证结果（failure 层可跳过）
  - Action: verify

Stage 5: 回写收口
  - 产出：git commit + 验证摘要
  - Action: task close + docs
```

**必须验证**：
```
- static:   ✅ 
- unit:     ✅（新增逻辑必须有单元测试）
- integration: ✅（涉及多模块变更必须跑集成测试）
- failure:  ❌ 跳过
- writeback: ✅（检查产出物落点）
```

### H 级别—完整（5 阶段 + super-flow，详见 [7-flows/flow-full.md](file:///E:/Mytest_skill/.trae/skills/ReqPlan-v3/7-flows/flow-full.md)）

**必须执行**：
```
Stage 1: 任务入口
  - 产出：完整任务定义（写入 .agent/plans/）
  - Action: intent + start + context track

Stage 2: 计划冻结
  - 产出：完整实现路径计划（所有 12 节）
  - 包含：范围冻结 / Entry Points / 组件职责 / 关键时序 / 失败策略 / 验证命令 / 回写目标 / 决策日志 / 管道状态映射
  - Action: plan + task create

Stage 3: Agent 执行（多轮迭代）
  - 产出：代码变更（可能多轮提交）
  - 使用 super-flow 编排多轮 Stage 3 → Stage 4 循环
  - Action: sync + task update + guide + status

Stage 4: 验证评审（分阶段门控）
  - 产出：完整 5 层验证报告
  - 每层验证通过后才能进入下一阶段
  - Action: verify + lock check + status

Stage 5: 回写收口
  - 产出：git commit + 验证报告 + 决策日志 + PR/MR 描述
  - Action: task close + docs generate + writeback
```

**必须验证**：
```
- static:   ✅ 
- unit:     ✅（全部新增代码）
- integration: ✅（全链路测试）
- failure:  ✅（异常/超时/边界条件）
- writeback: ✅（产出物落点检查）
```

## 常见场景速查表

| 场景 | X | Y | Z | 总分 | 级别 | 决策理由 |
|------|---|---|---|------|------|---------|
| 修改拼写错误 | 1 | 1 | 1 | 1 | S | 单文件、无风险、无需流程 |
| 修改组件样式 | 1 | 2 | 1 | 2 | S | 纯 UI 变更、有流程但不需要 |
| 新增一个 API 路由 | 2 | 1 | 2 | 4 | L | 新功能但项目不成熟、中等风险 |
| 修改订单状态机逻辑 | 2 | 2 | 3 | 12 | M | 标准变更、标准项目、高风险核心链路 |
| 重构支付模块 | 3 | 3 | 3 | 27 | H | 跨模块、完善项目、核心链路最高风险 |
| 新项目初始化 | 3 | 1 | 1 | 3 | S/L | 复杂度高但成熟度低、低风险，建议跳过后在核心变更时升 M |
| 数据库表结构变更 | 3 | 2 | 3 | 18 | M→H | 复杂度+风险双高，建议按 H 执行 |

## 级别切换规则

### 升级条件

执行中发现以下信号，可以**在任务中途升级** Harness 级别：

```
L → M 升级信号：
  - 范围蔓延：任务实际修改的文件数超过了 L 级别的预期
  - 发现隐藏风险：执行中发现涉及核心逻辑
  - 验证失败：lint/typecheck 通过但功能测试未通过
  
M → H 升级信号：
  - 跨模块影响：修改波及了预期外的模块
  - 多轮迭代：需要 3 轮以上的 Stage 3 → Stage 4 循环
  - 数据完整性风险：发现需要处理数据迁移
```

**升级操作**：
```
1. 记录升级原因到 decision_log
2. 补充当前级别缺失的章节（如 L→M 需补计划冻结）
3. 继续以新级别执行
```

### 降级条件

同样允许降级（但不常见）：

```
M → L 降级信号：
  - 实际变更量远小于预期
  - 验证全部通过且无新增风险
  - 用户明确要求快速完成

降级操作：
  1. 确认未引入新风险
  2. 跳过当前阶段的完整验证
  3. 记录降级原因到 decision_log
```

## 与现有组件的集成

### 集成到 Task Pipeline

```
Stage 1 任务入口
    │
    ├── 评估三轴 → 确定 Harness 级别
    │       │
    │       ├── S: 直接退出管道，Agent 自由执行
    │       ├── L: 进入 Stage 1 → Stage 3 → Stage 5
    │       ├── M: 进入完整 5 阶段管道
    │       └── H: 进入 5 阶段 + super-flow
    │
    └── 以确定的级别继续
```

### 集成到 core-actions

每个 Action 依据 Harness 级别调整行为深度：

```yaml
actions:
  plan:
    harness_levels:
      S: "不执行"
      L: "不执行（在 Stage 3 中直接处理）"
      M: "执行简写版（仅范围冻结四要素 + 验证命令）"
      H: "执行完整版（全部 12 节实现路径）"
  verify:
    harness_levels:
      S: "跳过"
      L: "仅 static 层"
      M: "static + unit + integration + writeback"
      H: "完整 5 层"
  docs:
    harness_levels:
      S: "不生成"
      L: "不生成"
      M: "生成验证摘要"
      H: "生成验证报告 + PR/MR 描述"
```

### 集成到 adoption-guide

本指南是 adoption-guide 中 Phase 2 ~ Phase 3 判断"当前任务该用多重的 harness"的具体工具。

```
adoption-guide.md:  告诉项目管理者"分三阶段渐进落地"
core-harness-selector.md: 告诉 Agent "当前这个任务该用哪一级别"
```

## 初始默认值

当项目没有明确的 landing zone 时，建议的初始默认值：

| 条件 | 默认 Y 值 | 说明 |
|------|----------|------|
| AGENTS.md 存在 | Y=1 | 已入门 |
| AGENTS.md + .agent/PLANS.md 存在 | Y=2 | 已建立计划协议 |
| AGENTS.md + .agent/PLANS.md + 脚本存在 | Y=3 | 已机械化为规则 |

## 版本信息
**版本**: 1.0.0
**更新时间**: 2026-05-14
**引用**: 3-core/core-task-pipeline.md, 3-core/core-actions.md, 6-docs/adoption-guide.md, 4-schemas/schema-landing-zone.md
