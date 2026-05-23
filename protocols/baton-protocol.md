# ReqPlan-v3 接力棒协议

> **核心原则**：接力棒文件是跨 Session 的唯一真相来源。每次交互结束后，必须更新接力棒。

---

## 一、为什么需要接力棒

传统 Skill 的问题：
- ❌ 每个 Session 都是全新的
- ❌ 用户中断后无法续跑
- ❌ 进度丢失，需要重新开始
- ❌ 产物分散，难以追踪

接力棒机制的优势：
- ✅ 状态持久化到文件系统
- ✅ 任何时候都可以续跑
- ✅ 产物和进度一目了然
- ✅ 支持多人协作

---

## 二、接力棒文件规范

### 2.1 文件位置

```
{项目路径}/.agent/harness/_baton.md
```

### 2.2 命名规则

- 前缀 `_baton.md` 表示内部状态文件
- 位置固定在 `.agent/harness/` 目录下

---

## 三、接力棒文件模板

### 3.1 START 阶段最小化模板（首次创建用）

START 阶段只需创建以下简化版本（~30 行），随着阶段推进逐步扩展为完整模板：

```markdown
# 🔄 ReqPlan-v3 接力棒

## 元信息

| 字段 | 值 |
|------|-----|
| 项目 | {项目名称} |
| 开始时间 | {ISO 8601} |
| 最后更新 | {ISO 8601} |
| 当前状态 | START |
| 模式 | NORMAL |

## 进度追踪

### 阶段完成情况

- [ ] START - 启动
- [ ] ANALYZE - 分析
- [ ] CONFIRM - 确认
- [ ] DESIGN - 设计
- [ ] IMPLEMENT - 实现
- [ ] VERIFY - 验证
- [ ] JUDGE - 判断
```

进入 ANALYZE 阶段时，扩展为下方的完整模板（增加质量审核追踪、产物清单、任务追踪等）。

### 3.2 完整模板（ANALYZE 起使用）

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

## 质量审核追踪

| 审核阶段 | 状态 | 分数 | 重试次数 | 报告文件 |
|---------|------|------|---------|---------|
| quality_audit_analysis | 未审核/已通过/已打回 | - | 0/2 | - |
| quality_audit_design | 未审核/已通过/已打回 | - | 0/2 | - |
| quality_audit_implement | 未审核/已通过/已打回 | - | 0/2 | - |
| quality_audit_verify | 未审核/已通过/已打回 | - | 0/2 | - |
| quality_audit_judge | 未审核/已通过/已打回 | - | - | - |

## 进度追踪

### 阶段完成情况

- [ ] START - 启动
- [ ] ANALYZE - 分析
- [ ] CONFIRM - 确认
- [ ] DESIGN - 设计
- [ ] IMPLEMENT - 实现
- [ ] VERIFY - 验证
- [ ] JUDGE - 判断

### 产物清单

- [ ] `.agent/harness/_analysis.md` - 分析报告
- [ ] `.agent/harness/_design.md` - 设计文档
- [ ] `.agent/harness/_implementation.md` - 实现摘要
- [ ] `.agent/harness/_verification.md` - 验证报告
- [ ] `.agent/harness/_quality_audit_analysis.md` - 分析审核报告
- [ ] `.agent/harness/_quality_audit_design.md` - 设计审核报告
- [ ] `.agent/harness/_quality_audit_implement.md` - 实现审核报告
- [ ] `.agent/harness/_quality_audit_verify.md` - 验证审核报告
- [ ] `.agent/harness/_quality_audit_judge.md` - 最终判定报告

### ⭐ 任务追踪（统一管理）

> **重要**：所有任务状态统一在 baton.md 中管理，不再使用独立的 tasks.md 文件。

| # | 任务名称 | 状态 | 完成时间 | 备注 |
|---|---------|------|---------|------|
| 1 | {任务1} | ✅ 完成 | {时间} | {备注} |
| 2 | {任务2} | 🔄 进行中 | - | {备注} |
| 3 | {任务3} | ⏳ 待开始 | - | {备注} |

**任务状态说明**：
- ✅ 完成：任务已完成
- 🔄 进行中：任务正在执行
- ⏳ 待开始：任务还未开始
- ❌ 失败：任务执行失败

## 当前阶段详情

### {状态名称}

**进度**: {百分比}%
**已完成任务**: {列表}
**进行中任务**: {任务}
**待完成任务**: {列表}

## 问题记录

### ⚠️ 阻塞问题
{问题列表}

### 💡 待确认事项
{待确认事项}

## 下一步行动

### 立即执行（Next）
1. {任务1}
2. {任务2}
3. {任务3}

---

*最后更新: {ISO 8601}*
```

---

## 四、接力棒生命周期

### 4.1 更新时机

⚠️ **必须更新的时机**：

| # | 时机 | 必须执行 | 优先级 |
|---|------|----------|--------|
| 1 | 阶段开始时 | 更新状态为"进行中" | 高 |
| 2 | 阶段完成时 | 标记阶段为完成 | 高 |
| 3 | 用户交互后 | 记录用户反馈 | 高 |
| 4 | 产物生成后 | 更新产物清单 | 高 |
| 5 | 遇到问题时 | 记录到问题记录 | 高 |

> **注意**：不需要在每次工具调用后更新，只需在上述关键时机更新。阶段内多次工具调用可在阶段完成时统一更新。

---

## 五、接力棒读写流程

### 5.1 完整交互流程

```
用户输入 → 读取接力棒 → 识别状态 → 执行阶段 → 更新接力棒 → 响应用户
                                              ↑
                                    ┌─────────────────┐
                                    | ⚠️ 必须执行！    |
                                    | 即使任务失败    |
                                    | 也要记录进度    |
                                    └─────────────────┘
```

---

## 六、续跑流程

### 6.1 续跑检查

```bash
# 1. 读取接力棒
read {项目路径}/.agent/harness/_baton.md

# 2. 识别当前状态
当前状态: {状态}

# 3. 续跑检查清单
- [ ] 接力棒文件存在
- [ ] 所有已完成产物存在
- [ ] 用户意图明确
- [ ] 有明确的下一步
```

---

## 七、状态流转

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

### 7.1 续跑映射

| 当前状态 | 读取文件 | 继续执行 |
|---------|---------|---------|
| ANALYZE | _analysis.md | 继续分析 |
| CONFIRM | _analysis.md | 等待确认 |
| DESIGN | _design.md | 继续设计 |
| IMPLEMENT | _design.md | 继续实现 |
| VERIFY | _verification.md | 继续验证 |
| JUDGE | _verification.md | 判断 |

---

## 八、快速参考

### 接力棒命令速查

```bash
# 读取接力棒
read {项目路径}/.agent/harness/_baton.md

# 更新接力棒
write {项目路径}/.agent/harness/_baton.md

# 检查产物
ls -la {项目路径}/.agent/harness/
```
