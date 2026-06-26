#!/usr/bin/env bash
# L3: Bootstrap self-check — generated project must run its own checks.
#
# Most rigorous validation: generates a project from the java-tdd example,
# then exercises the generated project's own check scripts, git hook, CI
# workflow, and AGENTS.md markdown shape. Catches breakages that static
# template inspection (L1) and snapshot diffs (L2) cannot.
#
# Depends on scripts/run-with-answers.sh (a non-interactive runner) which is
# NOT implemented in v1. Per spec §9 the runner is a planned future extension;
# until then this script runs in warning-only state: prints a notice and
# exits 0 so it can sit in CI without blocking, while signaling that L3
# coverage is not yet automated.
#
# Exit codes: 0 = all sub-checks passed (or warning-only state); 1 = ≥1 failure.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

FAIL=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "▶ L3: generating java-tdd project in $tmp"

# ---------------------------------------------------------------------------
# Gate: non-interactive runner must exist for full L3 automation.
#   v1 ships without it; warn and exit 0 so CI does not break.
# ---------------------------------------------------------------------------
if [[ ! -f scripts/run-with-answers.sh ]]; then
  echo "⚠️  L3: scripts/run-with-answers.sh not implemented, skipping"
  echo "   L3 check is in warning-only state for v1."
  exit 0
fi

if ! bash scripts/run-with-answers.sh examples/java-tdd/answers.json "$tmp"; then
  echo "❌ L3: generation failed"
  exit 1
fi

cd "$tmp"

# Sub-check 1: generated check-tests.sh exists and is valid bash
if [[ ! -f scripts/check-tests.sh ]]; then
  echo "❌ L3: scripts/check-tests.sh not generated"
  FAIL=$((FAIL+1))
else
  if ! bash -n scripts/check-tests.sh; then
    echo "❌ L3: generated check-tests.sh has syntax error"
    FAIL=$((FAIL+1))
  fi
fi

# Sub-check 2: generated check-consistency.sh runs (may report findings, but should run)
if [[ -f scripts/check-consistency.sh ]]; then
  bash check-consistency.sh || {
    # Non-zero exit means checks found issues, which is OK for a fresh project
    # UNLESS the script itself crashed. Differentiate:
    exit_code=$?
    if [[ $exit_code -eq 1 ]]; then
      echo "ℹ️  L3: check-consistency.sh reported violations on fresh project (expected if README has unfilled placeholders)"
    else
      echo "❌ L3: check-consistency.sh crashed with exit $exit_code"
      FAIL=$((FAIL+1))
    fi
  }
fi

# Sub-check 3: pre-commit hook is valid bash
if [[ ! -f .githooks/pre-commit ]]; then
  echo "❌ L3: .githooks/pre-commit not generated"
  FAIL=$((FAIL+1))
else
  if ! bash -n .githooks/pre-commit; then
    echo "❌ L3: pre-commit has syntax error"
    FAIL=$((FAIL+1))
  fi
fi

# Sub-check 4: CI workflow is valid YAML
if [[ -f .github/workflows/consistency.yml ]]; then
  if command -v python &>/dev/null; then
    if ! python -c "import yaml; yaml.safe_load(open('.github/workflows/consistency.yml'))" 2>/dev/null; then
      echo "❌ L3: consistency.yml is invalid YAML"
      FAIL=$((FAIL+1))
    fi
  fi
fi

# Sub-check 5: AGENTS.md is valid markdown (basic check: starts with H1)
if ! head -1 AGENTS.md | grep -qE '^# '; then
  echo "❌ L3: AGENTS.md doesn't start with a H1 title"
  FAIL=$((FAIL+1))
fi

if [[ "$FAIL" -gt 0 ]]; then
  echo "🛑 L3: $FAIL failures"
  exit 1
fi

echo "✅ L3: bootstrap self-check passed"
exit 0
