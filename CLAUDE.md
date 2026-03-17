---

## ⚡ 특별법 제1조: 플랫폼 자동화 도구 우선순위 (전 레포 공통 — 2026-03-18)

> **플랫폼 자동화 작업 시 Claude는 반드시 이 순서를 따른다. 임의로 스크립트 작성 금지.**

```
0순위: API / 터미널
  → 항상 먼저 확인. 되면 끝. 아래로 내려가지 않는다.

      ↓ API/터미널로 안 될 때만

1순위: Claude in Chrome (Chrome 확장)
  → GUI 클릭 필수 작업 (구글 콘솔, YouTube Studio, OAuth 등)
  → Claude가 브라우저 안에서 직접 보고 클릭. UI 변화 자동 적응.

2순위: Playwright MCP
  → Claude가 브라우저 외부에서 직접 조작

3순위: CDP/스크립트 (tools/ 경로)
  → 반복 배치. 사람 없이 야간 자동 실행.
```

**Claude 행동 규칙: 위 순서를 건너뛰고 스크립트를 먼저 짜는 것은 헌법 위반이다.**

---

# termux-bridge — Agent Protocol

---

## 헌법 제1조: 레포지토리는 소설이다
## 헌법 제2조: 매트릭스 아키텍처

> 상위 규정: `~/CLAUDE.md` 참조

---

## 1. Identity

| 항목 | 값 |
|------|-----|
| **Tier** | 인프라 (Infrastructure) |
| **Parent** | dtslib-papyrus (Group HQ) |
| **Type** | Termux ↔ PC 간극을 메우는 도구 모음 |
| **Repo** | https://github.com/dtslib1979/termux-bridge |
| **구 이름** | playwright-bot (2026-01-04 ~ 2026-02-26) |
| **Owner** | 박씨 100% |
| **Origin** | Claude Code가 자발적으로 생성 (2026-01-04) |

---

## 2. Purpose

> **PC에서 되는데 Termux에서 안 되는 것 → 이 레포가 해결한다.**

Galaxy 핸드폰 + Termux만으로 28개 레포를 운영하는 환경.
PC에서는 되는데 여기선 안 되는 것들이 생길 때마다 이 레포에 도구를 추가한다.

### 이름 변경 경위 (2026-02-26)

playwright-bot → **termux-bridge**

v1은 CDP 스크린샷 도구였지만, 역할이 "Termux 모바일 개발 필수 도구 모음"으로 확장됨.
"PC ↔ Termux 간극을 메우는 다리"가 정확한 이름.

---

## 3. Termux 환경 도구 현황

### 설치 완료 (시스템 패키지)

| 도구 | 버전 | 용도 |
|------|------|------|
| git | 2.53.0 | 버전 관리 |
| node | 24.13.0 | JS 런타임 |
| python | 3.12.12 | Python 런타임 |
| ffmpeg | 8.0.1 | 오디오/비디오 처리 |
| gh | 2.87.3 | GitHub CLI |
| imagemagick | 7.1.2 | 이미지 변환/처리 |
| jq | 1.8.1 | JSON 처리 |
| poppler | 26.02.0 | PDF 도구 (pdftotext, pdfinfo) |
| rclone | 1.73.1 | Google Drive 동기화 |
| rsync | 3.4.1 | 파일 동기화 |
| tree | 2.3.1 | 디렉토리 시각화 |
| wget | 1.25.0 | 파일 다운로드 |
| android-tools | adb | ADB 바이너리 (shizuku.sh 사전조건) |
| chromium | x11-repo | CDP 스크린샷용 |
| cmake + ninja | 빌드 도구 | 네이티브 컴파일 |
| termux-api | 0.59.1 | 핸드폰 하드웨어 접근 |

### 설치 완료 (Python)

| 패키지 | 버전 | 용도 |
|--------|------|------|
| pillow | 12.1.1 | 이미지 처리 (OpenCV 대체) |
| numpy | 2.2.5 | 수치 연산 |
| requests | 2.32.5 | HTTP 클라이언트 |

### 설치 완료 (npm)

| 패키지 | 용도 |
|--------|------|
| claude-code | Claude Code CLI |
| ws | CDP WebSocket 연결 |

### 설치 완료 (Android 앱)

| 앱 | 용도 | 레이어 |
|----|------|--------|
| Shizuku | ADB급 시스템 권한 — 루트 없이 | Termux 위 시스템 레이어 |

> **Shizuku 위상:**
> Termux(쉘/파일 레이어) 위에서 Android 시스템 API를 ADB 수준으로 제어.
> APK 설치, 권한 관리, 앱 제어 등 루트 없이 가능.
> `local/shizuku.sh` 로 Termux에서 직접 사용.

