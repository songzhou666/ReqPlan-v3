# ReqPlan-v3 执行指南 (v4.1)

> **本文档是 ReqPlan-v3 的核心执行手册。每次激活 Skill 时，必须按照本指南执行。**
>
> **核心原则**：不做完当前阶段的强制检查点，就无法进入下一阶段。

---

## 一、激活后的强制第一步

### 1.1 状态自检（必须执行，不做无法继续）

每次收到用户输入，立即执行以下自检：

```markdown
## 强制自检清单

- [ ] 1. 我已读取接力棒（_baton.md）
- [ ] 2. 我知道当前状态（START/ANALYZE/CONFIRM/DESIGN/IMPLEMENT/VERIFY/JUDGE）
- [ ] 3. 我知道当前阶段该做什么
- [ ] 4. 我已读取当前阶段对应的 Agent 指南

**阻断规则**：以上任一未勾选 → 停止执行 → 先完成自检
```

### 1.2 接力棒读取流程

```bash
# 步骤 1：尝试读取接力棒
read {项目路径}/.agent/harness/_baton.md

# 步骤 2：判断结果
if 文件存在:
    提取当前状态
    按状态续跑
else:
    创建目录 mkdir -p {项目路径}/.agent/harness/
    创建接力棒（状态=START）
    进入 START 阶段
```

---

## 二、阶段执行通用流程

每个阶段必须按以下顺序执行，**跳过任何一步都无法进入下一阶段**：

```
┌─────────────────────────────────────────┐
│ Step 1: 读取接力棒                       │ ← 强制
│  - 确认当前状态                           │
│  - 确认当前模式（NORMAL/FIX）              │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ Step 2: 读取阶段指南                     │ ← 强制
│  - 读取对应的 Agent 文档                   │
│  - 读取前置产物（如 _analysis.md）         │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ Step 3: 执行阶段任务                     │
│  - 按 Agent 指南执行任务                   │
│  - 生成产物文件                           │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ Step 4: 自检清单                         │ ← 强制
│  - 检查产物是否完整                        │
│  - 检查格式是否符合模板                     │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ Step 5: 检查点验证（Checkpoint）          │ ← 强制阻断
│  - 验证产物完整性                          │
│  - 验证格式正确性                          │
│  - 验证可执行性（如任务列表）               │
│  【未通过 → 阻断 → 必须修复】              │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ Step 6: 更新接力棒（必须实际写入文件）    │ ← 强制
│  - 执行：read {项目路径}/.agent/harness/_baton.md
│  - 修改内容：更新状态为"完成"              │
│  - 修改内容：更新产物清单                  │
│  - 修改内容：记录问题和决策                │
│  - 执行：write {项目路径}/.agent/harness/_baton.md
│  - 验证：再次 read 确认写入成功            │
│  【未实际写入 → 阻断 → 必须重新写入】      │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ Step 7: 进入下一阶段                     │
│  - 按状态机流转                           │
│  - 在回复中明确写出："状态已更新为：[状态]" │
└─────────────────────────────────────────┘
```

---

## 三、状态机与流程

### 3.1 基础状态机

```
START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE
              ↑        │                      ↓
              └────────┘      ┌─────────────────┼─────────────────┐
              (修改)          ↓                 ↓                 ↓
                           ✅ DONE           🔧 DESIGN          🔄 IMPLEMENT
                                           (修复模式)          (重试模式)

CONFIRM 分支:
- ✅ 确认 → DESIGN
- ✏️  修改 → ANALYZE
- ❌ 取消 → ABORT

终止状态: DONE, ABORT, FAILED
```

### 3.2 7 个核心流程的差异化执行路径

#### 流程 1: 完整项目流程
**适用场景**：新项目启动，从需求到验收的全流程。
**执行路径**：`START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE → DONE`
**说明**：完整执行所有阶段。

#### 流程 2: 需求迭代流程
**适用场景**：已有项目的需求更新和迭代。
**执行路径**：`START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE → DONE`
**说明**：完整执行所有阶段，但 ANALYZE 阶段重点关注变更影响范围。

