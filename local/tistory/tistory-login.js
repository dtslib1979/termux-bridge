#!/usr/bin/env node
/**
 * tistory-login.js
 * Chromium CDP로 Kakao → Tistory 로그인 후 쿠키 추출
 *
 * 사용법:
 *   node tistory-login.js <email> <password> [blog_name]
 *   node tistory-login.js dtslib1k@kakao.com "think4good*" dtslib1k
 */

const { spawn } = require('child_process');
const http = require('http');
const net = require('net');
const fs = require('fs');
const path = require('path');

const CHROMIUM = '/data/data/com.termux/files/usr/bin/chromium-browser';
const DEBUG_PORT = 9223;
const COOKIES_DIR = path.join(__dirname, 'cookies');
const TIMEOUT = 30000;

const [,, email, password, blogLabel] = process.argv;

if (!email || !password) {
  console.error('사용법: node tistory-login.js <email> <password> [label]');
  process.exit(1);
}

if (!fs.existsSync(COOKIES_DIR)) fs.mkdirSync(COOKIES_DIR, { recursive: true });

// ── 포트 사용 중인지 확인 ──────────────────────────────
function isPortFree(port) {
  return new Promise(resolve => {
    const s = net.createServer();
    s.once('error', () => resolve(false));
    s.once('listening', () => { s.close(); resolve(true); });
    s.listen(port);
  });
}

// ── CDP JSON 가져오기 ──────────────────────────────────
function cdpGet(path) {
  return new Promise((resolve, reject) => {
    http.get({ host: 'localhost', port: DEBUG_PORT, path }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => { try { resolve(JSON.parse(d)); } catch(e) { resolve(d); } });
    }).on('error', reject);
  });
}

// ── WebSocket CDP 연결 ─────────────────────────────────
function connectCDP(wsUrl) {
  return new Promise((resolve, reject) => {
    const url = new URL(wsUrl);
    const net = require('net');
    const sock = net.createConnection({ host: url.hostname, port: url.port || 80 });
    const key = Buffer.from(Math.random().toString()).toString('base64');
    let buf = '';
    let resolved = false;

    sock.write(
      `GET ${url.pathname} HTTP/1.1\r\n` +
      `Host: ${url.host}\r\n` +
      `Upgrade: websocket\r\n` +
      `Connection: Upgrade\r\n` +
      `Sec-WebSocket-Key: ${key}\r\n` +
      `Sec-WebSocket-Version: 13\r\n\r\n`
    );

    const msgCallbacks = {};
    let msgId = 1;

    function sendFrame(data) {
      const json = JSON.stringify(data);
      const payload = Buffer.from(json, 'utf8');
      const mask = Buffer.from([Math.random()*256, Math.random()*256, Math.random()*256, Math.random()*256]);
      const masked = Buffer.alloc(payload.length);
      for (let i = 0; i < payload.length; i++) masked[i] = payload[i] ^ mask[i % 4];
      const header = Buffer.alloc(payload.length < 126 ? 6 : 8);
      header[0] = 0x81;
      if (payload.length < 126) {
        header[1] = 0x80 | payload.length;
        mask.copy(header, 2);
      } else {
        header[1] = 0x80 | 126;
        header.writeUInt16BE(payload.length, 2);
        mask.copy(header, 4);
      }
      sock.write(Buffer.concat([header, masked]));
    }

    function send(method, params = {}) {
      return new Promise((res, rej) => {
        const id = msgId++;
        msgCallbacks[id] = { res, rej };
        sendFrame({ id, method, params });
        setTimeout(() => { if (msgCallbacks[id]) { delete msgCallbacks[id]; rej(new Error(`Timeout: ${method}`)); } }, TIMEOUT);
      });
    }

    let rawBuf = Buffer.alloc(0);
    let handshakeDone = false;

    sock.on('data', chunk => {
      if (!handshakeDone) {
        buf += chunk.toString();
        if (buf.includes('\r\n\r\n')) {
          handshakeDone = true;
          const rest = chunk.slice(chunk.indexOf('\r\n\r\n') + 4);
          if (rest.length) rawBuf = Buffer.concat([rawBuf, rest]);
          if (!resolved) { resolved = true; resolve({ send, sock }); }
        }
        return;
      }
      rawBuf = Buffer.concat([rawBuf, chunk]);
      while (rawBuf.length >= 2) {
        const opcode = rawBuf[0] & 0x0f;
        if (opcode === 0x8) break;
        const payLen = rawBuf[1] & 0x7f;
        let offset = 2;
        let len = payLen;
        if (payLen === 126) { if (rawBuf.length < 4) break; len = rawBuf.readUInt16BE(2); offset = 4; }
        if (rawBuf.length < offset + len) break;
        const payload = rawBuf.slice(offset, offset + len);
        rawBuf = rawBuf.slice(offset + len);
        try {
          const msg = JSON.parse(payload.toString('utf8'));
          if (msg.id && msgCallbacks[msg.id]) {
            const cb = msgCallbacks[msg.id];
            delete msgCallbacks[msg.id];
            if (msg.error) cb.rej(new Error(msg.error.message));
            else cb.res(msg.result);
          }
        } catch(e) {}
      }
    });

    sock.on('error', reject);
    setTimeout(() => { if (!resolved) reject(new Error('WS connect timeout')); }, 10000);
  });
}

