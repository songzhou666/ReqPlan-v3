# ReqPlan 变更日志

## v4.9 (2026-05-23)
### 中断处理机制版

**新增**：
- **用户中断处理机制（全阶段适用）**：当用户在状态机执行过程中提出额外需求/问题/调整要求时，AI 暂停当前操作并提供 3 个选项供用户选择（立即重置/记入 TODO/仅讨论），详见 SKILL.md 第4节
- 覆盖"激活即执行"自动推进行为，用户主动介入时优先响应中断

**修复**：
- 回应遗留讨论项：弥补了非 CONFIRM 阶段用户中途打断无正式处理路径的空白

## v4.8 (2026-05-24)
### 系统审查修复版 + 自绑定增强版

**修复之前发现的所有问题**：
- **版本号4重不一致**：SKILL.md frontmatter v4.4/body v4.5、SKILL-execution.md/baton-protocol.md v4.4、agent文件 4.2、quality-auditor-agent 1.0、实际内容已含v4.6变更 — 全部统一为v4.6，agent统一为4.4，QA agent统一为1.1
- **质量审核缺失于检查清单**：template-artifacts.md 中 DESIGN/IMPLEMENT/VERIFY 的"完成后检查清单"缺失质量审核触发步骤 — 全部补充
- **baton审核状态缺失**：`quality_audit_judge` 状态选项缺少"已打回" — 补充为"未审核/已通过/已打回"
- **产物列表前缀缺失**：SKILL.md frontmatter 质量审核报告列表第二个起丢了 `_quality_audit_` 前缀 — 修正为完整路径
- **跳越条件不完整**：仅定义IMPLEMENT/VERIFY跳过，但chunk-02-flows定义DESIGN也可跳过（文档完善流程）— 补充DESIGN跳过条件
- **子章节编号不符**：`## 三、核心流程与场景映射` 下使用 `### 2.1` / `### 2.2`，应使用 `### 3.1` / `### 3.2` — 修正
- **质量审核引用路径不一致**：`read agents/quality-auditor-agent.md + quality-control/00-quality-system.md` 缺少 `{Skill路径}`前缀 — 统一补充
- **JUDGE回环语义问题**：JUDGE→DESIGN/IMPLEMENT修复回环时使用"JUDGE"（语义矛盾，流程还在进行中）— 改为`JUDGE -> DESIGN(修复模式)` / `JUDGE -> IMPLEMENT(修复模式)`

**新增自绑定机制（防止AI绕过状态机）**：
- **自绑定条款**（SKILL.md）：声明所有规则无条件适用于元任务（审查/修复Skill自身），列出4个不构成绕过依据的借口，明确定义违规后果
- **首次响应守卫**（SKILL.md）：最外层防线，AI第一次回复必须满足3个条件（第一行输出状态、写出实际命令执行记录、禁止包含实质性工作），列举5种违规模式
- **扩展AI不得清单**：新增3条禁令（元任务绕过、先读文件绕过、Task子Agent绕过）
- **子Agent约束**（SKILL-execution.md 新增二章）：明确Task子Agent返回后必须回到状态机、Quality Auditor是阶段内步骤不是独立流转、search子Agent的限制
- **自绑定审查流程4**（chunk-02-flows.md 新增）：专为元任务设计的6步流程，完整7阶段**禁止跳过**
- **元任务场景检测**（chunk-01-guide.md）：激活确认表新增元任务类，附绑定说明
- **核心流程表扩展**（SKILL-execution.md）：从7个流程扩展为8个，新增自绑定审查流程

**涉及文件**：
- SKILL.md：自绑定条款、首次响应守卫、AI不得扩展
- SKILL-execution.md：新增子Agent约束章、章节编号重构(2→7)、流程表扩展(7→8)
- SKILL.chunks/chunk-01-guide.md：元任务场景检测
- SKILL.chunks/chunk-02-flows.md：新增流程4自绑定审查
- 6-docs/changelog.md：本次变更记录

---

