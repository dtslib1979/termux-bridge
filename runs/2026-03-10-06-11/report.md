# QA Snapshot Report

**Run ID:** 2026-03-10-06-11
**Generated:** 2026-03-10 06:12:49 UTC
**Sites checked:** 27
**Duration:** 83s
**Summary:** 9 PASS / 15 WARN / 3 FAIL / 33 broken links

---

| Status | Site | Load | Links | Errors | DocQA |
|--------|------|------|-------|--------|-------|
| OK | Gohsy Production | 2.2s | 0 | 0 | 6/6 |
| !! | Branch HQ | 2.2s | 0 | 1 | 5/6 |
| OK | Gohsy | 2.1s | 0 | 0 | 6/6 |
| OK | Espiritu Tango | 1.9s | 0 | 1 | 6/6 |
| !! | Phoneparis | 1.2s | 1 | 0 | 6/6 |
| !! | DTSLIB HQ | 1.0s | 2 | 0 | 6/6 |
| !! | Namoneygoal | 1.0s | 0 | 2 | 6/6 |
| !! | Buckley Chang | 0.9s | 0 | 0 | 5/6 |
| XX | Koosy | 0.8s | 0 | 0 | 5/6 |
| OK | Alexandria Sanctuary | 0.8s | 0 | 0 | 6/6 |
| !! | Parksy Image | 0.8s | 0 | 4 | 5/6 |
| !! | Papafly | 0.8s | 0 | 0 | 5/6 |
| OK | OPS Dashboard | 0.8s | 0 | 5 | 6/6 |
| !! | Hoyadang | 0.8s | 0 | 0 | 5/6 |
| !! | Cloud Appstore | 0.8s | 0 | 0 | 5/6 |
| !! | APK Lab | 0.7s | 0 | 0 | 4/6 |
| !! | EAE.kr | 0.7s | 26 | 0 | 6/6 |
| OK | Buddies.kr | 0.7s | 0 | 0 | 6/6 |
| OK | EAE University | 0.7s | 0 | 0 | 6/6 |
| !! | Artrew | 0.7s | 0 | 0 | 5/6 |
| !! | OrbitPrompt | 0.7s | 0 | 0 | 4/6 |
| !! | Parksy Audio | 0.7s | 0 | 0 | 5/6 |
| OK | DTSLIB.kr | 0.6s | 0 | 1 | 6/6 |
| !! | Parksy Logs | 0.6s | 0 | 0 | 4/6 |
| OK | Parksy.kr | 0.6s | 0 | 0 | 6/6 |
| XX | Namone | 0.5s | 2 | 1 | 3/6 |
| XX | Dongseon Studio | 0.5s | 2 | 1 | 3/6 |

---

## Document QA (Lane A)

> "PWA 앱이 아니라 문서 웹" — 읽어주기/번역/검색이 먹히는 구조인지

| Site | sw-off | skeleton | text-density | url-nav | meta | freshness |
|------|------|------|------|------|------|------|
| Gohsy Production | OK | OK | OK | OK | OK | OK |
| Branch HQ | OK | OK | !! | OK | OK | OK |
| Gohsy | OK | OK | OK | OK | OK | OK |
| Espiritu Tango | OK | OK | OK | OK | OK | OK |
| Phoneparis | OK | OK | OK | OK | OK | OK |
| DTSLIB HQ | OK | OK | OK | OK | OK | OK |
| Namoneygoal | OK | OK | OK | OK | OK | OK |
| Buckley Chang | OK | OK | !! | OK | OK | OK |
| Koosy | OK | XX | OK | OK | OK | OK |
| Alexandria Sanctuary | OK | OK | OK | OK | OK | OK |
| Parksy Image | OK | OK | OK | OK | !! | OK |
| Papafly | OK | !! | OK | OK | OK | OK |
| OPS Dashboard | OK | OK | OK | OK | OK | OK |
| Hoyadang | OK | !! | OK | OK | OK | OK |
| Cloud Appstore | OK | !! | OK | OK | OK | OK |
| APK Lab | OK | !! | OK | OK | !! | OK |
| EAE.kr | OK | OK | OK | OK | OK | OK |
| Buddies.kr | OK | OK | OK | OK | OK | OK |
| EAE University | OK | OK | OK | OK | OK | OK |
| Artrew | OK | !! | OK | OK | OK | OK |
| OrbitPrompt | OK | !! | OK | OK | !! | OK |
| Parksy Audio | OK | OK | OK | OK | !! | OK |
| DTSLIB.kr | OK | OK | OK | OK | OK | OK |
| Parksy Logs | OK | !! | OK | OK | !! | OK |
| Parksy.kr | OK | OK | OK | OK | OK | OK |
| Namone | OK | !! | !! | OK | XX | OK |
| Dongseon Studio | OK | !! | !! | OK | XX | OK |

### DocQA Issues

**Branch HQ:**
- [!!] 가시 텍스트 500자+: 326 chars

**Buckley Chang:**
- [!!] 가시 텍스트 500자+: 412 chars

**Koosy:**
- [XX] 문서 골격: h1: 0, main/article: false

**Parksy Image:**
- [!!] lang/title/desc/charset: Missing: description

**Papafly:**
- [!!] 문서 골격: h1: 1, main/article: false

**Hoyadang:**
- [!!] 문서 골격: h1: 1, main/article: false

**Cloud Appstore:**
- [!!] 문서 골격: h1: 1, main/article: false

**APK Lab:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] lang/title/desc/charset: Missing: description

**Artrew:**
- [!!] 문서 골격: h1: 1, main/article: false

