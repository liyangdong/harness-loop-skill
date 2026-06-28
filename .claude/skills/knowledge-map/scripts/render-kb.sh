#!/usr/bin/env bash
# render-kb.sh — deterministic renderer: fragments + templates → knowledge base.
# Usage: render-kb.sh <fragments-dir> <output-dir> [<templates-dir>]
# <fragments-dir> contains manifest.tsv + fragments/* (harvest output).
# <output-dir> receives KNOWLEDGE.md, domains/*.md, drift.md.
# <templates-dir> defaults to this script's ../templates/.

set -uo pipefail
trap 'rm -f "$TMP" "$TMP.2"' EXIT

FRAG_DIR="${1:?usage: render-kb.sh <fragments-dir> <output-dir> [templates-dir]}"
OUT_DIR="${2:?usage: render-kb.sh <fragments-dir> <output-dir> [templates-dir]}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPL_DIR="${3:-$SCRIPT_DIR/../templates}"
MANIFEST="$FRAG_DIR/manifest.tsv"

if [[ ! -f "$MANIFEST" ]]; then
  echo "❌ render: manifest not found: $MANIFEST" >&2
  exit 1
fi

mkdir -p "$OUT_DIR/domains"

# --- helpers ---------------------------------------------------------------

# substitute <placeholder> with the content of <fragpath>, multiline, in stdin → stdout
substitute() {
  local placeholder="$1" fragpath="$2"
  local marker_open="{{${placeholder}}}"
  awk -v open="$marker_open" -v file="$fragpath" '
    BEGIN {
      if (file != "") {
        content = ""
        while ((getline line < file) > 0) {
          content = (content == "" ? line : content "\n" line)
        }
        close(file)
      }
    }
    {
      line = $0
      out = ""
      while ((p = index(line, open)) > 0) {
        out = out substr(line, 1, p-1) content
        line = substr(line, p + length(open))
      }
      print out line
    }
  '
}

# --- load static placeholders from sources.json ----------------------------
SOURCES="$FRAG_DIR/../sources.json"
get_src() { # get_src <key>
  [[ -f "$SOURCES" ]] || { echo ""; return; }
  grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$SOURCES" \
    | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/'
}

REPO_NAME="$(get_src repoName)"
[[ -z "$REPO_NAME" ]] && REPO_NAME="repo"

# parse one manifest line into globals M_SCOPE M_ID M_PLACEHOLDER M_PATH.
# NOTE: we use `cut`, not `IFS=$'\t' read`, because bash `read` collapses empty
# fields (the `id` column is intentionally empty for global/drift rows), which
# would misalign placeholder/path. `cut -f` preserves empty columns.
parse_row() {
  M_SCOPE=$(printf '%s' "$1" | cut -f1)
  M_ID=$(printf '%s' "$1" | cut -f2)
  M_PLACEHOLDER=$(printf '%s' "$1" | cut -f3)
  M_PATH=$(printf '%s' "$1" | cut -f4)
}

# --- 1. render KNOWLEDGE.md (global placeholders + REPO_NAME) ---------------
echo "▶ rendering KNOWLEDGE.md"
TMP=$(mktemp)
cp "$TMPL_DIR/knowledge-index.md.tmpl" "$TMP"
awk -v r="$REPO_NAME" '{ gsub(/\{\{REPO_NAME\}\}/, r); print }' "$TMP" > "$TMP.2"; mv "$TMP.2" "$TMP"
while IFS= read -r row; do
  parse_row "$row"
  [[ "$M_SCOPE" == "global" ]] || continue
  [[ -z "$M_PLACEHOLDER" ]] && continue
  [[ -f "$FRAG_DIR/$M_PATH" ]] || echo "⚠️  render: fragment not found: $FRAG_DIR/$M_PATH" >&2
  substitute "$M_PLACEHOLDER" "$FRAG_DIR/$M_PATH" < "$TMP" > "$TMP.2"; mv "$TMP.2" "$TMP"
done < "$MANIFEST"
mv "$TMP" "$OUT_DIR/KNOWLEDGE.md"

# --- 2. render drift.md -----------------------------------------------------
echo "▶ rendering drift.md"
TMP=$(mktemp)
cp "$TMPL_DIR/drift-report.md.tmpl" "$TMP"
while IFS= read -r row; do
  parse_row "$row"
  [[ "$M_SCOPE" == "drift" ]] || continue
  [[ -z "$M_PLACEHOLDER" ]] && continue
  [[ -f "$FRAG_DIR/$M_PATH" ]] || echo "⚠️  render: fragment not found: $FRAG_DIR/$M_PATH" >&2
  substitute "$M_PLACEHOLDER" "$FRAG_DIR/$M_PATH" < "$TMP" > "$TMP.2"; mv "$TMP.2" "$TMP"
done < "$MANIFEST"
mv "$TMP" "$OUT_DIR/drift.md"

# --- 3. render domains/<id>.md (per domain) --------------------------------
DOMAIN_IDS=$(awk -F'\t' '$1=="domain" && $2!="" {print $2}' "$MANIFEST" | sort -u)
for did in $DOMAIN_IDS; do
  echo "▶ rendering domains/$did.md"
  TMP=$(mktemp)
  cp "$TMPL_DIR/domain-knowledge.md.tmpl" "$TMP"
  while IFS= read -r row; do
    parse_row "$row"
    [[ "$M_SCOPE" == "domain" && "$M_ID" == "$did" ]] || continue
    [[ -z "$M_PLACEHOLDER" ]] && continue
    [[ -f "$FRAG_DIR/$M_PATH" ]] || echo "⚠️  render: fragment not found: $FRAG_DIR/$M_PATH" >&2
    substitute "$M_PLACEHOLDER" "$FRAG_DIR/$M_PATH" < "$TMP" > "$TMP.2"; mv "$TMP.2" "$TMP"
  done < "$MANIFEST"
  mv "$TMP" "$OUT_DIR/domains/$did.md"
done

# --- 4. copy .meta (sources.json, anchors.json, harvest-data.json) ---------
for metafile in sources.json anchors.json harvest-data.json; do
  if [[ -f "$FRAG_DIR/../$metafile" ]]; then
    mkdir -p "$OUT_DIR/.meta"
    cp "$FRAG_DIR/../$metafile" "$OUT_DIR/.meta/$metafile"
  fi
done

echo "✅ render complete → $OUT_DIR"
exit 0
