# harness-loop-skill

A project-level Claude Code skill that generates harness-engineering constraint systems via an interactive wizard.

## 6 大概念

## 1. Repo as Truth

If it is not in the repo, it does not exist for the agent.

### Why it matters

Agents start every iteration with a fresh read of the repository. Anything living in
Slack DMs, Google Docs, Notion, a video call summary, or someone's head is **invisible**
to that fresh read. The agent cannot ask "what did the team decide last week?" — it can
only ask "what does the repo say right now?"

This is the single largest source of agent confusion in real projects: a human reviewer
remembers the conversation that produced a decision, the agent does not. The agent then
re-litigates the decision, rewrites working code, or contradicts an earlier choice. Every
re-litigation burns throughput and erodes trust in the constraint system.

The fix is structural, not procedural: decisions must live in versioned files the agent
can read. A decision written in Slack is a decision the agent has not seen.

### How to apply

- Every architectural decision gets an ADR (`docs/specs/decisions/NNNN-*.md`).
- Every "we agreed to do X" lives in a comment in code, a `TASKS.md` entry, or a
  `state/` log line — not in chat.
- When a human reviews agent output and finds an error, the fix is a repo edit (new
  check, new AGENTS.md line, new test) — never "I'll just tell the agent next time".
- `state/iteration.md` is the agent's short-term memory; it is rebuilt from disk each
  iteration, never from session history.
- Treat the repo as the **only** channel: if a teammate wants to constrain the agent,
  they open a PR, not a chat thread.

### Anti-patterns

- "We decided in standup yesterday to use library X." — not in repo, agent picks Y.
- Reviewer feedback given only as a chat message: the next iteration forgets it.
- Tribal knowledge like "don't touch the `legacy/` folder" living only in a senior dev's
  head. Encode it in `AGENTS.md` or `scripts/check-*.sh`.
- ADR written to a wiki but not committed to `docs/specs/decisions/`.

### References

- `state/iteration.md` — short-term agent memory on disk
- Concept 03 — mechanical enforcement turns repo decisions into invariants
- deusyu/harness-engineering — "Disk Is State, Git Is Memory"

## 2. Map, Not Manual

AGENTS.md is an index, not an encyclopedia.

### Why it matters

Giant instruction files die three deaths, all of them fatal to agent-driven work:

1. **Context bloat.** A 2000-line AGENTS.md eats context budget on every iteration. The
   agent spends tokens re-reading instructions that are mostly irrelevant to the current
   task, leaving less budget for the actual work.
2. **Unmaintainable.** Long files accumulate contradictions. Section 4 says "use POST",
   section 17 says "use PUT" — both were true at some point, no one knows which wins.
   Contradictions silently degrade agent reliability because the agent has no tiebreaker.
3. **Unverifiable.** A constraint in prose can be ignored; it has no mechanical force.
   The longer the prose, the more constraints are floating free of any check.

The fix is **progressive disclosure**: a small root AGENTS.md (~100 lines) that lists
where things are, and subdir `AGENTS.md` files that the agent loads only when entering
that subdir. Each file stays short because each file is scoped.

### How to apply

- Root `AGENTS.md` stays ≤100 lines: project purpose, where things live, golden rules.
- Each subdirectory that has rules gets its own `AGENTS.md` (`tests/AGENTS.md`,
  `docs/specs/AGENTS.md`, `scripts/AGENTS.md`).
- Root file links to subdir files; subdir files do not duplicate root content.
- If a rule applies repo-wide, it goes in root. If it applies only to `tests/`, it goes
  in `tests/AGENTS.md`.
- Use `## N.` headings in root so concepts can be added or removed without renumbering.
- A constraint that grows past 5 lines of prose becomes a check script (see Concept 03).

### Anti-patterns

- 800-line root AGENTS.md "because everything is important" — context tax on every call.
- Duplicating the same rule in root and subdir — they drift, agent sees two truths.
- Instructions in `CONTRIBUTING.md` that agents never read — that file is not in the
  agent's default load path.
- Commenting out stale rules instead of deleting them — the agent reads comments too.

### References

