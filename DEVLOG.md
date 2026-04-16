# termux-bridge 개발일지

> **구 이름:** playwright-bot (2026-01-04 ~ 2026-02-26)

## 2026-04-16 | 윈도우 강제 업데이트 → 폰 단독 세션 — 환경 진단 및 정리

### 배경
4월 14일 마이크로소프트 패치 화요일 (KB5083769) 대규모 배포.
167개 취약점 수정 + Secure Boot 변경으로 **이틀 연속 강제 재부팅** 발생.
WSL2 세션 강제 종료 → 폰 단독으로 Claude Code 세션 진행.

2026-03-16 패러다임 전환 이후 폰이 SSH 클라이언트로만 쓰이다 보니,
폰 직접 Claude Code 환경이 오래간만이었다. 환경 자체를 다시 점검하는 계기가 됨.

### 진단 결과 (시작 시점)

| 항목 | 수치 | 판정 |
|------|------|------|
| RAM 여유 | 2.4GB / 11GB (21%) | ✅ |
| Swap 사용 | 6.5GB / 12GB (53%) | ⚠️ 과부하 |
| 배터리 | 58%, 32.6°C | ✅ |
| 전류 드레인 | -2.0A | ⚠️ 높음 |
| 온도 | 32.6°C | ✅ |

### 원인 파악
- **Termux:GUI** — 쓰지 않는데 백그라운드에서 32% 배터리 잡아먹고 있었음
- **tts-server.sh** — PC 꺼진 상태에서 `nc -l 9876` 무한루프 대기 중
  - TTS 서버는 텔레그램 봇 → PC → SSH 역터널 → 폰 TTS 구조
  - PC 꺼지면 연결 안 오는데도 루프 살아있음

### 조치
```
am start -a android.intent.action.DELETE -d package:com.termux.gui
→ Termux:GUI 삭제
```
KDE Connect도 이번에 불필요함 확인 → 삭제 결정 (PC 켜지면 ADB로 처리)

### 삭제 후 결과

| 항목 | 삭제 전 | 삭제 후 | 변화 |
|------|---------|---------|------|
| RAM 여유 | 2.4GB | 3.7GB | +1.3GB ✅ |
| Swap 사용 | 53% | 24% | 절반 ✅ |
| 온도 | 32.6°C | 29.1°C | -3.5°C ✅ |
| 전류 | -2.0A | -1.1A | ✅ |

### 앱 티어 정리 (이번 세션에서 확립)

| 티어 | 도구 |
|------|------|
| S — 핵심 인프라 | Tailscale, RustDesk, ADB, Termux |
| A — 접속 레이어 | Mosh, SSH |
| B — AI 작업 | Claude Code, Aider, DeepSeek |
| C — GPU 인프라 | Vast.ai, RunPod |
| Samsung 레이어 | Good Lock, Galaxy AI, 그리기 어시스트, Samsung 키보드+STT, 통화녹음+텍스트변환, 화면녹화 |

### 확인된 Termux 단독 한계
- `pm list packages`, `dumpsys`, `/data/data/` — 전부 권한 차단
- Android 앱 레벨 프로세스 목록 불가
- ADB 없이 앱 삭제 불가 (Intent 트리거로 UI 호출만 가능)
- 저장공간 수치 접근 불가

### PC 켜지면 할 것
- `adb shell pm uninstall com.android.chrome` — Chrome 삭제
- `adb shell pm uninstall com.kde.kdeconnect_tp` — KDE Connect 삭제
- `apt upgrade` — 30개+ 패키지 업그레이드
- `pip install --upgrade` — 8개 패키지 업그레이드
- `adb shell pm list packages -3` — 앱 전체 목록 뽑아서 불필요한 거 정리

### 소결
WSL+ADB 환경과 폰 직접 환경은 완전히 다른 세계.
패러다임 전환(2026-03-16) 이후 폰이 클라이언트로만 쓰이다 보니
폰 단독 Claude Code가 낯설어진 것. 오늘이 좋은 재점검 기회였다.

---

## 2026-03-27 | 태블릿 (Tab S9) ADB 무선 연결 개통