#### 流程 3: 设计评审流程
**适用场景**：架构设计、接口定义、数据库设计的评审。
**执行路径**：`START → ANALYZE → CONFIRM → DESIGN → VERIFY → JUDGE → DONE`
**说明**：跳过 IMPLEMENT 阶段，VERIFY 阶段只验证设计文档质量。

#### 流程 4: 代码开发流程
**适用场景**：代码实现、Bug 修复、功能开发。
**执行路径**：`START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE → DONE`
**说明**：ANALYZE 阶段可简化，DESIGN 阶段可简化为任务列表。

#### 流程 5: 测试优化流程
**适用场景**：测试策略制定、用例设计、覆盖提升。
**执行路径**：`START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE → DONE`
**说明**：IMPLEMENT 阶段只编写测试代码，VERIFY 阶段验证测试有效性。

#### 流程 6: 文档完善流程
**适用场景**：技术文档、API 文档的补充。
**执行路径**：`START → ANALYZE → CONFIRM → IMPLEMENT → VERIFY → JUDGE → DONE`
**说明**：跳过 DESIGN 阶段，IMPLEMENT 阶段编写文档，VERIFY 阶段验证文档质量。

#### 流程 7: 架构重构流程
**适用场景**：架构优化、技术债务清理。
**执行路径**：`START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE → DONE`
**说明**：DESIGN 阶段重点输出重构计划，VERIFY 阶段增加回归测试。

### 3.3 流程选择速查

| 流程 | 跳过阶段 | 特殊说明 |
|------|----------|----------|
| 完整项目 | 无 | 完整执行 |
| 需求迭代 | 无 | 关注变更影响 |
| 设计评审 | IMPLEMENT | 只验证设计 |
| 代码开发 | 无 | ANALYZE 可简化 |
| 测试优化 | 无 | 只编写测试 |
| 文档完善 | DESIGN | 只编写文档 |
| 架构重构 | 无 | 增加回归测试 |

---

## 四、阶段详解（含强制检查点）

### 4.1 START 阶段

**入口**：用户首次触发 ReqPlan-v3

**执行步骤**：

```markdown
1. [ ] 读取接力棒
   read {项目路径}/.agent/harness/_baton.md

2. [ ] 如果不存在，创建目录和接力棒
   mkdir -p {项目路径}/.agent/harness/
   write {项目路径}/.agent/harness/_baton.md

3. [ ] 提取用户需求
   - 识别场景类型（开发/分析/修复）
   - 确认项目路径

4. [ ] 更新接力棒
   - 状态: START → ANALYZE
   - 记录: 用户需求摘要

5. [ ] 自检清单
   - [ ] 接力棒已创建/已读取
   - [ ] 用户需求已记录
   - [ ] 场景类型已识别

6. [ ] 检查点验证
   - [ ] 接力棒文件存在
   - [ ] 接力棒包含状态字段
   - [ ] 状态为 ANALYZE

7. [ ] 更新接力棒（标记 START 完成）

8. [ ] 进入 ANALYZE 阶段
```

---

### 4.2 ANALYZE 阶段

**入口**：START 完成 或 CONFIRM 用户选择修改

**前置检查（阻断条件）**：
```markdown
- [ ] 接力棒状态为 ANALYZE 或 START
- [ ] 项目路径已确认
- [ ] 用户需求已明确

**如果任一不满足 → 阻断 → 返回 START 阶段**
```

**执行步骤**：

