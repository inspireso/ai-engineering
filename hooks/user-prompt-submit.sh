#!/bin/bash
# user-prompt-submit hook — 检测疑似明文凭据
# 输入：stdin 上的 JSON（prompt、cwd、session_id 等）

INPUT=$(cat)

PROMPT=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("prompt", ""))
except Exception:
    pass
' 2>/dev/null)

if printf '%s' "$PROMPT" | grep -qEi '(password|passwd|secret|api[_-]?key|access[_-]?key|private[_-]?key|token)[[:space:]]*[:=][[:space:]]*[^[:space:]]{8,}'; then
    echo "WARN: 提示词里疑似包含明文凭据，注意不要写入代码、文档或日志。" >&2
fi

exit 0
