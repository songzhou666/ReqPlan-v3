# Core File IO
# 文件 IO 核心模块

## 概述

文件操作模块负责管理ReqPlan的文件读写操作，包括标准路径规范、原子性写入、目录自动创建等功能。

## Input

```yaml
- action: string              # 操作类型：read | write | update | delete | exists | list
- filePath: string           # 文件路径（必填）
- content?: string           # 文件内容（write/update时必填）
- options?: object           # 选项参数（可选）
```

### action类型说明

| action | 说明 | 参数要求 |
|------|------|----------|
| read | 读取文件内容 | filePath |
| write | 写入文件（覆盖） | filePath, content |
| update | 更新文件内容 | filePath, content |
| delete | 删除文件 | filePath |
| exists | 检查文件是否存在 | filePath |
| list | 列出目录内容 | filePath（目录路径） |

### options说明

```yaml
options:
  encoding: string           # 编码格式，默认utf-8
  atomic: boolean           # 是否原子性写入，默认true
  createDir: boolean        # 是否自动创建目录，默认true
  backup: boolean          # 是否创建备份，默认true
  backupSuffix: string      # 备份文件后缀，默认".backup"
```

## Output

```yaml
- success: boolean           # 操作是否成功
- filePath: string          # 文件路径
- content?: string          # 文件内容（read时返回）
- files?: string[]          # 文件列表（list时返回）
- exists?: boolean          # 文件是否存在（exists时返回）
- message: string          # 操作结果消息
- timestamp: string        # 操作时间戳
```

## 标准路径规范

### 项目根目录

```
.trae/reqplan/
├── config.yaml             # 全局配置
├── index.yaml              # 项目索引
└── projects/
    └── <projectId>/        # 项目目录
```

### 项目目录结构

```
.trae/reqplan/projects/<projectId>/
├── config.yaml             # 项目配置
├── state.yaml              # 当前状态
├── state.backup.yaml       # 状态备份
├── snapshots/             # 快照目录
│   └── snapshot-<timestamp>.yaml
└── requirements/          # 需求目录
    └── <reqId>/           # 需求目录
        ├── intent.md      # 意图分析文档
        ├── req.md         # 需求规格文档
        ├── design.md      # 设计文档
        ├── plan.md        # 开发计划文档
        └── verification/  # 验收评估目录
            ├── testcases.md
            ├── report.md
            └── issues.md
```

## 原子性写入策略

### 写入流程

```
1. 检查目标目录是否存在，不存在则创建
2. 如果启用备份，先备份原文件
3. 写入临时文件（.tmp后缀）
4. 验证临时文件内容
5. 重命名临时文件为目标文件
6. 如果失败，恢复备份文件
```

## 目录自动创建机制

### 创建规则

1. 当写入文件时，如果父目录不存在，自动创建
2. 创建目录时，同时创建必要的中间目录
3. 设置合适的目录权限

## 文件操作方法

### 读取文件

```yaml
action: "read"
filePath: ".trae/reqplan/projects/my-project/state.yaml"

Output:
- success: true
- content: "project: my-project\n..."
- message: "文件读取成功"
```

### 写入文件

```yaml
action: "write"
filePath: ".trae/reqplan/projects/my-project/requirements/REQ-001/intent.md"
content: "# 意图分析\n\n## 功能点\n..."
options:
  atomic: true
  createDir: true

Output:
- success: true
- filePath: ".trae/reqplan/projects/my-project/requirements/REQ-001/intent.md"
- message: "文件写入成功"
```

### 更新文件

```yaml
action: "update"
filePath: ".trae/reqplan/projects/my-project/state.yaml"
content: "\nprogress:\n  overall: 60\n"
options:
  append: true  # 追加模式

Output:
- success: true
- message: "文件更新成功"
```

### 删除文件

```yaml
action: "delete"
filePath: ".trae/reqplan/projects/my-project/requirements/REQ-001/intent.md"

Output:
- success: true
- message: "文件删除成功"
```

### 检查文件存在

```yaml
action: "exists"
filePath: ".trae/reqplan/projects/my-project/state.yaml"

Output:
- success: true
- exists: true
- message: "文件存在"
```

### 列出目录内容

```yaml
action: "list"
filePath: ".trae/reqplan/projects/my-project/requirements"

Output:
- success: true
- files:
  - "REQ-001/"
  - "REQ-002/"
  - "REQ-003/"
- message: "目录列表获取成功"
```

## 失败策略

### E601 - 文件不存在

```yaml
E601:
  error: "文件不存在"
  message: "无法找到指定的文件：{filePath}"
  recovery:
    - 检查文件路径是否正确
    - 确认项目已初始化
    - 确认需求已创建
```

### E602 - 文件写入失败

```yaml
E602:
  error: "文件写入失败"
  message: "无法写入文件：{filePath}"
  recovery:
    - 检查磁盘空间是否充足
    - 检查文件权限
    - 检查目录是否可写
```

### E603 - 权限不足

```yaml
E603:
  error: "权限不足"
  message: "没有足够的权限操作文件：{filePath}"
  recovery:
    - 检查文件权限设置
    - 以管理员身份运行
    - 检查目录权限
```

### E604 - 目录创建失败

