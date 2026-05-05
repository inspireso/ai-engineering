# AI 工程规范库

企业项目的 AI Agent 使用规范和最佳实践，可作为 Claude Code 插件或 git 子模块引入。

## 安装

### Claude Code 插件（推荐）

```bash
# 1. 注册 marketplace
claude plugin marketplace add https://github.com/inspireso/ai-engineering.git

# 2. 安装插件
claude plugin install ai-engineering@inspireso-marketplace
```

安装后所有 skills、commands、hooks 自动生效，命名空间为 `ai-engineering`。

**更新**：`claude plugin update ai-engineering@inspireso-marketplace`

### Git 子模块

适用于需要在项目中引入规范文件（如 `CLAUDE.md`）的场景。

```bash
git submodule add https://github.com/inspireso/ai-engineering.git .ai-standards
.ai-standards/scripts/install.sh --tool claude-code
```

Windows 用户使用 `install.ps1`。详情见 [scripts/](scripts/)。

> **注意**: 插件模式更简单，推荐优先使用。

## 目录结构

```
ai-engineering/
├── .claude-plugin/
│   ├── plugin.json          # 插件清单
│   └── marketplace.json     # Marketplace 索引
├── commands/                 # 斜杠命令
│   ├── qa.md
│   ├── release.md
│   └── review.md
├── skills/                   # AI 技能
│   ├── doc-gen/SKILL.md
│   ├── refactor-analysis/SKILL.md
│   ├── review-fix-pipeline/SKILL.md
│   └── tdd-feature/SKILL.md
├── hooks/                    # 钩子脚本
│   ├── hooks.json            # 插件 hook 声明
│   ├── pre-tool-use.sh
│   ├── post-tool-use.sh
│   └── user-prompt-submit.sh
├── settings.json             # 默认插件设置（权限+环境变量）
├── shared/
│   └── AGENTS.md             # 公用 Agent 规范
├── tools/                    # 各工具特有配置
│   ├── claude-code/settings.json
│   ├── qoder/
│   └── trae/
├── scripts/                  # 安装和升级脚本
│   ├── install.sh
│   ├── install.ps1
│   ├── upgrade.sh
│   └── upgrade.ps1
└── VERSION
```

## 包含内容

### Commands

| 命令 | 用途 |
|------|------|
| `/ai-engineering:qa` | 系统化 QA 测试流程 |
| `/ai-engineering:release` | 发布流程（合并、测试、CHANGELOG） |
| `/ai-engineering:review` | PR 代码审查流程 |

### Skills

| 技能 | 用途 |
|------|------|
| `doc-gen` | 先大纲后生成的文档创建 |
| `refactor-analysis` | 重构影响分析（跨文件依赖检查） |
| `review-fix-pipeline` | 审查→修复→测试闭环 |
| `tdd-feature` | TDD 功能实现（RED→GREEN→REFACTOR） |

### Hooks

| 钩子 | 功能 |
|------|------|
| PreToolUse | 拦截 `rm -rf`、`DROP TABLE`、`force-push` 等危险命令 |
| PostToolUse | 工具调用后处理（可扩展） |
| UserPromptSubmit | 敏感关键词检测（password、api_key 等） |

## 支持的 AI 工具

| 工具 | 模式 |
|------|------|
| Claude Code | 插件（推荐）或子模块 |
| Trae | 子模块（实验性） |
| Qoder | 子模块（实验性） |