## v4.6 (2026-05-24)

### 代入式演练修复版 — 修复演练发现的执行层面问题

**Bug 修复**：
- **消除自检清单三体问题**：SKILL-execution.md 中 4 个阶段的自检清单全部改为"参考对应 Agent 定义"的简洁引用，消除与 template-artifacts.md、Agent 定义的三份清单冲突。统一以 template-artifacts.md 为最终标准
- **统一质量审核与检查点顺序**：ANALYZE/DESIGN/VERIFY 阶段的质量审核（原 Step 5/6）和检查点验证（原 Step 4/5）顺序对调，全部统一为"自检 → 质量审核 → 检查点 → 更新接力棒"
- **明确 JUDGE 决策优先级**：补充决策优先级规则——Quality Auditor 最终等级为最高优先级（D 级阻断），VERIFY 的 PASS/FAIL 用于决定修复方向
- **扩充 IMPLEMENT 自检清单**：从 4 项扩展至 6 项，补充任务完成度检查、文件一致性检查、破坏性变更检查
- **补充 FAILED 恢复流程**：新增 FAILED 状态恢复流程（读取baton → 展示失败摘要 → 提供恢复选项），明确 AI 不能自动恢复，需用户介入
- **DESIGN_FIX 模式复位**：DESIGN 阶段更新接力棒时增加"模式重置为 NORMAL"步骤
- **START 阶段最小化接力棒模板**：新增 30 行最小化模板，进入 ANALYZE 时再扩展为完整模板
- **多语言验证命令**：verifier-agent.md Layer 1-4 验证命令表扩展 Java（Gradle/Maven）和 Go 命令

**涉及文件**：
- SKILL-execution.md：4 阶段自检清单引用化、审核+检查点顺序统一、JUDGE 决策优先级、IMPLEMENT 清单扩充、FAILED 恢复流程
- protocols/baton-protocol.md：新增 START 阶段最小化模板
- agents/verifier-agent.md：验证命令表扩展 Java/Go
- 6-docs/changelog.md：本次变更记录

---

## v4.5 (2026-05-24)

### 质量审核修复版 — 修复审查发现的所有问题

**Bug 修复**：
- **统一版本号**：SKILL.md metadata 与 body 统一为 v4.4（原 metadata v4.3、body v4.4），SKILL-execution.md、README.md、manifest.yaml 等 7 个文件版本全部统一
- **消除 CONFIRM 矛盾**：移除条件性跳过中 CONFIRM 自动确认规则，CONFIRM 阶段严格执行"必须等待用户确认"
- **补全 VERIFY 前置检查**：SKILL-execution.md VERIFY 阶段前置检查补充 `_quality_audit_implement.md`（原遗漏，与 run-checks.ps1 不一致）
- **修正章节编号**：SKILL-execution.md 修复了两个"二、"的编号重复（二→三→四→五→六），子章节编号同步修正
- **调整审核场景顺序**：quality-auditor-agent.md 中的审核场景章节按 execution 顺序排列（analysis→design→implement→verify→judge）
- **精简通用流程**：合并 Step 4（自检清单）和 Step 4.5（验证链检查）为单一"自检+验证链检查"步骤，消除边界模糊
- **移除 TODO_RESOLVE 占位**：条件性跳过表中移除未实现的 TODO_RESOLVE 未来扩展标注
- **添加验证体系说明**：通用流程头部新增验证体系关系说明，澄清 5 层验证概念各自的用途和定位
- **明确元任务路径规则**：补充 cwd 定义和后备检查条件说明
- **自检清单权威来源**：在验证链规则中声明 artifacts/template-artifacts.md 为 Agent 自检清单的最终标准

**涉及文件**：
- SKILL.md：版本号统一、元任务路径规则补充、验证链规则补充
- SKILL-execution.md：版本号统一、CONFIRM 跳过移除、VERIFY 前置检查补全、章节编号修正、通用流程合并、验证体系说明
- README.md：版本号统一
- 1-manifest/skill-manifest.yaml：版本号统一
- agents/quality-auditor-agent.md：审核场景章节顺序调整
- artifacts/template-artifacts.md：版本号统一
- protocols/baton-protocol.md：版本号统一
- 6-docs/changelog.md：本次变更记录

