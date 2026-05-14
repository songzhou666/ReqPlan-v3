# ReqPlan v3.2 命令速查

## 快速开始

```
/reqplan start [--flow <flow>] [--resume]  # 启动引导或恢复上次进度
/reqplan init                               # 初始化项目 Harness 目录结构
/reqplan flow list                          # 列出所有可用流程
/reqplan guide                              # 智能引导（推荐）
```

## 流程选择

### 7个核心流程

| 流程 | 命令 | 说明 |
|------|------|------|
| 完整项目（超级流程） | `/reqplan flow full` | 编排器：串联需求→设计→开发→测试→文档 |
| 需求迭代 | `/reqplan flow iteration` | 现有项目的功能迭代 |
| 设计评审 | `/reqplan flow design-review` | 架构设计和接口评审 |
| 代码审计 | `/reqplan flow audit` | 代码质量审查 |
| 测试优化 | `/reqplan flow testing` | 测试策略和用例优化 |
| 文档完善 | `/reqplan flow docs` | 技术文档和用户文档 |
| 架构重构 | `/reqplan flow refactor` | 系统架构优化 |

## 完整命令列表

### 引导与启动

| 命令 | 说明 | 示例 |
|------|------|------|
| `/reqplan start [--flow <name>]` | 启动流程引导 | `/reqplan start --flow full` |
| `/reqplan start --resume` | 恢复上次中断的流程 | `/reqplan start --resume` |
| `/reqplan guide` | 智能引导下一步 | `/reqplan guide` |
| `/reqplan intent <描述>` | 分析需求意图 | `/reqplan intent 我需要一个订单模块` |

### 流程管理

| 命令 | 说明 | 示例 |
|------|------|------|
| `/reqplan flow list` | 列出所有可用流程 | `/reqplan flow list` |
| `/reqplan flow switch <id>` | 切换到指定流程 | `/reqplan flow switch full` |
| `/reqplan flow current` | 查看当前流程 | `/reqplan flow current` |

### 状态查看

| 命令 | 说明 | 示例 |
|------|------|------|
| `/reqplan status` | 查看全局状态 | `/reqplan status` |
| `/reqplan status --detail` | 查看详细状态 | `/reqplan status --detail` |
| `/reqplan history` | 查看流程历史 | `/reqplan history` |
| `/reqplan history --detail` | 查看详细历史（含决策日志） | `/reqplan history --detail` |

### 任务管理

| 命令 | 说明 | 示例 |
|------|------|------|
| `/reqplan task list` | 查看任务列表 | `/reqplan task list` |
| `/reqplan task create` | 创建新任务 | `/reqplan task create` |
| `/reqplan task update <id>` | 更新任务状态 | `/reqplan task update TASK-001` |
| `/reqplan task delete <id>` | 删除任务 | `/reqplan task delete TASK-001` |

### 文档管理

| 命令 | 说明 | 示例 |
|------|------|------|
| `/reqplan docs list` | 查看文档列表 | `/reqplan docs list` |
| `/reqplan docs generate <type>` | 生成指定类型文档 | `/reqplan docs generate req` |
| `/reqplan docs update <path>` | 更新指定文档 | `/reqplan docs update docs/req.md` |

### 验证验收

| 命令 | 说明 | 示例 |
|------|------|------|
| `/reqplan verify [--level <1-5>]` | 执行验证验收 | `/reqplan verify --level 5` |
| `/reqplan sync [--dry-run]` | 文件同步检测 | `/reqplan sync --dry-run` |

### 上下文管理（v3.2 新增）

| 命令 | 说明 | 示例 |
|------|------|------|
| `/reqplan context status` | 查看上下文健康度 | `/reqplan context status` |
| `/reqplan context decisions` | 查看决策日志 | `/reqplan context decisions` |
| `/reqplan context compact` | 手动收敛上下文 | `/reqplan context compact` |
| `/reqplan context snapshot` | 创建上下文快照 | `/reqplan context snapshot` |
| `/reqplan context restore <id>` | 恢复到指定快照 | `/reqplan context restore snap-001` |
| `/reqplan context archive list` | 查看归档记录 | `/reqplan context archive list` |

