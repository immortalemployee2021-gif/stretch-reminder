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

# 알림 간격 선택지 (라벨, 분). 분이 None이면 45~80분 랜덤.
INTERVALS = [
    ("랜덤 (45~80분)", None),
    ("30분마다", 30),
    ("60분마다", 60),
    ("90분마다", 90),
]
INTERVAL_MAP = {label: minutes for label, minutes in INTERVALS}


def show_popup(title, header, desc):
    body = f"{header}\\n\\n{desc}"
    script = (
        f'display dialog "{body}" '
        f'buttons {{"완료"}} '
        f'with title "{title}"'
    )
    subprocess.run(["osascript", "-e", script])


class StretchApp(rumps.App):
    def __init__(self):
        super().__init__("🧘", quit_button=None)
        self.paused = False
        # None이면 45~80분 랜덤, 정수면 해당 분 고정
        self.interval_fixed = None
        # '알림 간격' 서브메뉴 항목 생성 (현재 선택지에 체크 표시)
        self._interval_items = []
        for label, _minutes in INTERVALS:
            item = rumps.MenuItem(label, callback=self.set_interval)
            item.state = 1 if INTERVAL_MAP[label] == self.interval_fixed else 0
            self._interval_items.append(item)
        self.menu = [
            ("알림 간격", self._interval_items),
            "일시정지",
            None,
            "앱 종료",
        ]
        self._timer_thread = threading.Thread(target=self._timer_loop, daemon=True)
        self._timer_thread.start()

    def _timer_loop(self):
        # 최초 실행 시 10초 후 첫 팝업
        first = True
        while True:
            if first:
                wait = 10  # 최초 실행 시 10초 후 첫 팝업
                first = False
            elif self.interval_fixed is None:
                wait = random.randint(INTERVAL_MIN, INTERVAL_MAX)
            else:
                wait = self.interval_fixed * 60
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

    def set_interval(self, sender):
        # 선택한 간격으로 변경하고 체크 표시 갱신 (다음 알림 주기부터 적용)
        self.interval_fixed = INTERVAL_MAP[sender.title]
        for item in self._interval_items:
            item.state = 1 if INTERVAL_MAP[item.title] == self.interval_fixed else 0

    @rumps.clicked("앱 종료")
    def quit_app(self, _):
        import os
        plist = os.path.expanduser("~/Library/LaunchAgents/com.user.stretchreminder.plist")
        subprocess.run(["launchctl", "unload", plist], capture_output=True)
        rumps.quit_application()


if __name__ == "__main__":
    StretchApp().run()
