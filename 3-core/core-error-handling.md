# Core Error Handling
# 错误处理核心模块

## 概述

错误处理模块定义了ReqPlan的统一错误码体系和错误响应格式，提供清晰的错误信息和恢复策略。

## 错误码体系

### 错误码分类

| 类别 | 错误码范围 | 说明 |
|------|-----------|------|
| 意图分析 | E001-E099 | 需求分析相关错误 |
| 文档生成 | E101-E199 | 文档生成相关错误 |
| 任务管理 | E201-E299 | 任务管理相关错误 |
| 审核建议 | E301-E399 | 代码审核相关错误 |
| 验收评估 | E401-E499 | 验收测试相关错误 |
| 验证错误 | E501-E599 | 验证执行相关错误 |
| 文件操作 | E601-E699 | 文件读写相关错误 |
| 状态管理 | E701-E799 | 状态管理相关错误 |
| 流程引擎 | E801-E899 | 流程引擎相关错误 |
| 系统错误 | E901-E999 | 系统级错误 |

### 错误码详细定义

#### E001-E099 - 意图分析错误

```yaml
E001:
  code: "E001"
  category: "intent-analysis"
  level: "warning"
  title: "信息不足"
  message: "请补充以下信息：{missingFields}"
  recovery:
    - "提供明确的选项让用户选择"
    - "列出需要补充的字段"

E002:
  code: "E002"
  category: "intent-analysis"
  level: "warning"
  title: "需求模糊"
  message: "我理解您需要{requirement}，但需要澄清以下几点：{clarifications}"
  recovery:
    - "列出需要澄清的问题"
    - "提供示例帮助用户理解"

E003:
  code: "E003"
  category: "intent-analysis"
  level: "error"
  title: "分析失败"
  message: "无法分析需求，请重试"
  recovery:
    - "建议用户重新描述需求"
    - "提供需求描述示例"
```

#### E101-E199 - 文档生成错误

```yaml
E101:
  code: "E101"
  category: "doc-generation"
  level: "warning"
  title: "模板不存在"
  message: "模板文件不存在：{templatePath}"
  recovery:
    - "使用默认Markdown格式生成"
    - "记录警告日志"

E102:
  code: "E102"
  category: "doc-generation"
  level: "warning"
  title: "内容不完整"
  message: "缺少以下必填信息：{missingFields}"
  recovery:
    - "列出需要补充的字段"
    - "提供默认值选项"

E103:
  code: "E103"
  category: "doc-generation"
  level: "error"
  title: "生成失败"
  message: "文档生成失败：{error}"
  recovery:
    - "检查模板文件"
    - "检查输入数据"
    - "重试生成操作"
```

#### E201-E299 - 任务管理错误

```yaml
E201:
  code: "E201"
  category: "task-management"
  level: "warning"
  title: "项目不存在"
  message: "项目不存在：{projectId}"
  recovery:
    - "询问用户是否创建新项目"
    - "提供创建项目的流程"

E202:
  code: "E202"
  category: "task-management"
  level: "warning"
  title: "任务不存在"
  message: "未找到任务：{taskId}"
  recovery:
    - "列出当前所有任务"
    - "确认任务ID是否正确"

E203:
  code: "E203"
  category: "task-management"
  level: "warning"
  title: "任务状态无效"
  message: "无效的任务状态：{status}"
  recovery:
    - "列出有效的任务状态"
    - "自动纠正为最接近的有效状态"

E204:
  code: "E204"
  category: "task-management"
  level: "error"
  title: "任务依赖错误"
  message: "任务依赖关系错误：{dependencyError}"
  recovery:
    - "检查依赖任务是否存在"
    - "解决循环依赖问题"
```

#### E301-E399 - 审核建议错误

```yaml
E301:
  code: "E301"
  category: "review"
  level: "warning"
  title: "审核目标无效"
  message: "无效的审核目标：{target}"
  recovery:
    - "列出有效的审核目标类型"
    - "提示正确的使用方法"

E302:
  code: "E302"
  category: "review"
  level: "error"
  title: "审核失败"
  message: "审核过程发生错误：{error}"
  recovery:
    - "检查输入内容"
    - "重试审核操作"
```

#### E401-E499 - 验收评估错误

```yaml
E401:
  code: "E401"
  category: "verification"
  level: "warning"
  title: "验收任务不存在"
  message: "未找到待验收任务：{taskId}"
  recovery:
    - "列出可验收的任务"
    - "确认任务ID是否正确"

E402:
  code: "E402"
  category: "verification"
  level: "error"
  title: "验收失败"
  message: "验收过程发生错误：{error}"
  recovery:
    - "检查测试用例"
    - "检查验收标准"
    - "重试验收操作"
```

#### E501-E599 - 验证错误

```yaml
E501:
  code: "E501"
  category: "verification"
  level: "warning"
  title: "验证命令未找到"
  message: "未找到验证命令：{command}"
  recovery:
    - "检查项目文档（AGENTS.md）中的验证命令配置"
    - "确认相关依赖已安装"
    - "手动指定验证方式"

E502:
  code: "E502"
  category: "verification"
  level: "warning"
  title: "验证层级前置条件不满足"
  message: "当前验证层级的前置条件不满足：Layer {layerNumber}"
  recovery:
    - "从 Layer 1 开始逐层执行验证"
    - "确认前置验证已通过"
```

