# Entropy Log

Tracks pattern drift found by `scripts/check-entropy.sh`.

| Date | Issue | Location | Severity | Status |
|------|-------|----------|----------|--------|
| (initially empty) |

## Severity levels

- `info`: noted, no action needed.
- `warn`: should fix in next refactor pass.
- `error`: violates a golden rule, fix before merge.

## Workflow

- New row appended by `check-entropy.sh` on each run that finds drift.
- Set `Status` to `open` when added; flip to `resolved` once fixed and the
  next `check-entropy.sh` run confirms zero findings for that pattern.
- Do not delete rows — the log is the audit trail of how entropy was tamed.
