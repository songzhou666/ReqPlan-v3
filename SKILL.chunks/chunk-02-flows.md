# 三大流程定义

三大场景共享同一个工作管道：**理解 → 设计 → 实施 → 验证**，区别在于起点不同。

```
开发：起点是"需求" → 走完整管道
分析：起点是"目标" → 侧重理解与设计阶段
修复：起点是"问题" → 侧重诊断与验证阶段
```

> 本 chunk 定义的 3 场景 Step 流程与主 SKILL.md 的 7 阶段状态机（START→ANALYZE→...→JUDGE）**互补而非替代**：
> - **运行时状态追踪**统一使用 `.agent/harness/_baton.md`（参见 protocols/baton-protocol.md）
> - **运行时产物**统一放在 `.agent/harness/`（_analysis.md / _design.md / _implementation.md / _verification.md）
> - **长期归档**使用 `docs/harness/`（history.yaml / reviews / fixes，参见 chunk-04-chain.md）

---

## 项目初始化（/reqplan init）

仅首次使用或项目缺少入口文件时需要。

### 执行内容
1. 检查 `.agent/harness/` 目录是否存在
   - 无 → 创建 `.agent/harness/` 目录
2. 检查 `.agent/harness/_baton.md` 是否存在
   - 无 → 创建接力棒，状态设为 START（模板见 protocols/baton-protocol.md）
3. 检查 `docs/harness/` 目录是否存在
   - 无 → 创建 `docs/harness/` 目录
4. 检查 `docs/harness/history.yaml` 是否存在
   - 无 → 创建空记录 `history: []`
5. 输出给用户：已初始化了哪些文件和目录

### 完成条件
`.agent/harness/_baton.md`、`docs/harness/history.yaml` 已就位。
然后询问用户下一步任务。

---

## 执行准则

AI收到任务后，首先要判断属于哪个场景，然后按对应流程执行。每个Step完成后，必须先满足**完成条件**才能进入下一个Step。
执行过程中同步更新 `.agent/harness/_baton.md` 中的状态和进度。

### 路径不存在时的处理

| 情况 | 处理方式 |
|------|---------|
| `.agent/harness/` 目录不存在 | 创建 `.agent/harness/`，初始化 `_baton.md` |
| `docs/harness/` 目录不存在 | 创建 `docs/harness/`，初始化空 `history.yaml` |
| `_baton.md` 不存在 | 按 protocols/baton-protocol.md 模板创建，状态设为 START |
| 以上均不存在 | 提示用户是否执行 `/reqplan init` 一次性初始化 |
| 项目本身目录不存在 | 提示用户先创建项目目录或指定现有路径 |

**原则**：不要因为文件不存在就跳过功能。文件不存在就创建它，目录不存在就创建目录。
只有整个项目目录都不存在时才提示用户。

### 会话恢复

如果用户是在**中断后续期**再次触发：
1. 读取 `.agent/harness/_baton.md` 获取当前状态和进度
2. 读取 `docs/harness/history.yaml` 了解已完成的任务
3. 向用户展示当前进度摘要："上次做到XX，已完成Y/Z个任务"
4. 询问用户：**"需要继续上次的任务，还是开始新的任务？"**
5. 用户选择继续 → 从当前状态续跑（按 SKILL.md 状态路由表）
6. 用户选择新任务 → 启动对应流程的 Step 1，现有计划保留为历史记录

### 任务状态流转
```
⏳ TODO → 🔄 WIP → ✅ DONE
⏳ TODO → ❌ CANCELLED（用户取消或需求变更为不做了）
🔄 WIP → ⛔ BLOCKED（遇到依赖阻塞无法继续）
⛔ BLOCKED → 🔄 WIP（阻塞解除后恢复）
✅ DONE → 不可逆（如需重做，在下一轮迭代中重新开任务）
```

## 流程1：开发（新功能 / 迭代 / 重构）

对应 SKILL.md 7 阶段主流程。

### Step 1 理解需求
引导用户澄清功能点、角色、数据和约束。
**对应状态机阶段**：ANALYZE
**产出**：`.agent/harness/_analysis.md`（按 artifacts/template-artifacts.md 模板）
**完成条件**：需求摘要已与用户确认
**门控**：→ 用户确认后进入 Step 2

### Step 2 设计方案
根据需求确定技术方案：架构、模块划分、接口设计、数据模型。
**对应状态机阶段**：DESIGN
**产出**：`.agent/harness/_design.md`（按 artifacts/template-artifacts.md 模板）
**完成条件**：技术方案已与用户确认
**门控**：→ 方案确认后进入 Step 3

### Step 3 制定计划
将方案拆解为可执行的任务列表，每项任务标注涉及文件和验证方式。
**对应状态机阶段**：DESIGN（任务拆解部分）
**产出**：任务列表写入 `_design.md` 的任务列表章节
**完成条件**：任务列表初始状态全部为 ⏳ TODO
**门控**：→ 计划就绪后进入 Step 4

### Step 4 执行实施
按计划逐个任务实施，每完成一个更新 `_baton.md` 中的任务追踪状态。
**对应状态机阶段**：IMPLEMENT
**状态更新规则**：
- 开始实施某任务 → ⏳ TODO 改为 🔄 WIP
- 完成实施 + 验证 → 🔄 WIP 改为 ✅ DONE
- 遇到阻塞 → 🔄 WIP 改为 ⛔ BLOCKED，记录阻塞原因
- 用户取消 → ⏳ TODO 改为 ❌ CANCELLED
- 进度行自动更新：{doneCount}/{totalCount} ({progressPercent}%)
**产出**：`.agent/harness/_implementation.md`
**完成条件**：所有任务均为 ✅ DONE 或 ❌ CANCELLED
**门控**：→ 计划任务全部完成后进入 Step 5

