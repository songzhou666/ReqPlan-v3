# ReqPlan-v3 执行指南

> **本文档是 ReqPlan-v3 的阶段执行手册。每次激活 Skill 后，按当前状态读取对应的阶段详解执行。**
>
> **核心原则**：不做完当前阶段的强制检查点，就无法进入下一阶段。
>
> **入口检查请参考 SKILL.md**：包含完整的强制入口检查清单、状态机、防跳过/防遗忘机制。

---

## 一、条件性跳过

在进入每个阶段前，检查跳过条件。满足条件时直接跳过该阶段，不执行任务。

### 跳过条件表

| 阶段 | 跳过条件 | 跳过处理 |
|------|----------|----------|
| DESIGN | 文档完善流程（流程6）明确标记跳过 | 标记 DESIGN 跳过，直接到 IMPLEMENT |
| IMPLEMENT | 设计评审流程（流程3）或文档完善流程（流程6）明确标记跳过 | 标记 IMPLEMENT 跳过，直接到 VERIFY |
| VERIFY | 实现阶段无代码变更（仅设计评审流程） | 标记 VERIFY 跳过，直接到 JUDGE |

### 跳过执行方式
1. 创建阶段产物（内容标注"该阶段已跳过，原因：[跳过条件]"）
2. 更新接力棒，标记该阶段为 ✅ 跳过
3. 直接进入下一阶段

### 跳过限制
- 同一阶段最多连续跳过 1 次
- 用户明确要求不跳过时 → 禁止跳过
- **首次运行（接力棒为 START）时禁止跳过任何阶段**

---

## 二、子Agent 约束（防绕过）

### 2.1 Task 子Agent 不是后门

当 AI 使用 `Task()` 工具启动子Agent 执行任务时，**子Agent 同样受本 Skill 约束**：

```markdown
- [ ] 子Agent 返回后，AI 必须回到当前阶段的状态机继续执行
- [ ] 子Agent 的产出必须写入产物文件，不能只在对话中展示
- [ ] 子Agent 不能替代状态机流转——比如子Agent完成了分析，不等于 ANALYZE 阶段已完成
- [ ] 子Agent 的产物必须通过验证链检查（计数/列表/文件）
```

### 2.2 Quality Auditor 子Agent 的特殊处理

Quality Auditor 子Agent 是在指定阶段内调用的审核子Agent，它不独立于状态机：

```markdown
- [ ] "拉起 Quality Auditor 子Agent" 是当前阶段的一个步骤，不是独立的阶段流转
- [ ] 审核完成后，AI 必须回到当前阶段的剩余步骤继续执行
- [ ] 审核报告必须写入文件，更新接力棒
```

### 2.3 search 子Agent 的限制

```markdown
- [ ] search 子Agent 仅用于信息搜索，不得用于执行实质性修改
- [ ] 使用 search 子Agent 前，必须已完成入口清单和首次响应守卫
- [ ] search 子Agent 返回后，必须回到当前阶段，而不是跳转执行
```

---


## 三、阶段执行通用流程

每个阶段必须按以下顺序执行，**跳过任何一步都无法进入下一阶段**：

> **关于验证体系的说明**：本 Skill 包含多层次的验证，各有侧重：
> - **Step 4（自检+验证链）**：AI 对自身产物的即时检查（计数/列表/文件），确保量化证据完整
> - **Step 5（阶段转换合法性检查）**：AI 按 SKILL.md 状态路由表校验阶段转换合法性、前置产物存在性
> - **Agent 自检清单**：各 Agent 定义文件中的格式/内容检查清单（如 Analyzer 的第5节）
> - **独立质量审核（Quality Auditor）**：由独立子Agent对各阶段产物的盲审（阻断点，见各阶段内的质量审核步骤）
> - **5层验证金字塔（VERIFY阶段）**：Verifier Agent 执行的 L1-L5 技术验证（静态检查→单元测试→构建集成→异常处理→流程合规）

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
┌───────────────────────────────────────────────┐
│ Step 4: 自检 + 验证链检查（自身产物验证）        │ ← 强制
│  ├─ 检查**本次阶段产物**是否完整、格式是否符合模板  │
│  ├─ 收集"计数"证据（声明数量和实际数量对比）      │
│  ├─ 收集"列表"证据（是否逐个列出所有项）          │
│  ├─ 收集"文件"证据（确认写入成功）                │
│  ├─ 检查流程图格式（使用Mermaid而非ASCII）        │
│  【未通过 → 阻断 → 补充后继续】                   │
└───────────────────────────────────────────────┘
                   ↓
