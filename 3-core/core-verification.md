# Core Verification
# 验证体系（v3.3）

## 概述

验证是 ReqPlan 的核心质量保障能力。本文档定义 5 层验证金字塔，取代原有的单一验收模式。

**设计原则**：验证不是最终环节的最后一步，而是嵌入到流程每个阶段的持续活动。
**边界**：verification 负责自动化工具检查（lint/typecheck/test），有明确的 pass/fail 结果；人工/半自动判断（设计一致性、代码可读性、架构合理性）由 core-review.md 处理。

## 5 层验证金字塔

```
                    ┌─────────────────────────────────────┐
                    │        Layer 5: 回写验证             │
                    │  结果是否同步到任务系统/PR/文档        │
                    ├─────────────────────────────────────┤
                    │        Layer 4: 失败验证             │
                    │  异常、超时、重试、回滚策略是否符合预期  │
                    ├─────────────────────────────────────┤
                    │        Layer 3: 链路验证             │
                    │  入口、输入、处理、输出是否连通         │
                    ├─────────────────────────────────────┤
                    │        Layer 2: 单元验证             │
                    │  核心函数和边界条件是否正确            │
                    ├─────────────────────────────────────┤
                    │        Layer 1: 静态检查             │
                    │  代码结构、类型、lint、格式是否符合规范  │
                    └─────────────────────────────────────┘
```

### Layer 1: 静态检查（Static）

**目的**：在代码运行前发现结构性问题

**检查内容**：
- 代码结构是否符合项目规范
- 类型是否一致
- lint 规则是否满足
- 格式是否统一

**证据类型**：
- lint 输出
- 类型检查结果
- 编译/构建结果

**通用检查项**：
```yaml
static_checks:
  - check: "代码风格检查"
    command: "npm run lint / ruff check / go vet"
    pass: "零错误，或仅允许的 warning 级别"
    fail_action: "修复后重新检查"
  - check: "类型检查"
    command: "npm run typecheck / mypy / go build"
    pass: "零类型错误"
    fail_action: "修复类型后重新检查"
  - check: "格式检查"
    command: "prettier --check / black --check / gofmt -l"
    pass: "无格式差异"
    fail_action: "自动格式化或手动修复"
```

### Layer 2: 单元验证（Unit）

**目的**：验证核心函数和边界条件是否正确

**检查内容**：
- 核心函数的正确性
- 边界条件处理
- 错误路径覆盖

**证据类型**：
- 单测结果
- 关键 case 列表
- 覆盖率报告

**通用检查项**：
```yaml
unit_checks:
  - check: "单元测试执行"
    command: "npm run test / pytest / go test ./..."
    pass: "所有 P0 用例通过，整体通过率 >= 90%"
    fail_action: "修复失败用例后重新运行"
  - check: "边界条件覆盖"
    command: "检查测试用例是否包含边界值"
    pass: "关键边界条件已覆盖"
    fail_action: "补充边界测试用例"
```

### Layer 3: 链路验证（Integration）

**目的**：验证入口、输入、处理、输出是否连通

**检查内容**：
- 入口命令是否可执行
- 输入能否正确传递
- 处理链路是否完整
- 输出是否符合预期

**证据类型**：
- 命令执行记录
- 接口请求/响应记录
- mock 环境结果

**通用检查项**：
```yaml
integration_checks:
  - check: "入口验证"
    command: "执行入口命令或脚本"
    pass: "命令成功执行，无异常退出"
    fail_action: "检查入口配置和依赖"
  - check: "接口验证"
    command: "API 请求测试 / curl / 接口文档对照"
    pass: "接口返回预期状态码和数据结构"
    fail_action: "修正接口实现后重试"
  - check: "数据流验证"
    command: "执行完整操作链路"
    pass: "数据在各环节正确流转"
    fail_action: "检查数据转换和处理逻辑"
```

### Layer 4: 失败验证（Failure）

**目的**：验证异常场景的处理是否符合预期

**检查内容**：
- 异常输入的处理
- 超时场景
- 重试机制
- 回滚/停止策略

**证据类型**：
- 错误日志
- 失败 case 记录
- 恢复步骤验证

**通用检查项**：
```yaml
failure_checks:
  - check: "异常输入验证"
    command: "传入无效/缺失/错误格式的输入"
    pass: "系统给出明确的错误提示，不会崩溃"
    fail_action: "补充异常处理逻辑"
  - check: "超时验证"
    command: "模拟超时场景"
    pass: "超时后触发预期策略（重试/跳过/停止）"
    fail_action: "修正超时处理逻辑"
  - check: "回滚验证"
    command: "模拟失败场景后执行回滚操作"
    pass: "系统恢复到可用状态"
    fail_action: "修正回滚逻辑"
```

### Layer 5: 回写验证（Writeback）

**目的**：验证结果是否写回到应有的位置

**检查内容**：
- 验证摘要是否生成
- 结果是否同步到任务系统
- PR/MR 是否包含变更说明
- 文档是否更新

**证据类型**：
- 验证摘要文件
- 任务状态更新记录
- PR/MR 描述
- 文档变更记录

**通用检查项**：
```yaml
writeback_checks:
  - check: "验证摘要"
    command: "检查 docs/test/ 目录下的验证摘要文件"
    pass: "摘要包含验证结果、剩余风险、后续事项"
    fail_action: "补全验证摘要"
  - check: "任务同步"
    command: "检查任务系统状态更新"
    pass: "任务状态已更新，反馈已记录"
    fail_action: "手动同步任务状态"
  - check: "文档同步"
    command: "检查相关文档是否更新"
    pass: "文档与实现一致"
    fail_action: "更新相关文档"
```

