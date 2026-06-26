## 工作循环: Plain (No Enforced Methodology)

This project does not impose TDD, SDD, BDD, DDD, or RDD. The only rules are
the ones written in this `AGENTS.md` and enforced by `scripts/check-*.sh`.
Pick whatever design approach fits the task; the harness cares about outputs,
not process.

### Workflow

1. Read `TASKS.md` for the current subtask. Read `state/iteration.md` for
   what was tried last iteration and why. These two files are the entire
   "methodology" — they tell you what to do and what has been done.
2. Read the relevant subdirectory `AGENTS.md` files (if any). Those describe
   local conventions for `src/`, `docs/`, or other top-level dirs. Follow
   them as the local rules of the road.
3. Make the change using whatever approach fits: prototype-then-refine,
   test-as-you-go, spec-then-build. The harness does not prescribe the
   approach.
4. Run `bash scripts/check-tests.sh` (and any other `check-*.sh` that exists
   in `scripts/`). Every check must exit 0. If a check fails, its stderr
   tells you the file, line, and fix — apply the fix and re-run.
5. Update `state/iteration.md` (progress field, last action) so the next
   iteration starts from current truth, not from session memory.
6. Commit. The commit message should describe what changed and why; if your
   project's `AGENTS.md` mandates a format (Conventional Commits, etc.),
   follow it.
7. If you find yourself wanting to enforce a methodology (TDD, SDD, etc.),
   STOP. Methodology adoption is a project-level decision that updates this
   `AGENTS.md` and regenerates scaffolding. Do not silently introduce one.

### Acceptance criteria

- [ ] `bash scripts/check-tests.sh` exits 0
- [ ] Every `check-*.sh` in `scripts/` exits 0
- [ ] `state/iteration.md` progress field was updated this iteration
- [ ] No new directory or file was created that implies an un-adopted
      methodology (e.g. no `tests/` appearing without TDD being declared,
      no `docs/specs/` appearing without SDD)

### Required artifacts

- `AGENTS.md` — the project's own conventions file. This IS the
  "methodology" for Plain projects. Edit it when conventions change; do not
  leave conventions only in chat or in someone's head.
- `scripts/check-tests.sh` — the always-on gate. Even Plain projects must
  pass this; it is the floor below which nothing sinks.

### Anti-patterns

- **Silent methodology adoption.** The agent starts writing tests first,
  creating a `docs/specs/` directory, or building `.feature` files without
  updating `AGENTS.md`. The next iteration sees structure with no stated
  rule and reverts or duplicates it. If you want a methodology, declare it.
- **Skipping `state/iteration.md`.** "I'll remember what I did." You will
  not; the next iteration starts fresh. Always write progress to disk.
- **Adding rules to chat instead of `AGENTS.md`.** A reviewer says "from now
  on always do X" in a PR comment. The rule lives only in chat; the next
  fresh-context agent never sees it. Encode rules in `AGENTS.md` or in a
  `check-*.sh`, never only in conversation.
- **Disabling checks because they are noisy.** A check fails; rather than
  fixing the underlying issue, the check is muted. The harness loses its
  teeth. Fix the issue, or downgrade the project to `advisory` mode via
  regeneration — do not delete or comment out check logic.