┌───────────────────────────────────────────────┐
│ Step 5: 阶段转换合法性检查（前置产物验证）           │ ← 强制阻断
│  - AI 按 SKILL.md 状态路由表校验阶段转换合法性      │
│  - 校验接力棒状态与目标阶段是否匹配                  │
│  - 校验**前置产物**存在性 + 重试计数是否超限          │
│  【未通过 → 阻断 → 必须修复】                        │
└───────────────────────────────────────────────┘
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

## 四、核心流程与场景映射

### 4.1 7 个核心流程

| # | 流程 | 适用场景 | 执行路径 | 特殊说明 |
|:-:|------|----------|----------|----------|
| 1 | 完整项目流程 | 新项目启动，从需求到验收 | 完整7阶段 | 完整执行所有阶段 |
| 2 | 需求迭代流程 | 已有项目的需求更新 | 完整7阶段 | ANALYZE 关注变更影响范围 |
| 3 | 设计评审流程 | 架构设计、接口定义评审 | 跳过 IMPLEMENT | VERIFY 只验证设计文档质量 |
| 4 | 代码开发流程 | 代码实现、Bug 修复、功能开发 | 完整7阶段 | ANALYZE/DESIGN 可简化 |
| 5 | 测试优化流程 | 测试策略、用例设计、覆盖提升 | 完整7阶段 | IMPLEMENT 只写测试代码 |
| 6 | 文档完善流程 | 技术文档、API 文档补充 | 跳过 DESIGN | IMPLEMENT 编写文档 |
| 7 | 架构重构流程 | 架构优化、技术债务清理 | 完整7阶段 | DESIGN 重点输出重构计划 |
| 8 | **🪞 自绑定审查流程** | **审查/修复 Skill 自身** | **完整7阶段** | **不允许跳过，详见 chunk-02-flows 流程4** |

### 4.2 8 流程 ↔ 3 场景映射

在 SKILL.chunks 中定义了 **三大场景（开发/分析/修复）** 的分步引导。以下映射表帮助你将 8 个流程对接到对应的 chunk 场景：

| 流程 | 对应 chunk 场景 | 引导参考 |
|:----|:---------------|----------|
| 完整项目流程 | 开发场景 | [SKILL.chunks/chunk-02-flows.md](SKILL.chunks/chunk-02-flows.md) → 流程1（开发） |
| 需求迭代流程 | 开发场景 | chunk-02-flows.md → 流程1（开发） |
| 设计评审流程 | 分析场景 | chunk-02-flows.md → 流程2（分析） |
| 代码开发流程 | 开发场景 | chunk-02-flows.md → 流程1（开发） |
| 测试优化流程 | 开发/分析场景 | chunk-02-flows.md → 流程1+流程2 |
| 文档完善流程 | 开发场景 | chunk-02-flows.md → 流程1（开发），输出阶段参考 |
| 架构重构流程 | 修复场景 | chunk-02-flows.md → 流程3（修复） |
| 🪞 自绑定审查流程 | 元任务场景 | [SKILL.chunks/chunk-02-flows.md](SKILL.chunks/chunk-02-flows.md) → **流程4（自绑定审查）** |

**使用方式**：确定当前属于哪个流程后，查阅对应 chunk 场景的分步引导获取更细化的执行指引。

---

## 五、阶段详解（含强制检查点）

### 5.1 START 阶段

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
   mkdir -Force {项目路径}/.agent/harness/
   write {项目路径}/.agent/harness/_baton.md
   （状态保持 START，不提前修改）

3. [ ] 提取用户需求
   - 识别场景类型（开发/分析/修复）
   - 确认项目路径

4. [ ] 自检清单
   - [ ] 接力棒已创建/已读取
   - [ ] 用户需求已记录
   - [ ] 场景类型已识别

5. [ ] 检查点验证 — 校验阶段转换合法性
   - [ ] 接力棒文件存在
   - [ ] 接力棒包含状态字段
   - [ ] 用户需求已明确记录
   【确认满足 START→ANALYZE 条件】
   【未通过 → 阻断 → 必须修复】

6. [ ] 更新接力棒
   - 状态: START → ANALYZE
   - 记录: 用户需求摘要
   - 标记: START ✅

7. [ ] 第一行输出："当前状态：ANALYZE，下一步：生成需求分析报告"

