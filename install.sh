#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
PLIST_LABEL="com.user.stretchreminder"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

echo "🧘 스트레치 리마인더 설치를 시작합니다..."

# 1. Homebrew 확인
if ! command -v brew &>/dev/null; then
    echo ""
    echo "❌ Homebrew가 필요합니다. 설치하려면 아래 명령어를 먼저 실행해주세요:"
    echo ""
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo ""
    echo "설치 후 다시 install.sh를 실행해주세요."
    exit 1
fi

# 2. Python3 확인
if ! command -v python3 &>/dev/null; then
    echo "Python3를 설치합니다..."
    brew install python || {
        echo "❌ Python3 설치에 실패했습니다. 수동으로 설치 후 다시 시도해주세요."
        exit 1
    }
fi

# 3. 가상환경 생성
# venv 내부의 pip은 PEP 668(시스템 Python 보호) 제한 없이 패키지를 설치할 수 있음
if [ ! -d "$VENV_DIR" ]; then
    echo "가상환경을 생성합니다..."
    python3 -m venv "$VENV_DIR" || {
        echo "❌ 가상환경 생성에 실패했습니다."
        echo "   python3 --version 으로 Python이 정상 설치됐는지 확인해주세요."
        exit 1
    }
fi

# 4. rumps 설치
echo "rumps를 설치합니다..."
"$VENV_DIR/bin/pip" install --quiet rumps || {
    echo "❌ rumps 설치에 실패했습니다."
    echo "   인터넷 연결을 확인하고 다시 시도해주세요."
    rm -rf "$VENV_DIR"  # 불완전한 venv 제거
    exit 1
}

# 설치 확인
"$VENV_DIR/bin/python" -c "import rumps" || {
    echo "❌ rumps가 정상적으로 설치되지 않았습니다. 다시 시도해주세요."
    exit 1
}

# 5. 이미 실행 중이면 먼저 언로드
if launchctl list "$PLIST_LABEL" &>/dev/null; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi

# 6. launchd plist 생성
PYTHON_PATH="$VENV_DIR/bin/python"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_PATH</string>
        <string>$SCRIPT_DIR/app.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/stretchreminder.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/stretchreminder.log</string>
</dict>
</plist>
EOF

# 7. 서비스 시작
launchctl load "$PLIST_PATH" || {
    echo "❌ 서비스 시작에 실패했습니다."
    echo "   로그 확인: cat /tmp/stretchreminder.log"
    exit 1
}

echo ""
echo "✅ 설치 완료! 상단 메뉴바에 🧘 아이콘이 나타납니다."
echo "   45~80분 사이 랜덤으로 스트레칭 알림이 표시됩니다."
echo ""
echo "   제거: bash $SCRIPT_DIR/uninstall.sh"