### 의도적으로 사용하지 않는 것

| 도구 | 이유 |
|------|------|
| Tasker | 코드로 만들 수 있는 걸 GUI 자동화 도구로 대체할 필요 없음. APK·PWA 직접 제작이 방향 |

### Termux에서 불가능 (우회 필요)

| 도구 | 이유 | 우회 방법 |
|------|------|----------|
| OpenCV | aarch64 빌드 실패 | Pillow 대체 |
| scipy | 빌드 실패 | numpy로 대체 |
| Puppeteer | Android 미지원 | CDP 직접 연결 |
| Playwright | Android 미지원 | GitHub Actions |
| Flutter | 미설치, 빌드 불가 | GitHub Actions CI |
| Docker | 커널 제약 | 불가 |
| Lighthouse | 빌드 실패 | Actions에서 실행 |

---

## 4. 레포 내 도구

### A. QA 시스템 — GitHub Actions (Primary)

| 항목 | 내용 |
|------|------|
| 대상 | 26개 사이트, 3-tier |
| 주기 | Daily 06:00 UTC |
| 산출물 | JSON + Markdown 리포트 + 스크린샷 |
| 대시보드 | dtslib.com/qa/ (Papyrus에서 raw fetch) |

### B. 로컬 CDP 도구 — Termux (Secondary)

| 파일 | 용도 |
|------|------|
| `local/snap.js` | 단일 URL CDP 스크린샷 |
| `local/screenshot.js` | 데스크톱 뷰포트 캡처 |
| `local/screenshot-mobile.js` | 모바일 뷰포트 캡처 |

### C. 시스템 제어 도구 — Shizuku + Wireless ADB

| 파일 | 용도 |
|------|------|
| `local/shizuku.sh` | APK 설치 · 권한 관리 · 앱 제어 · ADB 쉘 |

---

## 5. 파일 구조

```
termux-bridge/
├── CLAUDE.md                    ← AI 파싱 진입점
├── README.md                    ← 프로젝트 개요
├── DEVLOG.md                    ← 개발일지 (삽질 기록 보존)
├── package.json
│
├── install.sh                   ← 유니버설 인스톨러 (Termux·Ubuntu·macOS)
├── install/
│   ├── bom.json                 ← 검증된 패키지 원장 → phoneparis baptism 동기화
│   └── README.md
│
├── qa/                          ← QA 엔진 (Actions용)
│   ├── check.js                 ← 메인 엔진
│   └── urls.json                ← 26사이트 + ignore 화이트리스트
│
├── local/                       ← Termux 로컬 도구
│   ├── snap.js                  ← CDP 스크린샷
│   ├── screenshot.js
│   ├── screenshot-mobile.js
│   └── shizuku.sh               ← Shizuku/ADB 시스템 제어
│
├── runs/                        ← 자동 생성 QA 결과
│   ├── index.json
│   └── <runId>/
│
├── 00_TRUTH/
│   └── automation-boundary.md   ← 자동화 경계 선언
│
└── .github/workflows/
    └── qa-snapshot.yml          ← Daily QA 워크플로우
```

---

## 6. 설계 원칙

1. **PC ↔ Termux 간극을 메운다** — PC에서 되는 걸 여기서도 되게 만든다
2. **증거 생산까지만 자동화** — 판단과 수정은 사람 몫
3. **도구가 필요해지면 그때 만든다** — 미리 만들지 않는다
4. **시스템 패키지 우선** — pip/npm보다 pkg 패키지가 안정적

---

## 7. 크로스레포 연결

| 연결 | 용도 |
|------|------|
| dtslib-papyrus | QA 대시보드가 runs/ raw fetch |
| phoneparis | baptism BOM (`tools/baptism/config/packages.json`)의 원장 |
| 28개 전체 레포 | 이 도구 모음으로 개발/운영 |

---

## 8. 포스팅 규칙 (Ledger ↔ BOM 동기화)

> **이 레포 = 원장 (General Ledger).** 실제 설치/검증된 도구 목록.
> **phoneparis baptism = 상품 BOM.** 고객에게 제공하는 패키지 명세.

### 포스팅 방향

```
termux-bridge CLAUDE.md §3 (실제 설치 현황)
        ↓ posting
phoneparis/tools/baptism/config/packages.json (상품 BOM)
```

### 포스팅 트리거

| 이벤트 | 액션 |
|--------|------|
| 새 패키지 설치 성공 | CLAUDE.md §3 업데이트 → packages.json에 `verified: true` + 버전 추가 |
| 패키지 설치 실패 확인 | CLAUDE.md §3 "불가능" 추가 → packages.json `blocked` 섹션에 추가 |
| 패키지 버전 업데이트 | CLAUDE.md §3 버전 갱신 → packages.json `verified_version` 갱신 |

