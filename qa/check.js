// qa/check.js — Full QA: screenshots + link check + console errors + structured JSON
// Runs in GitHub Actions (Ubuntu + Playwright)

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const URLS_FILE = path.join(__dirname, 'urls.json');
const ROOT = path.join(__dirname, '..');
const RUNS_DIR = path.join(ROOT, 'runs');
const SCREENSHOT_DIR = path.join(ROOT, 'screenshots');
const MAX_RUNS = 5;

const DESKTOP = { width: 1280, height: 800 };
const MOBILE = { width: 390, height: 844 };
const JPEG_QUALITY = 70;
const NAV_TIMEOUT = 15000;
const LINK_TIMEOUT = 8000;

async function checkSite(browser, site, ignorePatterns) {
  const result = {
    id: site.id,
    name: site.name,
    url: site.url,
    tier: site.tier,
    status: 'PASS',
    loadTime: 0,
    brokenLinks: [],
    consoleErrors: [],
    screenshots: { desktop: null, mobile: null }
  };

  // --- Desktop ---
  try {
    const ctx = await browser.newContext({
      viewport: DESKTOP,
      deviceScaleFactor: 1,
      bypassCSP: true
    });
    const page = await ctx.newPage();

    page.on('console', msg => {
      if (msg.type() === 'error') {
        result.consoleErrors.push(msg.text().slice(0, 200));
      }
    });

    const start = Date.now();
    await page.goto(site.url, { waitUntil: 'networkidle', timeout: NAV_TIMEOUT }).catch(() => {});
    result.loadTime = Date.now() - start;

    const deskFile = `${site.id}_desktop.jpg`;
    const deskPath = path.join(SCREENSHOT_DIR, deskFile);
    await page.screenshot({ path: deskPath, type: 'jpeg', quality: JPEG_QUALITY });
    result.screenshots.desktop = deskFile;

    // --- Link check (guard against non-string href) ---
    const links = await page.$$eval('a[href]', els =>
      els.map(a => {
        const h = a.href;
        if (typeof h !== 'string') return null;
        return { href: h, text: (a.textContent || '').trim().slice(0, 50) };
      }).filter(l => l && l.href.startsWith('http'))
    );

    const uniqueLinks = [...new Map(links.map(l => [l.href, l])).values()];

    for (const link of uniqueLinks.slice(0, 50)) {
      try {
        const res = await page.request.fetch(link.href, {
          method: 'HEAD',
          timeout: LINK_TIMEOUT
        }).catch(() => null);

        if (!res || res.status() >= 400) {
          const status = res ? res.status() : 'TIMEOUT';
          const ignored = ignorePatterns.some(p => link.href.includes(p.pattern));
          if (ignored) {
            result.ignoredLinks = result.ignoredLinks || [];
            result.ignoredLinks.push({ href: link.href, text: link.text, status, reason: ignorePatterns.find(p => link.href.includes(p.pattern)).reason });
          } else {
            result.brokenLinks.push({ href: link.href, text: link.text, status });
          }
        }
      } catch {
        const ignored = ignorePatterns.some(p => link.href.includes(p.pattern));
        if (!ignored) {
          result.brokenLinks.push({ href: link.href, text: link.text, status: 'ERROR' });
        }
      }
    }

    await ctx.close();
  } catch (err) {
    result.status = 'FAIL';
    result.consoleErrors.push(`Desktop error: ${err.message}`);
  }

  // --- Mobile ---
  try {
    const ctx = await browser.newContext({
      viewport: MOBILE,
      deviceScaleFactor: 1,
      isMobile: true,
      userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36'
    });
    const page = await ctx.newPage();
    await page.goto(site.url, { waitUntil: 'networkidle', timeout: NAV_TIMEOUT }).catch(() => {});

    const mobFile = `${site.id}_mobile.jpg`;
    const mobPath = path.join(SCREENSHOT_DIR, mobFile);
    await page.screenshot({ path: mobPath, type: 'jpeg', quality: JPEG_QUALITY });
    result.screenshots.mobile = mobFile;

    await ctx.close();
  } catch (err) {
    result.consoleErrors.push(`Mobile error: ${err.message}`);
  }

  if (result.brokenLinks.length > 0) result.status = 'WARN';
  if (result.consoleErrors.some(e => e.includes('error') || e.includes('Error'))) {
    if (result.status === 'PASS') result.status = 'WARN';
  }

  return result;
}

function generateRunId() {
  const d = new Date();
  return d.toISOString().slice(0, 16).replace(/[T:]/g, '-');
}

function generateReport(results, startTime, runId) {
  const elapsed = ((Date.now() - startTime) / 1000).toFixed(0);
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
  const pass = results.filter(r => r.status === 'PASS').length;
  const warn = results.filter(r => r.status === 'WARN').length;
  const fail = results.filter(r => r.status === 'FAIL').length;
  const totalBroken = results.reduce((n, r) => n + r.brokenLinks.length, 0);

  let md = `# QA Snapshot Report\n\n`;
  md += `**Run ID:** ${runId}\n`;
  md += `**Generated:** ${now} UTC\n`;
  md += `**Sites checked:** ${results.length}\n`;
  md += `**Duration:** ${elapsed}s\n`;
  md += `**Summary:** ${pass} PASS / ${warn} WARN / ${fail} FAIL / ${totalBroken} broken links\n\n`;
  md += `---\n\n`;

  md += `| Status | Site | Load | Links | Errors |\n`;
  md += `|--------|------|------|-------|--------|\n`;
  for (const r of results) {
    const icon = r.status === 'PASS' ? 'OK' : r.status === 'WARN' ? '!!' : 'XX';
    const load = r.loadTime ? `${(r.loadTime / 1000).toFixed(1)}s` : '-';
    md += `| ${icon} | ${r.name} | ${load} | ${r.brokenLinks.length} | ${r.consoleErrors.length} |\n`;
  }

  const issues = results.filter(r => r.status !== 'PASS');
  if (issues.length > 0) {
    md += `\n---\n\n## Issues\n\n`;
    for (const r of issues) {
      md += `### ${r.name} (${r.status})\n`;
      md += `URL: ${r.url}\n\n`;

      if (r.brokenLinks.length > 0) {
        md += `**Broken links:**\n`;
        for (const l of r.brokenLinks) {
          md += `- [${l.status}] ${l.text || '(no text)'} → ${l.href}\n`;
        }
        md += `\n`;
      }

      if (r.consoleErrors.length > 0) {
        md += `**Console errors:**\n`;
        for (const e of r.consoleErrors) {
          md += `- ${e}\n`;
        }
        md += `\n`;
      }
    }
  }

  return md;
}

