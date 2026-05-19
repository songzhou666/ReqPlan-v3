# ReqPlan-v3 Harness 验证与调试指南

> 本文档说明如何验证和调试 ReqPlan-v3 Harness 系统

---

## 一、验证机制

### 1.1 产物契约验证

每个 Agent 的产物必须满足契约要求：

| Agent | 产物 | 契约要求 |
|-------|------|----------|
| Analyzer | `_analysis.md` | 必须包含：基本信息、需求理解、项目现状、约束条件、分析结论 |
| Designer | `_design.md` | 必须包含：需求回顾、架构设计、任务计划、验证方案 |
| Verifier | `_verification.md` | 必须包含：验证结果、错误分类、修复建议、最终判定 |

### 1.2 状态机验证

状态转移必须遵循规则：

```
✓ 允许的转移：
  - INIT → START
  - START → ANALYZE
  - ANALYZE → CONFIRM
  - CONFIRM → DESIGN | ABORT
  - DESIGN → IMPLEMENT
  - IMPLEMENT → VERIFY
  - VERIFY → JUDGE
  - JUDGE → DONE | DESIGN | IMPLEMENT | FAILED
  - DESIGN → IMPLEMENT（修复模式）
  - IMPLEMENT → VERIFY（修复模式）

✗ 不允许的转移：
  - START → DESIGN（跳过 ANALYZE）
  - DESIGN → DONE（跳过 IMPLEMENT 和 VERIFY）
  - JUDGE → ANALYZE（回退过多阶段）
```

---

## 二、调试方法

### 2.1 检查产物文件

当流程出现问题时，首先检查产物文件：

```bash
# 检查产物目录
ls -la {项目路径}/.agent/harness/

# 检查产物内容
cat {项目路径}/.agent/harness/_analysis.md
cat {项目路径}/.agent/harness/_design.md
cat {项目路径}/.agent/harness/_verification.md
```

### 2.2 检查状态

```bash
# 检查当前状态
grep "状态" {项目路径}/.agent/harness/_*.md

# 检查历史记录
cat {项目路径}/docs/harness/history.yaml
```

### 2.3 检查计划文件

```bash
# 检查任务计划
ls -la {项目路径}/.agent/plans/

# 检查特定计划
cat {项目路径}/.agent/plans/{date}-{module}.md
```

---

## 三、常见问题

### 3.1 产物文件缺失

**问题**：`_analysis.md` 或 `_design.md` 不存在

**排查**：
1. 检查对应 Agent 是否执行
2. 检查 Agent prompt 是否正确
3. 检查文件路径是否正确

**解决**：
1. 重新运行对应 Agent
2. 手动创建产物文件（按模板）

### 3.2 状态转移错误

**问题**：状态机跳过了某个阶段

**排查**：
1. 检查 SKILL.md 中的禁止清单
2. 检查状态机定义
3. 检查产物文件

**解决**：
1. 修正状态转移
2. 重新执行被跳过的阶段
3. 补充缺失的产物

### 3.3 验证失败

**问题**：验证阶段持续失败

**排查**：
1. 检查 Layer 1 是否通过
2. 检查错误分类是否正确
3. 检查重试计数

**解决**：
1. 根据错误类型选择修复模式
2. 修复后重新验证
3. 如果超过重试上限，报告失败

### 3.4 Agent 执行失败

**问题**：子 Agent 无法正常执行

**排查**：
1. 检查 Agent prompt 文件是否存在
2. 检查产物读取是否正确
3. 检查上下文是否完整

**解决**：
1. 补充缺失信息
2. 手动触发 Agent
3. 降级为单 Agent 模式

---

## 四、调试工具

### 4.1 状态检查命令

```bash
# 查看所有产物文件
find {项目路径}/.agent/harness -name "*.md" -type f

# 查看最近修改的产物
ls -lt {项目路径}/.agent/harness/

# 查看产物创建时间
stat {项目路径}/.agent/harness/_*.md
```

### 4.2 流程回放

```bash
# 按时间顺序查看产物
cat {项目路径}/.agent/harness/_analysis.md | grep "分析时间"
cat {项目路径}/.agent/harness/_design.md | grep "设计时间"
cat {项目路径}/.agent/harness/_verification.md | grep "验证时间"
```

