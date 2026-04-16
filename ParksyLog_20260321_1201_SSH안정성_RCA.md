---
date: 2026-03-21 12:01:20
session_id: 3cc47c96-c2c0-4930-80bd-589e32df551d
duration: ~50min
messages: user=60, assistant=83
source: claude-session-parse
---

### 2026-03-21 | SSH 세션 안정성 4중 복합 원인 RCA

**작업**:
- 오늘 세션 드랍 80% 원인 분석
- SSH 자기루프 발견 및 종료 (PID 2117, CPU 38% 독식, 19시간 동작)
- tailscaled CPU 폭주 해소 (29.6% → 0%, 재시작)
- `.wslconfig` 생성 (`vmIdleTimeout=-1`, `memory=7GB`)
- `wsl.conf` boot.command에 `wsl-server-init.sh` 추가
- TTS 좀비 프로세스 5개 정리 (script -q 인스턴스)

**결정**:
- SSH 루프: `claude-main` tmux 세션이 자기 자신(100.90.83.128:2222)에게 SSH하고 있었음 → kill
- tailscaled: 재시작만으로 해결 (원인 불명이지만 재시작 후 idle)
- wslconfig: Windows idle 시 WSL 자동 종료 → `vmIdleTimeout=-1`로 영구 방지
- Termux에서 tmux 쓰지 않는 습관 확립 (중첩 구조가 화면 깨짐 원인)

**결과**:
```
[수정 전]          [수정 후]
CPU ~98%   →   ~1% (idle 98.9%)
SSH 루프  →   종료
tailscaled 폭주 → 0%
WSL 자동종료 → 방지 (다음 재시작 후 적용)
```
- 4중 원인 전부 조치 완료
- ⚠️ autossh 미완 (다음 세션 넘어감)

**교훈**:
- Termux에서는 tmux 절대 쓰지 마라. PC SSH 후 claude-main에 attach만.
- 올바른 패턴: `Termux 맨 bash → SSH → PC WSL2 tmux attach`
- `wslconfig`는 처음 셋업 때부터 넣어야 함 (vmIdleTimeout=-1)
- SSH 루프는 오래 방치하면 CPU 38% 독식 가능. 정기적으로 `ps aux | grep ssh` 확인

**재구축 힌트**:
"SSH 루프 확인: ps aux | grep ssh
tailscaled 상태: systemctl status tailscaled
wslconfig 확인: cat /mnt/c/Users/dtsli/.wslconfig"

---
*상세 분석: `ParksyLog_20260321_세션안정성_트러블슈팅.md` 참조*