### 목표
폰(S25 Ultra)과 동일한 ADB 무선 환경을 태블릿(Tab S9)에도 구축 → 병렬 작업 2-디바이스 체제

### 과정
1. `adb devices` 로 WSL 직접 연결 시도 → 태블릿 미감지
2. `cmd.exe /c "C:\\platform-tools\\adb.exe devices -l"` Windows adb로 확인 → `R54W900AH4Z device` 태블릿 인식
3. `adb -s R54W900AH4Z tcpip 5555` → TCP 모드 전환
4. 태블릿 Tailscale IP 확인: `tun0` 인터페이스에 `100.74.21.77`
5. `adb connect 100.74.21.77:5555` → 연결 성공
6. `~/.tablet_ip` 파일에 IP 저장

### 확정 디바이스 맵

| 기기 | 모델 | ADB 주소 | IP 저장 파일 |
|------|------|----------|-------------|
| 폰 | SM_S938N (S25 Ultra) | `100.103.250.45:5555` | `~/.phone_ip` |
| 태블릿 | SM_X716N (Tab S9) | `100.74.21.77:5555` | `~/.tablet_ip` |

### ADB 기기 구분 방법
```bash
adb -s 100.103.250.45:5555 shell ...   # 폰
adb -s 100.74.21.77:5555 shell ...    # 태블릿
```

### 의미
폰 + 태블릿 동시 ADB 무선 제어 → 박씨 병렬 2-디바이스 작업 인프라 완성.
집 PC WSL2가 두 기기 모두 관제.

---

## 2026-03-21 | TTS 브릿지 원클릭 통합 (tts-bridge.sh)

### 문제
- TTS 서버 시작 + SSH 역방향 터널 + PC 접속이 각각 수동 3단계였음
- Termux 탭 두 개 이상 필요하고, alias 없이 긴 ssh 명령 직접 입력

### 해결
`tts-bridge.sh` 하나로 통합:
1. `tts-server.sh` nohup bg 시작
2. `exec ssh -R 9876:localhost:9876 ... PC` → 탭 하나에서 완료

### PC 측 추가
`~/.bashrc`에 `tts()` 함수 + `cc-tts` alias 추가:
```bash
tts "폰이 읽어줘"
cc-tts "Claude 프롬프트"
```

### setup.sh 변경
`set_alias` 함수 추가 → `alias pc='~/termux-bridge/tts-bridge.sh'` 자동 설치/교체

### 사용 플로우
```
Termux: pc (엔터 한번)
  → TTS 서버 bg 시작
  → PC SSH 연결 + 역방향 터널 (9876)
  → PC 쉘에서 tts "읽어줘" 하면 폰이 읽어줌
```

---

## 2026-01-04 | 초기 구축 완료

### 목적

Termux 환경에서 Claude가 웹페이지(특히 WordPress)의 렌더링 결과를 **직접 확인**할 수 있도록 자동 스크린샷 봇 구축.

### 배경

- Claude MCP Desktop은 Puppeteer로 브라우저를 실시간 확인 가능
- Termux Claude는 이 기능이 없어서 사용자가 매번 수동 스크린샷 필요
- 수정 → 확인 → 피드백 루프에서 사용자 노동 제거가 목표

### 시도한 방법들

#### 1. proot-distro + Ubuntu + Playwright (실패)

```bash
proot-distro install ubuntu
apt install nodejs npm chromium-browser
npm install playwright-core
```

**결과:** `double free or corruption` 오류
- proot 환경에서 Chromium 메모리 관리 호환성 문제
- 다양한 Chrome flag 조합 시도했으나 해결 안 됨

#### 2. Termux Native + Playwright (실패)

```bash
pkg install chromium  # x11-repo에서
npm install playwright-core
```

**결과:** `Unsupported platform: android` 오류
- Playwright가 Android 플랫폼을 공식 지원하지 않음
- 플랫폼 감지 단계에서 차단됨

#### 3. Termux Native + CDP 직접 연결 (성공)

Playwright 라이브러리 우회, Chrome DevTools Protocol 직접 사용

```bash
pkg install chromium  # from x11-repo
npm install ws        # WebSocket only
```

**결과:** 성공!

### 최종 구성