// ── 대기 ──────────────────────────────────────────────
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function waitForUrl(send, pattern, maxMs = 25000) {
  const start = Date.now();
  while (Date.now() - start < maxMs) {
    const r = await send('Runtime.evaluate', { expression: 'location.href' });
    const url = r.result?.value || '';
    if (pattern.test(url)) return url;
    await sleep(800);
  }
  const r = await send('Runtime.evaluate', { expression: 'location.href' });
  return r.result?.value || '';
}

async function waitForElement(send, selector, maxMs = 15000) {
  const start = Date.now();
  while (Date.now() - start < maxMs) {
    const r = await send('Runtime.evaluate', {
      expression: `!!document.querySelector(${JSON.stringify(selector)})`
    });
    if (r.result?.value) return true;
    await sleep(500);
  }
  return false;
}

// ── 메인 ──────────────────────────────────────────────
async function main() {
  console.log(`\n▶ 로그인: ${email}`);

  const free = await isPortFree(DEBUG_PORT);
  if (!free) {
    console.log(`  포트 ${DEBUG_PORT} 사용 중 — 기존 Chromium 종료 후 재시도`);
    require('child_process').execSync(`pkill -f "remote-debugging-port=${DEBUG_PORT}" 2>/dev/null || true`);
    await sleep(1500);
  }

  // Chromium 실행
  const dataDir = `/data/data/com.termux/files/home/.chrome-tistory-${Date.now()}`;
  const chrome = spawn(CHROMIUM, [
    `--remote-debugging-port=${DEBUG_PORT}`,
    '--no-sandbox',
    '--disable-gpu',
    '--disable-dev-shm-usage',
    '--headless=new',
    '--window-size=1280,900',
    `--user-data-dir=${dataDir}`,
    'about:blank',
  ], { detached: false, stdio: 'ignore' });

  chrome.on('error', e => { console.error('Chromium 실행 실패:', e.message); process.exit(1); });
  console.log('  Chromium 시작 중...');
  await sleep(3000);

  let cdp;
  for (let i = 0; i < 10; i++) {
    try {
      const tabs = await cdpGet('/json');
      const tab = Array.isArray(tabs) ? tabs[0] : null;
      if (tab?.webSocketDebuggerUrl) {
        cdp = await connectCDP(tab.webSocketDebuggerUrl);
        break;
      }
    } catch(e) {}
    await sleep(1000);
  }

  if (!cdp) { console.error('CDP 연결 실패'); chrome.kill(); process.exit(1); }
  const { send } = cdp;
  console.log('  CDP 연결 완료');

  await send('Network.enable', {});
  await send('Page.enable', {});

  // Tistory 로그인 페이지 이동
  console.log('  Tistory 로그인 이동...');
  await send('Page.navigate', { url: 'https://www.tistory.com/auth/kakao' });
  await sleep(3000);

  let currentUrl = await waitForUrl(send, /kakao|tistory/, 15000);
  console.log(`  현재 URL: ${currentUrl.slice(0, 70)}`);

  // Kakao 로그인 폼 처리
  if (currentUrl.includes('kakao')) {
    console.log('  Kakao 로그인 폼 입력...');

    // 이메일 입력
    await waitForElement(send, '#loginId--1, input[name="loginId"], input[type="email"]', 10000);
    await send('Runtime.evaluate', {
      expression: `
        (function() {
          const id = document.querySelector('#loginId--1') ||
                     document.querySelector('input[name="loginId"]') ||
                     document.querySelector('input[type="email"]');
          const pw = document.querySelector('#password--2') ||
                     document.querySelector('input[name="password"]') ||
                     document.querySelector('input[type="password"]');
          if (id) {
            id.value = ${JSON.stringify(email)};
            id.dispatchEvent(new Event('input', {bubbles:true}));
            id.dispatchEvent(new Event('change', {bubbles:true}));
          }
          if (pw) {
            pw.value = ${JSON.stringify(password)};
            pw.dispatchEvent(new Event('input', {bubbles:true}));
            pw.dispatchEvent(new Event('change', {bubbles:true}));
          }
          return {id: !!id, pw: !!pw};
        })()
      `,
      returnByValue: true
    }).then(r => console.log(`  입력 결과: ${JSON.stringify(r.result?.value)}`));

    await sleep(800);

    // 로그인 버튼 클릭
    await send('Runtime.evaluate', {
      expression: `
        (function() {
          const btn = document.querySelector('button[type="submit"]') ||
                      document.querySelector('.btn_g.highlight') ||
                      document.querySelector('button.btn_confirm');
          if (btn) { btn.click(); return true; }
          return false;
        })()
      `,
      returnByValue: true
    });

    console.log('  로그인 버튼 클릭, 대기 중...');
    await sleep(5000);
    currentUrl = await waitForUrl(send, /tistory\.com/, 20000);
    console.log(`  로그인 후 URL: ${currentUrl.slice(0, 70)}`);
  }

  // tistory.com 이동 확인
  if (!currentUrl.includes('tistory.com')) {
    await send('Page.navigate', { url: 'https://www.tistory.com' });
    await sleep(3000);
  }

  // 쿠키 추출
  const cookieResult = await send('Network.getAllCookies', {});
  const allCookies = cookieResult.cookies || [];
  const tistoryCookies = allCookies.filter(c =>
    c.domain.includes('tistory.com') || c.domain.includes('kakao.com')
  );

  if (tistoryCookies.length === 0) {
    console.error('  ✗ 쿠키 없음 — 로그인 실패');

    // 디버그: 현재 페이지 HTML 저장
    const htmlR = await send('Runtime.evaluate', { expression: 'document.documentElement.outerHTML' });
    const dbgFile = path.join(__dirname, `debug_${email.split('@')[0]}.html`);
    fs.writeFileSync(dbgFile, htmlR.result?.value || '', 'utf8');
    console.log(`  디버그 HTML: ${dbgFile}`);

    chrome.kill();
    try { fs.rmSync(dataDir, { recursive: true }); } catch(e) {}
    process.exit(1);
  }

  // 쿠키 저장
  const label = blogLabel || email.split('@')[0];
  const cookieFile = path.join(COOKIES_DIR, `${label}.json`);
  const cookieMap = {};
  tistoryCookies.forEach(c => { cookieMap[c.name] = c.value; });

  fs.writeFileSync(cookieFile, JSON.stringify({
    email,
    label,
    saved_at: new Date().toISOString(),
    cookies: cookieMap,
    cookie_header: tistoryCookies.map(c => `${c.name}=${c.value}`).join('; '),
  }, null, 2), 'utf8');

  console.log(`\n  ✓ 쿠키 저장: ${cookieFile}`);
  console.log(`  쿠키 수: ${Object.keys(cookieMap).length}개`);
  console.log(`  키: ${Object.keys(cookieMap).join(', ')}`);

  chrome.kill();
  await sleep(500);
  try { fs.rmSync(dataDir, { recursive: true }); } catch(e) {}

  console.log('  완료\n');
}

main().catch(e => {
  console.error('오류:', e.message);
  process.exit(1);
});
