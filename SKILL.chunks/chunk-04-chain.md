# 信息落点与文件链路

每次开发/分析/修复任务完成时，在项目中留下可追溯的记录。
这些记录不是状态管理——不控制并发、不加锁、不追踪会话。
它们的作用是：**让后续任务能理解变更历史、评估影响范围、复用验证方案**。

来源：Harness Engineering 信息落点体系

---

## 链路记录三件套

### 1. 全局历史 docs/harness/history.yaml

每个任务完成后**追加**一条记录（不要覆盖已有内容）。格式：

```yaml
history:
  - date: "2026-05-15"
    type: "开发"
    task: "订单模块"
    plan: ".agent/plans/2026-05-15-user-order.md"
    progress: "4/4 (100%)"
    files:
      - "src/models/Order.ts"
      - "src/api/order.ts"
      - "src/pages/OrderList.vue"
    result: "验证通过"

  - date: "2026-05-15"
    type: "修复"
    task: "订单金额精度Bug"
    issue: "金额计算浮点数精度丢失"
    fix: "使用 Decimal 类型替代 float"
    status: "closed"
```

AI 读取方式：`/reqplan status` 或下次会话开始时读取此文件。

### 2. 开发计划 .agent/plans/{date}-{module}.md

当前活跃任务的详细计划，包含任务列表和进度。
AI 每次执行完任务更新此文件的状态列。

### 3. 决策日志 docs/harness/decisions.yaml

记录关键选型决策，让后续任务理解当时的选择背景：

```yaml
decisions:
  - date: "2026-05-15"
    context: "订单模块技术选型"
    options:
      - "RESTful API"
      - "GraphQL"
    choice: "RESTful API"
    reason: "团队熟悉度高，当前需求以CRUD为主，无需GraphQL灵活性"
```

---

### 4. 项目约束 docs/harness/project-constraints.md

登记项目级规则，让后续任务避免重复犯错。

```markdown
# 项目约束

## 编码规范
- 使用 TypeScript 严格模式，禁止 any 类型
- API 响应统一包裹 Response<T> 格式

## 已验证规则
| 规则 | 来源 | 状态 |
|------|------|------|
| 前端图片必须使用 webp 格式 | 2026-05-10 审查 | 已执行 |
| 所有 API 必须有速率限制 | 2026-04-20 安全审计 | lint 检查已添加 |
```

当同类错误在 review 中出现第二次时，主动提示用户是否需要登记到此文件。

### 5. 入口地图 AGENTS.md

项目根目录下的入口地图，让 AI 进入项目时能快速了解项目和验证命令。

```markdown
# {项目名称}

## 技术栈
- 前端: React 18 + TypeScript
- 后端: Go 1.22
- 数据库: PostgreSQL 15

## 验证命令
- lint: npm run lint
- typecheck: npm run typecheck
- test: npm run test
- build: npm run build
```

AI 每次进入项目时先读此文件获取入口信息。

---

## 信息落点总览

| 类别 | 位置 | 用途 |
|------|------|------|
| 入口地图 | AGENTS.md（项目根目录） | AI 进入项目时读取的入口信息 |
| 任务入口 | 对话 + /reqplan 命令 | 触发和执行入口 |
| 开发计划 | .agent/plans/ | 任务列表与进度跟踪 |
| 全局历史 | docs/harness/history.yaml | 跨任务全局视图 |
| 决策日志 | docs/harness/decisions.yaml | 选型决策记录 |
| 项目约束 | docs/harness/project-constraints.md | 项目级规则登记 |
| 分析报告 | docs/harness/reviews/ | 代码审查/设计评审报告 |
| 修复报告 | docs/harness/fixes/ | Bug诊断与修复记录 |
| 验证入口 | package.json 中的 test/lint/typecheck | 质量验证命令 |

---

## 回写时机

每个 Task 或 Step 完成时，做一次回写：

```
开发任务完成 → 更新 plan 状态 → 追加到 history.yaml
决策发生     → 追加到 decisions.yaml
同类问题第二次出现 → 提示用户是否登记到 project-constraints.md
任务收口前   → 执行 Layer 5 回写验证确认所有链路已记录
```
