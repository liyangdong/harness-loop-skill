#!/usr/bin/env bash
# L2: deterministic render+diff against examples/lucene/.
# Re-renders the example KB from its committed .meta/fragments/ via render-kb.sh,
# then diffs vs the committed rendered output. Same fragments + same templates → identical bytes.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE="$SKILL_DIR/examples/lucene"
FRAG="$EXAMPLE/.meta/fragments"

FAIL=0

if [[ ! -f "$FRAG/manifest.tsv" ]]; then
  echo "⚠️  L2: examples/lucene/.meta/fragments/manifest.tsv not found — build the example first (Tasks 13-15)"
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "▶ L2: re-rendering lucene example from committed fragments into $tmp"
if ! bash "$SKILL_DIR/scripts/render-kb.sh" "$FRAG" "$tmp" "$SKILL_DIR/templates"; then
  echo "❌ L2: render-kb.sh failed"
  FAIL=$((FAIL+1))
else
  for f in KNOWLEDGE.md drift.md; do
    if ! diff -q "$EXAMPLE/$f" "$tmp/$f" >/dev/null 2>&1; then
      echo "❌ L2: $f differs from snapshot:"
      diff "$EXAMPLE/$f" "$tmp/$f" | head -40
      FAIL=$((FAIL+1))
    else
      echo "✅ L2: $f matches snapshot"
    fi
  done
  for ex_domain in "$EXAMPLE"/domains/*.md; do
    [[ -e "$ex_domain" ]] || continue
    name=$(basename "$ex_domain")
    if ! diff -q "$ex_domain" "$tmp/domains/$name" >/dev/null 2>&1; then
      echo "❌ L2: domains/$name differs from snapshot:"
      diff "$ex_domain" "$tmp/domains/$name" | head -40
      FAIL=$((FAIL+1))
    else
      echo "✅ L2: domains/$name matches snapshot"
    fi
  done
fi

if [[ "$FAIL" -gt 0 ]]; then echo "🛑 L2: $FAIL failures"; exit 1; fi
echo "✅ L2: example renders cleanly from fragments"
exit 0
