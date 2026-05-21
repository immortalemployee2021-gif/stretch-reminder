#!/usr/bin/env python3
import random
import subprocess
import sys
import threading
import time

import AppKit

# rumps 초기화 전에 Dock 아이콘 숨김
AppKit.NSApplication.sharedApplication().setActivationPolicy_(
    AppKit.NSApplicationActivationPolicyAccessory
)

import rumps

from tips import TIPS, TITLES

# 45~80분 (초 단위)
INTERVAL_MIN = 45 * 60
INTERVAL_MAX = 80 * 60

# --test 플래그: 5초 후 즉시 팝업
if "--test" in sys.argv:
    INTERVAL_MIN = 5
    INTERVAL_MAX = 5


def show_popup(title, header, desc):
    body = f"{header}\\n\\n{desc}"
    script = (
        f'display dialog "{body}" '
        f'buttons {{"완료"}} '
        f'default button "완료" '
        f'with title "{title}"'
    )
    subprocess.run(["osascript", "-e", script])


class StretchApp(rumps.App):
    def __init__(self):
        super().__init__("🧘", quit_button=None)
        self.paused = False
        self.menu = ["일시정지", None, "앱 종료"]
        self._timer_thread = threading.Thread(target=self._timer_loop, daemon=True)
        self._timer_thread.start()

    def _timer_loop(self):
        # 최초 실행 시 10초 후 첫 팝업
        first = True
        while True:
            wait = 10 if first else random.randint(INTERVAL_MIN, INTERVAL_MAX)
            first = False
            for _ in range(wait):
                time.sleep(1)

            if not self.paused:
                tip = random.choice(TIPS)
                title = random.choice(TITLES)
                show_popup(title, tip["header"], tip["desc"])

    @rumps.clicked("일시정지")
    def toggle_pause(self, sender):
        self.paused = not self.paused
        if self.paused:
            self.title = "⏸"
            sender.title = "알림 재시작"
        else:
            self.title = "🧘"
            sender.title = "일시정지"

    @rumps.clicked("앱 종료")
    def quit_app(self, _):
        rumps.quit_application()


if __name__ == "__main__":
    StretchApp().run()
