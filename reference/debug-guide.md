# ReqPlan-v3 验证与调试指南

> 本文档是 ReqPlan-v3 Harness 系统的验证与调试辅助手册。

---

## 一、产物契约验证

每个阶段执行完成后，必须验证产物文件的完整性和格式正确性。

### 1.1 验证方法

```powershell
# 检查产物文件是否存在
Test-Path "{项目路径}/.agent/harness/_analysis.md"

# 读取产物文件确认内容
cat "{项目路径}/.agent/harness/_analysis.md" | Select-Object -First 5
```

### 1.2 产物完整性检查模板

| 阶段 | 必需产物 | 验证要点 |
|------|---------|---------|
| ANALYZE | `_analysis.md` | 基本信息完整、问题清单、约束条件 |
| DESIGN | `_design.md` | 技术方案、任务列表、验证方案 |
| IMPLEMENT | `_implementation.md` | 修改摘要、文件清单、测试结果 |
| VERIFY | `_verification.md` | 验证结果、违规清单、判定结论 |

### 1.3 接力棒验证

```powershell
# 读取接力棒
cat "{项目路径}/.agent/harness/_baton.md"
```

检查接力棒的：
- 当前状态与实际执行状态一致
- 产物清单与实际产物一致
- 发现问题摘要与当前阶段匹配

---

## 二、状态机验证

### 2.1 状态转换验证

| 当前状态 | 允许的下一个状态 | 验证方式 |
|---------|----------------|---------|
| START | ANALYZE | 接力棒状态字段 |
| ANALYZE | CONFIRM | 产物 _analysis.md 存在 |
| CONFIRM | DESIGN/ANALYZE/ABORT | 用户响应 |
| DESIGN | IMPLEMENT | 产物 _design.md 存在 |
| IMPLEMENT | VERIFY | 产物 _implementation.md 存在 |
| VERIFY | JUDGE | 产物 _verification.md 存在 |
| JUDGE | DONE/DESIGN/IMPLEMENT/FAILED | 判定结果 |

### 2.2 阻断条件检查

| 阻断条件 | 验证方式 | 失败处理 |
|---------|---------|---------|
| 前置产物缺失 | 读文件确认 | 返回上一阶段 |
| 质量审核不通过 | 读审核报告确认 | 返回修复 |
| 重试超限 | 接力棒重试计数 | 标记 FAILED |

---

## 三、调试方法

### 3.1 Windows 环境调试

```powershell
# 检查目录是否存在
Test-Path ".agent/harness/"

# 如果不存在，创建目录
mkdir -Force ".agent/harness/"

# 列出所有产物
Get-ChildItem ".agent/harness/" | Select-Object Name, LastWriteTime
```

### 3.2 产物写入验证

```powershell
# 写入产物后立即验证
# 例如：验证 _analysis.md 是否写入成功
$content = cat "{项目路径}/.agent/harness/_analysis.md"
if ($content.Length -gt 0) {
    Write-Output "写入成功，文件大小：$($content.Length) 字符"
} else {
    Write-Output "写入失败或文件为空"
}
```

---

## 四、常见问题处理

### 4.1 接力棒丢失或损坏

```powershell
# 重建接力棒
if (-not (Test-Path "{项目路径}/.agent/harness/_baton.md")) {
    mkdir -Force "{项目路径}/.agent/harness/"
    # 写入新的接力棒文件，从 START 开始
}
```

### 4.2 产物被意外覆盖

- 立即回滚：从历史记录恢复（需启用版本控制）
- 未启用版本控制时：重新从当前阶段生成产物

### 4.3 Windows vs Unix 命令差异

| 操作 | Unix 命令 | Windows PowerShell |
|------|----------|-------------------|
| 创建目录 | `mkdir -p` | `mkdir -Force` |
| 读文件 | `cat` | `cat` 或 `Get-Content` |
| 写文件 | `echo >` | `Set-Content` |
| 路径分隔符 | `/` | `\`（支持 /） |

### 4.4 质量审核不通过

1. 读取审核报告：`cat "{项目路径}/.agent/harness/_quality_audit_{phase}.md"`
2. 定位"待修复问题清单"
3. 逐条修复
4. 重审（新报告文件命名：`_quality_audit_{phase}_v2.md`）

---

## 五、版本说明

本文档跟随 ReqPlan-v3 主版本。当前对应版本见 SKILL.md 版本信息。

---

*本文档是 ReqPlan-v3 Harness 系统的调试辅助手册*