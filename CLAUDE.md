<!-- DTSLIB-LAW-PACK-START -->
---

## 헌법 제1조: 레포지토리는 소설이다

> **모든 레포지토리는 한 권의 소설책이다.**
> **커밋이 문장이고, 브랜치가 챕터이고, git log --reverse가 줄거리다.**

- 삽질, 실패, 방향 전환 전부 남긴다. squash로 뭉개지 않는다.
- 기능 구현 과정 = 플롯 (문제→시도→실패→전환→해결)
- 레포 서사 → 블로그/웹툰/방송 콘텐츠로 파생 (액자 구성)

---

## ⚙️ 헌법 제2조: 매트릭스 아키텍처

> **모든 레포지토리는 공장이다.**
> **가로축은 재무 원장(ERP)이고, 세로축은 제조 공정(FAB)이다.**

### 가로축: 재무 원장 (ERP 로직)

커밋은 전표다. 한번 기표하면 수정이 아니라 반대 분개로 정정한다.

| 회계 개념 | Git 대응 | 예시 |
|-----------|----------|------|
| 전표 (Journal Entry) | 커밋 | `feat: 새 기능 구현` |
| 원장 (General Ledger) | `git log --reverse` | 레포 전체 거래 이력 |
| 계정과목 (Account) | 디렉토리 | `tools/`, `scripts/`, `assets/` |
| 회계 인터페이스 | 크로스레포 동기화 | 명시적 스크립트/매니페스트 |
| 감사 추적 (Audit Trail) | Co-Authored-By | AI/Human 협업 기록 |

### 세로축: 제조 공정 (FAB 로직)

레포는 반도체 팹이다. 원자재(아이디어)가 들어와서 완제품(콘텐츠)이 나간다.

| 제조 개념 | 레포 대응 | 예시 |
|-----------|----------|------|
| BOM (자재 명세) | 의존성 + 에셋 목록 | `pubspec.yaml`, `package.json`, `assets/` |
| 라우팅 (공정 순서) | 파이프라인 스크립트 | 빌드→테스트→배포 순차 실행 |
| WIP (재공품) | 브랜치 + Queue | `claude/*` 브랜치, `_queue/` |
| 수율 (Yield) | 빌드 성공률 | CI 통과율, 테스트 커버리지 |
| MES (제조실행) | 자동화 스크립트 | 동기화, 추출, 배포 도구 |
| 검수 (QC) | 테스트 + 리뷰 | `tests/`, 체크리스트 |

### 4대 원칙

1. **삭제는 없다, 반대 분개만 있다** — `git revert`로 정정. `reset --hard` 금지.
2. **증빙 없는 거래는 없다** — 커밋 메시지에 이유와 맥락. 크로스레포 이동은 명시적 스크립트로.
3. **BOM 확인 후 착공한다** — 의존성/에셋 명세 먼저, 공정 순서 명시 후 실행.
4. **재공품을 방치하지 않는다** — WIP 브랜치와 큐는 정기적으로 소화한다.

---

### 특별법 제0조: 패러다임 전환 (2026-03-16)

> **전환 이유: Claude Code가 메인 드라이버다.**
> Claude Code는 에이전트다. 이 에이전트가 가장 잘 돌아가는 환경(WSL2)에 모든 걸 맞춘다.
> Windows 환경은 무시한다. WSL2 기준으로 모든 작업을 설계한다.

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

---

### 특별법 제1조: 플랫폼 자동화 도구 우선순위 (2026-03-17)

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
<!-- DTSLIB-LAW-PACK-END -->

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

### 듀얼 레인 아키텍처 (2026-03-26 확정)
```
LANE 1: Phone (S25 Ultra)
  삼성 온디바이스 (대체 불가): STT 키보드, 통화녹음, 그리기 어시스트
  시스템/자동화: SSH → PC WSL2 경유

LANE 2: Tablet (Tab S9)
  대화면 방송 키트: 화면녹화, S Pen, RustDesk

LANE 3 (공기계): 폐기
  SSH+PC 구조로 존재 이유 소멸
  보안 분리 → 용도 분리로 재정의됨
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
