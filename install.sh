#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# termux-bridge / install.sh  —  Universal Environment Installer
#
# Platforms : Termux (Android) · Ubuntu/Debian · macOS
# Output    : install/bom.json  →  phoneparis baptism 원장 자동 동기화
#
# Usage:
#   bash install.sh              # 전체 설치
#   bash install.sh --dry-run    # 설치 없이 체크만
#   bash install.sh --verify     # 이미 설치된 환경 검증만
#   bash install.sh --bom-only   # BOM JSON 생성만 (설치 없음)
# ═══════════════════════════════════════════════════════════════════════

set -uo pipefail
IFS=$'\n\t'

# ── 색상 ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

pass()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!!]${NC} $1"; }
fail()  { echo -e "${RED}[XX]${NC} $1"; }
info()  { echo -e "${BLUE}[--]${NC} $1"; }
head_() { echo -e "\n${BOLD}${CYAN}$1${NC}"; }

# ── 플래그 파싱 ──────────────────────────────────────────────────────────
DRY_RUN=false; VERIFY_ONLY=false; BOM_ONLY=false
for arg in "$@"; do
  case $arg in
    --dry-run)   DRY_RUN=true ;;
    --verify)    VERIFY_ONLY=true ;;
    --bom-only)  BOM_ONLY=true ;;
  esac
done

# ── 경로 ────────────────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$REPO_ROOT/install"
BOM_FILE="$INSTALL_DIR/bom.json"
mkdir -p "$INSTALL_DIR"

# ── 타임스탬프 ──────────────────────────────────────────────────────────
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# ── 플랫폼 감지 ──────────────────────────────────────────────────────────
detect_platform() {
  if [ -d "/data/data/com.termux" ] || [ -n "${TERMUX_VERSION:-}" ]; then
    echo "termux"
  elif [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
    echo "macos"
  elif [ -f /etc/debian_version ] || grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
    echo "ubuntu"
  elif [ -f /etc/os-release ]; then
    echo "linux"
  else
    echo "unknown"
  fi
}

PLATFORM=$(detect_platform)
CANONICAL=$( [ "$PLATFORM" = "termux" ] && echo "true" || echo "false" )

# ── 버전 캡처 헬퍼 ──────────────────────────────────────────────────────
ver() {
  local cmd="$1"; local flag="${2:---version}"
  "$cmd" $flag 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo ""
}

# ── 설치 함수 ────────────────────────────────────────────────────────────
pkg_install() {
  local pkg="$1"
  if $DRY_RUN || $VERIFY_ONLY || $BOM_ONLY; then return 0; fi
  case "$PLATFORM" in
    termux) pkg install -y "$pkg" 2>/dev/null ;;
    ubuntu) sudo apt-get install -y "$pkg" 2>/dev/null ;;
    macos)  brew install "$pkg" 2>/dev/null ;;
    *)      warn "Unknown platform — skipping $pkg" ;;
  esac
}

pip_install() {
  local pkg="$1"
  if $DRY_RUN || $VERIFY_ONLY || $BOM_ONLY; then return 0; fi
  pip install --quiet "$pkg" 2>/dev/null || pip3 install --quiet "$pkg" 2>/dev/null
}

npm_install_g() {
  local pkg="$1"
  if $DRY_RUN || $VERIFY_ONLY || $BOM_ONLY; then return 0; fi
  npm install -g "$pkg" --quiet 2>/dev/null
}

npm_install_local() {
  local pkg="$1"
  if $DRY_RUN || $VERIFY_ONLY || $BOM_ONLY; then return 0; fi
  cd "$REPO_ROOT" && npm install "$pkg" --quiet 2>/dev/null
}

# ── BOM 빌더 (JSON 조각 누적) ────────────────────────────────────────────
SYS_ENTRIES=""
PY_ENTRIES=""
NPM_ENTRIES=""
ANDROID_ENTRIES=""
BLOCKED_ENTRIES=""
PASS_COUNT=0; FAIL_COUNT=0; WARN_COUNT=0

bom_entry() {
  local name="$1" cmd="$2" verified="$3" version="$4" purpose="$5"
  local pkg_termux="${6:-$name}" pkg_apt="${7:-$name}" pkg_brew="${8:-$name}"
  printf '    {"name":"%s","cmd":"%s","pkg_termux":"%s","pkg_apt":"%s","pkg_brew":"%s","verified":%s,"verified_version":"%s","purpose":"%s"}' \
    "$name" "$cmd" "$pkg_termux" "$pkg_apt" "$pkg_brew" "$verified" "$version" "$purpose"
}

