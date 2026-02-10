#!/data/data/com.termux/files/usr/bin/bash
export TMPDIR=/data/data/com.termux/files/usr/tmp
node /data/data/com.termux/files/home/playwright-bot/snap.js "$@" > /data/data/com.termux/files/home/playwright-bot/snap.log 2>&1
echo "EXIT:$?"
