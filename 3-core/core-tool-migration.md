# Core Tool Migration
# 工具迁移指南 (v1)

## 职责

- 工具/框架/库迁移的规范化方法，迁移类任务有标准可依
- 迁移风险分级与影响评估
- 迁移验证策略——逐步验证而非一步到位
- 可回滚的撤销方案模板

## 使用条件

本指南在以下任一条件满足时激活：

1. 任务涉及核心依赖版本升级（React 17→18、Vue 2→3 等）
2. 任务涉及构建工具/打包工具的替换（Webpack→Vite、CRA→Next.js 等）
3. 任务涉及数据层的替换（Redux→Zustand、Axios→fetch 等）
4. 任务涉及目标平台的切换（Node 16→18、Python 3.8→3.11 等）
5. 任务涉及基础设施的迁移（VM→Docker、自建→云服务等）

## 迁移类型与风险分级

### 四级风险模型

| 风险级别 | 迁移类型 | 典型场景 | 影响评估 | 失败后果 |
|---------|---------|---------|---------|---------|
| **L1 补丁级** | 同级版本升级、patch 版本 | React 18.2.0→18.3.0 | 无 API 变更，无行为变化 | 回退即可，无影响 |
| **L2 优化级** | 次版本升级、开发工具替换 | Vite 4→5、Webpack→Turbopack | 可能有弃用 API，本地开发体验变化 | 开发效率短期下降 |
| **L3 重构级** | 主版本升级、同生态框架替换 | React 17→18、Vue 2→3 | API 变更、可能有破坏性变更 | 业务模块需调整 |
| **L4 替换级** | 跨生态迁移、数据库替换 | Redux→Zustand、MySQL→PostgreSQL | 大量代码重写、数据需迁移 | 严重项目延期 |

### 风险评分矩阵

| 因素 | L1 | L2 | L3 | L4 |
|------|-----|-----|-----|-----|
| API 兼容性 | 100% | ≥90% | ≥70% | <70% |
| 代码改动率 | <1% | <10% | <30% | ≥30% |
| 测试覆盖率要求 | 无要求 | ≥60% | ≥80% | ≥95% |
| 回滚复杂度 | 简单 | 简单 | 中等 | 复杂 |
| 是否需要并行运行 | 否 | 否 | 推荐 | 强制 |

## 迁移的"四步走"框架

任何迁移任务都应遵循以下四个阶段：

```
评估 → 规划 → 执行(可回滚) → 观察
 ↑                         │
 └──────── 回退 ──────────┘
```

### 第一步：评估

**产出**：迁移评估报告

```
迁移评估模板：

1. 当前版本：xxx → 目标版本：xxx
2. 变更类型：L1/L2/L3/L4
3. 影响范围：涉及文件数 ___、涉及模块 ___、涉及 API ___
4. 破坏性变更清单：
   - [ ] 变更1：影响模块A、B
   - [ ] 变更2：影响模块C
5. 测试覆盖率要求：___%（当前：___%）
6. 回滚方案概要：___
7. 是否需要并行运行：是/否
8. 预计工作量：___ 人天
9. 风险评估：低/中/高
10. 建议：执行/延期/放弃
```

### 第二步：规划

**产出**：迁移实现路径计划

在 template-plan.md 的实现路径格式中，特别关注以下章节：

```yaml
# Entry Points：迁移的起点
entryPoints:
  - type: "command"
    path: "npx react-codemod rename-unsafe-lifecycles"
    description: "React 官方 codemod 自动迁移弃用生命周期"
  - type: "command"
    path: "npm outdated"
    description: "检查当前依赖版本"
  - type: "file"
    path: "package.json"
    description: "版本号修改入口"

# Failure Strategy：迁移的决定性章节
failureStrategies:
  - scenario: "codemod 运行报错"
    strategy: "skip"
    retries: 2
    escalation: "单文件手动处理"
    note: "codemod 不是全覆盖的"
  - scenario: "迁移后测试失败超过 10%"
    strategy: "rollback"
    retries: 0
    escalation: "回退后分析根因再重试"
    note: "超过阈值说明迁移准备不充分"
  - scenario: "迁移后构建产物不一致"
    strategy: "block"
    retries: 0
    escalation: "等待 team lead 决策"
    note: "产物差异需确认是预期行为还是 Bug"
  - scenario: "某个 API 在新版本中已废弃"
    strategy: "fallback"
    retries: 0
    escalation: "用 polyfill 或 shim 临时替代"
    note: "记录到 decision_log 作为后续 cleanup 任务"

# Rollback：迁移的核心保障
rollbackStrategy:
  - condition: "任一验收口径未通过"
    action: "git revert + npm install 旧版本"
    verification: "所有测试用例通过 + 构建成功"
  - condition: "上线后错误率上升超过 5%"
    action: "回退发布 + 标记迁移版本为 blocked"
    verification: "错误率恢复至基线水平"
```

