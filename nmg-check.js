const { spawn } = require('child_process');
const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const CHROMIUM_PATH = '/data/data/com.termux/files/usr/bin/chromium-browser';
const OUTPUT_DIR = path.join(__dirname, 'screenshots');
const DEBUG_PORT = 9225;
const URL = 'https://namoneygoal.vercel.app/slots/slot01/';

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function httpGet(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    client.get(url, res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    }).on('error', reject);
  });
}

function sendCDP(ws, id, method, params = {}) {
  return new Promise((resolve, reject) => {
    const handler = data => {
      const msg = JSON.parse(data.toString());
      if (msg.id === id) { ws.removeListener('message', handler); msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result); }
    };
    ws.on('message', handler);
    ws.send(JSON.stringify({ id, method, params }));
  });
}

(async () => {
  console.log('Starting Chromium...');
  const chrome = spawn(CHROMIUM_PATH, [
    '--headless=new','--disable-gpu','--no-sandbox','--disable-setuid-sandbox',
    '--disable-dev-shm-usage','--disable-software-rasterizer','--no-first-run',
    '--no-zygote','--single-process','--remote-debugging-port=' + DEBUG_PORT,
    '--window-size=412,915','about:blank'
  ], { stdio: ['ignore','pipe','pipe'] });

  chrome.on('error', e => { console.error('Chrome error:', e.message); process.exit(1); });

  await sleep(6000);
  console.log('Connecting CDP...');

  try {
    const targets = await httpGet('http://127.0.0.1:' + DEBUG_PORT + '/json');
    const page = targets.find(t => t.type === 'page');
    if (!page) throw new Error('No page found');

    const WebSocket = require('ws');
    const ws = new WebSocket(page.webSocketDebuggerUrl);
    await new Promise((r,j) => { ws.on('open',r); ws.on('error',j); });

    let id = 1;
    await sendCDP(ws, id++, 'Page.enable');
    await sendCDP(ws, id++, 'Emulation.setDeviceMetricsOverride', { width:412, height:915, deviceScaleFactor:2.625, mobile:true });
    await sendCDP(ws, id++, 'Emulation.setUserAgentOverride', { userAgent:'Mozilla/5.0 (Linux; Android 13) Mobile' });

    console.log('Navigating to:', URL);
    await sendCDP(ws, id++, 'Page.navigate', { url: URL });
    await sleep(5000);

    const metrics = await sendCDP(ws, id++, 'Page.getLayoutMetrics');
    const h = Math.ceil(metrics.contentSize.height);
    await sendCDP(ws, id++, 'Emulation.setDeviceMetricsOverride', { width:412, height:h, deviceScaleFactor:2.625, mobile:true });

    console.log('Capturing screenshot...');
    const shot = await sendCDP(ws, id++, 'Page.captureScreenshot', { format:'png', captureBeyondViewport:true });

    const ts = new Date().toISOString().replace(/[:.]/g,'-').slice(0,19);
    const outPath = path.join(OUTPUT_DIR, 'nmg_slot01_' + ts + '.png');
    fs.writeFileSync(outPath, Buffer.from(shot.data, 'base64'));
    console.log('DONE:', outPath);

    ws.close();
  } catch(e) {
    console.error('Error:', e.message);
  } finally {
    chrome.kill();
    process.exit(0);
  }
})();
