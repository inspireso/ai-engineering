#!/bin/bash
# Stop hook - 会话结束前执行
# 用途：提醒用户同步文档（sync-docs），防止遗忘
# 策略：仅在存在未提交变更时提醒，且同一会话内只提醒一次

PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-.}"

# 无项目 CLAUDE.md/AGENTS.md 则跳过
if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ] && [ ! -f "$PROJECT_ROOT/AGENTS.md" ]; then
    exit 0
fi

# 非 git 仓库则跳过
if ! git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    exit 0
fi

# 无变更则跳过
if ! git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null | grep -qv '^$'; then
    exit 0
fi

# 同一会话只提醒一次（用标记文件）
MARKER="/tmp/claude-sync-reminder-${CLAUDE_SESSION_ID:-$$}"
if [ -f "$MARKER" ]; then
    exit 0
fi

touch "$MARKER"
echo "📝 本次会话有未提交变更，结束时别忘了同步文档。输入「同步一下」即可。"
exit 0
