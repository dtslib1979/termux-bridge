// qa/check.js — Full QA: screenshots + link check + console errors + report
// Runs in GitHub Actions (Ubuntu + Playwright)

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const URLS_FILE = path.join(__dirname, 'urls.json');
const OUT_DIR = path.join(__dirname, '..', 'screenshots', 'latest');
const REPORT_PATH = path.join(OUT_DIR, 'report.md');

const DESKTOP = { width: 1280, height: 800 };
const MOBILE = { width: 390, height: 844 };
const JPEG_QUALITY = 70;
const NAV_TIMEOUT = 15000;
const LINK_TIMEOUT = 8000;

async function checkSite(browser, site) {
  const result = {
    id: site.id,
    name: site.name,
    url: site.url,
    tier: site.tier,
    desktop: null,
    mobile: null,
    brokenLinks: [],
    consoleErrors: [],
    loadTime: 0,
    status: 'PASS'
  };

  // --- Desktop screenshot ---
  try {
    const ctx = await browser.newContext({
      viewport: DESKTOP,
      deviceScaleFactor: 1,
      bypassCSP: true
    });
    const page = await ctx.newPage();

    // Capture console errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        result.consoleErrors.push(msg.text().slice(0, 200));
      }
    });

    const start = Date.now();
    await page.goto(site.url, { waitUntil: 'networkidle', timeout: NAV_TIMEOUT }).catch(() => {});
    result.loadTime = Date.now() - start;

    const deskPath = path.join(OUT_DIR, `${site.id}_desktop.jpg`);
    await page.screenshot({ path: deskPath, type: 'jpeg', quality: JPEG_QUALITY });
    result.desktop = `${site.id}_desktop.jpg`;

    // --- Link check ---
    const links = await page.$$eval('a[href]', els =>
      els.map(a => ({ href: a.href, text: (a.textContent || '').trim().slice(0, 50) }))
        .filter(l => l.href.startsWith('http'))
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
          result.brokenLinks.push({ href: link.href, text: link.text, status });
        }
      } catch {
        result.brokenLinks.push({ href: link.href, text: link.text, status: 'ERROR' });
      }
    }

    await ctx.close();
  } catch (err) {
    result.status = 'FAIL';
    result.consoleErrors.push(`Desktop error: ${err.message}`);
  }

  // --- Mobile screenshot ---
  try {
    const ctx = await browser.newContext({
      viewport: MOBILE,
      deviceScaleFactor: 1,
      isMobile: true,
      userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36'
    });
    const page = await ctx.newPage();
    await page.goto(site.url, { waitUntil: 'networkidle', timeout: NAV_TIMEOUT }).catch(() => {});

    const mobPath = path.join(OUT_DIR, `${site.id}_mobile.jpg`);
    await page.screenshot({ path: mobPath, type: 'jpeg', quality: JPEG_QUALITY });
    result.mobile = `${site.id}_mobile.jpg`;

    await ctx.close();
  } catch (err) {
    result.consoleErrors.push(`Mobile error: ${err.message}`);
  }

  if (result.brokenLinks.length > 0) result.status = 'WARN';
  if (result.consoleErrors.some(e => e.includes('error') || e.includes('Error'))) result.status = 'WARN';

  return result;
}

function generateReport(results, startTime) {
  const elapsed = ((Date.now() - startTime) / 1000).toFixed(0);
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
  const pass = results.filter(r => r.status === 'PASS').length;
  const warn = results.filter(r => r.status === 'WARN').length;
  const fail = results.filter(r => r.status === 'FAIL').length;
  const totalBroken = results.reduce((n, r) => n + r.brokenLinks.length, 0);

  let md = `# QA Snapshot Report\n\n`;
  md += `**Generated:** ${now} UTC\n`;
  md += `**Sites checked:** ${results.length}\n`;
  md += `**Duration:** ${elapsed}s\n`;
  md += `**Summary:** ${pass} PASS / ${warn} WARN / ${fail} FAIL / ${totalBroken} broken links\n\n`;
  md += `---\n\n`;

  // Summary table
  md += `| Status | Site | Load | Links | Errors |\n`;
  md += `|--------|------|------|-------|--------|\n`;
  for (const r of results) {
    const icon = r.status === 'PASS' ? 'OK' : r.status === 'WARN' ? '!!' : 'XX';
    const load = r.loadTime ? `${(r.loadTime / 1000).toFixed(1)}s` : '-';
    md += `| ${icon} | ${r.name} | ${load} | ${r.brokenLinks.length} | ${r.consoleErrors.length} |\n`;
  }

  // Details for WARN/FAIL only
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

(async () => {
  const config = JSON.parse(fs.readFileSync(URLS_FILE, 'utf8'));
  const sites = config.sites;

  // Filter by tier if specified
  const tierFilter = process.argv.find(a => a.startsWith('--tier='));
  const tier = tierFilter ? parseInt(tierFilter.split('=')[1]) : null;
  const filtered = tier ? sites.filter(s => s.tier <= tier) : sites;

  // Filter by ID if specified
  const idFilter = process.argv.find(a => a.startsWith('--id='));
  const ids = idFilter ? idFilter.split('=')[1].split(',') : null;
  const targets = ids ? filtered.filter(s => ids.includes(s.id)) : filtered;

  console.log(`[QA] Checking ${targets.length} sites...`);

  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const startTime = Date.now();
  const results = [];

  for (const site of targets) {
    console.log(`[QA] ${site.name} (${site.url})`);
    const result = await checkSite(browser, site);
    console.log(`  → ${result.status} | ${result.loadTime}ms | ${result.brokenLinks.length} broken | ${result.consoleErrors.length} errors`);
    results.push(result);
  }

  await browser.close();

  const report = generateReport(results, startTime);
  fs.writeFileSync(REPORT_PATH, report, 'utf8');
  console.log(`\n[QA] Report saved: ${REPORT_PATH}`);
  console.log(`[QA] Screenshots: ${OUT_DIR}/`);

  // Exit with error code if any FAIL
  if (results.some(r => r.status === 'FAIL')) process.exit(1);
})();
