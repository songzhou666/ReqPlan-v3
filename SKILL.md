---
name: reqplan-v3
version: 6.1
author: songzhou
description: 以 7 阶段状态机驱动软件工程任务的全生命周期，每阶段产出独立产物、经独立质量审核后方可推进，接力棒持久化支持跨 Session 续跑。Use：开发新功能、实现需求、代码评审、Bug 修复、架构重构、写测试、补文档等多步骤任务。Skip：单次简单问答、纯聊天、纯信息查询、仅浏览代码、需求极度模糊且用户拒绝澄清，以及改个变量名级别的微操作。
---

# ReqPlan-v3 — Harness Engineering 引擎

> 约束即自由：给 AI 严格的框架，它才能在框架内交出可靠的工作。
> 本 skill 的每条规则都对应一个可验证的检查点；未通过则阻断流程。

---

## 定位与边界

| | 内容 |
|---|---|
| **Use** | 开发/实现功能、代码评审与设计分析、Bug 修复、架构重构、写测试、补充文档，以及任何需要多步骤推进且值得留痕的任务 |
| **Skip** | 单次简单问答、纯聊天、纯信息查询、仅浏览代码、需求极度模糊且用户拒绝澄清、改个变量名级别的微操作 |
| **How** | 读取接力棒 → 按状态机推进：START→ANALYZE→CONFIRM→DESIGN→IMPLEMENT→VERIFY→JUDGE，每阶段验证产物后方可进入下一阶段 |
| **Product** | 需求分析报告、技术设计文档、实现摘要、验证报告、接力棒状态、质量审核报告 |

---

## 激活即执行

本 skill 被激活后（用户表达了开发/修复/分析等意图），立即执行：

1. **定路径（确定工作区根）**：优先级为 —— ① 用户明确指定的路径；② 当前工作目录向上回溯，**最近一个含 `.trae/` 或 `.workbuddy/` 的目录**；③ 回退为当前工作目录。下文所有 `{项目路径}` 均指此**工作区根**。**产物一律写入 `{工作区根}/.agent/harness/`，不因 TRAE / WorkBuddy 而改变。** 元任务（审查/修复本 skill 自身）优先取 `{工作区根}/.trae/skills/{Skill名称}/`——`{Skill名称}` 取**目录名**（如 `ReqPlan-v3`），大小写以磁盘实际拼写为准；该目录须含 `SKILL.md`，否则回退上述优先级。
2. **读接力棒**：`read {项目路径}/.agent/harness/_baton.md`。存在则解析当前状态准备续跑；不存在则创建 `.agent/harness/` 与接力棒，状态置 `START`。
3. **报状态**：回复**第一行**输出 `当前状态：[状态名]，下一步：[操作]`。首次激活且在同一回复内已完成 START→ANALYZE 转换时报 `ANALYZE`；接力棒由本轮新建、尚未转换时报 `START`。续跑时报接力棒中的实际状态。
4. **推流程**：按状态路由表执行当前阶段 → 更新接力棒 → 自动进入下一阶段，直到 `CONFIRM` 或 `DONE`。

**边界（陈述式，非恐吓）**：

- 上述 4 步完成前，不执行任何实质性工作（分析代码、搜索文件、写代码、读非入口文档）。
- 不以「这是元任务」「先读文件了解一下」「交给子 Agent 做」为由跳过状态机；子 Agent 返回后仍回到状态机当前阶段。
- 用户主动中断或提问时，优先执行「用户中断处理」，不继续自动推进。
- 不等待 `/reqplan start` 才启动；不在每步后问「下一步做什么」（`CONFIRM` 阶段除外）。
- 产物必须写入文件，不以「已在对话中展示」替代。

每轮回复结束时自检一行：是否输出了「当前状态」与「下一步」？没有则说明已偏离状态机，立即修正。

---

## 状态路由（核心）