| 컴포넌트 | 선택 | 이유 |
|----------|------|------|
| 환경 | Termux Native | proot 메모리 이슈 회피 |
| 브라우저 | Chromium 143 (x11-repo) | Termux 공식 패키지 |
| 프로토콜 | CDP (Chrome DevTools Protocol) | Playwright 플랫폼 제한 우회 |
| 의존성 | ws (WebSocket) | 최소 의존성 |

### 핵심 코드 구조

```
termux-bridge/
├── screenshot.js    # CDP 기반 스크린샷 봇
├── screenshots/     # 출력 디렉토리
├── package.json
└── DEVLOG.md
```

### 사용법

```bash
cd ~/playwright-bot
node screenshot.js <URL>
```

### 동작 흐름

1. Chromium headless 모드로 실행 (`--remote-debugging-port=9222`)
2. CDP WebSocket 연결
3. 페이지 네비게이션
4. Full-page 스크린샷 캡처
5. PNG 파일 저장

### 테스트 결과

```
URL: https://dtslib-papyrus.vercel.app
결과: 성공
파일: dtslib_papyrus_vercel_app_2026-01-04T06-16-08.png (57KB)
```

### 의의

| Before | After |
|--------|-------|
| 사용자가 브라우저 열기 | Claude가 자동 실행 |
| 사용자가 스크린샷 찍기 | Claude가 자동 캡처 |
| 사용자가 이미지 업로드 | Claude가 직접 확인 |
| 사용자가 문제점 설명 | Claude가 직접 판단 |

**결론:** Claude에게 "눈"을 부여. 수정-확인-피드백 루프에서 사용자 개입 최소화.

### 한계

- MCP Desktop처럼 실시간 연동은 아님 (수동 실행 필요)
- 로그인 필요한 페이지는 추가 구현 필요
- 동적 콘텐츠는 대기 시간 조정 필요할 수 있음

### 향후 개선 → v2.0에서 해결됨

- [ ] WordPress 로그인 세션 처리 → 의도적 배제 (credential 저장 = 보안 리스크)
- [x] 모바일/데스크톱 뷰포트 전환 → v2.0 QA에서 구현
- [x] 여러 URL 배치 처리 → v2.0 QA에서 26사이트 일괄 처리

---

## 2026-02-10 | v2.0 — QA 시스템 전면 개편

### 변경 사항

**v1.0 → v2.0 핵심 전환:**
- 단일 URL 스크린샷 도구 → 26사이트 자동 검증 시스템
- 로컬 실행 전용 → GitHub Actions 기반 (Daily 06:00 UTC)
- 이미지만 출력 → 구조화 JSON + Markdown 리포트 + 스크린샷

### 새 아키텍처

```
실행: GitHub Actions (Ubuntu + Playwright)
  → 26 sites × Desktop + Mobile 스크린샷
  → 사이트별 링크 체크 (최대 50개/사이트)
  → 콘솔 에러 수집

저장:
  → screenshots/ → Actions Artifact (14일 보관, Git 미커밋)
  → runs/<runId>/summary.json + sites.json + report.md → Git 커밋
  → runs/index.json → 최근 5회 run 인덱스

표시:
  → Papyrus docs/qa/index.html (Dark+Gold 테마)
  → raw.githubusercontent.com fetch (토큰 불필요)
  → 3 views: Overview / Site Detail / Search
```

### 해결된 문제들

| 문제 | 해결 |
|------|------|
| 스크린샷 Git 폭발 (52 JPG/run × daily) | Artifact 분리, Git에는 JSON만 |
| 크로스 레포 push (토큰/권한) | raw fetch로 대체, push 불필요 |
| SVGAnimatedString 링크 체크 버그 | `typeof h !== 'string'` 가드 |
| Actions push race condition | `git pull --rebase` 추가 |

### 파일 구조 (v2.0)

