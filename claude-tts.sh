#!/bin/bash
# claude-tts.sh (PC WSL2)
# Claude 응답에서 코드블록 제거 후 한글 텍스트만 폰 TTS 전송
#
# 설정: ~/.bashrc에 추가
#   alias claude='~/termux-bridge/claude-tts.sh'
#
# 사용법:
#   claude "질문"        → -p 모드로 응답 → TTS 자동 전송
#   claude               → 인터랙티브 모드 (응답 중 한글 자동 TTS)

PORT=9876
TTS_ENABLED=true

# TTS 서버 연결 확인
if ! nc -z localhost "$PORT" 2>/dev/null; then
    echo "[경고] TTS 서버 없음 (폰에서 tts-bridge.sh 실행 필요)"
    TTS_ENABLED=false
fi

tts_filter() {
    local in_code=false
    while IFS= read -r line; do
        # ANSI 이스케이프 코드 제거 (TUI 출력 정리)
        line=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*[A-Za-z]//g; s/\x1b[()][AB012]//g; s/\r//g')
        # 코드블록 시작/끝 감지 (``` 또는 ~~~)
        if [[ "$line" =~ ^(\`\`\`|~~~) ]]; then
            [ "$in_code" = false ] && in_code=true || in_code=false
            continue
        fi
        # 코드블록 내부 스킵
        [ "$in_code" = true ] && continue
        # 빈 줄 / 구분선 스킵
        [ -z "$(echo "$line" | tr -d ' \t')" ] && continue
        [[ "$line" =~ ^[-=]{3,}$ ]] && continue
        # 마크다운 기호 제거
        local clean
        clean=$(echo "$line" | sed 's/[#*`_~>|]//g; s/  */ /g; s/^ *//; s/ *$//')
        # 한글 포함 줄만 TTS 전송
        if echo "$clean" | grep -q '[가-힣]' && [ -n "$clean" ]; then
            nc -q1 localhost "$PORT" <<< "$clean" 2>/dev/null &
        fi
    done
}

# 인수 없으면 인터랙티브 모드 — TTS 래핑 포함 (alias 무한루프 방지)
if [ $# -eq 0 ]; then
    if [ "$TTS_ENABLED" = true ]; then
        LOG=$(mktemp /tmp/claude_tts_XXXXXX)
        # 백그라운드: 로그 실시간 감시 → ANSI 제거 → 한글 TTS 전송
        tail -f "$LOG" 2>/dev/null | tts_filter &
        TTS_BG=$!
        # 인터랙티브 claude 실행 (script로 PTY 유지 + 출력 파일 기록)
        script -q -c "command claude" "$LOG" 2>/dev/null
        # 정리
        sleep 0.5
        kill "$TTS_BG" 2>/dev/null
        rm -f "$LOG"
    else
        exec command claude
    fi
    exit 0
fi

# 인수 있으면 -p 단일 질의 모드
if [ "$TTS_ENABLED" = true ]; then
    command claude -p "$*" 2>&1 | tee /dev/tty | tts_filter
else
    command claude -p "$*"
fi
