#!/bin/bash
set -e

PLIST_LABEL="com.user.stretchreminder"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

echo "🧘 스트레치 리마인더를 제거합니다..."

if launchctl list "$PLIST_LABEL" &>/dev/null; then
    launchctl unload "$PLIST_PATH"
fi

if [ -f "$PLIST_PATH" ]; then
    rm "$PLIST_PATH"
fi

echo "✅ 제거 완료."