```
termux-bridge/
├── .github/workflows/qa-snapshot.yml  ← Actions 워크플로우
├── qa/
│   ├── check.js                       ← 메인 QA 엔진 (302줄)
│   └── urls.json                      ← 26 sites, 3-tier
├── runs/                              ← 자동 생성 결과
│   ├── index.json                     ← 최근 5 run 인덱스
│   └── <runId>/
│       ├── summary.json
│       ├── sites.json
│       └── report.md
├── 00_TRUTH/
│   ├── _inherit.json
│   ├── index.md
│   └── automation-boundary.md         ← 자동화 경계 선언
├── snap.js                            ← 로컬 CDP 도구 (Termux)
├── screenshot.js                      ← 로컬 CDP 스크린샷
├── screenshot-mobile.js               ← 로컬 모바일 CDP
├── run-snap.sh                        ← 로컬 래퍼
├── docs/                              ← Staff Office (비밀번호 갤러리)
├── package.json
├── DEVLOG.md
└── .gitignore
```

### 두 가지 운영 모드

| 모드 | 환경 | 용도 |
|------|------|------|
| **Actions QA** (Primary) | Ubuntu + Playwright | 26사이트 일괄 검증 + JSON 커밋 |
| **Local CDP** (Secondary) | Termux + Chromium + ws | 개발 중 단일 URL 빠른 확인 |

### 실행 검증

```
2026-02-10 1차: 20 PASS / 6 WARN / 0 FAIL / 14 broken links
2026-02-10 2차: 20 PASS / 6 WARN / 0 FAIL / 14 broken links
→ 연속 2회 성공, index.json 누적 확인
→ Papyrus 대시보드 raw fetch 정상
```

### Automation Boundary

> 이 시스템은 "증거 생산"까지 자동화한다. "판단"과 "수정"은 인간 몫이다.

상세: [`00_TRUTH/automation-boundary.md`](./00_TRUTH/automation-boundary.md)

---

## 2026-02-26 | 이름 변경 — playwright-bot → termux-bridge

### 변경 이유

v1 역할(CDP 스크린샷 도구)을 넘어 "Termux 모바일 개발 필수 도구 모음"으로 역할이 확장됨.
"PC ↔ Termux 간극을 메우는 다리"가 실제 정체성이므로 이름도 맞춤.

### 추가된 레이어

- `install/` — 유니버설 인스톨러 + BOM 원장
- `local/shizuku.sh` — Shizuku/ADB 시스템 제어 도구
- `install/bom.json` — 검증된 패키지 원장 (phoneparis baptism sync_target)

---

## 2026-03-12 | 아키텍처 확정 — phoneparis 맞춤 프로그램 생산 구조

### 배경

phoneparis 맞춤 프로그램 시스템의 전체 구조를 논의하며 세 레이어의 역할이 명확히 정의됨.

### 확정된 아키텍처

```
[termux-bridge]              ← General Ledger / 기술코드 생산 센터
  bom.json (verified 원장)
  install.sh (환경 세팅)
  CLAUDE.md §3 (세션 컨텍스트)
         ↓ posting (bom.json → packages.json)
[phoneparis/tools/baptism/]  ← Bridge Layer / 상품 BOM
  packages.json (고객용 패키지 명세)
         ↓ 조합
[APK Lab]         [DTSLIB Studio PWA]
  Axis, Pen,        Lecture Shorts/Long,
  Capture,          Auto Shorts,
  Subtitle,         Clip Shorts ...
  Wavesy, TTS ...
         ↓ 라이프스타일 매핑
[phoneparis 맞춤 프로그램]    ← 고객 제품
```

### 세 레이어 역할 분담

| 레이어 | 역할 | 핵심 파일 |
|--------|------|-----------|
| termux-bridge | 실제 검증된 도구만 기록. 새 기술 조합 개발·검증 | `bom.json`, `install.sh` |
| baptism | 검증된 목록을 고객용 BOM으로 변환. 조합 브릿지 | `packages.json` |
| APK Lab | 시스템 권한·오프라인·백그라운드 필요한 네이티브 앱 | F-Droid → APK 파이프라인 |
| DTSLIB Studio | 브라우저 즉시 실행. ffmpeg WASM 기반 | PWA 4종 |

### 콘텐츠 조합 원칙

APK (오프라인·시스템 접근 필요) + PWA (즉시 실행·설치 불필요) 두 풀에서 라이프스타일에 맞게 픽앤믹스.