```yaml
E604:
  error: "目录创建失败"
  message: "无法创建目录：{dirPath}"
  recovery:
    - 检查父目录权限
    - 检查磁盘空间
    - 确认路径有效
```

## Harness 初始化支持

### 概述

ReqPlan v3.1 新增 Harness 目录初始化能力。当执行 `/reqplan init` 时，在项目根目录生成标准 Harness 结构。

### 初始化动作

```yaml
action: "harness_init"
projectPath: string         # 项目根目录路径（必填）
techStack: object           # 技术栈信息
  - framework: string       # 框架
  - language: string       # 编程语言
  - packageManager: string # 包管理器
verificationCommands: object # 验证命令
  - lint: string
  - typeCheck: string
  - test: string
  - build: string
options:
  overwrite: boolean       # 是否覆盖已有文件，默认false
  createHarnessDirs: boolean # 是否创建Harness目录，默认true
  createExamples: boolean   # 是否创建示例文件，默认false
```

### Harness 目录结构

初始化时创建的标准 Harness 目录结构：

```
项目根目录/
├── AGENTS.md                     # 入口地图（必建）
├── .agent/
│   ├── PLANS.md                  # 计划协议（必建）
│   └── plans/                    # 计划文件目录（必建）
├── docs/
│   └── harness/
│       ├── control-plane.md      # 控制面文档（必建）
│       └── project-constraints.md # 项目约束登记（必建）
├── docs/test/                    # 验证摘要目录（必建）
└── scripts/
    └── harness/                  # 检查脚本目录（建议建）
        └── check-structure.sh    # 结构检查脚本（示例）
```

### 初始化流程

```
1. 读取目标项目的技术栈和验证命令
   - 检查 package.json / go.mod / pyproject.toml 等
   - 提取 lint/test/build 命令

2. 生成 AGENTS.md
   - 使用 5-templates/template-agents.md 模板
   - 填充项目基本信息、验证命令、项目结构

3. 创建 Harness 目录结构
   - .agent/ + PLANS.md
   - docs/harness/ + control-plane.md + project-constraints.md
   - docs/test/

4. 生成控制面文档
   - 使用 5-templates/template-control-plane.md 模板
   - 填充任务入口、验证规范、回写规范

5. 创建 scripts/harness/（可选）
   - 生成结构检查脚本
   - 生成计划检查脚本

6. 验证初始化结果
   - 检查必要文件是否存在
   - 验证 AGENTS.md 完整性
```

### Harness 初始化输出

```yaml
Output:
- success: boolean
- createdFiles:
  - "AGENTS.md"
  - ".agent/PLANS.md"
  - ".agent/plans/"
  - "docs/harness/control-plane.md"
  - "docs/harness/project-constraints.md"
  - "docs/test/"
  - "scripts/harness/"
- existingFilesSkipped: string[]
- message: "Harness 初始化完成"
- verificationSummary:
  - "AGENTS.md 验证命令检查通过"
  - ".agent/PLANS.md 已创建"
  - "docs/harness/ 结构完整"
```

### 失败策略

#### E901 - Harness 初始化失败

```yaml
E901:
  error: "Harness 初始化失败"
  message: "无法在 {projectPath} 初始化 Harness 目录"
  recovery:
    - 检查项目目录是否可写
    - 确认 AGENTS.md 模板路径
    - 验证命令是否存在于项目环境中
```

#### E902 - 验证命令未找到

```yaml
E902:
  error: "验证命令未找到"
  message: "在项目 {projectPath} 中未找到有效的验证命令"
  recovery:
    - 检查项目是否为标准工程结构
    - 手动确认验证命令
    - 在 AGENTS.md 中手动补充
```

### 初始化后验证

```yaml
post_init_checks:
  - check: "AGENTS.md 存在"
    command: "检查项目根目录的 AGENTS.md"
    pass: "文件存在且包含验证命令"
  - check: ".agent/PLANS.md 存在"
    command: "检查 .agent/ 目录"
    pass: "PLANS.md 存在"
  - check: "docs/harness/ 存在"
    command: "检查 docs/harness/ 目录"
    pass: "control-plane.md 和 project-constraints.md 存在"
  - check: "docs/test/ 存在"
    command: "检查 docs/test/ 目录"
    pass: "目录存在"
```

## 文件编码规范

### 编码格式

- 默认编码：UTF-8
- 支持编码：UTF-8, UTF-16, GBK, GB2312

### 行尾符

- 统一使用 LF（\n）作为行尾符
- 兼容 Windows 的 CRLF（\r\n）

### 文件格式

- Markdown文件：使用标准Markdown语法
- YAML文件：使用YAML 1.2规范
- JSON文件：使用JSON规范

## 最佳实践

1. **原子性写入**：始终启用原子性写入，防止文件损坏
2. **定期备份**：重要文件定期备份
3. **路径验证**：操作前验证路径合法性
4. **错误处理**：完善的错误处理和恢复机制
5. **编码统一**：使用UTF-8编码，避免乱码问题
6. **权限管理**：合理设置文件和目录权限

## 版本信息

**版本**: 3.3
**更新时间**: 2026-05-14
**引用**: 3-core/core-file-sync.md, 3-core/core-state-management.md, 4-schemas/schema-state.md
