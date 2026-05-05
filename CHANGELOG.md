# Changelog

## 1.1.0 (2026-05-05)

### 新增

- 添加 `tdd-feature` skill：TDD 功能实现（RED→GREEN→REFACTOR 三阶段工作流）

### 变更

- 简化 `README.md` 安装说明：突出 marketplace 安装方式，移除冗余备选方案
- 更新版本号至 1.1.0
- 更新 `.gitignore` 添加 `.DS_Store` 忽略规则

## 1.0.0 (2026-04-26)

### 新增

- 添加 `.claude-plugin/plugin.json` 插件清单文件
- 添加 `settings.json` 项目权限和安全护栏配置
- 添加 `hooks/hooks.json` 插件 hooks 配置（PreToolUse/PostToolUse/UserPromptSubmit）
- 添加 `commands/` 目录（qa、review、release 命令）
- 添加 `skills/` 目录（doc-gen、refactor-analysis、review-fix-pipeline 技能）
- 添加 `hooks/` 目录（pre-tool-use、post-tool-use、user-prompt-submit 脚本）

### 变更

- 重构目录结构：`shared/` → `commands/`、`hooks/`、`skills/` 顶层目录
- 修复 `hooks.json` 结构：添加顶层 `hooks` 包装对象
- 修复 `plugin.json`：移除冗余的 `hooks` 引用（标准位置自动加载）
- 更新 `install.sh` 和 `upgrade.sh` 适配新目录结构
- 更新 `README.md` 文档
- 更新 `release.md` 命令：添加 git 提交步骤
