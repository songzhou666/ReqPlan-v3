---
name: reqplan-v3
version: 4.9
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
  2. 按状态机自动执行：START→ANALYZE→CONFIRM→DESIGN→IMPLEMENT→VERIFY→JUDGE（无需用户逐一下令）
  3. 每个阶段必须验证产物才能进入下一阶段
  4. 所有产物通过文件传递，禁止口头传递
  5. 用户必须在 CONFIRM 阶段确认后才能继续
  6. 每步回复第一行必须输出"当前状态：[状态名]，下一步：[操作]"
  7. 每步结束执行验证链检查（计数验证/列表验证/文件验证），防止虚假完成

  **What it produces**:
  - 需求分析报告（_analysis.md）
  - 技术设计文档（_design.md）
  - 实现摘要（_implementation.md）
  - 验证报告（_verification.md）
  - 接力棒状态（_baton.md）
  - **质量审核报告（_quality_audit_analysis.md / _quality_audit_design.md / _quality_audit_implement.md / _quality_audit_verify.md / _quality_audit_judge.md）**
---

# ReqPlan-v3 — Harness Engineering 引擎

> **约束即自由**。给 AI 严格的框架，它才能在框架内交出可靠的工作。
> 本 Skill 的每个规则都必须通过检查点验证，未通过则阻断流程。

---

## ⚠️ 激活即执行（强制！）

当 ReqPlan-v3 被激活时（用户表达了开发/修复/分析等意图），AI **必须**立即执行以下流程，不得等待用户额外指令：

```
Step 1: 运行强制入口清单（见下方）
Step 2: 读取接力棒 → 确定当前状态
Step 3: 如果接力棒不存在 → 创建接力棒，状态 START
Step 4: 如果状态是 X → 直接从 X 阶段续跑
Step 5: 按状态路由表执行当前阶段任务
Step 6: 完成阶段任务 → 更新接力棒 → 自动进入下一阶段
Step 7: 重复 Step 5-6，直到 CONFIRM 或 DONE
```

> **🔗 自绑定条款（不可绕过）**：
> - 本条 skill 的 **所有规则、约束、状态机均无条件适用于一切被激活的场景，包括但不限于**：
>   1. 常规开发/修复/分析任务
>   2. **元任务：审查/检查/修复本 Skill 自身**
>   3. **元任务：评估本 Skill 的执行质量或完整性**
>   4. 被 Task 子Agent 调用时的任何子任务
> - 以下理由 **不构成绕过状态机的合法依据**：
>   - "我正在审查Skill本身，所以不需要走状态机"
>   - "我先读取所有文件了解一下，之后再走状态机"
>   - "我用Task子Agent来做，子Agent不需要遵守状态机"
>   - "我不知道当前状态是什么，所以从零开始做"
> - **违规后果**：如果在任何回复中发现AI绕过了状态机（未输出"当前状态"、未创建接力棒、未按阶段执行），用户可判定本 Skill **无效**。

**AI 不得**：
- ❌ 等待用户输入 `/reqplan start` 命令才开始
- ❌ 做完一步后询问"下一步做什么？"（除非在 CONFIRM 阶段）
- ❌ 跳过产物更新直接进入下一阶段
- ❌ 用"已在对话中展示"替代写入产物文件
- ❌ 以路径模糊为由跳过状态机
- ❌ **以元任务（审查/修复 Skill 自身）为由绕过状态机**
- ❌ **以"先读取所有文件了解一下"为由跳过入口清单**
- ❌ **使用 Task 子Agent 执行实质性工作时绕过状态机**（子Agent返回后必须继续遵守状态机，不得跳过当前阶段）
- ❌ **在用户主动中断/提问时忽略用户输入并继续自动推进**（必须优先执行"用户中断处理机制"，见第4节）

### 0. 确定项目路径（必须先决定）