**OrbitPrompt:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] lang/title/desc/charset: Missing: description

**Parksy Audio:**
- [!!] lang/title/desc/charset: Missing: description

**Parksy Logs:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] lang/title/desc/charset: Missing: description

**Namone:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] 가시 텍스트 500자+: 220 chars
- [XX] lang/title/desc/charset: Missing: lang, description

**Dongseon Studio:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] 가시 텍스트 500자+: 220 chars
- [XX] lang/title/desc/charset: Missing: lang, description

---

## Link & Console Issues

### Branch HQ
URL: https://dtslib1979.github.io/dtslib-branch

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()

### Espiritu Tango
URL: https://dtslib1979.github.io/espiritu-tango

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()

### Phoneparis
URL: https://dtslib1979.github.io/phoneparis

**Broken links:**
- [404] Baptism
        → → http://phoneparis.kr/products/baptism/

### DTSLIB HQ
URL: https://dtslib.com

**Broken links:**
- [404] dongseon-studio디지털 렌더링 스튜디오 → https://dtslib1979.github.io/dongseon-studio
- [404] namone부동산 길드장 → https://dtslib1979.github.io/namone/

### Namoneygoal
URL: https://dtslib1979.github.io/namoneygoal

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()
- Registry load failed: SyntaxError: Unexpected token '<', "<!DOCTYPE "... is not valid JSON

### Parksy Image
URL: https://dtslib1979.github.io/parksy-image

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()
- Failed to load resource: the server responded with a status of 404 ()
- Failed to load resource: the server responded with a status of 404 ()
- Failed to load resource: the server responded with a status of 404 ()

### OPS Dashboard
URL: https://dtslib.com/dashboard/

**Console errors:**
- Access to fetch at 'https://dtslib1979.github.io/playwright-bot/runs/index.json' from origin 'https://dtslib.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on
- Failed to load resource: net::ERR_FAILED
- Failed to load resource: the server responded with a status of 404 ()
- Failed to load resource: the server responded with a status of 404 ()
- Failed to load resource: the server responded with a status of 404 ()

### EAE.kr
URL: https://eae.kr

**Broken links:**
- [404] Channeling Technique — Beyond Empathy into Full Pe → https://www.eae.kr/category/channeling/channeling-vs-empathy
- [404] Three Accounts, Three Worldviews — Multi-Persona O → https://www.eae.kr/category/channeling/multi-persona-operation
- [404] Range and Scope — Defining University in the AI Er → https://www.eae.kr/category/eae-blueprint/range-and-scope-ai-university
- [404] Serendipity — How a Wrong Repo Assignment Created  → https://www.eae.kr/category/eae-blueprint/serendipity-repo-structure
- [404] 🗂️ArchiveFull Index → https://www.eae.kr/archive
- [404] 🎨EAE Univ.YouTube lecture structure & design3 → https://www.eae.kr/category/eae-blueprint
- [404] 📄Editorial Technique8 → https://www.eae.kr/category/editorial
- [404] 📄Operational Technique3 → https://www.eae.kr/category/operational
- [404] 📄Channeling Technique2 → https://www.eae.kr/category/channeling
- [404] 📄Survival Technique2 → https://www.eae.kr/category/survival
- [404] AI Visual Material Library for YouTubeeae-blueprin → https://www.eae.kr/category/eae-blueprint/ai-visual-material-library
- [404] MAL — My Authentic Language: Owning Your Wordsedit → https://www.eae.kr/category/editorial/authentic-language
- [404] PHL — Compressing 200 Words into 3 Concept Tokense → https://www.eae.kr/category/editorial/concept-token-compression
- [404] Editorial Technique — The Meta Philosophy of EAE U → https://www.eae.kr/category/editorial/editorial-manifesto
- [404] EML — Emotion Music Lab: Editing Feelings into Sou → https://www.eae.kr/category/editorial/emotion-music-editorial
- [404] Loop Author: System as Mediumeditorial2026-03-07 → https://www.eae.kr/category/editorial/loop-author
- [404] PENON — When the Pen Touches Paper, Thought Become → https://www.eae.kr/category/editorial/pen-on-structure
- [404] QSketch — Speed Drawing is Proof of Understandinge → https://www.eae.kr/category/editorial/speed-draw-units
- [404] Patchtech — Editing Technology Like Editing Texted → https://www.eae.kr/category/editorial/tech-material-editorial
- [404] Browser is Studio — 13 Free Engines for Broadcast  → https://www.eae.kr/category/operational/browser-is-studio
- [404] A Commit is a Voucher — Matrix Architecture ERP Ax → https://www.eae.kr/category/operational/commit-is-voucher
- [404] PhonePress ERP — Running a Content Factory from a  → https://www.eae.kr/category/operational/phonepress-erp
- [404] CLAUDE.md is a Franchise Manual — 23 Constitutions → https://www.eae.kr/category/survival/franchise-manual
- [404] Quantum Jump — Franchising a 28-Repository Content → https://www.eae.kr/category/survival/quantum-jump
- [404] 📚ArchiveAll content → https://eae.kr/archive
- [404] 📋AboutMission → https://eae.kr/about

### DTSLIB.kr
URL: https://dtslib.kr

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()

### Namone
URL: https://dtslib1979.github.io/namone/

**Broken links:**
- [403] @githubstatus → https://twitter.com/githubstatus
- [404] (no text) → https://dtslib1979.github.io/

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()

### Dongseon Studio
URL: https://dtslib1979.github.io/dongseon-studio

**Broken links:**
- [403] @githubstatus → https://twitter.com/githubstatus
- [404] (no text) → https://dtslib1979.github.io/

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()

