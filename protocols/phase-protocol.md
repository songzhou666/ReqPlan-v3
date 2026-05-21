# ReqPlan-v3 阶段执行规范

> **本文档定义每个阶段的详细执行流程、检查清单和验证标准。**

---

## 一、阶段通用流程

每个阶段必须遵循以下标准流程：

```
┌─────────────────────────────────────────┐
│ Phase Entry                              │
│ 1. 读取接力棒                            │
│ 2. 检查前置条件                          │
│ 3. 更新状态为"进行中"                     │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ Phase Execute                            │
│ 1. 读取必要输入                          │
│ 2. 调用子 Agent（如果需要）               │
│ 3. 生成产物                             │
│ 4. 验证产物                             │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ Phase Exit                               │
│ 1. 更新接力棒                            │
│ 2. 展示摘要给用户                        │
│ 3. 等待用户输入                          │
└─────────────────────────────────────────┘
```

### 通用检查项

```markdown
阶段进入前必须确认：
- [ ] 接力棒文件存在（调用 scripts/validate-baton.ps1 校验）
- [ ] 前置阶段已完成
- [ ] 所需产物已生成（调用 scripts/validate-artifact.ps1 校验）
- [ ] 用户意图明确
- [ ] 阶段转换合法（调用 scripts/run-checks.ps1 校验）
```

> **强制检查点**：每个阶段转换前，必须调用 `scripts/run-checks.ps1 -ProjectPath <路径> -Stage <阶段名>` 进行校验。未通过则阻断流程。

---

## 二、阶段 1: START

### 1.1 执行时机

用户首次触发 ReqPlan-v3 时进入。

### 1.2 入口检查

```markdown
检查项：
- [ ] 接力棒文件是否存在？
- [ ] 用户需求已接收？
```

### 1.3 任务清单

```markdown
任务 1: 检查接力棒
[ ] read {项目路径}/.agent/harness/_baton.md

任务 2: 如果接力棒不存在，创建新的
[ ] mkdir -p {项目路径}/.agent/harness/
[ ] write _baton.md (状态保持 START，不提前修改)

任务 3: 提取用户需求
[ ] 解析用户输入
[ ] 识别场景类型（开发/分析/修复）
[ ] 确认项目路径

任务 4: 自检清单
[ ] 接力棒已创建/已读取
[ ] 用户需求已记录
[ ] 场景类型已识别

任务 5: 检查点验证 — 调用 run-checks 校验阶段转换
[ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage ANALYZE
【此时 baton 状态为 START，run-checks 校验 START→ANALYZE 合法性】

任务 6: 更新接力棒
[ ] 状态: START → ANALYZE
[ ] 记录用户需求摘要
[ ] 记录开始时间
[ ] 标记: START ✅
```

### 1.4 执行命令示例

```bash
# 1. 检查接力棒
read {项目路径}/.agent/harness/_baton.md

# 2. 如果不存在，创建目录
mkdir -p {项目路径}/.agent/harness/

# 3. 创建接力棒（状态 START，不提前修改）
write {项目路径}/.agent/harness/_baton.md

# 4. run-checks 校验阶段转换（此时 baton 状态仍为 START）
pwsh -File {Skill路径}/scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage ANALYZE

# 5. 验证通过后，更新接力棒状态为 ANALYZE
# read → 修改状态 → write
```

### 1.5 退出标准

- [ ] 接力棒已创建/已读取
- [ ] 用户需求已记录
- [ ] 场景类型已识别
- [ ] run-checks 校验通过（START→ANALYZE 合法）
- [ ] 状态已更新为 ANALYZE

---

## 三、阶段 2: ANALYZE

### 2.1 执行时机

START 完成后自动进入，或用户修改需求时返回。

### 2.2 入口检查

```markdown
检查项：
- [ ] 接力棒状态为 ANALYZE 或 START
- [ ] 项目路径已确认
- [ ] 用户需求已明确
```

### 2.3 任务清单

