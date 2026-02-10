# Automation Boundary — playwright-bot

> This system intentionally stops automation before account-bound or monetized actions.
> All outputs are evidential artifacts for human decision.

---

## What IS Automated

| Layer | Action | Trigger | Output |
|-------|--------|---------|--------|
| Screenshot | Desktop + Mobile capture (26 sites) | Daily cron / manual dispatch | JPEG artifacts (14-day retention) |
| Link Check | HEAD request per link (max 50/site) | Same | Broken link list (JSON) |
| Console | Browser console error capture | Same | Error list (JSON) |
| Report | Structured JSON + Markdown generation | Same | `runs/<id>/summary.json`, `sites.json`, `report.md` |
| History | Run index with auto-cleanup (max 5) | Same | `runs/index.json` |
| Commit | QA results committed to repo | Post-check | Git push (runs/ only) |

---

## What Requires Human Judgment

| Item | Why Not Automated | Human Action |
|------|-------------------|--------------|
| Broken link triage | 403 = external block vs actual broken. 404 = private repo vs dead link. | Classify: fix / whitelist / ignore |
| Console error triage | Not all console errors are bugs (e.g., third-party script warnings). | Decide: fix / suppress / accept |
| Fix implementation | Broken links span 11+ repos with different architectures. | Edit source files in each repo |
| Priority decision | "Which 5 of 14 broken links matter today?" | Human ranks by business impact |
| Deploy verification | "Did the fix actually work?" | Trigger re-run, inspect dashboard |

---

## What Is Intentionally Excluded

| Item | Reason | Category |
|------|--------|----------|
| Auto-fix broken links | Cross-repo write = token sprawl + blast radius | Scope Boundary |
| GUI click automation | Platform ban risk (YouTube/Google TOS) | Red Line |
| Login-gated page checks | Credential storage in Actions = security risk | Red Line |
| Termux:API notifications | Repo-centric OS doesn't need device hooks | Over-engineering |
| Shizuku/ADB automation | Same as above | Over-engineering |
| SEO/Lighthouse scoring | Scope Boundary (this is health check, not optimization) | Scope Boundary |
| Uptime monitoring | GitHub Pages has its own uptime; we check content, not availability | Scope Boundary |

---

## Operating Modes

This repo has two distinct operating modes:

### Mode 1: Actions QA (Primary)

```
GitHub Actions (Ubuntu + Playwright)
  → 26 sites × Desktop + Mobile
  → Structured JSON committed to runs/
  → Screenshots uploaded as artifacts
  → Papyrus dashboard reads via raw.githubusercontent.com
```

- **Trigger**: Daily 06:00 UTC / manual / urls.json push
- **Zero phone involvement**

### Mode 2: Local CDP (Secondary)

```
Termux (Android + system Chromium + ws)
  → Single URL screenshot via CDP
  → Local file output only
```

- **Files**: `snap.js`, `screenshot.js`, `screenshot-mobile.js`
- **Use case**: Quick visual check during development
- **Not part of QA pipeline**

---

## Signal Legend (for Papyrus Dashboard)

| Signal | Meaning |
|--------|---------|
| PASS | Site loads, no broken links, no critical errors |
| WARN | Broken links found OR console errors detected |
| FAIL | Site failed to load within timeout |
| N/A | Intentionally excluded from check (whitelist) |

---

## One-Line Definition

> **playwright-bot produces evidence. Humans produce decisions.**

---

*Effective: 2026-02-10*
