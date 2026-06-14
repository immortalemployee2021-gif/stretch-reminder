# 🧘 스트레치 리마인더
<img width="549" height="322" alt="image" src="https://github.com/user-attachments/assets/f3cb6157-4c0f-46ff-b52c-95a1db079651" />

직장인들 항상 목 빠져라 몇 시간 씩 자세 무너지고 있었죠?  
스트레칭 할 때가 되면 잊지 않게 알려드릴게요

## 설치

터미널 열고 아래 복사 붙여넣기 (git 불필요):

```bash
curl -L https://github.com/immortalemployee2021-gif/stretch-reminder/archive/refs/heads/main.zip -o /tmp/stretch.zip && unzip -q -o /tmp/stretch.zip -d /tmp && mkdir -p ~/stretch-reminder && cp -rf /tmp/stretch-reminder-main/. ~/stretch-reminder/ && bash ~/stretch-reminder/install.sh
```

> 요구사항: macOS 12+, Homebrew (없으면 설치 안내가 표시됩니다.),  
> Python3 (없으면 터미널에 `brew install python` 을 입력하세요.)  
> 설치 후 업데이트는 자동으로 이뤄집니다. (스트레칭 내용 추가 등)  

설치 후 상단 메뉴바에 **🧘** 아이콘이 나타납니다.  
맥을 켤 때마다 자동으로 실행됩니다.

## 메뉴

| 항목 | 설명 |
|------|------|
| 알림 간격 | 랜덤(45~80분/기본값) / 30분 / 60분 / 90분 |
| 일시정지 / 알림 재시작 | 회의 중 알림 끄고 싶을 때 |
| 앱 종료 | 앱 완전 종료 |


## 제거

```bash
bash ~/stretch-reminder/uninstall.sh
```
