# ReqPlan-v3 执行指南 (v4.1)

> **本文档是 ReqPlan-v3 的阶段执行手册。每次激活 Skill 后，按当前状态读取对应的阶段详解执行。**
>
> **核心原则**：不做完当前阶段的强制检查点，就无法进入下一阶段。
>
> **入口检查请参考 SKILL.md**：包含完整的强制入口检查清单、状态机、防跳过/防遗忘机制。

---

## 一、阶段执行通用流程

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
│  - 调用 run-checks.ps1 校验阶段转换合法性  │
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

## 二、核心流程与场景映射

### 2.1 7 个核心流程

| # | 流程 | 适用场景 | 执行路径 | 特殊说明 |
|:-:|------|----------|----------|----------|
| 1 | 完整项目流程 | 新项目启动，从需求到验收 | 完整7阶段 | 完整执行所有阶段 |
| 2 | 需求迭代流程 | 已有项目的需求更新 | 完整7阶段 | ANALYZE 关注变更影响范围 |
| 3 | 设计评审流程 | 架构设计、接口定义评审 | 跳过 IMPLEMENT | VERIFY 只验证设计文档质量 |
| 4 | 代码开发流程 | 代码实现、Bug 修复、功能开发 | 完整7阶段 | ANALYZE/DESIGN 可简化 |
| 5 | 测试优化流程 | 测试策略、用例设计、覆盖提升 | 完整7阶段 | IMPLEMENT 只写测试代码 |
| 6 | 文档完善流程 | 技术文档、API 文档补充 | 跳过 DESIGN | IMPLEMENT 编写文档 |
| 7 | 架构重构流程 | 架构优化、技术债务清理 | 完整7阶段 | DESIGN 重点输出重构计划 |

### 2.2 7 流程 ↔ 3 场景映射

在 SKILL.chunks 中定义了 **三大场景（开发/分析/修复）** 的分步引导。以下映射表帮助你将 7 个流程对接到对应的 chunk 场景：

| 流程 | 对应 chunk 场景 | 引导参考 |
|:----|:---------------|----------|
| 完整项目流程 | 开发场景 | [SKILL.chunks/chunk-02-flows.md](SKILL.chunks/chunk-02-flows.md) → 流程1（开发） |
| 需求迭代流程 | 开发场景 | chunk-02-flows.md → 流程1（开发） |
| 设计评审流程 | 分析场景 | chunk-02-flows.md → 流程2（分析） |
| 代码开发流程 | 开发场景 | chunk-02-flows.md → 流程1（开发） |
| 测试优化流程 | 开发/分析场景 | chunk-02-flows.md → 流程1+流程2 |
| 文档完善流程 | 开发场景 | chunk-02-flows.md → 流程1（开发），输出阶段参考 |
| 架构重构流程 | 修复场景 | chunk-02-flows.md → 流程3（修复） |

**使用方式**：确定当前属于哪个流程后，查阅对应 chunk 场景的分步引导获取更细化的执行指引。

---

## 三、阶段详解（含强制检查点）

### 3.1 START 阶段

**入口**：用户首次触发 ReqPlan-v3

**执行步骤**：

```markdown
0. [ ] 确定项目路径（元任务兜底）
   - 用户明确指定了路径？→ 使用该路径
   - 否则 → 使用当前工作目录（本次对话的 cwd）
   - 注意：即使任务是"审查 Skill 本身"也必须选一个路径
   【路径模糊不是跳过状态机的理由】

1. [ ] 读取接力棒
   read {项目路径}/.agent/harness/_baton.md

2. [ ] 如果不存在，创建目录和接力棒
   mkdir -p {项目路径}/.agent/harness/
   write {项目路径}/.agent/harness/_baton.md
   （状态保持 START，不提前修改）

3. [ ] 提取用户需求
   - 识别场景类型（开发/分析/修复）
   - 确认项目路径

4. [ ] 自检清单
   - [ ] 接力棒已创建/已读取
   - [ ] 用户需求已记录
   - [ ] 场景类型已识别

5. [ ] 检查点验证 — 调用 run-checks 校验阶段转换
   - [ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage ANALYZE
   - [ ] 接力棒文件存在
   - [ ] 接力棒包含状态字段
   【此时 baton 状态为 START，run-checks 校验 START→ANALYZE 合法性】
   【未通过 → 阻断 → 必须修复】

6. [ ] 更新接力棒
   - 状态: START → ANALYZE
   - 记录: 用户需求摘要
   - 标记: START ✅

7. [ ] 第一行输出："当前状态：ANALYZE，下一步：生成需求分析报告"

8. [ ] 进入 ANALYZE 阶段
```