---

## v4.4 (2026-05-23)

### 强制执行版 — 参照 ManualGen 强化自执行机制

**新机制**：
- **"激活即执行"**：AI 激活后自动沿状态机推进，无需用户逐一下令
- **"AI 不得"明确清单**：5条禁令（等待命令、问下一步、跳产物、口头展示、路径模糊）
- **状态路由表新增"自动推进"列**：每阶段标注 自动 / 等待用户
- **验证链规则**：计数验证 + 列表验证 + 文件验证 + 流程图验证，防止虚假完成
- **条件性跳过机制**：首次运行不跳过，后续按条件跳过特定阶段

**Bug 修复**：
- **IMPLEMENT 审核报告覆盖 Bug**：原指向 `_quality_audit_design.md` 导致被 DESIGN 审核报告覆盖，改为 `_quality_audit_implement.md`
- **审核场景数不一致**：chunk-03-harness.md 描述"4个阶段"漏了 IMPLEMENT，修正为5个
- **run-checks 缺检查**：DESIGN/VERIFY/IMPLEMENT 入口共缺3个质量审核产物检查，已补齐
- **validate-artifact 缺 quality_audit_implement**：ValidateSet 新增类型

**涉及文件**：
- SKILL.md：新增"激活即执行"+"AI 不得"+验证链规则+自动推进列；产物列表新增 _quality_audit_implement.md
- SKILL-execution.md：新增条件性跳过机制+验证链检查步骤；IMPLEMENT 审核报告路径修复
- chunk-03-harness.md：审核关卡数 4→5，新增实现质量审核关卡
- protocols/baton-protocol.md：质量审核追踪表新增 quality_audit_implement 行；产物清单新增对应项
- artifacts/template-artifacts.md：baton 模板同步更新审核追踪表+产物清单；命名规则扩展为5阶段
- scripts/harness/run-checks.ps1：DESIGN/VERIFY/IMPLEMENT 补齐缺失的 QA 产物检查
- scripts/harness/validate-artifact.ps1：ValidateSet 新增 quality_audit_implement
- 6-docs/changelog.md：本次变更记录

---

## v4.3 (2026-05-21)

### 自强制机制（P0）— 阻止AI绕过状态机

**问题背景**：在 v4.2 实际使用中发现，AI 在激活 Skill 后可以不执行入口检查就直接进入实质性工作，完全跳过了状态机的 START→ANALYZE→... 流程，导致不创建接力棒、不产出文档、不更新状态。

**修复方案**：
- **0. 路径兜底规则**：新增"确定项目路径"规则（用户指定 > cwd > workspace 根），明确元任务（审查 Skill 本身）也必须选路径，不以路径模糊为由跳过
- **1. 强制入口清单**：将入口检查从"建议"升级为"硬性阻断"——入口清单未全部完成，禁止执行任何实质性工作
- **2. 自检闭环**：每次回复结束必须检查是否输出了"当前状态"和"下一步"，偏离则立即修正
- **3. 输出契约**：每步回复第一行必须输出"当前状态：[状态名]，下一步：[操作]"

**涉及文件**：
- SKILL.md：激活后强制执行部分重写，How it works 新增第 0 步和第 6 步
- SKILL-execution.md：START 阶段新增"确定项目路径"步骤和强制输出行
- phase-protocol.md：START 阶段新增任务 0（路径决定）、任务 7（强制输出）

---

## v4.2 (2026-05-21)

### 路径体系统一（P0）

