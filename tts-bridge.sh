#!/data/data/com.termux/files/usr/bin/bash
# tts-bridge.sh — Termux 탭 하나로 TTS 서버 + PC 접속 완성
#
# 사용법:
#   Termux에서: pc    (setup.sh 이후 alias pc 적용됨)
#   또는 직접:  ~/termux-bridge/tts-bridge.sh
#
# 동작:
#   1. TTS 서버 백그라운드 시작 (tts-server.sh → termux-tts-speak)
#   2. PC에 SSH 역방향 터널로 접속
#      → PC의 포트 9876 → 폰의 TTS 서버
#   3. PC에서 tts "읽어줘" 하면 폰이 읽어줌

PC_HOST="100.90.83.128"
PC_USER="dtsli"
PC_PORT="2222"
TTS_PORT="9876"
TTS_SCRIPT="$HOME/termux-bridge/tts-server.sh"
LOG="${TMPDIR:-/tmp}/tts-server.log"

# ── 1. TTS 서버 시작 ────────────────────────────────
echo ""
echo "╔═══════════════════════════════════╗"
echo "║   TTS Bridge — 폰+PC 연결 시작    ║"
echo "╚═══════════════════════════════════╝"
echo ""

# 기존 프로세스 정리
if pgrep -f "tts-server.sh" > /dev/null 2>&1; then
    echo "[1/2] TTS 서버 재시작..."
    pkill -f "tts-server.sh" 2>/dev/null
    sleep 0.5
else
    echo "[1/2] TTS 서버 시작..."
fi

nohup bash "$TTS_SCRIPT" > "$LOG" 2>&1 &
TTS_PID=$!
sleep 0.5

# 시작 확인
if kill -0 "$TTS_PID" 2>/dev/null; then
    echo "     ✓ TTS 서버 실행 중 (PID $TTS_PID, 포트 $TTS_PORT)"
    echo "     log: $LOG"
else
    echo "     ✗ TTS 서버 시작 실패 — $LOG 확인"
    exit 1
fi

# ── 2. PC SSH 접속 + 역방향 터널 ────────────────────
echo ""
echo "[2/2] PC 접속 중 ($PC_USER@$PC_HOST:$PC_PORT) + TTS 터널..."
echo "      PC에서 → tts \"텍스트\" 하면 폰이 읽어줌"
echo "      PC에서 → cc-tts \"프롬프트\" 하면 Claude 응답도 읽어줌"
echo ""

# exec: 이 스크립트를 SSH 세션으로 교체 (탭 점유 최소화)
exec ssh \
    -R "${TTS_PORT}:localhost:${TTS_PORT}" \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -p "$PC_PORT" \
    "$PC_USER@$PC_HOST"
