#!/bin/bash
cd /data/data/com.termux/files/home/playwright-bot

# Start chromium
/data/data/com.termux/files/usr/bin/chromium-browser \
  --headless=new \
  --disable-gpu \
  --no-sandbox \
  --disable-setuid-sandbox \
  --disable-dev-shm-usage \
  --disable-software-rasterizer \
  --no-first-run \
  --no-zygote \
  --single-process \
  --remote-debugging-port=9223 \
  --window-size=412,915 \
  about:blank &

CHROME_PID=$!
echo "Chrome PID: $CHROME_PID"

# Wait longer for chromium startup
sleep 6

# Run the screenshot script
node screenshot-mobile.js "https://dtslib1979.github.io/buckley/" 2>&1

# Cleanup
kill $CHROME_PID 2>/dev/null
