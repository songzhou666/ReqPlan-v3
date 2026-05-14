# Core Frontend Guide
# 前端实现深度指南 (v1)

## 职责

- 前端功能实现的规范化方法，涉足前端变更时有一致的执行方式
- 状态覆盖的完整框架——从"列举几条"到"系统性检查每一类状态"
- 组件层级分解规范，解决"组件该拆多细"的问题
- 前端特有验证策略：不仅测逻辑，还要测交互、视觉和边界

## 使用条件

本指南在以下条件**同时满足**时激活：

1. 当前任务涉及前端代码变更
2. Harness 级别为 M 或 H（L 级别可略读）
3. 任务存在可感知的用户界面状态变化

## 状态覆盖方法论

### 问题定位

前端实现中 80% 的 Bug 来自未覆盖的状态——"loading 状态没处理"、"空数据时白屏"、"错误提示不够友好"是最高频的三类缺陷。

### 六维状态模型

不再使用简单的"状态名称/覆盖方式"表格，改为**六维系统性检查**：

```
对于一个页面或组件，必须考虑以下 6 个维度的状态：
```

| 维度 | 检查问题 | 典型场景 | 验证方式 |
|------|---------|---------|---------|
| **加载态** | 数据未返回时用户看到什么？ | Skeleton / Spinner / 进度条 | 模拟慢网速观察 |
| **空数据态** | 列表/表格没有数据时显示什么？ | 空状态插画 + 引导文案 | 清空数据源验证 |
| **错误态** | 请求失败/网络异常时如何反馈？ | Toast / 错误页面 / 重试按钮 | mock 接口返回 500 |
| **边界态** | 超长内容/极大数据量时是否崩？ | 文本截断/虚拟滚动/分页 | 构造边界数据 |
| **交互态** | 用户操作过程中的反馈是否及时？ | Button loading / 禁用 / 防抖 | 快速反复点击 |
| **权限态** | 无权限用户看到什么？ | 403 页面 / 按钮隐藏 / 功能禁用 | 模拟不同角色登录 |

### 状态覆盖检查清单

每轮前端任务应在计划阶段完成以下清单：

```
前端状态检查清单：
  加载态处理：
    - [ ] 首屏有 Skeleton 或 Loading Spinner
    - [ ] 列表加载有分页 Skeleton
    - [ ] 异步操作按钮有 loading 状态
  空数据态处理：
    - [ ] 空列表有空状态插画 + 引导文案
    - [ ] 搜索结果为空有"没有找到相关内容"提示
    - [ ] 详情页数据为空有兜底展示
  错误态处理：
    - [ ] 接口异常有 Toast 或 Snackbar 提示
    - [ ] 页面级错误有错误展示页
    - [ ] 支持重试（自动或手动）
  边界态处理：
    - [ ] 超长文本被截断（CSS text-overflow）
    - [ ] 长列表使用虚拟滚动或分页
    - [ ] 特殊字符/XSS/HTML 注入做了转义
  交互态处理：
    - [ ] 提交/保存按钮防止重复点击
    - [ ] 表单输入有即时校验
    - [ ] 操作有明确的成功/失败反馈
  权限态处理：
    - [ ] 无权限页面跳转到 403
    - [ ] 无权限操作按钮隐藏或禁用
    - [ ] 数据级别权限在前端有过滤
```

### 在计划模板中的使用

在 template-plan.md 的状态覆盖表格中，按六维维度填写：

```yaml
frontendStates:
  - stateName: "加载态"
    coverageType: "Skeleton"
    coverageMethod: "使用 antd Skeleton 组件包裹列表区域"
    status: "已规划"
  - stateName: "空数据态"
    coverageType: "空状态插画"
    coverageMethod: "引入全局 Empty 组件，默认展示 + 操作按钮"
    status: "已规划"
  - stateName: "错误态"
    coverageType: "全局异常处理"
    coverageMethod: "封装 request interceptor，统一 Toast + 可点击重试"
    status: "已规划"
  - stateName: "边界态"
    coverageType: "CSS 截断"
    coverageMethod: "text-overflow: ellipsis + 最大宽度限制"
    status: "已规划"
  - stateName: "交互态"
    coverageType: "防抖 + loading"
    coverageMethod: "提交按钮使用 useDebounce 防抖 + loading 状态"
    status: "已规划"
  - stateName: "权限态"
    coverageType: "无权隐藏"
    coverageMethod: "封装 AuthButton 组件，根据 role 判断是否渲染"
    status: "不适用-当前无权限系统"
```