8. [ ] 进入 ANALYZE 阶段
```

---

### 5.2 ANALYZE 阶段

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
   参考 `agents/analyzer-agent.md` 第5节执行自检
   （以 `artifacts/template-artifacts.md` 中 _analysis.md 的"完成后检查清单"为最终标准）
   - [ ] 产物完整、格式正确、内容完备（具体条目见 Agent 定义）
   - [ ] 验证链通过（计数/列表/文件验证）

4. [ ] 质量审核检查点（阻断点）
   - [ ] 读取质量审核配置（read {Skill路径}/agents/quality-auditor-agent.md + {Skill路径}/quality-control/00-quality-system.md）
   - [ ] 确定审核等级（L1/L2/L3）
   - [ ] 拉起 Quality Auditor 子Agent审核 _analysis.md（Task参数: 审核场景=analysis, 审核等级=L2/L3）
   - [ ] 审核通过 → 继续
   - [ ] 审核不通过（C级/D级）→ 读取审核报告的"待修复问题清单" → 返回修复
   - [ ] 写入审核报告文件：_quality_audit_analysis.md
   > 重审命名规则：首次→_quality_audit_analysis.md / 第1次修复重审→_quality_audit_analysis_v2.md / 第2次→_quality_audit_analysis_v3.md（详见 template-artifacts.md 6.2节）
   - [ ] 更新接力棒 quality_audit_analysis 状态

   **未通过 → 输出错误："ANALYZE 产物质量审核不通过，详见 _quality_audit_analysis.md" → 必须修复**
   **重试超过2次 → FAILED → 需人工介入**

5. [ ] 检查点验证（阻断点）
   - [ ] 产物文件存在
   - [ ] 格式符合模板
   - [ ] 内容完整（所有必需章节）
   - [ ] _quality_audit_analysis.md 存在（质量审核已通过）

   **未通过 → 输出错误："ANALYZE 产物不完整，缺少：[具体项]" → 必须修复**

6. [ ] 更新接力棒
   read {项目路径}/.agent/harness/_baton.md
   - 状态: ANALYZE ✅ → CONFIRM
   - 下一步: CONFIRM
   - quality_audit_analysis 行: 将"状态"列改为"已通过"（或"已打回"），"报告文件"列填入 _quality_audit_analysis.md
   write {项目路径}/.agent/harness/_baton.md

7. [ ] 进入 CONFIRM 阶段
```

---

### 5.3 CONFIRM 阶段

**入口**：ANALYZE 完成

**⚠️ 关键**：这是唯一的用户交互节点！**必须等待用户明确响应，不能自动继续！**

**前置检查（阻断条件）**：
```markdown
- [ ] _analysis.md 存在（执行：ls {项目路径}/.agent/harness/_analysis.md）
- [ ] _analysis.md 内容完整（执行：cat {项目路径}/.agent/harness/_analysis.md | head -20）
- [ ] _quality_audit_analysis.md 存在（质量审核已通过）

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
   
   ### 📋 质量审核结果
   
   > 分析阶段已通过独立质量审核，详见 `_quality_audit_analysis.md`。如有需要可查看审核报告了解分析质量评分。
   
   ---
   
   *确认后，我将进入设计阶段，制定详细的技术方案。*

3. [ ] 强制等待用户响应
   ⚠️ 阻断规则：在没有收到用户明确回复前，禁止执行任何其他操作
   ⚠️ 禁止行为：不要自动进入下一阶段，不要假设用户同意

4. [ ] 检查点验证（阻断点）
   - [ ] 用户明确回复"确认"/"同意"/"继续"/"是的"
   - [ ] 或用户回复包含肯定意味的表达
   
   **如果用户选择"修改" → 记录修改内容到接力棒 → 返回 ANALYZE**
   （返回 ANALYZE 后，AI 自动重新分析、更新鉴定棒，完成后再次进入 CONFIRM 等待用户确认）
   **如果用户选择"取消" → 状态设为 ABORT → 输出终止报告（见附录：终止报告模板）→ 流程结束**
   **如果用户未明确确认 → 阻断 → 重复步骤 2-3（再次展示摘要并等待）**

5. [ ] 检查点验证 — 校验阶段转换合法性
   - [ ] 用户已确认（CONFIRM ✅）
   - [ ] _analysis.md 存在且完整
   - [ ] _quality_audit_analysis.md 存在（质量审核已通过）
   【确认满足 CONFIRM→DESIGN 条件】
   **未通过 → 阻断 → 检查流程状态**

6. [ ] 更新接力棒
   命令：read {项目路径}/.agent/harness/_baton.md
   修改：状态 CONFIRM ✅ → DESIGN
   命令：write {项目路径}/.agent/harness/_baton.md

7. [ ] 进入 DESIGN 阶段
```

---

### 5.4 DESIGN 阶段

**入口**：CONFIRM 用户确认 或 JUDGE 判定 DESIGN_FIX

