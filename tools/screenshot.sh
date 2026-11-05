#!/bin/bash
# 1ページを5パターンでスクショする（スマホ390/PC1280 × 文字100%/150%、＋320px）
# 使い方: bash tools/screenshot.sh <htmlの相対パス> <名前>   例: bash tools/screenshot.sh works/index.html works
#   第3引数に "#asami" のようなハッシュを付けると、その位置で撮る
# 注意: headless Chrome は窓幅を500px未満にできないため、500未満は iframe に入れて撮ってから切り抜く。
set -eu
cd "$(dirname "$0")/.."
HTML=$1; NAME=$2; HASH=${3:-}; FIXH=${4:-}   # 第4引数: 全パターンの高さを固定（拡大表示など画面いっぱいの確認用）
OUT=docs/screenshots
mkdir -p "$OUT"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
URL="file://$(pwd)/$HTML"
UA_SP="Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

shot() { # 幅 高さ クエリ 出力名
  local w=$1 h=$2 q=$3 out=$4
  if [ "$w" -ge 500 ]; then
    "$CHROME" --headless=new --disable-gpu --hide-scrollbars --window-size="$w,$h" \
      --virtual-time-budget=5000 --screenshot="$OUT/$out.png" "$URL$q$HASH" >/dev/null 2>&1
  else
    local host="$OUT/_host-$out.html"
    # iframe を中央に置き、sips の中央切り抜き（-c）でちょうど iframe だけが残るようにする
    printf '<!DOCTYPE html><html><body style="margin:0;background:#888"><iframe src="%s" width="%s" height="%s" style="border:0;display:block;margin:0 auto"></iframe></body></html>' \
      "$URL$q$HASH" "$w" "$h" > "$host"
    "$CHROME" --headless=new --disable-gpu --hide-scrollbars --window-size="600,$h" \
      --user-agent="$UA_SP" --virtual-time-budget=5000 --screenshot="$OUT/$out.png" "file://$(pwd)/$host" >/dev/null 2>&1
    sips -c "$h" "$w" "$OUT/$out.png" --out "$OUT/$out.png" >/dev/null
    rm -f "$host"
  fi
}
shot 390  ${FIXH:-3600} ""        "$NAME-sp-100"
shot 390  ${FIXH:-4200} "?fs=150" "$NAME-sp-150"
shot 1280 ${FIXH:-2800} ""        "$NAME-pc-100"
shot 1280 ${FIXH:-3200} "?fs=150" "$NAME-pc-150"
shot 320  ${FIXH:-3600} ""        "$NAME-320"
ls -1 "$OUT" | grep "^$NAME-" | sed "s|^|$OUT/|"
