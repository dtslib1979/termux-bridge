# Parksy Log — 2026-05-02
## Parksy Air 동영상 강의 자동화 양산 라인 완성 (M0 + M1 통과)

---

## 한 줄 요약
> **박씨 1명 + AI 에이전트 군단으로 돌아가는 1인 미디어 제국 자동화 공장의 첫 번째 양산 라인 (Parksy Air) 가 오늘 완성됐다.**

---

## 시간순 작업

### Phase 0 (~1시간) — 진단
- 4개 트랙 병렬 조사 (web2video / 슬라이드 빌더 / AI성우+판서 / 산출물)
- 박씨 시스템 4계층 거꾸로 브리핑
  - 1차 텍스트 → 2차 인터랙티브 웹페이지 → 3차 AI 강의 영상 → 4차 N채널 배포
- 리팩토링 마스터 플랜 (29KB / 743줄) 작성 → 텔레그램 송부
- 진단 결과:
  - web2video: 5.3/10
  - 슬라이드 빌더: 4.75/10
  - AI성우+판서: 6.2/10
  - 산출물: 8.6/10

### Phase 1 (~30분) — 응급수술 (검증)
- ❗ 진단 정정사항 발견:
  - "action_mapper 미실행" → 사실 작동 중 (29/29 매핑)
  - "박씨 GPT-SoVITS 미디폴트" → 사실 디폴트 (tts_engine.py 자동 import)
  - "voice_filter v2 필요" → parksy_voice_filter.md 228줄 이미 박혀있음
- 즉 "근본 결함 없고 단지 연결만 일부 정리" 필요

### Phase 2 (~1시간) — P4 자동화 + Layer2 QC
- `tools/youtube/upload_youtube.py` 작성 (Python 래퍼)
- `tools/web2video/subtitle_generator.py` 작성 (script.json → SRT + burnin)
- `tools/web2video/audio_qc.py` 한국어 패치 (CER + 언어 자동 감지)
- `orchestrator.py` P3.7 자막 자동 통합
- `article_page.html` ?mode=slide URL 파라미터 처리
- `action_mapper.py` 셀렉터 양쪽 형식 (termux-bridge + article_page) 지원
- `numbers.py` → `samples/test_numbers_squared_cubed.py` (stdlib 충돌 해결)

### M0 통과 (12:00) — 베이스라인 1편
- 3슬라이드 빌드 → YouTube unlisted 업로드 검증
- **https://youtu.be/XBjdwZ00YRg**
- 1.9MB / 18.56초 / 1080×1920 / 30fps

### M1 통과 (12:15) — 풀런 E2E
- 29슬라이드 풀런 + YouTube 자동 업로드
- **https://youtu.be/7rLw67cfB_o**
- 4.8MB / 2분 10초 / 빌드 25분 13초

---

## 통합 검증 결과

### ✅ 작동 확인된 것
- action_mapper — 29/29 pointer_target 매핑 (.cover-title, h2.slide-title, .card-title)
- 박씨 GPT-SoVITS 음성 — parksy-tts core synthesize, 29개 wav 생성
- 박씨 딕션 — voice_filter.md 적용 ("이게 다다", "해봐라", "끝이다")
- Canvas 판서 — highlight/circle/underline
- 오프닝 영상 합성 — opening_latest.mp4 (10초)
- Telegram 자동 전송 — 4.8MB 영상
- YouTube 자동 업로드 — visualizer-parksy 채널 unlisted
- 자막 SRT — 29개 큐, 사이드카 .srt 파일

### 📊 Layer2 Whisper QC (한국어 CER)

| 등급 | 카운트 | 비율 |
|------|-------|------|
| 매우 양호 (CER < 15%) | 11/29 | 38% |
| 양호 (15~30%) | 8/29 | 28% |
| 개선 필요 (>30%) | 10/29 | 34% |
| **평균 CER** | **~22%** | — |

**최고**: step 24 "PC를 서버로 만든다 이게 다야" — CER 0% (완벽)

### ⚠️ 발견된 이슈
1. step_27 — 길이 비율 3.03 (Layer1 fail, 음성 너무 김)
2. step_15, 16 — CER 60%+ (음성 디그레이드, 원인 미파악)
3. 영어 부분 (step 21, 22) — Whisper가 박씨 영어 발음 못 잡음
   - **해결**: Chatterbox 다국어 헤드 사용 (박씨 본인이 정정한 역할 분담)

---

## 음성 파이프라인 역할 정정 (박씨 본인 정정 — 2026-05-02)

| 엔진 | 담당 | 박씨 본인 여부 |
|------|------|---------------|
| **GPT-SoVITS** | **박씨 본인 더빙** (한국어/영어) | ✅ 박씨 클론 |
| **Chatterbox** | **다국어 성우 더빙** (영/일/중/스페인) | ❌ 다른 화자 |
| **DiffSinger** | **가창 + 가상악기** (노래/음악) | — 성우 아님 |