bom_blocked() {
  local name="$1" reason="$2" alternative="${3:-}"
  printf '    {"name":"%s","reason":"%s","alternative":"%s"}' "$name" "$reason" "$alternative"
}

append_sys()     { [ -n "$SYS_ENTRIES" ]     && SYS_ENTRIES="$SYS_ENTRIES,"$'\n';     SYS_ENTRIES="$SYS_ENTRIES$1"; }
append_py()      { [ -n "$PY_ENTRIES" ]      && PY_ENTRIES="$PY_ENTRIES,"$'\n';       PY_ENTRIES="$PY_ENTRIES$1"; }
append_npm()     { [ -n "$NPM_ENTRIES" ]     && NPM_ENTRIES="$NPM_ENTRIES,"$'\n';     NPM_ENTRIES="$NPM_ENTRIES$1"; }
append_android() { [ -n "$ANDROID_ENTRIES" ] && ANDROID_ENTRIES="$ANDROID_ENTRIES,"$'\n'; ANDROID_ENTRIES="$ANDROID_ENTRIES$1"; }
append_blocked() { [ -n "$BLOCKED_ENTRIES" ] && BLOCKED_ENTRIES="$BLOCKED_ENTRIES,"$'\n'; BLOCKED_ENTRIES="$BLOCKED_ENTRIES$1"; }

# ── 패키지 처리 함수 ──────────────────────────────────────────────────────
handle_sys() {
  local name="$1" cmd="$2" pkg_t="${3:-$name}" pkg_a="${4:-$name}" pkg_b="${5:-$name}" purpose="${6:-}"
  local platform_pkg
  case "$PLATFORM" in termux) platform_pkg="$pkg_t" ;; macos) platform_pkg="$pkg_b" ;; *) platform_pkg="$pkg_a" ;; esac

  if ! command -v "$cmd" &>/dev/null; then
    pkg_install "$platform_pkg"
  fi

  if command -v "$cmd" &>/dev/null; then
    local v; v=$(ver "$cmd")
    pass "$name $v"
    append_sys "$(bom_entry "$name" "$cmd" "true" "$v" "$purpose" "$pkg_t" "$pkg_a" "$pkg_b")"
    PASS_COUNT=$((PASS_COUNT+1))
  else
    fail "$name (설치 실패)"
    append_sys "$(bom_entry "$name" "$cmd" "false" "" "$purpose" "$pkg_t" "$pkg_a" "$pkg_b")"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi
}

handle_py() {
  local name="$1" import="$2" purpose="${3:-}"
  if ! python3 -c "import $import" &>/dev/null 2>&1; then
    pip_install "$name"
  fi
  if python3 -c "import $import" &>/dev/null 2>&1; then
    local v; v=$(python3 -c "import importlib.metadata; print(importlib.metadata.version('$name'))" 2>/dev/null || echo "")
    pass "pip:$name $v"
    append_py "$(printf '    {"name":"%s","import":"%s","verified":true,"verified_version":"%s","purpose":"%s"}' "$name" "$import" "$v" "$purpose")"
    PASS_COUNT=$((PASS_COUNT+1))
  else
    fail "pip:$name (설치 실패)"
    append_py "$(printf '    {"name":"%s","import":"%s","verified":false,"verified_version":"","purpose":"%s"}' "$name" "$import" "$purpose")"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi
}

