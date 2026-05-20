# Core State Management
# 状态管理核心模块

## 概述

状态管理模块负责管理ReqPlan的全局状态，包括项目状态、任务状态、进度追踪和上下文保持。

**核心原则**：
- `_baton.md`（接力棒）是跨Session持久化的**唯一真相来源**
- 使用统一的**7阶段Harness状态机**：START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE
- 支持重试机制和回退修复流程

## Input

```yaml
- projectId: string           # 项目ID（必填）
- action: string              # 操作类型：get | set | update | reset | snapshot
- data?: object               # 更新数据（可选）
- options?: object            # 选项参数（可选）
```

### action类型说明

| action | 说明 | 参数要求 |
|--------|------|----------|
| get | 获取状态 | projectId |
| set | 设置状态（覆盖） | projectId, data |
| update | 更新状态（合并） | projectId, data |
| reset | 重置状态 | projectId |
| snapshot | 创建快照 | projectId |

## Output

```yaml
- success: boolean           # 操作是否成功
- state: object              # 当前状态对象
- filePath: string          # 状态文件路径
- message: string           # 操作结果消息
- timestamp: string         # 操作时间戳
```

## 状态文件结构

### 目录结构
```
<项目根目录>/
└── .agent/
    └── harness/
        ├── _baton.md          # 接力棒（主要状态文件）
        ├── _analysis.md       # 分析产物
        ├── _design.md         # 设计产物
        ├── _implementation.md # 实现摘要
        └── _verification.md   # 验证产物
```

### _baton.md格式（接力棒）

```markdown
# 🔄 ReqPlan-v3 接力棒

## 元信息

| 字段 | 值 |
|------|-----|
| 项目 | {项目名称} |
| 开始时间 | {ISO 8601} |
| 最后更新 | {ISO 8601} |
| 当前状态 | START | ANALYZE | CONFIRM | DESIGN | IMPLEMENT | VERIFY | JUDGE | DONE | FAILED |
| 模式 | NORMAL | DESIGN_FIX | REVIEW_FIX | RETRY_FIX |
| 重试计数 | {0/1/2} |

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

### ⭐ 任务追踪（统一管理）

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

## 7阶段状态转换规则

### 主流程转换
```
START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE
                                  ↓
              ┌───────────────────┼───────────────────┐
              ↓                   ↓                   ↓
           ✅ DONE            🔧 DESIGN          🔄 IMPLEMENT
                              (修复模式)         (重试模式)
                             ↓         ↓      ↓         ↓
                        ARCH问题   REVIEW问题  重试≤2   重试>2
                             ↓         ↓      ↓         ↓
                        继续DESIGN  继续IMP  继续IMP  ❌ FAILED
```

### 阶段转换条件

| 当前阶段 | 下一阶段 | 条件 |
|---------|---------|------|
| START | ANALYZE | 接力棒已创建，用户需求已记录 |
| ANALYZE | CONFIRM | `_analysis.md` 已生成并验证通过 |
| CONFIRM | DESIGN | 用户已确认需求 |
| CONFIRM | ANALYZE | 用户要求修改需求 |
| DESIGN | IMPLEMENT | `_design.md` 已生成并验证通过 |
| IMPLEMENT | VERIFY | `_implementation.md` 已生成，所有任务完成 |
| VERIFY | JUDGE | `_verification.md` 已生成，5层验证完成 |
| JUDGE | DONE | 验证结果为 PASS |
| JUDGE | DESIGN | 验证结果为 ARCHITECTURE_VIOLATION，进入 DESIGN_FIX 模式 |
| JUDGE | IMPLEMENT | 验证结果为 REVIEW_VIOLATION，进入 REVIEW_FIX 模式 |
| JUDGE | IMPLEMENT | 验证结果为 RUNTIME_FAILURE 且 retry < 2，进入 RETRY_FIX 模式 |
| JUDGE | FAILED | retry >= 2 |

### 任务状态转换
```
⏳ 待开始 → 🔄 进行中 → ✅ 完成
                ↓
              ❌ 失败
```

**转换条件**：
- `待开始 → 进行中`：任务开始执行
- `进行中 → 完成`：任务完成
- `进行中 → 失败`：任务执行失败

## 进度计算

### 阶段进度
```
每个阶段的进度 = (已完成步骤数 / 总步骤数) × 100%
```

### 综合进度
```
overall_progress =
  (START_weight * START_progress +
   ANALYZE_weight * ANALYZE_progress +
   CONFIRM_weight * CONFIRM_progress +
   DESIGN_weight * DESIGN_progress +
   IMPLEMENT_weight * IMPLEMENT_progress +
   VERIFY_weight * VERIFY_progress +
   JUDGE_weight * JUDGE_progress) / 100

默认权重：
- START: 5
- ANALYZE: 15
- CONFIRM: 5
- DESIGN: 20
- IMPLEMENT: 30
- VERIFY: 15
- JUDGE: 10
```

## 快照机制

### 创建快照
```yaml
action: snapshot
options:
  reason: string    # 快照原因（可选）
  version: string   # 版本标识（可选）
```

### 快照文件结构
```
<项目根目录>/.agent/harness/snapshots/
├── baton-20260520-100000.md
├── baton-20260520-110000.md
└── baton-20260520-120000.md
```

### 快照恢复
```yaml
action: restore
data:
  snapshotPath: string    # 快照文件路径
```

## 失败策略

### E701 - 接力棒文件损坏
```yaml
E701:
  error: "接力棒文件损坏"
  message: "检测到接力棒文件损坏，正在尝试恢复..."
  recovery:
    - 尝试从最近的快照恢复
    - 如果快照也损坏，询问用户是否重新初始化
    - 提供手动恢复选项
```

### E702 - 项目未初始化
```yaml
E702:
  error: "项目未初始化"
  message: "项目尚未初始化，请先创建项目"
  recovery:
    - 提示用户使用 /reqplan start 创建新项目
    - 提供创建项目的流程
```

### E703 - 状态版本不兼容
```yaml
E703:
  error: "状态版本不兼容"
  message: "接力棒文件版本与当前版本不兼容"
  recovery:
    - 尝试自动升级接力棒格式
    - 如果升级失败，提示手动迁移
```

## 最佳实践

1. **每次交互后更新接力棒**：确保状态持久化
2. **事务性更新**：确保状态更新的原子性
3. **定期创建快照**：建议每完成一个阶段创建快照
4. **错误恢复**：提供清晰的错误信息和恢复路径

## 版本信息

**版本**: 4.1
**更新时间**: 2026-05-20
**引用**: ../protocols/baton-protocol.md, ../protocols/phase-protocol.md