**统一三套路径为一套**
- chunk-02-flows.md：init 流程从创建 AGENTS.md + `.agent/plans/` 改为创建 `.agent/harness/_baton.md` + `docs/harness/history.yaml`
- chunk-02-flows.md：Step 产出路径从 `.agent/plans/` / `.agent/requirements/` / `.agent/plans/{date}-{fix}.md` 统一为 `.agent/harness/_*.md`
- chunk-02-flows.md：会话恢复从读取 `.agent/plans/` 改为读取 `.agent/harness/_baton.md`
- chunk-04-chain.md：新增"两层路径模型"章节，明确 `.agent/harness/`（运行时）与 `docs/harness/`（归档）的职责分工
- skill-manifest.yaml：废弃 `docs/reqplan/` 和 `9-data/` 未激活路径，替换为 `runtime_state` + `long_term_archive`

### SKILL.md 精简（P1）

**543 行 → ~183 行（精简 66%）**
- 删除重复的状态路由表（L102-113 与 L141-152 重复）
- 将详细检查点清单、接力棒模板等优化为精简引用，细节委托至 SKILL-execution.md
- 简化入口检查为简练的 2 步流程

### 冗余清理（P1）

**文件删除**：
- 删除 `6-docs/quick-reference.md`（空壳占位："已移除"）
- 删除 `6-docs/adoption-guide.md`（空壳占位："已移动"）
- 删除 `6-docs/troubleshooting.md`（空壳占位："已移动"）

**文档修正**：
- legacy/README.md：修正与实际代码的矛盾描述，更新归档内容表和 v4.1 变更说明

### 过时引用清理（P2）

- debug-guide.md：移除 `INIT → START` 过时状态转移，更新产物契约表，替换 `.agent/plans/` 引用为 `.agent/harness/`
- scripts/harness/README.md：标注 9 个 PowerShell 脚本的 v4.1 兼容性状态（3 个兼容 + 6 个 v3.3 遗留）
- chunk-01-guide.md：补充 `/reqplan guide` 命令行为定义和执行步骤

### 版本一致性

- SKILL.md frontmatter: `4.1` → `4.2`
- SKILL.md body: `v4.1 (强制检查点版)` → `v4.2 (路径统一版)`
- skill-manifest.yaml: `4.1` → `4.2`
- README.md: 版本号同步

---

## v4.1 (2026-05-21)

### 强制检查点版

**核心机制**：
- 增加强制检查点机制（Checkpoint）
- 增加阶段跳跃阻断
- 增加产物缺失阻断
- 增加状态自检清单
- 增加防遗忘机制
- 优化自然语义触发词库
- 目录结构整合（消除v3.3/v4.1冗余）
- 产物模板统一为 artifacts/template-artifacts.md（唯一源）
- 激活 SKILL.chunks 分块加载
- 废弃 _manifest.md 5合1模式，保留独立文件产物模式

---

## v3.4 (2026-05-14)

### 一致性修复

**P0 — 版本矛盾修复**
- core-verification.md body 版本号 `3.1.0` 更正为 `3.3`，与标题 v3.3 一致
- schema-context.md 示例数据中 `version: "3.1"` 和 `skill_version: "3.1.0"` 统一为 `"3.3"`

**P1 — 版本号统一（15个文件）**
- 7 个 core 文件：`3.1.0` → `3.2.0`
  core-doc-generation.md, core-error-handling.md, core-file-sync.md, core-intent-analysis.md, core-review.md, core-task-management.md, core-workflow-engine.md
- 5 个 schema 文件：`3.0.0`/`3.1.0` → `3.2.0`
  schema-state.md, schema-task.md, schema-testcase.md, schema-writeback.md, schema-landing-zone.md
- 3 个 template 文件：`3.1`/`3.1.0` → `3.2`/`3.2.0`
  template-design.md, template-req.md, template-control-plane.md

**P1 — 英文标题行补充（8个core文件）**
- core-doc-generation.md, core-error-handling.md, core-file-io.md, core-intent-analysis.md, core-review.md, core-state-management.md, core-task-management.md, core-verification.md
- 统一格式：第一行为 `# Core Xxx`（英文），第二行为 `# 中文标题`

