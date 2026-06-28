#!/usr/bin/env bash
# L1: Static checks for the knowledge-map skill itself.
# Verifies SKILL.md frontmatter, template placeholder consistency, line counts, subdir AGENTS.md.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

FAIL=0

# S1: SKILL.md frontmatter
if ! head -1 SKILL.md | grep -q '^---$'; then
  echo "❌ S1: SKILL.md missing frontmatter opening ---"; FAIL=$((FAIL+1))
fi
if ! head -10 SKILL.md | grep -q '^name: knowledge-map$'; then
  echo "❌ S1: SKILL.md missing 'name: knowledge-map'"; FAIL=$((FAIL+1))
fi
if ! head -10 SKILL.md | grep -qE '^description: .+$'; then
  echo "❌ S1: SKILL.md missing description"; FAIL=$((FAIL+1))
fi
echo "✅ S1: SKILL.md frontmatter valid"

# S2: SKILL.md ≤ 100 lines
LINES=$(wc -l < SKILL.md)
if [[ "$LINES" -gt 100 ]]; then
  echo "❌ S2: SKILL.md is $LINES lines (max 100)"; FAIL=$((FAIL+1))
else
  echo "✅ S2: SKILL.md is $LINES lines"
fi

# S3: every .tmpl uses at least one {{PLACEHOLDER}} (except meta reference shells)
while IFS= read -r f; do
  base=$(basename "$f")
  [[ "$base" == meta-*.tmpl ]] && continue
  if ! grep -qE '\{\{[A-Z_]+\}\}' "$f"; then
    echo "⚠️  S3: $f has no {{PLACEHOLDER}} — should it be a plain file?"
  fi
done < <(find templates -name '*.tmpl' -type f)
echo "✅ S3: template placeholder scan complete"

# S4: subdir AGENTS.md ≤ 100 lines (excluding examples/)
LONG=0
while IFS= read -r f; do
  l=$(wc -l < "$f")
  if [[ "$l" -gt 100 ]]; then
    echo "❌ S4: $f is $l lines (max 100)"; LONG=$((LONG+1)); FAIL=$((FAIL+1))
  fi
done < <(find . -name AGENTS.md -not -path './examples/*')
echo "✅ S4: AGENTS.md line counts checked"

# S5: render-kb.sh + check-*.sh exist and parse as valid bash
for s in scripts/render-kb.sh scripts/check-skill.sh scripts/check-examples.sh scripts/check-anchors.sh scripts/check-drift.sh; do
  if [[ ! -f "$s" ]]; then
    echo "❌ S5: missing $s"; FAIL=$((FAIL+1))
  elif ! bash -n "$s" 2>/dev/null; then
    echo "❌ S5: $s has bash syntax error"; FAIL=$((FAIL+1))
  fi
done
echo "✅ S5: skill scripts present and parse"

# S6: in-target check templates parse as valid bash after {{STRICT_MODE}} substitution
for t in templates/checks/check-knowledge.sh.tmpl templates/checks/check-anchors.sh.tmpl templates/checks/check-drift.sh.tmpl; do
  [[ -f "$t" ]] || { echo "⚠️  S6: $t not yet present"; continue; }
  if ! sed 's/{{STRICT_MODE}}/advisory/g' "$t" | bash -n 2>/dev/null; then
    echo "❌ S6: $t does not parse as bash after substitution"; FAIL=$((FAIL+1))
  fi
done
echo "✅ S6: in-target check templates parse"

if [[ "$FAIL" -gt 0 ]]; then
  echo "🛑 L1: $FAIL failures"; exit 1
fi
echo "✅ L1: all static checks passed"
exit 0
