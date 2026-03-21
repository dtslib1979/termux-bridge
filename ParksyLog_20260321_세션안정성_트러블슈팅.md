# 세션 안정성 트러블슈팅 보고서
**날짜**: 2026-03-21
**작성**: Claude Code (Sonnet 4.6)
**분류**: INFRA — 긴급 장애 분석

---

## 1. 오늘 삽질의 전체 구조

박씨 오늘 삽질의 80%가 세션 드랍 후 재접속이었다. 원인은 단일이 아닌 4중 복합.

```
WiFi↔LTE 전환
    ↓
SSH 끊김
    ↓
tmux 중첩 (Termux에서 tmux 실행 → PC에서 또 tmux)
    ↓
화면 깨짐 + 컨텍스트 소실
    ↓
새 세션 = 맥락 없음
    ↓
관제탑 프로토콜로 복구 (메모리 읽기)
```

---

## 2. 근본 원인 (RCA)

### 원인 A — SSH 자기 루프 (주범, CPU 38% 독식)

**발견**: `claude-main` tmux 세션 안에서 자기 자신에게 SSH 루프가 19시간 동작 중

```
claude-main 세션
  └─ bash (PID 341)
       └─ ssh -p 2222 dtsli@100.90.83.128 (PID 2117, 18% CPU)
            └─ sshd: dtsli@pts/3 (PID 2147, 20.3% CPU)
```

**영향**: 전체 CPU의 38%를 19시간 독식. 시스템 응답 지연 → SSH keepalive 실패 → 세션 드랍.
**조치**: `kill 2117` → CPU 즉시 1%대로 정상화.

### 원인 B — tailscaled CPU 폭주 (29.6%)

**발견**: `tailscaled` 단독 프로세스가 30% CPU 사용 (정상은 1% 미만)
**영향**: Tailscale 경유 SSH 연결 지연 + 불안정
**조치**: 재시작 → 0% (idle 상태)

### 원인 C — `.wslconfig` 없음 (WSL 자동 종료)

**발견**: `/mnt/c/Users/dtsli/.wslconfig` 미존재
**증거**: `server.log` 갭 — 오전 09:08 ~ 오후 16:09 (7시간 동안 credentials sync 로그 없음)
**원인**: Windows idle/절전 시 WSL2 VM 자동 종료. 종료되면 watchdog도 같이 죽음.
**조치**: `.wslconfig` 생성 (`vmIdleTimeout=-1`)

### 원인 D — TTS 좀비 프로세스 (script -q 5개)

**발견**: 롤백(`revert: TTS 브릿지 전부 제거`)했는데 기존에 실행된 `script -q -c command claude` 프로세스 5개가 계속 살아있음
**영향**: 메모리 + 불필요한 클로드 인스턴스 유지
**조치**: `kill` → 정리 완료

### 원인 E — tmux 중첩 구조 (습관적 패턴)

**패턴**: Termux에서 tmux 실행 → SSH → PC에서 또 tmux
**영향**: 중첩된 tmux에서 키 바인딩 충돌 + 화면 깨짐 + 세션 추적 불가
**올바른 패턴**:
```
Termux: 맨 bash (tmux 없이)
  → SSH → PC WSL2
       → claude-main tmux 세션에 attach
```

---

## 3. 수정 완료 항목 (2026-03-21 오늘)

| 항목 | 수정 내용 | 효과 |
|------|----------|------|
| SSH 자기루프 종료 | `kill 2117` | CPU 38% 해방 |
| TTS 좀비 정리 | `kill` 5개 프로세스 | 메모리 + 클로드 인스턴스 정리 |
| tailscaled 재시작 | `sudo kill 1553` → 재시작 | CPU 29.6% → 0% |
| `.wslconfig` 생성 | `vmIdleTimeout=-1`, `memory=7GB` | WSL 자동 종료 방지 (다음 재시작 후 적용) |
| `wsl.conf` boot.command | `wsl-server-init.sh` 자동 실행 | WSL 재시작 시 서비스 자동 복구 |

### 수정 후 CPU 변화

```
[수정 전]                    [수정 후]
tmux 누적  36.7%  →  0.0%   (SSH 루프가 원인이었음)
tailscaled 29.6%  →  0.0%   (재시작 후 idle)
sshd       20.3%  →  0.0%   (루프 종료)
ssh        18.0%  →  0.0%   (루프 종료)
전체 CPU   ~98%   →  ~1%    (idle 98.9%)
```

