# ReqPlan-v3 (v4.2) — Harness Engineering + 接力棒持久化

> 基于 Harness Engineering 理念 + 接力棒持久化机制的项目全生命周期管理引擎

---

## 核心特色

### 🎯 融合设计

- **Harness Engineering**：多 Agent 协作（Analyzer → Designer → Implementer → Verifier）
- **接力棒持久化**：跨 Session 续跑，状态持久化
- **5 层验证体系**：Static → Unit → Integration → Failure → Compliance
- **产物契约**：Agent 间通过文件传递，不靠记忆

### 🔄 接力棒机制

```bash
{项目路径}/.agent/harness/_baton.md
```

接力棒文件记录：
- 当前状态
- 进度追踪
- 产物清单
- 问题记录
- 下一步行动

**核心价值**：任何时候都能续跑，不需要重新开始！

---

## 快速开始

### 1. 首次使用

```bash
# 激活 Skill
/reqplan start     # 启动引导，选择流程
/reqplan init      # 初始化项目 Harness 目录
```

### 2. 续跑（中断后继续）

```bash
# 自动读取接力棒，恢复进度
/reqplan start
```

---

## 7个核心流程

| # | 流程 | 适用场景 |
|---|------|----------|
| 1 | 完整项目流程 | 新项目启动，从需求到验收 |
| 2 | 需求迭代流程 | 已有项目的需求更新和迭代 |
| 3 | 设计评审流程 | 架构设计、接口定义、数据库设计 |
| 4 | 代码开发流程 | 代码实现、Bug 修复、功能开发 |
| 5 | 测试优化流程 | 测试策略制定、用例设计、覆盖提升 |
| 6 | 文档完善流程 | 技术文档、API 文档的补充 |
| 7 | 架构重构流程 | 架构优化、技术债务清理 |

---

## 多 Agent 协作

```
┌──────────────────────────────────────────────────────────────┐
│                     REQPLAN HARNESS                          │
│                                                              │
│  ┌─────────────┐                                             │
│  │  总控(我)    │ ← 状态机 + 调度 + 判断                      │
│  └──────┬──────┘                                             │
│         │ 调度                                               │
│    ┌────┴────┬────────────┬─────────────┐                   │
│    ▼         ▼            ▼             ▼                    │
│ ┌──────┐ ┌──────┐    ┌──────┐     ┌──────┐                  │
│ │分析Agent│ │设计Agent│  │实现Agent│   │验证Agent│                  │
│ │ explorer│ │ worker │    │ worker │    │ worker │                  │
│ └──────┘ └──────┘    └──────┘     └──────┘                  │
│     ↓         ↓           ↓             ↓                    │
│ _analysis _design   源码变更   _verification               │
│    .md       .md       文件        .md                         │
└──────────────────────────────────────────────────────────────┘
```

---

## 状态机

```
START → ANALYZE → CONFIRM → DESIGN → IMPLEMENT → VERIFY → JUDGE
                                      ↓
                  ┌────────────────────┼────────────────────┐
                  ↓                    ↓                    ↓
               ✅ DONE              🔧 DESIGN             🔄 IMPLEMENT
                                    (修复模式)           (重试模式)
```

---

## 产物结构

```
{项目路径}/
└── .agent/
    └── harness/
        ├── _baton.md          # 接力棒
        ├── _analysis.md       # 分析产物
        ├── _design.md         # 设计产物
        ├── _implementation.md # 实现摘要
        └── _verification.md   # 验证产物
```

---

## 5 层验证体系

| 层级 | 验证内容 | 工具 |
|------|----------|------|
| Layer 1 | 静态检查 | pylint, ruff, mypy |
| Layer 2 | 单元测试 | pytest |
| Layer 3 | 构建集成 | python -m py_compile |
| Layer 4 | 异常处理 | 边界测试 |
| Layer 5 | 流程合规 | 产物完整性 |

---

## 目录结构

```
ReqPlan-v3/
├── SKILL.md                  # 技能入口
├── SKILL-execution.md        # 核心执行指南
├── README.md                 # 本文件
├── agents/                   # Agent 定义
│   ├── analyzer-agent.md     # 分析 Agent
│   ├── designer-agent.md     # 设计 Agent
│   ├── implementer-agent.md  # 实现 Agent
│   └── verifier-agent.md     # 验证 Agent
├── protocols/                # 协议文档
│   ├── baton-protocol.md     # 接力棒协议
│   └── phase-protocol.md     # 阶段执行规范
├── artifacts/                # 产物模板（唯一来源）
│   └── template-artifacts.md # 产物模板集合
├── SKILL.chunks/             # 分块加载（按需激活）
├── legacy/                   # v3.3 历史归档
├── scripts/harness/          # 校验脚本
├── reference/                # 参考文档
└── 6-docs/changelog.md       # 版本日志
```

---

## 设计理念

### Harness Engineering

1. **角色边界** — 每个 Agent 只做一件事
2. **状态机** — 定义流程走向，防止跳步
3. **产物契约** — Agent 间用文件传递，不靠记忆
4. **护栏规则** — 明确禁止清单，防止越权

### 接力棒持久化

1. **跨 Session 续跑** — 任何时候都能继续之前的工作
2. **状态可视化** — 一目了然当前进度
3. **问题记录** — 遇到的问题不会丢失
4. **上下文恢复** — 自动恢复完整上下文

---

## 版本信息

**版本**: v4.2 (路径统一版)
**更新日期**: 2026-05-21

**融合内容**：
- ReqPlan-v3 原始仓库 (v3.3) 的 7 个核心流程
- Harness Engineering 多 Agent 协作
- 接力棒持久化机制
- 5 层验证体系
- 独立文件产物模式（_analysis.md / _design.md / _implementation.md / _verification.md）

**最新变更 (v4.2, 2026-05-21)**：
- 三套路径体系统一为 `.agent/harness/`（运行时）+ `docs/harness/`（归档）
- SKILL.md 从 543 行精简至 ~183 行
- 删除重复状态路由表，清理 3 个空壳占位文件
- 修正 legacy/README 矛盾描述，清理 debug-guide 过时引用
- 标注 PowerShell 脚本兼容性，补充 /reqplan guide 命令行为定义

**v4.1 变更 (2026-05-21)**：
- 废弃 _manifest.md 5合1模式，保留独立文件产物模式
- 清理 3-core / 4-schemas / 5-templates / 7-flows 无效占位文件
- 统一版本号至 v4.1

**基于**：
- ReqPlan-v3 原始仓库
- testerhome Harness 设计模式
- OpenAI Harness Engineering 文章

---

## 参考资料

- [ReqPlan-v3 GitHub](https://github.com/songzhou666/ReqPlan-v3)
- [Harness Engineering 文章](https://mp.weixin.qq.com/s/AFX_qsyAPBRYyqEV365O9Q)
- [testerhome Harness 设计](https://testerhome.com/articles/44066)

---

**作者**: songzhou
**维护**: 持续更新中
