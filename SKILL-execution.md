# ReqPlan-v3 执行指南 (v4.0)

> **本文档是 ReqPlan-v3 的核心执行手册。每次激活 Skill 时，必须按照本指南执行。**

---

## 一、快速开始

### 1.1 首次激活

```bash
# 1. 立即读取接力棒
read {项目路径}/.agent/harness/_baton.md

# 2. 如果不存在，创建目录和接力棒
mkdir -p {项目路径}/.agent/harness/
write {项目路径}/.agent/harness/_baton.md

# 3. 按照本指南执行 START → ANALYZE
```

### 1.2 续跑执行

```bash
# 1. 立即读取接力棒
read {项目路径}/.agent/harness/_baton.md

# 2. 识别当前状态
# 当前状态: {状态名称}

# 3. 读取相关产物
read {项目路径}/.agent/harness/_analysis.md
read {项目路径}/.agent/harness/_design.md

# 4. 按照状态继续执行
```

---

## 二、执行前必读

### ⚠️ 绝对禁止行为

| # | 禁止项 | 后果 |
|---|--------|------|
| 1 | ❌ 不读接力棒就执行 | 可能破坏已有进度 |
| 2 | ❌ 不更新接力棒就结束 | 下一个 Session 无法续跑 |
| 3 | ❌ 跳过产物验证 | 可能引入错误 |
| 4 | ❌ 跳过 CONFIRM 阶段 | 必须用户确认 |
| 5 | ❌ 自行修复后不记录 | 破坏状态一致性 |
| 6 | ❌ 超过重试上限继续 | 防止死循环 |
| 7 | ❌ 不读取产物就做判断 | 必须基于产物决策 |
| 8 | ❌ 直接编写代码 | 必须通过 Implementer Agent |

### ⚠️ 必须执行行为

| # | 必须项 | 时机 |
|---|--------|------|
| 1 | ✅ 读取接力棒 | 任何操作前 |
| 2 | ✅ 更新接力棒 | 每个阶段结束前 |
| 3 | ✅ 验证产物 | 进入下一阶段前 |
| 4 | ✅ 展示摘要 | CONFIRM 阶段 |
| 5 | ✅ 记录问题 | 遇到问题时 |

---

## 三、完整执行流程

```
START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE
                                      ↓
                  ┌────────────────────┼────────────────────┐
                  ↓                    ↓                    ↓
               ✅ DONE              🔧 DESIGN             🔄 IMPLEMENT
                                    (修复模式)           (重试模式)
```

---

## 四、阶段详解

### 4.1 START 阶段

**入口**：用户首次触发 ReqPlan-v3

**执行步骤**：

```markdown
1. [ ] 检查接力棒是否存在
   read {项目路径}/.agent/harness/_baton.md

2. [ ] 如果不存在，创建目录和接力棒
   mkdir -p {项目路径}/.agent/harness/
   write {项目路径}/.agent/harness/_baton.md

3. [ ] 提取用户需求
   - 识别场景类型（开发/分析/修复）
   - 确认项目路径

4. [ ] 更新接力棒
   - 状态: START → ANALYZE
   - 记录: 用户需求摘要

5. [ ] 自动进入 ANALYZE 阶段
```

---

### 4.2 ANALYZE 阶段

**入口**：START 完成

**执行步骤**：

```markdown
1. [ ] 创建工作目录
   mkdir -p {项目路径}/.agent/harness/

2. [ ] 读取 Analyzer Agent
   read {Skill路径}/agents/analyzer-agent.md

3. [ ] 调度 Analyzer Agent
   - 使用 explorer 类型
   - 生成 _analysis.md

4. [ ] 验证产物
   - 检查 _analysis.md 存在
   - 检查格式符合模板

5. [ ] 更新接力棒
   - 状态: ANALYZE ✅
   - 下一步: CONFIRM

6. [ ] 自动进入 CONFIRM 阶段
```

---

### 4.3 CONFIRM 阶段

**入口**：ANALYZE 完成

**⚠️ 关键**：这是唯一的用户交互节点！

```markdown
1. [ ] 读取 _analysis.md

2. [ ] 展示摘要
   - 核心功能列表
   - 技术栈
   - 涉及文件

3. [ ] 等待用户响应
   - ✅ 确认 → 进入 DESIGN
   - ✏️  修改 → 返回 ANALYZE
   - ❌ 取消 → 终止流程
```

---

### 4.4 DESIGN 阶段

**入口**：CONFIRM 用户确认

**执行步骤**：

```markdown
1. [ ] 读取上下文
   - _analysis.md
   - designer-agent.md

2. [ ] 调度 Designer Agent
   - 使用 worker 类型
   - 生成 _design.md

3. [ ] 验证产物
   - 检查格式完整
   - 检查任务列表可执行

4. [ ] 更新接力棒
   - 状态: DESIGN ✅
   - 下一步: IMPLEMENT
```

---

### 4.5 IMPLEMENT 阶段

