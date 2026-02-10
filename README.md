# playwright-bot

Automated site health checks for the DTSLIB ecosystem.

> **playwright-bot produces evidence. Humans produce decisions.**

## What It Does

- Checks **26 sites** across 3 tiers (HQ, Studios, Branches)
- Captures **Desktop + Mobile** screenshots
- Detects **broken links** (up to 50 per site)
- Collects **console errors**
- Outputs **structured JSON** + Markdown reports

## Architecture

```
GitHub Actions (Daily 06:00 UTC)
  │
  ├── Screenshots → Artifacts (14-day retention)
  │
  └── JSON Results → git commit to runs/
                       │
                       └── Papyrus Dashboard fetches via
                           raw.githubusercontent.com
```

## Quick Start

**Trigger manually:**
```bash
gh workflow run qa-snapshot.yml
```

**Run locally (Actions environment):**
```bash
npm install playwright
npx playwright install chromium
node qa/check.js
```

**Run with filters:**
```bash
node qa/check.js --tier=1          # HQ only
node qa/check.js --id=koosy,gohsy  # specific sites
```

## File Structure

```
playwright-bot/
├── qa/
│   ├── check.js          # QA engine (310 lines)
│   └── urls.json          # 26 sites + ignore whitelist
├── runs/                   # Auto-generated results
│   ├── index.json          # Last 5 runs index
│   └── <runId>/
│       ├── summary.json
│       ├── sites.json
│       └── report.md
├── local/                  # Termux CDP tools (secondary)
│   ├── snap.js
│   ├── screenshot.js
│   └── screenshot-mobile.js
├── 00_TRUTH/
│   └── automation-boundary.md
├── .github/workflows/
│   └── qa-snapshot.yml
└── DEVLOG.md
```

## Automation Boundary

| Layer | Automated | Human |
|-------|-----------|-------|
| Detection | Screenshots, link checks, error capture | - |
| Classification | - | Triage broken links (fix / whitelist / ignore) |
| Remediation | - | Edit source files across repos |
| Verification | Re-run QA check | Inspect dashboard |

See [`00_TRUTH/automation-boundary.md`](./00_TRUTH/automation-boundary.md) for the full spec.

## Dashboard

Live at [dtslib.com/qa/](https://dtslib.com/qa/) — reads from this repo's `runs/` directory.

## Part of

[DTSLIB Franchise OS](https://dtslib.com) — Infra category
