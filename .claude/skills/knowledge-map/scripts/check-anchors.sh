#!/usr/bin/env bash
# L3 (skill self-check): verify every anchor in examples/lucene/.meta/anchors.json
# resolves via codegraph. Requires codegraph + the lucene .codegraph index.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE="$SKILL_DIR/examples/lucene"
ANCHORS="$EXAMPLE/.meta/anchors.json"
PROJECT_PATH="${LUCENE_PROJECT_PATH:-D:/project/lucene-main/lucene-main/lucene}"

if [[ ! -f "$ANCHORS" ]]; then
  echo "⚠️  L3: $ANCHORS not found — build the lucene example first (Task 14)"
  exit 0
fi

if ! command -v codegraph &>/dev/null; then
  echo "⚠️  L3: codegraph CLI not found — skipping (run locally where codegraph is installed)"
  exit 0
fi

FAIL=0; RESOLVED=0; MISSING=0
SYMBOLS=$(grep -oE '"symbol"[[:space:]]*:[[:space:]]*"[^"]+"' "$ANCHORS" \
  | sed -E 's/.*"symbol"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' | sort -u)

for sym in $SYMBOLS; do
  if codegraph explore "$sym" --path "$PROJECT_PATH" >/dev/null 2>&1; then
    RESOLVED=$((RESOLVED+1))
  else
    echo "❌ L3: example anchor not resolved: $sym"
    echo "   修复: 重建 lucene codegraph 索引，或更新 examples/lucene/.meta/anchors.json"
    MISSING=$((MISSING+1)); FAIL=$((FAIL+1))
  fi
done

echo "L3 summary: $RESOLVED resolved, $MISSING missing (of unique symbols)"
if [[ "$FAIL" -gt 0 ]]; then echo "🛑 L3: $FAIL failures"; exit 1; fi
echo "✅ L3: all example anchors resolved"
exit 0
