# 信息落点与文件链路

每次开发/分析/修复任务完成时，在项目中留下可追溯的记录。
这些记录不是状态管理——不控制并发、不加锁、不追踪会话。
它们的作用是：**让后续任务能理解变更历史、评估影响范围、复用验证方案**。

来源：Harness Engineering 信息落点体系

---

## 两层路径模型

> **运行时状态**（.agent/harness/）与 **长期归档**（docs/harness/）互补：

| 路径 | 用途 | 生命周期 |
|------|------|----------|
| `.agent/harness/_baton.md` | 运行时状态追踪（唯一真相源） | 当前任务 |
| `.agent/harness/_analysis.md` 等 | 运行时产物 | 当前任务 |
| `docs/harness/history.yaml` | 全局历史归档 | 永久追加 |
| `docs/harness/decisions.yaml` | 关键决策日志 | 永久追加 |
| `docs/harness/reviews/` | 分析/审查报告 | 永久保存 |
| `docs/harness/fixes/` | Bug诊断/修复记录 | 永久保存 |

---

## 链路记录三件套

### 1. 运行时状态 .agent/harness/_baton.md

当前任务的完整状态（状态机阶段、进度追踪、产物清单、任务追踪）。详见 [protocols/baton-protocol.md](../protocols/baton-protocol.md)。

每次阶段转换时更新。任务完成后判断 PASS/FAIL，然后回写到长期归档中。

### 2. 全局历史 docs/harness/history.yaml

每个任务完成后**追加**一条记录（不要覆盖已有内容）。格式：

```yaml
history:
  - date: "2026-05-15"
    type: "开发"
    task: "订单模块"
    plan: ".agent/harness/_baton.md"
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

### 5. 入口地图 AGENTS.md（可选）

项目根目录下的入口地图，让 AI 进入项目时能快速了解项目和验证命令。
如果项目已有 AGENTS.md，读取其内容辅助分析。如果没有，按需创建。

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

> 注意：AGENTS.md 是可选的辅助入口。核心状态追踪始终使用 `.agent/harness/_baton.md`。

---

## 信息落点总览

| 类别 | 位置 | 用途 |
|------|------|------|
| 运行时状态 | `.agent/harness/_baton.md` | 当前任务状态与进度（唯一真相源） |
| 运行时产物 | `.agent/harness/_analysis.md` 等 | 当前任务的阶段性产物 |
| 任务入口 | 对话 + `/reqplan` 命令 | 触发和执行入口 |
| 全局历史 | `docs/harness/history.yaml` | 跨任务全局视图（长期归档） |
| 决策日志 | `docs/harness/decisions.yaml` | 选型决策记录 |
| 项目约束 | `docs/harness/project-constraints.md` | 项目级规则登记 |
| 分析报告 | `docs/harness/reviews/` | 代码审查/设计评审报告 |
| 修复报告 | `docs/harness/fixes/` | Bug诊断与修复记录 |
| 入口地图 | `AGENTS.md`（项目根目录，可选） | 项目技术栈与验证命令速查 |
| 验证入口 | `package.json` 中的 test/lint/typecheck | 质量验证命令 |

---

## 回写时机

每个 Task 或 Step 完成时，做一次回写：

```
开发任务完成 → 更新 _baton.md 状态 → 追加到 history.yaml（长期归档）
决策发生     → 追加到 decisions.yaml
同类问题第二次出现 → 提示用户是否登记到 project-constraints.md
任务收口前   → 执行 Layer 5 回写验证确认所有链路已记录
```