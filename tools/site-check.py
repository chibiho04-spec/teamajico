#!/usr/bin/env python3
"""Team ajico サイトの安全点検（読み取りのみ。何も変更しない）。

使い方:
  python3 tools/site-check.py          手元のファイル＋公開サイト＋DNSを点検
  python3 tools/site-check.py --local  手元のファイルだけ点検（push 前）

NG があると終了コード 1。注意は 0 のまま表示だけ。
期限は .gitignore 済みの「期限メモ.txt」（1行に「YYYY-MM-DD 内容」）から読む。
"""
import datetime as dt
import glob
import os
import re
import socket
import ssl
import struct
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = "https://chibiho04-spec.github.io/teamajico/"  # ドメイン切替後は https://team-ajico.net/ に変える
DOMAIN = "team-ajico.net"
PAGES = ["", "profile/index.html", "works/index.html", "contact/index.html",
         "hair-make-chie/index.html", "stylist-asami/index.html"]
INTERNAL = ["CLAUDE.md", "CLAUDE.html", "STATUS.md", "tools/ogp.html", "tools/screenshot.sh",
            "docs/specs/2026-11-05-新サイト設計.md", "docs/plans/2026-11-05-新サイト実装計画.md"]
SECRET = (r"ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}"
          r"|BEGIN [A-Z ]*PRIVATE KEY|(password|passwd|api[_-]?key|secret)[\"' ]*[:=][\"' ]*[^\s\"']{6,}")
FORBIDDEN = ("logo/", "素材/", "現サイト調査/", "docs/screenshots/", ".superpowers/", "STATUS.md", "期限メモ.txt", "team-ajico/")

ng = warn = 0


def report(level, message):
    global ng, warn
    ng += level == "NG"
    warn += level == "注意"
    print(f"[{level}] {message}")


def run(*args):
    return subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=60).stdout


def tracked():
    return [f for f in run("git", "-c", "core.quotePath=false", "ls-files").splitlines()]


def html_files():
    return [p + "index.html" if p == "" else p for p in PAGES]


def has_gps(path):
    """JPEG の Exif に位置情報(GPS)の項目があるか。"""
    with open(path, "rb") as fh:
        d = fh.read()
    i = 2
    while d[:2] == b"\xff\xd8" and i + 4 < len(d) and d[i] == 0xFF:
        marker, size = d[i + 1], struct.unpack(">H", d[i + 2:i + 4])[0]
        if marker == 0xDA:
            return False
        if marker == 0xE1 and d[i + 4:i + 10] == b"Exif\0\0":
            t = d[i + 10:i + 2 + size]
            order = "<" if t[:2] == b"II" else ">"
            off = struct.unpack(order + "I", t[4:8])[0]
            count = struct.unpack(order + "H", t[off:off + 2])[0]
            tags = [struct.unpack(order + "H", t[off + 2 + 12 * k:off + 4 + 12 * k])[0] for k in range(count)]
            return 0x8825 in tags
        i += 2 + size
    return False


def check_local():
    print("--- 手元のファイル ---")
    files = tracked()

    bad = [f for f in files if f.startswith(FORBIDDEN)]
    report("NG" if bad else "OK", f"公開してはいけないファイルが GitHub に入っていない {bad[:5] if bad else ''}")

    hits = run("git", "grep", "-nIE", SECRET, "--", ".", ":!tools/site-check.py").strip()
    report("NG" if hits else "OK", "パスワードや鍵らしき文字列がない" + (":\n" + hits[:500] if hits else ""))

    mails = run("git", "grep", "-nIE", r"[A-Za-z0-9._%+-]+@(gmail|icloud|yahoo)\.[a-z.]+", "--").strip()
    report("NG" if mails else "OK", "個人のメールアドレスがない" + (":\n" + mails[:300] if mails else ""))

    author = run("git", "config", "user.email").strip()
    report("OK" if author.endswith("@users.noreply.github.com") else "NG", "コミットの作者が匿名アドレスになっている")

    plain, no_alt, noindex, no_noopener, targets = [], [], [], [], []
    for rel in html_files():
        with open(os.path.join(ROOT, rel), encoding="utf-8") as fh:
            s = fh.read()
        if re.search(r'(src|href)="http://', s):
            plain.append(rel)
        no_alt += [rel for tag in re.findall(r"<img\b[^>]*>", s) if not re.search(r"\balt=", tag)]
        if "noindex" in s:
            noindex.append(rel)
        no_noopener += [rel for tag in re.findall(r'<a\b[^>]*target="_blank"[^>]*>', s) if "noopener" not in tag]
        targets += re.findall(r'href="([^"]+)"', s)
    with open(os.path.join(ROOT, "assets/css/style.css"), encoding="utf-8") as fh:
        if "http://" in fh.read():
            plain.append("style.css")
    report("NG" if plain else "OK", f"暗号化なし(http)の読み込みがない {plain or ''}")
    report("NG" if no_alt else "OK", f"すべての画像に alt がある {sorted(set(no_alt)) or ''}")
    report("NG" if noindex else "OK", f"検索よけ(noindex)が残っていない {noindex or ''}")
    report("NG" if no_noopener else "OK", f"外部リンクに noopener がある {sorted(set(no_noopener)) or ''}")

    gps = [f for f in glob.glob(os.path.join(ROOT, "assets/img/**/*.jp*g"), recursive=True) if has_gps(f)]
    report("NG" if gps else "OK", f"写真に撮影場所の情報がない {[os.path.basename(g) for g in gps[:5]] or ''}")

    link = subprocess.run(["bash", "tools/check-links.sh"], cwd=ROOT, capture_output=True, text=True)
    last = link.stdout.strip().splitlines()[-1] if link.stdout.strip() else "結果なし"
    report("OK" if link.returncode == 0 else "NG", f"サイト内リンク切れなし（{last}）")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def fetch(url):
    """(状態コード, ヘッダー) を返す。リダイレクトは追わない。"""
    parts = urllib.parse.urlsplit(url)
    url = urllib.parse.urlunsplit(parts._replace(path=urllib.parse.quote(parts.path)))
    req = urllib.request.Request(url, headers={"User-Agent": "teamajico-site-check"})
    opener = urllib.request.build_opener(NoRedirect)
    try:
        with opener.open(req, timeout=20) as res:
            return res.status, res.headers
    except urllib.error.HTTPError as err:
        return err.code, err.headers
    except (urllib.error.URLError, OSError):
        return 0, {}


