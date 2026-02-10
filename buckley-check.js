const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');

const CHROMIUM = '/data/data/com.termux/files/usr/bin/chromium-browser';
const PORT = 9225;
const URL = 'https://dtslib1979.github.io/buckley/';
const OUT = path.join(__dirname, 'screenshots');

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function httpGet(url) {
  return new Promise((resolve, reject) => {
    http.get(url, res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => { try { resolve(JSON.parse(d)); } catch(e) { reject(e); } });
    }).on('error', reject);
  });
}

function sendCDP(ws, id, method, params = {}) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('CDP timeout')), 15000);
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

async function waitForChrome(maxRetries = 20) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const targets = await httpGet(`http://127.0.0.1:${PORT}/json`);
      if (targets && targets.length > 0) return targets;
    } catch(e) {}
    await sleep(1000);
  }
  throw new Error('Chrome never became ready');
}

(async () => {
  console.log('[1/5] Starting Chromium on port ' + PORT);
  const chrome = spawn(CHROMIUM, [
    '--headless=new','--disable-gpu','--no-sandbox','--disable-setuid-sandbox',
    '--disable-dev-shm-usage','--disable-software-rasterizer','--no-first-run',
    '--no-zygote','--single-process',`--remote-debugging-port=${PORT}`,
    '--window-size=412,915','about:blank'
  ], { stdio: ['ignore','pipe','pipe'] });

  chrome.on('error', e => { console.error('FATAL:', e.message); process.exit(1); });

  try {
    console.log('[2/5] Waiting for Chrome ready...');
    const targets = await waitForChrome();
    const page = targets.find(t => t.type === 'page');
    if (!page) throw new Error('No page target');
    console.log('[2/5] Chrome ready!');

    const WebSocket = require('ws');
    const ws = new WebSocket(page.webSocketDebuggerUrl);
    await new Promise((r, j) => { ws.on('open', r); ws.on('error', j); });

    let id = 1;
    await sendCDP(ws, id++, 'Page.enable');
    await sendCDP(ws, id++, 'Emulation.setDeviceMetricsOverride', {
      width: 412, height: 915, deviceScaleFactor: 2.625, mobile: true
    });

    console.log('[3/5] Navigating to ' + URL);
    await sendCDP(ws, id++, 'Page.navigate', { url: URL });
    await sleep(7000);

    console.log('[4/5] Capturing full page...');
    const metrics = await sendCDP(ws, id++, 'Page.getLayoutMetrics');
    const h = Math.ceil(metrics.contentSize.height);
    await sendCDP(ws, id++, 'Emulation.setDeviceMetricsOverride', {
      width: 412, height: h, deviceScaleFactor: 2.625, mobile: true
    });

    const shot = await sendCDP(ws, id++, 'Page.captureScreenshot', {
      format: 'png', captureBeyondViewport: true
    });

    const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const outPath = path.join(OUT, `buckley_verify_${ts}.png`);
    fs.writeFileSync(outPath, Buffer.from(shot.data, 'base64'));
    console.log('[5/5] SAVED: ' + outPath);

    ws.close();
  } catch (e) {
    console.error('ERROR:', e.message);
  } finally {
    chrome.kill();
    process.exit(0);
  }
})();