#### E601-E699 - 文件操作错误

```yaml
E601:
  code: "E601"
  category: "file-operations"
  level: "warning"
  title: "文件不存在"
  message: "无法找到指定的文件：{filePath}"
  recovery:
    - "检查文件路径是否正确"
    - "确认项目已初始化"
    - "确认需求已创建"

E602:
  code: "E602"
  category: "file-operations"
  level: "error"
  title: "文件写入失败"
  message: "无法写入文件：{filePath}"
  recovery:
    - "检查磁盘空间是否充足"
    - "检查文件权限"
    - "检查目录是否可写"

E603:
  code: "E603"
  category: "file-operations"
  level: "error"
  title: "权限不足"
  message: "没有足够的权限操作文件：{filePath}"
  recovery:
    - "检查文件权限设置"
    - "以管理员身份运行"
    - "检查目录权限"

E604:
  code: "E604"
  category: "file-operations"
  level: "error"
  title: "目录创建失败"
  message: "无法创建目录：{dirPath}"
  recovery:
    - "检查父目录权限"
    - "检查磁盘空间"
    - "确认路径有效"
```

#### E701-E799 - 状态管理错误

```yaml
E701:
  code: "E701"
  category: "state-management"
  level: "error"
  title: "状态文件损坏"
  message: "检测到状态文件损坏，正在尝试恢复..."
  recovery:
    - "尝试从备份文件恢复"
    - "如果备份也损坏，询问用户是否重新初始化"
    - "提供手动恢复选项"

E702:
  code: "E702"
  category: "state-management"
  level: "warning"
  title: "项目未初始化"
  message: "项目尚未初始化，请先创建项目"
  recovery:
    - "提示用户使用 /reqplan start 创建新项目"
    - "提供创建项目的流程"

E703:
  code: "E703"
  category: "state-management"
  level: "info"
  title: "上下文已过期"
  message: "您的会话已过期，请重新选择需求"
  recovery:
    - "列出最近的需求供用户选择"
    - "提供创建新需求的选项"

E704:
  code: "E704"
  category: "state-management"
  level: "error"
  title: "状态版本不兼容"
  message: "状态文件版本与当前版本不兼容"
  recovery:
    - "尝试自动升级状态文件"
    - "如果升级失败，提示手动迁移"

#### E801-E899 - 流程引擎错误

```yaml
E801:
  code: "E801"
  category: "workflow-engine"
  level: "warning"
  title: "流程切换失败"
  message: "无法切换到指定流程：{flowName}"
  recovery:
    - "检查流程名称是否正确"
    - "使用 /reqplan flow list 查看可用流程"
    - "确认当前状态是否支持该流程切换"

E802:
  code: "E802"
  category: "workflow-engine"
  level: "warning"
  title: "文件检测失败"
  message: "文件变更检测失败：{error}"
  recovery:
    - "使用 /reqplan sync 手动触发同步检测"
    - "检查文件路径是否正确"
    - "确认文件是否可读"

E803:
  code: "E803"
  category: "workflow-engine"
  level: "warning"
  title: "流程上下文异常"
  message: "流程上下文状态不正确或丢失"
  recovery:
    - "使用 /reqplan context 查看上下文详情"
    - "使用 /reqplan flow current 确认当前流程"
    - "访问 flow_history 检查流程记录"

E804:
  code: "E804"
  category: "workflow-engine"
  level: "error"
  title: "流程步骤错误"
  message: "流程步骤顺序异常：{stepError}"
  recovery:
    - "检查步骤顺序是否正确"
    - "查看流程历史了解当前位置"
    - "按阶段门控要求重试"

E805:
  code: "E805"
  category: "workflow-engine"
  level: "error"
  title: "流程规则冲突"
  message: "检测到流程规则冲突：{conflictDetail}"
  recovery:
    - "显示冲突的规则内容"
    - "建议用户选择优先规则"
    - "记录冲突解决结果到 decision_log"
```

## 标准错误响应格式

### 统一响应结构

```yaml
error:
  code: string              # 错误码
  category: string          # 错误类别
  level: string             # 错误级别：info | warning | error
  title: string            # 错误标题
  message: string          # 错误消息
  details?: object         # 详细信息
  recovery: string[]       # 恢复建议
  timestamp: string        # 时间戳
```

## 错误处理流程

### 错误捕获

```
1. 操作执行
2. 捕获异常
3. 转换为标准错误格式
4. 记录错误日志
5. 返回错误响应
```

## 错误日志规范

### 日志格式

```yaml
log_entry:
  timestamp: string        # 时间戳
  level: string           # 日志级别
  code: string           # 错误码
  message: string        # 错误消息
  stack_trace?: string   # 堆栈跟踪（可选）
  context: object        # 上下文信息
    - projectId: string
    - userId: string
    - action: string
    - params: object
```

## 最佳实践

1. **错误码统一**：使用统一的错误码体系
2. **信息清晰**：错误消息简洁明了
3. **恢复建议**：提供可操作的恢复建议
4. **日志记录**：记录详细的错误日志
5. **用户友好**：错误信息对用户友好
6. **错误分级**：根据严重程度分级处理

## 版本信息

**版本**: 3.2.0
**更新时间**: 2026-05-14