**前置检查（阻断条件）**：
```markdown
- [ ] 接力棒状态为 DESIGN
- [ ] 用户已确认（CONFIRM ✅）
- [ ] _analysis.md 存在且完整
- [ ] _quality_audit_analysis.md 存在（质量审核已通过）

**如果 _analysis.md 不存在 → 阻断 → 返回 ANALYZE**
```

**执行步骤**：

```markdown
1. [ ] 读取上下文
   - _analysis.md
   - {Skill路径}/agents/designer-agent.md

2. [ ] 判断模式
   - 如果是 DESIGN_FIX：读取 _verification.md 识别架构问题（仅当 _verification.md 存在时）
   - 如果是 NORMAL：从头开始设计

3. [ ] 调度 Designer Agent
   - 使用 worker 类型
   - 生成 _design.md

4. [ ] 自检清单
   参考 `agents/designer-agent.md` 的自检清单章节
   （以 `artifacts/template-artifacts.md` 中 _design.md 的"完成后检查清单"为最终标准）
   - [ ] 产物完整、格式正确、任务可执行、验证方案明确
   - [ ] 验证链通过（计数/列表/文件验证）

5. [ ] 质量审核检查点（阻断点）
   - [ ] 读取质量审核配置（read {Skill路径}/agents/quality-auditor-agent.md + {Skill路径}/quality-control/00-quality-system.md）
   - [ ] 确定审核等级（L1/L2/L3）
   - [ ] 拉起 Quality Auditor 子Agent审核 _design.md（Task参数: 审核场景=design, 审核等级=L2/L3）
   - [ ] 审核通过 → 继续
   - [ ] 审核不通过（C级/D级）→ 读取审核报告的"待修复问题清单" → 返回修复
   - [ ] 写入审核报告文件：_quality_audit_design.md
   > 重审命名规则：首次→_quality_audit_design.md / 第1次修复重审→_quality_audit_design_v2.md / 第2次→_quality_audit_design_v3.md（详见 template-artifacts.md 6.2节）
   - [ ] 更新接力棒 quality_audit_design 状态

   **未通过 → 输出错误："DESIGN 产物质量审核不通过，详见 _quality_audit_design.md" → 必须修复**
   **重试超过2次 → FAILED → 需人工介入**

6. [ ] 检查点验证（阻断点）
   - [ ] 产物文件存在
   - [ ] 格式符合模板
   - [ ] 任务列表可执行（有涉及文件和验证方式）
   - [ ] _quality_audit_design.md 存在（质量审核已通过）

   **未通过 → 输出错误："DESIGN 产物不完整或不可执行" → 必须修复**

7. [ ] 更新接力棒
   read {项目路径}/.agent/harness/_baton.md
   - 状态: DESIGN ✅ → IMPLEMENT
   - 模式: 重置为 NORMAL（即使此前为 DESIGN_FIX，修复后已恢复常规流程）
   - 下一步: IMPLEMENT
   - quality_audit_design 行: 将"状态"列改为"已通过"（或"已打回"），"报告文件"列填入 _quality_audit_design.md
   write {项目路径}/.agent/harness/_baton.md

8. [ ] 进入 IMPLEMENT 阶段
```

---

### 5.5 IMPLEMENT 阶段

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
   参考 `agents/implementer-agent.md` 的自检清单章节
   （以 `artifacts/template-artifacts.md` 中 _implementation.md 的"完成后检查清单"为最终标准）
   - [ ] _implementation.md 文件已创建，格式正确
   - [ ] 所有任务已按依赖顺序执行完毕（无遗漏任务）
   - [ ] 所有代码已保存到文件系统（不是只在对话中，逐文件验证）
   - [ ] 修改/新增文件清单与实际写入的文件一致
   - [ ] 未引入设计范围外的破坏性变更
   - [ ] 验证链通过（计数/列表/文件验证）

5. [ ] 质量审核检查点（阻断点）
   - [ ] 读取质量审核配置（read {Skill路径}/agents/quality-auditor-agent.md + {Skill路径}/quality-control/00-quality-system.md）
   - [ ] 拉起 Quality Auditor 子Agent 审核 _implementation.md（Task参数: 审核场景=implement, 审核等级=L2/L3）
   - [ ] 审核报告保存到 _quality_audit_implement.md
   > 重审命名规则：首次→_quality_audit_implement.md / 第1次修复重审→_quality_audit_implement_v2.md / 第2次→_quality_audit_implement_v3.md（详见 template-artifacts.md 6.2节）
   - [ ] 更新接力棒 quality_audit_implement 状态

   **未通过 → 检查质量问题类型：**
   - 代码规范问题 → 本阶段修复（不计入重试）
   - 设计理解错误 → 返回 DESIGN 阶段（计入 design_fix_retry）
   - **重试超过2次 → FAILED → 需人工介入**

