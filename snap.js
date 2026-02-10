#!/usr/bin/env node

// snap.js — Claude-friendly screenshot tool
// Usage: node snap.js <URL> [options]
//   --mobile    Mobile viewport (390x844)
//   --full      Full page (capped at 4000px height)
//   --quality N JPEG quality 1-100 (default: 70)
//   --name X    Custom filename prefix

const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');

const CHROMIUM_PATH = '/data/data/com.termux/files/usr/bin/chromium-browser';
const OUTPUT_DIR = path.join(__dirname, 'screenshots');
const DEBUG_PORT = 9225;
const MAX_FULL_HEIGHT = 4000;

// Parse args
const args = process.argv.slice(2);
const url = args.find(a => !a.startsWith('--'));
const isMobile = args.includes('--mobile');
const isFull = args.includes('--full');
const qualityIdx = args.indexOf('--quality');
const quality = qualityIdx !== -1 ? parseInt(args[qualityIdx + 1]) : 70;
const nameIdx = args.indexOf('--name');
const customName = nameIdx !== -1 ? args[nameIdx + 1] : null;

if (!url) {
  console.log(`Usage: node snap.js <URL> [options]
  --mobile    Mobile viewport (390x844)
  --full      Full page (capped at ${MAX_FULL_HEIGHT}px)
  --quality N JPEG quality 1-100 (default: 70)
  --name X    Custom filename prefix

Examples:
  node snap.js https://dtslib.com
  node snap.js https://dtslib.com --mobile
  node snap.js https://dtslib.com --full --quality 50
  node snap.js https://dtslib.com --name landing`);
  process.exit(1);
}

if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function httpGet(u) {
  return new Promise((resolve, reject) => {
    http.get(u, res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    }).on('error', reject);
  });
}

function sendCDP(ws, id, method, params = {}) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`CDP timeout: ${method}`)), 30000);
    const handler = data => {
      const msg = JSON.parse(data.toString());
      if (msg.id === id) {
        clearTimeout(timeout);
        ws.removeListener('message', handler);
        msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
      }
    };
    ws.on('message', handler);
    ws.send(JSON.stringify({ id, method, params }));
  });
}

(async () => {
  const vw = isMobile ? 390 : 1280;
  const vh = isMobile ? 844 : 800;
  const scale = 1; // No retina — keeps file small for AI reading

  console.log(`[snap] ${isMobile ? 'Mobile' : 'Desktop'} ${vw}x${vh} | ${isFull ? 'Full page' : 'Viewport'} | JPEG q${quality}`);
  console.log(`[snap] URL: ${url}`);

  const userDataDir = path.join(__dirname, '.chrome-data');
  if (!fs.existsSync(userDataDir)) fs.mkdirSync(userDataDir, { recursive: true });

  const chrome = spawn(CHROMIUM_PATH, [
    '--headless=new', '--disable-gpu', '--no-sandbox',
    '--disable-setuid-sandbox', '--disable-dev-shm-usage',
    '--disable-software-rasterizer', '--no-first-run',
    '--no-zygote', '--single-process',
    `--user-data-dir=${userDataDir}`,
    `--crash-dumps-dir=${userDataDir}/crashes`,
    `--remote-debugging-port=${DEBUG_PORT}`,
    `--window-size=${vw},${vh}`, 'about:blank'
  ], {
    stdio: ['ignore', 'pipe', 'pipe'],
    env: { ...process.env, TMPDIR: '/data/data/com.termux/files/usr/tmp', HOME: '/data/data/com.termux/files/home' }
  });

  chrome.on('error', e => { console.error('[snap] Chrome error:', e.message); process.exit(1); });

  try {
    await sleep(4000);

    const targets = await httpGet(`http://127.0.0.1:${DEBUG_PORT}/json`);
    const page = targets.find(t => t.type === 'page');
    if (!page) throw new Error('No page target found');

    const WebSocket = require('ws');
    const ws = new WebSocket(page.webSocketDebuggerUrl);
    await new Promise((r, j) => { ws.on('open', r); ws.on('error', j); });

    let id = 1;
    await sendCDP(ws, id++, 'Page.enable');

    // Set viewport
    await sendCDP(ws, id++, 'Emulation.setDeviceMetricsOverride', {
      width: vw, height: vh, deviceScaleFactor: scale, mobile: isMobile
    });

    if (isMobile) {
      await sendCDP(ws, id++, 'Emulation.setUserAgentOverride', {
        userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36'
      });
    }

    // Navigate
    await sendCDP(ws, id++, 'Page.navigate', { url });
    await sleep(4000);

    let captureHeight = vh;

    if (isFull) {
      const metrics = await sendCDP(ws, id++, 'Page.getLayoutMetrics');
      const fullH = Math.ceil(metrics.contentSize.height);
      captureHeight = Math.min(fullH, MAX_FULL_HEIGHT);
      console.log(`[snap] Page height: ${fullH}px → capped to ${captureHeight}px`);

      await sendCDP(ws, id++, 'Emulation.setDeviceMetricsOverride', {
        width: vw, height: captureHeight, deviceScaleFactor: scale, mobile: isMobile
      });
    }

    // Capture as JPEG
    console.log('[snap] Capturing...');
    const shot = await sendCDP(ws, id++, 'Page.captureScreenshot', {
      format: 'jpeg',
      quality: quality,
      captureBeyondViewport: isFull
    });

    // Generate filename
    const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const prefix = customName || url.replace(/https?:\/\//, '').replace(/[^a-zA-Z0-9]/g, '_').slice(0, 40);
    const mode = isMobile ? 'mob' : 'desk';
    const filename = `${prefix}_${mode}_${ts}.jpg`;
    const outPath = path.join(OUTPUT_DIR, filename);

    fs.writeFileSync(outPath, Buffer.from(shot.data, 'base64'));
    const size = fs.statSync(outPath).size;
    const sizeKB = (size / 1024).toFixed(0);

    console.log(`[snap] Saved: ${outPath}`);
    console.log(`[snap] Size: ${sizeKB} KB`);

    ws.close();
  } catch (e) {
    console.error('[snap] Error:', e.message);
  } finally {
    chrome.kill();
    process.exit(0);
  }
})();
