# Strict vs Advisory Mode

Every generated `check-*.sh` script branches on `{{STRICT_MODE}}` so the same template
serves both new projects (block aggressively) and legacy projects migrating in (warn,
don't break).

## strict (default)

- Any check failure exits non-zero.
- Pre-commit hook blocks the commit.
- CI workflow fails the PR check.
- Agent must fix before proceeding.

Use strict when:
- New project, greenfield.
- Constraint system has been live for a while and the team trusts the checks.
- After a cleanup pass has brought the repo into compliance.

## advisory

- Check failure prints a warning to stderr.
- Exit code is always 0.
- Pre-commit hook allows the commit.
- CI workflow posts a comment but does not block.
- Useful for legacy codebases migrating to constraints.

Use advisory when:
- Existing project applying constraints for the first time (avoid blocking all work).
- Rolling out a new check that is expected to fail on existing code.
- During a transition period while the team cleans up deviations.

## Implementation in templates

Each `check-*.sh.tmpl` includes this pattern near the bottom:

```bash
STRICT="{{STRICT_MODE}}"
# ... run check, accumulate FAILURES count ...

if [[ "$FAILURES" -gt 0 ]]; then
  if [[ "$STRICT" == "strict" ]]; then
    exit 1
  else
    exit 0
  fi
fi
```

Warnings in advisory mode always print to stderr with the prefix `ADVISORY:` so they are
greppable and distinct from normal output.

## Decision rule

| Situation | Mode |
|---|---|
| New project | strict |
| Existing project, first time applying constraints | advisory |
| After cleanup pass | switch to strict |
| Newly added check on existing repo | advisory for 1 release, then strict |

The mode is set once per project in `.opencode/config.json` (`STRICT_MODE` field) and
substituted into every check at generation time. Switching modes later requires
regenerating the check scripts — see the wizard Q8 default.