```markdown
任务 1: 创建工作目录
[ ] mkdir -p {项目路径}/.agent/harness/

任务 2: 读取 Analyzer Agent
[ ] read agents/analyzer-agent.md

任务 3: 拼接上下文
[ ] 用户原始需求
[ ] 项目路径
[ ] 场景类型

任务 4: 调度 Analyzer Agent
[ ] 使用 explorer 类型
[ ] 执行分析任务

任务 5: 生成产物
[ ] 生成 _analysis.md
[ ] 遵循模板格式

任务 6: 验证产物
[ ] 检查文件存在
[ ] 检查格式正确
[ ] 检查内容完整

任务 7: 检查点验证 — 调用 run-checks 校验阶段转换
[ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage CONFIRM
【此时 baton 状态为 ANALYZE，校验 ANALYZE→CONFIRM 合法性】

任务 8: 更新接力棒
[ ] 状态: ANALYZE ✅ → CONFIRM
[ ] 产物清单更新
[ ] 下一步: CONFIRM
```

### 2.4 产物验证标准

`_analysis.md` 必须包含以下章节：

```markdown
检查清单：
- [ ] # 需求分析报告（标题）
- [ ] ## 基本信息（时间、分析者、场景类型、原始需求）
- [ ] ## 需求理解
  - [ ] ### 核心功能（表格形式）
  - [ ] ### 涉及角色
  - [ ] ### 数据实体
- [ ] ## 技术栈
- [ ] ## 涉及文件
- [ ] ## 约束条件
- [ ] ## 可复用资源
```

### 2.5 执行命令示例

```bash
# 1. 创建目录
mkdir -p {项目路径}/.agent/harness/

# 2. 读取 Analyzer Agent
read {Skill路径}/agents/analyzer-agent.md

# 3. 执行分析（这里由 AI 自主执行）

# 4. 写入产物
write {项目路径}/.agent/harness/_analysis.md

# 5. 验证产物（强制检查点）
# 调用校验脚本验证产物格式
. {Skill路径}/scripts/harness/validate-artifact.ps1 -ProjectPath {项目路径} -Artifact analysis

# 6. 阶段转换检查 — 先调用 run-checks（此时 baton 状态为 ANALYZE）
. {Skill路径}/scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage CONFIRM

# 7. 校验通过后更新接力棒
read {项目路径}/.agent/harness/_baton.md
# 修改状态为 ANALYZE ✅ → CONFIRM
write {项目路径}/.agent/harness/_baton.md
```

### 2.6 退出标准

- [ ] `_analysis.md` 已生成
- [ ] 格式符合模板
- [ ] 内容完整（包含所有必需章节）
- [ ] 接力棒已更新
- [ ] 状态为 ANALYZE ✅

---

## 四、阶段 3: CONFIRM

### 4.1 执行时机

ANALYZE 完成后进入。

### 4.2 入口检查

```markdown
检查项：
- [ ] 接力棒状态为 CONFIRM 或 ANALYZE
- [ ] `_analysis.md` 存在
- [ ] 内容完整
```

### 4.3 交互模板

```markdown
---

## 📋 需求分析摘要

> 请花 1 分钟确认需求理解是否正确。

### 核心功能

| # | 功能点 | 优先级 | 说明 |
|---|--------|--------|------|
| 1 | {功能1} | P0 | {说明} |
| 2 | {功能2} | P1 | {说明} |
| 3 | {功能3} | P2 | {说明} |

### 技术栈

- 后端：{技术栈}
- 前端：{技术栈}
- 数据库：{数据库}
- 其他：{其他依赖}

### 涉及文件

- `{文件1}`
- `{文件2}`
- `{文件3}`

### 关键约束

- {约束1}
- {约束2}

---

### ⚠️ 请确认

**需求理解是否正确？**

- ✅ **确认（继续设计）**：开始设计技术方案
- ✏️  **修改需求**：描述需要修改的内容，我会重新分析
- ❌  **取消**：终止 ReqPlan 流程

---

*确认后，我将进入设计阶段，制定详细的技术方案。*
```

### 4.4 用户响应处理

#### 如果用户选择"确认"

```markdown
1. 检查点验证 — 调用 run-checks 校验阶段转换
   [ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage DESIGN
   【此时 baton 状态为 CONFIRM，校验 CONFIRM→DESIGN 合法性】

2. 更新接力棒
   - 状态: CONFIRM ✅ → DESIGN
   - 记录: 用户已确认
   - 下一步: DESIGN

3. 展示提示
   "好的，开始设计技术方案..."
   
4. 自动进入 DESIGN 阶段
```

#### 如果用户选择"修改"

