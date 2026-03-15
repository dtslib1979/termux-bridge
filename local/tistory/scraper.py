#!/usr/bin/env python3
"""
Tistory 전체 포스트 HTML 수집기
RSS → 포스트 개별 URL → HTML 모드 원문 저장

사용법:
    python scraper.py
    python scraper.py --blog blogger-parksy  # 특정 블로그만
"""

import argparse
import json
import re
import time
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path
import urllib.request
import urllib.error

ARCHIVE_DIR = Path.home() / "parksy.kr" / "backup" / "blogs"
MANIFEST_FILE = ARCHIVE_DIR / "manifest.json"

DELAY = 1.5  # 요청 간 딜레이 (초)

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "ko-KR,ko;q=0.9,en;q=0.8",
}

# 확정된 블로그 목록 (서브도메인 확인됨)
BLOGS = [
    {"account": "parksy_kr", "name": "blogger-parksy",     "url": "https://blogger-parksy.tistory.com"},
    {"account": "parksy_kr", "name": "philosopher-parksy",  "url": "https://philosopher-parksy.tistory.com"},
    {"account": "parksy_kr", "name": "visualizer-parksy",   "url": "https://visualizer-parksy.tistory.com"},
    {"account": "parksy_kr", "name": "musician-parksy",     "url": "https://musician-parksy.tistory.com"},
    {"account": "parksy_kr", "name": "technician-parksy",   "url": "https://technician-parksy.tistory.com"},
    {"account": "eae_kr",    "name": "eae-kr",              "url": "https://eae-kr.tistory.com"},
    {"account": "dtslib1k",  "name": "dtslib1k",            "url": "https://dtslib1k.tistory.com"},
    {"account": "dtslib2k",  "name": "dtslib2k",            "url": "https://dtslib2k.tistory.com"},
]


def fetch(url, timeout=15):
    req = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read()
            # 인코딩 감지
            ct = r.headers.get("Content-Type", "")
            enc = "utf-8"
            if "charset=" in ct:
                enc = ct.split("charset=")[-1].strip()
            try:
                return raw.decode(enc, errors="replace")
            except Exception:
                return raw.decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        print(f"  ✗ HTTP {e.code}: {url}")
        return None
    except Exception as e:
        print(f"  ✗ Error: {url} — {e}")
        return None


def parse_rss(blog_url, blog_name):
    """RSS에서 포스트 목록 추출"""
    rss_url = f"{blog_url}/rss"
    print(f"  RSS: {rss_url}")
    content = fetch(rss_url)
    if not content:
        return []

    posts = []
    try:
        # XML 파싱
        root = ET.fromstring(content.encode("utf-8"))
        ns = ""
        channel = root.find("channel")
        if channel is None:
            return []

        for item in channel.findall("item"):
            title_el = item.find("title")
            link_el  = item.find("link")
            date_el  = item.find("pubDate")
            desc_el  = item.find("description")

            title = title_el.text if title_el is not None else "제목없음"
            link  = link_el.text  if link_el  is not None else ""
            date  = date_el.text  if date_el  is not None else ""
            desc  = desc_el.text  if desc_el  is not None else ""

            # post id 추출
            post_id = ""
            m = re.search(r"/(\d+)$", link.strip())
            if m:
                post_id = m.group(1)

            posts.append({
                "title": title.strip(),
                "url":   link.strip(),
                "post_id": post_id,
                "date":  date.strip(),
                "rss_html": desc.strip(),
            })
    except ET.ParseError as e:
        print(f"  ✗ RSS 파싱 오류: {e}")

    return posts


def extract_post_html(page_html):
    """포스트 페이지에서 본문 HTML 추출"""
    # 에디터 원문 (hidden input or script)
    patterns = [
        r'<textarea[^>]*id=["\']?content["\']?[^>]*>([\s\S]*?)</textarea>',
        r'"content"\s*:\s*"([\s\S]*?)"(?:,|\})',
        r'<div[^>]*class=["\'][^"\']*\bcont\b[^"\']*["\'][^>]*>([\s\S]*?)</div>',
        r'<div[^>]*class=["\'][^"\']*\barticle\b[^"\']*["\'][^>]*>([\s\S]*?)</div>',
    ]

    # 1순위: #tt-body-page 또는 .entry-content
    m = re.search(r'<div[^>]*class=["\'][^"\']*\btt-body-page\b[^"\']*["\'][^>]*>([\s\S]*?)</div>\s*</div>', page_html)
    if m:
        return m.group(1).strip()

    m = re.search(r'<div[^>]*id=["\']?article-view["\']?[^>]*>([\s\S]*?)</div>(?:\s*</div>){1,3}', page_html)
    if m:
        return m.group(1).strip()

    # 2순위: og:description 으로 최소한 내용 보존
    m = re.search(r'<meta\s+property=["\']og:description["\']\s+content=["\'](.*?)["\']', page_html)
    if m:
        return f"<!-- og:description fallback -->\n<p>{m.group(1)}</p>"

    return "<!-- 본문 추출 실패 -->"