handle_npm_g() {
  local name="$1" cmd="${2:-$name}" purpose="${3:-}"
  if ! command -v "$cmd" &>/dev/null; then
    npm_install_g "$name"
  fi
  if command -v "$cmd" &>/dev/null; then
    local v; v=$(npm list -g "$name" --depth=0 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
    pass "npm:$name $v"
    append_npm "$(printf '    {"name":"%s","scope":"global","verified":true,"verified_version":"%s","purpose":"%s"}' "$name" "$v" "$purpose")"
    PASS_COUNT=$((PASS_COUNT+1))
  else
    fail "npm:$name (설치 실패)"
    append_npm "$(printf '    {"name":"%s","scope":"global","verified":false,"verified_version":"","purpose":"%s"}' "$name" "$purpose")"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi
}

handle_npm_local() {
  local name="$1" purpose="${2:-}"
  local installed; installed=$(node -e "require('$name')" 2>/dev/null && echo "yes" || echo "no")
  if [ "$installed" = "no" ]; then
    npm_install_local "$name"
    installed=$(node -e "require('$name')" 2>/dev/null && echo "yes" || echo "no")
  fi
  if [ "$installed" = "yes" ]; then
    local v; v=$(node -e "console.log(require('$REPO_ROOT/node_modules/$name/package.json').version)" 2>/dev/null || echo "")
    pass "npm:$name@local $v"
    append_npm "$(printf '    {"name":"%s","scope":"local","verified":true,"verified_version":"%s","purpose":"%s"}' "$name" "$v" "$purpose")"
    PASS_COUNT=$((PASS_COUNT+1))
  else
    fail "npm:$name@local (설치 실패)"
    append_npm "$(printf '    {"name":"%s","scope":"local","verified":false,"verified_version":"","purpose":"%s"}' "$name" "$purpose")"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi
}

# ── Android 앱 감지 (Termux 전용 — APK는 자동설치 불가, 감지만) ──────────
handle_android_app() {
  local name="$1" pkg_id="$2" purpose="$3" install_url="$4" termux_tool="${5:-}"

  if [ "$PLATFORM" != "termux" ]; then
    warn "android_app:$name — Termux 전용, 현재 플랫폼 스킵"
    WARN_COUNT=$((WARN_COUNT+1))
    append_android "$(printf '    {"name":"%s","package":"%s","verified":false,"verified_version":"","purpose":"%s","layer":"system","install_url":"%s","termux_tool":"%s","note":"non-termux platform"}' \
      "$name" "$pkg_id" "$purpose" "$install_url" "$termux_tool")"
    return
  fi

  # pm 명령으로 설치 여부 확인 (Termux에서 접근 가능한 경우)
  local installed=false
  local ver_str=""

  # 방법 1: pm list packages (일부 Android 버전에서 가능)
  if pm list packages 2>/dev/null | grep -q "$pkg_id"; then
    installed=true
    ver_str=$(pm dump "$pkg_id" 2>/dev/null | grep "versionName" | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "")
  # 방법 2: adb 연결된 경우 adb shell pm
  elif command -v adb &>/dev/null && adb devices 2>/dev/null | grep -q "localhost"; then
    if adb shell pm list packages 2>/dev/null | grep -q "$pkg_id"; then
      installed=true
      ver_str=$(adb shell pm dump "$pkg_id" 2>/dev/null | grep "versionName" | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "")
    fi
  fi

  if $installed; then
    pass "android:$name $ver_str"
    append_android "$(printf '    {"name":"%s","package":"%s","verified":true,"verified_version":"%s","purpose":"%s","layer":"system","install_url":"%s","termux_tool":"%s"}' \
      "$name" "$pkg_id" "$ver_str" "$purpose" "$install_url" "$termux_tool")"
    PASS_COUNT=$((PASS_COUNT+1))
  else
    warn "android:$name — 미설치 (수동 설치 필요)"
    warn "  설치: $install_url"
    append_android "$(printf '    {"name":"%s","package":"%s","verified":false,"verified_version":"","purpose":"%s","layer":"system","install_url":"%s","termux_tool":"%s","note":"manual install required"}' \
      "$name" "$pkg_id" "$purpose" "$install_url" "$termux_tool")"
    WARN_COUNT=$((WARN_COUNT+1))
  fi
}

# ════════════════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║   termux-bridge  /  Universal Installer      ║"
echo "║   phoneparis baptism 원장 자동 생성 포함       ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
info "Platform  : ${BOLD}$PLATFORM${NC}"
info "Canonical : $CANONICAL  (Termux = 원장 기준)"
info "Mode      : $( $DRY_RUN && echo "DRY RUN" || $VERIFY_ONLY && echo "VERIFY ONLY" || $BOM_ONLY && echo "BOM ONLY" || echo "INSTALL + VERIFY")"
info "Timestamp : $TIMESTAMP"

# ── Termux: x11-repo 사전 설정 ──────────────────────────────────────────
if [ "$PLATFORM" = "termux" ] && ! $DRY_RUN && ! $VERIFY_ONLY && ! $BOM_ONLY; then
  head_ "► Termux x11-repo 설정"
  if ! pkg list-installed 2>/dev/null | grep -q "x11-repo"; then
    pkg install -y x11-repo 2>/dev/null && pass "x11-repo enabled" || warn "x11-repo 설정 실패 (chromium 설치 불가)"
  else
    pass "x11-repo already enabled"
  fi
fi

# ── Ubuntu: 사전 업데이트 ───────────────────────────────────────────────
if [ "$PLATFORM" = "ubuntu" ] && ! $DRY_RUN && ! $VERIFY_ONLY && ! $BOM_ONLY; then
  head_ "► apt 업데이트"
  sudo apt-get update -qq 2>/dev/null && pass "apt updated"
fi

# ── macOS: Homebrew 확인 ────────────────────────────────────────────────
if [ "$PLATFORM" = "macos" ] && ! command -v brew &>/dev/null; then
  warn "Homebrew 미설치. https://brew.sh 참조"
fi

# ── 시스템 패키지 ────────────────────────────────────────────────────────
head_ "► System Packages"
handle_sys "git"          "git"          "git"            "git"             "git"          "버전 관리"
handle_sys "node"         "node"         "nodejs"         "nodejs"          "node"         "JS 런타임"
handle_sys "python"       "python3"      "python"         "python3"         "python3"      "Python 런타임"
handle_sys "ffmpeg"       "ffmpeg"       "ffmpeg"         "ffmpeg"          "ffmpeg"       "오디오/비디오 처리"
handle_sys "gh"           "gh"           "gh"             "gh"              "gh"           "GitHub CLI"
handle_sys "imagemagick"  "convert"      "imagemagick"    "imagemagick"     "imagemagick"  "이미지 변환/처리"
handle_sys "jq"           "jq"           "jq"             "jq"              "jq"           "JSON 처리"
handle_sys "poppler"      "pdftotext"    "poppler"        "poppler-utils"   "poppler"      "PDF 도구"
handle_sys "rclone"       "rclone"       "rclone"         "rclone"          "rclone"       "Google Drive 동기화"
handle_sys "rsync"        "rsync"        "rsync"          "rsync"           "rsync"        "파일 동기화"
handle_sys "tree"         "tree"         "tree"           "tree"            "tree"         "디렉토리 시각화"
handle_sys "wget"         "wget"         "wget"           "wget"            "wget"         "파일 다운로드"
# android-tools: adb 바이너리 — shizuku.sh 사전조건
handle_sys "android-tools" "adb"         "android-tools"  "android-tools"   "android-platform-tools" "ADB 바이너리 (shizuku.sh 사전조건)"

# Termux 전용 패키지
if [ "$PLATFORM" = "termux" ]; then
  handle_sys "chromium"   "chromium-browser" "chromium"   "" ""              "CDP 스크린샷용 (x11-repo)"
  handle_sys "cmake"      "cmake"            "cmake"      "cmake"  "cmake"   "빌드 도구"
  handle_sys "ninja"      "ninja"            "ninja-build" "ninja-build" "ninja" "빌드 도구"
  handle_sys "termux-api" "termux-microphone-record" "termux-api" "" ""      "핸드폰 하드웨어 접근"
else
  warn "chromium/termux-api: Termux 전용 패키지 — 현재 플랫폼 스킵"
  WARN_COUNT=$((WARN_COUNT+1))
fi

# ── Python 패키지 ────────────────────────────────────────────────────────
head_ "► Python Packages"
if command -v python3 &>/dev/null && { command -v pip &>/dev/null || command -v pip3 &>/dev/null; }; then
  handle_py "pillow"   "PIL"      "이미지 처리 (OpenCV 대체)"
  handle_py "numpy"    "numpy"    "수치 연산"
  handle_py "requests" "requests" "HTTP 클라이언트"
else
  warn "pip 미설치 — Python 패키지 스킵"
  WARN_COUNT=$((WARN_COUNT+1))
fi

# ── npm 패키지 ───────────────────────────────────────────────────────────
head_ "► npm Packages"
if command -v npm &>/dev/null; then
  handle_npm_g     "claude"  "claude"  "Claude Code CLI"
  handle_npm_local "ws"                "CDP WebSocket 연결"
else
  warn "npm 미설치 — npm 패키지 스킵"
  WARN_COUNT=$((WARN_COUNT+1))
fi

# ── Android 앱 (감지 전용 — 수동 설치 필요) ─────────────────────────────
head_ "► Android Apps (Termux 전용 — 감지만, 수동 설치)"
handle_android_app \
  "Shizuku" \
  "moe.shizuku.privileged.api" \
  "ADB급 시스템 권한 — 루트 없이. APK 설치·권한 관리·앱 제어" \
  "https://shizuku.rikka.app" \
  "local/shizuku.sh"

# ── Blocked ───────────────────────────────────────────────────────────────
head_ "► Blocked (설치 불가 — 대안 사용)"
append_blocked "$(bom_blocked "opencv-python" "aarch64 빌드 실패"           "pillow")"
append_blocked "$(bom_blocked "scipy"          "빌드 실패"                   "numpy")"
append_blocked "$(bom_blocked "puppeteer"      "Android 미지원"              "CDP 직접 연결")"
append_blocked "$(bom_blocked "playwright"     "Android 미지원 (Termux)"     "GitHub Actions")"
append_blocked "$(bom_blocked "docker"         "커널 제약"                   "불가")"
append_blocked "$(bom_blocked "lighthouse"     "빌드 실패"                   "GitHub Actions")"
append_blocked "$(bom_blocked "tasker"         "코드로 만들 수 있는 걸 GUI 자동화 도구로 대체 불필요" "APK/PWA 직접 제작")"
info "opencv→pillow, puppeteer/playwright→CDP+Actions, tasker→직접제작"

# ── BOM JSON 생성 ────────────────────────────────────────────────────────
head_ "► BOM 생성 → install/bom.json"

cat > "$BOM_FILE" <<EOF
{
  "_meta": {
    "source": "termux-bridge",
    "ledger_version": "3.0",
    "description": "PC ↔ Termux 간극을 메우는 도구 모음 — 검증된 패키지 원장",
    "generated": "$TIMESTAMP",
    "platform": "$PLATFORM",
    "canonical": $CANONICAL,
    "note": "canonical=true (Termux) 일 때만 phoneparis baptism 원장으로 사용",
    "repo": "https://github.com/dtslib1979/termux-bridge",
    "sync_target": "phoneparis/tools/baptism/config/packages.json"
  },
  "system": [
$SYS_ENTRIES
  ],
  "python": [
$PY_ENTRIES
  ],
  "npm": [
$NPM_ENTRIES
  ],
  "android_apps": [
$ANDROID_ENTRIES
  ],
  "blocked": [
$BLOCKED_ENTRIES
  ]
}
EOF

pass "install/bom.json 생성 완료"

# ── 요약 ─────────────────────────────────────────────────────────────────
head_ "► 설치 결과"
echo -e "${GREEN}PASS${NC} $PASS_COUNT  ${YELLOW}WARN${NC} $WARN_COUNT  ${RED}FAIL${NC} $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
  warn "일부 패키지 설치 실패. 위 [XX] 항목 확인"
fi

# ── Shizuku 설치 안내 (미설치인 경우) ───────────────────────────────────
if [ "$PLATFORM" = "termux" ] && echo "$ANDROID_ENTRIES" | grep -q '"Shizuku".*"verified":false'; then
  head_ "► Shizuku 설치 안내 (필수)"
  echo -e "${YELLOW}Shizuku가 미설치되어 있습니다.${NC}"
  echo ""
  echo "1. Play Store 또는 F-Droid에서 Shizuku 설치:"
  echo "   https://shizuku.rikka.app"
  echo ""
  echo "2. 설치 후 설정 → 개발자 옵션 → 무선 디버깅 활성화"
  echo ""
  echo "3. Shizuku 앱 실행 → '무선 디버깅으로 시작' 선택"
  echo ""
  echo "4. Termux에서 연결:"
  echo "   bash local/shizuku.sh pair     # 최초 1회"
  echo "   bash local/shizuku.sh status   # 상태 확인"
fi

# ── phoneparis 동기화 안내 ──────────────────────────────────────────────
head_ "► phoneparis baptism 동기화"
if [ "$CANONICAL" = "true" ]; then
  echo -e "${GREEN}이 기기가 Termux(원장 기준)입니다.${NC}"
  echo "다음 명령으로 phoneparis BOM을 업데이트하세요:"
  echo ""
  echo -e "  ${CYAN}cp install/bom.json ../phoneparis/tools/baptism/config/packages.json${NC}"
  echo -e "  ${CYAN}cd ../phoneparis && git add tools/baptism/config/packages.json${NC}"
  echo -e "  ${CYAN}git commit -m 'baptism: BOM sync from termux-bridge $TIMESTAMP'${NC}"
  echo -e "  ${CYAN}git push${NC}"
else
  warn "비Termux 환경 — 이 BOM은 참고용입니다. phoneparis 원장은 Termux에서 생성하세요."
fi

echo ""
info "BOM 파일: $BOM_FILE"
info "완료: $TIMESTAMP"
echo ""
