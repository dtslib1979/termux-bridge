# OCI Lifestyle Scheduler — 설계 문서
> 작성일: 2026-04-16
> 부제: Oracle 생존 조건 = 내 최소 생산성 기준

---

## 1. 발상의 기원

Oracle Always Free ARM을 유지하려면 CPU/네트워크/메모리를 7일 기준 20% 이상 유지해야 한다.
이 조건을 인위적으로 채우는 대신 — **내 실제 작업 패턴이 조건을 충족하도록 라이프스타일을 설계한다.**

```
Oracle 회수 조건 → 역설계 → 내 최소 작업 기준
Oracle이 나를 강제하는 구조
```

---

## 2. Oracle 가드레일 (레드라인)

| 조건 | 기준 | 역설계 |
|------|------|--------|
| CPU 7일 95퍼센타일 | 20% 이상 유지 | 주 5일 이상 실제 작업 |
| 네트워크 활동 | 20% 이상 유지 | GitHub/Discord/텔레그램 매일 |
| 계정 방치 | 30일 이내 접속 | 월 1회 이상 OCI 콘솔 확인 |
| ToS 위반 | 크립토/스팸 금지 | 콘텐츠 파이프라인만 |

---

## 3. KST 기반 자연 패턴

```
실제 작업 집중 시간 (KST = UTC+9)

09:00~12:00  ████████  작업 시작, 세션 집중
13:00~18:00  ██████    배치 돌리고 설계
21:00~24:00  ███████   마무리 커밋, 정리
02:00~06:00  ███       렌더링/배치 자동화
06:00~09:00  █         거의 없음
```

Oracle 입장에서:
- UTC 기준 불규칙하게 보임
- 아시아 사용자 시그니처
- 자동화 봇이 아닌 인간 패턴

---

## 4. 스케줄러 설계

```python
# oracle_lifestyle_scheduler.py
# Oracle 가드레일 = Parksy OS 최소 생산성 기준

import random
from datetime import datetime
from zoneinfo import ZoneInfo

KST = ZoneInfo('Asia/Seoul')

# 시간대별 활동 가중치 (KST)
ACTIVITY_WEIGHT = {
    (9, 12):  1.0,   # 오전 집중
    (13, 18): 0.7,   # 오후
    (21, 24): 0.8,   # 저녁 마무리
    (2, 6):   0.3,   # 새벽 배치
    (6, 9):   0.1,   # 거의 없음
}

def jitter(base_seconds, variance=0.3):
    """기본 주기에 ±30% 랜덤 편차 — 인간 패턴"""
    delta = base_seconds * variance
    return base_seconds + random.uniform(-delta, delta)

# 잡 정의
JOBS = [
    # (기본주기초,  설명,                    Oracle 충족 항목)
    (jitter(300),  "MCP 헬스체크",           "CPU + 네트워크"),
    (jitter(3600), "GitHub 상태 조회",       "네트워크"),
    (jitter(7200), "Discord 봇 활동",        "네트워크"),
    (jitter(1800), "parksy-logs RAG 쿼리",   "CPU + 메모리"),
    (86400,        "일일 사용량 덤프",        "계정 방치 방지"),
    ("02:00~05:00 KST", "heavy 배치 윈도우", "CPU 스파이크"),
]
```

---

## 5. Parksy OS 최소 생산성 기준

Oracle 가드레일을 내 작업 규칙으로 번역:

```
✅ 주 5일 이상 — MCP 세션 1회 이상
✅ 매일 — GitHub 커밋 또는 Discord 활동
✅ 월 1회 — OCI 콘솔 접속 확인
✅ 새벽 배치 — parksy-audio/image 렌더링
❌ 7일 연속 손 놓기 금지 (Oracle 회수 트리거)
```

---

## 6. 연출 가치

```
"Oracle Cloud ARM 위에서 돌아가는 Parksy OS"
"Oracle이 나를 강제하는 라이프스타일 OS"

→ YouTube 방송 비하인드 소재
→ 지인 초대제 블랙박스 MCP
→ 허세 + 실용 동시 충족
```

---

## 7. 다음 액션

1. Oracle Cloud 가입 + PAYG 업그레이드
2. 춘천 리전 ARM A1 인스턴스 생성
3. MCP 서버 + oracle_lifestyle_scheduler.py 배포
4. SSH/Mosh 열고 지인 초대

---

*Oracle이 회수 안 하려면 내가 일해야 한다.*
*가드레일이 곧 규율이다.*

---

*Authored: 2026-04-16 폰 단독 세션*
*Built with: Claude Code (claude-sonnet-4-6)*
