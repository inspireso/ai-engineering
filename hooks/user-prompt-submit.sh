#!/bin/bash
# user-prompt-submit hook - 用户提交前处理
# 用于检查用户输入或注入上下文

USER_PROMPT="${CLAUDE_USER_PROMPT:-$1}"

# 检查是否包含敏感关键词
if echo "$USER_PROMPT" | grep -qE "password|secret|api_key|token"; then
    echo "WARN: Prompt contains sensitive keywords. Be careful not to expose secrets."
fi

exit 0