이전 마스터 플랜에서 "박씨 RVC/영문 헤드"로 잘못 적은 부분을 박씨가 직접 정정. 다국어 더빙은 Chatterbox 담당.

---

## 자산 배치 (최종)

```
parksy-image/
├── tools/
│   ├── web2video/
│   │   ├── orchestrator.py        ← 메인 파이프라인 (P0~P4 + 자막)
│   │   ├── script_generator.py    ← P0 박씨 딕션 나레이션
│   │   ├── action_mapper.py       ← P0.5 DOM 셀렉터 매핑 (양쪽 형식 지원)
│   │   ├── extractor.py           ← P1 Playwright CDP + Canvas 판서
│   │   ├── tts_humanizer.py       ← P2 후처리
│   │   ├── audio_qc.py            ← Layer1 sox + Layer2 Whisper KR
│   │   ├── renderer.py            ← P3 ffmpeg 합성
│   │   ├── subtitle_generator.py  ← P3.7 자막 SRT (NEW)
│   │   └── comfyui_opening.py     ← 오프닝 (Vast.ai)
│   ├── youtube/
│   │   ├── upload_youtube.py      ← P4 Python 래퍼 (NEW)
│   │   ├── youtube-studio.js      ← Node.js 실행 엔진
│   │   ├── channels.json          ← 15채널 매핑
│   │   └── accounts/token_*.json  ← 채널별 토큰
│   └── mcp_slide_builder/
│       ├── page_service.py        ← 5단계 공정 (read→plan→fill→validate→render)
│       └── templates/
│           └── article_page.html  ← ?mode=slide URL 파라미터 (NEW)
└── samples/
    └── test_numbers_squared_cubed.py  ← stdlib 충돌 회피
```

---

## 양산 라인 흐름 (확정)

```
[입력]
  텍스트 (.txt) or 슬라이드 URL
        ↓
[1차: mcp_slide_builder]
  build_page() → docs/slides/article_xxx.html
        ↓
[2차: web2video orchestrator]
  --url ".../article_xxx.html?mode=slide"
        ↓
  P0 (script_generator)   — 박씨 딕션 나레이션 자동 생성
  P0.5 (action_mapper)    — DOM 셀렉터 매핑
  P0.6 (P0.5 결과 반영)
  P2 (tts_humanizer)      — 박씨 GPT-SoVITS 음성 합성
  P2.5                    — 실측 길이 → durationSec sync
  P1 (extractor)          — Playwright + Canvas 판서 녹화
  P3 (renderer)           — ffmpeg 합성 (오프닝 + 강의)
  P3.7 (subtitle)         — SRT 자막 자동 생성
  → Telegram 전송
        ↓
[P4: upload_youtube]
  visualizer-parksy 채널 unlisted 업로드
  → YouTube URL 반환
```

---

## 다음 단계 (박씨 결재 후)

### Phase 2 (인터랙티브 깊이) — 2주 예정
- article_page.html 코드 실행 영역 (xterm.js)
- "다음 단계" CTA + 진행도 localStorage
- 변수 입력 시뮬레이션
- 인포그래픽 10종 실제 구현

### Phase 3 (양산 라인 표준화) — 1주
- 28레포 매니페스트 (manifest.yaml)
- 배치 빌드 (`./run.sh --batch 28`)
- orchestrator 모듈 결합도 낮춤 (Stage 클래스)

### Phase 4 (QC + 배포 자동화) — 1주
- A/V 싱크 자동 검증
- 자막 burnin 옵션
- Chatterbox 다국어 통합 (영/일/중)
- 썸네일 자동 생성

### Phase 5 (28레포 풀 가동) — 지속
- cron 일일 자동 생성
- 시청 데이터 모니터링
- 회귀 테스트 (10개 골든 샘플)

---

## 교훈

1. **진단 결과 절반은 잘못된 정보** — 코드 직접 보기 전엔 평가 못 믿는다.
2. **시스템이 이미 거의 다 작동 중** — 박씨가 4개월 동안 쌓아놓은 게 그만큼 많다.
3. **양산 라인의 핵심은 "연결"** — 새 컴포넌트 작성보다 기존 컴포넌트 연결이 더 중요.
4. **음성 역할 정확히 분리** — SoVITS=본인, Chatterbox=다국어, DiffSinger=가창.
5. **Layer2 한국어 QC 추가하길 잘함** — 영어 전용은 박씨 음성 검증 못 함.

---

## 커밋

```
f807d71 chore: M1 마일스톤 완료 — Parksy Air 풀런 E2E 검증 + 산출물 .gitignore
efbf1ac feat: 강의 양산 라인 통합 강화 — slide-mode + Layer2 KR + 자막 자동
f3061e6 feat: Parksy Air P4 자동화 — YouTube 업로드 + 자막 SRT + 리팩토링 마스터 플랜
```

GitHub: https://github.com/dtslib1979/parksy-image/tree/main