```markdown
1. [ ] 读取 Analyzer Agent 指南
   read {Skill路径}/agents/analyzer-agent.md

2. [ ] 调度 Analyzer Agent
   - 使用 explorer 类型
   - 生成 _analysis.md

3. [ ] 自检清单
   - [ ] _analysis.md 文件已创建
   - [ ] 文件包含 "# 需求分析报告" 标题
   - [ ] 文件包含 "## 基本信息" 章节
   - [ ] 文件包含 "## 需求理解" 章节
   - [ ] 文件包含 "## 技术栈" 章节
   - [ ] 文件包含 "## 涉及文件" 章节
   - [ ] 文件包含 "## 约束条件" 章节

4. [ ] 检查点验证（阻断点）
   - [ ] 产物文件存在
   - [ ] 格式符合模板
   - [ ] 内容完整（所有必需章节）

   **未通过 → 输出错误："ANALYZE 产物不完整，缺少：[具体项]" → 必须修复**

5. [ ] 更新接力棒
   - 状态: ANALYZE ✅
   - 下一步: CONFIRM

6. [ ] 进入 CONFIRM 阶段
```

---

### 4.3 CONFIRM 阶段

**入口**：ANALYZE 完成

**⚠️ 关键**：这是唯一的用户交互节点！**必须等待用户明确响应，不能自动继续！**

**前置检查（阻断条件）**：
```markdown
- [ ] _analysis.md 存在（执行：ls {项目路径}/.agent/harness/_analysis.md）
- [ ] _analysis.md 内容完整（执行：cat {项目路径}/.agent/harness/_analysis.md | head -20）

**如果不存在 → 阻断 → 返回 ANALYZE 阶段**
```

**执行步骤**：

```markdown
1. [ ] 读取 _analysis.md
   命令：read {项目路径}/.agent/harness/_analysis.md

2. [ ] 展示摘要（必须包含以下内容）
   ========================================
   📋 需求确认摘要
   ========================================
   
   🎯 核心功能：
   - {功能1}
   - {功能2}
   
   🛠️ 技术栈：{技术栈}
   
   📁 涉及文件：
   - {文件1}
   - {文件2}
   
   ⚠️ 关键约束：
   - {约束1}
   
   ========================================
   请确认以上理解是否正确？
   回复【确认】继续进入设计阶段
   回复【修改】返回分析阶段调整需求
   回复【取消】终止本次任务
   ========================================

3. [ ] 强制等待用户响应
   ⚠️ 阻断规则：在没有收到用户明确回复前，禁止执行任何其他操作
   ⚠️ 禁止行为：不要自动进入下一阶段，不要假设用户同意

4. [ ] 检查点验证（阻断点）
   - [ ] 用户明确回复"确认"/"同意"/"继续"/"是的"
   - [ ] 或用户回复包含肯定意味的表达
   
   **如果用户选择"修改" → 记录修改内容到接力棒 → 返回 ANALYZE**
   **如果用户选择"取消" → 状态设为 ABORT → 输出终止报告 → 流程结束**
   **如果用户未明确确认 → 阻断 → 重复步骤 2-3（再次展示摘要并等待）**

5. [ ] 更新接力棒
   命令：read {项目路径}/.agent/harness/_baton.md
   修改：状态 CONFIRM ✅
   命令：write {项目路径}/.agent/harness/_baton.md

6. [ ] 进入 DESIGN 阶段
```

---

### 4.4 DESIGN 阶段

**入口**：CONFIRM 用户确认 或 JUDGE 判定 DESIGN_FIX

**前置检查（阻断条件）**：
```markdown
- [ ] 接力棒状态为 DESIGN
- [ ] 用户已确认（CONFIRM ✅）
- [ ] _analysis.md 存在且完整

**如果 _analysis.md 不存在 → 阻断 → 返回 ANALYZE**
```

**执行步骤**：

