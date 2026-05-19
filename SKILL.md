---
name: ReqPlan-v3
version: 4.0
author: songzhou
description: |
  基于 Harness Engineering + 接力棒持久化的项目全生命周期管理引擎。

  **When（触发条件）**：
  - 用户提出项目任务：需求分析、设计评审、代码开发、测试优化、文档完善等
  - 用户对已有项目提出变更或迭代需求
  - 用户输入 /reqplan <command> 命令

  **How（执行方式）**：
  - 智能识别用户意图（7个核心流程）
  - 多 Agent 协作（Analyzer → Designer → Implementer → Verifier）
  - 接力棒持久化（跨 Session 续跑）
  - 5 层分层验证
  - 产物契约（Agent 间文件传递）

  **What（产出结果）**：
  - 需求分析文档、设计文档、开发计划
  - 评审报告、验证报告
  - 完整的项目状态和追溯记录

---

# ReqPlan-v3 — Harness Engineering + 接力棒持久化引擎

> **融合设计**：保留 ReqPlan-v3 原有的 7 个核心流程 + Harness 多 Agent 协作 + 接力棒持久化机制

---

## ⚡ 快速开始

```bash
# 首次使用
/reqplan start     # 启动引导，选择流程
/reqplan init      # 初始化项目 Harness 目录

# 续跑（中断后继续）
/reqplan resume    # 读取接力棒，恢复进度
```

---

## 一、核心架构：Harness + 接力棒

### 1.1 多 Agent 协作

```
┌──────────────────────────────────────────────────────────────┐
│                     REQPLAN HARNESS                          │
│                                                              │
│  ┌─────────────┐                                             │
│  │  总控(我)    │ ← 状态机 + 调度 + 判断                      │
│  └──────┬──────┘                                             │
│         │ 调度                                               │
│    ┌────┴────┬────────────┬─────────────┐                   │
│    ▼         ▼            ▼             ▼                    │
│ ┌──────┐ ┌──────┐    ┌──────┐     ┌──────┐                  │
│ │分析Agent│ │设计Agent│  │实现Agent│   │验证Agent│                  │
│ │ explorer│ │ worker │    │ worker │    │ worker │                  │
│ └──────┘ └──────┘    └──────┘     └──────┘                  │
│     ↓         ↓           ↓             ↓                    │
│ _analysis _design   源码变更   _verification               │
│    .md       .md       文件        .md                         │
└──────────────────────────────────────────────────────────────┘
```

### 1.2 接力棒持久化

**核心机制**：每个阶段结束必须更新接力棒，确保跨 Session 可续跑。

```
{项目路径}/.agent/harness/_baton.md
```

**接力棒内容**：
- 当前状态
- 进度追踪
- 产物清单
- 问题记录
- 下一步行动

### 1.3 状态机

```
START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE
                                      ↓
                  ┌────────────────────┼────────────────────┐
                  ↓                    ↓                    ↓
               ✅ DONE              🔧 DESIGN             🔄 IMPLEMENT
                                    (修复模式)           (重试模式)
                                   ↓         ↓       ↓         ↓
                              ARCH问题   REVIEW问题  重试≤2   重试>2
                                   ↓         ↓       ↓         ↓
                               继续DESIGN 继续IMPL  继续IMPL  ❌ FAILED
```

---

## 二、7个核心流程

### 1. 完整项目流程
**适用场景**：新项目启动，从需求到验收的全流程。

### 2. 需求迭代流程
**适用场景**：已有项目的需求更新和迭代。

### 3. 设计评审流程
**适用场景**：架构设计、接口定义、数据库设计的评审。

### 4. 代码开发流程
**适用场景**：代码实现、Bug 修复、功能开发。

### 5. 测试优化流程
**适用场景**：测试策略制定、用例设计、覆盖提升。

### 6. 文档完善流程
**适用场景**：技术文档、API 文档的补充。

### 7. 架构重构流程
**适用场景**：架构优化、技术债务清理。

---

## 三、双轨触发机制

### 3.1 命令触发

```bash
/reqplan start      # 启动引导，选择流程
/reqplan init       # 初始化项目 Harness 目录
/reqplan resume     # 续跑（读取接力棒）
/reqplan status     # 查看当前状态
/reqplan guide      # 智能引导下一步
/reqplan flow list  # 列出可用流程
/reqplan flow <id>  # 切换流程
/reqplan sync       # 文件同步
/reqplan history    # 流程历史
```

### 3.2 自然语言触发

| 意图 | 匹配流程 |
|------|----------|
| "我要开发...", "实现...", "新增..." | 代码开发流程 |
| "帮我看看...", "审查...", "分析..." | 设计评审流程 |
| "出错了", "报错了", "修个Bug" | 代码开发流程 |
| "帮我规划...", "怎么做...", "有什么方案" | 需求迭代流程 |
| "完善文档...", "补充文档..." | 文档完善流程 |

---

## 四、执行前必读

### ⚠️ 绝对禁止行为

