## 3. Mechanical Enforcement

Docs rot, lint rules don't.

### Why it matters

Prose constraints have zero force. "Always write tests for new functions" written in
AGENTS.md will be violated by the very next agent run, because there is nothing to stop
it. The agent has no reason to re-read AGENTS.md before each edit, and even if it did,
prose does not return a non-zero exit code.

A check script does. `scripts/check-tests.sh` returning `1` on missing tests is
enforceable: the pre-commit hook blocks, CI fails, the loop refuses to proceed. The
constraint becomes a **machine invariant** instead of a polite request.

The deeper value is that check scripts are **self-documenting**. The error message can
embed the exact fix instruction ("add `tests/foo_test.py` covering the new branch on
line 42"). The agent does not need to look anything up — the failure tells it what to do.

### How to apply

- Every constraint in AGENTS.md must have a corresponding `scripts/check-*.sh` or it is
  aspirational, not enforced. Aspirational rules belong in a separate "Guidelines"
  section so agents know they are soft.
- Embed fix instructions in every check's stderr output: file path, line, what's wrong,
  how to fix.
- Checks must be deterministic: same repo state → same exit code. Flaky checks destroy
  trust in the loop.
- Each check is one file, one concern (`check-tests.sh`, `check-consistency.sh`).
  Compose in the pre-commit hook, not inside a mega-check.
- When a check fails for a wrong reason, fix the check in the same PR that exposes the
  bug — never disable it.

### Anti-patterns

- "We have a style guide in `STYLE.md`." — no force, agent ignores it.
- One `check-all.sh` with 500 lines — opaque, hard to extend, no granular failure mode.
- Check error message: "validation failed". Fix it: "tests/user_test.py missing; create
  it covering the public API of src/user.py".
- Disabling a check with `|| true` "to unblock" — you have just deleted the constraint.

### References

- `templates/checks/*.sh.tmpl` — check script templates
- `templates/strict-mode.md` — strict vs advisory exit-code behavior
- deusyu/harness-engineering — "Backpressure Over Prescription"