```markdown
1. [ ] 读取上下文
   - _analysis.md
   - {Skill路径}/agents/designer-agent.md

2. [ ] 判断模式
   - 如果是 DESIGN_FIX：读取 _verification.md 识别架构问题
   - 如果是 NORMAL：从头开始设计

3. [ ] 调度 Designer Agent
   - 使用 worker 类型
   - 生成 _design.md

4. [ ] 自检清单
   - [ ] _design.md 文件已创建
   - [ ] 文件包含 "# 技术设计文档" 标题
   - [ ] 文件包含 "## 技术方案概述" 章节
   - [ ] 文件包含 "## 模块划分" 章节
   - [ ] 文件包含 "## 任务列表" 章节
   - [ ] 每个任务有明确的"涉及文件"
   - [ ] 每个任务有明确的"验证方式"
   - [ ] 文件包含 "## 验证方案" 章节（Layer 1-5）

5. [ ] 检查点验证（阻断点）
   - [ ] 产物文件存在
   - [ ] 格式符合模板
   - [ ] 任务列表可执行（有涉及文件和验证方式）

   **未通过 → 输出错误："DESIGN 产物不完整或不可执行" → 必须修复**

6. [ ] 更新接力棒
   - 状态: DESIGN ✅
   - 下一步: IMPLEMENT

7. [ ] 进入 IMPLEMENT 阶段
```

---

### 4.5 IMPLEMENT 阶段

**入口**：DESIGN 完成 或 JUDGE 判定 REVIEW_FIX/RETRY_FIX

**前置检查（阻断条件）**：
```markdown
- [ ] 接力棒状态为 IMPLEMENT
- [ ] _design.md 存在且完整

**如果 _design.md 不存在 → 阻断 → 返回 DESIGN**
```

**执行步骤**：

```markdown
1. [ ] 读取上下文
   - _design.md
   - {Skill路径}/agents/implementer-agent.md

2. [ ] 按任务列表执行
   for each 任务 in 任务列表（按依赖顺序）:
     - 理解任务要求
     - 编写代码（保存到文件）
     - 记录进度

3. [ ] 生成实现摘要
   - _implementation.md

4. [ ] 自检清单
   - [ ] _implementation.md 文件已创建
   - [ ] 文件包含 "# 实现摘要" 标题
   - [ ] 文件包含 "## 完成的任务" 章节
   - [ ] 所有代码已保存到文件系统（不是只在对话中）

5. [ ] 检查点验证（阻断点）
   - [ ] 产物文件存在
   - [ ] 代码已保存到文件

   **未通过 → 输出错误："代码必须保存到文件后才能进入验证" → 必须修复**

6. [ ] 更新接力棒
   - 状态: IMPLEMENT ✅
   - 下一步: VERIFY

7. [ ] 进入 VERIFY 阶段
```

---

### 4.6 VERIFY 阶段

**入口**：IMPLEMENT 完成

**前置检查（阻断条件）**：
```markdown
- [ ] 接力棒状态为 VERIFY
- [ ] _design.md 存在
- [ ] _implementation.md 存在

**如果任一不存在 → 阻断 → 返回对应阶段**
```

**执行步骤**：

```markdown
1. [ ] 读取上下文
   - _design.md
   - {Skill路径}/agents/verifier-agent.md

2. [ ] 执行 5 层验证
   - Layer 1: 静态检查 (pylint/ruff/mypy)
   - Layer 2: 单元测试 (pytest)
   - Layer 3: 构建集成 (python -m py_compile)
   - Layer 4: 异常处理 (边界测试)
   - Layer 5: 流程合规 (产物完整性)

3. [ ] 生成验证报告
   - _verification.md

4. [ ] 自检清单
   - [ ] _verification.md 文件已创建
   - [ ] 文件包含 "# 验证报告" 标题
   - [ ] 文件包含 Layer 1-5 的验证结果
   - [ ] 文件包含 "## 综合判定" 章节
   - [ ] 判定结果为 PASS 或 FAIL
   - [ ] 如果 FAIL，包含错误分类

5. [ ] 检查点验证（阻断点）
   - [ ] 产物文件存在
   - [ ] 判定结果明确（PASS/FAIL）
   - [ ] 如果 FAIL，错误分类明确

   **未通过 → 输出错误："VERIFY 必须给出明确的 PASS/FAIL 判定" → 必须修复**

6. [ ] 更新接力棒
   - 状态: VERIFY ✅
   - 下一步: JUDGE

7. [ ] 进入 JUDGE 阶段
```

---

### 4.7 JUDGE 阶段

**入口**：VERIFY 完成

