# AI 工程规范库

企业项目的 AI Agent 使用规范和最佳实践，作为 git 子模块引入。

## 快速开始

### 新项目

```bash
git submodule add https://your-repo/ai-engineering-standards.git .ai-standards
.ai-standards/scripts/install.sh --tool claude-code
```

### 已有项目

```bash
git submodule add https://your-repo/ai-engineering-standards.git .ai-standards
.ai-standards/scripts/install.sh --tool claude-code --merge
```

## 目录结构

- `shared/` — 公用规范文件（AGENTS.md、commands、skills、hooks）
- `tools/` — 各工具特有配置（settings.json）
- `scripts/` — 安装和升级脚本

## 版本管理

使用语义化版本，main 分支为最新稳定版。