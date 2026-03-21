#!/bin/bash
# tts-send.sh (PC WSL2에서 실행)
# 텍스트를 폰 TTS로 전송
#
# 사용법:
#   echo "안녕" | ./tts-send.sh
#   ./tts-send.sh "직접 텍스트"

PORT=9876

send() {
    nc -q1 localhost "$PORT" <<< "$1" 2>/dev/null
}

if [ -n "$1" ]; then
    send "$1"
elif [ ! -t 0 ]; then
    # stdin 파이프 입력
    while IFS= read -r line; do
        [ -n "$line" ] && send "$line"
    done
fi
