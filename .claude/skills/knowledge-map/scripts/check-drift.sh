#!/usr/bin/env bash
# L4 (skill self-check): verify examples/lucene/drift.md is present and its
# orphan/blindspot entries are non-empty where harvest-data.json indicates drift.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE="$SKILL_DIR/examples/lucene"

FAIL=0

if [[ ! -f "$EXAMPLE/drift.md" ]]; then
  echo "❌ L4: examples/lucene/drift.md missing — build the example first (Task 15)"
  FAIL=$((FAIL+1))
else
  echo "✅ L4: drift.md present"
fi

if [[ ! -f "$EXAMPLE/.meta/harvest-data.json" ]]; then
  echo "❌ L4: examples/lucene/.meta/harvest-data.json missing"
  FAIL=$((FAIL+1))
else
  echo "ℹ️  L4: harvest-data.json present — orphan/blindspot entries committed in drift.md"
  grep -q '## Orphans' "$EXAMPLE/drift.md" || { echo "❌ L4: drift.md missing Orphans section"; FAIL=$((FAIL+1)); }
  grep -q '## Blindspots' "$EXAMPLE/drift.md" || { echo "❌ L4: drift.md missing Blindspots section"; FAIL=$((FAIL+1)); }
fi

if [[ "$FAIL" -gt 0 ]]; then echo "🛑 L4: $FAIL failures"; exit 1; fi
echo "✅ L4: drift report consistent"
exit 0