## 组件层级设计

### 分层原则

前端组件按职责分层，每层有明确边界：

```
┌─────────────────────────────────────────┐
│              页面层 (Page)                │    路由级别，组合区块
│  ┌─────────────────────────────────┐    │
│  │       区块层 (Section)          │    │    业务模块，组合小组件
│  │  ┌──────────┐ ┌──────────┐    │    │
│  │  │ 小组件    │ │ 小组件    │    │    │    有具体业务含义
│  │  │ (Widget) │ │ (Widget) │    │    │
│  │  └──────────┘ └──────────┘    │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │        基础组件 (Base)          │    │    跨项目复用，UI 库
│  │  Button / Input / Table / ...  │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### 各层职责

| 层级 | 职责 | 数据来源 | 是否可复用 | 测试重点 |
|------|------|---------|-----------|---------|
| **Page** | 路由匹配、参数提取、权限校验 | URL params + store/context | 否（页面唯一） | 路由跳转 + 整体渲染 |
| **Section** | 业务逻辑编排、数据聚合、状态管理 | store/context + props | 当前项目内复用 | 业务功能 + 状态覆盖 |
| **Widget** | UI 表现、事件处理 | props（无直接数据依赖） | 可跨项目复用 | 交互行为 + UI 展示 |
| **Base** | 通用 UI 元素 | props | 全局复用（UI 库） | 视觉 + 无障碍 |

### 组件分解决策树

```
一个 UI 区域该如何分解？

这块 UI 有没有独立的业务含义？
    ├── 没有 → 是否可复用？
    │        ├── 是 → 放到 Base 层（Button/Input/Table...）
    │        └── 否 → 合并到上层，不做独立组件
    └── 有 → 是否跨页面复用？
            ├── 跨项目复用 → Widget 层
            ├── 仅在当前项目中复用 → Section 层
            └── 仅当前页面出现 → 保持在 Page 层内部
```

### 在计划模板中的表达

在组件的 component_responsibilities 中按分层标注：

```
componentResponsibility:
  - component: "OrderListPage"
    type: "page"
    responsibility: "订单列表路由，URL 参数提取、权限校验"
    input: "URL query: page, search, status"
    output: "传入 Section 组件"
  
  - component: "OrderTableSection"
    type: "section"
    responsibility: "表格数据聚合、排序/筛选状态管理"
    input: "raw order list from API"
    output: "formatRows → Table"
  
  - component: "StatusTag"
    type: "widget"
    responsibility: "订单状态的颜色标签渲染"
    input: "status: string"
    output: "带颜色标签的 div"
```

## 页面结构规范

### 标准页面模板

```
┌─────────────────────────────────────────┐
│  顶部：PageHeader                       │
│  - 标题 + 描述                          │
│  - 操作按钮组（新建/编辑/导出）          │
├─────────────────────────────────────────┤
│  筛选区：FilterSection                  │
│  - 搜索框 + 下拉筛选 + 日期范围          │
│  - 筛选条件变更 → 触发列表刷新           │
├─────────────────────────────────────────┤
│  列表区：ContentSection                 │
│  - 表格/列表组件                          │
│  - 分页器（位置：底部居右）              │
│  - 空状态/加载态/错误态 三态覆盖         │
├─────────────────────────────────────────┤
│  浮层区：Modal / Drawer                 │
│  - 新建/编辑表单（弹窗形式）             │
│  - 确认对话框                            │
└─────────────────────────────────────────┘
```

### 页面结构填写示例

```
pageStructure: |
  [Page] OrderListPage
    [FilterSection] FilterSection
      ├── SearchInput (关键词搜索)
      ├── StatusSelect (订单状态筛选)
      └── DateRangePicker (下单日期范围)
    [ContentSection] OrderTableSection
      ├── Table (订单列表)
      ├── Pagination (分页)
      └── EmptyState (空数据)
    [Modal] OrderDetailModal
      └── 订单详情展示
```

## API 对接模式

### 三层数据流

```
用户操作 → Component → Service Layer → API
                              ↓
                          Store/Context
                              ↓
                 其他组件通过 store 响应
```

### 对接规范

```
Service 层原则：
  1. 每个 页面/区块 有独立的 service 文件
  2. Service 只做数据转换，不做 UI 操作
  3. 错误统一在 Service 层捕获并转换为标准格式

标准格式：
  interface ApiResult<T> {
    loading: boolean
    error: Error | null
    data: T | null
    retry: () => void
  }

