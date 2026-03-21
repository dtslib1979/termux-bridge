#!/data/data/com.termux/files/usr/bin/bash
# termux-bridge setup — 새 기기에서 Claude Code 환경 원클릭 세팅
# 사용법: curl -fsSL https://raw.githubusercontent.com/dtslib1979/termux-bridge/main/setup.sh | bash

set -e

REPO_URL="https://github.com/dtslib1979/termux-bridge.git"
REPO_DIR="$HOME/termux-bridge"
BASHRC="$HOME/.bashrc"
PC_IP="100.90.83.128"
PC_PORT="2222"
PC_USER="dtsli"

echo "=== termux-bridge setup ==="

# 1. 필수 패키지 설치
echo "[1/6] 시스템 패키지 확인..."
pkg install -y nodejs git gh autossh 2>/dev/null || true

# 2. Claude Code 전역 설치
echo "[2/6] Claude Code 설치..."
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
  echo "  -> claude-code 설치 완료"
else
  echo "  -> claude-code 이미 설치됨 ($(claude --version 2>/dev/null || echo '버전확인불가'))"
fi

# 3. 레포 클론 또는 업데이트
echo "[3/6] termux-bridge 레포 준비..."
if [ -d "$REPO_DIR/.git" ]; then
  echo "  -> 이미 존재, pull..."
  git -C "$REPO_DIR" pull origin main
else
  echo "  -> 클론 중..."
  git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR" && npm install

# 4. SSH 클라이언트 keepalive 설정
echo "[4/6] SSH 클라이언트 keepalive 설정..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
SSH_CONFIG="$HOME/.ssh/config"
PC_HOST_BLOCK="Host pc-wsl
    HostName $PC_IP
    Port $PC_PORT
    User $PC_USER
    ServerAliveInterval 30
    ServerAliveCountMax 3
    TCPKeepAlive yes
    ConnectTimeout 10"

if grep -q "Host pc-wsl" "$SSH_CONFIG" 2>/dev/null; then
  # 기존 블록 교체
  python3 - <<PYEOF
import re, os
config_path = os.path.expanduser("~/.ssh/config")
with open(config_path, "r") as f:
    content = f.read()
block = """$PC_HOST_BLOCK"""
# Host pc-wsl 블록 통째로 교체
new_content = re.sub(r'Host pc-wsl\n(?:[ \t]+.*\n?)*', block + "\n\n", content)
with open(config_path, "w") as f:
    f.write(new_content)
PYEOF
  echo "  -> ~/.ssh/config pc-wsl 블록 업데이트됨"
else
  echo "" >> "$SSH_CONFIG"
  echo "$PC_HOST_BLOCK" >> "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  echo "  -> ~/.ssh/config pc-wsl 블록 추가됨"
fi

# 5. .bashrc alias 세팅
echo "[5/6] alias 세팅..."

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
# pc: autossh로 PC 접속 — 끊기면 자동 재접속, claude-main tmux에 attach
set_alias "pc" "autossh -M 0 -o 'ServerAliveInterval 30' -o 'ServerAliveCountMax 3' -o 'TCPKeepAlive yes' -p $PC_PORT ${PC_USER}@${PC_IP} -t 'tmux attach -t claude-main || tmux new-session -s claude-main'"

echo "[6/6] TTS 자동시작 제거 확인 (롤백됨)..."
TTS_MARKER="# tts-server auto-start (termux-bridge)"
if grep -q "$TTS_MARKER" "$BASHRC" 2>/dev/null; then
  # TTS 자동시작 블록 제거
  sed -i "/$TTS_MARKER/,/^fi$/d" "$BASHRC"
  echo "  -> TTS 자동시작 제거됨"
else
  echo "  -> TTS 자동시작 없음 (정상)"
fi

echo ""
echo "=== 완료 ==="
echo ""
echo "  source ~/.bashrc  (alias 바로 적용)"
echo ""
echo "사용법:"
echo "  pc   ← PC 접속 (autossh — 끊겨도 자동 재접속)"
echo "  cc   ← termux-bridge에서 claude 바로 실행"
echo "  cb   ← termux-bridge 폴더 이동"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  수동 필수 — 안드로이드 배터리 최적화 해제"
echo "   설정 → 배터리 → 앱별 최적화 → Termux → 제한 없음"
echo "   (안 하면 화면 꺼지고 10분 후 Termux 프로세스 사망)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