## 验证层级与流程映射

```yaml
flow_verification_mapping:
  full_project:
    - phase: "需求分析"
      layers: ["Layer 2", "Layer 3"]
    - phase: "设计与规划"
      layers: ["Layer 1", "Layer 2"]
    - phase: "开发实现"
      layers: ["Layer 1", "Layer 2", "Layer 3"]
    - phase: "验收测试"
      layers: ["Layer 2", "Layer 3", "Layer 4"]
    - phase: "交付收口"
      layers: ["Layer 5"]

  iteration:
    - phase: "迭代开发"
      layers: ["Layer 1", "Layer 2", "Layer 3"]
    - phase: "迭代验收"
      layers: ["Layer 2", "Layer 4"]
    - phase: "收口"
      layers: ["Layer 5"]

  design_review:
    - phase: "设计审查"
      layers: ["Layer 1"]
    - phase: "设计验证"
      layers: ["Layer 3"]
    - phase: "结论记录"
      layers: ["Layer 5"]

  audit:
    - phase: "代码扫描"
      layers: ["Layer 1"]
    - phase: "逻辑验证"
      layers: ["Layer 2", "Layer 3"]
    - phase: "安全审查"
      layers: ["Layer 4"]
    - phase: "报告输出"
      layers: ["Layer 5"]

  testing:
    - phase: "测试设计"
      layers: ["Layer 2"]
    - phase: "测试执行"
      layers: ["Layer 2", "Layer 3", "Layer 4"]
    - phase: "报告输出"
      layers: ["Layer 5"]

  docs:
    - phase: "文档审查"
      layers: ["Layer 1"]
    - phase: "文档验证"
      layers: ["Layer 3"]
    - phase: "发布确认"
      layers: ["Layer 5"]

  refactor:
    - phase: "架构分析"
      layers: ["Layer 1"]
    - phase: "重构实施"
      layers: ["Layer 1", "Layer 2", "Layer 3"]
    - phase: "回归验证"
      layers: ["Layer 2", "Layer 3", "Layer 4"]
    - phase: "收口确认"
      layers: ["Layer 5"]
```

## 验证流程

### Step 1: 确定验证层级

根据当前流程阶段，确定需要执行的验证层级。

### Step 2: 逐层执行

从 Layer 1 开始，逐层向上执行验证。**前一层未通过时，不建议跳过到更高层**。

### Step 3: 记录验证结果

每层验证结果记录到验证摘要：

```yaml
verification_summary:
  taskId: "TASK-001"
  layers:
    - layer: 1
      status: "pass"
      evidence: "lint 零错误，类型检查通过"
      issues: []
    - layer: 2
      status: "pass"
      evidence: "12/12 用例通过"
      issues: []
    - layer: 3
      status: "pass"
      evidence: "API 链路验证通过"
      issues: []
    - layer: 4
      status: "warning"
      evidence: "超时处理未覆盖所有场景"
      issues:
        - "数据库连接超时未处理"
    - layer: 5
      status: "pass"
      evidence: "验证摘要已写入 docs/test/"
      issues: []
  overall: "pass"
  remaining_risks:
    - "数据库连接超时场景将在下一轮迭代处理"
  writeback_location: "docs/test/verify-TASK-001.md"
```

## 结果回写规范

验证完成后，结果应回写到以下位置：

```yaml
writeback_targets:
  - target: "docs/test/verify-{{taskId}}.md"
    content:
      - "验证摘要"
      - "剩余风险"
      - "后续事项"
    format: "markdown"

  - target: "任务系统状态更新"
    content:
      - "任务状态"
      - "验证结论"
    format: "根据任务系统格式"

  - target: "PR/MR 描述"
    content:
      - "变更说明"
      - "验证结果"
      - "风险说明"
    format: "markdown"
```

## 验证结果状态定义

```yaml
verification_status:
  pass: "所有检查项通过，无未处理问题"
  warning: "存在非阻塞问题，有处理计划"
  fail: "存在阻塞问题，需要修复"
  skip: "该层级不适用于当前场景"
```

## 失败策略

### E501: 验证命令未找到

**错误信息**：
```
E501: 验证命令未找到：{{command}}
```

**处理方式**：
```
⚠️ 未找到验证命令：{{command}}

可能的原因：
1. 项目未配置该验证命令
2. 依赖未安装

建议操作：
1. 检查项目文档（AGENTS.md）验证命令
2. 安装缺失依赖
3. 手动指定验证方式
```

### E502: 验证层级前置条件不满足

**错误信息**：
```
E502: 验证层级前置条件不满足：Layer {{layerNumber}}
```

**处理方式**：
```
⚠️ 当前验证层级的前置条件不满足：

Layer {{layerNumber}} 的前置验证未通过。

建议：从 Layer 1 开始逐层执行验证
```

## 最佳实践

1. **逐层推进**：前一层未通过时不跳转到更高层
2. **持续验证**：验证不是最终环节的最后一步，而是嵌入到每个阶段
3. **结果可追溯**：每层验证结果记录到验证摘要
4. **风险透明**：不掩盖剩余风险，写入摘要并说明处理计划
5. **命令可执行**：验证命令应可直接运行，避免"手动检查"类模糊描述

## 版本信息

**版本**: 3.3
**更新时间**: 2026-05-14
**引用**: 4-schemas/schema-landing-zone.md, 7-flows/ 下所有流程文件