```markdown
1. 更新接力棒
   - 状态: CONFIRM → ANALYZE
   - 记录: 用户修改内容

2. 询问具体修改
   "请描述需要修改的内容"

3. 等待用户输入

4. 重新进入 ANALYZE 阶段
```

#### 如果用户选择"取消"

```markdown
1. 更新接力棒
   - 状态: CONFIRM → ABORT
   - 记录: 用户取消

2. 输出结束摘要
   ```
   ReqPlan 流程已终止。
   
   完成情况：
   - [x] 需求分析
   
   产出文件：
   - {项目路径}/.agent/harness/_analysis.md
   
   如需重新开始，请说"帮我规划 XXX"
   ```

3. 结束流程
```

### 4.5 退出标准

- [ ] 用户已做出选择
- [ ] 接力棒已更新
- [ ] 状态已流转（CONFIRM/DESIGN/ANALYZE/ABORT）

---

## 五、阶段 4: DESIGN

### 5.1 执行时机

CONFIRM 用户确认后进入，或 JUDGE 判断需要 DESIGN_FIX 时返回。

### 5.2 入口检查

```markdown
检查项：
- [ ] 接力棒状态为 DESIGN
- [ ] 用户已确认（CONFIRM ✅）
- [ ] `_analysis.md` 存在
- [ ] 模式类型已知（NORMAL/DESIGN_FIX）
```

### 5.3 任务清单

```markdown
任务 1: 读取上下文
[ ] read _analysis.md
[ ] read agents/designer-agent.md

任务 2: 判断模式
- 如果是 DESIGN_FIX：
  - 读取 _verification.md 识别架构问题
  - 聚焦修复架构问题
- 如果是 NORMAL：
  - 从头开始设计

任务 3: 调度 Designer Agent
[ ] 使用 worker 类型
[ ] 传入分析报告内容
[ ] 传入模式类型

任务 4: 生成产物
[ ] 生成 _design.md
[ ] 遵循模板格式

任务 5: 验证产物
[ ] 检查文件存在
[ ] 检查格式正确
[ ] 检查内容完整

任务 6: 检查点验证 — 调用 run-checks 校验阶段转换
[ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage IMPLEMENT
【此时 baton 状态为 DESIGN，校验 DESIGN→IMPLEMENT 合法性】

任务 7: 更新接力棒
[ ] 状态: DESIGN ✅ → IMPLEMENT
[ ] 产物清单更新
[ ] 下一步: IMPLEMENT
```

### 5.4 产物验证标准

`_design.md` 必须包含以下章节：

```markdown
检查清单：
- [ ] # 技术设计文档（标题）
- [ ] ## 基本信息
- [ ] ## 技术方案概述
- [ ] ## 模块划分
  - [ ] 模块结构图
  - [ ] 模块职责说明
- [ ] ## 接口定义
  - [ ] REST API 规范（路径、方法、参数、响应）
  - [ ] 数据格式（JSON Schema）
- [ ] ## 数据模型
  - [ ] 数据表结构
  - [ ] 字段定义
- [ ] ## 任务列表
  - [ ] 任务表格（任务名、涉及文件、验证方式、依赖）
  - [ ] 优先级排序
  - [ ] ⚠️ **重要**：任务状态统一在 baton.md 的"任务追踪"章节中管理

- [ ] ## 验证方案
  - [ ] Layer 1: 静态检查
  - [ ] Layer 2: 单元测试
  - [ ] Layer 3: 构建集成
  - [ ] Layer 4: 异常处理
  - [ ] Layer 5: 流程合规
```

### 5.5 特殊处理：DESIGN_FIX 模式

当 JUDGE 判断为 ARCHITECTURE_VIOLATION 时：

```markdown
## DESIGN_FIX 模式

### 识别架构问题
[ ] read _verification.md
[ ] 提取 ARCHITECTURE_VIOLATION 列表

### 问题示例
```
### Layer 1: 架构违规

| # | 问题 | 涉及文件 | 建议修复 |
|---|------|---------|---------|
| 1 | 分层混乱 | app.py | 拆分到 services/ |
| 2 | 循环依赖 | models/ | 解除依赖 |
```

### 聚焦修复
- [ ] 只修复架构问题
- [ ] 不改变业务逻辑
- [ ] 更新 _design.md
- [ ] 更新模块划分图

### 退出条件
- [ ] 所有架构问题已修复
- [ ] _design.md 已更新
- [ ] 接力棒已更新
```