| 当前状态 | 推进 | 必须做 | 禁止做 |
|----------|------|--------|--------|
| START | 自动 | 创建接力棒，进入 ANALYZE | 直接开始编码 |
| ANALYZE | 自动 | 读 `analyzer-agent.md`，产出 `_analysis.md`，调用 Quality Auditor 审核 | 跳过分析直接设计 |
| CONFIRM | **等待用户** | 展示摘要，等待用户响应 | 自动进入下一阶段 |
| DESIGN | 自动 | 读 `_analysis.md` 与 `designer-agent.md`，调用 Quality Auditor 审核 | 不读分析就设计 |
| IMPLEMENT | 自动 | 读 `_design.md` 与 `implementer-agent.md`，调用 Quality Auditor 审核 | 不读设计就编码 |
| VERIFY | 自动 | 读 `_design.md` 与 `verifier-agent.md`，调用 Quality Auditor 独立盲审 | 不读设计就验证 |
| JUDGE | 自动 | 读 `_verification.md`，调用 Quality Auditor 做六维最终判定 | 不看验证报告就判定 |
| DONE / ABORT / FAILED | 终止 | 输出最终报告，流程结束 | 继续执行 |
| DONE（新任务） | 自动重置 | 用户发起新任务时重置接力棒为 START（保留历史产物） | 不重置 |

```
START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE
              ↑        │                      ↓
              └────────┘      ┌───────────────┼───────────────┐
              (修改)          ↓               ↓               ↓
                           DONE            DESIGN          IMPLEMENT
                                        (修复模式)        (重试模式)
```

**关键约束**：

- `CONFIRM` 必须等待用户明确确认，禁止自动跳过。
- 禁止阶段跳跃：ANALYZE 不能直接到 IMPLEMENT，DESIGN 不能直接到 VERIFY。
- 前置产物缺失则阻断：进 DESIGN 需 `_analysis.md`，进 IMPLEMENT 需 `_design.md`，进 VERIFY 需 `_implementation.md`。
- 重试上限：`design_fix_retry` 与 `retry` 各最多 2 次。
- 每阶段结束必须更新接力棒（模板见 `protocols/baton-protocol.md`）。

**条件性跳过**（详见 `SKILL-execution.md` 第一章）：分析类任务可跳过 IMPLEMENT，文档完善类可跳过 DESIGN；首次运行不跳过。

---

## 产物路径

所有产物置于 **`{工作区根}/.agent/harness/`**（工作区根的判定见「激活即执行」第 1 步；TRAE 与 WorkBuddy 共用同一落点，不因 IDE 而变）：

| 文件 | 说明 | 生成阶段 |
|------|------|----------|
| `_baton.md` | 接力棒（状态+进度+任务追踪） | START（持续更新） |
| `_analysis.md` | 需求分析报告 | ANALYZE |
| `_design.md` | 技术设计文档 | DESIGN |
| `_implementation.md` | 实现摘要 | IMPLEMENT |
| `_verification.md` | 验证报告 | VERIFY |
| `_quality_audit_analysis.md` | 分析质量审核报告 | ANALYZE→CONFIRM 间 |
| `_quality_audit_design.md` | 设计质量审核报告 | DESIGN→IMPLEMENT 间 |
| `_quality_audit_implement.md` | 实现质量审核报告 | IMPLEMENT→VERIFY 间 |
| `_quality_audit_verify.md` | 验证质量审核报告 | VERIFY→JUDGE 间 |
| `_quality_audit_judge.md` | 最终全局判定报告 | JUDGE |

长期归档（跨任务）：`docs/harness/history.yaml`、`docs/harness/decisions.yaml`

---

## 验证链（防虚假完成）

每个阶段的输出必须提供可验证证据：

- **计数**：声称「提取了 N 个功能/API/任务」→ 必须逐个列出；声称 N 个只列 M 个（M<N）→ 阻断。
- **列表**：声称「涉及文件」→ 必须列出具体路径，不用「等」字省略。
- **文件**：声称「已写入产物」→ 必须 `read` 确认写入成功。
- **流程图**：技术方案中的流程图必须用标准 Mermaid 语法（如 `flowchart TD`），不得用 ASCII 画框。
- **证据分级**：每个结论须区分 **观察 / 推断 / 未知**，引用产物文件与行号保持可追溯；部分来源中的「未匹配」不等于「不存在」。

任一未通过 → 视为阶段未完成，补充后继续。

> 自检清单的权威来源是 `artifacts/template-artifacts.md` 中对应产物的「完成后检查清单」；Agent 定义与之一致，如有差异以模板为准。

---

## 修复回路（JUDGE 阶段决策）