```
规则：{项目路径} 的优先级
1. 用户明确指定的路径 → 使用该路径
2. 当前工作目录（本次对话的 cwd） → 使用该路径
3. 以上都不可用时 → 使用当前工作目录作为兜底

元任务路径选择（重要）：
当用户要求审查/检查/分析 Skill 本身时（元任务）：
- 优先使用当前工作目录下的 .trae/skills/{Skill名称}/ 路径
  - 当前工作目录 = AI 本次对话的工作目录（cwd），通常是项目根目录
  - Skill 名称对应的目录必须包含 SKILL.md 文件，否则回退到规则 1-3
- 如果当前工作目录下无 skills 目录，则回退到规则 1-3 的标准优先级

注意：元任务的接力棒文件依然存放在 `{项目路径}/.agent/harness/`，以保持产物路径统一。
即使你的任务是"审查 Skill 本身"（元任务），也必须选定一个项目路径。
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
- [ ] 已在回复**第一行**输出 "当前状态：[状态名]，下一步：[操作]"

**任何为未完成以上项目 → 禁止执行后续步骤 → 必须先完成入口清单**
**验证方式**：用户可在任何时候要求检查入口清单是否全部打勾。
```

### 1.1 🛡️ 首次响应守卫（最外层防线）

这是 **本 Skill 的最后一道自强制防线**，在所有规则之上：

```markdown
## 🛡️ 首次响应守卫

当 ReqPlan-v3 被激活时，AI 的**第一次回复**必须满足以下条件，否则视作违反本 Skill：

**条件一：回复第一行必须是** ✅
```
当前状态：[状态名]，下一步：[操作]
```
例：`当前状态：START，下一步：创建接力棒，进入 ANALYZE`

**条件二：回复中必须包含入口清单的明确执行记录** ✅
- 不能只是在心里想"已完成"——必须写出实际执行的命令结果
- `read {项目路径}/.agent/harness/_baton.md` → 显示文件内容或"文件不存在"
- `write {项目路径}/.agent/harness/_baton.md`（如不存在）→ 显示写入确认

**条件三：回复中不得包含实质性工作** ✅
（实质性工作 = 分析代码、搜索文件、写代码、修改文件、读取非入口文件的文档）
- 在 CONFIRM 阶段之前，**禁止执行任何不属于入口清单的操作**
- 如果用户的问题是"审查这个Skill"，第一次回复只能说"当前状态：START，正在初始化..."
- 执行分析/搜索/读取等操作必须等START→ANALYZE阶段

**违规检测规则**：
⚠️ 如果AI的第一次回复：
- 没有输出"当前状态"行 → 违反
- 直接开始读文件/搜索/分析 → 违反
- 输出"让我先看看文件结构" → 违反
- 直接使用Task子Agent执行实质性工作 → 违反
- 把入口清单在心里想一遍就当完成了 → 违反

**违反后果**：如果用户判定AI未通过"首次响应守卫"，用户有权要求AI立即停止并重新执行入口清单。

**条件性例外（修正）**：
- 状态转换（START→ANALYZE）属于"入口清单"流程的一部分，不视为"实质性工作"
- 即首次回复可以推进 START→ANALYZE 的状态转换和接力棒更新
- 但 ANALYZE 的实际分析工作（读文件、搜索、写分析报告）必须等第二次回复开始
```

### 2. 自检闭环（防止遗忘）

每次回复结束时，必须检查：
```markdown
- [ ] 我在本次回复中是否输出了 "当前状态" 和 "下一步"？
- [ ] 如果没有 → 说明已偏离状态机 → 立即返回并修正
```

### 3. 状态路由（强制）