6. [ ] 检查点验证（阻断点）
   - [ ] 产物文件存在
   - [ ] 代码已保存到文件
   - [ ] _quality_audit_implement.md 存在（质量审核已通过）

   **未通过 → 输出错误："代码必须保存到文件后才能进入验证" → 必须修复**

7. [ ] 更新接力棒
   - 状态: IMPLEMENT ✅ → VERIFY
   - 下一步: VERIFY

8. [ ] 进入 VERIFY 阶段
```

---

### 5.6 VERIFY 阶段

**入口**：IMPLEMENT 完成

**前置检查（阻断条件）**：
```markdown
- [ ] 接力棒状态为 VERIFY
- [ ] _design.md 存在
- [ ] _implementation.md 存在
- [ ] _quality_audit_design.md 存在（设计质量审核已通过）
- [ ] _quality_audit_implement.md 存在（实现质量审核已通过）

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
   参考 `agents/verifier-agent.md` 的自检清单章节
   （以 `artifacts/template-artifacts.md` 中 _verification.md 的"完成后检查清单"为最终标准）
   - [ ] _verification.md 文件已创建
   - [ ] 包含 Layer 1-5 验证结果
   - [ ] 判定结果明确（PASS/FAIL），如果 FAIL 包含错误分类
   - [ ] 验证链通过（计数/列表/文件验证）

5. [ ] 质量审核检查点（阻断点）
   - [ ] 读取质量审核配置（read {Skill路径}/agents/quality-auditor-agent.md + {Skill路径}/quality-control/00-quality-system.md）
   - [ ] 确定审核等级（L1/L2/L3）
   - [ ] 拉起 Quality Auditor 子Agent审核代码文件和 _implementation.md（Task参数: 审核场景=verify, 审核等级=L2/L3）
   - [ ] 审核通过 → 继续
   - [ ] 审核不通过（C级/D级）→ 读取审核报告的"待修复问题清单" → 返回修复
   - [ ] 写入审核报告文件：_quality_audit_verify.md
   > 重审命名规则：首次→_quality_audit_verify.md / 第1次修复重审→_quality_audit_verify_v2.md / 第2次→_quality_audit_verify_v3.md（详见 template-artifacts.md 6.2节）
   - [ ] 更新接力棒 quality_audit_verify 状态

   **未通过 → 输出错误："VERIFY 产物质量审核不通过，详见 _quality_audit_verify.md" → 必须修复**
   **重试超过2次 → FAILED → 需人工介入**

6. [ ] 检查点验证（阻断点）
   - [ ] 产物文件存在
   - [ ] 判定结果明确（PASS/FAIL）
   - [ ] 如果 FAIL，错误分类明确
   - [ ] _quality_audit_verify.md 存在（或已降级为自检模式）

   **未通过 → 输出错误："VERIFY 必须给出明确的 PASS/FAIL 判定" → 必须修复**

7. [ ] 更新接力棒
   read {项目路径}/.agent/harness/_baton.md
   - 状态: VERIFY ✅ → JUDGE
   - 下一步: JUDGE
   - quality_audit_verify 行: 将"状态"列改为"已通过"（或"已打回"），"报告文件"列填入 _quality_audit_verify.md
   write {项目路径}/.agent/harness/_baton.md

8. [ ] 进入 JUDGE 阶段
```

---

### 5.7 JUDGE 阶段

**入口**：VERIFY 完成

**前置检查（阻断条件）**：
```markdown
- [ ] 接力棒状态为 JUDGE
- [ ] _verification.md 存在且包含判定结果
- [ ] _quality_audit_verify.md 存在（或已降级为自检模式）

**如果不存在 → 阻断 → 返回 VERIFY**
```

**执行步骤**：

```markdown
1. [ ] 读取上下文
   - _verification.md
   - _quality_audit_verify.md（验证质量审核报告）
   - {Skill路径}/agents/quality-auditor-agent.md

2. [ ] 提取综合判定依据
   - 验证阶段的通过/失败状态（来自 _verification.md）
   - 验证质量审核的等级（来自 _quality_audit_verify.md）

3. [ ] 拉起 Quality Auditor 做最终全局审核
   - [ ] 拉起子Agent审核所有产物文件（_analysis.md, _design.md, _implementation.md, _verification.md）
   - [ ] 输出六维度全局评分报告：_quality_audit_judge.md
   - [ ] 获取最终等级（A/B/C/D）