**P1 — 引用部分补充**
- schema-state.md / schema-task.md / schema-testcase.md 新增 `**引用**` 字段
- template-design.md / template-plan.md / template-req.md 新增 `**引用**` 字段

**P1 — 上下文管理标记精简**
- core-state-management.md 中 `# 上下文管理` YAML 注释改为 `# 上下文有效期（完整策略参见 core-context-tracker.md）`，消除与 core-context-tracker.md 的内容重叠

**P2 — schema-context 补充 JSON Schema**
- 新增完整 JSON Schema 定义（draft-07），覆盖 context 全部 7 个对象属性
- 包含 flow_history / global_tasks / snapshots / context_expiry / metadata 嵌套结构验证

**P2 — SKILL.md 元信息完善**
- frontmatter 新增 `author: songzhou`、`version: 3.3`
- 详细文档部分新增 `scripts/harness/` 脚本引用（run-checks.ps1 / validate-intent-analysis.ps1）
- 移除 body 中的冗余版本号

---

## v3.3 (2026-05-14)

### 缺陷修复

**P1 — state_version / lock_version 不一致修复**
- core-state-management.md 补充缺失的 `state_version: 3` 字段
- schema-state-lock.md 中 `lock_version: 3` 统一为 `lock_version: 5`
- 示例中锁版本号从 3→4 更正为 5→6

**P2 — context-tracker 命令命名不一致修复**
- core-context-tracker.md 中 `/reqplan context archive list` 更正为 `archive_list`，与 core-actions.md 保持一致
- core-context-tracker.md 引用列表补充 `4-schemas/schema-writeback.md`

**P3 — flow-full.md 回写链路补全**
- Step 2（需求评审）、Step 4（设计评审）、Step 5（代码实现）、Step 6（代码审计）、Step 7（测试执行）、Step 9（验收交付）补全 `writeback_target` 字段

### 重构

**触发条件收敛（P2-2）**
- SKILL.md When 从 7 条细项收敛为 3 条通用分类
- 自然语言触发精简为引用式描述

**轻量路径标注（P2-3）**
- 7 个流程文件标注入 Harness 级别适配
- 13 个 Action 全部标注 `harness_levels` 字段

**职责边界清理**
- core-state-management.md 任务状态定义引用 core-task-management.md
- core-state-management.md 上下文超时逻辑移除，统一委托给 core-context-tracker.md
- core-workflow-engine.md 新增编排层次图（流程层→管道层→动作层）
- schema-state.md 补充双存储模型说明：state.yaml 为索引摘要，详细内容在目录层级

**文档与脚本**
- P2-1：template-agents.md 精简（194→145 行）
- P4：scripts/harness/README.md 移除幽灵脚本 `check-constraints.ps1` 引用
- P4：命名约定示例由 `validate-plan.ps1` 更正为 `validate-entry-points.ps1`

**P9 — validate-entry-points.ps1 增强**
- 新增 Test-NpmScript()：读取 package.json 检查 npm/yarn 脚本命令
- 新增 Test-PythonModule()：解析嵌套 Python 模块路径
- 新增 Test-AnyCommand()：统一检查系统命令与 npm/yarn 脚本
- code block 检测正则增强：`^```$` → `^```\w*$`，支持语言标记

**P10 — verification 与 review 边界标注**
- core-verification.md 补充边界说明：负责自动化工具检查（lint/typecheck/test）
- core-review.md 补充边界说明：负责人工/半自动判断（设计一致性、代码可读性等）

**P11 — core-file-operations → core-file-io 重命名**
- 文件名更明确，避免与 core-file-sync.md 概念重叠
- 更新 SKILL.md、template-agents.md、core-file-sync.md、changelog.md 共 4 处引用

**P12 — flow-full.md 步骤格式统一**
- 9 个步骤从 YAML code block 转换为 Markdown 章节格式，与其他 6 个流程文件保持一致
- 步骤结构：目标 / 引导 / 输出 / writeback_target / 完成检查 / 门控
- 保留流程完成确认内容，转为普通代码块

---

