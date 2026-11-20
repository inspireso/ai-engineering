#!/bin/bash
# pre-tool-use hook — 工具调用前拦截危险命令
# 输入：stdin 上的 JSON（tool_name、tool_input、cwd、session_id 等）

INPUT=$(cat)

TOOL_NAME=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("tool_name", ""))
except Exception:
    pass
' 2>/dev/null)

[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception:
    pass
' 2>/dev/null)

block() {
    echo "BLOCK: $1" >&2
    exit 2
}

printf '%s' "$COMMAND" | grep -qE '(^|[;&|[:space:]])rm[[:space:]]+-[A-Za-z]*[rRf]' \
    && block "检测到递归或强制删除（rm -r/-rf/-f），改用精确路径，或先确认影响范围"

printf '%s' "$COMMAND" | grep -qiE 'DROP[[:space:]]+TABLE' \
    && block "检测到 DROP TABLE，先确认影响范围并备份"

printf '%s' "$COMMAND" | grep -qE 'git[[:space:]]+push[[:space:]].*(--force(-with-lease)?|-f)([[:space:]]|$)' \
    && block "检测到 force-push，未获用户明确授权不得执行"

exit 0