4. [ ] 决策（检查点验证）

   > **决策优先级规则**：
   > 1. **Quality Auditor 最终等级为 D → 无论 VERIFY 结果如何，必须阻断返回修复**
   > 2. **VERIFY 报告 FAIL → 按错误分类路由修复路径**
   > 3. **VERIFY 报告 PASS + QA 等级 A/B/C → 通过**
   >
   > 即：Quality Auditor 的最终等级是最高优先级判定。VERIFY 报告的 PASS/FAIL
   > 用于决定修复方向，但无法覆盖 QA 的 D 级判定。

   第一步：检查质量审核最终等级（_quality_audit_judge.md）
   - [ ] D级 → 阻断，读取审核报告的"待修复问题清单" → 返回对应阶段修复
   - [ ] A/B/C级 → 继续下一步判定

   第二步：按 VERIFY 结果路由
   如果 PASS ✅:
     - [ ] A级/B级 → 直接 DONE
     - [ ] C级 → 记录改进项到接力棒，DONE
     - [ ] 更新接力棒: 状态 JUDGE ✅ → DONE
     - read {项目路径}/.agent/harness/_baton.md
     - quality_audit_judge 行: 将"状态"列改为"已通过"，"分数"列填入{分数}
     - write {项目路径}/.agent/harness/_baton.md
     - [ ] 输出完成报告（包含最终等级和评分）
     - [ ] 提供后续选项：
       ```
       ### 🔄 后续操作
       
       流程已完成。请选择：
       - ✅ **结束**：流程结束，所有产物保留在 .agent/harness/
       - 🆕 **启动新任务**：自动重置接力棒为 START，开始新的任务流程
         （执行方式：read _baton.md → 重置状态为 START，模式为 NORMAL，
          重试计数归零，质量审核追踪全部重置，阶段完成情况全部取消勾选
          → write _baton.md → 进入 START 阶段引导用户）
       ```
     - [ ] 流程结束

   如果 ARCHITECTURE_VIOLATION 🔧:
     - [ ] 检查 design_fix_retry < 2
     【确认满足 JUDGE→DESIGN 条件】
     - [ ] 更新接力棒: 状态 JUDGE ➡ DESIGN(修复模式), 模式 DESIGN_FIX, design_fix_retry += 1
     - [ ] 进入 DESIGN 阶段（修复模式）
     - [ ] 如果 design_fix_retry >= 2 → 状态 FAILED → 流程结束

   如果 REVIEW_VIOLATION 🔧:
     【确认满足 JUDGE→IMPLEMENT 条件】
     - [ ] 更新接力棒: 状态 JUDGE ➡ IMPLEMENT(修复模式), 模式 REVIEW_FIX
     - [ ] 进入 IMPLEMENT 阶段（修复模式）

   如果 RUNTIME_FAILURE 🔄:
     - [ ] 检查 retry < 2
     【确认满足 JUDGE→IMPLEMENT 条件】
     - [ ] 更新接力棒: 状态 JUDGE ➡ IMPLEMENT(重试模式), 模式 RETRY_FIX, retry += 1
     - [ ] 进入 IMPLEMENT 阶段（重试模式）
     - [ ] 如果 retry >= 2 → 状态 FAILED → 流程结束

   如果 ENVIRONMENT ⚠️:
     - [ ] 更新接力棒: 记录环境问题
     - [ ] 输出环境问题的通知和建议
     - [ ] 等待用户处理环境后手动继续
   
   **ENVIRONMENT 恢复路径**：
   - 用户解决环境问题后，手动更新接力棒状态为 ENVIRONMENT（保持当前阶段）
   - AI 读取到 ENVIRONMENT 状态后：恢复执行被中断的质量审核或阻断检查
   - 如果环境问题无法解决 → 手动将状态设为 FAILED → 流程结束
```

---

### FAILED 状态恢复流程

当接力棒状态变为 FAILED 时（重试超过上限），AI 应按以下流程处理：

```markdown
1. [ ] 读取接力棒，确认失败原因
   read {项目路径}/.agent/harness/_baton.md
   - 检查重试计数（design_fix_retry / retry）
   - 检查质量审核失败阶段（quality_audit_analysis / _design / _implement / _verify）
   - 检查问题记录和错误日志

2. [ ] 展示失败摘要给用户
   - 失败阶段：{阶段名}
   - 失败原因：{错误描述}
   - 最后一次失败详情：{具体问题}
   - 剩余产物：{已完成的产物清单}

