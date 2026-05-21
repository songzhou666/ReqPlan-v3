# ReqPlan v3.3 渐进落地指南

## 设计理念

ReqPlan v3.3 引入的 Harness Engineering 能力不需要一步到位，你可以根据项目的实际需要分阶段采纳。

本指南将落地过程分为三个递进阶段，每个阶段都提供**明确的目标**、**最少必要操作**和**验证方式**，让你可以按需推进。

---

## Phase 1：让 Agent 找得到入口（入门级）

### 目标

在你的项目中建立最基础的 Agent 发现能力，任何 Agent 进入项目后都能知道：

- 这个项目是什么、用什么技术栈
- 如何运行、测试、构建
- 核心目录结构在哪里

### 最少必要操作

#### 步骤 1：初始化 Harness 目录结构

```bash
/reqplan init
```

该命令会在项目根目录自动创建：

```
AGENTS.md          # Agent 入口地图
.agent/
  PLANS.md         # 计划协议（初始模板）
docs/
  harness/         # 控制面文档目录
  test/            # 测试验证目录
scripts/
  harness/         # 检查脚本目录
```

#### 步骤 2：填写 AGENTS.md

初始化后，打开 `AGENTS.md`，填入项目基本信息：

```markdown
# 项目名称

## 项目简介
一句话说明这个项目做什么。

## 技术栈
- 前端：React 18 + TypeScript
- 后端：Go 1.22 + PostgreSQL
- 构建：Vite / Make

## 验证命令
- 代码检查：`npm run lint` / `golangci-lint run`
- 类型检查：`npm run typecheck`
- 测试：`npm test` / `go test ./...`
- 构建：`npm run build` / `make build`

## 目录结构
src/          # 前端源码
internal/     # 后端核心逻辑
docs/         # 项目文档
```

详见：[AGENTS.md 模板](../5-templates/template-agents.md)

#### 步骤 3（可选）：补充控制面信息

编辑 `docs/harness/control-plane.md`，说明本项目如何管理任务：

- 任务从哪来（Issue / 需求池 / 直接沟通）
- 如何确定做不做（Scope 冻结流程）
- 验证通过的标准是什么

详见：[控制面文档模板](../5-templates/template-control-plane.md)

#### 步骤 4（可选）：登记项目约束

编辑 `docs/harness/project-constraints.md`，记录已知的项目规则和约束：

- 不允许的行为（如禁止直接操作生产库）
- 必须遵守的规范（如 commit message 格式）
- 已知的技术限制

### 验证方式

完成 Phase 1 后，重新进入项目并执行：

```
/reqplan status
```

如果 AGENTS.md 存在且内容完整，Agent 会自动识别项目信息并展示。

### 什么时候可以进入 Phase 2

- [x] 项目根目录已有 AGENTS.md
- [x] .agent/ 目录已创建并包含 PLANS.md
- [x] 团队成员知道 AGENTS.md 的存在和作用
- [x] 处理简单任务时不再出现"Agent 看不懂项目"的情况

---

## Phase 2：让任务可复用（标准级）

### 目标

让项目中的**复杂任务**有明确的计划协议和验证标准，避免以下问题：

- Agent 拿到需求后自由发挥、偏离目标
- 做完发现做多了或做少了
- 验收标准模糊，反复返工

### 最少必要操作

#### 步骤 1：使用范围冻结（Scope Freeze）

在启动复杂任务之前，显式定义：

**Scope（本轮目标）**：用一句话说明这次任务做什么。

```
本轮目标：实现用户订单列表页面，包含分页、搜索、状态筛选
```

**Non-Goals（明确不做的）**：防止范围膨胀。

```
明确不做的：
- 不做订单详情页面
- 不做退款功能
- 不做移动端适配
```

**Validation（验收口径）**：预先写好的验收条件。

```
验收标准：
- [ ] 列表页支持分页（每页20条）
- [ ] 搜索支持模糊匹配订单号
- [ ] 筛选支持按状态（待支付/已支付/已取消）
- [ ] 页面加载时间 < 500ms
```

**Rollback（回滚策略）**：失败时的后手。

```
回滚策略：
- 触发条件：验收标准超过3项不通过
- 回滚操作：git revert 本次变更
- 恢复验证：回滚后再次通过全量测试
```

