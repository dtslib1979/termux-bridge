# PARKSY OS 아키텍처 백서 v3
> 작성일: 2026-04-16  
> 부제: GitHub 태양계 + 이중 복구 레인 + OCI 블랙박스 MCP

---

## 1. 오늘의 사건이 증명한 것

마이크로소프트 패치 화요일 (KB5083769) 강제 재부팅 → WSL2 세션 강제 종료.
폰 단독 세션으로 전환. 불편함이 아키텍처를 완성시켰다.

**확립된 원칙:**
> GitHub가 태양이다. 나머지는 교체 가능한 부품이다.
> 준비한 것은 결국 필요해진다.

---

## 2. 최종 아키텍처 — 3층 구조

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Layer 0 — 태양 (불변)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                ☀️  GitHub
          28개 레포 / Actions / CDN
    GitHub Pages + Discord = 공짜 WordPress
    → 회수 불가, 트래픽 무제한, 영구

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Layer 1 — 이중 복구 레인 (안전망)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 [물리] 집 PC WSL2 (12월까지 메인)
   뻗으면 → SD카드 WTG 복구 부팅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Layer 2 — OCI ARM 블랙박스 (연출/실험)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 Oracle Cloud Always Free
 ARM A1 · 4 vCPU · 24GB RAM · $0/월
   → MCP 서버 상시 가동
   → 초대받은 지인만 접속
   → 방송용 "Parksy OS 비하인드" 연출
   → 회수되면? GitHub+로컬로 복귀. 어쩔 수 없고.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 입력 레인
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 폰/탭 → STT → Mosh → WSL2 (메인)
                    → OCI ARM (블랙박스)
```

---

## 3. OCI ARM 블랙박스 스펙

| 항목 | 값 |
|------|-----|
| 플랫폼 | Oracle Cloud Always Free |
| 인스턴스 | VM.Standard.A1.Flex (Ampere A1) |
| CPU | 4 vCPU @ 3.0GHz (ARM) |
| RAM | 24GB |
| 스토리지 | 200GB |
| 비용 | **$0/월 (영구 무료)** |
| 리스크 | Idle 회수 가능 → MCP 상시 가동으로 자동 해결 |
| 보호책 | PAYG 업그레이드 (청구 $0 유지, 회수 위협 제거) |

**집 PC(i7-8550U / 16GB)보다 RAM이 더 많다.**

---

## 4. MCP 전략 — 28개 레포 = 이미 MCP

```
parksy-audio   → audio MCP 서버
parksy-image   → image MCP 서버
parksy-logs    → log/RAG MCP 서버
dtslib-papyrus → orchestrator MCP
Perplexity     → 검색/추론 MCP
```

**OCI ARM 위에서 돌아가는 구조:**
```
지인 접속 (초대제)
        ↓
OCI ARM MCP 서버
        ↓
Claude Code + 28개 레포 파이프라인
        ↓
GitHub에 결과 푸시
```

핵심 데이터는 전부 GitHub에 있어서, OCI가 날아가도 아무것도 잃지 않는다.

---

## 5. SD카드 WTG 완성 현황

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

## 6. 12월 노마드 전환

```
퇴거 (2026-12)
        ↓
집 PC 정리 / SD카드 퇴역
        ↓
폰 + 탭 + 크로스백
        ↓
OCI ARM → 메인 MCP 커널 승격
Vast.ai GPU → 배치 작업 온디맨드
        ↓
필요하면 그때 RunPod 유료 추가
```

---

## 7. 콘텐츠 파이프라인

```
레포 (살아있는 소설)
        ↓
GitHub Pages (인터랙티브 PWA)
        ↓ Playwright 연출 + 화면녹화
AI 성우 판서 강의영상
        ↓ Perplexity 서머리
YouTube ("OCI ARM 위에서 돌아가는 Parksy OS")
        ↓
parksy-logs → LLM 파인튜닝 → 루프백
```

---

## 8. 비용 구조

| 항목 | 비용 | 역할 |
|------|------|------|
| GitHub Pro | $4/월 | 28개 레포 + 프라이빗 Pages |
| OCI ARM Always Free | **$0/월** | MCP 블랙박스 + 연출용 서버 |
| Vast.ai GPU | 온디맨드 | 배치 작업만 |
| **합계** | **$4/월** | **전체 생태계 운영** |

---

## 9. 핵심 원칙

1. **GitHub = 태양.** 회수 불가. 모든 것의 중심.
2. **OCI = 멋있는 공짜 블랙박스.** 있으면 쓰고, 가져가면 어쩔 수 없고.
3. **이중 복구 레인.** SD카드(물리) + OCI(클라우드).
4. **Discord = 동적 레이어.** GitHub Pages의 정적 한계 보완.
5. **MCP = 사고방식의 코드화.** 28개 레포가 곧 MCP다.
6. **집 PC = 임시.** 12월 퇴거와 함께 정리.

---

*공짜면 쓰고, 가져가면 어쩔 수 없고.*
*허세는 공짜로 부릴 수 있다.*
*준비한 것은 결국 필요해진다.*

---

*Authored: 2026-04-16 폰 단독 세션*
*Built with: Claude Code (claude-sonnet-4-6)*
