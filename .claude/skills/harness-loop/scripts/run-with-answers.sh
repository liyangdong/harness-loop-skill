#!/usr/bin/env bash
# Non-interactive renderer: reads an answers.json, applies the wizard's
# decision-tree logic, renders templates with substitutions, writes a
# complete project layout to <output_dir>.
#
# Thin wrapper around run-with-answers.py. Bash entry point keeps invocation
# consistent with the other scripts/check-*.sh entry points; the actual
# rendering logic lives in Python (see run-with-answers.py for the
# language-choice rationale).
#
# Usage:
#   scripts/run-with-answers.sh <answers.json> <output_dir>
#
# Exit codes:
#   0 = success
#   1 = rendering error
#   2 = usage error

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Pick a working Python 3 interpreter. We try candidates in order and verify
# each one actually runs (the Microsoft Store 'python3' stub on Windows is
# broken until installed via the Store; `command -v` reports it exists but
# invoking it exits non-zero without printing anything).
pick_python() {
  local candidate
  for candidate in python3 python py; do
    command -v "$candidate" &>/dev/null || continue
    if "$candidate" -c 'import sys; sys.exit(0 if sys.version_info >= (3,6) else 1)' 2>/dev/null; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

PY="$(pick_python)" || {
  echo "❌ run-with-answers: no working python3 interpreter found in PATH" >&2
  echo "   Tried: python3, python, py. The runner requires Python 3.6+" >&2
  echo "   (Python is already a soft dep via the L3 YAML validation check.)" >&2
  exit 1
}

exec "$PY" "$SCRIPT_DIR/run-with-answers.py" "$@"
