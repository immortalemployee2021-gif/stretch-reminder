#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_LABEL="com.user.stretchreminder"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
UPDATE_LABEL="com.user.stretchreminder.update"
UPDATE_PLIST="$HOME/Library/LaunchAgents/$UPDATE_LABEL.plist"
APP_BUNDLE="$HOME/Applications/스트레칭 리마인더.app"

echo "🧘 스트레치 리마인더를 제거합니다..."

if launchctl list "$PLIST_LABEL" &>/dev/null; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi

# 자동 업데이트 LaunchAgent 도 함께 제거
if launchctl list "$UPDATE_LABEL" &>/dev/null; then
    launchctl unload "$UPDATE_PLIST" 2>/dev/null || true
fi

[ -f "$PLIST_PATH" ] && rm "$PLIST_PATH"
[ -f "$UPDATE_PLIST" ] && rm "$UPDATE_PLIST"
[ -d "$APP_BUNDLE" ] && rm -rf "$APP_BUNDLE"

BREW_BIN="$(brew --prefix)/bin"
[ -L "$BREW_BIN/stretch-upgrade" ] && rm "$BREW_BIN/stretch-upgrade"

echo "✅ 제거 완료."
