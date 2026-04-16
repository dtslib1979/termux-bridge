---
date: 2026-03-21 07:48:00
session_id: 17b0b9b4-cfc4-459b-a012-9958e128797b
duration: ~6min
messages: user=34, assistant=43
source: claude-session-parse
---

### 2026-03-21 | TTS 브릿지 구현 + PC 서버 안정화

**작업**:
- `claude-tts.sh` 래퍼 구현 — 박씨 말하면 한글 응답이 폰 TTS로 자동 전송
- PC 서버 안정화 3종 세트: Windows 절전모드 차단 + 자동업데이트 재부팅 차단 + WSL2 keepalive
- TTS 연결 실패 에러 도배 → `/dev/null` 처리로 화면 정리

**결정**:
- TTS 브릿지를 claude alias에 래핑 (claude-tts.sh → script -q -c)
- PC 절전 차단을 TTS보다 먼저 해야 안정적으로 작동한다고 판단
- 에러 출력 억제는 사용성 개선 목적 (연결 실패가 치명적이지 않으므로)

**결과**:
- TTS 브릿지 1차 완성 (port 9876)
- PC 절전/업데이트/keepalive 3개 완료
- ⚠️ 이후 세션에서 `revert: TTS 브릿지 전부 제거` — 좀비 프로세스 5개 남아있었음

**교훈**:
- `script -q -c command claude` 래퍼는 세션 종료 후 좀비 프로세스로 남는다
- TTS 브릿지 재도입 시 프로세스 생명주기 관리 필수
- PC 서버 안정화(절전/wslconfig)는 TTS와 무관하게 항상 먼저 해야 함

**재구축 힌트**:
"termux-bridge에서 TTS 브릿지 다시 만들어. script 래퍼 말고 직접 소켓 방식으로.
좀비 프로세스 안 생기는 구조로."
