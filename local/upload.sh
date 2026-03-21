#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# termux-bridge / local/upload.sh  —  Termux → PC 파일 전송
#
# 사용법:
#   upload 파일경로          # 단일 파일
#   upload ~/storage/shared/DCIM/사진.png
#   upload 파일1 파일2 ...   # 다중 파일
#
# PC 수신 경로: ~/uploads/
# alias 등록:  ~/.bashrc 에 아래 줄 추가
#   alias upload='bash ~/termux-bridge/local/upload.sh'
# ═══════════════════════════════════════════════════════════════════════

PC_HOST="100.90.83.128"
PC_USER="dtsli"
PC_DEST="~/uploads/"

if [ $# -eq 0 ]; then
  echo "사용법: upload 파일경로 [파일경로2 ...]"
  echo "예시:   upload ~/storage/shared/DCIM/photo.png"
  exit 1
fi

echo "▶ PC로 전송 중... ($PC_HOST:$PC_DEST)"

for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "✗ 파일 없음: $file"
    continue
  fi
  filename=$(basename "$file")
  scp -q "$file" "${PC_USER}@${PC_HOST}:${PC_DEST}" && \
    echo "✓ $filename → PC ~/uploads/$filename" || \
    echo "✗ 전송 실패: $filename"
done