**前置检查（阻断条件）**：
```markdown
- [ ] 接力棒状态为 JUDGE
- [ ] _verification.md 存在且包含判定结果

**如果不存在 → 阻断 → 返回 VERIFY**
```

**执行步骤**：

```markdown
1. [ ] 读取 _verification.md

2. [ ] 提取判定结果

3. [ ] 决策（检查点验证）

   如果 PASS ✅:
     - [ ] 更新接力棒: 状态 DONE ✅
     - [ ] 输出完成报告
     - [ ] 流程结束

   如果 ARCHITECTURE_VIOLATION 🔧:
     - [ ] 检查 design_fix_retry < 2
     - [ ] 更新接力棒: 状态 DESIGN, 模式 DESIGN_FIX, design_fix_retry += 1
     - [ ] 进入 DESIGN 阶段（修复模式）
     - [ ] 如果 design_fix_retry >= 2 → 状态 FAILED → 流程结束

   如果 REVIEW_VIOLATION 🔧:
     - [ ] 更新接力棒: 状态 IMPLEMENT, 模式 REVIEW_FIX
     - [ ] 进入 IMPLEMENT 阶段（修复模式）

   如果 RUNTIME_FAILURE 🔄:
     - [ ] 检查 retry < 2
     - [ ] 更新接力棒: 状态 IMPLEMENT, 模式 RETRY_FIX, retry += 1
     - [ ] 进入 IMPLEMENT 阶段（重试模式）
     - [ ] 如果 retry >= 2 → 状态 FAILED → 流程结束

   如果 ENVIRONMENT ⚠️:
     - [ ] 更新接力棒: 记录环境问题
     - [ ] 输出环境问题的通知和建议
     - [ ] 等待用户处理环境后手动继续
```

---

## 五、防跳跃机制

### 5.1 阶段跳跃阻断表

| 当前状态 | 允许进入 | 禁止进入 |
|----------|----------|----------|
| START | ANALYZE | 其他所有 |
| ANALYZE | CONFIRM | DESIGN, IMPLEMENT, VERIFY, JUDGE |
| CONFIRM | DESIGN, ANALYZE(修改), ABORT(取消) | IMPLEMENT, VERIFY, JUDGE |
| DESIGN | IMPLEMENT | VERIFY, JUDGE |
| IMPLEMENT | VERIFY | JUDGE |
| VERIFY | JUDGE | 其他所有 |
| JUDGE | DONE, DESIGN(修复), IMPLEMENT(修复/重试), FAILED | 其他所有 |

### 5.2 跳跃阻断输出模板

```
╔══════════════════════════════════════════════════════════════╗
║  ❌ 阶段跳跃阻断                                              ║
╠══════════════════════════════════════════════════════════════╣
║  当前状态: [当前状态]                                         ║
║  目标状态: [目标状态]                                         ║
║                                                              ║
║  正确路径:                                                   ║
║  [当前状态] → [正确下一状态] → ... → [目标状态]              ║
║                                                              ║
║  请按正确路径执行。                                           ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 六、产物检查清单

### 6.1 _analysis.md 必须包含

```markdown
- [ ] # 需求分析报告（标题）
- [ ] ## 基本信息（时间、分析者、场景类型）
- [ ] ## 需求理解（核心功能、涉及角色、数据实体）
- [ ] ## 技术栈
- [ ] ## 涉及文件
- [ ] ## 约束条件
- [ ] ## 可复用资源
```

### 6.2 _design.md 必须包含

```markdown
- [ ] # 技术设计文档（标题）
- [ ] ## 技术方案概述
- [ ] ## 模块划分
- [ ] ## 接口定义（REST API）
- [ ] ## 数据模型
- [ ] ## 任务列表（带依赖，每个任务有涉及文件和验证方式）
- [ ] ## 验证方案（Layer 1-5）
```

### 6.3 _implementation.md 必须包含

```markdown
- [ ] # 实现摘要（标题）
- [ ] ## 基本信息（时间、实现者、模式）
- [ ] ## 完成的任务
- [ ] ## 涉及的文件（新增/修改）
- [ ] ## 问题记录
```

### 6.4 _verification.md 必须包含

```markdown
- [ ] # 验证报告（标题）
- [ ] ## Layer 1: 静态检查
- [ ] ## Layer 2: 单元测试
- [ ] ## Layer 3: 构建集成
- [ ] ## Layer 4: 异常处理
- [ ] ## Layer 5: 流程合规
- [ ] ## 综合判定: PASS / FAIL（必须明确）
- [ ] ## 错误分类（如果 FAIL）
```

---

## 七、接力棒更新模板

### 7.1 强制更新内容

每个阶段结束后，必须包含以下字段：

```markdown
# 🔄 ReqPlan-v3 接力棒