- Concept 03 — mechanical enforcement (prose → check script)
- deusyu/harness-engineering — "Steer With Signals, Not Scripts"
- This skill's `templates/agents-root.md.tmpl` — root file generation

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

## 4. Agent Readability

Optimize for agent reasoning over human convenience.

### Why it matters

A repo that is pleasant for a human to skim and a repo that an agent can reason about
reliably are not the same thing. Agents struggle with: magic that depends on runtime
convention, library APIs that change between minor versions, frameworks with terse DSLs
that hide control flow, and dependencies whose training data is thin.

Choosing "boring" technology — stable APIs, well-documented libraries, plain data
structures — dramatically increases the agent's hit rate. The agent has seen these
patterns thousands of times in training; it can write correct code on the first try
without spelunking through docs.

Sometimes this means reimplementing a small subset of a fancy library by hand. A 50-line
inlined implementation the agent fully understands beats a 5-line call into an opaque
upstream that fails in ways the agent cannot diagnose. The cost of writing the subset is
paid once; the cost of debugging the opaque call is paid every iteration.

### How to apply

- Prefer languages and runtimes with stable, well-documented standard libraries.
- Pick libraries that appear frequently in training data (a popular ORM > a clever new
  one).
- Inline small utilities rather than introducing a one-off dependency for 20 lines of
  code.
- Prefer explicit data (plain dicts, structs, JSON) over framework magic (annotations
  that hide control flow, metaclasses, codegen).
- When wrapping an upstream API, write a thin shim with a stable interface — isolate
  upstream churn behind it.
- Avoid beta/preview features in agent-edited code; they change semantics between
  releases.

### Anti-patterns

- Adopting a brand-new framework because it "saves typing" — agent gets it wrong on
  every iteration until training data catches up.
- Heavy metaprogramming so the human can write 3 lines instead of 30 — the agent cannot
  follow the control flow and emits plausible-looking but broken code.
- Wrapping a stable stdlib call in a clever helper "for readability" — now the agent has
  to learn your helper.
- Pinning to `latest` — upstream breaks, agent has no idea why.

### References

- Concept 01 — repo as truth (decisions about stack go in ADRs)
- Concept 06 — entropy GC catches "agent picked the fancy library" drift
- deusyu/harness-engineering — "Fresh Context Is Reliability"

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

## Ralph 信条

## Ralph 6 信条

The six tenets that shape day-to-day agent work in this repo. Read them as operating
principles, not slogans — each one maps to a concrete practice on the right.

| 信条 | 含义 | 在本项目的应用 |
|---|---|---|
| Fresh Context Is Reliability | 每轮迭代重新读仓库 | agent 不依赖会话内存，所有状态写文件（`state/iteration.md`） |
| Backpressure Over Prescription | 不规定怎么做，门控拒绝坏结果 | `check-*.sh` 拒绝非零退出，但不指挥如何修复 |
| The Plan Is Disposable | 重新生成的成本只是 planning loop | 失败的尝试可丢弃，`state/` 是真相而非会话历史 |
| Disk Is State, Git Is Memory | 文件是交接机制 | `TASKS.md` + `state/iteration.md` 持久化进度，commit 记录历史 |
| Steer With Signals, Not Scripts | 加路标，不加脚本 | `AGENTS.md` 描述目标与约束，不写命令序列 |
| Let Ralph Ralph | 坐在循环上，不坐在循环里 | 用户监督而非微管理，让 loop 自己跑完 |

### Day-to-day meaning

These tenets resolve the most common judgment calls an agent faces:

- **"Should I remember X from earlier?"** — No. Re-read `state/iteration.md`. (Tenet 1)
- **"The check failed, what do I do?"** — The check tells you the file and the fix in
  its stderr. Apply the fix; do not look for a hidden "right way". (Tenet 2)
- **"This approach feels wrong, should I salvage it?"** — Discard and regenerate. Disk
  state survives; session state does not. (Tenet 3)
- **"Where do I record progress?"** — Write to disk (`TASKS.md`, `state/`). Do not rely
  on the human remembering. (Tenet 4)
- **"Should I add a new step to the loop?"** — Only if it adds a signal (a check, a
  log). Do not add steps that prescribe *how* to do the work. (Tenet 5)
