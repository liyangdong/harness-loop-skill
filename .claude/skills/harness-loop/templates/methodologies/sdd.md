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
