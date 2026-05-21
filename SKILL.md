---
name: reqplan-v3
version: 4.2
author: songzhou
description: |
  项目全生命周期管理引擎。用于系统化、流程化地执行软件工程任务。

  **When to use**:
  - 用户说"帮我开发..."、"实现...功能"、"新增..."、"写个..."
  - 用户说"帮我分析..."、"审查..."、"看看这个设计..."
  - 用户说"出错了"、"报错了"、"修个Bug"、"修复..."
  - 用户说"帮我规划..."、"怎么做..."、"有什么方案"
  - 用户说"完善文档..."、"补充文档..."、"写文档..."
  - 用户说"重构..."、"优化架构..."、"技术债务..."
  - 用户说"测试..."、"写测试..."、"覆盖率..."
  - 用户输入 "/reqplan" 命令
  - 任何涉及多步骤、需要设计-实现-验证的复杂任务

  **When NOT to use**:
  - 单次简单问答（如"Python列表怎么排序"）
  - 纯聊天对话，无具体任务目标

  **How it works**:
  0. 确定项目路径（元任务走兜底规则，不以路径模糊为由跳过）
  1. 读取接力棒（.agent/harness/_baton.md）获取当前状态
  2. 按状态机执行：START→ANALYZE→CONFIRM→DESIGN→IMPLEMENT→VERIFY→JUDGE
  3. 每个阶段必须验证产物才能进入下一阶段
  4. 所有产物通过文件传递，禁止口头传递
  5. 用户必须在 CONFIRM 阶段确认后才能继续
  6. 每步回复第一行必须输出"当前状态：[状态名]，下一步：[操作]"

  **What it produces**:
  - 需求分析报告（_analysis.md）
  - 技术设计文档（_design.md）
  - 实现摘要（_implementation.md）
  - 验证报告（_verification.md）
  - 接力棒状态（_baton.md）
---

# ReqPlan-v3 — Harness Engineering 引擎

> **约束即自由**。给 AI 严格的框架，它才能在框架内交出可靠的工作。
> 本 Skill 的每个规则都必须通过检查点验证，未通过则阻断流程。

---

## ⚠️ 激活后强制执行

### 0. 确定项目路径（必须先决定）

```
规则：{项目路径} 的优先级
1. 用户明确指定的路径 → 使用该路径
2. 当前工作目录（本次对话的 cwd） → 使用该路径
3. 以上都不可用时 → 使用当前工作目录作为兜底

说明：即使你的任务是"审查 Skill 本身"（元任务），也必须选定一个项目路径。
不要让路径模糊成为跳过状态机的理由。
```

### 1. 强制入口清单（硬性阻断 — 不完成不得进行任何实质性工作）

```markdown
## 🚨 强制入口清单（激活后第一步必须完成）

在回答用户任何问题、执行任何分析、写任何代码之前，必须：

- [ ] 已确定项目路径（按规则 0）
- [ ] 已执行 read {项目路径}/.agent/harness/_baton.md
- [ ] 已确认接力棒存在与否
    - 存在 → 解析当前状态，准备续跑
    - 不存在 → 创建目录和接力棒，状态 START
- [ ] 已执行 write {项目路径}/.agent/harness/_baton.md（如果不存在）
- [ ] 已在回复第一行输出 "当前状态：[状态名]，下一步：[操作]"

**任何为未完成以上项目 → 禁止执行后续步骤 → 必须先完成入口清单**
**验证方式**：用户可在任何时候要求检查入口清单是否全部打勾。
```

### 2. 自检闭环（防止遗忘）

每次回复结束时，必须检查：
```markdown
- [ ] 我在本次回复中是否输出了 "当前状态" 和 "下一步"？
- [ ] 如果没有 → 说明已偏离状态机 → 立即返回并修正
```

### 3. 状态路由（强制）

