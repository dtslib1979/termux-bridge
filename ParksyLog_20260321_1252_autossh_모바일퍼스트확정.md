---
date: 2026-03-21 12:52:39
session_id: 00b8dab7-160e-4e6f-9307-f3b426f1d888
duration: ~46min
messages: user=15, assistant=22
source: claude-session-parse
---

### 2026-03-21 | autossh 도입 + 모바일 퍼스트 철학 재확정

**작업**:
- `termux-bridge/setup.sh` — `pc` alias를 `tts-bridge.sh` 참조에서 `autossh` 기반으로 교체
- `termux-bridge/install.sh` — `autossh` 패키지 추가
- git push → 폰에서 pull
- APK/PWA/Termux 유레카 철학 메모리 저장

**결정**:
- `pc` alias autossh 전환:
  ```bash
  alias pc='autossh -M 0 \
    -o "ServerAliveInterval 30" \
    -o "ServerAliveCountMax 3" \
    -o "ExitOnForwardFailure yes" \
    -p 2222 dtsli@100.90.83.128 \
    -t "tmux attach -t claude-main || tmux new-session -s claude-main"'
  ```
- sed 에러 비치명적이라 push 후 종료 결정
- 모바일 퍼스트 철학을 `project_mobile_first_philosophy.md`로 메모리화

**결과**:
- autossh 기반 pc alias 완성 → WiFi↔LTE 전환 시 자동 재접속
- install.sh에 autossh 패키지 추가
- 오늘 최종 아키텍처 확정:
  ```
  폰 Termux (맨 bash)
    → autossh → Tailscale (100.90.83.128:2222)
      → WSL2 tmux claude-main
  ```

**교훈**:
- APK = 온디바이스, PWA = 외부 API 의존, Termux Claude Code = 최강 API가 온디바이스로
- 공식 제휴 기다릴 이유 없음 — Termux가 그 제휴를 대신함
- Tailscale IP 바뀌면 autossh alias 수동 갱신 필요

**재구축 힌트**:
"termux-bridge setup.sh의 pc alias 확인해봐. autossh 기반인지."
"autossh 안 돼: pkg install autossh → source ~/.bashrc"

---
*관련: project_mobile_first_philosophy.md (메모리), project_ssh_stability.md (메모리)*
