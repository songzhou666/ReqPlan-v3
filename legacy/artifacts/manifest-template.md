# ReqPlan-v3 项目执行清单模板

> 本模板用于统一记录 ReqPlan 执行周期的所有阶段产物。
> 执行过程中，每个阶段结束后将内容追加到 `{项目路径}/.agent/harness/_manifest.md`。
> **核心规则**：全生命周期只写一个文件，不拆分多个独立产物文件。

---

```markdown
# ReqPlan-v3 项目执行清单

## 元信息
- 项目: {项目名称}
- 开始时间: {ISO 8601}
- 最后更新: {ISO 8601}
- 当前状态: {START/ANALYZE/CONFIRM/DESIGN/IMPLEMENT/VERIFY/JUDGE/DONE/ABORT/FAILED}
- 模式: {NORMAL/DESIGN_FIX/REVIEW_FIX/RETRY_FIX}
- 重试计数: {0/1/2}
- 阶段进度: {0}%

## 阶段记录

### 🔵 START
- **时间**: {ISO 8601}
- **任务**: {用户需求描述}
- **产物**: — (无)

---

### 🟡 ANALYZE
- **时间**: {ISO 8601}
- **状态**: ⏳ 待开始 / 🔄 进行中 / ✅ 已完成

<details>
<summary>📋 分析内容</summary>

{分析报告完整内容}

</details>

---

### 🟠 CONFIRM
- **时间**: {ISO 8601}
- **状态**: ⏳ 待开始 / 🔄 进行中 / ✅ 已完成

<details>
<summary>💬 确认记录</summary>

{用户确认内容}

</details>

---

### 🟢 DESIGN
- **时间**: {ISO 8601}
- **状态**: ⏳ 待开始 / 🔄 进行中 / ✅ 已完成

<details>
<summary>📐 设计方案</summary>

{技术设计方案内容}

</details>

---

### 🔵 IMPLEMENT
- **时间**: {ISO 8601}
- **状态**: ⏳ 待开始 / 🔄 进行中 / ✅ 已完成

<details>
<summary>🛠️ 实现摘要</summary>

{实现摘要内容}

</details>

---

### 🟣 VERIFY
- **时间**: {ISO 8601}
- **状态**: ⏳ 待开始 / 🔄 进行中 / ✅ 已完成

<details>
<summary>✅ 验证报告</summary>

{验证报告内容}

</details>

---

### ⚪ JUDGE
- **时间**: {ISO 8601}
- **判定**: ⏳ 待判定 / ✅ PASS / ❌ FAIL

<details>
<summary>🏁 最终判定</summary>

{判定结果}

</details>
```

## 使用说明

1. **初始化**：REQPLAN 启动时，创建 `{项目}/.agent/harness/_manifest.md`，写入元信息和 START 章节
2. **追加**：每个阶段完成后，追加对应章节到文件末尾
3. **折叠**：使用 `<details>` 标签折叠详细内容，保持文档概览清晰
4. **更新元信息**：每次追加时同时更新顶部的「元信息」和「阶段进度」
5. **不拆分**：不创建 `_analysis.md` / `_design.md` 等独立文件

## 章节结构说明

| 章节 | 何时写入 | 应包含内容 |
|------|----------|-----------|
| START | 流程启动时 | 用户需求、项目信息 |
| ANALYZE | 分析阶段完成 | 需求分析、技术栈、文件清单 |
| CONFIRM | 用户确认时 | 用户反馈、确认/修改记录 |
| DESIGN | 设计阶段完成 | 技术方案、模块划分、任务列表 |
| IMPLEMENT | 实现阶段完成 | 完成的任务、涉及的文件、问题记录 |
| VERIFY | 验证阶段完成 | 5层验证结果、判定 |
| JUDGE | 流程结束时 | 最终 PASS/FAIL 判定、完成报告 |

---

> ⚠️ 此文件已废弃（v4.1）。决策：保留独立文件模式（_analysis.md, _design.md 等），5合1的 _manifest.md 模式与渐进式加载、检查点验证等核心机制冲突。
> 仅保留作为历史参考。

*本文档是 ReqPlan-v3 产物模板的唯一来源*
*版本: 4.1*
*时间: {ISO 8601}*