| # | 禁止项 | 原因 |
|---|--------|------|
| 1 | ❌ 不读接力棒就执行 | 可能破坏已有进度 |
| 2 | ❌ 不更新接力棒就结束 | 下一个 Session 无法续跑 |
| 3 | ❌ 跳过 CONFIRM 阶段 | 必须用户确认 |
| 4 | ❌ 由我直接编写代码 | 代码必须由 Implementer Agent 编写 |
| 5 | ❌ 由我直接运行测试 | 测试必须由 Verifier Agent 执行 |
| 6 | ❌ 不读取产物就做判断 | 必须基于产物做决策 |
| 7 | ❌ 超过重试上限继续 | 超过 2 次必须停止 |
| 8 | ❌ 跨 Agent 只口头传递信息 | 产物必须通过 Artifact 文件传递 |

### ⚠️ 必须执行行为

| # | 必须项 | 时机 |
|---|--------|------|
| 1 | ✅ 读取接力棒 | 任何操作前 |
| 2 | ✅ 更新接力棒 | 每个阶段结束前 |
| 3 | ✅ 验证产物 | 进入下一阶段前 |
| 4 | ✅ 展示摘要 | CONFIRM 阶段 |
| 5 | ✅ 记录问题 | 遇到问题时 |

---

## 五、Harness Engineering 五大支柱

### 5.1 信息落点

| 落点 | 位置 | 用途 |
|------|------|------|
| 接力棒 | `.agent/harness/_baton.md` | 跨 Session 状态持久化 |
| 分析产物 | `.agent/harness/_analysis.md` | Analyzer Agent 输出 |
| 设计产物 | `.agent/harness/_design.md` | Designer Agent 输出 |
| 验证产物 | `.agent/harness/_verification.md` | Verifier Agent 输出 |
| 计划协议 | `.agent/plans/{date}-{module}.md` | 任务计划和范围冻结 |

### 5.2 计划协议

每个复杂任务必须包含：
- **Scope**：本轮目标
- **Non-Goals**：明确不做的
- **Validation**：验收标准
- **Rollback**：失败回滚

### 5.3 5 层验证

| 层级 | 验证内容 | 工具 |
|------|----------|------|
| Layer 1 | 静态检查 | pylint, ruff, mypy |
| Layer 2 | 单元测试 | pytest |
| Layer 3 | 构建集成 | python -m py_compile |
| Layer 4 | 异常处理 | 边界测试 |
| Layer 5 | 流程合规 | 产物完整性 |

### 5.4 结果回写

每次任务完成后必须回写：
- 更新状态文件
- 记录决策日志
- 归档产物文件
- 同步相关文档

### 5.5 可执行校验

| 校验脚本 | 用途 |
|----------|------|
| validate-intent-analysis.ps1 | 验证意图分析产出物 |
| validate-verification.ps1 | 验证 5 层全覆盖 |
| verify-review-gate.ps1 | 验证评审门禁条件 |
| run-checks.ps1 | 综合检查入口 |

---

## 六、Agent 职责表

| Agent | 类型 | 职责 | 产物 |
|-------|------|------|------|
| Analyzer | explorer | 解析需求、扫描代码、收集上下文 | `_analysis.md` |
| Designer | worker | 技术方案、模块划分、任务拆解 | `_design.md` |
| Implementer | worker | 代码编写、任务执行、缺陷修复 | 源码变更 |
| Verifier | worker | 分层验证、错误分类、报告输出 | `_verification.md` |

---

## 七、产物契约

### 7.1 产物文件路径

```
{项目路径}/
└── .agent/
    └── harness/
        ├── _baton.md          # 接力棒（总控维护）
        ├── _analysis.md       # 分析产物
        ├── _design.md         # 设计产物
        └── _verification.md   # 验证产物
```

### 7.2 产物读取规则

| 阶段 | 必须读取的产物 | 用途 |
|------|---------------|------|
| CONFIRM | _analysis.md | 展示摘要给用户确认 |
| DESIGN | _analysis.md | 作为设计输入 |
| IMPLEMENT | _design.md | 作为实现依据 |
| VERIFY | _design.md, 源码 | 执行验证 |
| JUDGE | _verification.md | 做判断决策 |

---

## 八、详细文档

### 核心模块
- [SKILL-execution.md](SKILL-execution.md) - ⭐ 核心执行指南
- [agents/analyzer-agent.md](agents/analyzer-agent.md) - 分析 Agent
- [agents/designer-agent.md](agents/designer-agent.md) - 设计 Agent
- [agents/implementer-agent.md](agents/implementer-agent.md) - 实现 Agent
- [agents/verifier-agent.md](agents/verifier-agent.md) - 验证 Agent

### 协议文档
- [protocols/baton-protocol.md](protocols/baton-protocol.md) - 接力棒协议
- [protocols/phase-protocol.md](protocols/phase-protocol.md) - 阶段执行规范

### 模板
- [artifacts/template-artifacts.md](artifacts/template-artifacts.md) - 产物模板

---

## 九、版本信息

**版本**: v4.0 (融合版)
**更新内容**:
- 融合 ReqPlan-v3 原有的 7 个核心流程
- 整合 Harness Engineering 多 Agent 协作
- 添加接力棒持久化机制
- 保留 5 层验证体系
- 整合产物契约

**基于**:
- ReqPlan-v3 原始仓库 (v3.3)
- Harness Engineering 设计模式
- 接力棒持久化机制