3. [ ] 提供恢复选项
   - 🔄 **从指定阶段重跑**：用户修复根本原因后，手动修改接力棒状态为指定阶段（如 DESIGN），
     设置模式为 NORMAL，重置重试计数为 0，重新进入流程
   - ❌ **终止流程（ABORT）**：输出终止报告，流程结束
   - ⚠️ **报告环境问题**：如果失败原因为环境问题，等待用户处理环境后继续

4. [ ] 记录恢复决定到接力棒
```

**注意**：AI 不能自动发起 FAILED→恢复的转换。必须等待用户介入并明确选择恢复路径后，
AI 根据用户选择执行对应操作。恢复后需清除相关重试计数，防止重复计数导致无限循环。

---

## 六、文件路径速查

```bash
# Skill 根目录
{Skill路径}/

# Agent 模板
- agents/analyzer-agent.md
- agents/designer-agent.md
- agents/implementer-agent.md
- agents/verifier-agent.md
- agents/quality-auditor-agent.md          [新增] 质量审核Agent

# 质量体系（新增）
- quality-control/
- quality-control/00-quality-system.md     [新增] 质量审核体系定义

# 协议文档
- protocols/baton-protocol.md — 接力棒协议（模板、生命周期、续跑）

# 产物模板
- artifacts/template-artifacts.md

# 分块加载
- SKILL.chunks/chunk-index.yaml
- SKILL.chunks/chunk-01-guide.md
- SKILL.chunks/chunk-02-flows.md
- SKILL.chunks/chunk-03-harness.md
- SKILL.chunks/chunk-04-chain.md
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
{项目路径}/.agent/harness/_quality_audit_analysis.md    [新增] 分析审核报告
{项目路径}/.agent/harness/_quality_audit_design.md      [新增] 设计审核报告
{项目路径}/.agent/harness/_quality_audit_implement.md   [新增] 实现审核报告
{项目路径}/.agent/harness/_quality_audit_verify.md      [新增] 验证审核报告
{项目路径}/.agent/harness/_quality_audit_judge.md       [新增] 最终判定报告
```

---

---

## 七、阶段内续跑与手动恢复机制

### 7.1 自动续跑（接力棒检测）

当 Skill 被重新激活时，通过读取接力棒自动识别当前状态并续跑：

```
流程：
1. 读取 {项目路径}/.agent/harness/_baton.md
2. 解析 "当前状态" 字段
3. 按状态路由表进入对应阶段
4. 读取对应阶段的产物体检当前进度
5. 从阶段入口检查点开始执行
```

### 7.2 手动指定续跑命令

当自动续跑无法满足需求时（如阶段内中途失败），支持手动指定从任意阶段续跑：

| 命令/操作 | 用途 | 操作方式 |
|-----------|------|---------|
| 设置接力棒状态 | 手动指定目标阶段 | 编辑 `_baton.md`，将"当前状态"改为目标阶段（如 VERIFY） |
| 重设重试计数 | 清空或重置重试次数 | 编辑 `_baton.md`，将"重试计数"或"design_fix_retry"设为 0 |
| 跳过/覆盖检查 | 强制从某个检查点继续 | 手动在接力棒"阶段完成情况"中勾选已完成项，然后重新激活 |

**限制条件**：
- 不能跨阶段跳跃（如从 VERIFY 直接跳到 JUDGE）
- 跳过阶段对应的前置产物必须已存在

### FAILED 状态恢复流程

如果某个阶段在执行中途失败（如文件写入失败、Task 调用失败），按以下步骤恢复：

```markdown
1. [ ] 确认失败原因（读取错误信息）
2. [ ] 修复问题（如重新创建目录、重新执行 Task）
3. [ ] 无需修改接力棒状态（阶段状态不变）
4. [ ] 从失败点之前的检查点重新执行
5. [ ] 如果失败重复发生，考虑进入人工介入流程
```

### 6.4 重试超限处理

当 JUDGE 阶段的修复循环达到重试上限时：

```markdown
1. 输出 FAILED 报告（见附录A.3）
2. 接力棒状态设为 FAILED
3. 记录失败原因到接力棒和历史
4. 建议人工介入
```

---

## 八、超范围场景处理引导

> 当用户需求超出 ReqPlan-v3 能力范围时，AI 应遵循以下引导规范。
> 补充引导参考：参考 [SKILL.md](../SKILL.md) 核心机制中的"超范围场景处理引导"章节。

### 8.1 用户要求执行不支持的编程语言

```
场景：用户要求使用 ReqPlan-v3 分析/修复一个 COBOL 项目。
处理：
1. AI 不拒绝，但说明当前验证体系主要支持主流语言
2. 建议用户提供明确的验证命令，AI 可自定义执行
3. 如果用户无法提供验证方案，降级为"仅分析不出代码"模式
```

### 8.2 用户要求合并多个不相关任务到同一个流程

```
场景：用户说"帮我重构这个模块，同时给它加一个 CI/CD 流水线，再写一篇博客文章"
处理：
1. 识别出这是3个完全不相干的任务（重构 + CI/CD配置 + 写作）
2. 建议用户选择优先级最高的任务先执行
3. 剩余任务记入接力棒的"待办清单"，当前流程 DONE 后自动发起
```

### 8.3 用户要求跳过强制检查点

```
场景：用户说"不用验证了，直接上线吧"
处理：
1. 说明质量审核和验证是阻断点，不可跳过
2. 解释跳过验证可能带来的风险（线上故障、回归Bug）
3. 如果用户坚持，提供折中方案：降级验证强度（如仅做静态检查，跳过单元测试）
```

### 8.4 用户要求的功能需要外部资源

```
场景：用户说"帮我部署到 AWS 并配置 CDN"
处理：
1. 说明 AI 无法直接执行外部部署操作
2. 提供替代方案：生成部署脚本、Terraform 配置或 Docker Compose 文件
3. 引导用户将需求转化为"本地可执行的产物生成"
```

### 8.5 用户对 AI 输出不满意要求立即重做

```
场景：用户说"这个设计太差，全部重来，我不要走流程了"
处理：
1. 先理解不满意的具体原因（设计方向错误？细节不完善？）
2. 如果是设计方向错误 → 使用"中断处理机制"选择"立即重置"回到 ANALYZE
3. 如果只是细节不完善 → 在当前阶段修复即可
4. 解释直接重走流程反而更慢，建议定位具体问题后精准修复
```

---

## 附录A：终止报告模板

当流程进入 DONE / ABORT / FAILED 状态时，使用以下模板输出最终报告。

### A.1 DONE 报告（流程成功完成）

```markdown
# ✅ ReqPlan 流程完成报告

