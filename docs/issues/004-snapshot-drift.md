# Snapshot drift between examples and renderer output

## Summary

After implementing `run-with-answers.sh` (issue 003), L2 now actually runs and surfaces **8 drift items** between the hand-authored example snapshots (committed by T19-T21) and what the renderer produces from `answers.json`.

L2 working as designed = drift surfaced = this issue.

## Drift items

### Bug class A: snapshot has hand-edits the renderer doesn't reproduce

1. **`.gitignore` comment** (all 3 examples): snapshot says `"## How the AI agent works on this repo (appended section for .gitignore)"` but template says `"# Harness-loop generated — append to existing .gitignore"`.
2. **`AGENTS.md` concepts/ subdir-index line** (java-tdd): snapshot omits the `concepts/ — 6 core concepts (learning archive)` line. Note: java-hybrid DOES include this line — drift between snapshots themselves.
3. **`scripts/check-consistency.sh` line endings** (java-tdd only): snapshot has CRLF (Windows edit), renderer uses LF.

### Bug class B: missing template features

4. **`README.md` Q4-conditional content** (java-sdd): when Q4 lacks `外部验证`, snapshot omits `bash scripts/check-tests.sh` from "manually run checks" section and uses mode-specific text (`advisory — failures warn but do not block`). Template hardcodes both.
5. **`TASKS.md` Q4-conditional content** (java-sdd): same pattern — snapshot references `check-consistency.sh` instead of `check-tests.sh` when Q4 lacks `外部验证`. Template hardcodes `check-tests.sh`.
6. **Hybrid `AGENTS.md` callout block** (java-hybrid): snapshot has a manually-added `> **Hybrid methodology:** this repo combines SDD + TDD ...` block at the top. Template doesn't produce this.

### Bug class C: cosmetic

7. **Hybrid `AGENTS.md` extra blank lines**: snapshot has extra blank lines around the `---` methodology separator and before each H2 (manually added for readability).
8. **`tests/pom.xml` comment alignment** (java-tdd, java-hybrid): snapshot author manually realigned comment text after `{{GROUP_ID}}`/`{{ARTIFACT_ID}}`/etc. substitution. Renderer preserves template alignment.

## Two resolution paths

### Path A: renderer is canonical

Regenerate all 3 snapshots from the renderer. Loses hand-crafted content (Hybrid callout, Q4-conditional text). Fastest. L2 passes immediately.

### Path B: enhance renderer to match snapshots

Add the missing features:
- Q4-conditional content in readme-section.tmpl and tasks-md.tmpl
- Hybrid callout block in agents-root.md.tmpl
- Configurable `.gitignore` header comment
- Comment realignment in pom.xml.tmpl

More work but preserves intended UX. L2 passes once features added.

## Suggested resolution

**Path B for bug class B** (real missing features — Q4-conditional, Hybrid callout). These represent actual skill behavior the snapshots correctly captured.

**Path A for bug class A and C** (cosmetic hand-edits). Snapshots aligned to renderer output.

## Acceptance criteria

- [x] Decision made per drift item (which path)
- [x] For Path B items: renderer enhanced, all 3 snapshots regenerated
- [x] For Path A items: snapshots aligned to renderer output
- [x] L2 passes (exit 0) on all 3 examples
- [x] New renderer features documented in decision-tree.md

## Resolution (issue 004 closed)

**Implementation approach: Option A — Python renderer logic.**
Templates stay simple text with `{{PLACEHOLDER}}` tokens; branching lives in
`run-with-answers.py`. Per the issue recommendation: keeps templates static
and reviewable, logic centralized where the answers dict is already in scope.

### Class B (renderer enhancements)

Five new conditional helpers added to `run-with-answers.py`:

| Helper | Placeholder | Behavior |
|---|---|---|
| `build_hybrid_callout` | `{{HYBRID_CALLOUT}}` | Empty unless Q2=Hybrid; emits the `>` blockquote naming the Q2_sub methodologies with priority-ordering note |
| `build_entry_point_block` | `{{ENTRY_POINT_BLOCK}}` | Both lines when 外部验证 ∈ Q4; otherwise only `check-consistency.sh` |
| `build_manual_checks` | `{{MANUAL_CHECKS}}` | `bash scripts/check-tests.sh` only when 外部验证 ∈ Q4; always `bash scripts/check-consistency.sh` |
| `build_primary_check_script` | `{{PRIMARY_CHECK_SCRIPT}}` | `check-tests.sh` (外部验证) / `check-consistency.sh` (otherwise) |
| `build_strict_mode_desc` | `{{STRICT_MODE_DESC}}` | strict → "failures block commits"; advisory → "failures warn but do not block" |

### Class A & C (snapshots aligned)

All 3 example dirs regenerated via:
```bash
for ex in java-tdd java-sdd java-hybrid; do
  exdir="…/examples/$ex"
  ansfile="$exdir/answers.json"
  find "$exdir" -type f ! -name answers.json -delete
  tmp=$(mktemp -d)
  bash scripts/run-with-answers.sh "$ansfile" "$tmp"
  cp -r "$tmp/." "$exdir/"
  rm -rf "$tmp"
done
```

Snapshots now reflect renderer output byte-for-byte. Specifically:
- `.gitignore` header comment uses template's `# Harness-loop generated …`
- `AGENTS.md` always lists `concepts/` in SUBDIR_INDEX when Q7=生成 (java-tdd
  snapshot previously omitted this — that was an internal drift between
  java-tdd and java-hybrid)
- `check-consistency.sh` is LF (CRLF in the old java-tdd snapshot was a
  Windows-edit artifact)
- Hybrid AGENTS.md blank-line structure matches renderer output (the
  manually-added extra blank lines around `---` separator and before H2s
  were drift item 7)
- `tests/pom.xml` comment alignment preserved as-is (renderer doesn't
  realign — acknowledged as a known cosmetic item that cannot be fixed
  without a comment-alignment pass the renderer doesn't do)

### Documentation

Five new placeholder rows added to the Substitution map table in
`wizard/decision-tree.md`, each marked "Added in issue 004".

### Verification

- L1 (`check-skill.sh`): ✅ passes
- L2 (`check-examples.sh`): ✅ all 3 examples match snapshots, exit 0
- L3 (`check-bootstrap.sh`): ✅ bootstrap self-check passes

## Priority

Medium — L2 surfacing drift is good, but shipping with known drift undermines the regression-baseline purpose of examples.

## Found by

Implementing issue 003's runner (commit `d02e127`). L2 ran for the first time and surfaced these.