## v3.2.1 (2026-05-14)

### 新增功能

**任务完整管道（全新模块）**
- 创建 `3-core/core-task-pipeline.md`：5 阶段任务完整链路规范
- 五阶段模型：任务入口 → 计划冻结 → Agent执行 → 验证评审 → 回写收口
- 每阶段定义：目的/入口条件/输入来源/处理流程/产出物(YAML Schema)/判断条件/失败处理(E101~E502)
- 管道状态管理：阶段级状态追踪、阶段间数据传递、标准/回退/跳过/中断四种流控制
- 任务复杂度 → 管道选择映射（L1 简化3阶段 / L2 标准5阶段 / L3 完整5阶段+super-flow）
- 完整组件映射表：按阶段列出信息落点/Action/Flow/Schema 的关联关系

**可执行脚本层（全新模块）**
- 创建 `scripts/harness/README.md`：Harness 可执行脚本规范文档
- 定义命名规范（check-/validate-/sync-/report-）、输出格式、退出码约定
- 提供 CI 集成示例（GitHub Actions / GitLab CI）和跨平台转换指南
- 建立与 Task Pipeline 阶段的映射关系

### 改进功能

**计划模板重构（实现路径格式）**
- 完全重写 `5-templates/template-plan.md`：从 PM 管理计划 → Engineer 实现路径
- 核心新增：真实入口(Entry Points) / 组件职责矩阵 / 关键时序 / 失败策略 / 验证命令 / 回写目标
- 保留并强化：范围冻结（Scope/Non-Goals/Validation/Rollback）
- 新增：决策日志(Decision Log) / 管道状态映射 / 组件类型说明
- 精简删除：资源估算/里程碑/开发阶段/沟通计划/质量保证等 PM 冗余章节
- 更新 core-doc-generation.md 计划数据模型对齐新格式

**脚本示例**
- `check-structure.ps1`：验证 12 个 Landing Zone 的目录结构完整性
- `check-plan.ps1`：验证计划文件包含实现路径格式的必需章节
- `validate-entry-points.ps1`：验证计划中定义的文件入口是否可达、命令是否可用

### 文档更新
- SKILL.md：新增 core-task-pipeline.md 引用；版本升级为 3.2.1
- changelog.md：本次变更记录

---

## v3.2.0 (2026-05-14)

### 新增功能

**Action 接口规范（全新模块）**
- 创建 `3-core/core-actions.md`：定义13个标准化 Action 接口
- 每个 Action 有完整的 I/O 定义、约束条件和错误处理
- Action 注册表格式：triggers / interface / constraints / post_actions
- 渐进迁移路线：从 prompt 模拟 → 脚本校验 → 完全可执行
- 新增 Action 编排协议和组合 Action 能力

**状态锁机制（全新模块）**
- 创建 `4-schemas/schema-state-lock.md`：锁文件数据结构定义
- 锁操作协议：Acquire / Release / Write Validation / Force Acquire
- 锁状态机：unlocked → locked → stale 三态转换
- 脏锁自动清理和超时机制
- 并发写入冲突检测（乐观锁版本号）
- JSON Schema 格式，可被工具链消费

**上下文追踪增强（完全重写）**
- 三层上下文模型：全局 / 项目 / 会话
- 精准 TTL 管理：30分钟有效期 + 自动续期 + 降级策略
- 跨会话恢复协议：检测 → 重建 → 验证 → 确认 四阶段
- 上下文收敛机制：分类 → 压缩 → 聚合 → 归档
- 决策日志规范化：每条决策可追溯、可覆盖
- Token 预算分配和上下文大小估算

**完整项目超级流程（完全重写）**
- 升级为**超级流程编排器**，串联6个子流程
- 五阶段模型：需求 → 设计 → 开发 → 测试 → 文档
- 阶段门控（Phase Gate）：交付物 + 质量门禁双关卡
- 分支路由协议：enter/exit/interrupt 三模式与子流程对接
- 非线性路径：回退（Rollback）/ 跳过（Skip）/ 并行（Parallel）
- 进度加权计算（五阶段权重 20:20:30:20:10）
- 里程碑管理（M1~M5）