## 项目信息
- 项目路径: {项目路径}
- 流程时间: {开始时间} ~ {结束时间}

## 任务完成清单

| # | 阶段 | 状态 | 产物 | 说明 |
|---|------|------|------|------|
| 1 | START | ✅ | _baton.md | 启动 |
| 2 | ANALYZE | ✅ | _analysis.md / _quality_audit_analysis.md | 分析通过 |
| 3 | CONFIRM | ✅ | - | 用户确认 |
| 4 | DESIGN | ✅ | _design.md / _quality_audit_design.md | 设计通过 |
| 5 | IMPLEMENT | ✅ | _implementation.md / _quality_audit_implement.md | 实现完成 |
| 6 | VERIFY | ✅ | _verification.md / _quality_audit_verify.md | 验证通过 |
| 7 | JUDGE | ✅ | _quality_audit_judge.md | 全局判定通过 |

## 最终产物
- 全部产物位于 `{项目路径}/.agent/harness/`
- 历史归档位于 `{项目路径}/docs/harness/`

## 总结
- 总耗时: {时长}
- 重试次数: {n}
- 质量评分: {评分}
```

### A.2 ABORT 报告（用户取消）

```markdown
# ⏹️ ReqPlan 流程已终止

## 项目信息
- 项目路径: {项目路径}
- 流程时间: {开始时间} ~ {终止时间}
- 终止阶段: {终止时的状态名}
- 终止原因: 用户选择取消

## 已完成的工作

| # | 阶段 | 状态 | 产物 |
|---|------|------|------|
| 1 | START | ✅ | _baton.md |
| 2 | ANALYZE | ✅ | _analysis.md |
| ... | ... | ... | ... |

## 说明
流程因用户取消而终止。产物保留在 `{项目路径}/.agent/harness/` 中可供参考。
如需重新启动，可手动设置接力棒状态并重新开始。
```

### A.3 FAILED 报告（流程执行失败）

```markdown
# ❌ ReqPlan 流程执行失败

## 项目信息
- 项目路径: {项目路径}
- 流程时间: {开始时间} ~ {失败时间}
- 失败阶段: {失败时的状态名}

## 失败原因

```
{描述失败的详细原因：如重试超限、阻断检查未通过等}
```

## 已完成的产物

| # | 阶段 | 状态 | 产物 |
|---|------|------|------|
| 1 | START | ✅ | _baton.md |
| ... | ... | ... | ... |

## 恢复建议
1. 修复问题后，手动更新接力棒状态为需要重新运行的阶段
2. 重新执行 `{命令或步骤}`
3. 如问题无法解决，请联系项目管理员

## 错误日志
{相关错误信息或日志输出}
```
