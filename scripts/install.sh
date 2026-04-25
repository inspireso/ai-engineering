#!/bin/bash
# install.sh - AI 工程规范库安装脚本
# 将规范文件软链接到项目目录

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STANDARDS_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_DIR="$STANDARDS_ROOT/shared"
TOOLS_DIR="$STANDARDS_ROOT/tools"

# 默认参数
TOOL="claude-code"
MERGE=false
PROJECT_ROOT="$(pwd)"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --tool)
            TOOL="$2"
            shift 2
            ;;
        --tools)
            # 多工具安装，逗号分隔
            TOOLS="$2"
            IFS=',' read -ra TOOL_ARRAY <<< "$TOOLS"
            for t in "${TOOL_ARRAY[@]}"; do
                "$SCRIPT_DIR/install.sh" --tool "$t" --project-root "$PROJECT_ROOT"
            done
            exit 0
            ;;
        --merge)
            MERGE=true
            shift
            ;;
        --project-root)
            PROJECT_ROOT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: install.sh --tool <tool> [--merge] [--project-root <path>]"
            exit 1
            ;;
    esac
done

echo "Installing AI standards for: $TOOL"
echo "Project root: $PROJECT_ROOT"

# 根据工具类型执行安装
case $TOOL in
    claude-code)
        CLAUDE_DIR="$PROJECT_ROOT/.claude"

        # 创建 .claude 目录
        mkdir -p "$CLAUDE_DIR"

        # 创建软链接
        ln -sf "$SHARED_DIR/AGENTS.md" "$CLAUDE_DIR/CLAUDE.md"
        ln -sf "$SHARED_DIR/commands" "$CLAUDE_DIR/commands"
        ln -sf "$SHARED_DIR/skills" "$CLAUDE_DIR/skills"
        ln -sf "$SHARED_DIR/hooks" "$CLAUDE_DIR/hooks"

        # 处理 settings.json
        SETTINGS_SRC="$TOOLS_DIR/claude-code/settings.json"
        SETTINGS_DEST="$CLAUDE_DIR/settings.json"

        if [ "$MERGE" = true ] && [ -f "$SETTINGS_DEST" ]; then
            # 合并模式：使用 jq 合并 JSON
            if command -v jq &> /dev/null; then
                jq -s '.[0] * .[1]' "$SETTINGS_DEST" "$SETTINGS_SRC" > "$SETTINGS_DEST.tmp"
                mv "$SETTINGS_DEST.tmp" "$SETTINGS_DEST"
                echo "Merged settings.json"
            else
                echo "WARN: jq not found, copying settings.json instead of merging"
                cp "$SETTINGS_SRC" "$SETTINGS_DEST"
            fi
        else
            # 新项目模式：直接复制
            cp "$SETTINGS_SRC" "$SETTINGS_DEST"
        fi

        echo "Claude Code standards installed successfully"
        echo "Created symlinks:"
        echo "  $CLAUDE_DIR/CLAUDE.md -> $SHARED_DIR/AGENTS.md"
        echo "  $CLAUDE_DIR/commands -> $SHARED_DIR/commands"
        echo "  $CLAUDE_DIR/skills -> $SHARED_DIR/skills"
        echo "  $CLAUDE_DIR/hooks -> $SHARED_DIR/hooks"
        ;;

    trae)
        TRAE_DIR="$PROJECT_ROOT/.trae"
        mkdir -p "$TRAE_DIR"

        # Trae 配置（待确认自动读取机制）
        ln -sf "$SHARED_DIR/AGENTS.md" "$TRAE_DIR/AGENTS.md"
        ln -sf "$SHARED_DIR/commands" "$TRAE_DIR/commands"
        ln -sf "$SHARED_DIR/skills" "$TRAE_DIR/skills"

        echo "Trae standards installed (experimental)"
        ;;

    qoder)
        QODER_DIR="$PROJECT_ROOT/.qoder"
        mkdir -p "$QODER_DIR"

        # Qoder 配置（待确认自动读取机制）
        ln -sf "$SHARED_DIR/AGENTS.md" "$QODER_DIR/AGENTS.md"
        ln -sf "$SHARED_DIR/commands" "$QODER_DIR/commands"
        ln -sf "$SHARED_DIR/skills" "$QODER_DIR/skills"

        echo "Qoder standards installed (experimental)"
        ;;

    *)
        echo "Unknown tool: $TOOL"
        echo "Supported tools: claude-code, trae, qoder"
        exit 1
        ;;
esac

echo "Done!"