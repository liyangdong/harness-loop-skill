# C2 regex in check-consistency.sh caps at 2 path segments

## Summary

The C2 check in `templates/checks/check-consistency.sh.tmpl` uses a regex that only recognizes directory paths up to 2 segments deep. Paths like `.claude/skills/harness-loop/` (3 segments) cannot be matched as a single directory reference, causing the check to either miss AGENTS.md files at deeper levels or split the path incorrectly.

## How to reproduce

1. Apply the harness-loop skill to a project with a 3+ level deep directory that contains an AGENTS.md (e.g., `.claude/skills/harness-loop/AGENTS.md`)
2. Reference that path in the root `AGENTS.md` subdir index
3. Run `bash scripts/check-consistency.sh`
4. Observe: C2 reports a false positive ("subdir AGENTS.md missing") because it looks for `.claude/skills/AGENTS.md` instead of `.claude/skills/harness-loop/AGENTS.md`

## Workaround

Don't index 3+ level deep directories in the root AGENTS.md subdir index section. The dogfood (commit `0824420`) avoided this by not indexing `.claude/skills/harness-loop/`.

## Suggested fix

Update the regex in `check-consistency.sh.tmpl` `check_c2()` function from a 1-2 segment pattern to support N-deep paths. Something like:

```bash
# Current (buggy):
grep -oE '([A-Za-z0-9_.-]+/){1,2}[A-Za-z0-9_.-]+' AGENTS.md

# Fixed:
grep -oE '([A-Za-z0-9_.-]+/)+[A-Za-z0-9_.-]+' AGENTS.md
```

Then verify the matched path has an AGENTS.md sibling.

## Acceptance criteria

- [ ] Regex matches paths of any depth
- [ ] C2 correctly verifies 3+ level deep directories
- [ ] No false positives on legitimate deep paths
- [ ] Existing 1-2 level paths still work
- [ ] `examples/java-hybrid/docs/specs/AGENTS.md` (2 levels) still verified
- [ ] A new test case with 3-level path added to examples

## Priority

Medium — affects projects with nested skill/plugin directories.

## Found by

Dogfood of the skill on its own host project (commit `0824420`).