### 5.6 退出标准

- [ ] `_design.md` 已生成
- [ ] 格式符合模板
- [ ] 内容完整（包含所有必需章节）
- [ ] 任务列表可执行
- [ ] 接力棒已更新
- [ ] 状态为 DESIGN ✅

---

## 六、阶段 5: IMPLEMENT

### 6.1 执行时机

DESIGN 完成后进入，或 JUDGE 判断需要 REVIEW_FIX/RETRY_FIX 时返回。

### 6.2 入口检查

```markdown
检查项：
- [ ] 接力棒状态为 IMPLEMENT
- [ ] 用户已确认设计
- [ ] `_design.md` 存在
- [ ] 任务列表明确
- [ ] 模式类型已知（NORMAL/REVIEW_FIX/RETRY_FIX）
```

### 6.3 任务清单

```markdown
任务 1: 读取上下文
[ ] read _design.md
[ ] read agents/implementer-agent.md

任务 2: 判断模式
- 如果是 REVIEW_FIX：
  - 读取 _verification.md 识别代码规范问题
  - 聚焦修复规范问题
- 如果是 RETRY_FIX：
  - 检查环境问题
  - 重新执行任务
- 如果是 NORMAL：
  - 按任务列表顺序执行

任务 3: 按任务列表执行
[ ] 任务 1: 读取设计 → 编写代码 → 验证
[ ] 任务 2: ...
[ ] ...

任务 4: 记录进度
[ ] 每个任务完成后更新进度
[ ] 遇到问题记录到 baton

任务 5: 生成实现摘要
[ ] 创建 _implementation.md
[ ] 记录：完成的任务、涉及文件、问题记录

任务 6: 检查点验证 — 调用 run-checks 校验阶段转换
[ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage VERIFY
【此时 baton 状态为 IMPLEMENT，校验 IMPLEMENT→VERIFY 合法性】

任务 7: 更新接力棒
[ ] 状态: IMPLEMENT ✅ → VERIFY
[ ] 产物清单更新
[ ] 下一步: VERIFY
```

### 6.4 进度更新示例

```markdown
## 当前阶段详情

### IMPLEMENT（进行中）

**进度**: 60%

**已完成任务**:
- [x] 任务 1: 用户模型 ✅
  - 涉及文件: models/user.py
  - 验证: pylint ✅

**进行中任务**:
- [ ] 任务 2: JWT 认证 🔄
  - 涉及文件: services/auth.py
  - 预计: 15 分钟

**待完成任务**:
- [ ] 任务 3: 注册接口 ⏳
- [ ] 任务 4: 登录接口 ⏳
- [ ] 任务 5: 密码重置 ⏳

**遇到的问题**:
- ⚠️ JWT 过期时间配置待确认
- 💡 使用默认 30 分钟过期
```

### 6.5 特殊处理：REVIEW_FIX 模式

当 JUDGE 判断为 REVIEW_VIOLATION 时：

```markdown
## REVIEW_FIX 模式

### 识别规范问题
[ ] read _verification.md
[ ] 提取 REVIEW_VIOLATION 列表

### 问题示例
```
### Layer 1: 代码规范

| # | 问题 | 文件 | 行号 | 建议修复 |
|---|------|------|------|---------|
| 1 | 缺少文档注释 | app.py | 45 | 添加 docstring |
| 2 | 命名不符 | utils.py | 12 | 改为 snake_case |
| 3 | 缺少 type hint | auth.py | 8 | 添加类型标注 |
```

### 聚焦修复
- [ ] 按问题列表逐一修复
- [ ] 不改变业务逻辑
- [ ] 完成后重新验证
```

### 6.6 特殊处理：RETRY_FIX 模式

当 JUDGE 判断为 RUNTIME_FAILURE 且 retry < 2 时：

```markdown
## RETRY_FIX 模式

### 分析失败原因
[ ] read _verification.md
[ ] 提取 RUNTIME_FAILURE 信息

### 问题示例
```
### Layer 3: 构建失败

**错误信息**:
```
ImportError: cannot import name 'JWTManager'
```

**可能原因**:
1. 依赖未安装
2. 导入路径错误
3. 版本不兼容

**修复方案**:
1. 检查 requirements.txt
2. 修复导入语句
```

### 执行步骤
1. [ ] 分析失败原因
2. [ ] 实施修复
3. [ ] 重新执行构建
4. [ ] 记录修复方案
```

