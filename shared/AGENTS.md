# AI Agent 工程规范

本文档定义 AI 编程助手在企业项目中的使用规范和最佳实践。

---

## 核心原则

### 1. 流程优先

- **规划先行**: 任何非 trivial 任务必须先 brainstorm → plan，再实现
- **测试驱动**: 新功能先写测试，再实现
- **证据优先**: 没有测试/截图/QA 报告不算完成

### 2. 安全护栏

- **禁止硬编码密钥**: API Key、密码、Token 不得写入代码
- **参数化查询**: 数据库访问必须使用参数化查询，禁止字符串拼接
- **危险命令拦截**: `rm -rf`、`DROP TABLE`、`force-push` 等必须先确认

### 3. 代码质量

- **YAGNI**: 不添加当前不需要的功能
- **DRY**: 重复代码提取为函数/模块
- **单一职责**: 每个文件/函数只做一件事
- **命名清晰**: 代码应自解释，避免过度注释

---

## 工作流程

### 新功能开发

```
brainstorm → writing-plans → executing-plans → qa → verification → code-review → ship
```

### Bug 修复

```
systematic-debugging → fix → test → verification → code-review → ship
```

### 小修改（配置/文案/单文件）

```
实现 → 测试 → 提交
```

---

## Change Delivery Gate

声明完成、准备 commit/push/PR 之前必须满足：

1. 已完成相关验证并如实报告结果
2. 已过对应质量门禁（review/verification）
3. 关键验证无法执行时必须明确说明原因
4. 禁止虚构命令输出
5. 没有验证证据不得声称"通过"或"完成"

---

## Skill 使用指南

### 流程类 Skill

| Skill | 用途 | 触发时机 |
|-------|------|----------|
| brainstorming | 创意细化、方案设计 | 任何创造性工作前 |
| writing-plans | 实现计划编写 | 设计确认后 |
| executing-plans | 计划执行 | 计划审核后 |
| systematic-debugging | Bug 排查 | 遇到 Bug/测试失败时 |
| verification-before-completion | 完成验证 | 声明完成前 |
| requesting-code-review | 请求 review | 功能完成后 |

### 执行类 Skill

| Skill | 用途 | 触发时机 |
|-------|------|----------|
| test-driven-development | TDD 流程 | 实现新功能时 |
| qa | QA 测试 | 功能完成后 |

---

## Commit Message 规范

遵循 Conventional Commits:

```
<type>(<scope>): <subject>

# 示例
feat(auth): add JWT token validation
fix(api): resolve timeout issue in handler
docs(readme): update installation guide
refactor(db): simplify query logic
test(unit): add tests for payment module
```

**Types**: feat, fix, docs, refactor, test, chore, style

---

## 禁止事项

1. 禁止在代码中硬编码敏感信息
2. 禁止绕过安全检查（如 `--no-verify`）
3. 禁止未经确认的 destructive 操作
4. 禁止虚构测试结果或命令输出
5. 禁止跳过必要的 review 流程