예시:
- 크리에이터 타입 → Auto Shorts + Wavesy + TTS + Capture
- 강의 제작 타입 → Lecture Shorts/Long + Subtitle
- 생산성 타입 → Pen + Liner + ChronoCall

### 슬로건 ↔ 아키텍처 대응

> "폰 하나로 AI를 **쓴다**. **만든다**. **움직인다**."

| 슬로건 | 담당 레이어 |
|--------|------------|
| 쓴다 | phoneparis (제품, 고객 인터페이스) |
| 만든다 | termux-bridge (인프라, 기술코드 생산) |
| 움직인다 | APK Lab + DTSLIB Studio (실행 산출물) |

### 상시 작업 3종 세트

| 레포 | 역할 |
|------|------|
| termux-bridge | 인프라 검증 + BOM 원장 관리 |
| phoneparis | baptism BOM + 맞춤 프로그램 조합 |
| dtslib (APK Lab + Studio) | 네이티브 앱 + PWA 생산 |

---

*Updated: 2026-03-13*

---

## 2026-03-13 | Playwright 위상 재정립 — GUI 자동화 근본 레이어

### 배경

티스토리 블로그 다계정 스킨 일괄 작업 중 Claude + Playwright MCP 동작 장면을 보며 개념 정리 세션 진행.

### 핵심 정리

#### Playwright란?

> **브라우저를 코드로 조종하는 도구**

사람이 손으로 하는 것(클릭, 입력, 이동)을 코드로 대체.
API 없는 플랫폼(티스토리, 네이버, YouTube)도 자동화 가능.

#### Playwright vs Claude in Chrome

| | Playwright | Claude in Chrome |
|--|--|--|
| 조작 방식 | DOM 직접 타겟 | 화면 보고 마우스/키보드 |
| 속도 | 빠름 | 느림 |
| 안정성 | 안정적 | UI 바뀌면 실패 가능 |
| 토큰 소비 | 적음 | 많음 (스크린샷 분석) |
| 한계 | DOM에 없으면 못 함 | 뭐든 됨 |

**비유:**
- Playwright = 점자 (DOM 구조 손으로 더듬음)
- Claude in Chrome = 눈 (화면 보고 판단)

#### Puppeteer vs Playwright

| | Puppeteer | Playwright |
|--|--|--|
| 만든 곳 | Google (2017) | Microsoft (2020, Puppeteer 팀 영입) |
| 브라우저 | 크롬/엣지만 | 크롬+파이어폭스+사파리 |
| 결론 | 구버전 | 후속작, 더 안정적 |

새로 시작하면 Playwright. Puppeteer 배울 이유 없음.

#### 플랫폼별 자동화 가능 여부

| 플랫폼 | Playwright만으로? | 비고 |
|--------|-----------------|------|
| 티스토리 | ✅ 충분 | DOM 구조 일정, 반복 패턴 |
| 네이버 | ✅ 대부분 | 로그인·글쓰기·카페 다 됨 |
| YouTube | ⚠️ 80% | 업로드/설정은 됨. 퀄리티 판단은 Claude in Chrome |

### 이 레포 역사와 위상 재정립

```
2026-01-04   playwright-bot 탄생
             → Termux에서 GUI 못 보니까 눈 달기 시도
             → CDP 직접 연결로 해결 (Playwright 자체는 Android 미지원)
             → 이 레포의 출발점이자 근본

2026-02-14   QA 시스템으로 발전
             → Playwright (GitHub Actions) + CDP (Termux 로컬) 구조 완성

2026-02-26   playwright-bot → termux-bridge 이름 변경

2026-03-12   Shizuku 시스템 레이어 추가
```

**도구 진화 레이어:**

```
CDP (local/)       → 1세대: Termux GUI 자동화 해답
Playwright (QA)    → 2세대: Actions에서 돌아가는 풀스펙
Shizuku            → 3세대: 시스템 레이어로 확장
```

> Playwright/CDP가 이 레포에서 가장 먼저, 가장 근본적인 문제를 푼 도구.
> Shizuku보다 위상이 높음.

### Termux GUI 자동화 대안으로서의 위치

```
Claude in Chrome (진짜 눈)  →  PC 전용, 핸드폰 불가
Playwright                  →  Termux 불가 (Android 미지원)
CDP (snap.js)               →  ✅ Termux에서 돌아가는 점자
```