### 6.7 退出标准

- [ ] 所有任务已完成
- [ ] 代码符合规范
- [ ] `_implementation.md` 已生成
- [ ] 接力棒已更新
- [ ] 状态为 IMPLEMENT ✅

---

## 七、阶段 6: VERIFY

### 7.1 执行时机

IMPLEMENT 完成后进入。

### 7.2 入口检查

```markdown
检查项：
- [ ] 接力棒状态为 VERIFY
- [ ] 实现已完成
- [ ] `_design.md` 存在
- [ ] 实现摘要已生成
```

### 7.3 任务清单

```markdown
任务 1: 读取上下文
[ ] read _design.md
[ ] read agents/verifier-agent.md

任务 2: 执行 Layer 1 验证（静态检查）
[ ] 执行: pylint/ruff/mypy
[ ] 记录: 违规数量和详情
[ ] 判断: 是否通过

任务 3: 执行 Layer 2 验证（单元测试）
[ ] 执行: pytest tests/
[ ] 记录: 通过率、覆盖率
[ ] 判断: 是否通过

任务 4: 执行 Layer 3 验证（构建集成）
[ ] 执行: python -m py_compile
[ ] 记录: 构建结果
[ ] 判断: 是否通过

任务 5: 执行 Layer 4 验证（异常处理）
[ ] 测试: 401/403/404 响应
[ ] 测试: 边界条件
[ ] 记录: 异常处理结果

任务 6: 执行 Layer 5 验证（流程合规）
[ ] 检查: 产物完整性
[ ] 检查: 文档更新
[ ] 记录: 合规检查结果

任务 7: 生成验证报告
[ ] 生成 _verification.md
[ ] 包含判定结果

任务 8: 检查点验证 — 调用 run-checks 校验阶段转换
[ ] 调用 scripts/harness/run-checks.ps1 -ProjectPath {项目路径} -Stage JUDGE
【此时 baton 状态为 VERIFY，校验 VERIFY→JUDGE 合法性】

任务 9: 更新接力棒
[ ] 状态: VERIFY ✅ → JUDGE
[ ] 产物清单更新
[ ] 下一步: JUDGE
```

### 7.4 验证命令参考

```bash
# Layer 1: 静态检查
pylint app.py
ruff check app.py
mypy app.py

# Layer 2: 单元测试
pytest tests/ -v --tb=short

# Layer 3: 构建测试
python -m py_compile app.py

# Layer 4: 异常测试
# 手动测试或编写测试用例

# Layer 5: 产物检查
ls -la .agent/harness/
```

### 7.5 产物验证标准

`_verification.md` 必须包含以下章节：

```markdown
检查清单：
- [ ] # 验证报告（标题）
- [ ] ## 基本信息
- [ ] ## Layer 1: 静态检查
  - [ ] 工具名称和版本
  - [ ] 检查结果（通过/失败）
  - [ ] 违规列表（如果有）
- [ ] ## Layer 2: 单元测试
  - [ ] 测试框架
  - [ ] 测试结果（通过数/总数）
  - [ ] 覆盖率
- [ ] ## Layer 3: 构建集成
  - [ ] 构建命令
  - [ ] 构建结果
- [ ] ## Layer 4: 异常处理
  - [ ] 测试场景
  - [ ] 结果
- [ ] ## Layer 5: 流程合规
  - [ ] 产物检查
  - [ ] 文档检查
- [ ] ## 判定结果
  - [ ] 综合判定: PASS / FAIL
  - [ ] 错误类型: ARCHITECTURE / REVIEW / RUNTIME
```

### 7.6 判定结果格式

```markdown
## 判定结果

### 综合判定
**状态**: ✅ PASS / ❌ FAIL

### 错误分类
如果 FAIL，分类如下：

| # | 错误类型 | 错误数 | 详情 |
|---|----------|--------|------|
| 1 | ARCHITECTURE_VIOLATION | 0 | 架构/分层违规 |
| 2 | REVIEW_VIOLATION | 0 | 代码规范问题 |
| 3 | RUNTIME_FAILURE | 0 | 测试/运行失败 |
| 4 | ENVIRONMENT | 0 | 环境配置问题 |

### 下一步
- PASS → JUDGE → DONE ✅
- ARCHITECTURE → JUDGE → DESIGN(修复模式)
- REVIEW → JUDGE → IMPLEMENT(修复模式)
- RUNTIME & retry < 2 → JUDGE → IMPLEMENT(重试模式)
- retry >= 2 → JUDGE → FAILED ❌
```