## 元信息
| 字段 | 值 |
|------|-----|
| 项目 | {项目名称} |
| 开始时间 | {ISO 8601} |
| 最后更新 | {ISO 8601} |
| 当前状态 | {START/ANALYZE/CONFIRM/DESIGN/IMPLEMENT/VERIFY/JUDGE/DONE/ABORT/FAILED} |
| 模式 | {NORMAL/DESIGN_FIX/REVIEW_FIX/RETRY_FIX} |
| 重试计数 | {0/1/2} |
| design_fix_retry | {0/1/2} |

## 进度追踪
- [x] START - {时间} ✅
- [x] ANALYZE - {时间} ✅
- [x] CONFIRM - {时间} ✅
- [ ] DESIGN - 进行中 ⏳
- [ ] IMPLEMENT - 待开始
- [ ] VERIFY - 待开始
- [ ] JUDGE - 待开始

## 产物清单
- [x] `.agent/harness/_analysis.md` ✅
- [x] `.agent/harness/_design.md` ✅
- [ ] `.agent/harness/_implementation.md` ⏳
- [ ] `.agent/harness/_verification.md` ⏳

## 当前阶段详情
### {状态名称}（进行中）
**进度**: {百分比}%
**已完成**: {列表}
**进行中**: {任务}
**待完成**: {列表}

## 问题记录
### ⚠️ 阻塞问题
{问题列表}

### 💡 待确认事项
{待确认事项}

## 下一步行动
1. {具体任务1}
2. {具体任务2}

---
*最后更新: {ISO 8601}*
```

---

## 八、文件路径速查

```bash
# Skill 根目录
{Skill路径}/

# Agent 模板
agents/analyzer-agent.md
agents/designer-agent.md
agents/implementer-agent.md
agents/verifier-agent.md

# 协议文档
protocols/baton-protocol.md
protocols/phase-protocol.md

# 产物模板
artifacts/template-artifacts.md
```

```bash
# 项目目录
{项目路径}/

# 接力棒和产物
{项目路径}/.agent/harness/_baton.md
{项目路径}/.agent/harness/_analysis.md
{项目路径}/.agent/harness/_design.md
{项目路径}/.agent/harness/_implementation.md
{项目路径}/.agent/harness/_verification.md
```

---

## 九、常见问题

### 9.1 接力棒不存在

```markdown
情况：首次触发

解决方案：
1. 创建目录
2. 创建接力棒（状态=START）
3. 继续 START → ANALYZE
```

### 9.2 产物丢失

```markdown
情况：接力棒显示存在，但文件不存在

解决方案：
1. 识别缺失的产物
2. 重新生成
3. 更新接力棒
```

### 9.3 用户中断

```markdown
情况：用户突然停止

解决方案：
1. 立即更新接力棒
2. 记录当前进度
3. 提示续跑方式
```

### 9.4 AI 忘记当前状态

```markdown
情况：AI 不知道自己在哪个阶段

解决方案：
1. 强制读取接力棒
2. 按接力棒状态执行
3. 如果接力棒损坏 → 重新初始化
```

---

*本文档是 ReqPlan-v3 的核心执行手册*
*版本: v4.1*
*更新: 2026-05-20*