- **"Should I wait for human input?"** — Only at configured checkpoints. Otherwise keep
  the loop running; the human watches, you do not block on them. (Tenet 6)

### References

- Concepts 01-06 — concrete practices that follow from these tenets
- `state/iteration.md`, `TASKS.md`, `state/entropy-log.md` — the on-disk state surface
- deusyu/harness-engineering — source of the tenet framing

## 工作循环

## 工作循环: SDD (Spec-Driven Development)

Spec before code. A feature exists as a written spec under `docs/specs/` before
any line of implementation is written. The spec is the contract; implementation
is verified against it, not against the author's intent.

### Workflow

1. Open a new spec file at `docs/specs/<feature>.md` using the project's spec
   template. Fill in: problem statement, inputs, outputs, edge cases,
   acceptance criteria, and explicit non-goals.
2. Walk the spec line-by-line against `TASKS.md`. If the spec implies work not
   tracked in `TASKS.md`, add the subtasks now. If `TASKS.md` lists work the
   spec does not cover, either expand the spec or remove the subtask.
3. Self-review the spec for ambiguity: every "should", "might", "could" must
   be rewritten as a checkable statement. Vague specs produce vague code.
4. Implement against the spec. Each acceptance criterion in the spec maps to
   at least one test or one observable behavior. Track coverage in the spec
   file itself (a per-criterion checkbox list at the bottom).
5. Run `bash scripts/check-consistency.sh` — it verifies the spec, the
   implementation, and `TASKS.md` agree (spec name appears in `TASKS.md`,
   acceptance criteria appear as tests or checks).
6. When the spec changes during implementation, update the spec file FIRST,
   then update code, then update tests. Never let the spec drift behind.
7. On completion, the spec's acceptance criteria checkboxes are all ticked
   and the file carries a `Status: implemented` line at the top.

### Acceptance criteria

- [ ] A spec file exists at `docs/specs/<feature>.md` for every behavior added
      this iteration
- [ ] Every acceptance criterion in the spec has a matching test, check, or
      observable behavior referenced by file path
- [ ] `bash scripts/check-consistency.sh` exits 0 (spec, code, and `TASKS.md`
      are mutually aligned)
- [ ] No production code in this iteration lacks a spec entry pointing at it

### Required artifacts

- `docs/specs/<feature>.md` — one spec per feature or significant change.
  Scaffolding directory is `templates/scaffolding/methodology-dirs/specs/`.
- `docs/specs/decisions/NNNN-*.md` — ADRs for cross-cutting decisions that
  outlive a single feature spec.

### Anti-patterns

- **Coding without a spec.** The agent writes implementation, then backfills
  a spec describing what it built. The spec becomes documentation of an
  accident, not a contract. Always write the spec first.
- **Spec drift.** The spec says one thing, the code does another, and no one
  notices because nothing checks. Run `check-consistency.sh` every iteration;
  when the spec and code disagree, fix one of them in the same commit.
- **Vague acceptance criteria.** "The system should be fast." No test can
  fail against that. Reword as "p95 latency < 200ms under load profile X",
  measurable by a specific script.
- **Spec sprawl.** One spec trying to cover five features. Split into five
  files so each can be implemented, reviewed, and marked complete
  independently.

## 子目录索引

docs/specs/ — spec writing conventions (see docs/specs/AGENTS.md)
concepts/ — 6 core concepts (learning archive)
state/ — iteration + entropy logs (see state/AGENTS.md)
scripts/ — check-consistency.sh and friends (see scripts/AGENTS.md)

## 机械化检查

- scripts/check-consistency.sh — runs C1/C2/C6 checks
(No check-tests.sh: Q3=非代码, no test runner)

入口：`./scripts/check-tests.sh`（验证完成度）
     `./scripts/check-consistency.sh`（验证仓库一致性）

## 当前任务

见 `TASKS.md`。每轮迭代更新 `state/iteration.md`。

## 严格度

本仓库采用 **strict** 模式。
- strict: 任何检查失败阻断 commit/merge
- advisory: 仅警告不阻断
