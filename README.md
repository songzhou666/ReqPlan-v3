# ReqPlan v3.3 — 项目全生命周期管理引擎

ReqPlan 是一个面向 TRAE Agent 的项目全生命周期管理引擎，基于 **Harness Engineering** 理念设计。它将项目开发从"靠提示词自由发挥"升级为"有规范、可验证、可追溯"的结构化流程。

---

## 适用场景

| 场景 | 说明 |
|------|------|
| 新项目启动 | 从零开始，需求→设计→开发→测试→文档全流程 |
| 需求迭代 | 已有项目的功能增量开发和维护 |
| 设计评审 | 架构设计、接口定义、数据库设计的评审 |
| 代码审计 | 代码质量、安全性、性能的全面审查 |
| 测试优化 | 测试策略制定、用例设计、覆盖提升 |
| 文档完善 | 技术文档、API 文档、架构说明的补充 |
| 架构重构 | 模块重构、性能优化、技术债务清理 |

---

## 核心能力

### Harness Engineering 五大支柱

| 支柱 | 说明 | 对应文件 |
|------|------|---------|
| 信息落点 | 定义项目内信息的固定位置，Agent 和工程师沿同一套路径找依据 | `AGENTS.md`, `.agent/`, `docs/harness/` |
| 计划协议 | 复杂任务必须有范围冻结（Scope / Non-Goals / Validation / Rollback） | [template-plan.md](5-templates/template-plan.md) |
| 5 层验证 | Static → Unit → Integration → Failure → Writeback 分层验收 | [core-verification.md](3-core/core-verification.md) |
| 结果回写 | 每次任务完成后将核心信息回写到标准位置 | [schema-writeback.md](4-schemas/schema-writeback.md) |
| 可执行校验 | 将人工提醒的规则转化为自动检查脚本 | [scripts/harness/](scripts/harness/) |

### 智能流程管理

- **7 个预定义流程**：覆盖项目全生命周期各阶段
- **超级流程编排**：通过 `flow-full` 串联 6 个子流程，支持多轮迭代
- **双轨触发**：支持命令触发（`/reqplan flow <name>`）和自然语言触发
- **上下文感知**：自动追踪会话状态，支持中断恢复和上下文收敛

### 状态与并发控制

- **状态锁机制**：防止多会话并发修改导致状态冲突
- **上下文追踪**：TTL 管理、快照备份、跨会话恢复
- **决策日志**：记录关键决策，支持回溯和约束提取

### 产出物自动校验（v3.3 新增）

每个核心 Action 执行完毕后，可运行对应脚本自动验证产出物完整性：

| Action | 校验脚本 |
|--------|---------|
| 意图分析完成 | `validate-intent-analysis.ps1` |
| 验证评估完成 | `validate-verification.ps1` |
| 审核评估完成 | `verify-review-gate.ps1` |
| 任务收口前 | `run-checks.ps1`（全量检查） |

---

## 快速开始

在 TRAE 对话中直接输入：

```
/reqplan start     # 启动引导，选择流程
/reqplan init      # 初始化项目 Harness 目录结构
```

**三步上手**：

1. **初始化**：运行 `/reqplan init`，自动创建 `AGENTS.md`、`.agent/`、`docs/harness/` 等目录
2. **填写入口**：在 `AGENTS.md` 中填入项目名称、技术栈、验证命令
3. **开始任务**：输入 `/reqplan start` 选择流程，或直接用自然语言描述需求

渐进式落地手册请参考 [adoption-guide.md](6-docs/adoption-guide.md)。

---

## 目录结构

```
ReqPlan-v3/
├── SKILL.md                  # 技能入口（TRAE 加载点）
├── README.md                 # 本文件
├── 3-core/                   # 16 个核心模块
│   ├── core-actions.md       # Action 接口规范（14 个 Action）
│   ├── core-error-handling.md# 错误码体系（E001-E999）
│   ├── core-task-pipeline.md # 5 阶段任务管道
│   ├── core-harness-selector.md # S/L/M/H 级别选择器
│   └── ...                   # 上下文追踪、意图分析、验证等
├── 4-schemas/                # 7 个 Schema 定义
├── 5-templates/              # 5 个文档模板
│   ├── template-req.md       # 需求文档模板
│   ├── template-design.md    # 设计文档模板
│   ├── template-plan.md      # 计划协议模板
│   ├── template-agents.md    # AGENTS.md 模板
│   └── template-control-plane.md # 控制面文档模板
├── 6-docs/                   # 辅助文档
│   ├── adoption-guide.md     # 渐进式落地指南
│   ├── quick-reference.md    # 命令速查
│   ├── changelog.md          # 变更日志
│   └── troubleshooting.md    # 故障排查
├── 7-flows/                  # 7 个流程定义
│   ├── flow-full.md          # 超级流程编排器
│   └── flow-*.md             # 6 个子流程
└── scripts/harness/          # 可执行校验脚本
    ├── run-checks.ps1        # 全量检查编排器
    ├── check-structure.ps1   # 目录结构检查
    ├── check-plan.ps1        # 计划文件检查
    ├── validate-*.ps1        # 产出物校验脚本
    └── verify-review-gate.ps1# 评审门禁检查
```

---

## 命令速览

```
/reqplan start              # 启动引导
/reqplan init               # 初始化 Harness 目录
/reqplan flow <name>        # 切换流程
/reqplan plan               # 制定计划（含范围冻结）
/reqplan verify             # 执行分层验证
/reqplan status             # 查看全局状态
/reqplan guide              # 智能引导下一步
/reqplan sync               # 文件同步
/reqplan context decisions  # 查看决策日志
/reqplan lock acquire       # 获取状态锁
```

完整命令列表请参考 [quick-reference.md](6-docs/quick-reference.md)。

---

## 设计理念

ReqPlan 遵循 **Harness Engineering** 理念：

1. **信息落点** — 每类信息有且只有一个标准位置，Agent 和人都能找到
2. **计划协议** — 复杂任务启动前先约定范围（Scope）、不做清单（Non-Goals）、验收标准（Validation）、回滚策略（Rollback）
3. **5 层验证** — 不在最后一刻才验证，每个阶段做对应层次的检查
4. **可执行检查** — 不依赖"记住规则"，把规则写成可重复运行的脚本
5. **结果回写** — 每次闭环都把产出物放到标准位置，下次可复用

---

## 版本历史

| 版本 | 亮点 |
|------|------|
| v3.3 | 产出物校验脚本、重复错误检测、前端三段式路径（**当前版本**） |
| v3.2 | Action 接口规范、Harness 级别选择器、超级流程编排、上下文追踪、状态锁 |
| v3.1 | 信息落点体系、智能引导 2.0 |
| v3.0 | 初始版本，7 个核心流程 + 双轨触发 |

---

**版本**: v3.3  
**作者**: songzhou  
**更新日期**: 2026-05-14  
**基于**: Harness Engineering 理念 + TRAE Skill 编写规范
