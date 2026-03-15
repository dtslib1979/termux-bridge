#!/usr/bin/env python3
"""
Kakao → Tistory 세션 로그인
requests로 Kakao OAuth 처리 후 tistory.com 쿠키 획득
"""

import json
import re
import time
import urllib.parse
import urllib.request
import urllib.error
import http.cookiejar
from pathlib import Path

COOKIES_FILE = Path(__file__).parent / "cookies.json"

HEADERS_PC = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "ko-KR,ko;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
}


def make_opener():
    cj = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    opener.addheaders = list(HEADERS_PC.items())
    return opener, cj


def fetch(opener, url, data=None, extra_headers=None):
    headers = dict(HEADERS_PC)
    if extra_headers:
        headers.update(extra_headers)

    if data:
        if isinstance(data, dict):
            data = urllib.parse.urlencode(data).encode("utf-8")
        req = urllib.request.Request(url, data=data, headers=headers)
    else:
        req = urllib.request.Request(url, headers=headers)

    try:
        with opener.open(req, timeout=20) as r:
            raw = r.read()
            try:
                import zlib
                if r.headers.get("Content-Encoding") == "gzip":
                    raw = zlib.decompress(raw, 16 + zlib.MAX_WBITS)
                elif r.headers.get("Content-Encoding") == "deflate":
                    raw = zlib.decompress(raw)
            except Exception:
                pass
            return raw.decode("utf-8", errors="replace"), r.geturl()
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"  HTTP {e.code}: {url}")
        return body, url
    except Exception as e:
        print(f"  Error: {e}")
        return "", url


def extract_field(html, name):
    m = re.search(rf'name=["\']?{re.escape(name)}["\']?\s+[^>]*value=["\']([^"\']*)["\']', html)
    if not m:
        m = re.search(rf'value=["\']([^"\']*)["\'][^>]*name=["\']?{re.escape(name)}["\']?', html)
    return m.group(1) if m else ""


def cookies_to_dict(cj, domain=None):
    result = {}
    for c in cj:
        if domain is None or domain in c.domain:
            result[c.name] = c.value
    return result


def login(email, password):
    opener, cj = make_opener()

    print(f"[1] Tistory → Kakao OAuth 시작")
    html, final_url = fetch(opener, "https://www.tistory.com/auth/kakao?loginType=kakao&redirectUrl=https://www.tistory.com/")
    time.sleep(1)

    print(f"[2] Kakao 로그인 페이지: {final_url[:80]}")

    # hidden 필드 추출
    authenticity_token = extract_field(html, "authenticity_token")
    login_url_field    = extract_field(html, "url")
    login_key          = extract_field(html, "loginKey") or extract_field(html, "login_key")

    print(f"    authenticity_token: {'있음' if authenticity_token else '없음'}")
    print(f"    loginKey: {'있음' if login_key else '없음'}")

    # 로그인 엔드포인트 찾기
    action_m = re.search(r'action=["\']([^"\']+)["\']', html)
    action = action_m.group(1) if action_m else "/login/universal"
    if not action.startswith("http"):
        action = "https://accounts.kakao.com" + action

    print(f"[3] POST → {action}")

    post_data = {
        "loginId":         email,
        "password":        password,
        "saveLoginInfo":   "true",
        "url":             login_url_field or "https://www.tistory.com/",
        "loginKey":        login_key,
        "authenticity_token": authenticity_token,
    }
    post_data = {k: v for k, v in post_data.items() if v}

    html2, final_url2 = fetch(opener, action, data=post_data, extra_headers={
        "Content-Type": "application/x-www-form-urlencoded",
        "Referer": "https://accounts.kakao.com/",
        "Origin":  "https://accounts.kakao.com",
    })
    time.sleep(1.5)

    print(f"    최종 URL: {final_url2[:80]}")

    # 로그인 실패 감지
    if "로그인에 실패" in html2 or "incorrect" in html2.lower() or "비밀번호" in html2 and "틀" in html2:
        print("  ✗ 로그인 실패 — 이메일/비밀번호 확인")
        return None

    # 봇 감지
    if "captcha" in html2.lower() or "robot" in html2.lower():
        print("  ✗ 봇 감지됨")
        return None

    # tistory 쿠키 확인
    tistory_cookies = cookies_to_dict(cj, "tistory.com")
    kakao_cookies   = cookies_to_dict(cj, "kakao.com")

    print(f"\n    Tistory 쿠키: {list(tistory_cookies.keys())}")
    print(f"    Kakao 쿠키:   {list(kakao_cookies.keys())}")

    if not tistory_cookies:
        # 리다이렉트 수동 처리
        redirect_m = re.search(r'location\.href\s*=\s*["\']([^"\']+)["\']', html2)
        if not redirect_m:
            redirect_m = re.search(r'<meta[^>]+refresh[^>]+url=([^\s"\']+)', html2, re.I)
        if redirect_m:
            redir = redirect_m.group(1)
            print(f"[4] 리다이렉트 수동 처리: {redir[:80]}")
            fetch(opener, redir)
            time.sleep(1)
            tistory_cookies = cookies_to_dict(cj, "tistory.com")

    if not tistory_cookies:
        print("  ✗ Tistory 세션 쿠키 없음 — 봇 감지 or 로그인 흐름 변경됨")
        # html 일부 저장해서 디버깅
        debug_f = Path(__file__).parent / "debug_login.html"
        debug_f.write_text(html2, encoding="utf-8")
        print(f"  디버그 HTML 저장: {debug_f}")
        return None

    # 쿠키 저장
    all_cookies = {**kakao_cookies, **tistory_cookies}
    COOKIES_FILE.write_text(json.dumps(all_cookies, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\n  ✓ 로그인 성공! 쿠키 저장: {COOKIES_FILE}")
    return all_cookies, opener, cj


if __name__ == "__main__":
    import sys
    email    = sys.argv[1] if len(sys.argv) > 1 else "dtslib1k@kakao.com"
    password = sys.argv[2] if len(sys.argv) > 2 else "think4good*"

    result = login(email, password)
    if result:
        cookies, opener, cj = result
        print("\n쿠키 목록:")
        for k, v in cookies.items():
            print(f"  {k}: {v[:30]}...")
