# QA Snapshot Report

**Run ID:** 2026-03-15-06-17
**Generated:** 2026-03-15 06:18:53 UTC
**Sites checked:** 27
**Duration:** 81s
**Summary:** 8 PASS / 15 WARN / 4 FAIL / 18 broken links

---

| Status | Site | Load | Links | Errors | DocQA |
|--------|------|------|-------|--------|-------|
| OK | Gohsy Production | 2.3s | 0 | 0 | 6/6 |
| OK | Gohsy | 2.1s | 0 | 0 | 6/6 |
| !! | Branch HQ | 2.0s | 0 | 1 | 5/6 |
| OK | Espiritu Tango | 2.0s | 0 | 1 | 6/6 |
| !! | Phoneparis | 1.2s | 1 | 0 | 6/6 |
| !! | DTSLIB HQ | 1.2s | 2 | 0 | 6/6 |
| OK | EAE University | 1.1s | 0 | 0 | 6/6 |
| !! | Buckley Chang | 1.0s | 1 | 0 | 5/6 |
| !! | Papafly | 0.9s | 0 | 0 | 5/6 |
| XX | Koosy | 0.8s | 0 | 0 | 5/6 |
| OK | Alexandria Sanctuary | 0.8s | 0 | 0 | 6/6 |
| !! | Parksy Image | 0.8s | 0 | 4 | 5/6 |
| !! | APK Lab | 0.8s | 0 | 0 | 4/6 |
| !! | Hoyadang | 0.8s | 0 | 0 | 5/6 |
| OK | OPS Dashboard | 0.8s | 0 | 5 | 6/6 |
| !! | EAE.kr | 0.7s | 8 | 0 | 6/6 |
| OK | Buddies.kr | 0.7s | 0 | 0 | 6/6 |
| !! | Artrew | 0.7s | 0 | 0 | 5/6 |
| !! | Parksy Audio | 0.6s | 0 | 0 | 5/6 |
| !! | Cloud Appstore | 0.6s | 1 | 0 | 5/6 |
| OK | Parksy.kr | 0.6s | 0 | 0 | 6/6 |
| !! | DTSLIB.kr | 0.6s | 1 | 0 | 6/6 |
| !! | OrbitPrompt | 0.6s | 0 | 0 | 4/6 |
| !! | Parksy Logs | 0.6s | 0 | 0 | 4/6 |
| XX | Namone | 0.5s | 2 | 1 | 3/6 |
| XX | Dongseon Studio | 0.5s | 2 | 1 | 3/6 |
| XX | Namoneygoal | 0.1s | 0 | 0 | 2/6 |

---

## Document QA (Lane A)

> "PWA 앱이 아니라 문서 웹" — 읽어주기/번역/검색이 먹히는 구조인지

| Site | sw-off | skeleton | text-density | url-nav | meta | freshness |
|------|------|------|------|------|------|------|
| Gohsy Production | OK | OK | OK | OK | OK | OK |
| Gohsy | OK | OK | OK | OK | OK | OK |
| Branch HQ | OK | OK | !! | OK | OK | OK |
| Espiritu Tango | OK | OK | OK | OK | OK | OK |
| Phoneparis | OK | OK | OK | OK | OK | OK |
| DTSLIB HQ | OK | OK | OK | OK | OK | OK |
| EAE University | OK | OK | OK | OK | OK | OK |
| Buckley Chang | OK | !! | OK | OK | OK | OK |
| Papafly | OK | !! | OK | OK | OK | OK |
| Koosy | OK | XX | OK | OK | OK | OK |
| Alexandria Sanctuary | OK | OK | OK | OK | OK | OK |
| Parksy Image | OK | OK | OK | OK | !! | OK |
| APK Lab | OK | !! | OK | OK | !! | OK |
| Hoyadang | OK | !! | OK | OK | OK | OK |
| OPS Dashboard | OK | OK | OK | OK | OK | OK |
| EAE.kr | OK | OK | OK | OK | OK | OK |
| Buddies.kr | OK | OK | OK | OK | OK | OK |
| Artrew | OK | !! | OK | OK | OK | OK |
| Parksy Audio | OK | OK | OK | OK | !! | OK |
| Cloud Appstore | OK | !! | OK | OK | OK | OK |
| Parksy.kr | OK | OK | OK | OK | OK | OK |
| DTSLIB.kr | OK | OK | OK | OK | OK | OK |
| OrbitPrompt | OK | !! | OK | OK | !! | OK |
| Parksy Logs | OK | !! | OK | OK | !! | OK |
| Namone | OK | !! | !! | OK | XX | OK |
| Dongseon Studio | OK | !! | !! | OK | XX | OK |
| Namoneygoal | OK | XX | XX | OK | XX | !! |

### DocQA Issues

**Branch HQ:**
- [!!] 가시 텍스트 500자+: 326 chars

**Buckley Chang:**
- [!!] 문서 골격: h1: 1, main/article: false

**Papafly:**
- [!!] 문서 골격: h1: 1, main/article: false

**Koosy:**
- [XX] 문서 골격: h1: 0, main/article: false

**Parksy Image:**
- [!!] lang/title/desc/charset: Missing: description

**APK Lab:**
- [!!] 문서 골격: h1: 1, main/article: false
- [!!] lang/title/desc/charset: Missing: description

**Hoyadang:**
- [!!] 문서 골격: h1: 1, main/article: false

**Artrew:**
- [!!] 문서 골격: h1: 1, main/article: false

**Parksy Audio:**
- [!!] lang/title/desc/charset: Missing: description

**Cloud Appstore:**
- [!!] 문서 골격: h1: 1, main/article: false

**OrbitPrompt:**
- [!!] 문서 골격: h1: 1, main/article: false
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

**Namoneygoal:**
- [XX] 문서 골격: h1: 0, main/article: false
- [XX] 가시 텍스트 500자+: 0 chars
- [XX] lang/title/desc/charset: Missing: lang, title, description, charset
- [!!] Response freshness: no ETag or Last-Modified

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

### Buckley Chang
URL: https://buckleychang.com

**Broken links:**
- [404] Zone Check 시작하기 → → https://buckleychang.com/zone-check/

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

**Broken links:**
- [404] → Pentagon Hub → https://eae-univ.github.io/
- [404] EML
        Editorial Markup Language
        콘텐츠  → https://eae-univ.github.io/eml
- [404] QSketch
        Quick Sketch System
        아이디어를  → https://eae-univ.github.io/qsketch
- [404] MAL
        Multi-Agent Layering
        AI 에이전트 역 → https://eae-univ.github.io/mal
- [404] PENON
        Persona Engineering
        캐릭터 IP 설 → https://eae-univ.github.io/penon
- [404] PHL
        Philosophy Layering
        철학을 콘텐츠 레이 → https://eae-univ.github.io/phl
- [404] Patchtech
        Patch Technology
        기존 시스템  → https://eae-univ.github.io/patchtech
- [404] → GitHub 원본 보기 → https://github.com/dtslib1979/eae.kr/tree/main/src/content

### Cloud Appstore
URL: https://dtslib-cloud-appstore.vercel.app/

**Broken links:**
- [404] GitHub → https://github.com/dtslib1979/dtslib-cloud-appstore

### DTSLIB.kr
URL: https://dtslib.kr

**Broken links:**
- [404] 아카이브 열기 → → https://dtslib2k.tistory.com/

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

