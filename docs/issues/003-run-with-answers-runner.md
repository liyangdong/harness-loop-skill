# Implement scripts/run-with-answers.sh for L2/L3 automation

## Summary

The L2 (`check-examples.sh`) and L3 (`check-bootstrap.sh`) self-verification scripts depend on a non-interactive runner `scripts/run-with-answers.sh` that doesn't exist. Both currently degrade gracefully (print warning, exit 0), but this means **example regression detection and bootstrap self-check are not actually running**.

## Current state

- `scripts/check-examples.sh` (L2): prints "scripts/run-with-answers.sh not implemented" and exits 0 without diffing
- `scripts/check-bootstrap.sh` (L3): same warning, exits 0 without generating a test project
- Both scripts have their full logic implemented behind the runner check — only the runner is missing

## What the runner needs to do

`scripts/run-with-answers.sh <answers.json> <output_dir>`

Reads the JSON answer set, applies the same wizard logic the interactive skill uses, and writes rendered files to `<output_dir>`. Effectively a non-interactive renderer.

### Inputs

```json
{
  "Q1": "应用代码",
  "Q2": "TDD",
  "Q3": "Java",
  "Q4": ["外部验证", "检查点"],
  "Q5": null,
  "Q6": "claude-sonnet-4-6",
  "Q7": "生成",
  "Q8": "strict",
  "PROJECT_NAME": "...",
  "MISSION_ONE_LINER": "..."
}
```

### Logic

1. Parse `<answers.json>`
2. Read `wizard/decision-tree.md` to determine which templates to load
3. Read each template, substitute placeholders with answer values
4. Write rendered files to `<output_dir>` mirroring the structure the interactive wizard produces
5. Exit 0 on success, non-zero on error

### Implementation language

Bash with `jq` for JSON parsing (consistent with other scripts in the skill). Could also be Python if jq is unavailable — but bash + jq is preferred for portability with the rest of the skill.

## Acceptance criteria

- [ ] `scripts/run-with-answers.sh` exists and is executable
- [ ] Takes `<answers.json> <output_dir>` args
- [ ] Produces output byte-equivalent to the interactive wizard for the same answer set
- [ ] L2 (`check-examples.sh`) runs end-to-end and verifies all 3 examples match snapshots
- [ ] L3 (`check-bootstrap.sh`) generates a real `java-tdd` project and runs its checks
- [ ] Documented in the skill README's verification section

## Priority

Low for v0.1.0 (current state is functional, just degraded). Medium-high for v0.2.0+ when examples become a real regression baseline.

## Related

Spec §9 (Future extensions) lists this as planned work. Examples are designed to support this from day one.
