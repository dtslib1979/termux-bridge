#!/usr/bin/env node
// screenshot.js — 데스크톱 뷰포트 캡처 (snap.js 래퍼)
// Usage: node screenshot.js <URL>
// snap.js --full 과 동일. 하위 호환용으로 유지.

const { spawnSync } = require('child_process');
const path = require('path');

const url = process.argv[2];
if (!url) {
  console.error('Usage: node screenshot.js <URL>');
  process.exit(1);
}

const snapJs = path.join(__dirname, 'snap.js');
const result = spawnSync('node', [snapJs, url, '--full'], { stdio: 'inherit' });
process.exit(result.status || 0);
