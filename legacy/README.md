# legacy — v3.3 历史归档

> 本目录包含 ReqPlan-v3 **v3.3 版本**的历史文件，在 **v4.1 目录结构整合**过程中移至此处。
> 保留这些文件仅用于历史参考，**不会**被 v4.1 的 SKILL 入口加载。

---

## 归档内容

| 子目录 | 文件 | 说明 |
|--------|------|------|
| `3-core/` | 11 个 core-*.md 文件 | v3.3 核心模块，v4.1 已重构为 agents/ + protocols/ + SKILL.md |
| `5-templates/` | template-*.md 文件（5个） | v3.3 分散模板，v4.1 已统一为 artifacts/template-artifacts.md |
| `6-docs/` | adoption-guide.md, troubleshooting.md | v3.3 文档，v4.1 参考内容已整合 |
| `7-flows/` | 5 个 flow-*.md 文件 | v3.3 独立流程定义，v4.1 已整合至 SKILL.chunks/chunk-02-flows.md |
| `artifacts/` | manifest-template.md | v3.3 5合1清单模板，v4.1 已废弃该模式 |
| `scripts/` | 6 个 .ps1 校验脚本 | v3.3 校验脚本，v4.x 已改用 run-checks/validate-baton/validate-artifact 三个核心脚本 |

---

## 保留并沿用到 v4.1 的内容

以下文件/目录在 v4.1 中**保留并使用**，未移入 legacy：

| 路径 | 说明 |
|------|------|
| `agents/` | 4 个 Agent 定义（analyzer / designer / implementer / verifier） |
| `protocols/` | 协议定义（baton-protocol.md / phase-protocol.md） |
| `artifacts/` | 产物模板唯一来源（template-artifacts.md） |
| `SKILL.chunks/` | 分块加载（chunk-index.yaml + 4 个 chunk） |
| `scripts/harness/` | 校验脚本（9 个 PowerShell 脚本） |
| `reference/` | 参考文档（debug-guide.md） |
| `SKILL.md` | 技能入口（v4.1 精简版，~183行） |
| `SKILL-execution.md` | 核心执行指南（v4.1） |
| `README.md` | 项目说明（v4.1） |
| `6-docs/changelog.md` | 版本日志 |

---

## v4.1 关键变更

- **产物模式**：保持独立文件模式（_analysis.md / _design.md / _implementation.md / _verification.md），废弃 5合1 的 _manifest.md 模式
- **产物模板统一**：多个分散模板合并为 `artifacts/template-artifacts.md`（唯一源）
- **目录扁平化**：消除 v3.3/v4.1 冗余嵌套
- **分块加载**：新增 `SKILL.chunks/`，按需激活不同功能块
- **路径统一**：运行时状态统一使用 `.agent/harness/`，长期归档使用 `docs/harness/`，两套路径互补
- **SKILL.md 精简**：从 543 行精简到 ~183 行，详细内容委托至 SKILL-execution.md 和 chunks