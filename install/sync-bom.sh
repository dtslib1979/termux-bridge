#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# install/sync-bom.sh — BOM → phoneparis baptism 자동 동기화
#
# termux-bridge install/bom.json
#   → phoneparis/tools/baptism/config/packages.json
#
# 사전조건:
#   1. bash install.sh (또는 --bom-only) 실행 완료
#   2. phoneparis 레포가 ../phoneparis 에 존재
#   3. phoneparis에 커밋 권한 있는 gh 인증 완료
#
# 사용법:
#   bash install/sync-bom.sh
#   PHONEPARIS_DIR=/path/to/phoneparis bash install/sync-bom.sh
# ═══════════════════════════════════════════════════════════════════════

set -uo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
err()  { echo -e "${RED}[XX]${NC} $*" >&2; exit 1; }
warn() { echo -e "${YELLOW}[!!]${NC} $*"; }
info() { echo -e "${BLUE}[--]${NC} $*"; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PHONEPARIS_DIR="${PHONEPARIS_DIR:-$REPO_ROOT/../phoneparis}"
BOM_SRC="$REPO_ROOT/install/bom.json"
BOM_DST="$PHONEPARIS_DIR/tools/baptism/config/packages.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

info "BOM 소스 : $BOM_SRC"
info "sync 대상: $BOM_DST"
echo ""

# ── 검증 ─────────────────────────────────────────────────────────────────
[ ! -f "$BOM_SRC" ] && err "BOM 파일 없음. 먼저 실행: bash install.sh --bom-only"

# canonical 체크 (Termux에서 생성된 BOM인지)
if command -v jq &>/dev/null; then
  canonical=$(jq -r '._meta.canonical' "$BOM_SRC" 2>/dev/null || echo "unknown")
  platform=$(jq -r '._meta.platform' "$BOM_SRC" 2>/dev/null || echo "unknown")
  generated=$(jq -r '._meta.generated' "$BOM_SRC" 2>/dev/null || echo "unknown")
  info "BOM 플랫폼  : $platform"
  info "BOM canonical: $canonical"
  info "BOM 생성일   : $generated"
  echo ""
  if [ "$canonical" != "true" ]; then
    warn "canonical=false — 비Termux 환경에서 생성된 BOM입니다."
    warn "phoneparis 원장은 Termux(canonical=true) BOM만 사용해야 합니다."
    read -r -p "그래도 계속하시겠습니까? (y/N): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { info "취소됨"; exit 0; }
  fi
fi

[ ! -d "$PHONEPARIS_DIR" ] && err "phoneparis 레포 없음: $PHONEPARIS_DIR\n  PHONEPARIS_DIR=/경로/to/phoneparis bash install/sync-bom.sh"

DST_DIR="$(dirname "$BOM_DST")"
[ ! -d "$DST_DIR" ] && err "대상 디렉토리 없음: $DST_DIR\n  phoneparis/tools/baptism/config/ 확인 필요"

# ── 복사 ─────────────────────────────────────────────────────────────────
cp "$BOM_SRC" "$BOM_DST"
ok "BOM 복사 완료: $BOM_DST"

# ── phoneparis git 커밋 + 푸시 ─────────────────────────────────────────
cd "$PHONEPARIS_DIR"

git add tools/baptism/config/packages.json

if git diff --staged --quiet; then
  info "BOM 변경 없음 — 커밋 스킵"
  exit 0
fi

git commit -m "baptism: BOM sync from termux-bridge — $TIMESTAMP"
ok "phoneparis 커밋 완료"

git push
ok "phoneparis 푸시 완료"

echo ""
ok "BOM 동기화 완료: termux-bridge → phoneparis"
info "시각: $TIMESTAMP"
