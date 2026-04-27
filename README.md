# AI 工程规范库

企业项目的 AI Agent 使用规范和最佳实践，可作为 Claude Code 插件或 git 子模块引入。

## 快速开始

### 方式一：Claude Code 插件（推荐）

#### 方式 A：通过自定义 Marketplace（推荐）

```bash
# 注册自定义 marketplace
claude plugin marketplace add https://github.com/inspireso/ai-engineering.git

# 在 Claude Code 中安装插件
/plugin install ai-engineering@inspireso-marketplace
```

或者手动在 `~/.claude/settings.json` 中配置：

```json
{
  "extraKnownMarketplaces": {
    "inspireso-marketplace": {
      "source": {
        "source": "git",
        "url": "https://github.com/inspireso/ai-engineering.git"
      }
    }
  }
}
```

#### 方式 B：手动克隆安装

```bash
# 1. 克隆到 Claude Code 插件目录
git clone https://github.com/inspireso/ai-engineering.git ~/.claude/plugins/ai-engineering

# 2. 在 Claude Code 中安装
/plugin install ai-engineering
```

安装后插件会自动注册所有 skills、commands 和 hooks，命名空间为 `ai-engineering`。

本地开发测试可用：

```bash
claude --plugin-dir /path/to/ai-engineering
```

### 更新插件

```bash
cd ~/.claude/plugins/ai-engineering && git pull
# 然后在 Claude Code 中执行 /reload-plugins
```

### 方式二：Git 子模块

#### Linux / macOS

```bash
# 新项目
git submodule add https://github.com/inspireso/ai-engineering.git .ai-standards
.ai-standards/scripts/install.sh --tool claude-code

# 已有项目（合并 settings.json）
git submodule add https://github.com/inspireso/ai-engineering.git .ai-standards
.ai-standards/scripts/install.sh --tool claude-code --merge
```

#### Windows (PowerShell)

```powershell
# 新项目
git submodule add https://github.com/inspireso/ai-engineering.git .ai-standards
.ai-standards/scripts/install.ps1 -Tool claude-code

# 已有项目（合并 settings.json）
git submodule add https://github.com/inspireso/ai-engineering.git .ai-standards
.ai-standards/scripts/install.ps1 -Tool claude-code -Merge

# 安装多个工具
.ai-standards/scripts/install.ps1 -Tools "claude-code,trae"

# 指定项目根目录
.ai-standards/scripts/install.ps1 -Tool claude-code -ProjectRoot "D:\projects\myapp"
```

> **注意**: Windows 上目录链接优先使用 Junction（无需管理员权限），文件链接优先使用
> SymbolicLink。如果未开启开发者模式且无管理员权限，将自动降级为 HardLink 或复制。
> 降级为复制后，规范库更新时需重新运行 `install.ps1`。

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

### Hooks

| 钩子 | 功能 |
|------|------|
| PreToolUse | 拦截 `rm -rf`、`DROP TABLE`、`force-push` 等危险命令 |
| PostToolUse | 工具调用后处理（可扩展） |
| UserPromptSubmit | 敏感关键词检测（password、api_key 等） |

## 版本管理

使用语义化版本，main 分支为最新稳定版。

## Windows 注意事项

- 安装脚本同时提供 bash 版本 (`install.sh`) 和 PowerShell 版本 (`install.ps1`)
- PowerShell 版本兼容 Windows PowerShell 5.1 和 PowerShell 7
- 目录链接优先使用 Junction（无需管理员权限），文件链接在无管理员权限时降级为 HardLink 或复制
- 升级脚本同样有 PowerShell 版本 (`upgrade.ps1`)
- Hook 脚本 (`.sh`) 由 Claude Code runtime 调用，在 Windows 上通过 Git Bash 执行，install 脚本只负责部署

## 支持的 AI 工具

- **Claude Code** — 插件 + 子模块双重模式
- **Trae** — 子模块模式（实验性）
- **Qoder** — 子模块模式（实验性）
