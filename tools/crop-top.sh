#!/bin/bash
# スクショの上部だけを切り出して確認用に保存する
# 使い方: bash tools/crop-top.sh docs/screenshots/top-sp-100.png 400  → docs/screenshots/_crop-top-sp-100.png
# （sips の --cropOffset は 0 を「未指定＝中央」と扱うので、縦は 1px ずらして上端から切る）
set -eu
IN=$1; H=${2:-400}
W=$(sips -g pixelWidth "$IN" | awk '/pixelWidth/{print $2}')
OUT="$(dirname "$IN")/_crop-$(basename "$IN")"
sips --cropOffset 1 0 -c "$H" "$W" "$IN" --out "$OUT" >/dev/null
echo "$OUT"
