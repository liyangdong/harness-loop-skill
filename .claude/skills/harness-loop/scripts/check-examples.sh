#!/usr/bin/env bash
# L2: End-to-end diff against examples/.
# Re-runs the skill with each example's answer set, diffs output vs snapshot.
#
# Depends on scripts/run-with-answers.sh (a non-interactive runner) which is
# NOT implemented in v1. Per spec §9, the runner is a planned future extension.
# Until then this script runs in warning-only state: it prints a notice and
# exits 0 so it can sit in CI without blocking, while signaling that L2
# coverage is not yet automated.
#
# Volatile / non-regenerated files excluded from the diff:
#   - iteration.md     (timestamp / loop-counter dependent)
#   - entropy-log.md   (non-deterministic ordering)
#   - last-output.txt  (contains run-local timestamps)
#   - *.tmp            (scratch)
#   - answers.json     (the runner's INPUT, not its output; lives only in the
#                       snapshot, never regenerated into the temp dir)
#
# Exit codes: 0 = all examples match (or warning-only state); 1 = ≥1 mismatch.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

FAIL=0

# ---------------------------------------------------------------------------
# Gate: non-interactive runner must exist for full L2 automation.
#   v1 ships without it; warn and exit 0 so CI does not break.
# ---------------------------------------------------------------------------
if [[ ! -f scripts/run-with-answers.sh ]]; then
  echo "⚠️  L2: scripts/run-with-answers.sh not implemented"
  echo "   L2 check is in warning-only state for v1."
  echo "   Full automation requires the runner (planned for future extension per spec §9)."
  echo "   To verify examples manually: invoke the skill with each examples/*/answers.json"
  exit 0
fi

for example in examples/java-tdd examples/java-sdd examples/java-hybrid; do
  if [[ ! -d "$example" ]]; then
    echo "⚠️  L2: $example not yet populated, skipping"
    continue
  fi

  name=$(basename "$example")
  tmp=$(mktemp -d)
  echo "▶ L2: regenerating $name into $tmp"

  # Run skill non-interactively using answer set
  if ! bash scripts/run-with-answers.sh "$example/answers.json" "$tmp"; then
    echo "❌ L2: generation failed for $name"
    FAIL=$((FAIL+1))
    rm -rf "$tmp"
    continue
  fi

  # Diff generated output vs committed snapshot, excluding volatile files.
  diff -r \
    --exclude="iteration.md" \
    --exclude="entropy-log.md" \
    --exclude="last-output.txt" \
    --exclude="*.tmp" \
    --exclude="answers.json" \
    "$example/" "$tmp/" > "/tmp/l2-${name}-diff.txt"

  if [[ $? -ne 0 ]]; then
    echo "❌ L2: $name differs from snapshot:"
    head -50 "/tmp/l2-${name}-diff.txt"
    FAIL=$((FAIL+1))
  else
    echo "✅ L2: $name matches snapshot"
  fi

  rm -rf "$tmp"
done

if [[ "$FAIL" -gt 0 ]]; then
  echo "🛑 L2: $FAIL failures"
  exit 1
fi

echo "✅ L2: all examples match snapshots"
exit 0
