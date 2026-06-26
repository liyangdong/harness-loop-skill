## 5. Throughput Over Perfection (Merges)

Correction is cheap, waiting is expensive.

### Why it matters

In an agent-driven loop, the bottleneck is wall-clock time per iteration, not code
correctness per merge. A PR that sits open for two days waiting for a human to nitpick
naming has cost the loop ~48 iterations of work that could have happened. The math is
brutal: every hour of latency is an hour the agent was not making progress.

This inverts traditional review priorities. In human-only teams, careful pre-merge
review catches bugs cheaply. In agent loops, the agent itself will re-touch this code in
the next iteration anyway — so a "good enough" merge followed by an immediate
correction PR is usually faster than a slow careful merge.

The same logic applies to flaky tests. In a human loop, a flaky test demands
investigation. In an agent-throughput loop, a `retry: 3` on CI and a follow-up cleanup
task is often the right call: the loop keeps moving, the flake gets fixed in a later
entropy pass.

### How to apply

- Default to auto-merge on green checks; require explicit human block to hold a PR.
- Keep PR scope small enough to review in under 5 minutes; split larger work.
- Treat test flakes as a cleanup task, not a stop-the-line event. Add `retry-on-failure`
  in CI, file a `TASKS.md` entry, move on.
- Prefer "merge and fix forward" over "reject and rewrite". A small follow-up PR is
  cheaper than re-running the failed iteration.
- Set a PR age alarm: any PR open >24h in an agent loop is a process bug.
- Track merge lead time as a metric; optimize it before optimizing code style.

### Anti-patterns

- PR open for a week while humans argue about a variable name — the agent has rewritten
  the surrounding code twice by then.
- Blocking the loop on a flaky integration test "until we figure out the race" — figure
  it out in an entropy pass, let the loop run.
- "Review everything carefully before merge" as a default policy in an agent-driven
  repo — the agent will out-wait the reviewer.
- Using merge queues that add 30+ minutes of latency for serial safety in a repo that
  doesn't need it.

### References

- Concept 06 — entropy GC schedules the cleanup that this concept defers
- `TASKS.md` — where deferred cleanup items live
- deusyu/harness-engineering — "The Plan Is Disposable"