**状态管理增强**
- 增加锁机制集成：lock_version / lock_status / last_lock_session
- 增加超级流程状态：phases / milestones / overall_progress
- 增加上下文扩展：expiry / decision_log / convergence
- 新增 E703/E704 错误码

### 文档更新
- SKILL.md：新增 Action 接口、状态锁、错误码引用；版本升级为 3.2.0；计划模板标注实现路径格式
- quick-reference.md：新增锁管理、上下文管理命令
- changelog.md：本次变更记录

### 兼容性
- 完全兼容 v3.1.0 版本的状态文件格式
- 新增锁文件为可选，不影响未启用锁的项目
- 所有新功能向后兼容

---

## v3.1.0 (2026-05-14)

### 新增功能

**Harness Engineering 支持**
- 引入 Harness Engineering 体系：信息落点、计划协议、5层验证、结果回写
- 新增 `/reqplan init` 命令，自动创建标准 Harness 目录结构

**信息落点体系**
- 定义 11 个标准信息落点（AGENTS.md、.agent/、docs/harness/、docs/test/、scripts/harness/ 等）
- 每类信息有固定的落点位置，Agent 和工程师都能找到
- 落点验证规则（error/warning/info 三级）

**范围冻结（Scope Freeze）**
- 计划模板新增范围冻结四要素：Scope / Non-Goals / Validation / Rollback
- 新增实现链路说明、前端实现说明
- 所有产出物指定信息落点

**5层验证金字塔**
- 静态验证 → 单元验证 → 集成验证 → 失败验证 → 回写验证
- 每个流程定义各阶段的验证层次要求
- 验证命令、预期结果、失败处理策略完整定义
- 验证摘要 YAML 格式，便于后续复用

**结果回写机制**
- 定义验证摘要、PR/MR 描述、评审报告三类回写模板
- 明确每个步骤的 writeback_target
- 4 条回写验证规则

**适用边界定义**
- 7 个流程文件均新增「适用边界」章节
- 区分完整流程 / 轻量化操作 / 人工判断三种模式
- 按场景选择最优执行路径

**AGENTS.md 入口模板**
- 项目信息、技术栈、验证命令、目录结构标准格式
- 5 条生成规则、4 个常见误用模式、5 个更新触发条件
- React 前端 + Go 后端示例

**控制面文档模板**
- 8 节标准结构：任务入口 → 范围冻结 → 任务拆分 → 实现 → 验证 → 评审 → 回写 → 交接
- 4 条生成规则、4 个常见误用模式

**新增文档**
- `4-schemas/schema-landing-zone.md`：信息落点规范
- `4-schemas/schema-writeback.md`：结果回写规范
- `5-templates/template-agents.md`：AGENTS.md 入口模板
- `5-templates/template-control-plane.md`：控制面文档模板
- `6-docs/adoption-guide.md`：渐进落地指南

**改进功能**

- SKILL.md：新增 Harness Engineering 说明、`/reqplan init` 命令、错误码 E901/E902
- core-file-io.md：新增 Harness 初始化支持
- core-verification.md：完全重写为 5 层验证体系
- template-plan.md：新增范围冻结、实现链路、前端实现说明
- quick-reference.md：新增 `/reqplan init` 命令

### 兼容性

- 完全兼容 v3.0.0 版本
- 新增 Harness 目录结构为可选，不破坏现有项目
- 所有新功能按阶段渐进采用

---

## v3.0.0 (2026-05-15)

### 新增功能

**项目全生命周期智能助手**
- 重新定位为项目全生命周期管理平台
- 支持7个核心流程的完整覆盖
- 智能流程切换和分支引导