命名约定：
  useXxx hook → 数据获取 + 状态管理
  xxxService  → 纯粹的 API 调用 + 数据转换
  xxxStore    → 全局状态（如跨页面共享）
```

### 数据流验证清单

```
- [ ] loading 状态在 API 调用期间正确展示
- [ ] 错误状态被正确捕获并展示给用户
- [ ] 数据更新后 store 中的其他消费组件正确响应
- [ ] 离开页面时未完成的请求被取消（AbortController）
- [ ] 重复请求被合并或去重（如快速切换 Tab）
```

## 前端验证策略

### 分层验证映射

```
┌───────────────────────────────────────────────┐
│  static（静态检查）                             │
│  ├── npm run lint（代码规范）                   │
│  ├── npm run typecheck（类型安全）              │
│  └── npm run format（代码格式）                 │
├───────────────────────────────────────────────┤
│  unit（单元验证）                               │
│  ├── 纯函数/工具方法测试                        │
│  ├── 自定义 hook 测试                           │
│  └── 组件渲染测试（无交互）                     │
├───────────────────────────────────────────────┤
│  integration（集成验证）                        │
│  ├── 组件交互测试（用户操作→UI 变化）           │
│  ├── Store → Component 层级数据流转             │
│  └── API Mock → 组件渲染链路                    │
├───────────────────────────────────────────────┤
│  failure（失败验证）                            │
│  ├── API 超时/500 时的 UI 表现                  │
│  ├── 网络断开后的行为                           │
│  └── 非法输入/边界值的提交                     │
├───────────────────────────────────────────────┤
│  writeback（回写验证）                          │
│  ├── 页面结构文档是否同步更新                   │
│  ├── 状态覆盖清单是否完成                       │
│  └── 新增组件已在组件树中记录                   │
└───────────────────────────────────────────────┘
```

### 常用验证命令模板

```bash
# 静态检查
npm run lint
npm run typecheck

# 单元测试（所有前端测试）
npm run test -- --coverage

# 单组件测试
npm run test -- --grep "OrderTableSection"

# 集成测试（如 Playwright）
npx playwright test --grep "订单列表"

# 构建验证
npm run build
```

## Harness 在前端项目中的落地

### Landing Zone 映射（前端特有）

| Landing Zone | 前端场景 | 示例 |
|-------------|---------|------|
| AGENTS.md | 技术栈声明 | React 18 + TypeScript + Vite |
| .agent/plans/ | 前端实现路径计划 | 含 pageStructure + frontendStates |
| docs/harness/control-plane.md | 前端设计约束 | UI 库、设计系统链接、代码规范 |
| docs/test/ | 前端测试验证 | Playwright 测试用例 |
| .agent/prompts/ | 前端专用 prompt | Storybook 组件开发规范 |
| scripts/harness/ | 前端检查脚本 | check-page-structure.ps1 |

### 前端项目的 adoption 路径

```
Phase 1（入门）：
  AGENTS.md 声明：
  - 前端技术栈（React/Vue/Angular + 版本）
  - 验证命令（lint/typecheck/test/build）
  - UI 组件库名称（antd / element-plus / shadcn）

Phase 2（标准）：
  template-plan.md 中填写：
  - pageStructure（页面结构树）
  - frontendStates（六维状态覆盖表格）
  - componentResponsibilities（组件层级标注）
  - 前端专用的 Entry Points

Phase 3（完善）：
  - 前端专用检查脚本（check-component-structure、check-page-coverage）
  - CI 中集成前端验证
  - Storybook / 组件文档自动同步
```

## 与现有组件的集成

### 集成到 Task Pipeline

```
Stage 1 任务入口 → 识别为前端任务 → 激活本指南
Stage 2 计划冻结 → 使用六维状态 + 组件分解方法论填写计划
Stage 3 Agent 执行 → 按分层架构 + 数据流规范实现
Stage 4 验证评审 → 使用分层验证映射（前端特有测试策略）
Stage 5 回写收口 → 同步前端组件文档和状态覆盖清单
```

### 集成到 template-plan

template-plan 中的 `前端实现说明` 章节引用本指南作为方法论基础：

```yaml
前端的 pageStructure 填写参考 core-frontend-guide.md 页面结构规范
前端的 frontendStates 填写参考 core-frontend-guide.md 六维状态模型
```

## 版本信息
**版本**: 1.0.0
**更新时间**: 2026-05-14
**引用**: 3-core/core-actions.md, 3-core/core-task-pipeline.md, 3-core/core-verification.md, 5-templates/template-plan.md, 5-templates/template-agents.md
