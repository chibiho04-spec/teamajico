#!/bin/bash
# 全HTMLの href / src（相対パス）が実在するか確認する。"/" 始まりは NG。
# 使い方: bash tools/check-links.sh   → 最後に "OK: N links, 0 missing"
set -u
cd "$(dirname "$0")/.."
total=0; missing=0; absolute=0
for html in $(find . -name "*.html" -not -path "./docs/*" -not -path "./tools/*" -not -path "./.superpowers/*" -not -path "./現サイト調査/*"); do
  dir=$(dirname "$html")
  for ref in $(grep -oE '(href|src)="[^"]+"' "$html" | sed -E 's/^(href|src)="//; s/"$//'); do
    case "$ref" in
      http*|mailto:*|tel:*|\#*|data:*) continue ;;
    esac
    total=$((total+1))
    case "$ref" in
      /*) echo "NG（/ 始まり）: $html → $ref"; absolute=$((absolute+1)); continue ;;
    esac
    path="${ref%%\#*}"; path="${path%%\?*}"
    [ -z "$path" ] && continue
    target="$dir/$path"
    if [ -d "$target" ]; then target="$target/index.html"; fi
    if [ ! -f "$target" ]; then echo "MISSING: $html → $ref"; missing=$((missing+1)); fi
  done
done
echo "OK: $total links, $missing missing, $absolute absolute"
[ "$missing" -eq 0 ] && [ "$absolute" -eq 0 ]
