#!/bin/bash
# stop hook — 会话结束时提醒同步文档（有未提交变更且项目有 CLAUDE.md/AGENTS.md 时）
# 输入：stdin 上的 JSON（cwd、session_id 等）

INPUT=$(cat)

CWD=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("cwd", ""))
except Exception:
    pass
' 2>/dev/null)

SESSION_ID=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("session_id", ""))
except Exception:
    pass
' 2>/dev/null)

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-${CWD:-.}}"

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

# 同一会话只提醒一次
MARKER="${TMPDIR:-/tmp}/claude-sync-reminder-${SESSION_ID:-$$}"
if [ -f "$MARKER" ]; then
    exit 0
fi

touch "$MARKER"
printf '{"systemMessage": "📝 本次会话有未提交变更，结束时别忘了同步文档。输入「同步一下」即可。"}\n'
exit 0