| 当前状态 | 必须做的事 | 禁止做的事 |
|----------|-------------|-------------|
| START | 创建接力棒，进入 ANALYZE | ❌ 直接开始编码 |
| ANALYZE | 读取 analyzer-agent.md，生成 _analysis.md | ❌ 跳过分析直接设计 |
| CONFIRM | 展示摘要，等待用户响应 | ❌ 自动进入下一阶段 |
| DESIGN | 读取 _analysis.md 和 designer-agent.md | ❌ 不读分析就设计 |
| IMPLEMENT | 读取 _design.md 和 implementer-agent.md | ❌ 不读设计就编码 |
| VERIFY | 读取 _design.md 和 verifier-agent.md | ❌ 不读设计就验证 |
| JUDGE | 读取 _verification.md，做判定 | ❌ 不看验证报告就做判断 |
| DONE/ABORT/FAILED | 输出最终报告，流程结束 | ❌ 继续执行 |

---

## 核心机制

### 阶段流转

```
START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE
              ↑        │                      ↓
              └────────┘      ┌─────────────────┼─────────────────┐
              (修改)          ↓                 ↓                 ↓
                           ✅ DONE           🔧 DESIGN          🔄 IMPLEMENT
                                           (修复模式)          (重试模式)
```

### 关键约束

- **CONFIRM 阶段必须等待用户明确确认**，禁止自动跳过
- **禁止阶段跳跃**：ANALYZE 不能直接到 IMPLEMENT，DESIGN 不能直接到 VERIFY
- **前置产物缺失则阻断**：进入 DESIGN 必须有 _analysis.md，进入 IMPLEMENT 必须有 _design.md，进入 VERIFY 必须有 _implementation.md
- **重试上限**：design_fix_retry 和 retry 各最多 2 次
- **每个阶段结束后必须更新接力棒**（模板见 protocols/baton-protocol.md）

### 产物路径（统一）

所有产物放在 `{项目路径}/.agent/harness/`：

| 文件 | 说明 | 生成阶段 |
|------|------|----------|
| `_baton.md` | 接力棒（状态+进度+任务追踪） | START（持续更新） |
| `_analysis.md` | 需求分析报告 | ANALYZE |
| `_design.md` | 技术设计文档 | DESIGN |
| `_implementation.md` | 实现摘要 | IMPLEMENT |
| `_verification.md` | 验证报告 | VERIFY |

长期归档（跨任务）：`docs/harness/history.yaml`、`docs/harness/decisions.yaml`

### 修复回路（JUDGE 阶段决策）

| 错误类型 | 策略 | 计入重试 | 说明 |
|----------|------|-----------|------|
| ARCHITECTURE_VIOLATION | DESIGN(修复) | ✅ design_fix_retry | 架构问题，最多修复2次 |
| REVIEW_VIOLATION | IMPLEMENT(修复) | ❌ | 代码规范问题 |
| RUNTIME_FAILURE | IMPLEMENT(重试) | ✅ retry | 测试失败，最多2次 |
| ENVIRONMENT | 报告用户，等待处理 | ❌ | 需人工介入 |

---

## 触发机制

### 自然语义触发

| 意图 | 典型触发词 |
|------|-----------|
| 代码开发 | "开发"、"实现"、"写"、"新增"、"创建" |
| Bug修复 | "修复"、"修"、"改"、"调整"、"出错了"、"报错了" |
| 设计评审 | "看看"、"审查"、"评审"、"分析"、"检查一下" |
| 需求规划 | "规划"、"方案"、"怎么做"、"如何"、"计划" |
| 文档完善 | "文档"、"写文档"、"补充文档"、"完善文档" |
| 架构重构 | "重构"、"架构"、"技术债务"、"重写" |
| 测试优化 | "测试"、"写测试"、"覆盖率"、"单元测试" |

### 命令触发

| 命令 | 用途 | 详细指引 |
|------|------|----------|
| `/reqplan start` | 启动引导，选择流程 | 进入 7 阶段状态机 |
| `/reqplan init` | 初始化项目 Harness 目录 | 创建 `.agent/harness/` + `docs/harness/` |
| `/reqplan status` | 查看当前状态 | 读取 `_baton.md` 展示进度 |
| `/reqplan guide` | 智能引导下一步 | 按 chunk-01-guide.md 引导用户澄清意图 |