### Step 5 分层验证
执行五层验证（详见 chunk-03-harness.md）：
Layer 1 静态检查 → Layer 2 单元验证 → Layer 3 链路验证 → Layer 4 失败验证 → Layer 5 回写验证
**对应状态机阶段**：VERIFY
**产出**：`.agent/harness/_verification.md`
**完成条件**：五层全部通过，或已记录已知例外
**门控**：→ 验证通过后进入 Step 6

### Step 6 链路回写
**对应状态机阶段**：JUDGE → DONE
- 更新 `.agent/harness/_baton.md` 状态为 DONE
- 追加记录到 `docs/harness/history.yaml`（长期归档，不要覆盖已有记录）
- 如果有关键选型，追加到 `docs/harness/decisions.yaml`
- 输出给用户的完成总结：本次完成了什么、涉及哪些文件、验证结果
**完成条件**：history.yaml 已更新
**门控**：→ 流程结束

---

## 流程2：分析（代码审查 / 设计评审 / 质量评估）

对应 SKILL.md 7 阶段中的 ANALYZE→CONFIRM→DESIGN（轻量版，跳过 IMPLEMENT）。

### Step 1 明确目标
确定分析对象和关注维度（质量/安全/性能/设计一致性）。
**完成条件**：分析目标已与用户确认
**门控**：→ 目标确认后进入 Step 2

### Step 2 划定范围
明确分析覆盖的文件范围。
**完成条件**：范围已确定
**门控**：→ 范围确定后进入 Step 3

### Step 3 逐项分析
按维度逐项检查。代码质量关注命名、结构、复杂度。
安全关注输入验证、权限、敏感信息。
设计关注一致性、扩展性、边界清晰度。
**产出**：逐项分析记录
**完成条件**：所有维度的分析已完成
**门控**：→ 分析完成后进入 Step 4

### Step 4 输出报告
结构化的分析报告。按以下结构输出：

```markdown
# 分析报告

## 基本信息
- 分析对象：{模块/文件}
- 关注维度：{质量/安全/性能/设计}
- 分析时间：{date}

## 发现的问题
| # | 问题 | 严重程度 | 位置 | 建议 |
|---|------|---------|------|------|
| 1 | {问题描述} | Critical/Major/Minor/Info | {文件:行号} | {修复建议} |

## 改进建议
- {建议1}
- {建议2}

## 风险等级
{低/中/高} - {说明}
```

**产出**：报告保存到 `docs/harness/reviews/{date}-{scope}.md`（确保目录存在）
**完成条件**：报告已与用户确认
**门控**：→ 报告确认后进入 Step 5

### Step 5 链路回写
追加记录到 `docs/harness/history.yaml`。
**完成条件**：history.yaml 已更新
**门控**：→ 流程结束

---

## 流程3：修复（Bug修复 / 问题排查）

对应 SKILL.md 7 阶段中的 ANALYZE→DESIGN（简化）→IMPLEMENT→VERIFY→JUDGE。

### Step 1 收集信息
现象、复现步骤、环境、最近变更、影响范围。
**完成条件**：信息足够支持诊断
**门控**：→ 信息充足后进入 Step 2

### Step 2 诊断根因
定位问题点，追溯代码链路，确认根因。
保留诊断记录：现象 → 排查路径 → 根因结论。
**完成条件**：根因已确认
**门控**：→ 根因确认后进入 Step 3

### Step 3 制定方案
修复方案 + 影响范围 + 回滚策略。
- 简单修复（涉及文件 ≤ 3 个，无架构性修改）：直接进入 Step 4
- 复杂修复：同步更新 `.agent/harness/_baton.md` 中的任务追踪，进入 Step 4
**完成条件**：方案已与用户确认
**门控**：→ 方案确认后进入 Step 4

### Step 4 实施修复
编码实现 + 测试验证。
复杂修复时按 baton.md 任务列表逐步执行，更新状态。
**完成条件**：修复编码完成 + 自测通过
**门控**：→ 修复完成进入 Step 5

### Step 5 验证修复
确认 Bug 不再复现 + 回归测试 + 验证影响范围。
**完成条件**：Bug确认修复 + 无回归问题
**门控**：→ 验证通过进入 Step 6

### Step 6 链路回写
- 更新 `.agent/harness/_baton.md` 状态为 DONE
- 追加记录到 `docs/harness/history.yaml`
- 诊断记录保存到 `docs/harness/fixes/{date}-{issue}.md`（确保目录存在）
**完成条件**：链路已更新
**门控**：→ 流程结束

---

## 前端三层检查（适用于开发和分析场景）

来源：Harness Engineering 前端三段式路径

| 层次 | 检查内容 | 完成后标记 |
|------|---------|-----------|
| 执行依据层 | 页面结构、组件层级、信息顺序是否冻结 | Pencil/设计说明已确认 |
| 状态暴露层 | 各状态方案是否完整 | Storybook/组件可见 |
| 交付实现层 | 路由、API、权限、联调是否完成 | 页面可访问 |

## 后端三层检查

| 层次 | 检查内容 | 完成后标记 |
|------|---------|-----------|
| 执行依据层 | 运行模式、输入输出、异常口径、非目标 | docs/plan 已说清 |
| 验证定层 | 验证脚本、mock方案、可复现命令 | 验证命令可执行 |
| 交付实现层 | 实现、测试、联调 | 代码进入业务路径 |