def dig(name, rtype):
    return [x.strip().strip('"') for x in run("dig", "+short", name, rtype).splitlines() if x.strip()]


def check_public():
    print("--- 公開サイト ---")
    bad = [p or "TOP" for p in PAGES if fetch(BASE + p)[0] != 200]
    report("NG" if bad else "OK", f"全ページが開ける {bad or ''}")

    status, headers = fetch(BASE.replace("https://", "http://"))
    report("OK" if status in (301, 308) and str(headers.get("Location", "")).startswith("https://") else "NG",
           "http で来ても https に転送される")

    exposed = [p for p in INTERNAL if fetch(BASE + p)[0] == 200]
    report("NG" if exposed else "OK", f"内部資料が公開ページに出ていない {exposed or ''}")

    print(f"--- ドメイン {DOMAIN} ---")
    try:
        ctx = ssl.create_default_context()
        with socket.create_connection((DOMAIN, 443), timeout=20) as raw:
            with ctx.wrap_socket(raw, server_hostname=DOMAIN) as tls:
                end = ssl.cert_time_to_seconds(tls.getpeercert()["notAfter"])
        days = int((end - dt.datetime.now().timestamp()) // 86400)
        report("OK" if days >= 14 else "NG", f"https の証明書の残り {days} 日（14日未満で NG）")
    except (OSError, ssl.SSLError) as err:
        report("NG", f"https の証明書を確認できない: {err}")

    powered = fetch(f"https://{DOMAIN}/")[1].get("X-Powered-By", "")
    if powered:
        report("注意", f"本番の表示元はまだプログラムが動くサーバー（{powered}）。新サイト切替と古い WordPress の停止が必要")

    mx = dig(DOMAIN, "MX")
    report("OK" if mx else "NG", f"メールの配送先(MX)がある {mx}")
    spf = [t for t in dig(DOMAIN, "TXT") if t.startswith("v=spf1")]
    report("OK" if len(spf) == 1 else "NG", f"送信元の証明(SPF)がちょうど1件ある（{len(spf)}件）")
    dmarc = [t for t in dig("_dmarc." + DOMAIN, "TXT") if t.startswith("v=DMARC1")]
    report("OK" if len(dmarc) == 1 else "注意", f"なりすまし対策(DMARC)がある（{dmarc[0] if dmarc else 'なし'}）")
    # 実在しないはずの名前が引ければ、すべてのサブドメインを受ける設定がある
    if dig(f"zz-check-{int(dt.datetime.now().timestamp())}.{DOMAIN}", "A"):
        report("注意", "すべてのサブドメインを受ける設定(ワイルドカード)がある。乗っ取りの原因になるので確認する")


def check_deadlines():
    path = os.path.join(ROOT, "期限メモ.txt")
    if not os.path.exists(path):
        return
    print("--- 契約の期限 ---")
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            m = re.match(r"(\d{4}-\d{2}-\d{2})\s+(.+)", line.strip())
            if m:
                left = (dt.date.fromisoformat(m.group(1)) - dt.date.today()).days
                report("NG" if left < 14 else "注意" if left < 45 else "OK", f"{m.group(2)}: 残り {left} 日（{m.group(1)}）")


def main():
    check_local()
    if "--local" not in sys.argv:
        check_public()
        check_deadlines()
    print(f"\n結果: NG {ng} 件 / 注意 {warn} 件")
    return 1 if ng else 0


if __name__ == "__main__":
    sys.exit(main())
