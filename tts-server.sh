#!/data/data/com.termux/files/usr/bin/bash
# termux-tts-server.sh
# 폰에서 실행 — PC에서 보내는 텍스트를 TTS로 읽어줌
#
# 사용법:
#   1) 이 스크립트를 폰 Termux에서 실행
#   2) PC SSH 접속 시 reverse tunnel 추가:
#      ssh -R 9876:localhost:9876 dtsli@<PC-IP>
#   3) 그러면 PC에서 echo "text" | nc localhost 9876 하면 폰이 읽어줌

PORT=9876

echo "[TTS Server] 포트 $PORT 대기 중... (Ctrl+C로 종료)"

while true; do
    nc -l "$PORT" | while IFS= read -r line; do
        [ -z "$line" ] && continue
        echo "[TTS] $line"
        # 마크다운 기호 제거 후 읽기
        clean=$(echo "$line" | sed 's/[#*`_~>|]//g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
        [ -n "$clean" ] && termux-tts-speak "$clean"
    done
done