### 第三步：执行（可回滚原则）

#### 版本控制策略

```
迁移过程中的每个成功节点都应当有一个 git tag：

git tag v3.2.0-before-migration   ← 迁移前快照
git tag v3.2.0-migration-codemod  ← codemod 执行后
git tag v3.2.0-migration-manual   ← 手动修复后
git tag v3.2.0-migration-test     ← 测试通过后
git tag v3.2.0-migration-done     ← 迁移完成

每个 tag 对应一个可回滚的恢复点。
```

#### 阶梯式迁移

不适合一次提交完成的迁移，应采用阶梯式策略：

```
L1 迁移：单次提交（1 个 stage）
  提交 → 验证 → 完成

L2 迁移：两次提交（2 个 stage）
  Stage 1: 兼容代码 + 弃用警告去除 → 验证
  Stage 2: 切换默认行为 → 验证

L3 迁移：三次提交（3 个 stage + 观察期）
  Stage 1: 添加新版本兼容层 → 验证
  Stage 2（观察期 24h）：确认兼容层无问题 → 验证
  Stage 3: 移除旧代码 → 验证

L4 迁移：N 次提交（Strangler Fig 模式）
  Stage 1: 建立并行运行环境
  Stage 2~N-1: 逐个模块迁移
  Stage N: 确认旧系统无流量 → 下线
```

#### Strangler Fig 模式（L4 迁移的标准做法）

```
┌─────────────────────────────┐
│  用户请求                    │
│      │                      │
│      ▼                      │
│  路由层（feature flag）      │
│      │                      │
│   ┌──┴──┐                   │
│   │     │                   │
│   ▼     ▼                   │
│ 旧系统  新系统               │
│   │     │                   │
│   └──┬──┘                   │
│      │                      │
│      ▼                      │
│  统一响应                    │
└─────────────────────────────┘

实施步骤：
  1. 在路由层加入 feature flag
  2. 对每个模块逐步切换：5% → 25% → 50% → 100%
  3. 每步观察 24h 错误率和性能
  4. 任何一步出现问题，flag 切回 0%
  5. 100% 运行稳定 1 周后移除旧系统
```

### 第四步：观察

#### 观察期清单

```
迁移后的观察期要求因风险级别而异：

L1：观察 0 小时（信任测试覆盖即可）
  检查项：
  - [ ] 构建通过
  - [ ] lint/typecheck 通过
  - [ ] 单元测试通过
  - [ ] 集成测试通过

L2：观察 1 小时
  检查项：
  - [ ] L1 全部
  - [ ] 开发者本地运行正常
  - [ ] CI/CD 流水线正常
  - [ ] 无新增 warning

L3：观察 24 小时
  检查项：
  - [ ] L2 全部
  - [ ] 错误率无异常上升
  - [ ] 核心链路功能正常
  - [ ] 性能指标未下降
  - [ ] 用户无投诉

L4：观察 1 周（按模块分批）
  检查项：
  - [ ] L3 全部
  - [ ] 数据一致性确认
  - [ ] 旧系统零流量
  - [ ] 备份验证通过
  - [ ] 团队知识转移完成
```

## 迁移特有的验证策略

### 对比验证

迁移的核心验证手段——不是"测试用例如期通过"就够了，而是"新旧版本输出一致"。

```
对比验证模式：
  1. 在测试环境中同时运行旧版本和新版本
  2. 对同一输入，比较新旧版本的输出
  3. 输出一致性阈值：≥99.9%（允许浮点数精度差异等可接受误差）
  4. 不一致的 case 逐一确认是否属于预期行为变化

工具推荐：
  - snapshot testing（组件渲染对比）
  - API response diff（接口响应对比）
  - lighthouse comparison（性能对比）
  - bundle analysis diff（产物体积对比）
```

### 迁移验证层次

| 验证层 | L1 | L2 | L3 | L4 |
|-------|-----|-----|-----|-----|
| static（lint/typecheck） | ✅ | ✅ | ✅ | ✅ |
| unit（测试用例） | ✅ | ✅ | ✅ | ✅ |
| integration（API 对比验证） | ❌ | ✅ | ✅ | ✅ |
| failure（异常场景） | ❌ | ❌ | ✅ | ✅ |
| writeback（回写/性能对比） | ❌ | ❌ | ✅ | ✅ |
| 灰度对比（生产流量 shadow） | ❌ | ❌ | 推荐 | 强制 |

