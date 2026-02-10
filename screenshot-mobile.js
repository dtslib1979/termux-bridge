#!/usr/bin/env node

const { spawn } = require('child_process');
const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const CHROMIUM_PATH = '/data/data/com.termux/files/usr/bin/chromium-browser';
const OUTPUT_DIR = path.join(__dirname, 'screenshots');
const DEBUG_PORT = 9223;

if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function httpGet(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    client.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });
}

function sendCDP(ws, id, method, params = {}) {
  return new Promise((resolve, reject) => {
    const handler = (data) => {
      const msg = JSON.parse(data.toString());
      if (msg.id === id) {
        ws.removeListener('message', handler);
        if (msg.error) reject(new Error(msg.error.message));
        else resolve(msg.result);
      }
    };
    ws.on('message', handler);
    ws.send(JSON.stringify({ id, method, params }));
  });
}

async function takeScreenshot(url) {
  if (!url) {
    console.error('Usage: node screenshot-mobile.js <URL>');
    process.exit(1);
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const urlSlug = url.replace(/https?:\/\//, '').replace(/[^a-zA-Z0-9]/g, '_').slice(0, 50);
  const filename = `mobile_${urlSlug}_${timestamp}.png`;
  const outputPath = path.join(OUTPUT_DIR, filename);

  console.log('Launching Chromium (Mobile)...');

  const chrome = spawn(CHROMIUM_PATH, [
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-software-rasterizer',
    '--no-first-run',
    '--no-zygote',
    '--single-process',
    `--remote-debugging-port=${DEBUG_PORT}`,
    '--window-size=412,915',
    'about:blank'
  ], {
    stdio: ['ignore', 'pipe', 'pipe']
  });

  chrome.stderr.on('data', (data) => {
    const msg = data.toString();
    if (msg.includes('DevTools listening')) {
      console.log('Chrome DevTools ready');
    }
  });

  try {
    await sleep(3000);

    console.log('Connecting to Chrome DevTools...');
    const targets = await httpGet(`http://127.0.0.1:${DEBUG_PORT}/json`);
    const page = targets.find(t => t.type === 'page');

    if (!page) {
      throw new Error('No page target found');
    }

    const WebSocket = require('ws');
    const ws = new WebSocket(page.webSocketDebuggerUrl);

    await new Promise((resolve, reject) => {
      ws.on('open', resolve);
      ws.on('error', reject);
    });

    console.log(`Navigating to: ${url}`);
    let cmdId = 1;

    await sendCDP(ws, cmdId++, 'Page.enable');

    // Set mobile viewport BEFORE navigation
    await sendCDP(ws, cmdId++, 'Emulation.setDeviceMetricsOverride', {
      width: 412,
      height: 915,
      deviceScaleFactor: 2.625,
      mobile: true
    });

    // Set mobile user agent
    await sendCDP(ws, cmdId++, 'Emulation.setUserAgentOverride', {
      userAgent: 'Mozilla/5.0 (Linux; Android 13; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36'
    });

    await sendCDP(ws, cmdId++, 'Page.navigate', { url });

    await sleep(5000);

    const layoutMetrics = await sendCDP(ws, cmdId++, 'Page.getLayoutMetrics');
    const { width, height } = layoutMetrics.contentSize;

    await sendCDP(ws, cmdId++, 'Emulation.setDeviceMetricsOverride', {
      width: 412,
      height: Math.ceil(height),
      deviceScaleFactor: 2.625,
      mobile: true
    });

    console.log('Taking mobile screenshot...');
    const screenshot = await sendCDP(ws, cmdId++, 'Page.captureScreenshot', {
      format: 'png',
      captureBeyondViewport: true
    });

    fs.writeFileSync(outputPath, Buffer.from(screenshot.data, 'base64'));
    console.log(`Screenshot saved: ${outputPath}`);

    ws.close();

  } finally {
    chrome.kill();
  }
}

const url = process.argv[2];
takeScreenshot(url).catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
