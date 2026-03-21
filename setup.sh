#!/data/data/com.termux/files/usr/bin/bash
# termux-bridge setup — 새 기기에서 Claude Code 환경 원클릭 세팅
# 사용법: curl -fsSL https://raw.githubusercontent.com/dtslib1979/termux-bridge/main/setup.sh | bash

set -e

REPO_URL="https://github.com/dtslib1979/termux-bridge.git"
REPO_DIR="$HOME/termux-bridge"
BASHRC="$HOME/.bashrc"

echo "=== termux-bridge setup ==="

# 1. 필수 패키지 설치
echo "[1/4] 시스템 패키지 확인..."
pkg install -y nodejs git gh 2>/dev/null || true

# 2. Claude Code 전역 설치
echo "[2/4] Claude Code 설치..."
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
  echo "  -> claude-code 설치 완료"
else
  echo "  -> claude-code 이미 설치됨 ($(claude --version 2>/dev/null || echo '버전확인불가'))"
fi

# 3. 레포 클론 또는 업데이트
echo "[3/4] termux-bridge 레포 준비..."
if [ -d "$REPO_DIR/.git" ]; then
  echo "  -> 이미 존재, pull..."
  git -C "$REPO_DIR" pull origin main
else
  echo "  -> 클론 중..."
  git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR" && npm install

# 4. .bashrc alias 세팅
echo "[4/4] alias 세팅..."

add_alias() {
  local name="$1"
  local cmd="$2"
  if ! grep -q "alias $name=" "$BASHRC" 2>/dev/null; then
    echo "alias $name='$cmd'" >> "$BASHRC"
    echo "  -> alias $name 추가됨"
  else
    echo "  -> alias $name 이미 있음"
  fi
}

# 기존 alias를 새 값으로 교체하거나 없으면 추가
set_alias() {
  local name="$1"
  local cmd="$2"
  if grep -q "alias $name=" "$BASHRC" 2>/dev/null; then
    sed -i "s|alias $name=.*|alias $name='$cmd'|" "$BASHRC"
    echo "  -> alias $name 업데이트됨"
  else
    echo "alias $name='$cmd'" >> "$BASHRC"
    echo "  -> alias $name 추가됨"
  fi
}

# cc: termux-bridge 폴더에서 claude 바로 실행
add_alias "cc" "cd $REPO_DIR && claude"
# cb: termux-bridge 폴더로 이동
add_alias "cb" "cd $REPO_DIR"
# pc: TTS 서버 bg 시작 + PC SSH 역방향 터널 (tts-bridge.sh)
set_alias "pc" "$REPO_DIR/tts-bridge.sh"

# 5. TTS 서버 자동 시작 (.bashrc에 한 번만 추가)
echo "[5/5] TTS 서버 자동 시작 설정..."
TTS_MARKER="# tts-server auto-start (termux-bridge)"
if ! grep -q "$TTS_MARKER" "$BASHRC" 2>/dev/null; then
  cat >> "$BASHRC" <<EOF

$TTS_MARKER
if ! pgrep -f "tts-server.sh" > /dev/null 2>&1; then
    nohup bash $REPO_DIR/tts-server.sh > \${TMPDIR:-/tmp}/tts-server.log 2>&1 &
fi
EOF
  echo "  -> TTS 서버 자동 시작 추가됨 (Termux 열 때 백그라운드 시작)"
else
  echo "  -> TTS 서버 자동 시작 이미 설정됨"
fi

echo ""
echo "=== 완료 ==="
echo ""
echo "  source ~/.bashrc  (alias 바로 적용)"
echo ""
echo "앞으로 사용법:"
echo "  pc        ← TTS 서버 시작 + PC SSH 접속 (원클릭)"
echo "  cc        ← termux-bridge에서 claude 바로 실행"
echo "  cb        ← termux-bridge 폴더 이동"
echo ""
echo "PC 접속 후:"
echo "  tts \"읽어줘\"          ← 폰이 읽어줌"
echo "  cc-tts \"프롬프트\"      ← Claude 응답도 폰이 읽어줌"
echo ""