### 7.7 退出标准

- [ ] Layer 1-5 验证全部执行
- [ ] `_verification.md` 已生成
- [ ] 判定结果明确
- [ ] 接力棒已更新
- [ ] 状态为 VERIFY ✅

---

## 八、阶段 7: JUDGE

### 8.1 执行时机

VERIFY 完成后进入。

### 8.2 入口检查

```markdown
检查项：
- [ ] 接力棒状态为 JUDGE
- [ ] `_verification.md` 存在
- [ ] 包含判定结果
```

### 8.3 判断逻辑

```markdown
## JUDGE 决策树

[ ] read _verification.md
[ ] 提取判定结果

如果 PASS ✅:
  [ ] → 调用 run-checks.ps1 -ProjectPath {项目路径} -Stage DONE
  【此时 baton 状态为 JUDGE，校验 JUDGE→DONE 合法性】
  [ ] → 更新接力棒: 状态 JUDGE ✅ → DONE
  [ ] → 输出完成报告
  [ ] → 流程结束

如果 ARCHITECTURE_VIOLATION 🔧:
  [ ] 检查 design_fix_retry 计数
  [ ] 如果 design_fix_retry < 2:
      [ ] 调用 run-checks.ps1 -ProjectPath {项目路径} -Stage DESIGN
      【此时 baton 状态为 JUDGE，校验 JUDGE→DESIGN 合法性】
      - 更新接力棒:
        - 状态: JUDGE ✅ → DESIGN
        - 模式: DESIGN_FIX
        - design_fix_retry += 1
        - 产物: _design.md (需重新生成)
      - → 继续 DESIGN 阶段
  [ ] 如果 design_fix_retry >= 2 ❌:
      - 更新接力棒: 状态 FAILED ❌
      - 输出失败报告: 架构问题反复出现，需要人工介入
      - 流程结束

如果 REVIEW_VIOLATION 🔧:
  [ ] → IMPLEMENT(修复模式)
  [ ] 调用 run-checks.ps1 -ProjectPath {项目路径} -Stage IMPLEMENT
  【此时 baton 状态为 JUDGE，校验 JUDGE→IMPLEMENT 合法性】
  [ ] 更新接力棒:
      - 状态: JUDGE ✅ → IMPLEMENT
      - 模式: REVIEW_FIX
      - retry += 0 (不计入重试)
  [ ] → 继续 IMPLEMENT 阶段

如果 RUNTIME_FAILURE 🔄 且 retry < 2:
  [ ] → IMPLEMENT(重试模式)
  [ ] 调用 run-checks.ps1 -ProjectPath {项目路径} -Stage IMPLEMENT
  【此时 baton 状态为 JUDGE，校验 JUDGE→IMPLEMENT 合法性】
  [ ] 更新接力棒:
      - 状态: JUDGE ✅ → IMPLEMENT
      - 模式: RETRY_FIX
      - retry += 1 (计入重试)
  [ ] → 继续 IMPLEMENT 阶段

如果 RUNTIME_FAILURE 🔄 且 retry >= 2 ❌:
  [ ] → FAILED
  [ ] 更新接力棒: 状态 FAILED ❌
  [ ] 输出失败报告
  [ ] 流程结束

如果 ENVIRONMENT ⚠️:
  [ ] → 报告用户
  [ ] 更新接力棒:
      - 状态: JUDGE
      - 记录: 环境问题详情
      - 下一步: 等待用户处理
  [ ] 输出环境问题的通知和建议
  [ ] 等待用户处理环境后手动继续
```

### 8.4 错误分类说明

| 错误类型 | 策略 | 计入重试 | 说明 |
|----------|------|-----------|------|
| **ARCHITECTURE_VIOLATION** | DESIGN(修复) | ✅ 是 (design_fix_retry) | 架构/分层问题，最多修复2次 |
| **REVIEW_VIOLATION** | IMPLEMENT(修复) | ❌ 否 | 代码规范问题，修复后不会反复 |
| **RUNTIME_FAILURE** | IMPLEMENT(重试) | ✅ 是 | 测试失败，可能环境问题 |
| **ENVIRONMENT** | 报告用户，等待处理 | ❌ 否 | 环境问题，需人工介入 |