def save_post(blog_name, post, page_html):
    """포스트 저장"""
    blog_dir = ARCHIVE_DIR / blog_name
    blog_dir.mkdir(parents=True, exist_ok=True)

    post_id = post["post_id"] or "unknown"
    safe_title = re.sub(r'[\\/*?:"<>|]', "_", post["title"])[:60]
    filename = f"{post_id}_{safe_title}.html"
    filepath = blog_dir / filename

    body_html = extract_post_html(page_html)

    content = f"""<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<title>{post['title']}</title>
<!-- SOURCE: {post['url']} -->
<!-- DATE: {post['date']} -->
<!-- BLOG: {blog_name} -->
<!-- SCRAPED: {datetime.now().isoformat()} -->
</head>
<body>
<!-- ===== RSS HTML (원문) ===== -->
<div id="rss-content">
{post['rss_html']}
</div>

<!-- ===== PAGE HTML (파싱) ===== -->
<div id="page-content">
{body_html}
</div>

<!-- ===== RAW PAGE (전체) ===== -->
<script type="text/x-raw-page">
{page_html[:50000]}
</script>
</body>
</html>"""

    filepath.write_text(content, encoding="utf-8")
    return filepath


def scrape_blog(blog_info):
    blog_name = blog_info["name"]
    blog_url  = blog_info["url"]
    account   = blog_info["account"]

    print(f"\n{'='*60}")
    print(f"블로그: {blog_name} ({account})")
    print(f"URL: {blog_url}")

    posts = parse_rss(blog_url, blog_name)
    if not posts:
        print(f"  → 포스트 없음 (비공개 또는 접근 불가)")
        return []

    print(f"  → {len(posts)}개 포스트 발견")

    results = []
    for i, post in enumerate(posts, 1):
        print(f"  [{i}/{len(posts)}] {post['title'][:40]}...")
        if not post["url"]:
            continue

        time.sleep(DELAY)
        page_html = fetch(post["url"])
        if not page_html:
            print(f"    ✗ 페이지 접근 실패")
            continue

        saved = save_post(blog_name, post, page_html)
        print(f"    ✓ 저장: {saved.name}")

        results.append({
            "blog": blog_name,
            "account": account,
            "post_id": post["post_id"],
            "title": post["title"],
            "url": post["url"],
            "date": post["date"],
            "file": str(saved),
        })

    return results


def load_manifest():
    if MANIFEST_FILE.exists():
        return json.loads(MANIFEST_FILE.read_text(encoding="utf-8"))
    return {"scraped_at": "", "total": 0, "posts": []}


def save_manifest(all_posts):
    manifest = {
        "scraped_at": datetime.now().isoformat(),
        "total": len(all_posts),
        "by_blog": {},
        "posts": all_posts,
    }
    for p in all_posts:
        b = p["blog"]
        manifest["by_blog"].setdefault(b, 0)
        manifest["by_blog"][b] += 1

    MANIFEST_FILE.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    return manifest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--blog", help="특정 블로그만 (name 기준)")
    args = parser.parse_args()

    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)

    target_blogs = BLOGS
    if args.blog:
        target_blogs = [b for b in BLOGS if b["name"] == args.blog]
        if not target_blogs:
            print(f"블로그 '{args.blog}' 없음. 가능한 목록:")
            for b in BLOGS:
                print(f"  {b['name']}")
            return

    all_posts = []
    for blog in target_blogs:
        posts = scrape_blog(blog)
        all_posts.extend(posts)

    manifest = save_manifest(all_posts)

    print(f"\n{'='*60}")
    print(f"완료: 총 {manifest['total']}개 포스트 수집")
    for blog_name, count in manifest["by_blog"].items():
        print(f"  {blog_name}: {count}개")
    print(f"저장 위치: {ARCHIVE_DIR}")
    print(f"매니페스트: {MANIFEST_FILE}")


if __name__ == "__main__":
    main()