### 状态锁管理（v3.2 新增）

| 命令 | 说明 | 示例 |
|------|------|------|
| `/reqplan lock status` | 查看锁状态 | `/reqplan lock status` |
| `/reqplan lock acquire` | 获取状态锁 | `/reqplan lock acquire` |
| `/reqplan lock acquire --force` | 强制获取锁 | `/reqplan lock acquire --force` |
| `/reqplan lock release` | 释放状态锁 | `/reqplan lock release` |

### 系统命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `/reqplan init` | 初始化 Harness 目录 | `/reqplan init` |
| `/reqplan status` | 查看全局状态 | `/reqplan status` |
| `/reqplan guide` | 智能引导 | `/reqplan guide` |

## 自然语言触发词

### 意图分析
- "我需要"、"我想要"、"我想"、"添加"、"创建"、"开发"、"做一个"、"新建需求"

### 流程选择
- "开始新项目"、"功能迭代"、"设计评审"、"代码审计"、"测试优化"、"完善文档"、"架构重构"

### 文档管理
- "生成文档"、"创建文档"、"查看文档"、"需求文档"

### 进度查看
- "看看进度"、"当前状态"、"怎么样了"、"进展如何"

### 验收评估
- "验收"、"测试"、"验证"、"完成"

### 引导
- "下一步"、"该做什么"、"引导我"、"继续"

## 状态概览格式（v3.2）

```
📊 当前状态：
├── 项目：订单管理系统
├── 超级流程：完整项目流程（Phase 2/5 — 架构设计）
├── 子流程：设计评审流程（步骤3/7）
├── 里程碑已达成：M1 ✅
├── 进度：40% [████████░░░░]
├── 上下文：健康（1200/4000 tokens）
├── 锁状态：未锁定
└── 全局任务：3个（P0:1, P1:1, P2:1）
```

## 下一步推荐格式（v3.2）

```
📌 下一步推荐：
1️⃣ 继续当前阶段 → "/reqplan guide"（推荐）
2️⃣ 查看子流程状态 → "/reqplan status --detail"
3️⃣ 查看决策日志 → "/reqplan context decisions"
4️⃣ 创建上下文快照 → "/reqplan context snapshot"
5️⃣ 获取状态锁 → "/reqplan lock acquire"
6️⃣ 切换流程 → "/reqplan flow list"
```

## 任务状态

| 状态 | 说明 | 图标 |
|------|------|------|
| TODO | 待开始 | ⏳ |
| IN_PROGRESS | 进行中 | 🔄 |
| DONE | 已完成 | ✅ |
| BLOCKED | 已阻塞 | ⚠️ |

## 全局标志

| 标志 | 说明 | 示例 |
|------|------|------|
| `--help` | 查看帮助 | `/reqplan start --help` |
| `--dry-run` | 预览不执行 | `/reqplan sync --dry-run` |
| `--quiet` | 静默模式 | `/reqplan lock acquire --quiet` |
| `--json` | JSON 格式输出 | `/reqplan status --json` |

## 快速流程：完整项目超级流程

```
1. /reqplan start --flow full       # 启动超级流程
2. /reqplan flow switch iteration   # Phase 1: 需求分析
3. /reqplan flow switch design-review # Phase 2: 架构设计
4. /reqplan flow switch audit       # Phase 3: 开发实现
5. /reqplan flow switch testing     # Phase 4: 测试验证
6. /reqplan flow switch docs        # Phase 5: 文档完善
7. /reqplan verify --level 5        # 最终验收
8. /reqplan status --detail         # 查看完成状态
```

### 需求迭代流程
```
1. /reqplan flow iteration           # 选择需求迭代流程
2. /reqplan intent                   # 分析迭代需求
3. /reqplan docs generate req        # 更新需求文档
4. /reqplan task create              # 创建迭代任务
5. /reqplan task update <ID>         # 执行任务
6. /reqplan verify                   # 验收评估
```

---

**文档版本**: 3.2.0  
**更新时间**: 2026-05-14