핸드폰 Termux에서 GUI 자동화가 필요하면 → CDP 직접 연결이 현재 유일한 답.

### 활용 맥락

- **정상 활용:** 본인 계정 반복 수작업 자동화 (지금 하고 있는 것)
- **어뷰징 활용:** 다계정 스팸 포스팅, 바이럴 마케팅, SEO 어뷰징 (플랫폼 약관 위반, 탐지 시 계정 정지)
- **차이:** 콘텐츠 품질 + 계정 수 + 목적

---

## 2026-03-13 | 역산 교재화 구상 — termux-bridge를 교본으로

### 배경

3개월 실전 사용 후 거꾸로 리뷰하면서 교재화 가능성 발견.

### 핵심 발견: 바텀업 학습법의 효과

```
전통적 방법:
개념 → 튜토리얼 → 예제 → 실전
(대부분 예제 단계에서 포기)

박씨 방법:
일단 씀 → 3개월 쌓임 → 거꾸로 개념 파악
(이미 체험했으니 개념이 즉시 붙음)
```

오늘 대화가 증거:
- Playwright 설명 → "아 그게 그거였구나" 즉시 연결
- CDP 설명 → snap.js 직접 쓰고 있었으니까 바로 이해
- 3개월 동안 몸으로 겪은 것들이 이미 체험으로 있음

### 새로운 교본의 구조

기존 프로그래밍 교육과 근본적으로 다름.

```
기존 교육:  언어가 중심 (Python 문법 → 변수 → 반복문 → 함수)
이 교본:    작업이 중심 (내가 뭘 하고 싶다 → 어떤 도구 → 어떻게 말하면 됨)
```

**십장 모델:**
- 십장은 못질 안 해도 됨
- 어디에 뭘 지어야 하는지 알면 됨
- 프로그래밍 언어 삭제, 지시하는 법만 남김

### 교본의 공리 (전제 조건)

```
0장. 전제
   1. Claude Max 구독 필수 (월 $100 / ~15만원)
      → 없으면 토큰 스트레스로 작업 흐름 끊김
      → 이게 없으면 교본 자체가 성립 안 함
   2. 핸드폰 + Termux (또는 PC)
   3. 코딩 지식 불필요
```

비교 대상은 개발자 고용. 개발자 월급 vs Claude Max 15만원.

### 교본 독자

```
기존 프로그래밍 책:  누구나 (책값만 있으면)
이 교본:            월 15만원 쓸 의향 있는 사람
                    코딩 배우기 싫은 사람
                    뭔가 만들고 싶은 사람
                    핸드폰만 있는 사람
```

박씨 자신이 독자의 원형.

### 교본 초안 구조

```
0장. 전제 — Claude Max + Termux + 코딩 지식 불필요
1장. 작업 정의 — "내가 뭘 반복하고 있나?" → 자동화 후보 찾기
2장. 도구 네비게이션 — 작업 종류별 어떤 도구 쓰는지만 파악
     파일/버전 관리  → git
     웹 자동화       → Playwright
     시스템 제어     → Shizuku
     판단 필요       → Claude in Chrome
3장. 지시하는 법 — 나쁜 지시 vs 좋은 지시, 실제 예시로만
4장. 결과 검증 — 잘 됐는지 어떻게 아나, 틀렸을 때 어떻게 말하나
```

### termux-bridge 이름의 재해석

```
termux  →  핸드폰으로 개발하고 싶다
bridge  →  모르는 것과 하고 싶은 것 사이의 다리
```

레포 이름 자체가 교본의 제목이었음.

> bridge는 언어를 배우는 다리가 아니라 하고 싶은 것을 실현하는 다리.
> 기존 교육: 다리 만드는 법 가르침
> 이 교본: 다리 건너는 법 가르침

### Claude Code가 2025년에 나온 것의 의미

이 교본이 기존에 존재할 수 없었던 이유:
말로 지시해서 코드가 나오는 게 2025년 이전엔 불가능했음.
박씨가 3개월 동안 실전으로 만든 것이 이 교본의 원재료.

---
