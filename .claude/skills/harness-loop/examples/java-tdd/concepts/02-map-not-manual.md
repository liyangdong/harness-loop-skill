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
