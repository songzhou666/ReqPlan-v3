# Core Workflow Engine
# 工作流引擎核心模块

## 职责
- 7个流程定义管理
- 流程切换控制
- 分支引导逻辑
- 流程进度追踪
- 流程规则验证

## 编排层次

ReqPlan 的整体编排分三层，workflow-engine 位于顶层：

```
  用户意图 / 触发条件
        │
        ▼
┌─────────────────────────────────────┐
│  ① 流程层 (Workflow Engine)        │ ← 选择哪个 Flow（full / iteration / ...）
│     引用: 7-flows/ 目录            │
│     职责: 流程切换、分支引导         │
└────────────┬────────────────────────┘
             │  flow 确定后
             ▼
┌─────────────────────────────────────┐
│  ② 管道层 (Task Pipeline)          │ ← 每个 Flow 内部走 5 阶段门控
│     引用: core-task-pipeline.md    │
│     职责: 入口→计划→执行→验证→回写  │
└────────────┬────────────────────────┘
             │  阶段内操作
             ▼
┌─────────────────────────────────────┐
│  ③ 动作层 (Actions)                │ ← 具体操作（init / start / verify / ...）
│     引用: core-actions.md          │
│     职责: 操作契约、输入输出、错误处理 │
└─────────────────────────────────────┘
```

- **流程层 → 管道层**：每个 Flow 的 Step 映射到 Task Pipeline 的 Stage（flow-full 的 9 步分布在 5 个 Phase 中）
- **管道层 → 动作层**：每个 Stage 内的具体工作通过 Action 接口执行（如 `entry_action`, `verify_action`, `writeback_action`）

## 流程定义
引用: 7-flows/ 目录下各流程文件

## 流程引用

所有7个核心流程的详细定义（适用场景、步骤、输入输出、引导）均位于 `7-flows/` 目录下：

| 流程名称 | 标识 | 文件 |
|---------|------|------|
| 完整项目流程 | full | [7-flows/flow-full.md](file:///E:/Mytest_skill/.trae/skills/ReqPlan-v3/7-flows/flow-full.md) |
| 需求迭代流程 | iteration | [7-flows/flow-iteration.md](file:///E:/Mytest_skill/.trae/skills/ReqPlan-v3/7-flows/flow-iteration.md) |
| 设计评审流程 | design-review | [7-flows/flow-design-review.md](file:///E:/Mytest_skill/.trae/skills/ReqPlan-v3/7-flows/flow-design-review.md) |
| 代码审计流程 | audit | [7-flows/flow-audit.md](file:///E:/Mytest_skill/.trae/skills/ReqPlan-v3/7-flows/flow-audit.md) |
| 测试优化流程 | testing | [7-flows/flow-testing.md](file:///E:/Mytest_skill/.trae/skills/ReqPlan-v3/7-flows/flow-testing.md) |
| 文档完善流程 | docs | [7-flows/flow-docs.md](file:///E:/Mytest_skill/.trae/skills/ReqPlan-v3/7-flows/flow-docs.md) |
| 架构重构流程 | refactor | [7-flows/flow-refactor.md](file:///E:/Mytest_skill/.trae/skills/ReqPlan-v3/7-flows/flow-refactor.md) |

## 流程切换

### 切换规则
```
允许的切换：
- 完整项目 ↔ 所有其他流程
- 需求迭代 ↔ 完整项目、设计评审、代码审计、测试优化、文档完善
- 设计评审 ↔ 完整项目、需求迭代、代码审计、测试优化、文档完善、架构重构
- 代码审计 ↔ 完整项目、需求迭代、设计评审、测试优化、文档完善、架构重构
- 测试优化 ↔ 完整项目、需求迭代、设计评审、代码审计、文档完善
- 文档完善 ↔ 所有流程
- 架构重构 ↔ 完整项目、需求迭代、设计评审、代码审计、测试优化、文档完善
```

### 切换流程
```
1. 验证目标流程是否允许
2. 保存当前流程状态
3. 记录到流程历史
4. 加载目标流程上下文
5. 显示新流程的引导信息
```

### 切换命令
```
/reqplan flow <flow_name>    # 切换到指定流程
/reqplan flow list           # 列出所有可用流程
/reqplan flow current        # 查看当前流程
/reqplan flow history        # 查看流程历史
```

## 分支引导

### 智能分支选择
```
根据当前状态自动判断：
1. 检查当前流程的进度
2. 推荐最适合的下一步
3. 提供可选的分支路径
4. 记录用户选择
```

### 分支示例
```
在完整项目流程的设计阶段后：
分支1：直接进入开发计划（推荐）
分支2：先进行设计评审
分支3：跳转到文档完善流程
```

## 流程进度追踪

### 进度计算
```
每个流程的进度 = (已完成步骤数 / 总步骤数) × 100%

显示格式：
[████████░░░░] 60% 完整项目流程
```

### 步骤完成标记
```
flow_progress:
  full:
    steps:
      initialization: completed
      requirements: completed
      design: in_progress
      planning: pending
      ...
    current_step: design
    overall: 30%
```

## 流程规则验证

### 前置条件检查
```
进入流程前检查：
1. 是否有项目上下文
2. 是否满足流程前置条件
3. 是否需要先完成其他步骤
4. 提示用户确认
```

### 流程约束
```
1. 不能跳过必要的前置步骤
2. 某些流程需要特定的权限
3. 流程切换需要保存当前状态
4. 不能回退到已完成的流程
```

## 引导信息

### 流程选择引导
```
🎯 请选择流程：
1. 完整项目流程 - 从零开始到上线
2. 需求迭代流程 - 现有项目功能迭代
3. 设计评审流程 - 架构和接口评审
4. 代码审计流程 - 代码质量审查
5. 测试优化流程 - 测试策略优化
6. 文档完善流程 - 技术文档生成
7. 架构重构流程 - 系统架构优化

输入 /reqplan flow <序号> 选择流程
```

### 当前流程引导
```
🔄 当前流程：完整项目流程
📍 当前步骤：架构设计
📊 进度：30%

下一步建议：
1. 完成架构设计 → 继续
2. 查看设计文档 → /reqplan design
3. 切换到设计评审 → /reqplan flow design-review
```

## 失败策略

### 流程切换失败 (E801)
```
1. 检查流程名称是否正确
2. 验证是否允许切换
3. 提示可用的流程列表
4. 保持在当前流程
```

### 流程步骤错误 (E804)
```
1. 检查步骤顺序
2. 提示正确的下一步
3. 提供回退选项
4. 记录错误日志
```

### 流程规则冲突 (E805)
```
1. 显示冲突的规则
2. 提供解决方案选项
3. 询问用户选择
4. 记录决策过程
```

## 版本信息

**版本**: 3.3.0
**更新时间**: 2026-05-20
**引用**: 7-flows/flow-full.md, 7-flows/flow-iteration.md, 7-flows/flow-design-review.md, 7-flows/flow-audit.md, 7-flows/flow-testing.md, 7-flows/flow-docs.md, 7-flows/flow-refactor.md, 4-schemas/schema-state.md
