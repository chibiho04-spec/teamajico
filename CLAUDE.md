# Team ajico 公式サイト（作り直し）

沖縄のヘアメイク・スタイリストチーム Team ajico のサイト。静的HTML 4ページ（TOP / PROFILE / WORKS / CONTACT）。
設計書：`docs/specs/2026-11-05-新サイト設計.md`　実装計画：`docs/plans/2026-11-05-新サイト実装計画.md`

## 絶対ルール
- **リンク・画像パスは相対パスのみ**（`../assets/...`）。`/` 始まりは禁止。ページへのリンクは `profile/index.html` のように **index.html まで書く**（file:// 直開きではフォルダ名だけだと一覧表示になってしまうため）。
- 連絡先は **電話（2人の携帯）と Instagram DM の2つ**（Shin決定・本人の掲載了承済み 2026-11-05）。メールアドレスは載せない。電話番号を変えるときは `contact/index.html` の `tel:` と表示の両方を直す。
- 公開先は GitHub `chibiho04-spec/teamajico`（GitHub Pages、main ブランチ直下）。修正したら commit → push で即公開（sat系と同じ運用）。仮公開URL: https://chibiho04-spec.github.io/teamajico/ 。ドメイン切替後は og:image を https://team-ajico.net/... に直す。
- `logo/`・`素材/`・`現サイト調査/` はコミットしない（.ai が345MBあり GitHub の上限を超える。元データは手元に残す）。
- 外部に頼るのは Google Fonts と Instagram の埋め込み（`instagram.com/<user>/embed/`）だけ。ライブラリ（jQuery等）禁止。

## 安全管理（Shin は運用の初心者。Claude が気をつける）
- **push の前に必ず** `python3 tools/site-check.py --local`。NG があれば push しない。作業の区切りでは `python3 tools/site-check.py` で公開サイトとDNSも見る。
- **このリポジトリは Public。** パスワード・鍵・サーバーの弱点・契約情報・個人のメールアドレスを、コード・コメント・docs・コミット文のどこにも書かない。`STATUS.md` と `期限メモ.txt` は手元だけ（.gitignore 済み）。
- `_config.yml` の `exclude` で内部資料を公開ページから外している。ただし github.com では読めるので、秘密を置いてよい場所にはならない。
- ログイン情報はチャットに貼らせない。アカウント作成・パスワード入力・DNSや契約の変更は Shin が行い、Claude は手順と確認を担当する。
- 写真を足すときは撮影場所の情報が残っていないか確認する（site-check が検出する）。
- **DNS の変更は、変更前の全レコードを控えてから。** MX・SPF・DMARC を消すとメールが止まる。

## ドメイン切替チェックリスト（未実施）
1. サイトとメールのバックアップ、DNS の全レコードの控えを取る。
2. GitHub のアカウント設定でドメインを検証する（他人に使われるのを防ぐ）。検証用の TXT は消さない。
3. DNS を編集できる場所を確認する。置き場を移すときは MX・SPF・DMARC を移し先へ入れ直し、送受信を試す。ワイルドカードは GitHub に向けない。
4. サイトの向き先を GitHub Pages へ変え、`CNAME` を追加し、「Enforce HTTPS」をオンにする。
5. `og:image` と `tools/site-check.py` の `BASE` を team-ajico.net に直し、`robots.txt` と `sitemap.xml` を追加する。
6. 表示と送受信を確認してから、古い WordPress を停止する。メールの契約は残す。

## 画像
- 元データ → `素材/`。サイトに載せるのは `assets/img/` の縮小版だけ。
- 作り直すときは `bash tools/prepare-images.sh`（何度実行しても同じ結果）。

## 確認手順（「できました」の前に必ず）
- `bash tools/screenshot.sh <html> <名前>` → `docs/screenshots/` に スマホ390px・PC1280px × 文字100%/150% と 320px の5枚。全部見て崩れ・横スクロールがないこと。
- `bash tools/check-links.sh` → `0 missing`。
- 文字サイズ150%は URL に `?fs=150` を付けると再現できる（`main.js` の検証用フック）。

## 公開前チェックリスト（未達）
- [x] 連絡先（電話2人分・Instagram）が本物で、本人の掲載了承がある（2026-11-05）
- [x] 部屋のイラスト・写真の使用許可（制作者・撮影者）（2026-11-05 Shin確認）
- [x] 4パターン確認・リンク確認を通している（2026-11-05）
- [x] `og:image` を公開URL（仮公開の github.io。ドメイン切替時に team-ajico.net へ）
- [x] コミット作者のメールアドレスは GitHub の匿名アドレス（chibiho04-spec@users.noreply.github.com）に書き換え済み。このリポジトリの git 設定も同じアドレスにしてある（2026-11-05）