### 8.5 退出标准

- [ ] 判定结果已确定
- [ ] 接力棒已更新
- [ ] 状态已流转（DONE/DESIGN/IMPLEMENT/FAILED）

---

## 九、完成报告模板

### 9.1 DONE 报告

```markdown
---

## ✅ ReqPlan 流程完成

**项目**: {项目名称}
**完成时间**: {ISO 8601}
**总耗时**: {X} 分钟

### 流程回顾

- [x] ANALYZE - 需求分析
- [x] CONFIRM - 需求确认
- [x] DESIGN - 技术设计
- [x] IMPLEMENT - 代码实现
- [x] VERIFY - 质量验证
- [x] JUDGE - 完成判定

### 产出文件

| 文件 | 位置 | 说明 |
|------|------|------|
| _analysis.md | .agent/harness/ | 需求分析报告 |
| _design.md | .agent/harness/ | 技术设计文档 |
| _implementation.md | .agent/harness/ | 实现摘要 |
| _verification.md | .agent/harness/ | 验证报告 |

### 实现的功能

1. {功能1}
2. {功能2}
3. {功能3}

### 验证结果

| 层级 | 状态 | 详情 |
|------|------|------|
| Layer 1: 静态检查 | ✅ 通过 | 0 违规 |
| Layer 2: 单元测试 | ✅ 通过 | 15/15 通过 |
| Layer 3: 构建集成 | ✅ 通过 | 构建成功 |
| Layer 4: 异常处理 | ✅ 通过 | 3/3 场景 |
| Layer 5: 流程合规 | ✅ 通过 | 全部合规 |

### 下一步建议

1. {建议1}
2. {建议2}
3. {建议3}

---

*ReqPlan-v3 流程结束。感谢使用！*
```

### 9.2 FAILED 报告

```markdown
---

## ❌ ReqPlan 流程失败

**项目**: {项目名称}
**失败时间**: {ISO 8601}
**重试次数**: {X} 次

### 失败原因

**错误类型**: {类型}

**问题描述**:
```
{详细错误信息}
```

**涉及文件**:
- {文件1}
- {文件2}

### 流程回顾

- [x] ANALYZE - 需求分析
- [x] CONFIRM - 需求确认
- [x] DESIGN - 技术设计
- [~] IMPLEMENT - 实现失败
- [~] VERIFY - 验证失败
- [x] JUDGE - 判定失败

### 已产出文件

| 文件 | 状态 | 说明 |
|------|------|------|
| _analysis.md | ✅ | 需求分析报告 |
| _design.md | ✅ | 技术设计文档 |
| _implementation.md | ❌ | 未完成 |
| _verification.md | ✅ | 验证报告 |

### 建议后续操作

1. **修复环境问题**: {建议}
2. **简化需求**: {建议}
3. **分阶段实现**: {建议}

### 如何重试

```
# 查看验证报告
read .agent/harness/_verification.md

# 修复问题后，重新开始
"继续实现 XXX 功能"
```

---

*ReqPlan-v3 流程因重试超限而终止。请修复问题后重试。*
```

---

## 十、快速参考

### 阶段入口速查

| 阶段 | 入口检查 | 关键产物 |
|------|----------|----------|
| START | 接力棒不存在 | 接力棒 |
| ANALYZE | 接力棒状态 | _analysis.md |
| CONFIRM | _analysis.md 存在 | 用户确认 |
| DESIGN | 用户已确认 | _design.md |
| IMPLEMENT | _design.md 存在 | _implementation.md |
| VERIFY | 实现完成 | _verification.md |
| JUDGE | 验证完成 | 判定结果 |

### 产物检查速查

```bash
# 检查所有产物
ls -la {项目路径}/.agent/harness/

# 检查接力棒
read {项目路径}/.agent/harness/_baton.md

# 验证格式
head -n 20 {产物文件}
```

### 接力棒更新速查

```bash
# 读取
read {项目路径}/.agent/harness/_baton.md

# 更新
# 修改内容后
write {项目路径}/.agent/harness/_baton.md
```

---

*本文档是 ReqPlan-v3 Harness 系统的执行规范*
*版本: 4.1*
*更新: 2026-05-20*
