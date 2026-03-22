#!/bin/bash
# claude-tts.sh (PC WSL2) — v2: 직접 소켓 방식
#
# v1 문제: script -q -c "command claude" 래퍼 → 세션 후 좀비 프로세스
# v2 해결: script 완전 제거 → stdout 직접 파이프 → 소켓 직통 전송
#
# 설치 (~/.bashrc):
#   alias cc='~/termux-bridge/claude-tts.sh'
#
# 사용법:
#   cc           → 인터랙티브 claude (PTY 직접 실행, TTS 미지원)
#   cc "질문"    → 단일 질의 + 폰 TTS 자동 전송
#   cc -p "질문" → 동일 (-p 명시)

PORT=9876

_tts_connected() {
    nc -z localhost "$PORT" 2>/dev/null
}

# stdout 파이프 → 한글 줄만 소켓 직통 전송 (중간 파일/프로세스 없음)
_tts_pipe() {
    local in_code=false
    while IFS= read -r line; do
        line=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*[A-Za-z]//g; s/\x1b[()][AB012]//g; s/\r//g')
        if [[ "$line" =~ ^(\`\`\`|~~~) ]]; then
            [ "$in_code" = false ] && in_code=true || in_code=false
            continue
        fi
        [ "$in_code" = true ] && continue
        [ -z "$(echo "$line" | tr -d ' \t')" ] && continue
        [[ "$line" =~ ^[-=]{3,}$ ]] && continue
        local clean
        clean=$(echo "$line" | sed 's/[#*`_~>|]//g; s/  */ /g; s/^ *//; s/ *$//')
        if echo "$clean" | grep -qP '[\x{AC00}-\x{D7A3}]' && [ -n "$clean" ]; then
            echo "$clean" | nc -q1 localhost "$PORT" >/dev/null 2>&1
        fi
    done
}

# ── 인터랙티브 모드 (인수 없음) ─────────────────────────────────
# script 래퍼 없이 PTY 직접 실행 → 좀비 없음
# 인터랙티브 중 TTS 필요하면: cc "질문" 단일 질의 사용
if [ $# -eq 0 ]; then
    if _tts_connected; then
        echo "[TTS ✓] 연결됨 — 단일질의 TTS: cc \"질문\""
    else
        echo "[TTS ✗] 폰 tts-bridge.sh 없음"
    fi
    exec command claude
fi

# ── 단일 질의 모드 ───────────────────────────────────────────────
# -p 플래그 직접 처리
QUERY="$*"
[[ "$1" == "-p" ]] && shift && QUERY="$*"

if _tts_connected; then
    command claude -p "$QUERY" 2>&1 | tee /dev/tty | _tts_pipe
else
    echo "[TTS ✗] 폰 tts-bridge.sh 없음 — TTS 없이 실행"
    command claude -p "$QUERY"
fi
