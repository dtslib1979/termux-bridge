# QA Snapshot Report

**Run ID:** 2026-03-02-06-15
**Generated:** 2026-03-02 06:16:43 UTC
**Sites checked:** 27
**Duration:** 94s
**Summary:** 13 PASS / 14 WARN / 0 FAIL / 1 broken links

---

| Status | Site | Load | Links | Errors | DocQA |
|--------|------|------|-------|--------|-------|
| OK | Koosy | 2.6s | 0 | 0 | 6/6 |
| OK | Gohsy Production | 2.5s | 0 | 0 | 6/6 |
| !! | Branch HQ | 2.3s | 0 | 1 | 5/6 |
| OK | Gohsy | 2.2s | 0 | 0 | 6/6 |
| OK | Artrew | 2.2s | 0 | 0 | 6/6 |
| OK | Espiritu Tango | 2.1s | 0 | 1 | 6/6 |
| !! | Papafly | 2.1s | 0 | 0 | 5/6 |
| !! | Phoneparis | 1.3s | 1 | 0 | 6/6 |
| OK | DTSLIB HQ | 1.2s | 0 | 0 | 6/6 |
| !! | Dongseon Studio | 1.0s | 0 | 0 | 5/6 |
| !! | Namoneygoal | 1.0s | 0 | 2 | 6/6 |
| !! | Buckley Chang | 0.9s | 0 | 0 | 5/6 |
| !! | Namone | 0.9s | 0 | 0 | 4/6 |
| OK | Alexandria Sanctuary | 0.8s | 0 | 0 | 6/6 |
| !! | Hoyadang | 0.8s | 0 | 0 | 5/6 |
| !! | Parksy Image | 0.8s | 0 | 4 | 5/6 |
| OK | OPS Dashboard | 0.8s | 0 | 5 | 6/6 |
| OK | Buddies.kr | 0.7s | 0 | 0 | 6/6 |
| OK | EAE University | 0.7s | 0 | 0 | 6/6 |
| !! | Parksy Audio | 0.7s | 0 | 0 | 5/6 |
| !! | Cloud Appstore | 0.6s | 0 | 0 | 4/6 |
| !! | Parksy Logs | 0.6s | 0 | 0 | 4/6 |
| !! | OrbitPrompt | 0.6s | 0 | 0 | 4/6 |
| OK | EAE.kr | 0.6s | 0 | 1 | 6/6 |
| !! | APK Lab | 0.6s | 0 | 0 | 3/6 |
| OK | DTSLIB.kr | 0.6s | 0 | 1 | 6/6 |
| OK | Parksy.kr | 0.6s | 0 | 0 | 6/6 |

---

## Document QA (Lane A)

> "PWA 앱이 아니라 문서 웹" — 읽어주기/번역/검색이 먹히는 구조인지

| Site | sw-off | skeleton | text-density | url-nav | meta | freshness |
|------|------|------|------|------|------|------|
| Koosy | OK | OK | OK | OK | OK | OK |
| Gohsy Production | OK | OK | OK | OK | OK | OK |
| Branch HQ | OK | OK | !! | OK | OK | OK |
| Gohsy | OK | OK | OK | OK | OK | OK |
| Artrew | OK | OK | OK | OK | OK | OK |
| Espiritu Tango | OK | OK | OK | OK | OK | OK |
| Papafly | OK | OK | !! | OK | OK | OK |
| Phoneparis | OK | OK | OK | OK | OK | OK |
| DTSLIB HQ | OK | OK | OK | OK | OK | OK |
| Dongseon Studio | OK | !! | OK | OK | OK | OK |
| Namoneygoal | OK | OK | OK | OK | OK | OK |
| Buckley Chang | OK | OK | !! | OK | OK | OK |
| Namone | OK | !! | !! | OK | OK | OK |
| Alexandria Sanctuary | OK | OK | OK | OK | OK | OK |
| Hoyadang | OK | !! | OK | OK | OK | OK |
| Parksy Image | OK | OK | OK | OK | !! | OK |
| OPS Dashboard | OK | OK | OK | OK | OK | OK |
| Buddies.kr | OK | OK | OK | OK | OK | OK |
| EAE University | OK | OK | OK | OK | OK | OK |
| Parksy Audio | OK | OK | OK | OK | !! | OK |
| Cloud Appstore | OK | !! | !! | OK | OK | OK |
| Parksy Logs | OK | !! | OK | OK | !! | OK |
| OrbitPrompt | OK | !! | OK | OK | !! | OK |
| EAE.kr | OK | OK | OK | OK | OK | OK |
| APK Lab | OK | !! | !! | OK | !! | OK |
| DTSLIB.kr | OK | OK | OK | OK | OK | OK |
| Parksy.kr | OK | OK | OK | OK | OK | OK |

### DocQA Issues

**Branch HQ:**
- [!!] 가시 텍스트 500자+: 326 chars

**Papafly:**
- [!!] 가시 텍스트 500자+: 455 chars

**Dongseon Studio:**
- [!!] 문서 골격: h1: 0, main/article: true

**Buckley Chang:**
- [!!] 가시 텍스트 500자+: 412 chars

**Namone:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] 가시 텍스트 500자+: 280 chars

**Hoyadang:**
- [!!] 문서 골격: h1: 1, main/article: false

**Parksy Image:**
- [!!] lang/title/desc/charset: Missing: description

**Parksy Audio:**
- [!!] lang/title/desc/charset: Missing: description

**Cloud Appstore:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] 가시 텍스트 500자+: 479 chars

**Parksy Logs:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] lang/title/desc/charset: Missing: description

**OrbitPrompt:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] lang/title/desc/charset: Missing: description

**APK Lab:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] 가시 텍스트 500자+: 319 chars
- [!!] lang/title/desc/charset: Missing: description

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
- Failed to load resource: the server responded with a status of 404 ()
- Access to fetch at 'https://dtslib1979.github.io/playwright-bot/runs/index.json' from origin 'https://dtslib.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on
- Failed to load resource: net::ERR_FAILED
- Failed to load resource: the server responded with a status of 404 ()
- Failed to load resource: the server responded with a status of 404 ()

### EAE.kr
URL: https://eae.kr

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()

### DTSLIB.kr
URL: https://dtslib.kr

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()