---

## 4. 미완료 — 다음 세션 필수 작업

### 4-1. autossh 도입 (핵심)

**현재 `pc` alias**: `tts-bridge.sh` (TTS 롤백됐으므로 이미 잘못된 상태)
**목표**: WiFi↔LTE 전환해도 자동 재접속

```bash
# Termux에서 실행할 것:
pkg install autossh

# setup.sh에서 pc alias 교체:
# 현재:
alias pc='~/termux-bridge/tts-bridge.sh'

# 목표:
alias pc='autossh -M 0 \
  -o "ServerAliveInterval 30" \
  -o "ServerAliveCountMax 3" \
  -o "ExitOnForwardFailure yes" \
  -p 2222 dtsli@100.90.83.128 \
  -t "tmux attach -t claude-main || tmux new-session -s claude-main"'
```

**주의**: Tailscale IP(`100.90.83.128`)가 바뀌면 수동 갱신 필요. 아니면 `~/.phone_ip` 파일에서 읽어오는 방식으로.

**작업 범위**:
1. `termux-bridge/setup.sh` — `pc` alias를 autossh 기반으로 교체
2. `termux-bridge/install.sh` — `autossh` 패키지 추가
3. `git push` → 폰에서 `git pull && source ~/.bashrc`

### 4-2. SSH keepalive 클라이언트 설정

```bash
# 폰(Termux)의 ~/.ssh/config 에 추가:
Host pc-tailscale
    HostName 100.90.83.128
    Port 2222
    User dtsli
    ServerAliveInterval 30
    ServerAliveCountMax 3
    TCPKeepAlive yes
```

### 4-3. Tmux 중첩 방지 — Termux .bashrc 경고

```bash
# 폰 ~/.bashrc에 추가:
# tmux 중첩 경고 (PC 접속 후 또 tmux 쓰는 습관 방지)
if [ -n "$TMUX" ]; then
    echo "[경고] 이미 tmux 안입니다. PC 접속 시 tmux 중첩 주의!"
fi
```

---

## 5. 아키텍처 현황 (수정 후)

```
[폰 Termux]
  bash (tmux 없이)
    ↓ autossh (다음 세션 작업)
    ↓ Tailscale SSH (100.90.83.128:2222)

[집 PC WSL2]
  tmux claude-main
    └─ Claude Code 실행
  tmux tg-image    ← @parksy_bridge_bot (상시)
  tmux tg-audio    ← @parksy_bridges_bot (상시)
  tmux watchdog    ← SSH/봇/Tailscale 감시 (상시)

[Windows]
  .wslconfig vmIdleTimeout=-1   ← WSL 자동 종료 방지 ✅
  wsl.conf boot.command          ← WSL 재시작 시 자동 init ✅
```

---

## 6. 교훈 정리

### 해결됨
| 원인 | 해결 |
|------|------|
| PC 절전 → SSH 끊김 | vmIdleTimeout=-1 + boot.command |
| tmux 중첩 → 화면 깨짐 | Termux에서 tmux 안 쓰는 습관 (+ 다음 세션에 경고 추가) |
| TTS 래퍼 → 좀비 + 포트 충돌 | 롤백 완료, 좀비 정리 완료 |
| SSH 자기 루프 → CPU 38% | kill 완료 |
| tailscaled 폭주 | 재시작 완료 |

### 미해결 (다음 세션)
| 원인 | 해결 방법 |
|------|----------|
| WiFi↔LTE 전환 → SSH 끊김 | **autossh 도입** (termux-bridge setup.sh 수정) |
| pc alias 파손 (tts-bridge.sh 참조) | autossh alias로 교체 |

---

## 7. 다음 세션 착수 명령

```
"autossh 작업 해. termux-bridge setup.sh의 pc alias를
autossh 기반으로 바꾸고 install.sh에 autossh 추가해서 push."
```

---

*보고서 작성: 2026-03-21*
*수정된 파일: /mnt/c/Users/dtsli/.wslconfig, /etc/wsl.conf*
*프로세스 조치: kill 2117, 1553, 10756, 12514, 13262, 15407, 20919*