**入口**：DESIGN 完成

**执行步骤**：

```markdown
1. [ ] 读取上下文
   - _design.md
   - implementer-agent.md

2. [ ] 按任务列表执行
   for each 任务 in 任务列表:
     - 读取设计要求
     - 编写代码
     - 记录进度

3. [ ] 生成实现摘要
   - _implementation.md

4. [ ] 更新接力棒
   - 状态: IMPLEMENT ✅
   - 下一步: VERIFY
```

---

### 4.6 VERIFY 阶段

**入口**：IMPLEMENT 完成

**执行步骤**：

```markdown
1. [ ] 读取上下文
   - _design.md
   - verifier-agent.md

2. [ ] 执行 5 层验证
   - Layer 1: 静态检查 (pylint/ruff/mypy)
   - Layer 2: 单元测试 (pytest)
   - Layer 3: 构建集成 (python -m py_compile)
   - Layer 4: 异常处理 (边界测试)
   - Layer 5: 流程合规 (产物完整性)

3. [ ] 生成验证报告
   - _verification.md

4. [ ] 更新接力棒
   - 状态: VERIFY ✅
   - 下一步: JUDGE
```

---

### 4.7 JUDGE 阶段

**入口**：VERIFY 完成

**执行步骤**：

```markdown
如果 PASS ✅:
  - → DONE
  - 更新接力棒: 状态 DONE ✅
  - 输出完成报告

如果 ARCHITECTURE_VIOLATION 🔧:
  - → DESIGN(修复模式)

如果 REVIEW_VIOLATION 🔧:
  - → IMPLEMENT(修复模式)
  - retry 不计入

如果 RUNTIME_FAILURE 🔄 且 retry < 2:
  - → IMPLEMENT(重试模式)
  - retry += 1

如果 retry >= 2 ❌:
  - → FAILED
  - 输出失败报告
```

---

## 五、产物检查清单

### 5.1 _analysis.md 必须包含

```markdown
- [ ] # 需求分析报告（标题）
- [ ] ## 基本信息（时间、分析者、场景类型）
- [ ] ## 需求理解（核心功能、涉及角色、数据实体）
- [ ] ## 技术栈
- [ ] ## 涉及文件
- [ ] ## 约束条件
- [ ] ## 可复用资源
```

### 5.2 _design.md 必须包含

```markdown
- [ ] # 技术设计文档（标题）
- [ ] ## 技术方案概述
- [ ] ## 模块划分
- [ ] ## 接口定义（REST API）
- [ ] ## 数据模型
- [ ] ## 任务列表（带依赖）
- [ ] ## 验证方案（Layer 1-5）
```

### 5.3 _verification.md 必须包含

```markdown
- [ ] # 验证报告（标题）
- [ ] ## Layer 1: 静态检查
- [ ] ## Layer 2: 单元测试
- [ ] ## Layer 3: 构建集成
- [ ] ## Layer 4: 异常处理
- [ ] ## Layer 5: 流程合规
- [ ] ## 判定结果: PASS / FAIL
```

---

## 六、接力棒更新模板

### 6.1 状态流转模板

```markdown
## 元信息
- 当前状态: {状态}
- 开始时间: {ISO 8601}
- 最后更新: {ISO 8601}

## 进度追踪
- [x] START - {时间} ✅
- [ ] ANALYZE - 进行中
- [ ] CONFIRM - 等待确认
- ...

## 产物清单
- [ ] .agent/harness/_analysis.md ⏳
- [ ] .agent/harness/_design.md ⏳
- ...

## 下一步行动
1. {任务1}
2. {任务2}
```

---

## 七、文件路径速查

```bash
# Skill 根目录
{Skill路径}/

# Agent 模板
agents/analyzer-agent.md
agents/designer-agent.md
agents/implementer-agent.md
agents/verifier-agent.md

# 协议文档
protocols/baton-protocol.md
protocols/phase-protocol.md

# 产物模板
artifacts/template-artifacts.md
```

```bash
# 项目目录
{项目路径}/

# 接力棒和产物
{项目路径}/.agent/harness/_baton.md
{项目路径}/.agent/harness/_analysis.md
{项目路径}/.agent/harness/_design.md
{项目路径}/.agent/harness/_verification.md
```

---

## 八、常见问题

### 8.1 接力棒不存在

```markdown
情况：首次触发

解决方案：
1. 创建目录
2. 创建接力棒
3. 继续 START → ANALYZE
```

### 8.2 产物丢失

```markdown
情况：接力棒显示存在，但文件不存在

解决方案：
1. 识别缺失的产物
2. 重新生成
3. 更新接力棒
```

### 8.3 用户中断

```markdown
情况：用户突然停止

解决方案：
1. 立即更新接力棒
2. 记录当前进度
3. 提示续跑方式
```

---

*本文档是 ReqPlan-v3 的核心执行手册*
*版本: v4.0*
*更新: 2026-05-19*
