# java-sdd-example — Harness 3-Phase Rollout

> Progressively adopt harness-engineering practices. Don't try to roll out all
> three phases at once — Phase 1 already brings a significant reliability lift;
> Phase 2 is the inflection point; Phase 3 is icing.

## Phase 1 — 信息层 (1-2 days)

Goal: make the project legible to any AI agent.

- [x] `AGENTS.md` exists at repo root (≤100 lines, map-mode)
- [x] Subdir `AGENTS.md` files for `state/`, `scripts/`, `docs/`, methodology dir
- [x] `TASKS.md` is the source of truth for in-progress work
- [x] `state/iteration.md` carries loop state
- [ ] Fill in `docs/architecture/overview.md` (if layout B/C)
- [ ] Fill in `docs/conventions/README.md` (if layout B/C)

**Outcome:** every agent iteration starts from the same documented baseline.
Output becomes consistent across runs.

## Phase 2 — 约束层 (3-5 days)

Goal: turn conventions into mechanical rules CI can enforce.

- [x] `.githooks/pre-commit` runs every `scripts/check-*.sh`
- [x] `.github/workflows/consistency.yml` runs a multi-gate pipeline:
      type-check → lint → tests → architecture → file-size → consistency → doc-freshness
- [ ] Enable `架构约束` (Q4) if the project has layered source — generates
      `scripts/check-architecture.sh` (advisory by default)
- [ ] Tune the file-size limit (default 300 lines) via `HARNESS_LOOP_MAX_FILE_LINES`
- [ ] Promote architecture check to strict (set `HARNESS_LOOP_ARCH_STRICT=1`
      and regenerate) once the codebase is clean

**Outcome:** violations fail CI before they reach `main`. Review load drops.

## Phase 3 — 自动化层 (1-2 weeks)

Goal: let the loop self-verify and self-heal.

- [ ] Add a `scripts/agent-verify.sh` worktree-isolation script (per cnblogs §4.2)
- [ ] Schedule a weekly doc-gardening pass: scan `docs/design/` for
      `Status: Draft` older than 30 days, open cleanup PRs
- [ ] Wire `state/entropy-log.md` into `TASKS.md` so the agent picks up
      refactor work autonomously
- [ ] (Optional) Stand up observability: Loki + Promtail + Grafana stack
      so the agent can read its own logs during debugging

**Outcome:** the loop runs longer without human intervention.

## When to revisit this roadmap

- After a major incident: re-evaluate Phase 2 strict-mode coverage
- Quarterly: review which conventions still belong in prose vs. which have
  become check scripts (Concept 03: docs rot, lint rules don't)
- Whenever the project pivots direction: regenerate via the harness-loop skill

## References

- Original guide: [Harness Engineering 最佳实践](https://www.cnblogs.com/informatics/p/19812585)
- Paradigm: [deusyu/harness-engineering](https://github.com/deusyu/harness-engineering)
- Skill internals: `.claude/skills/harness-loop/AGENTS.md`
