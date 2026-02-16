# QA Snapshot Report

**Run ID:** 2026-02-16-06-20
**Generated:** 2026-02-16 06:22:28 UTC
**Sites checked:** 27
**Duration:** 119s
**Summary:** 15 PASS / 12 WARN / 0 FAIL / 0 broken links

---

| Status | Site | Load | Links | Errors | DocQA |
|--------|------|------|-------|--------|-------|
| OK | Gohsy | 2.7s | 0 | 2 | 6/6 |
| OK | Gohsy Production | 2.6s | 0 | 0 | 6/6 |
| OK | Koosy | 2.5s | 0 | 0 | 6/6 |
| OK | Artrew | 2.5s | 0 | 0 | 6/6 |
| OK | Papafly | 2.4s | 0 | 0 | 6/6 |
| OK | Espiritu Tango | 2.4s | 0 | 1 | 6/6 |
| !! | Branch HQ | 2.4s | 0 | 1 | 5/6 |
| OK | DTSLIB HQ | 1.6s | 0 | 0 | 6/6 |
| !! | Namoneygoal | 1.2s | 0 | 2 | 6/6 |
| !! | Dongseon Studio | 1.2s | 0 | 0 | 5/6 |
| OK | Phoneparis | 1.1s | 0 | 0 | 6/6 |
| !! | Hoyadang | 1.1s | 0 | 0 | 5/6 |
| !! | Buckley Chang | 1.1s | 0 | 0 | 5/6 |
| !! | Cloud Appstore | 1.0s | 0 | 0 | 4/6 |
| OK | Alexandria Sanctuary | 1.0s | 0 | 0 | 6/6 |
| !! | Namone | 1.0s | 0 | 0 | 4/6 |
| !! | Parksy Image | 1.0s | 0 | 4 | 5/6 |
| OK | EAE University | 1.0s | 0 | 0 | 6/6 |
| !! | Parksy Logs | 0.9s | 0 | 0 | 4/6 |
| !! | APK Lab | 0.9s | 0 | 0 | 3/6 |
| OK | OPS Dashboard | 0.9s | 0 | 4 | 6/6 |
| OK | EAE.kr | 0.9s | 0 | 1 | 6/6 |
| !! | Parksy Audio | 0.8s | 0 | 0 | 5/6 |
| OK | Buddies.kr | 0.8s | 0 | 0 | 6/6 |
| !! | OrbitPrompt | 0.8s | 0 | 0 | 4/6 |
| OK | DTSLIB.kr | 0.8s | 0 | 1 | 6/6 |
| OK | Parksy.kr | 0.8s | 0 | 0 | 6/6 |

---

## Document QA (Lane A)

> "PWA 앱이 아니라 문서 웹" — 읽어주기/번역/검색이 먹히는 구조인지

| Site | sw-off | skeleton | text-density | url-nav | meta | freshness |
|------|------|------|------|------|------|------|
| Gohsy | OK | OK | OK | OK | OK | OK |
| Gohsy Production | OK | OK | OK | OK | OK | OK |
| Koosy | OK | OK | OK | OK | OK | OK |
| Artrew | OK | OK | OK | OK | OK | OK |
| Papafly | OK | OK | OK | OK | OK | OK |
| Espiritu Tango | OK | OK | OK | OK | OK | OK |
| Branch HQ | OK | OK | !! | OK | OK | OK |
| DTSLIB HQ | OK | OK | OK | OK | OK | OK |
| Namoneygoal | OK | OK | OK | OK | OK | OK |
| Dongseon Studio | OK | !! | OK | OK | OK | OK |
| Phoneparis | OK | OK | OK | OK | OK | OK |
| Hoyadang | OK | !! | OK | OK | OK | OK |
| Buckley Chang | OK | OK | !! | OK | OK | OK |
| Cloud Appstore | OK | !! | !! | OK | OK | OK |
| Alexandria Sanctuary | OK | OK | OK | OK | OK | OK |
| Namone | OK | !! | !! | OK | OK | OK |
| Parksy Image | OK | OK | OK | OK | !! | OK |
| EAE University | OK | OK | OK | OK | OK | OK |
| Parksy Logs | OK | !! | OK | OK | !! | OK |
| APK Lab | OK | !! | !! | OK | !! | OK |
| OPS Dashboard | OK | OK | OK | OK | OK | OK |
| EAE.kr | OK | OK | OK | OK | OK | OK |
| Parksy Audio | OK | OK | OK | OK | !! | OK |
| Buddies.kr | OK | OK | OK | OK | OK | OK |
| OrbitPrompt | OK | !! | OK | OK | !! | OK |
| DTSLIB.kr | OK | OK | OK | OK | OK | OK |
| Parksy.kr | OK | OK | OK | OK | OK | OK |

### DocQA Issues

**Branch HQ:**
- [!!] 가시 텍스트 500자+: 326 chars

**Dongseon Studio:**
- [!!] 문서 골격: h1: 0, main/article: true

**Hoyadang:**
- [!!] 문서 골격: h1: 1, main/article: false

**Buckley Chang:**
- [!!] 가시 텍스트 500자+: 412 chars

**Cloud Appstore:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] 가시 텍스트 500자+: 338 chars

**Namone:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] 가시 텍스트 500자+: 280 chars

**Parksy Image:**
- [!!] lang/title/desc/charset: Missing: description

**Parksy Logs:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] lang/title/desc/charset: Missing: description

**APK Lab:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] 가시 텍스트 500자+: 217 chars
- [!!] lang/title/desc/charset: Missing: description

**Parksy Audio:**
- [!!] lang/title/desc/charset: Missing: description

**OrbitPrompt:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] lang/title/desc/charset: Missing: description

---

## Link & Console Issues

### Gohsy
URL: https://dtslib1979.github.io/gohsy

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()
- Failed to load resource: the server responded with a status of 404 ()

### Espiritu Tango
URL: https://dtslib1979.github.io/espiritu-tango

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()

### Branch HQ
URL: https://dtslib1979.github.io/dtslib-branch

**Console errors:**
- Failed to load resource: the server responded with a status of 404 ()

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
- Failed to load resource: the server responded with a status of 404 ()
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

