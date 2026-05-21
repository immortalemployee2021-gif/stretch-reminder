# 🧘 스트레치 리마인더

45~80분 사이 랜덤으로 스트레칭을 알려주는 맥 메뉴바 앱.

## 설치

```bash
git clone https://github.com/<your-username>/stretch-reminder.git
cd stretch-reminder
bash install.sh
```

> Homebrew가 없으면 설치 안내가 표시됩니다.

설치 후 상단 메뉴바에 **🧘** 아이콘이 나타납니다.  
맥을 켤 때마다 자동으로 실행됩니다.

## 메뉴

| 항목 | 설명 |
|------|------|
| 일시중지 / 재개 | 회의 중 알림 끄고 싶을 때 |
| 종료 | 앱 완전 종료 |

## 팝업 즉시 테스트

```bash
python3 app.py --test
```

5초 후 팝업이 뜨면 정상입니다.

## 스트레칭 팁 수정

`tips.py` 파일을 열어 직접 편집하면 됩니다.

## 제거

```bash
bash uninstall.sh
```
