#!/bin/bash
# pre-tool-use hook - 工具调用前检查
# 用于拦截危险命令

TOOL_NAME="${CLAUDE_TOOL_NAME:-$1}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-$2}"

# 检查危险 Bash 命令
if [ "$TOOL_NAME" = "Bash" ]; then
    # 拦截 rm -rf
    if echo "$TOOL_INPUT" | grep -qE "rm\s+-rf|rm\s+-.{0,5}f"; then
        echo "BLOCK: rm -rf detected. Use /careful or /guard first."
        exit 1
    fi

    # 拦截 DROP TABLE
    if echo "$TOOL_INPUT" | grep -qE "DROP\s+TABLE"; then
        echo "BLOCK: DROP TABLE detected. Use /careful or /guard first."
        exit 1
    fi

    # 拦截 force push
    if echo "$TOOL_INPUT" | grep -qE "git\s+push\s+.*--force"; then
        echo "BLOCK: force-push detected. Use /careful or /guard first."
        exit 1
    fi
fi

exit 0