**7个核心流程**
1. **完整项目流程**：从零开始到上线的完整项目生命周期
2. **需求迭代流程**：现有项目的功能迭代和优化
3. **设计评审流程**：架构设计和接口评审
4. **代码审计流程**：代码质量审查和重构建议
5. **测试优化流程**：测试策略和用例优化
6. **文档完善流程**：技术文档和用户文档生成
7. **架构重构流程**：系统架构优化和技术债务清理

**智能引导系统2.0**
- 上下文感知的智能引导
- 基于当前流程的个性化建议
- 跨流程的状态保持
- 智能推荐下一步操作

**新增核心模块**
- `core-context-tracker.md`：上下文追踪、状态追溯、全局任务机制
- `core-workflow-engine.md`：7个流程定义、流程切换、分支引导
- `core-file-sync.md`：变更检测、影响分析、文件同步策略

**新增数据结构**
- `schema-context.md`：上下文追踪数据结构
- 扩展 `schema-state.md`：支持流程历史和进度追踪

**7-flows流程目录**
- 7个流程的详细定义文档
- 每个流程的步骤说明和引导信息

### 改进功能

**SKILL.md 完全重构**
- v3定位说明
- 7个核心流程介绍
- 智能引导系统2.0说明
- 文件行数控制在500行以内

**v2核心模块保留**
- 保持所有v2核心模块功能
- 仅在v3中兼容使用
- 渐进式引用深度≤1层

**文档更新**
- 更新`changelog.md`：添加v3.0.0版本信息

- 更新`quick-reference.md`：添加v3命令和流程
- 更新`troubleshooting.md`：v3故障排查

### 兼容性

- 完全兼容v2.x版本
- 支持v2状态文件自动升级
- 渐进式功能迁移
- 保持现有功能正常使用

---

## v2.1.0 (2026-05-14)

### 新增功能

**双轨触发机制**
- 支持命令触发（`/reqplan <command>`）
- 扩展自然语言触发词列表
- 命令格式符合TRAE规范

**智能引导系统**
- 状态概览显示
- 下一步推荐
- 阶段引导模板
- 命令复制友好格式

**状态管理模块**
- 完整的状态文件结构
- 状态转换规则
- 进度计算方法
- 上下文保持机制（30分钟有效期）
- 快照机制

**文件操作模块**
- 标准路径规范
- 原子性写入策略
- 目录自动创建

**错误处理模块**
- 完整的错误码体系（E000-E799）
- 标准错误响应格式
- 错误恢复策略

**Schema定义**
- schema-task.md - 任务数据结构
- schema-state.md - 状态数据结构  
- schema-testcase.md - 测试用例数据结构

**辅助文档**
- quick-reference.md - 命令速查
- changelog.md - 变更日志
- troubleshooting.md - 故障排查

### 改进功能

**SKILL.md 更新**
- 添加双轨触发机制说明
- 添加智能引导系统
- 添加状态管理规范
- 添加错误处理规范

**核心模块更新**
- intent-analysis: 添加扩展触发词和引导信息
- doc-generation: 添加扩展触发词和引导信息
- task-management: 添加扩展触发词和引导信息
- review: 添加扩展触发词和引导信息
- verification: 添加扩展触发词和引导信息

### 修复问题

- 修复自然语言触发不稳定的问题
- 修复上下文丢失的问题
- 修复引导信息不清晰的问题

### 兼容性

- 兼容 v2.0.0 版本的状态文件
- 支持自动升级旧版状态文件

## v2.0.0 (2026-05-13)

### 新增功能

**核心能力模块**
- intent-analysis: 意图分析
- doc-generation: 文档生成
- task-management: 任务管理
- review: 审核建议
- verification: 验收评估

**文档模板**
- template-req.md: 需求文档模板
- template-design.md: 设计文档模板
- template-plan.md: 开发计划模板

**状态管理**
- 状态文件结构定义
- 任务状态管理
- 进度追踪

**失败策略**
- E001-E002: 意图分析失败
- E101-E102: 文档生成失败
- E201-E202: 任务管理失败

### 基础架构

- 符合TRAE官方规范
- 渐进式披露原则
- 职责单一设计
