#!/bin/bash
# upgrade.sh - 规范库升级脚本
# 检查版本变更并提示用户

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STANDARDS_DIR="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="$STANDARDS_DIR/VERSION"

CURRENT_VERSION=$(cat "$VERSION_FILE")
echo "Current standards version: $CURRENT_VERSION"

# 检查是否有版本变更
OLD_VERSION_FILE=".ai-standards-version"
if [ -f "$OLD_VERSION_FILE" ]; then
    OLD_VERSION=$(cat "$OLD_VERSION_FILE")
    if [ "$OLD_VERSION" != "$CURRENT_VERSION" ]; then
        echo "Version changed from $OLD_VERSION to $CURRENT_VERSION"

        # 检查是否是主版本变更
        OLD_MAJOR=$(echo "$OLD_VERSION" | cut -d. -f1)
        CURRENT_MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)

        if [ "$OLD_MAJOR" != "$CURRENT_MAJOR" ]; then
            echo "WARN: Major version upgrade detected!"
            echo "Please review BREAKING_CHANGES.md if exists"
        fi
    fi
fi

# 更新版本记录
echo "$CURRENT_VERSION" > "$OLD_VERSION_FILE"

# 提示重新运行 install
echo "Consider running install.sh again to update symlinks"
echo "  .ai-standards/scripts/install.sh --tool claude-code --merge"

echo "Upgrade check complete"