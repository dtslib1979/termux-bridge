# PARKSY OS 아키텍처 백서
> 작성일: 2026-04-16  
> 작성 맥락: 윈도우 강제 업데이트 → 폰 단독 세션 중 확립

---

## 1. 오늘의 사건이 증명한 것

마이크로소프트 패치 화요일 (KB5083769) 강제 재부팅으로 WSL2 세션 강제 종료.
집 PC 없이 폰 단독으로 Claude Code 세션 진행.

**드러난 구조적 취약점:**
```
집 PC (WSL2) = 단일 장애점 (SPOF)
PC 꺼지면 → MCP 없음 → 에이전트 없음 → 일 못 함
```

**오늘로 확립된 원칙:**
> 작업 환경은 물리 머신에 의존하면 안 된다.
> GitHub가 태양이고, 나머지는 교체 가능한 부품이어야 한다.

---

## 2. 현재 아키텍처 (AS-IS)

```
폰/탭 → STT → Mosh → 집 PC WSL2 → Claude Code + MCP
                              ↓
                         GitHub (28개 레포)
                              ↓
                    Vast.ai GPU (배치 작업)
```

**문제:** WSL2 = 단일 장애점. PC 꺼지면 전체 중단.

---

## 3. 목표 아키텍처 (TO-BE)

### 태양계 구조

```
                    ☀️  GitHub (태양)
              25개 레포 / Actions / GitOps / CDN
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   브랜치 5개       스튜디오 3종      미디어 3종
   직영점 4개       지식관리 3종      인프라 4개
   (GitHub Pages + Discord = 공짜 WordPress)
        │                │                │
        └────────────────┼────────────────┘
                         │
              RunPod CPU (상시 MCP 커널) ← 12월~
              $3~5/월 / 윈도우 업데이트 무관
              Claude Code + MCP 서버들
                         │
              ┌──────────┴──────────┐
         Vast.ai GPU           RunPod GPU
         (이미지/영상)         (LLM 학습)

입력: 폰/탭 → STT → Mosh → RunPod CPU
```

### 집 PC의 역할 (12월까지만)
- WSL2: MCP + Claude Code 메인 환경
- SD카드 WTG: WSL2 장애 시 복구 부팅

### 12월 이후 (퇴거 후 노마드)
- 집 PC 없음
- 폰 + 탭 + 크로스백
- RunPod CPU: 상시 MCP 커널 (PC 역할 대체)
- Vast.ai: GPU 필요 시 온디맨드

---

## 4. GitHub + Discord = 공짜 WordPress

### 구조
```
GitHub Pages (정적 - CDN, 트래픽 무제한)
    +
Discord (동적 - 게시판 / 채팅 / 봇 / 알림)
    =
레포 1:1 매칭 SNS + 게시판 + 챗 완성
```

### 왜 트래픽 걱정 없냐
- GitHub Pages = 전 세계 CDN 엣지 서빙
- 정적 파일 = 서버 부하 개념 없음
- 동적 처리 = Discord 봇이 받음
- YouTube 터져서 트래픽 몰려와도 Pages는 끄떡없음

---

## 5. MCP 전략

### 개념
> 지금 28개 레포의 자동화 파이프라인 = 이미 MCP 구조
> 이름만 안 붙었을 뿐

```
parksy-audio  → audio MCP 서버
parksy-image  → image MCP 서버
parksy-logs   → log/RAG MCP 서버
dtslib-papyrus → orchestrator MCP
```

### 실행 방식
- 각 파이프라인 함수 → MCP 툴로 노출
- Claude Code가 툴 호출로 전체 생태계 조작
- 사고방식 Python 코드화 → GitHub 자체가 MCP

### 서버 옵션

| 옵션 | 비용 | 장점 | 단점 |
|------|------|------|------|
| 집 PC WSL2 | 전기세만 | 빠름 | SPOF, 관리 피로 |
| GitHub Actions | 무료 2000분/월 | 비용 없음 | 콜드스타트 1~2분 |
| RunPod CPU | $3~5/월 | 상시 대기, 안정적 | 비용 발생 |

**결론:** 폰 STT → Mosh → RunPod CPU MCP 구조가 최종 목표

---

## 6. 물리 백업 전략 (집 PC 있는 동안)

```
WSL2 정상 → 메인 작업 환경
    ↓ 장애 시
SD카드 WTG Windows 경량 부팅
    ↓
WSL2 복구 / 작업 재개
```

### SD카드 WTG 완성 현황

| 항목 | 상태 |
|------|------|
| microSD WTG 설치 | ✅ 완료 |
| Realtek CardReader 드라이버 | ✅ 완료 |
| Secure Boot 해결 | ✅ 완료 |
| BIOS 부팅 순위 설정 | ✅ 완료 |
| OpenSSH + Tailscale | ✅ 완료 |
| WSL minimal import | ❌ 미완료 |
| mosh-server 자동시작 | ❌ 미완료 |
| 자동 로그인 | ❌ 미완료 |

**집 가면 Step 2~5 완성 (30분).**

---

## 7. 12월 노마드 전환 플랜

### 배경
재개발 지역 월세방 → 2026년 12월 퇴거 예정.
퇴거 시 집 PC 정리. 이후 폰 + 탭 크로스백 노마드.

### 전환 후 스택
```
폰 (S25 Ultra) + 탭 (Tab S9) + 크로스백
        ↓ STT → Mosh
RunPod CPU ($3~5/월) — MCP 커널 상시
        ↓ 필요 시
Vast.ai GPU — 배치 작업 온디맨드
        ↓
Claude Code + DeepSeek + Aider
```

### 왜 RunPod이냐 (vs Vast.ai)
- Vast.ai = 남의 유휴 장비 임대 → 찝찝함
- RunPod = 전용 인프라 → 안정적
- CPU 인스턴스 $3~5/월으로 집 PC 사양 충분

---

## 8. 콘텐츠 파이프라인 (레포 = 살아있는 소설)

```
레포 (살아있는 소설 / 연재)
        ↓
GitHub Pages (인터랙티브 PWA)
        ↓ Playwright 연출 + 화면녹화
AI 성우 판서 강의영상
        ↓ Perplexity 서머리
YouTube 콘텐츠 (강의 소재)
        ↓
루프백: parksy-logs 축적 → LLM 파인튜닝
```

---

## 9. Perplexity MCP 역할

```
Perplexity (raw 데이터 수집)
        ↓
추론 모델링 파이프라인 (Python)
        ↓
MCP 툴로 노출
        ↓
Claude Code에서 "perplexity로 찾아봐" 한 마디로 끝
```

현재: parksy-image/perplexity_search.py (Playwright 방식, 오늘 2시간에 제작)
목표: MCP 서버 툴로 패키징

---

## 10. 핵심 원칙 요약

1. **GitHub = 태양.** 모든 레포, 파이프라인, 정책의 중심.
2. **집 PC = 임시.** 12월 퇴거와 함께 정리.
3. **MCP = 사고방식의 코드화.** 레포 자체가 MCP가 된다.
4. **Discord = 동적 레이어.** GitHub Pages의 정적 한계를 보완.
5. **RunPod CPU = 영구 커널.** 윈도우 업데이트 따위에 흔들리지 않는 기반.

---

*오늘 증명됨: 준비한 것은 결국 필요해진다.*  
*SD카드 WTG — 오늘 같은 날을 위해 어제 만들었다.*

---

*Authored: 2026-04-16 폰 단독 세션*  
*Built with: Claude Code (claude-sonnet-4-6)*
