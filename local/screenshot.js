#!/usr/bin/env node

const { spawn } = require('child_process');
const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const CHROMIUM_PATH = '/data/data/com.termux/files/usr/bin/chromium-browser';
const OUTPUT_DIR = path.join(__dirname, 'docs', 'screenshots');
const INDEX_FILE = path.join(OUTPUT_DIR, 'index.json');
const DEBUG_PORT = 9222;

// Ensure output directory exists
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

function updateIndex(filename, url, size) {
  let data = { screenshots: [] };

  try {
    if (fs.existsSync(INDEX_FILE)) {
      data = JSON.parse(fs.readFileSync(INDEX_FILE, 'utf8'));
    }
  } catch (err) {
    console.error('Warning: Could not read index file, creating new one');
  }

  data.screenshots.push({
    filename,
    url,
    size,
    timestamp: new Date().toISOString()
  });

  fs.writeFileSync(INDEX_FILE, JSON.stringify(data, null, 2));
  console.log('Updated index.json');
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
    console.error('Usage: node screenshot.js <URL>');
    process.exit(1);
  }

  // Generate filename
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const urlSlug = url.replace(/https?:\/\//, '').replace(/[^a-zA-Z0-9]/g, '_').slice(0, 50);
  const filename = `${urlSlug}_${timestamp}.png`;
  const outputPath = path.join(OUTPUT_DIR, filename);

  console.log('Launching Chromium...');

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
    '--window-size=1280,720',
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
    // Wait for Chrome to start
    await sleep(3000);

    // Get WebSocket URL
    console.log('Connecting to Chrome DevTools...');
    const targets = await httpGet(`http://127.0.0.1:${DEBUG_PORT}/json`);
    const page = targets.find(t => t.type === 'page');

    if (!page) {
      throw new Error('No page target found');
    }

    // Connect via WebSocket
    const WebSocket = require('ws');
    const ws = new WebSocket(page.webSocketDebuggerUrl);

    await new Promise((resolve, reject) => {
      ws.on('open', resolve);
      ws.on('error', reject);
    });

    console.log(`Navigating to: ${url}`);
    let cmdId = 1;

    // Enable Page domain
    await sendCDP(ws, cmdId++, 'Page.enable');

    // Navigate to URL
    await sendCDP(ws, cmdId++, 'Page.navigate', { url });

    // Wait for load
    await sleep(3000);

    // Set viewport
    await sendCDP(ws, cmdId++, 'Emulation.setDeviceMetricsOverride', {
      width: 1280,
      height: 720,
      deviceScaleFactor: 1,
      mobile: false
    });

    // Get full page metrics for full-page screenshot
    const layoutMetrics = await sendCDP(ws, cmdId++, 'Page.getLayoutMetrics');
    const { width, height } = layoutMetrics.contentSize;

    await sendCDP(ws, cmdId++, 'Emulation.setDeviceMetricsOverride', {
      width: Math.ceil(width),
      height: Math.ceil(height),
      deviceScaleFactor: 1,
      mobile: false
    });

    console.log('Taking screenshot...');
    const screenshot = await sendCDP(ws, cmdId++, 'Page.captureScreenshot', {
      format: 'png',
      captureBeyondViewport: true
    });

    // Save screenshot
    const imageBuffer = Buffer.from(screenshot.data, 'base64');
    fs.writeFileSync(outputPath, imageBuffer);
    console.log(`Screenshot saved: ${outputPath}`);

    // Update index.json for GitHub Pages gallery
    updateIndex(filename, url, imageBuffer.length);

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
