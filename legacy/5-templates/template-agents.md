---
template:
  name: template-agents
  version: "3.2"
  type: agents
  usage: 项目的入口地图（Entry Map），定义项目概述、验证命令和约束
---

# AGENTS.md 模板（Entry Map）

AGENTS.md 是项目的入口地图——告诉 Agent 和开发者项目是什么、验证命令是什么、底线规则是什么。不是项目百科，是导航和边界说明。

## 生成内容

```markdown
# {{projectName}}

## 项目信息

- **技术栈**：{{techStack}}
- **包管理器**：{{packageManager}}

## 快速开始

```bash
{{installCommand}}
{{devCommand}}
{{buildCommand}}
```

## 验证命令

| 类型 | 命令 |
|------|------|
| Lint | `{{lintCommand}}` |
| 类型检查 | `{{typeCheckCommand}}` |
| 单元测试 | `{{unitTestCommand}}` |
| 集成测试 | `{{integrationTestCommand}}` |
| 构建 | `{{buildCommand}}` |

## 项目结构

```
{{projectStructure}}
```

## 项目约束

{{#each constraints}}
- {{this}}
{{/each}}

## 相关文档

- [Harness 控制面](docs/harness/control-plane.md)
- [项目约束](docs/harness/project-constraints.md)
- [计划文档](.agent/plans/)
- [验证文档](docs/test/)
```

## 生成规则

| 规则 | 级别 |
|------|------|
| AGENTS.md 必须位于项目根目录 | error |
| 验证命令必须真实可用 | error |
| 引用文档路径必须真实存在 | error |
| 只写工程入口和约束，不写需求细节 | warning |
| 约束只登记已经确认的规则 | warning |

## 示例

### 前端

```markdown
# my-web-app

## 项目信息

- **技术栈**：React 18 + TypeScript + Vite
- **包管理器**：npm

## 快速开始

```bash
npm install
npm run dev
npm run build
```

## 验证命令

| 类型 | 命令 |
|------|------|
| Lint | `npm run lint` |
| 类型检查 | `npm run typecheck` |
| 单元测试 | `npm run test` |

## 项目约束

- 所有组件使用 TypeScript
- 组件默认使用命名导出（named export）
- 样式使用 CSS Modules
```

### 后端

```markdown
# my-api-service

## 项目信息

- **技术栈**：Go 1.22 + PostgreSQL
- **包管理器**：Go Modules

## 快速开始

```bash
go mod download
go run cmd/server/main.go
go build ./...
```

## 验证命令

| 类型 | 命令 |
|------|------|
| Lint | `golangci-lint run` |
| 单元测试 | `go test ./... -v` |
| 集成测试 | `go test ./... -tags=integration` |

## 项目约束

- 所有 API 错误使用标准错误码格式
- 数据库迁移使用 golang-migrate
- 日志使用 structured logging
```

## 更新时机

技术栈变更、验证命令变更、项目结构重大调整、新增约束时同步更新。

## 引用

4-schemas/schema-landing-zone.md, 3-core/core-file-io.md