详见：[计划协议模板](../5-templates/template-plan.md#范围冻结scope-freeze)

#### 步骤 2：采用分层验证

不要等到任务结束才验证，在每个阶段都做对应层次的检查：

| 阶段 | 验证层次 | 检查什么 | 命令示例 |
|------|---------|---------|---------|
| 编码中 | 静态验证 | 代码/类型/格式 | `npm run lint && npm run typecheck` |
| 函数完成 | 单元验证 | 核心函数逻辑 | `go test ./internal/... -run TestOrder` |
| 链路完成 | 集成验证 | 入口→处理→输出 | `npm run test:e2e` |
| 异常场景 | 失败验证 | 超时/异常/回滚 | 手动模拟错误场景 |
| 收口时 | 回写验证 | 文档/落点同步 | 逐项检查产出物落点 |

详见：[5层验证规范](../3-core/core-verification.md)

#### 步骤 3：使用控制面文档

在 `docs/harness/control-plane.md` 中记录：

1. **任务入口**：本项目的任务来源和收集方式
2. **范围冻结流程**：如何确定做不做、做多少
3. **任务拆分方式**：复杂任务如何分解
4. **验证标准**：各层次验证的执行方式
5. **评审要求**：什么情况下需要评审
6. **结果回写**：产出物应该放到哪里

详见：[控制面文档模板](../5-templates/template-control-plane.md)

#### 步骤 4：选择合适流程

根据任务类型选择预定义流程，每个流程都内置了适用边界判断：

| 流程 | 命令 | 适用场景 |
|------|------|---------|
| 完整项目 | `/reqplan flow full` | 新项目、完整功能、多模块 |
| 需求迭代 | `/reqplan flow iteration` | 增量开发、bug修复 |
| 设计评审 | `/reqplan flow design-review` | 架构/接口/数据库设计 |
| 代码审计 | `/reqplan flow audit` | 代码质量/安全/性能检查 |
| 测试优化 | `/reqplan flow testing` | 测试策略/用例/自动化 |
| 文档完善 | `/reqplan flow docs` | 项目文档/API文档/架构说明 |
| 架构重构 | `/reqplan flow refactor` | 模块重构/性能优化/技术债 |

### 验证方式

完成 Phase 2 后，处理一个中等复杂度的任务时：

```
/reqplan plan     # 制定带范围冻结的计划
/reqplan verify   # 执行分层验证，产出验证摘要
```

检查验证摘要是否包含完整的验证层次记录。

### 什么时候可以进入 Phase 3

- [x] 复杂任务都有明确的范围冻结
- [x] 团队成员习惯在启动任务前写 Non-Goals
- [x] 验证不再只是"跑一遍测试"，而是分层检查
- [x] 产出物都能找到固定的落点位置

---

## Phase 3：让规则机械化（进阶级）

### 目标

将人工提醒的规则逐步转化为**可执行检查**，让机器自动兜底。

### 最少必要操作

#### 步骤 1：编写结构检查脚本

在 `scripts/harness/` 下创建可执行检查脚本：

**check-structure.ps1**（检查目录结构完整性）：

```bash
#!/bin/bash
# 检查 Harness 目录结构是否完整
errors=0
[ ! -f "AGENTS.md" ] && echo "MISSING: AGENTS.md" && errors=$((errors+1))
[ ! -f ".agent/PLANS.md" ] && echo "MISSING: .agent/PLANS.md" && errors=$((errors+1))
exit $errors
```

**check-plan.ps1**（检查计划文件是否有范围冻结）：

```bash
#!/bin/bash
# 检查计划文件是否包含 Scope Freeze 四要素
plan_file=".agent/plans/$(ls -t .agent/plans/ 2>/dev/null | head -1)"
[ -z "$plan_file" ] && echo "INFO: 暂无计划文件" && exit 0

missing=0
grep -q "本轮目标" "$plan_file" || { echo "MISSING: 本轮目标"; missing=$((missing+1)); }
grep -q "明确不做的" "$plan_file" || { echo "MISSING: 明确不做的"; missing=$((missing+1)); }
grep -q "验收口径" "$plan_file" || { echo "MISSING: 验收口径"; missing=$((missing+1)); }
grep -q "回滚策略" "$plan_file" || { echo "MISSING: 回滚策略"; missing=$((missing+1)); }

echo "检查完成：$missing 项缺失"
exit $missing
```

#### 步骤 2：建立结果回写机制

每次任务完成后，将核心信息回写到标准位置：

| 回写目标 | 内容 | 格式 |
|---------|------|------|
| docs/test/verify-summary.md | 验证结果摘要 | YAML 格式 |
| PR/MR 描述 | 变更说明 + 验证结果 | 结构化文本 |
| 任务系统 | 状态更新 + 阻塞问题 | 按平台格式 |

详见：[结果回写规范](../4-schemas/schema-writeback.md)

验证摘要示例：

```yaml
## 验证摘要

task_id: "TASK-0042"
task_title: "实现订单列表搜索功能"

layers:
  static_check:
    status: pass
    details: "lint 0 error, typecheck 0 error"

  unit_test:
    status: pass
    details: "12 tests passed, coverage 85%"

  integration:
    status: pass
    details: "3 E2E scenarios passed"

  failure_scenarios:
    status: pass
    details: "超时重试验证通过"

  writeback:
    status: completed
    details: "docs/ 更新完毕, PR 描述已补充"

overall: pass
```

#### 步骤 3：集成到 CI（可选但推荐）

将检查脚本接入 CI pipeline：

```yaml
# .github/workflows/harness-check.yml（GitHub Actions 示例）
name: Harness Structure Check
on: [pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check Harness Structure
        run: |
          chmod +x scripts/harness/*
          scripts/harness/check-structure.ps1
```

#### 步骤 4：建立 Agent review 口径

在 `.agent/prompts/` 下创建 review 标准：

```
# Review 标准口径

## 代码审查必查项
1. 是否遵循了范围冻结中定义的 Scope？
2. Non-Goals 中的条目是否真的没有做？
3. 是否有新增功能超出原定范围？
4. 验证结果是否完整记录？

## 如果发现问题
- 超范围：要求 revert 或补充范围冻结
- 验证缺失：要求补充验证并回写结果
- 落点缺失：要求将产出物放到正确位置
```

### 验证方式

```
scripts/harness/check-structure.ps1   # 结构完整性检查
scripts/harness/check-plan.ps1        # 计划规范性检查
```

两个脚本都返回 exit code 0 即视为通过。

### Phase 3 完成标志

- [x] scripts/harness/ 下有至少 2 个可执行检查脚本
- [x] 每次 PR 都包含验证摘要回写
- [x] CI 流程中包含结构或规范检查
- [x] Agent 能根据 review 口径自动审查代码
- [x] 团队成员不再需要人工提醒"别忘了写 Non-Goals"

---

## 三阶段总览

| 维度 | Phase 1（入门） | Phase 2（标准） | Phase 3（进阶） |
|------|----------------|----------------|----------------|
| 核心目标 | Agent 找得到入口 | 任务可计划可验证 | 规则自动兜底 |
| 关键文件 | AGENTS.md | PLANS.md + control-plane | scripts/ + prompts/ |
| 命令使用 | `/reqplan init` | `/reqplan plan` + `/reqplan verify` | 自定义脚本 |
| 人力投入 | 10 分钟 | 半天到一天 | 持续迭代 |
| 团队规模 | 1 人项目 | 2-5 人小团队 | 5 人以上团队 |
| 收益 | 减少"Agent 看不懂项目" | 减少"做多了/做少了/做偏了" | 减少"忘记检查/忘记回写" |

---

## 常见疑问

### Q：项目很小，也要用全部功能吗？

不用。建议至少完成 Phase 1（创建 AGENTS.md），Phase 2 和 Phase 3 按需采用。小团队做小项目，Phase 1 已经完全够用。

### Q：现有项目没有 AGENTS.md，能补吗？

可以。运行 `/reqplan init` 会自动创建目录结构，然后按 Phase 1 步骤 2 填写即可。不需要从头开始。

### Q：团队不习惯写 Non-Goals 怎么办？

从"明确不做的"开始，只需要写 1-2 条，不用追求全面。习惯后再逐步扩展。Phase 2 的步骤 1 提供了最简格式。

### Q：验证脚本和 CI 冲突怎么办？

Phase 3 的检查脚本是补充性的，不会替代现有的 CI 流程。建议先独立运行，验证结果后再逐步集成到 CI。

### Q：落地后发现不适合怎么办？

灵活性是第一原则。可以随时：
- 暂停某个阶段的实践
- 回到前一阶段
- 只保留适合的部分

落地是持续优化的过程，不是一次性的改造。

---

**文档版本**: 3.1.0  
**更新时间**: 2026-05-14  
**关联文档**: template-agents.md, template-control-plane.md, schema-landing-zone.md, schema-writeback.md, core-verification.md, template-plan.md