---

### 3.2 ANALYZE 阶段

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
   - [ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage CONFIRM
   【此时 baton 状态为 ANALYZE，校验 ANALYZE→CONFIRM 合法性】

   **未通过 → 输出错误："ANALYZE 产物不完整，缺少：[具体项]" → 必须修复**

5. [ ] 更新接力棒
   - 状态: ANALYZE ✅ → CONFIRM
   - 下一步: CONFIRM

6. [ ] 进入 CONFIRM 阶段
```

---

### 3.3 CONFIRM 阶段

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
   
   ---
   
   ## 📋 需求分析摘要
   
   > 请花 1 分钟确认需求理解是否正确。
   
   ### 核心功能
   
   | # | 功能点 | 优先级 | 说明 |
   |---|--------|--------|------|
   | 1 | {功能1} | P0 | {说明} |
   | 2 | {功能2} | P1 | {说明} |
   | 3 | {功能3} | P2 | {说明} |
   
   ### 技术栈
   
   - 后端：{技术栈}
   - 前端：{技术栈}
   - 数据库：{数据库}
   - 其他：{其他依赖}
   
   ### 涉及文件
   
   - `{文件1}`
   - `{文件2}`
   - `{文件3}`
   
   ### 关键约束
   
   - {约束1}
   - {约束2}
   
   ---
   
   ### ⚠️ 请确认
   
   **需求理解是否正确？**
   
   - ✅ **确认（继续设计）**：开始设计技术方案
   - ✏️  **修改需求**：描述需要修改的内容，我会重新分析
   - ❌  **取消**：终止 ReqPlan 流程
   
   ---
   
   *确认后，我将进入设计阶段，制定详细的技术方案。*

3. [ ] 强制等待用户响应
   ⚠️ 阻断规则：在没有收到用户明确回复前，禁止执行任何其他操作
   ⚠️ 禁止行为：不要自动进入下一阶段，不要假设用户同意

4. [ ] 检查点验证（阻断点）
   - [ ] 用户明确回复"确认"/"同意"/"继续"/"是的"
   - [ ] 或用户回复包含肯定意味的表达
   
   **如果用户选择"修改" → 记录修改内容到接力棒 → 返回 ANALYZE**
   **如果用户选择"取消" → 状态设为 ABORT → 输出终止报告 → 流程结束**
   **如果用户未明确确认 → 阻断 → 重复步骤 2-3（再次展示摘要并等待）**

5. [ ] 检查点验证 — 调用 run-checks 校验阶段转换
   - [ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage DESIGN
   【此时 baton 状态为 CONFIRM，校验 CONFIRM→DESIGN 合法性】
   **未通过 → 阻断 → 检查流程状态**

6. [ ] 更新接力棒
   命令：read {项目路径}/.agent/harness/_baton.md
   修改：状态 CONFIRM ✅ → DESIGN
   命令：write {项目路径}/.agent/harness/_baton.md

7. [ ] 进入 DESIGN 阶段
```

---

### 3.4 DESIGN 阶段

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
   - [ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage IMPLEMENT
   【此时 baton 状态为 DESIGN，校验 DESIGN→IMPLEMENT 合法性】

   **未通过 → 输出错误："DESIGN 产物不完整或不可执行" → 必须修复**

6. [ ] 更新接力棒
   - 状态: DESIGN ✅ → IMPLEMENT
   - 下一步: IMPLEMENT

7. [ ] 进入 IMPLEMENT 阶段
```

---

### 3.5 IMPLEMENT 阶段

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
   - [ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage VERIFY
   【此时 baton 状态为 IMPLEMENT，校验 IMPLEMENT→VERIFY 合法性】

   **未通过 → 输出错误："代码必须保存到文件后才能进入验证" → 必须修复**

6. [ ] 更新接力棒
   - 状态: IMPLEMENT ✅ → VERIFY
   - 下一步: VERIFY

7. [ ] 进入 VERIFY 阶段
```

---

### 3.6 VERIFY 阶段

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
   - [ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage JUDGE
   【此时 baton 状态为 VERIFY，校验 VERIFY→JUDGE 合法性】

   **未通过 → 输出错误："VERIFY 必须给出明确的 PASS/FAIL 判定" → 必须修复**

6. [ ] 更新接力棒
   - 状态: VERIFY ✅ → JUDGE
   - 下一步: JUDGE

7. [ ] 进入 JUDGE 阶段
```

---

### 3.7 JUDGE 阶段

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
     - [ ] 调用 run-checks.ps1 -ProjectPath {项目路径} -Stage DONE
     【此时 baton 状态为 JUDGE，校验 JUDGE→DONE 合法性】
     - [ ] 更新接力棒: 状态 JUDGE ✅ → DONE
     - [ ] 输出完成报告
     - [ ] 流程结束

   如果 ARCHITECTURE_VIOLATION 🔧:
     - [ ] 检查 design_fix_retry < 2
     - [ ] 调用 run-checks.ps1 -ProjectPath {项目路径} -Stage DESIGN
     【此时 baton 状态为 JUDGE，校验 JUDGE→DESIGN 合法性】
     - [ ] 更新接力棒: 状态 JUDGE ✅, 模式 DESIGN_FIX, design_fix_retry += 1
     - [ ] 进入 DESIGN 阶段（修复模式）
     - [ ] 如果 design_fix_retry >= 2 → 状态 FAILED → 流程结束

   如果 REVIEW_VIOLATION 🔧:
     - [ ] 调用 run-checks.ps1 -ProjectPath {项目路径} -Stage IMPLEMENT
     【此时 baton 状态为 JUDGE，校验 JUDGE→IMPLEMENT 合法性】
     - [ ] 更新接力棒: 状态 JUDGE ✅, 模式 REVIEW_FIX
     - [ ] 进入 IMPLEMENT 阶段（修复模式）

   如果 RUNTIME_FAILURE 🔄:
     - [ ] 检查 retry < 2
     - [ ] 调用 run-checks.ps1 -ProjectPath {项目路径} -Stage IMPLEMENT
     【此时 baton 状态为 JUDGE，校验 JUDGE→IMPLEMENT 合法性】
     - [ ] 更新接力棒: 状态 JUDGE ✅, 模式 RETRY_FIX, retry += 1
     - [ ] 进入 IMPLEMENT 阶段（重试模式）
     - [ ] 如果 retry >= 2 → 状态 FAILED → 流程结束

   如果 ENVIRONMENT ⚠️:
     - [ ] 更新接力棒: 记录环境问题
     - [ ] 输出环境问题的通知和建议
     - [ ] 等待用户处理环境后手动继续
```

---

## 四、文件路径速查

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

# 分块加载
SKILL.chunks/chunk-index.yaml
SKILL.chunks/chunk-01-guide.md
SKILL.chunks/chunk-02-flows.md
SKILL.chunks/chunk-03-harness.md
SKILL.chunks/chunk-04-chain.md
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

*本文档是 ReqPlan-v3 的阶段执行手册*
*版本: v4.1*
*更新: 2026-05-21*
