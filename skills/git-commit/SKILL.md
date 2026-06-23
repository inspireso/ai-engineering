---
name: git-commit
description: 按 Conventional Commits 规范执行 git 提交——分析 diff 自动推断 type 与 scope，生成规范化提交信息，支持智能暂存与逻辑分组。当用户请求提交变更、创建 git commit，或在 release/review 等流程中需要按规范提交时自动触发。
license: MIT
allowed-tools: Bash
---

# Git Commit（Conventional Commits 规范）

## 概述

依据 Conventional Commits 规范创建标准化、语义化的 git 提交。通过分析实际 diff 确定合适的 type、scope 与提交信息。

## 提交信息格式

```
<type>[可选 scope]: <description>

[可选 body]

[可选 footer]
```

## 提交类型

| Type       | 用途                     |
| ---------- | ------------------------ |
| `feat`     | 新功能                   |
| `fix`      | Bug 修复                 |
| `docs`     | 仅文档变更               |
| `style`    | 格式/样式（不涉及逻辑）  |
| `refactor` | 重构（非新功能、非修复） |
| `perf`     | 性能优化                 |
| `test`     | 新增/更新测试            |
| `build`    | 构建系统/依赖            |
| `ci`       | CI/配置变更              |
| `chore`    | 维护/杂项                |
| `revert`   | 回滚提交                 |

## 破坏性变更

```
# type/scope 后加感叹号
feat!: remove deprecated endpoint

# 使用 BREAKING CHANGE footer
feat: allow config to extend other configs

BREAKING CHANGE: `extends` key behavior changed
```

## 工作流程

### 1. 分析 diff

```bash
# 已暂存时查看暂存区 diff
git diff --staged

# 未暂存时查看工作区 diff
git diff

# 同时检查状态
git status --porcelain
```

### 2. 暂存文件（按需）

若没有已暂存内容，或希望按逻辑重新分组：

```bash
# 暂存指定文件
git add path/to/file1 path/to/file2

# 按模式暂存
git add *.test.*
git add src/components/*

# 交互式暂存
git add -p
```

**绝勿提交敏感信息**（.env、credentials.json、私钥等）。

### 3. 生成提交信息

分析 diff 确定：

- **Type**：这是哪一类变更？
- **Scope**：影响哪个模块/区域？
- **Description**：一句话概括变更内容（现在时、祈使语气、<72 字符）

### 4. 执行提交

```bash
# 单行
git commit -m "<type>[scope]: <description>"

# 多行（含 body/footer）
git commit -m "$(cat <<'EOF'
<type>[scope]: <description>

<可选 body>

<可选 footer>
EOF
)"
```

## 最佳实践

- 一次提交只包含一个逻辑变更
- 使用现在时："add" 而非 "added"
- 使用祈使语气："fix bug" 而非 "fixes bug"
- 关联 issue：`Closes #123`、`Refs #456`
- description 控制在 72 字符以内

## Git 安全协议

- 绝不修改 git config
- 未经明确请求绝不执行破坏性命令（--force、hard reset）
- 除非用户要求，绝不跳过 hooks（--no-verify）
- 绝不向 main/master 强制推送
- 若因 hooks 失败，修复后创建**新提交**（不要 amend）
