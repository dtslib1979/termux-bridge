#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# local/shizuku.sh — Shizuku + Wireless ADB 유틸리티 for Termux
#
# Termux에서 ADB급 권한으로 Android 시스템 제어
# Termux(쉘 레이어) 위의 시스템 레이어를 담당
#
# 사전조건:
#   1. pkg install android-tools          (adb 바이너리)
#   2. 설정 → 개발자 옵션 → 무선 디버깅 활성화
#   3. bash shizuku.sh pair               (최초 1회 페어링)
#
# 사용법:
#   bash shizuku.sh status               # 연결 상태
#   bash shizuku.sh pair                 # 무선 디버깅 페어링 (최초 1회)
#   bash shizuku.sh connect              # 재연결
#   bash shizuku.sh install <apk>        # APK 설치
#   bash shizuku.sh grant <pkg> <perm>   # 권한 부여
#   bash shizuku.sh revoke <pkg> <perm>  # 권한 제거
#   bash shizuku.sh clear <pkg>          # 앱 데이터 삭제
#   bash shizuku.sh enable <pkg>         # 앱 활성화
#   bash shizuku.sh disable <pkg>        # 앱 비활성화
#   bash shizuku.sh list [filter]        # 설치된 앱 목록
#   bash shizuku.sh info <pkg>           # 앱 상세 정보
#   bash shizuku.sh shell                # ADB 인터랙티브 쉘
#   bash shizuku.sh perms <pkg>          # 앱 권한 목록
# ═══════════════════════════════════════════════════════════════════════

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
err()  { echo -e "${RED}[XX]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[!!]${NC} $*"; }
info() { echo -e "${BLUE}[--]${NC} $*"; }

CMD="${1:-status}"
shift || true

# ── adb 설치 확인 ────────────────────────────────────────────────────────
check_adb() {
  if ! command -v adb &>/dev/null; then
    err "adb 미설치. 다음 명령으로 설치:"
    echo "  pkg install android-tools"
    exit 1
  fi
}

# ── ADB 연결 상태 확인 ────────────────────────────────────────────────────
is_connected() {
  adb devices 2>/dev/null | grep -q "localhost"
}

# ── 연결 필요 시 안내 ────────────────────────────────────────────────────
require_connection() {
  if ! is_connected; then
    warn "ADB 미연결. 먼저 연결하세요:"
    echo "  bash shizuku.sh pair      # 최초 1회 페어링"
    echo "  bash shizuku.sh connect   # 이후 재연결"
    exit 1
  fi
}

# ════════════════════════════════════════════════════════════════════════
# COMMANDS
# ════════════════════════════════════════════════════════════════════════

cmd_status() {
  check_adb
  echo -e "${BOLD}${CYAN}── Shizuku / Wireless ADB 상태 ──────────────────${NC}"
  echo ""
  info "adb 버전: $(adb version 2>/dev/null | head -1)"
  echo ""

  local devices; devices=$(adb devices 2>/dev/null)
  if echo "$devices" | grep -q "localhost"; then
    ok "ADB 연결됨"
    echo "$devices" | grep "localhost" | while read -r line; do
      info "  $line"
    done
    echo ""
    info "Android 버전: $(adb shell getprop ro.build.version.release 2>/dev/null)"
    info "모델:         $(adb shell getprop ro.product.model 2>/dev/null)"
    info "SDK:          $(adb shell getprop ro.build.version.sdk 2>/dev/null)"
  else
    warn "ADB 미연결"
    echo ""
    echo "연결 방법:"
    echo "  1. 설정 → 개발자 옵션 → 무선 디버깅 활성화"
    echo "  2. bash shizuku.sh pair   (최초 1회)"
    echo "  3. bash shizuku.sh connect"
  fi
}

cmd_pair() {
  check_adb
  echo -e "${BOLD}${CYAN}── 무선 디버깅 페어링 (최초 1회) ───────────────${NC}"
  echo ""
  warn "설정 → 개발자 옵션 → 무선 디버깅 → 기기 페어링 (페어링 코드 사용)"
  echo ""
  read -r -p "페어링 포트 번호 입력: " PAIR_PORT
  read -r -p "페어링 코드 입력: " PAIR_CODE
  echo ""
  info "페어링 시도 중..."
  if adb pair "localhost:$PAIR_PORT" "$PAIR_CODE"; then
    ok "페어링 완료"
    echo ""
    cmd_connect
  else
    err "페어링 실패. 포트/코드 확인 후 재시도"
    exit 1
  fi
}

cmd_connect() {
  check_adb
  echo -e "${BOLD}${CYAN}── ADB 연결 ─────────────────────────────────────${NC}"
  echo ""

  # 이미 연결된 경우
  if is_connected; then
    ok "이미 연결됨"
    return 0
  fi

  warn "설정 → 개발자 옵션 → 무선 디버깅에서 포트 번호 확인"
  read -r -p "연결 포트 번호 입력: " CONN_PORT
  echo ""
  info "연결 시도: localhost:$CONN_PORT"
  if adb connect "localhost:$CONN_PORT" | grep -q "connected"; then
    ok "연결 성공"
  else
    err "연결 실패. 무선 디버깅 포트 확인"
    exit 1
  fi
}

cmd_install() {
  check_adb; require_connection
  local apk="${1:-}"
  [ -z "$apk" ] && { err "사용법: shizuku.sh install <apk 경로>"; exit 1; }
  [ ! -f "$apk" ] && { err "파일 없음: $apk"; exit 1; }
  info "APK 설치 중: $apk"
  if adb install -r "$apk"; then
    ok "설치 완료: $apk"
  else
    err "설치 실패"
    exit 1
  fi
}

