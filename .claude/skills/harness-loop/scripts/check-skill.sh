#!/usr/bin/env bash
# L1: Static checks for the harness-loop skill itself.
# Verifies frontmatter, template path consistency, line counts.
#
# This is the skill's self-test. It does NOT substitute placeholders or run
# rendered scripts (that is L2/L3). It only checks that the skill's own files
# are structurally sound: frontmatter well-formed, every path the decision tree
# references actually exists, every .tmpl file uses at least one placeholder,
# and every subdir AGENTS.md stays under the 100-line progressive-disclosure
# limit (per templates/AGENTS.md §3 "every AGENTS.md ≤ 100 lines").
#
# Exit codes: 0 = all hard checks passed (warnings permitted); 1 = ≥1 failure.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

FAIL=0

# ---------------------------------------------------------------------------
# S1: SKILL.md frontmatter
#   The skill entry must start with `---` and declare `name: harness-loop` and
#   a non-empty `description:`. Without these the skill loader will skip it.
# ---------------------------------------------------------------------------
if ! head -3 SKILL.md | grep -q '^---$'; then
  echo "❌ S1: SKILL.md missing frontmatter opening ---"
  FAIL=$((FAIL+1))
fi
if ! head -10 SKILL.md | grep -q '^name: harness-loop$'; then
  echo "❌ S1: SKILL.md missing 'name: harness-loop'"
  FAIL=$((FAIL+1))
fi
if ! head -10 SKILL.md | grep -qE '^description: .+$'; then
  echo "❌ S1: SKILL.md missing description"
  FAIL=$((FAIL+1))
fi

# ---------------------------------------------------------------------------
# S2: decision-tree references → file existence
#   Every concrete `templates/...` path mentioned in wizard/decision-tree.md
#   must resolve to a real file or directory in the skill. Dangling references
#   mean the wizard will instruct the agent to read a file that does not exist.
#
#   We only match paths that look like real references — i.e., ending in a
#   known template/source extension OR a trailing slash (directory). This
#   excludes prose shorthand like `templates/...` or `templates/checks/check-`
#   which are not file references.
# ---------------------------------------------------------------------------
DEC_TREE="wizard/decision-tree.md"
if [[ ! -f "$DEC_TREE" ]]; then
  echo "❌ S2: $DEC_TREE not found"
  FAIL=$((FAIL+1))
else
  while IFS= read -r path; do
    # Skip the literal ellipsis / placeholder forms that prose uses.
    case "$path" in
      *...|*01-06|*tests-|*/check-) continue ;;
    esac
    if [[ ! -e "$path" ]]; then
      echo "❌ S2: decision-tree references missing path: $path"
      FAIL=$((FAIL+1))
    fi
  done < <(
    grep -oE 'templates/[A-Za-z0-9_/.-]+' "$DEC_TREE" \
      | sed 's/`//g' \
      | sed 's/|$//' \
      | sed 's/^|//' \
      | tr -d ' ' \
      | sort -u
  )
fi

# ---------------------------------------------------------------------------
# S3: every .tmpl file uses {{...}} placeholders
#   A .tmpl file with no placeholder is either (a) a bug — someone wrote a
#   static file and gave it the wrong extension — or (b) intentional (the file
#   is rendered verbatim but kept under templates/ because it is part of the
#   substitution pipeline). We emit a WARNING, not a failure, and let the
#   author decide.
# ---------------------------------------------------------------------------
TMPL_COUNT=0
PLACEHOLDER_FAIL=0
while IFS= read -r f; do
  TMPL_COUNT=$((TMPL_COUNT+1))
  if ! grep -qE '\{\{[A-Z_]+\}\}' "$f"; then
    echo "⚠️  S3: $f has no {{PLACEHOLDER}} — should it be a plain file?"
    PLACEHOLDER_FAIL=$((PLACEHOLDER_FAIL+1))
  fi
done < <(find templates -name '*.tmpl' -type f)

# ---------------------------------------------------------------------------
# S4: subdir AGENTS.md ≤ 100 lines
#   Per templates/AGENTS.md §3, every subdir AGENTS.md must stay ≤ 100 lines
#   (progressive disclosure: long files belong in dedicated concept/methodology
#   blocks, not in the navigation index). The root SKILL.md and root AGENTS.md
#   are excluded — they are the top-level entry, not subdir navigation.
#
#   examples/ is excluded because example projects are dogfood outputs, not
#   authoritative AGENTS.md that agents will follow in real use.
# ---------------------------------------------------------------------------
LONG_AGENTS=0
while IFS= read -r f; do
  lines=$(wc -l < "$f")
  if [[ "$lines" -gt 100 ]]; then
    echo "❌ S4: $f is $lines lines (max 100)"
    LONG_AGENTS=$((LONG_AGENTS+1))
    FAIL=$((FAIL+1))
  fi
done < <(find . -name AGENTS.md -not -path './examples/*')

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "L1 Summary: $TMPL_COUNT templates, $PLACEHOLDER_FAIL placeholder warnings, $LONG_AGENTS oversized AGENTS.md"

if [[ "$FAIL" -gt 0 ]]; then
  echo "🛑 L1: $FAIL failures"
  exit 1
fi

echo "✅ L1: all static checks passed"
exit 0
