# Core File Sync
# 文件同步核心模块

## 职责
- 文件变更检测
- 变更影响分析
- 文件同步策略
- 同步状态管理
- 同步报告生成

## 文件变更检测

### 监控范围
```
监控的文件类型：
1. 需求文档 (*req*.md, *requirement*.md)
2. 设计文档 (*design*.md, *architecture*.md)
3. 计划文档 (*plan*.md, *schedule*.md)
4. 源代码文件 (*.js, *.ts, *.py, *.java, *.go, etc.)
5. 配置文件 (*.json, *.yaml, *.yml, *.config.*)
6. 测试文件 (*test*.md, *spec*.md, *.test.*)
```

### 检测方法
```
1. 文件修改时间比对
2. 文件内容哈希比对
3. Git变更检测（如果可用）
4. 手动触发检测
```

### 检测命令
```
/reqplan sync              # 手动触发同步检测
/reqplan sync status       # 查看同步状态
/reqplan sync report       # 生成同步报告
```

## 变更影响分析

### 影响范围判断
```
文件变更 → 影响分析：

1. 需求文档变更
   → 影响：设计文档、开发计划、测试用例
   → 建议：重新评审设计、更新计划

2. 设计文档变更
   → 影响：开发任务、API文档、测试用例
   → 建议：更新任务、重新生成API文档

3. 代码文件变更
   → 影响：测试用例、文档、相关模块
   → 建议：运行相关测试、检查依赖

4. 配置文件变更
   → 影响：部署、测试、相关服务
   → 建议：验证配置、更新部署文档
```

### 影响分析报告
```yaml
impact_analysis:
  changed_file: requirements/req-001.md
  change_type: modified
  impact_scope:
    - design/architecture.md
    - plans/dev-plan.md
    - tests/cases.md
  severity: high
  recommendations:
    - review design changes
    - update development plan
    - add new test cases
```

## 文件同步策略

### 同步规则
```
1. 自动同步：检测到变更时自动触发
2. 手动同步：用户主动触发同步
3. 定时同步：定期检查并同步
4. 条件同步：满足特定条件时同步
```

### 同步操作
```
同步操作类型：
1. 更新：更新相关文档和配置
2. 提醒：提醒用户注意变更
3. 审核：触发审核流程
4. 忽略：标记为无需同步
```

### 同步流程
```
1. 检测文件变更
2. 分析影响范围
3. 生成同步建议
4. 用户确认或修改
5. 执行同步操作
6. 记录同步结果
7. 生成同步报告
```

## 同步状态管理

### 同步状态
```
sync_status:
  last_check: 2026-05-15T10:00:00
  pending_changes: 3
  synced_files: 156
  last_sync: 2026-05-15T09:30:00
  conflicts: 0
```

### 冲突处理
```
发现冲突时：
1. 显示冲突的文件
2. 提供差异对比
3. 让用户选择保留哪个版本
4. 或提供合并选项
5. 记录解决方案
```

## 同步报告生成

### 报告内容
```
同步报告包含：
1. 变更文件列表
2. 影响分析结果
3. 已执行的同步操作
4. 待处理的事项
5. 建议的后续步骤
```

### 报告格式
```
📋 文件同步报告
生成时间：2026-05-15 10:30:00

变更文件：
✅ requirements/req-001.md (已同步)
✅ design/api.md (已同步)
⚠️  src/user-service.js (待审核)

影响分析：
- 需求变更影响3个文档
- API设计变更影响5个模块
- 代码变更需要审核

建议后续：
1. 审核代码变更 → /reqplan review
2. 更新测试用例 → /reqplan verify
3. 确认同步完成 → /reqplan sync
```

## 引导信息

### 变更检测提示
```
🔍 检测到文件变更：
📄 requirements/req-001.md (2分钟前修改)

影响分析：
- 设计文档可能需要更新
- 开发计划可能需要调整
- 测试用例可能需要补充

操作建议：
1. 查看详细影响 → /reqplan sync report
2. 自动同步相关文件 → /reqplan sync
3. 手动处理 → 稍后再说
```

### 同步完成提示
```
✅ 同步完成！
已处理：5个文件
已更新：3个文档
待审核：1个代码变更

下一步：
1. 查看同步报告 → /reqplan sync report
2. 继续当前流程 → /reqplan guide
3. 切换到审核流程 → /reqplan flow audit
```

## 失败策略

### 文件检测失败 (E802)
```
1. 检查文件路径是否正确
2. 检查文件权限
3. 提示用户手动指定文件
4. 记录错误日志
```

### 影响分析失败 (E806)
```
1. 显示已检测到的变更
2. 提示用户手动分析
3. 提供基础的同步建议
4. 记录错误日志
```

### 同步操作失败 (E807)
```
1. 回滚已执行的操作
2. 显示失败原因
3. 提供重试选项
4. 或让用户手动处理
5. 记录错误日志
```

## 版本信息

**版本**: 3.2.0
**更新时间**: 2026-05-14
**引用**: 3-core/core-file-io.md, 3-core/core-state-management.md, 4-schemas/schema-state.md