cmd_grant() {
  check_adb; require_connection
  local pkg="${1:-}" perm="${2:-}"
  [ -z "$pkg" ] || [ -z "$perm" ] && { err "사용법: shizuku.sh grant <패키지> <권한>"; exit 1; }
  info "권한 부여: $pkg → $perm"
  adb shell pm grant "$pkg" "$perm" && ok "완료" || err "실패"
}

cmd_revoke() {
  check_adb; require_connection
  local pkg="${1:-}" perm="${2:-}"
  [ -z "$pkg" ] || [ -z "$perm" ] && { err "사용법: shizuku.sh revoke <패키지> <권한>"; exit 1; }
  info "권한 제거: $pkg → $perm"
  adb shell pm revoke "$pkg" "$perm" && ok "완료" || err "실패"
}

cmd_clear() {
  check_adb; require_connection
  local pkg="${1:-}"
  [ -z "$pkg" ] && { err "사용법: shizuku.sh clear <패키지>"; exit 1; }
  warn "앱 데이터 삭제: $pkg"
  read -r -p "계속하시겠습니까? (y/N): " confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { info "취소됨"; exit 0; }
  adb shell pm clear "$pkg" && ok "완료" || err "실패"
}

cmd_enable() {
  check_adb; require_connection
  local pkg="${1:-}"
  [ -z "$pkg" ] && { err "사용법: shizuku.sh enable <패키지>"; exit 1; }
  adb shell pm enable "$pkg" && ok "활성화: $pkg" || err "실패"
}

cmd_disable() {
  check_adb; require_connection
  local pkg="${1:-}"
  [ -z "$pkg" ] && { err "사용법: shizuku.sh disable <패키지>"; exit 1; }
  warn "앱 비활성화: $pkg"
  adb shell pm disable-user "$pkg" && ok "비활성화: $pkg" || err "실패"
}

cmd_list() {
  check_adb; require_connection
  local filter="${1:-}"
  info "설치된 앱 목록${filter:+ (필터: $filter)}"
  echo ""
  if [ -n "$filter" ]; then
    adb shell pm list packages | grep -i "$filter" | sed 's/package://' | sort
  else
    adb shell pm list packages | sed 's/package://' | sort
  fi
}

cmd_info() {
  check_adb; require_connection
  local pkg="${1:-}"
  [ -z "$pkg" ] && { err "사용법: shizuku.sh info <패키지>"; exit 1; }
  echo -e "${BOLD}${CYAN}── $pkg ──${NC}"
  adb shell dumpsys package "$pkg" 2>/dev/null | grep -E \
    "versionName|versionCode|firstInstallTime|lastUpdateTime|userId|targetSdk|flags" \
    | head -20
}

cmd_perms() {
  check_adb; require_connection
  local pkg="${1:-}"
  [ -z "$pkg" ] && { err "사용법: shizuku.sh perms <패키지>"; exit 1; }
  echo -e "${BOLD}${CYAN}── $pkg 권한 ──${NC}"
  echo ""
  info "부여된 권한:"
  adb shell dumpsys package "$pkg" 2>/dev/null \
    | grep -A1 "granted=true" | grep "permission" | sed 's/.*: /  /' | sort
  echo ""
  info "거부된 권한:"
  adb shell dumpsys package "$pkg" 2>/dev/null \
    | grep -A1 "granted=false" | grep "permission" | sed 's/.*: /  /' | sort
}

cmd_shell() {
  check_adb; require_connection
  info "ADB 인터랙티브 쉘 (exit 으로 종료)"
  echo ""
  adb shell
}

cmd_help() {
  echo -e "${BOLD}${CYAN}shizuku.sh — Termux ADB 유틸리티${NC}"
  echo ""
  echo "사용법: bash shizuku.sh <명령> [인자]"
  echo ""
  echo -e "${BOLD}연결 관리:${NC}"
  echo "  status              ADB 연결 상태 확인"
  echo "  pair                무선 디버깅 페어링 (최초 1회)"
  echo "  connect             ADB 재연결"
  echo ""
  echo -e "${BOLD}앱 관리:${NC}"
  echo "  install <apk>       APK 설치"
  echo "  clear <pkg>         앱 데이터 삭제"
  echo "  enable <pkg>        앱 활성화"
  echo "  disable <pkg>       앱 비활성화"
  echo "  list [filter]       설치된 앱 목록"
  echo "  info <pkg>          앱 상세 정보"
  echo ""
  echo -e "${BOLD}권한 관리:${NC}"
  echo "  grant <pkg> <perm>  권한 부여"
  echo "  revoke <pkg> <perm> 권한 제거"
  echo "  perms <pkg>         권한 목록"
  echo ""
  echo -e "${BOLD}시스템:${NC}"
  echo "  shell               ADB 인터랙티브 쉘"
  echo ""
  echo -e "${BOLD}사전 설치:${NC}"
  echo "  pkg install android-tools"
}

# ── 라우터 ────────────────────────────────────────────────────────────────
case "$CMD" in
  status)   cmd_status ;;
  pair)     cmd_pair ;;
  connect)  cmd_connect ;;
  install)  cmd_install "$@" ;;
  grant)    cmd_grant "$@" ;;
  revoke)   cmd_revoke "$@" ;;
  clear)    cmd_clear "$@" ;;
  enable)   cmd_enable "$@" ;;
  disable)  cmd_disable "$@" ;;
  list)     cmd_list "${1:-}" ;;
  info)     cmd_info "$@" ;;
  perms)    cmd_perms "$@" ;;
  shell)    cmd_shell ;;
  help|--help|-h) cmd_help ;;
  *) err "알 수 없는 명령: $CMD"; echo ""; cmd_help; exit 1 ;;
esac
