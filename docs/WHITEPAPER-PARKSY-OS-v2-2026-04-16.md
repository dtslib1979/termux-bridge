# PARKSY OS 아키텍처 백서 v2
> 작성일: 2026-04-16  
> 작성 맥락: 윈도우 강제 업데이트 → 폰 단독 세션 → 이중 복구 레인 확립

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

## 2. 생태계 구조 (GitHub = 태양)

```
                    ☀️  GitHub (태양)
              28개 레포 / Actions / GitOps / CDN
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   브랜치 5개       스튜디오 3종      미디어 3종
   직영점 4개       지식관리 3종      인프라 4개
        │                │                │
        └────────────────┼────────────────┘
                         │
              GitHub Pages (정적 CDN, 트래픽 무제한)
                    +
              Discord (동적 레이어 — 게시판/챗/봇)
                    =
              공짜 WordPress 완성
```

**왜 트래픽/용량 걱정 없냐**
- GitHub Pages = Microsoft Azure CDN, 동시접속 제한 없음
- 월 100GB 대역폭, YouTube 터져서 몰려와도 버팀
- 동적 처리는 Discord 봇이 받음
- GitHub Pro $4/월 = 프라이빗 레포 Pages 발행 포함

---

## 3. 이중 복구 레인

### 시나리오 1 — SD카드 WTG (물리 백업)

```
집 PC WSL2 뻗음
        ↓
SD카드 Windows 경량으로 부팅 (F12)
        ↓
WSL 복구 / 작업 재개
```

**완성 현황**

| 항목 | 상태 |
|------|------|
| microSD WTG 설치 | ✅ 완료 |
| Realtek CardReader 드라이버 | ✅ 완료 |
| Secure Boot 해결 | ✅ 완료 |
| BIOS 부팅 순위 설정 | ✅ 완료 |
| OpenSSH + Tailscale | ✅ 완료 |
| WSL minimal import | ❌ 오늘 집 가서 완성 |
| mosh-server 자동시작 | ❌ 오늘 집 가서 완성 |
| 자동 로그인 | ❌ 오늘 집 가서 완성 |

---

### 시나리오 2 — RunPod CPU MCP (클라우드 백업)

```
집 PC 완전 사망 / WSL 접근 불가
        ↓
폰 → Mosh → RunPod CPU (독립 서버)
        ↓
Claude Code + MCP 서버 그대로 작동
```

**RunPod이 집 PC보다 나은 점**

| 상황 | 집 PC | RunPod |
|------|-------|--------|
| SSH 끊김 | 모니터 직접 봐야 함 | 웹 콘솔로 복구 |
| 설정 잘못됨 | 재설치 | 스냅샷 롤백 |
| 윈도우 업데이트 | 강제 재부팅 | 해당 없음 |
| 정전 | 끊김 | 해당 없음 |

```
RunPod 뻗음
        ↓
폰 브라우저 → RunPod 웹 대시보드
        ↓
웹 콘솔 (브라우저 터미널) 접속
        ↓
명령어 실행 / 재시작
```

---

## 4. 최종 아키텍처

```
━━━ 12월 이전 (현재) ━━━

폰/탭
  ├── Mosh → 집 PC WSL2 (메인)
  │              └── 뻗으면 → SD카드 WTG 복구
  └── Mosh → RunPod CPU (보조 MCP)
                     └── 뻗으면 → 웹 콘솔 복구


━━━ 12월 이후 (노마드) ━━━

폰 (S25 Ultra) + 탭 (Tab S9) + 크로스백
        ↓ STT → Mosh
RunPod CPU (메인 MCP 커널, $3~5/월)
        ↓ 필요 시
Vast.ai GPU (배치 작업, 온디맨드)
        ↓
Claude Code + DeepSeek + Aider
```

---

## 5. MCP 전략

### 개념
> 지금 28개 레포의 자동화 파이프라인 = 이미 MCP 구조
> 이름만 안 붙었을 뿐

```
parksy-audio   → audio MCP 서버
parksy-image   → image MCP 서버
parksy-logs    → log/RAG MCP 서버
dtslib-papyrus → orchestrator MCP
```

### Perplexity MCP
```
Perplexity raw 데이터 수집
        ↓
추론 모델링 파이프라인 (Python)
        ↓
MCP 툴로 노출
        ↓
Claude Code에서 한 마디로 끝
```

---

## 6. 콘텐츠 파이프라인

```
레포 (살아있는 소설 / 연재)
        ↓
GitHub Pages (인터랙티브 PWA)
        ↓ Playwright 연출 + 화면녹화
AI 성우 판서 강의영상
        ↓ Perplexity 서머리
YouTube 콘텐츠
        ↓
parksy-logs 축적 → LLM 파인튜닝 → 루프백
```

---

## 7. 비용 구조

| 항목 | 비용 | 역할 |
|------|------|------|
| GitHub Pro | $4/월 | 28개 레포 + 프라이빗 Pages |
| RunPod CPU | $3~5/월 | 상시 MCP 커널 + 복구 레인 |
| Vast.ai GPU | 온디맨드 | 배치 작업만 |
| **합계** | **$7~9/월** | **이중 복구 + MCP + 생태계 전체** |

---

## 8. 핵심 원칙

1. **GitHub = 태양.** 모든 레포, 파이프라인, 정책의 중심.
2. **이중 복구 레인.** SD카드(물리) + RunPod(클라우드).
3. **MCP = 사고방식의 코드화.** 레포 자체가 MCP가 된다.
4. **Discord = 동적 레이어.** GitHub Pages의 정적 한계 보완.
5. **집 PC = 임시.** 12월 퇴거와 함께 정리. RunPod이 영구 커널.

---

*오늘 증명됨: 준비한 것은 결국 필요해진다.*
*SD카드 WTG — 오늘 같은 날을 위해 어제 만들었다.*
*RunPod — 다음 번 오늘을 위해 지금 만든다.*

---

*Authored: 2026-04-16 폰 단독 세션*
*Built with: Claude Code (claude-sonnet-4-6)*