### 4.3 错误追踪

```bash
# 查找失败记录
grep -r "FAIL" {项目路径}/.agent/harness/
grep -r "FAILED" {项目路径}/.agent/plans/

# 查看失败详情
cat {项目路径}/.agent/harness/_verification.md | grep -A 10 "错误详情"
```

---

## 五、性能优化

### 5.1 减少产物文件大小

```
建议：
- 产物文件尽量精简
- 详细的错误信息放到附录
- 使用表格和列表而非大段文字
```

### 5.2 加速状态转移

```
优化点：
- 产物文件使用固定格式，便于快速解析
- 避免在产物中包含大段代码
- 使用头部摘要代替完整内容
```

### 5.3 缓存复用

```
策略：
- 可复用的代码分析结果可以缓存
- 技术栈信息可以复用
- 历史决策可以作为参考
```

---

## 六、安全检查

### 6.1 越权检查

检查是否有 Agent 越权：

```
Analyzer Agent 越权？
  - 编写代码？ ❌ 禁止
  - 运行测试？ ❌ 禁止

Designer Agent 越权？
  - 编写代码？ ❌ 禁止
  - 运行测试？ ❌ 禁止

Implementer Agent 越权？
  - 修改非任务范围文件？ ❌ 禁止
  - 跳过验证？ ❌ 禁止

Verifier Agent 越权？
  - 修改代码？ ❌ 禁止
```

### 6.2 数据完整性

检查产物数据完整性：

```
_analysis.md 必须包含：
  - 分析时间
  - 核心功能（至少 1 个）
  - 技术栈

_design.md 必须包含：
  - 设计时间
  - 任务列表（至少 1 个）
  - 验证方案

_verification.md 必须包含：
  - 验证时间
  - 最终判定
  - Layer 1 结果
```

---

## 七、日志记录

### 7.1 关键事件日志

建议在关键节点记录日志：

```markdown
# .agent/harness/trace.log

[2026-05-19 10:00:00] ANALYZE 开始
[2026-05-19 10:05:00] ANALYZE 完成，产物: _analysis.md
[2026-05-19 10:05:01] CONFIRM 开始
[2026-05-19 10:06:00] CONFIRM 用户确认
[2026-05-19 10:06:01] DESIGN 开始
...
```

### 7.2 错误日志

```markdown
# .agent/harness/error.log

[2026-05-19 10:10:00] ERROR: Layer 1 失败
  - 文件: types/order.ts
  - 错误: Missing return type
  - 建议: 添加返回类型

[2026-05-19 10:15:00] ERROR: 重试次数超限
  - 任务: 列表页面实现
  - 重试次数: 2
  - 原因: 测试持续失败
```

---

## 八、回归测试

### 8.1 基本流程测试

```
测试场景：
1. 启动 ReqPlan
2. 输入需求："做一个用户登录功能"
3. 检查状态转移：INIT → START → ANALYZE → CONFIRM
4. 确认需求
5. 检查状态转移：CONFIRM → DESIGN → IMPLEMENT → VERIFY
6. 检查状态转移：VERIFY → JUDGE → DONE
```

### 8.2 异常流程测试

```
测试场景：
1. 启动 ReqPlan
2. 输入需求："做一个用户登录功能"
3. 验证失败（模拟）
4. 检查重试机制
5. 检查超过重试上限后的处理
```

---

## 九、监控指标

### 9.1 关键指标

| 指标 | 定义 | 目标 |
|------|------|------|
| 成功率 | 流程完成的比率 | > 90% |
| 平均执行时间 | 从开始到完成的平均时间 | < 30 分钟 |
| 重试率 | 需要重试的任务比率 | < 20% |
| 产物完整率 | 产物文件完整的比率 | > 95% |

### 9.2 监控方法

```bash
# 统计成功率
grep -c "DONE" {项目路径}/docs/harness/history.yaml

# 统计重试次数
grep -c "RETRY" {项目路径}/.agent/harness/_verification.md

# 统计产物缺失
ls {项目路径}/.agent/harness/_*.md | wc -l
```

---

*本文档用于 ReqPlan-v3 Harness 系统的验证和调试*
