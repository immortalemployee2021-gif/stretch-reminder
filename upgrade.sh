#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔄 스트레치 리마인더를 업데이트합니다..."

if git -C "$SCRIPT_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
    git -C "$SCRIPT_DIR" pull
else
    # curl로 설치한 경우: ZIP 재다운로드
    curl -L https://github.com/immortalemployee2021-gif/stretch-reminder/archive/refs/heads/main.zip -o /tmp/stretch.zip
    unzip -q /tmp/stretch.zip -d /tmp
    cp -rf /tmp/stretch-reminder-main/. "$SCRIPT_DIR/"
fi

bash "$SCRIPT_DIR/install.sh"