---

## 详细文档索引

### 核心执行指南
- [SKILL-execution.md](SKILL-execution.md) — 阶段详解、检查点清单、防跳过/防遗忘机制（必读）

### Agent 定义
- [agents/analyzer-agent.md](agents/analyzer-agent.md) — 分析 Agent（explorer）
- [agents/designer-agent.md](agents/designer-agent.md) — 设计 Agent（worker）
- [agents/implementer-agent.md](agents/implementer-agent.md) — 实现 Agent（worker）
- [agents/verifier-agent.md](agents/verifier-agent.md) — 验证 Agent（worker）

### 协议与模板
- [protocols/baton-protocol.md](protocols/baton-protocol.md) — 接力棒协议（模板、生命周期、续跑）
- [protocols/phase-protocol.md](protocols/phase-protocol.md) — 阶段执行规范（每个阶段的详细步骤）
- [artifacts/template-artifacts.md](artifacts/template-artifacts.md) — 产物模板集合（唯一来源）

### 分块加载（按需激活）
- [SKILL.chunks/chunk-index.yaml](SKILL.chunks/chunk-index.yaml) — 分块索引与加载规则
- [SKILL.chunks/chunk-01-guide.md](SKILL.chunks/chunk-01-guide.md) — 意图引导（始终加载）
- [SKILL.chunks/chunk-02-flows.md](SKILL.chunks/chunk-02-flows.md) — 三大流程定义（高频）
- [SKILL.chunks/chunk-03-harness.md](SKILL.chunks/chunk-03-harness.md) — 验证与审查（中频）
- [SKILL.chunks/chunk-04-chain.md](SKILL.chunks/chunk-04-chain.md) — 信息落点与链路（低频）

### 辅助文档
- [reference/debug-guide.md](reference/debug-guide.md) — 验证与调试指南
- [6-docs/changelog.md](6-docs/changelog.md) — 版本变更日志
- [scripts/harness/README.md](scripts/harness/README.md) — 校验脚本说明（run-checks / validate-baton / validate-artifact）

---

## 版本信息

**版本**: v4.3 (自强制版)
**更新日期**: 2026-05-21

**核心设计**:
- 7 阶段状态机 + 强制检查点 + 阶段跳跃阻断 + 产物缺失阻断
- Harness Engineering 多 Agent 协作（Analyzer → Designer → Implementer → Verifier）
- 接力棒持久化机制（跨 Session 续跑）
- 5 层验证体系（静态→单元→构建→异常→合规）
- 独立文件产物模式 + SKILL.chunks 渐进式分块加载
- **自强制机制**：强制入口清单（硬性阻断）+ 自检闭环 + 输出契约

**v4.3 更新内容（自强制版）**:
- 新增路径兜底规则：用户指定 > cwd > workspace 根，元任务不例外
- 新增强制入口清单：激活后必须先完成入口检查，未完成禁止做实质性工作
- 新增自检闭环：每次回复结束时自动检查是否输出了状态和下一步
- 新增输出契约：每步第一行必须输出"当前状态：[状态名]，下一步：[操作]"
- SKILL-execution.md / phase-protocol.md START 阶段新增路径确定步骤和强制输出行

**v4.2 更新内容**:
- 三套路径体系统一为 `.agent/harness/`（运行时）+ `docs/harness/`（归档）
- SKILL.md 从 543 行精简至 ~183 行
- 删除重复状态路由表，消除两套流程体系冗余
- 清理 skill-manifest.yaml 未激活的路径定义
- 删除 3 个空壳占位文件，修正 legacy/README 矛盾描述
- 清理 debug-guide.md 过时引用，标注 PowerShell 脚本兼容性
- 补充 /reqplan guide 命令行为定义