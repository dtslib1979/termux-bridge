# termux-bridge 개발일지

> **구 이름:** playwright-bot (2026-01-04 ~ 2026-02-26)

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

*Updated: 2026-02-10*
