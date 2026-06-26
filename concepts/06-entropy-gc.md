## 6. Entropy GC

Tech debt is high-interest debt.

### Why it matters

Agents reproduce whatever patterns they see most often in the repo. If the repo has
three examples of a clean abstraction and one example of a hack, the agent will copy the
hack roughly 25% of the time — and the next agent iteration will copy the hack over the
hack, compounding. Within a few dozen iterations, a repo can drift from "mostly clean"
to "mostly expedient" without any single human decision.

Human teams catch this drift in code review. Agent loops merge fast (Concept 05) and
cannot rely on a human catching every regression. Without a cleanup mechanism, entropy
accumulates until the constraint system itself becomes unreliable.

The fix is a periodic **garbage collection** pass: a background task scans the repo for
deviations from golden rules (large files, missing tests, deprecated APIs, drift from
ADRs), updates quality scores in `state/entropy-log.md`, and opens refactor PRs against
the worst offenders. The agent gets the cleanup work as ordinary tasks; the loop stays
balanced.

### How to apply

- Define golden rules in `AGENTS.md` and `scripts/check-*.sh` — entropy GC measures
  deviation from these.
- Run `scripts/check-entropy.sh` on a schedule (cron, CI nightly) — not on every commit.
- Maintain `state/entropy-log.md` as an append-only ledger: timestamp, file, deviation,
  score.
- When score crosses a threshold, auto-create a `TASKS.md` entry "refactor X" — let the
  loop pick it up like any other task.
- Refactor PRs go through the same merge rules as feature PRs (Concept 05) — small,
  fast, auto-merge on green.
- Periodically archive resolved entropy entries; the log should stay readable.

### Anti-patterns

- "We'll clean it up later" with no scheduled pass — later never comes, entropy wins.
- One massive "tech debt sprint" every quarter instead of continuous GC — the repo
  spends 3 months drifting and 1 week catching up.
- Entropy log that only a human reads — it must feed `TASKS.md` so the agent acts on it.
- Deleting the entropy log to "start fresh" — you've lost the audit trail.

### References

- `scripts/check-entropy.sh.tmpl` — entropy measurement script
- `state/entropy-log.md` — append-only deviation ledger
- Concept 05 — throughput-over-perfection (deferred cleanup is the point of GC)
- deusyu/harness-engineering — entropy as compounding cost