| 当前状态 | 自动推进 | 必须做的事 | 禁止做的事 |
|----------|---------|-------------|-------------|
| START | ✅ 自动 | 创建接力棒，进入 ANALYZE | ❌ 直接开始编码 |
| ANALYZE | ✅ 自动 | 读取 analyzer-agent.md，生成 _analysis.md，**拉起 Quality Auditor 审核分析质量** | ❌ 跳过分析直接设计 |
| CONFIRM | ⛔ 等待用户 | 展示摘要，等待用户响应 | ❌ 自动进入下一阶段 |
| DESIGN | ✅ 自动 | 读取 _analysis.md 和 designer-agent.md，**拉起 Quality Auditor 审核设计质量** | ❌ 不读分析就设计 |
| IMPLEMENT | ✅ 自动 | 读取 _design.md 和 implementer-agent.md，**拉起 Quality Auditor 审核实现质量** | ❌ 不读设计就编码 |
| VERIFY | ✅ 自动 | 读取 _design.md 和 verifier-agent.md，**拉起 Quality Auditor 做独立盲审** | ❌ 不读设计就验证 |
| JUDGE | ✅ 自动 | 读取 _verification.md，**拉起 Quality Auditor 做六维度最终全局判定** | ❌ 不看验证报告就做判断 |
| DONE/ABORT/FAILED | 终止 | 输出最终报告，流程结束 | ❌ 继续执行 |
| DONE（新任务） | ✅ 自动重置 | 用户发起新任务时，AI 自动重置接力棒为 START（保留历史产物），直接进入 START 阶段引导新任务 | ❌ 不重置 |

### 4. 用户中断处理机制（全阶段适用）

当用户在状态机执行过程中（非 CONFIRM 阶段或 CONFIRM 阶段）提出额外需求、问题或调整要求时，AI 必须执行以下流程：

```markdown
## 中断处理流程

1. [ ] 立即暂停当前阶段操作
2. [ ] 向用户展示 3 个选项：

   > ⚠️ 我注意到您在流程执行中提出了新的需求/问题。
   > 请选择处理方式：
   > 
   > **① 立即重置**：中断当前流程，回到 ANALYZE 阶段重新分析并包含新需求
   > **② 记入 TODO**：将新需求记入接力棒 "待办清单"，当前流程完成后自动重新发起任务
   > **③ 仅讨论**：继续当前任务，暂不调整或新增（仅做讨论/解答）

3. [ ] 根据用户选择执行：
   - **选项① 立即重置** → 更新接力棒状态为 ANALYZE（保留已有产物），记录中断原因和新需求，进入 ANALYZE 阶段重新分析
   - **选项② 记入 TODO** → 在接力棒新增 "待办清单" 章节，记录新需求，继续当前阶段/流程。当前流程 DONE 后，自动触发 "DONE（新任务）" 规则重新发起任务
   - **选项③ 仅讨论** → 回答用户问题/讨论后，继续当前阶段操作，不修改任务范围

4. [ ] 更新接力棒：记录中断时间、原因、用户选择
```

**注意**：此机制覆盖 AI "激活即执行" 的自动推进行为。当用户主动介入时，AI 应优先响应用户中断而非自动推进。

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

### 验证链规则（防虚假完成）

AI 在每个阶段的输出必须提供可验证的证据链：

- **计数验证**：声称"提取了 N 个功能/API/任务"→ 必须逐个列出 N 个项，声称 N 个但只列出 M 个(M<N) → 阻断
- **列表验证**：声称"涉及文件"→ 必须列出具体文件路径，不得用"等"字省略
- **文件验证**：声称"已写入产物文件"→ 必须执行 `read` 命令确认写入成功
- **流程图验证**：技术方案中的流程图必须使用标准 Mermaid 语法（如 `flowchart TD`），不得使用 ASCII 文字画框
- **阻断规则**：以上任一未通过 → 视为阶段未完成 → 必须补充后继续

> **自检清单的权威来源**：每个阶段执行时，Agent 自检清单以 [artifacts/template-artifacts.md](artifacts/template-artifacts.md) 中对应产物的"完成后检查清单"为最终标准。
> Agent 定义文件中的自检清单与之一致，如有差异以模板文件为准。

### 产物路径（统一）