| 错误类型 | 策略 | 计入重试 | 说明 |
|----------|------|-----------|------|
| ARCHITECTURE_VIOLATION | DESIGN(修复) | 是（`design_fix_retry`，上限 2 次） | 架构问题 |
| REVIEW_VIOLATION | IMPLEMENT(修复) | 否 | 代码规范问题 |
| RUNTIME_FAILURE | IMPLEMENT(重试) | 是（`retry`，上限 2 次） | 测试失败 |
| ENVIRONMENT | 报告用户，等待处理 | 否 | 需人工介入 |

---

## 用户中断处理（全阶段适用）

用户在流程执行中提出新需求、问题或调整时，暂停当前阶段并向用户展示三个选项：

| 选项 | 行为 |
|------|------|
| **① 立即重置** | 接力棒状态改回 ANALYZE（保留已有产物），记录中断原因与新需求，重新分析 |
| **② 记入 TODO** | 在接力棒新增「待办清单」章节记录，继续当前流程；DONE 后自动触发「新任务重置」 |
| **③ 仅讨论** | 回答/讨论后继续当前阶段，不修改任务范围 |

随后更新接力棒：记录中断时间、原因、用户选择。本机制覆盖「激活即执行」的自动推进；用户主动介入时优先响应中断。

---

## 触发机制

**自然语义**：开发/实现/写/新增 → 代码开发；修复/改/出错/报错 → Bug 修复；看看/审查/评审/分析 → 设计评审；规划/方案/怎么做 → 需求规划；重构/架构/技术债 → 架构重构；测试/覆盖率 → 测试优化；文档/补充文档 → 文档完善。

**命令**：`/reqplan start`（启动引导）、`/reqplan init`（初始化 Harness 目录）、`/reqplan status`（查看状态）、`/reqplan guide`（意图引导）。

**流程选择**：不确定走哪条流程时先执行 `/reqplan guide`；场景与流程的完整映射见 `SKILL-execution.md` 第 4 章与 `SKILL.chunks/chunk-02-flows.md`。

---

## 按需读取指引

主文档只解决「怎么走」。遇到下列情况时，读取对应文件——**只读与当前任务相关的那一份**：

| 遇到的情况 | 读取 |
|-----------|------|
| 需要某阶段的详细步骤、检查点、防跳过机制 | [SKILL-execution.md](SKILL-execution.md) |
| 要写或校验产物文件 | [artifacts/template-artifacts.md](artifacts/template-artifacts.md) |
| 要创建/更新接力棒 | [protocols/baton-protocol.md](protocols/baton-protocol.md) |
| 某个 Agent 具体该怎么做 | [agents/](agents/) 下对应文件 |
| 质量审核的评分标准与阻断规则 | [quality-control/00-quality-system.md](quality-control/00-quality-system.md) |
| 安全与隐私规范、P0/P1 风险处理 | [reference/security-safety.md](reference/security-safety.md) |
| 需求超出能力范围（无法实现/多任务/越界方案） | [reference/out-of-scope.md](reference/out-of-scope.md) |
| 常见问题与边缘场景 | [reference/faq.md](reference/faq.md) · [reference/faq-deep.md](reference/faq-deep.md) |
| 想知道哪些做法是错的 | [reference/anti-patterns.md](reference/anti-patterns.md) |
| 验证或调试卡住 | [reference/debug-guide.md](reference/debug-guide.md) |
| 需要按场景按需加载分块 | [SKILL.chunks/chunk-index.yaml](SKILL.chunks/chunk-index.yaml) |
| 要写长期归档（任务摘要 / 决策记录） | [SKILL.chunks/chunk-04-chain.md](SKILL.chunks/chunk-04-chain.md) |

---

## 收尾

流程到达 `DONE` / `ABORT` / `FAILED` 时：

1. **回头核对** ANALYZE 阶段确立的问题清单，逐条标记「已答 / 部分答 / 未答」；未答项如实保留，不把广泛调查描述为完成。
2. **明确停止条件**：授权的工作已验证、或剩余收益无法证明、或继续只会用正确性换速度——三者任一成立即可停止，不再追加优化轮次。
3. 按 `SKILL-execution.md` 附录 A 输出终止报告（DONE / ABORT / FAILED 三套模板）。

---

## 版本信息

**v6.1**（产物路径统一版，2026-10-16）— 变更详情见 [6-docs/changelog.md](6-docs/changelog.md)。