## 常见迁移场景模板

### 场景一：React 版本升级

```
升级步骤：
  1. npm install react@18 react-dom@18
  2. 运行 `npx react-codemod rename-unsafe-lifecycles`
  3. 手动修复不受 codemod 覆盖的部分
  4. 检查新 API：createRoot 替代 render
  5. StrictMode 双次渲染兼容
  6. 运行全部测试，执行对比验证

风险点：
  - StrictMode 下 useEffect 执行两次
  - 旧版生命周期（componentWillMount 等）被删除
  - Concurrent Mode 的非兼容行为

验证命令：
  npm run lint
  npm run typecheck
  npm run test -- --coverage
  npm run build
  npx lighthouse-ci https://staging.example.com
```

### 场景二：构建工具替换（Webpack → Vite）

```
迁移步骤（L2-L3 风险）：
  1. 先安装 Vite + 对应插件
  2. 创建 vite.config.ts（保持与 webpack 一致的 alias、proxy）
  3. 逐个迁移功能模块的环境变量、静态资源导入
  4. 对比 dev server 行为一致
  5. 对比 build 产物体积和质量

验证命令：
  # 对比构建产物
  npm run build:webpack        # 旧构建
  npm run build:vite           # 新构建
  diff -r dist-webpack/ dist-vite/

  # 功能验证
  npx playwright test --reporter=list

风险点：
  - CommonJS → ESM 兼容问题
  - 环境变量暴露方式差异
  - 静态资源路径处理差异

回滚方案：
  保留 webpack 配置，在 package.json 中同时保留两个 build script
  如 Vite 构建出现问题，切回 webpack 构建后排查
```

### 场景三：状态管理替换（Redux → Zustand）

```
迁移步骤（L4 替换级 — Strangler Fig 模式）：
  1. 安装 zustand，保持 redux 并存
  2. 新建 store 使用 zustand 实现
  3. 新功能直接使用 zustand
  4. 逐个模块将 redux store 迁移到 zustand
  5. 迁移完成后移除 redux 依赖

对比验证：
  对每个迁移的模块，同时维护 redux + zustand 两份 store
  比较来自同一个 action 的两份 store 状态是否一致

验证命令：
  npm run test:redux-vs-zustand  # 自定义对比测试脚本

风险点：
  - middleware（redux-saga/thunk）的行为映射
  - devtools 支持差异
  - 大量订阅的性能差异

回滚方案：
  保留 redux 代码到下一个大版本，迁移期间不做大重构
```

## 迁移的决策日志

以下事项必须在 decision_log 中记录：

```
- 迁移前版本组合的锁定状态（package-lock.json / yarn.lock 的 hash）
- codemod 或自动迁移工具的输出日志
- 任何手动修改的地方及原因
- 测试失败的 case 及处理方式
- 预期行为变化的清单及确认记录（谁确认了什么变化是可接受的）
- 灰度/并行运行期间的数据（错误率、性能指标）
```

## 与现有组件的集成

### 集成到 Task Pipeline

```
Stage 1 任务入口：
  识别迁移类型（L1~L4）→ 确定是否升级 Harness 级别
  L1/L2 → 可按 L 级别执行
  L3/L4 → 强制按 H 级别执行

Stage 2 计划冻结：
  template-plan.md 中必须明确：
  - rollbackStrategy（迁移必须可回滚）
  - failureStrategies（codemod 失败、测试对比不一致等的处理）
  - verificationCommands（对比验证命令）

Stage 4 验证评审：
  迁移任务的核心验证不是"测试通过"，而是"新旧一致"
  必须包含对比验证环节

Stage 5 回写收口：
  迁移完成的标志不是"代码引入"，而是"旧版本下线"
  在 decision_log 中记录迁移全过程的决策
```

### 集成到 Harness Selector

迁移任务在 Harness Selector 中强制升级一级：

```yaml
# 如果按三轴算出来是 L（轻量），但任务是 L3/L4 迁移
# 强制升级到 M 或 H
harness_level_override:
  condition: "task_type == migration && risk_level >= L3"
  force_level: "M" # L3 → M
  or: "H"          # L4 → H
```

## 版本信息
**版本**: 1.0.0
**更新时间**: 2026-05-14
**引用**: 3-core/core-task-pipeline.md, 3-core/core-harness-selector.md, 3-core/core-verification.md, 5-templates/template-plan.md, 4-schemas/schema-writeback.md