所有产物放在 `{项目路径}/.agent/harness/`：

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
| `_quality_audit_judge.md` | 最终全局判定报告 | JUDGE 阶段 |

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
- [agents/quality-auditor-agent.md](agents/quality-auditor-agent.md) — [新增] 质量审核 Agent（独立盲审）

### 协议与模板
- [protocols/baton-protocol.md](protocols/baton-protocol.md) — 接力棒协议（模板、生命周期、续跑）
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

---

## 版本信息

**版本**: v4.9 (中断处理机制版)  
**更新日期**: 2026-05-23

**核心设计**:
- 7 阶段状态机 + 强制检查点 + 阶段跳跃阻断 + 产物缺失阻断
- Harness Engineering 多 Agent 协作（Analyzer → Designer → Implementer → Verifier → Quality Auditor）
- 接力棒持久化机制（跨 Session 续跑）
- 5 层验证体系（静态→单元→构建→异常→合规）
- **独立质量审核机制**：ANALYZE/DESIGN/IMPLEMENT/VERIFY/JUDGE 阶段启用独立子Agent盲审
- **审核报告持久化**：审核结果写入独立文件，修复不依赖对话记忆
- **修复验证闭环**：重审时逐条检查上次问题是否已修复
- 独立文件产物模式 + SKILL.chunks 渐进式分块加载
- **自强制机制**：强制入口清单（硬性阻断）+ 自检闭环 + 输出契约
- **验证链规则**：计数验证/列表验证/文件验证，防止虚假完成

**v4.6 更新内容（代入式演练修复版）**:
- 移除 PowerShell 脚本校验体系（validate-baton.ps1 / validate-artifact.ps1 / run-checks.ps1），该体系是从 ManualGen 抄来的备用方案，已被 Quality Auditor 子Agent 独立盲审完全替代
- 所有阶段检查点从脚本驱动改为 AI 状态路由表自检 + Quality Auditor 子Agent 评审
- 验证体系简化为两层：AI 自检（格式/计数/列表/文件）+ Quality Auditor 子Agent（语义/评分/阻断）
- 清理所有文档中的脚本引用（SKILL-execution.md、template-artifacts.md、baton-protocol.md、各 Agent 文件）
- 统一 Layer 3/4/5 命名（chunk-03-harness.md 对齐 SKILL-execution.md）
- 修复 quality-auditor-agent.md 前置检查缺失 implement 场景参数
- 补充 designer-agent.md 缺失的 section 6（错误处理）
- 统一 baton 模板（artifacts 和 protocols 双向补齐）

**v4.4 更新内容（强制执行版）**:
- 新增"激活即执行"机制：AI自动沿状态机推进，无需用户逐一下令
- 新增"AI 不得"明确清单（5条禁令）
- 状态路由表新增"自动推进"列，一眼确认哪些阶段自动流转
- 新增"验证链规则"：计数验证、列表验证、文件验证，防虚假完成
- 新增"条件性跳过"机制：首次运行不跳过，后续按条件可跳过
- 修复 IMPLEMENT 阶段审核报告写入 _quality_audit_design.md 的覆盖 Bug
- 新增 _quality_audit_implement.md 产物文件和对应审核关卡
- 统一审核场景描述为5个阶段（原描述4个，遗漏 IMPLEMENT）
- （注：v4.4 引入的 run-checks.ps1 和 validate-artifact.ps1 增强已在 v4.5 移除，由 QA 子Agent 替代）

**v4.2 更新内容**:
- 三套路径体系统一为 `.agent/harness/`（运行时）+ `docs/harness/`（归档）
- SKILL.md 从 543 行精简至 ~183 行
- 删除重复状态路由表，消除两套流程体系冗余
- 清理 skill-manifest.yaml 未激活的路径定义
- 删除 3 个空壳占位文件，修正 legacy/README 矛盾描述
- 清理 debug-guide.md 过时引用，标注 PowerShell 脚本兼容性
- 补充 /reqplan guide 命令行为定义