#!/data/data/com.termux/files/usr/bin/bash
# run-snap.sh — snap.js 래퍼 (Tasker 등 외부 호출용)
export TMPDIR=/data/data/com.termux/files/usr/tmp
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node "$SCRIPT_DIR/snap.js" "$@" > "$SCRIPT_DIR/../snap.log" 2>&1
echo "EXIT:$?"