### Claude 세션 체크

새 도구 설치/제거 시: **"BOM 포스팅 완료했는가?"** 확인.
양쪽 불일치 발견 시: 경고 + 동기화 실행.

---

---

## 9. phoneparis 맞춤 프로그램 생산 구조 (2026-03-12 확정)

### 전체 아키텍처

```
[termux-bridge]              ← General Ledger / 기술코드 생산 센터
         ↓ bom.json → packages.json 포스팅
[phoneparis/tools/baptism/]  ← Bridge Layer / 상품 BOM
         ↓ 조합
[APK Lab]  +  [DTSLIB Studio PWA]
         ↓ 라이프스타일 매핑
[phoneparis 맞춤 프로그램]    ← 고객 제품
```

### 두 생산 풀

| 풀 | 특징 | 예시 앱 |
|----|------|---------|
| APK Lab | 네이티브. 시스템 권한·오프라인·백그라운드 | Axis, Pen, Capture, Subtitle, Wavesy, TTS, ChronoCall, Liner |
| DTSLIB Studio PWA | 브라우저 즉시 실행. ffmpeg WASM | Lecture Shorts/Long, Auto Shorts, Clip Shorts |

### 콘텐츠 조합 방식

라이프스타일 세그먼트 정의 → 해당 세그먼트 APK + PWA 조합 선택.

### 슬로건 ↔ 레이어

| "폰 하나로..." | 레이어 |
|--------------|--------|
| 쓴다 | phoneparis 고객 인터페이스 |
| 만든다 | termux-bridge 인프라 |
| 움직인다 | APK Lab + Studio 실행 산출물 |

### 상시 작업 3종 세트

| 레포 | 역할 |
|------|------|
| termux-bridge | 인프라 검증 + BOM 원장 |
| phoneparis | baptism BOM + 프로그램 조합 |
| dtslib | APK + PWA 생산 |

---

*Version: 2.3*
*Renamed: 2026-02-26 (playwright-bot → termux-bridge)*
*Updated: 2026-03-12 (Shizuku 추가, Tasker 제거, §9 phoneparis 아키텍처 확정)*
*Built with: Claude Code (Claude Opus 4.6)*

---

## Browser Runtime

> Parksy OS 2+2 매트릭스 — 이 레포 전담 브라우저

| 항목 | 값 |
|------|-----|
| **브라우저** | Google Chrome |
| **이유** | PC↔Termux 자동화 — 기술 튜토리얼 |
| **URL** | https://github.com/dtslib1979/termux-bridge |


---

## ⚡ 전역 컨텍스트 — 반드시 읽어라 (2026-03-16 갱신)

> **세션 시작 시 이 블록을 먼저 읽는다. 모든 하위 조항보다 우선한다.**

### 패러다임 전환 (특별법 제0조)

| | Before | After (지금) |
|---|---|---|
| 메인 기기 | 핸드폰 (Termux) | 집 PC (WSL2) |
| 보조 기기 | PC (원격 서버) | 핸드폰 (SSH 클라이언트) |
| 브라우저 자동화 | headless 우회, ADB 체인 | PC Chrome 직접 (Playwright headless=False) |
| 배치 작업 | 핸드폰 한 세션 | tmux 던져놓고 퇴근 |

### 죽은 패턴 (절대 부활 금지)
```
❌ headless Chromium 우회
❌ ADB 체인
❌ 핸드폰에서 CDP 흉내
❌ 세션 1개 제약 설계
```

### 현재 작업 표준
```
핸드폰 → Tailscale SSH → 집 PC WSL2 → Claude Code
텔레그램 봇 → tmux 배치 세션 (tg-image, tg-audio)
브라우저 자동화 → Windows Chrome Playwright headless=False
```

### SCM 자동화 개발 시퀀스 (진행 중)
```
1. 텔레그램 봇        ✅ 완료 (2026-03-16)
2. 티스토리 자동화    🔄 진행 중 — Playwright headless=False
3. 네이버 자동화      ⏳ 대기 — login.cjs PC-native 교체
4. YouTube 자동화     ⏳ 대기 — Draft injection, OAuth 정상화
5. Google 자동화      ⏳ 대기
   ↓
6. APK 업데이트       ⏳ 대기
7. 워크센터 레포 정비 ⏳ 대기 (28개)
8. 양산               ⏳ 대기
```

### 지금 당장 막힌 것
- 티스토리 19개 블로그 스킨 삽입 미완료 (player.html)
- 티스토리 25슬롯 서브도메인 미확보
- 관련 스크립트: `C:\Temp\tistory_auto_v2.py`

---
