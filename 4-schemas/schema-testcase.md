# TestCase Schema

## 概述

定义测试用例（TestCase）的数据结构和验证规则。

## 数据结构

### TestCase 对象

```yaml
id: string              # 测试用例ID，格式：TC-XXX
title: string          # 测试用例标题
type: TestCaseType     # 用例类型
priority: Priority      # 优先级
preconditions: string[] # 前置条件
testSteps: string[]   # 测试步骤
expectedResult: string # 预期结果
testData?: object     # 测试数据（可选）
actualResult?: string  # 实际结果（可选）
status?: TestCaseStatus # 执行状态（可选）
notes?: string        # 备注（可选）
requirementId?: string # 关联需求ID（v3新增，可选）
taskId?: string       # 关联任务ID（v3新增，可选）
executionTime?: number # 执行时间（秒，v3新增，可选）
executedAt?: string  # 执行时间（v3新增，可选）
```

### TestCaseType 枚举

```yaml
positive: 正向测试（正常流程）
negative: 负向测试（异常流程）
boundary: 边界测试（边界条件）
performance: 性能测试
security: 安全测试
```

### Priority 枚举

```yaml
P0: 必须通过（阻塞性）
P1: 应该通过（重要）
P2: 建议通过（一般）
```

### TestCaseStatus 枚举

```yaml
pending: 待执行
pass: 通过
fail: 失败
blocked: 阻塞
skipped: 跳过
```

## 验证规则

### 必填字段
- `id`: 非空，符合格式 `TC-\d{3}`
- `title`: 非空，长度1-200字符
- `type`: 非空，必须是有效的TestCaseType值
- `priority`: 非空，必须是有效的Priority值
- `preconditions`: 非空数组，至少包含1项
- `testSteps`: 非空数组，至少包含1项
- `expectedResult`: 非空，长度1-500字符

### 可选字段
- `testData`: 对象类型，键值对形式
- `actualResult`: 长度1-500字符
- `status`: 必须是有效的TestCaseStatus值
- `notes`: 长度不限
- `requirementId`: 符合需求ID格式
- `taskId`: 符合任务ID格式
- `executionTime`: 必须大于等于0
- `executedAt`: ISO格式时间戳

## 示例

```yaml
id: "TC-001"
title: "订单创建成功"
type: "positive"
priority: "P0"
preconditions:
  - "用户已登录"
  - "系统正常运行"
  - "数据库连接正常"
testSteps:
  - "发送POST请求到 /api/orders"
  - "携带有效订单数据"
  - "检查响应状态码"
expectedResult: "返回201状态码，包含创建的订单ID"
testData:
  userId: "123"
  items:
    - productId: "P001"
      quantity: 2
  totalAmount: 99.99
actualResult: "返回201状态码，订单ID为ORD-001"
status: "pass"
notes: "测试通过，响应时间符合预期"
requirementId: "REQ-001"
taskId: "TASK-002"
executionTime: 0.25
executedAt: "2026-05-14T15:30:00Z"
```

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "TestCase Schema v3",
  "required": ["id", "title", "type", "priority", "preconditions", "testSteps", "expectedResult"],
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^TC-\\d{3}$"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 200
    },
    "type": {
      "type": "string",
      "enum": ["positive", "negative", "boundary", "performance", "security"]
    },
    "priority": {
      "type": "string",
      "enum": ["P0", "P1", "P2"]
    },
    "preconditions": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "string",
        "minLength": 1
      }
    },
    "testSteps": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "string",
        "minLength": 1
      }
    },
    "expectedResult": {
      "type": "string",
      "minLength": 1,
      "maxLength": 500
    },
    "testData": {
      "type": "object"
    },
    "actualResult": {
      "type": "string",
      "minLength": 1,
      "maxLength": 500
    },
    "status": {
      "type": "string",
      "enum": ["pending", "pass", "fail", "blocked", "skipped"]
    },
    "notes": {
      "type": "string"
    },
    "requirementId": {
      "type": "string",
      "pattern": "^REQ-\\d{3}$"
    },
    "taskId": {
      "type": "string",
      "pattern": "^TASK-\\d{3}$"
    },
    "executionTime": {
      "type": "number",
      "minimum": 0
    },
    "executedAt": {
      "type": "string",
      "format": "date-time"
    }
  }
}
```

---

**Schema版本**: 3.2.0  
**更新时间**: 2026-05-14  
**引用**: 7-flows/flow-testing.md, 3-core/core-verification.md
