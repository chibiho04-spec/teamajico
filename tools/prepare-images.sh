#!/bin/bash
# 素材/ と logo/ から assets/img/ を作り直す。何度実行しても同じ結果。
# 使い方: bash tools/prepare-images.sh
set -eu
cd "$(dirname "$0")/.."

SRC="素材/サイトから抽出"
OUT="assets/img"
SPRITE="$SRC/トップ/sprite-s4c4489049a.png"

mkdir -p "$OUT/logo" "$OUT/hero" "$OUT/parts" "$OUT/profile" "$OUT/works/thumb" "$OUT/works/large"

# --- ロゴ（.ai → 透過PNG）---
if [ ! -f "$OUT/logo/logo.png" ]; then
  swift tools/render-logo.swift "logo/ajico_logo赤水色.ai" "$OUT/logo/logo.png" 1200
fi
sips -Z 180 "$OUT/logo/logo.png" --out "$OUT/logo/apple-touch-icon.png" >/dev/null
sips -Z 64  "$OUT/logo/logo.png" --out "$OUT/logo/favicon.png" >/dev/null

# --- スプライト切り出し（x は常に 0）---
# 名前 y 幅 高さ
crop() {
  local name=$1 y=$2 w=$3 h=$4
  # sips の -c は中央基準なので、--cropOffset で左上を指定する（順序: cropOffset → cropToHeightWidth）
  sips --cropOffset "$y" 0 -c "$h" "$w" "$SPRITE" --out "$OUT/parts/$name.png" >/dev/null
}
crop frame-asami     0    140 235
crop frame-chie      235  150 240
crop lace-asami      475  170 167
crop flower-chie     642  170 167
crop rainbow-girl    809  140 190
crop butterfly-bird  999  128 196
crop book            1195 152 113
crop phone           1308 140 99
crop badge-contact   1407 136 153
crop badge-works     1560 136 153
crop ribbon-chie     1809 170 68
crop ribbon-asami    1877 170 68
crop triangles       1945 98  146
crop stars           2213 130 143
cp "$SRC/パーツ/vamos.jpg" "$OUT/parts/vamos.jpg"

# --- 部屋の絵 ---
sips -s format jpeg -s formatOptions 80 -Z 2000 "$SRC/トップ/mv-01.jpg" --out "$OUT/hero/room.jpg" >/dev/null
# スマホ用：中央 x=640..1760（幅1120）を全高で切り、幅1000に
sips --cropOffset 0 640 -c 808 1120 "$SRC/トップ/mv-01.jpg" --out "$OUT/hero/room-sp.jpg" >/dev/null
sips -s format jpeg -s formatOptions 80 -Z 1000 "$OUT/hero/room-sp.jpg" --out "$OUT/hero/room-sp.jpg" >/dev/null

# --- WORKS（一覧 600 / 拡大 1600）---
longest() { sips -g pixelWidth -g pixelHeight "$1" | awk '/pixel/{if($2>m)m=$2}END{print m}'; }
for f in "$SRC/works/"*.jpg; do
  b=$(basename "$f")
  L=$(longest "$f")
  # sips -Z は小さい画像を拡大してしまうので、元が小さいときは拡大しない
  if [ "$L" -gt 600 ]; then
    sips -s format jpeg -s formatOptions 82 -Z 600 "$f" --out "$OUT/works/thumb/$b" >/dev/null
  else
    sips -s format jpeg -s formatOptions 82 "$f" --out "$OUT/works/thumb/$b" >/dev/null
  fi
  if [ "$L" -gt 1600 ]; then
    sips -s format jpeg -s formatOptions 85 -Z 1600 "$f" --out "$OUT/works/large/$b" >/dev/null
  else
    sips -s format jpeg -s formatOptions 85 "$f" --out "$OUT/works/large/$b" >/dev/null
  fi
done

# --- プロフィールの現場写真（そのまま）---
cp "$SRC/プロフィール/"*.jpg "$OUT/profile/"

echo "parts: $(ls "$OUT/parts" | wc -l | tr -d ' ')  works thumb: $(ls "$OUT/works/thumb" | wc -l | tr -d ' ')  profile: $(ls "$OUT/profile" | wc -l | tr -d ' ')"
