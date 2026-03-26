# 기술명세: 헤드셋 버튼 → 음성 입력 자동화
**작성일**: 2026-03-26  
**대상 기기**: Samsung Galaxy S25 Ultra  
**작성 맥락**: Termux에서 시도 후 PC Claude에게 이관

---

## 목표

어떤 앱 화면에서든 헤드셋(Buds Pro / Plantronics Voyager) 버튼 한 번으로:
1. 현재 화면의 채팅 입력창에 커서 위치
2. 삼성 키보드 마이크(STT) 활성화
3. 말하면 텍스트 입력

---

## 기기 환경

| 항목 | 값 |
|------|-----|
| 기기 | Samsung Galaxy S25 Ultra |
| OS | Android 15 (One UI 7) |
| 해상도 | 3088 × 1440 |
| Termux | 설치됨 |
| Termux:API | 설치됨 |
| MacroDroid | 설치됨, 접근성 서비스 ON |
| ADB | Termux에 설치됨 (android-tools) |
| 헤드셋 | Samsung Buds Pro + Plantronics Voyager |

---

## 오늘 시도한 것들 (실패/성공 기록)

### ❌ 1. ADB 무선 디버깅 페어링 (Termux → 자기 자신)
- **시도**: `adb pair 100.103.250.45:PORT CODE`
- **결과**: `protocol fault (couldn't read status message): Success`
- **원인**: Android 15에서 동일 기기 셀프 ADB 페어링 차단됨
- **결론**: Termux에서 자기 폰으로 ADB 불가

### ❌ 2. termux-am (Android Activity Manager)
- **시도**: `termux-am start -a android.speech.action.RECOGNIZE_SPEECH`
- **결과**: `Could not connect to socket: No such file or directory`
- **원인**: Termux AM 소켓 서버(`/data/data/com.termux/files/apps/com.termux/termux-am/am.sock`)가 미생성
- **결론**: Termux 앱이 AM 소켓 서버를 안 띄운 상태. 해결 미완

### ✅ 3. termux-speech-to-text
- **시도**: `termux-speech-to-text`
- **결과**: Google 음성인식 팝업 뜨고 말하면 plain text 리턴
- **예시 출력**: `tell her to walk up go chicken deal I forgot about`
- **형식**: JSON 아님, plain text 직접 출력
- **결론**: 작동함. 이걸 기반으로 스크립트 만듦

### ✅ 4. headset-mic.sh 스크립트 (생성 완료)
```bash
# 경로: ~/bin/headset-mic.sh
#!/bin/bash
result=$(termux-speech-to-text 2>/dev/null)
if [ -n "$result" ]; then
    echo "$result" | termux-clipboard-set
    termux-toast "$result"
fi
```
- 테스트 완료: 음성 인식 → 클립보드 복사 → toast 알림
- **남은 문제**: 헤드셋 버튼 트리거 연결 안 됨

### ⚠️ 5. MacroDroid 연동 (부분 완료)
- 매크로 "삼성채팅마이크" 생성됨
- 트리거: 미디어 버튼 ✅
- 액션: 셸 스크립트 → 경로 설정
- **문제**: MacroDroid 셸 스크립트 액션은 Termux 환경이 아님
  - `termux-speech-to-text` PATH 못 찾음
  - Termux 바이너리 경로: `/data/data/com.termux/files/usr/bin/`
  - MacroDroid에서 직접 실행 시 이 PATH가 없음
- **미해결**: MacroDroid → Termux 스크립트 실행 방법

---

## PC Claude가 해결할 수 있는 방법들

### 방법 A: PC ADB → 폰 직접 제어 (권장)

PC에서 폰으로 ADB 연결은 정상 작동함 (동일기기 제한 없음).

```bash
# PC에서 실행
adb connect 100.103.250.45:34367  # 폰 IP:무선디버깅 포트

# 연결 후 탭 명령
adb shell input tap 80 2820  # 삼성 키보드 마이크 버튼 (S25 Ultra 추정 좌표)
```

**PC가 할 수 있는 것:**
- `adb shell input tap X Y` — 화면 탭
- `adb shell input keyevent KEYCODE_HEADSETHOOK` — 헤드셋 버튼 이벤트 감지
- `adb shell uiautomator dump` — 현재 화면 UI 요소 덤프 → 입력창 좌표 자동 탐지
- UIAutomator로 입력창을 텍스트/클래스로 찾아서 탭

**UIAutomator 입력창 자동 탐지 (좌표 하드코딩 불필요):**
```bash
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml
# XML에서 EditText 노드 찾아 bounds 파싱 → 탭 좌표 계산
```

### 방법 B: MacroDroid Intent 방식 (PC 불필요)

MacroDroid에서 Termux 스크립트를 Intent로 실행:

```
액션: 인텐트 전송
  패키지: com.termux
  클래스: com.termux.app.RunCommandService  
  액션: com.termux.RUN_COMMAND
  Extra:
    com.termux.RUN_COMMAND_PATH = /data/data/com.termux/files/home/bin/headset-mic.sh
    com.termux.RUN_COMMAND_BACKGROUND = true
```

사전 조건: `allow-external-apps = true` (이미 설정됨, termux.properties 확인)

### 방법 C: Shizuku 활용 (termux-bridge에 이미 설치됨)

`~/termux-bridge/local/shizuku.sh` 존재.  
Shizuku = 루트 없이 ADB급 권한.  
`adb shell` 수준 명령을 Termux에서 직접 실행 가능.

---

## 현재 파일 상태

```
~/bin/headset-mic.sh          ✅ 생성 완료, 테스트 완료
~/.termux/termux.properties   allow-external-apps = true 설정됨
MacroDroid                    설치됨, 접근성 ON, 매크로 생성됨
```

---

## 권장 구현 순서 (PC Claude용)

1. **PC에서 ADB 연결**
   ```
   adb connect 100.103.250.45:34367
   ```
   (폰에서 무선 디버깅 ON 상태여야 함)

2. **UIAutomator로 현재 화면 입력창 좌표 자동 탐지 스크립트 작성**

3. **삼성 키보드 마이크 버튼 정확한 좌표 확인**
   ```
   adb shell uiautomator dump → XML 파싱
   ```

4. **헤드셋 버튼 감지 방법 결정**
   - MacroDroid 미디어 버튼 트리거 → Termux Intent 실행
   - 또는 `adb shell getevent` 모니터링

5. **전체 파이프라인 연결**
   ```
   헤드셋 버튼 → MacroDroid → Intent → Termux 스크립트
   → termux-speech-to-text → clipboard → 붙여넣기
   ```

---

## 참고: 삼성 키보드 마이크 버튼 위치

- S25 Ultra 해상도: 3088 × 1440
- 키보드 마이크 버튼: 좌측 하단 (사용자 확인)
- 추정 좌표: X=80, Y=2820 (±50px, 기기에서 확인 필요)
- UIAutomator dump로 정확한 좌표 확인 가능

---

## 핵심 제약

- Termux에서 자기 폰 ADB 셀프 페어링: Android 15에서 차단
- MacroDroid 셸 액션: Termux PATH 없음 → Intent 방식으로 우회
- termux-speech-to-text: 작동 확인, plain text 출력
- 삼성 키보드 마이크: 접근성 트리에 안 잡힐 수 있음 → 좌표 탭이 더 안정적
