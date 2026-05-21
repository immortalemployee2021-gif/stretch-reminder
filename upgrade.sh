#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔄 스트레치 리마인더를 업데이트합니다..."
git -C "$SCRIPT_DIR" pull
bash "$SCRIPT_DIR/install.sh"
