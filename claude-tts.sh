#!/bin/bash
# claude-tts.sh (PC WSL2)
# Claude Code 응답을 실시간으로 폰 TTS로 전달하는 래퍼
#
# 사용법:
#   ./claude-tts.sh "프롬프트"
#   alias cc-tts='~/termux-bridge/claude-tts.sh'

PORT=9876
TTS_ENABLED=true

# TTS 서버 연결 확인
if ! nc -z localhost "$PORT" 2>/dev/null; then
    echo "[경고] TTS 서버 없음 (폰에서 tts-server.sh 실행 필요)"
    TTS_ENABLED=false
fi

tts_line() {
    local line="$1"
    # 빈 줄, 코드블록 펜스, 구분선 스킵
    [[ "$line" =~ ^(---|\`\`\`|===)$ ]] && return
    [ -z "$(echo "$line" | tr -d ' ')" ] && return
    # 마크다운 제거
    local clean
    clean=$(echo "$line" | sed 's/[#*`_~>|]//g;s/  */ /g;s/^ *//;s/ *$//')
    [ -n "$clean" ] && nc -q1 localhost "$PORT" <<< "$clean" 2>/dev/null &
}

# Claude Code 실행 + 출력 동시에 TTS 전송
if [ "$TTS_ENABLED" = true ]; then
    claude -p "$*" 2>&1 | tee /dev/tty | while IFS= read -r line; do
        tts_line "$line"
    done
else
    claude -p "$*"
fi
