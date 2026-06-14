#!/usr/bin/env python3
"""화면 정중앙에 알림 창을 띄우는 헬퍼.

app.py가 subprocess로 호출한다.
NSAlert는 폰트 크기·텍스트 위치를 바꿀 수 없어, 레이아웃을 직접 제어하려고
커스텀 NSWindow로 구성한다. (별도 프로세스라 메인스레드 UI 제약도 자연히 해결)

레이아웃: [아이콘] 큰 제목  /  아래에 동작(header) + 설명(desc)  /  '완료' 버튼
키보드로는 닫히지 않고 마우스 클릭으로만 닫힌다.

사용법: python popup.py "<title>" "<header>" "<desc>"
"""
import os
import sys

import AppKit

# 레이아웃 상수 (pt)
W = 480           # 창 가로폭
MARGIN = 24
ICON = 72         # 아이콘 한 변
GAP_ICON = 16     # 아이콘과 제목 사이
GAP_ROW = 16      # 제목줄과 본문 사이
GAP_HEADER = 8    # header와 desc 사이
GAP_DESC = 18     # desc와 버튼 사이
BTN_W, BTN_H = 110, 32


class _ButtonHandler(AppKit.NSObject):
    """완료 버튼 클릭 시 모달 종료."""

    def done_(self, _sender):
        AppKit.NSApplication.sharedApplication().stopModal()


def _label(text, font, width, color):
    """주어진 폭에서 자동 줄바꿈되는 라벨과 그 높이를 만든다."""
    field = AppKit.NSTextField.alloc().initWithFrame_(
        AppKit.NSMakeRect(0, 0, width, 20)
    )
    field.setStringValue_(text)
    field.setFont_(font)
    field.setTextColor_(color)
    field.setBezeled_(False)
    field.setDrawsBackground_(False)
    field.setEditable_(False)
    field.setSelectable_(False)
    field.cell().setWraps_(True)
    field.cell().setLineBreakMode_(AppKit.NSLineBreakByWordWrapping)
    size = field.cell().cellSizeForBounds_(AppKit.NSMakeRect(0, 0, width, 10000))
    field.setFrameSize_(AppKit.NSMakeSize(width, size.height))
    return field, size.height


def main():
    title, header, desc = sys.argv[1], sys.argv[2], sys.argv[3]

    app = AppKit.NSApplication.sharedApplication()
    app.setActivationPolicy_(AppKit.NSApplicationActivationPolicyAccessory)

    # 라벨 생성 (높이는 텍스트 길이에 따라 결정)
    title_w = W - MARGIN * 2 - ICON - GAP_ICON
    body_w = W - MARGIN * 2
    title_field, title_h = _label(
        title, AppKit.NSFont.boldSystemFontOfSize_(19), title_w,
        AppKit.NSColor.labelColor(),
    )
    header_field, header_h = _label(
        header, AppKit.NSFont.boldSystemFontOfSize_(14), body_w,
        AppKit.NSColor.labelColor(),
    )
    desc_field, desc_h = _label(
        desc, AppKit.NSFont.systemFontOfSize_(13), body_w,
        AppKit.NSColor.secondaryLabelColor(),
    )

    row1_h = max(ICON, title_h)
    total_h = (
        MARGIN + row1_h + GAP_ROW + header_h + GAP_HEADER + desc_h
        + GAP_DESC + BTN_H + MARGIN
    )

    # 윈도우 (제목표시줄 숨김, 둥근 모서리)
    style = (
        AppKit.NSWindowStyleMaskTitled
        | AppKit.NSWindowStyleMaskFullSizeContentView
    )
    window = AppKit.NSWindow.alloc().initWithContentRect_styleMask_backing_defer_(
        AppKit.NSMakeRect(0, 0, W, total_h), style,
        AppKit.NSBackingStoreBuffered, False,
    )
    window.setTitlebarAppearsTransparent_(True)
    window.setTitleVisibility_(AppKit.NSWindowTitleHidden)
    window.setLevel_(AppKit.NSFloatingWindowLevel)
    for b in (
        AppKit.NSWindowCloseButton,
        AppKit.NSWindowMiniaturizeButton,
        AppKit.NSWindowZoomButton,
    ):
        btn = window.standardWindowButton_(b)
        if btn is not None:
            btn.setHidden_(True)

    content = window.contentView()

    # 좌표는 좌하단 원점 → 위에서부터 쌓기 위해 (total_h - top - h)로 변환
    y = MARGIN  # 현재까지 쓴 '위에서부터의' 거리

    # 1행: 아이콘 + 제목 (서로 세로 중앙 정렬)
    icon_top = y + (row1_h - ICON) / 2.0
    icon_view = AppKit.NSImageView.alloc().initWithFrame_(
        AppKit.NSMakeRect(MARGIN, total_h - icon_top - ICON, ICON, ICON)
    )
    icon_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon.png")
    image = AppKit.NSImage.alloc().initWithContentsOfFile_(icon_path)
    if image is not None:
        icon_view.setImage_(image)
        icon_view.setImageScaling_(AppKit.NSImageScaleProportionallyUpOrDown)
        content.addSubview_(icon_view)

    title_top = y + (row1_h - title_h) / 2.0
    title_field.setFrameOrigin_(
        AppKit.NSMakePoint(MARGIN + ICON + GAP_ICON, total_h - title_top - title_h)
    )
    content.addSubview_(title_field)

    y += row1_h + GAP_ROW
    header_field.setFrameOrigin_(AppKit.NSMakePoint(MARGIN, total_h - y - header_h))
    content.addSubview_(header_field)

    y += header_h + GAP_HEADER
    desc_field.setFrameOrigin_(AppKit.NSMakePoint(MARGIN, total_h - y - desc_h))
    content.addSubview_(desc_field)

    # 완료 버튼 (오른쪽 아래). keyEquivalent 기본값 ""이라 엔터로는 안 닫힘
    handler = _ButtonHandler.alloc().init()
    button = AppKit.NSButton.alloc().initWithFrame_(
        AppKit.NSMakeRect(W - MARGIN - BTN_W, MARGIN - 4, BTN_W, BTN_H)
    )
    button.setTitle_("완료")
    button.setBezelStyle_(AppKit.NSBezelStyleRounded)
    button.setTarget_(handler)
    button.setAction_("done:")
    content.addSubview_(button)

    # 화면 정중앙 배치
    screen = AppKit.NSScreen.mainScreen().frame()
    x = screen.origin.x + (screen.size.width - W) / 2.0
    wy = screen.origin.y + (screen.size.height - total_h) / 2.0
    window.setFrameOrigin_(AppKit.NSMakePoint(x, wy))

    app.activateIgnoringOtherApps_(True)
    window.makeKeyAndOrderFront_(None)
    window.makeFirstResponder_(None)  # 포커스 제거 → 스페이스로도 안 닫힘
    app.runModalForWindow_(window)


if __name__ == "__main__":
    main()
