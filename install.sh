#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
RUNNER="$VENV_DIR/bin/StretchReminder"  # 심볼릭 링크 — macOS 백그라운드 항목 이름으로 표시됨
PLIST_LABEL="com.user.stretchreminder"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
APP_BUNDLE="$HOME/Applications/스트레칭 리마인더.app"

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
    rm -rf "$VENV_DIR"
    exit 1
}

# 설치 확인
"$VENV_DIR/bin/python" -c "import rumps" || {
    echo "❌ rumps가 정상적으로 설치되지 않았습니다. 다시 시도해주세요."
    exit 1
}

# 5. StretchReminder 심볼릭 링크 생성 (macOS 백그라운드 항목 표시 이름)
# venv 내부에 만들어야 Python이 pyvenv.cfg를 찾아 site-packages를 로드함
ln -sf python "$RUNNER"

# 6. 이미 실행 중이면 먼저 언로드
if launchctl list "$PLIST_LABEL" &>/dev/null; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi

# 7. launchd plist 생성
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$RUNNER</string>
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

# 8. Spotlight용 .app 번들 생성 (~/Applications/스트레칭 리마인더.app)
# "앱 종료" 후 Spotlight에서 "스트레칭" 검색해 재시작 가능
mkdir -p "$APP_BUNDLE/Contents/MacOS"
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>스트레칭 리마인더</string>
    <key>CFBundleDisplayName</key><string>스트레칭 리마인더</string>
    <key>CFBundleIdentifier</key><string>com.user.stretchreminder</string>
    <key>CFBundleExecutable</key><string>StretchReminder</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSUIElement</key><true/>
    <key>LSMinimumSystemVersion</key><string>12.0</string>
</dict>
</plist>
EOF

cat > "$APP_BUNDLE/Contents/MacOS/StretchReminder" <<EOF
#!/bin/bash
launchctl load -w "$PLIST_PATH" 2>/dev/null || true
EOF
chmod +x "$APP_BUNDLE/Contents/MacOS/StretchReminder"

# 9. stretch-upgrade 명령어 등록 (Homebrew bin에 심볼릭 링크)
BREW_BIN="$(brew --prefix)/bin"
chmod +x "$SCRIPT_DIR/upgrade.sh"
ln -sf "$SCRIPT_DIR/upgrade.sh" "$BREW_BIN/stretch-upgrade"

# 10. 서비스 시작
launchctl load "$PLIST_PATH" || {
    echo "❌ 서비스 시작에 실패했습니다."
    echo "   로그 확인: cat /tmp/stretchreminder.log"
    exit 1
}

echo ""
echo "✅ 설치 완료! 상단 메뉴바에 🧘 아이콘이 나타납니다."
echo "   45~80분 사이 랜덤으로 스트레칭 알림이 표시됩니다."
echo ""
echo "   재시작: Spotlight(Cmd+Space)에서 '스트레칭' 검색"
echo "   업데이트: stretch-upgrade"
echo "   제거: bash $SCRIPT_DIR/uninstall.sh"
