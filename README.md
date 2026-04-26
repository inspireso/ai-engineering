# AI 工程规范库

企业项目的 AI Agent 使用规范和最佳实践，可作为 Claude Code 插件或 git 子模块引入。

## 快速开始

### 方式一：Claude Code 插件（推荐）

```bash
# 在 Claude Code 中安装插件
/plugin install git:https://codeup.aliyun.com/suyuan/devops/ai-engineering.git
```

或本地测试：

```bash
claude --plugin-dir ./ai-engineering
```

插件会自动注册所有 skills、commands 和 hooks，命名空间为 `ai-engineering`。

### 方式二：Git 子模块

```bash
# 新项目
git submodule add https://codeup.aliyun.com/suyuan/devops/ai-engineering.git .ai-standards
.ai-standards/scripts/install.sh --tool claude-code

# 已有项目（合并 settings.json）
git submodule add https://codeup.aliyun.com/suyuan/devops/ai-engineering.git .ai-standards
.ai-standards/scripts/install.sh --tool claude-code --merge
```

## 目录结构

```
ai-engineering/
├── .claude-plugin/
│   └── plugin.json          # 插件清单
├── commands/                 # 斜杠命令
│   ├── qa.md
│   ├── release.md
│   └── review.md
├── skills/                   # AI 技能
│   ├── doc-gen/SKILL.md
│   ├── refactor-analysis/SKILL.md
│   └── review-fix-pipeline/SKILL.md
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
│   └── upgrade.sh
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

### Hooks

| 钩子 | 功能 |
|------|------|
| PreToolUse | 拦截 `rm -rf`、`DROP TABLE`、`force-push` 等危险命令 |
| PostToolUse | 工具调用后处理（可扩展） |
| UserPromptSubmit | 敏感关键词检测（password、api_key 等） |

## 版本管理

使用语义化版本，main 分支为最新稳定版。

## 支持的 AI 工具

- **Claude Code** — 插件 + 子模块双重模式
- **Trae** — 子模块模式（实验性）
- **Qoder** — 子模块模式（实验性）