function saveSummary(results, startTime, runId, runDir) {
  const elapsed = ((Date.now() - startTime) / 1000).toFixed(0);
  const pass = results.filter(r => r.status === 'PASS').length;
  const warn = results.filter(r => r.status === 'WARN').length;
  const fail = results.filter(r => r.status === 'FAIL').length;
  const totalBroken = results.reduce((n, r) => n + r.brokenLinks.length, 0);
  const totalErrors = results.reduce((n, r) => n + r.consoleErrors.length, 0);

  const summary = {
    runId,
    timestamp: new Date().toISOString(),
    duration: parseInt(elapsed),
    sitesChecked: results.length,
    totals: { pass, warn, fail },
    brokenLinks: totalBroken,
    ignoredLinks: results.reduce((n, r) => n + (r.ignoredLinks || []).length, 0),
    consoleErrors: totalErrors,
    topBroken: results
      .filter(r => r.brokenLinks.length > 0)
      .sort((a, b) => b.brokenLinks.length - a.brokenLinks.length)
      .slice(0, 5)
      .map(r => ({ id: r.id, name: r.name, count: r.brokenLinks.length })),
    topSlow: results
      .sort((a, b) => b.loadTime - a.loadTime)
      .slice(0, 5)
      .map(r => ({ id: r.id, name: r.name, ms: r.loadTime }))
  };

  fs.writeFileSync(path.join(runDir, 'summary.json'), JSON.stringify(summary, null, 2));
  return summary;
}

function saveSites(results, runDir) {
  const sites = results.map(r => ({
    id: r.id,
    name: r.name,
    url: r.url,
    tier: r.tier,
    status: r.status,
    loadTime: r.loadTime,
    brokenLinks: r.brokenLinks,
    consoleErrors: r.consoleErrors
  }));

  fs.writeFileSync(path.join(runDir, 'sites.json'), JSON.stringify(sites, null, 2));
}

function updateIndex(runId, summary) {
  const indexPath = path.join(RUNS_DIR, 'index.json');
  let index = [];
  if (fs.existsSync(indexPath)) {
    try { index = JSON.parse(fs.readFileSync(indexPath, 'utf8')); } catch { index = []; }
  }

  index.unshift({
    runId,
    timestamp: summary.timestamp,
    sitesChecked: summary.sitesChecked,
    totals: summary.totals,
    brokenLinks: summary.brokenLinks
  });

  // Keep only MAX_RUNS
  if (index.length > MAX_RUNS) {
    const removed = index.splice(MAX_RUNS);
    for (const old of removed) {
      const oldDir = path.join(RUNS_DIR, old.runId);
      if (fs.existsSync(oldDir)) {
        fs.rmSync(oldDir, { recursive: true, force: true });
      }
    }
  }

  fs.writeFileSync(indexPath, JSON.stringify(index, null, 2));
}

(async () => {
  const config = JSON.parse(fs.readFileSync(URLS_FILE, 'utf8'));
  const sites = config.sites;
  const ignorePatterns = config.ignoreLinks || [];

  const tierFilter = process.argv.find(a => a.startsWith('--tier='));
  const tier = tierFilter ? parseInt(tierFilter.split('=')[1]) : null;
  const filtered = tier ? sites.filter(s => s.tier <= tier) : sites;

  const idFilter = process.argv.find(a => a.startsWith('--id='));
  const ids = idFilter ? idFilter.split('=')[1].split(',') : null;
  const targets = ids ? filtered.filter(s => ids.includes(s.id)) : filtered;

  console.log(`[QA] Checking ${targets.length} sites...`);

  // Create dirs
  if (!fs.existsSync(RUNS_DIR)) fs.mkdirSync(RUNS_DIR, { recursive: true });
  if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });

  const runId = generateRunId();
  const runDir = path.join(RUNS_DIR, runId);
  fs.mkdirSync(runDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const startTime = Date.now();
  const results = [];

  for (const site of targets) {
    console.log(`[QA] ${site.name} (${site.url})`);
    const result = await checkSite(browser, site, ignorePatterns);
    console.log(`  → ${result.status} | ${result.loadTime}ms | ${result.brokenLinks.length} broken | ${result.consoleErrors.length} errors`);
    results.push(result);
  }

  await browser.close();

  // Save structured data
  const summary = saveSummary(results, startTime, runId, runDir);
  saveSites(results, runDir);

  // Save report.md
  const report = generateReport(results, startTime, runId);
  fs.writeFileSync(path.join(runDir, 'report.md'), report, 'utf8');

  // Update runs index
  updateIndex(runId, summary);

  console.log(`\n[QA] Run ID: ${runId}`);
  console.log(`[QA] Results: runs/${runId}/`);
  console.log(`[QA] Screenshots: screenshots/ (artifact only)`);

  if (results.some(r => r.status === 'FAIL')) process.exit(1);
})();
