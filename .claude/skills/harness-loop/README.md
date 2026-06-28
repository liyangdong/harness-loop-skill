# harness-loop

A project-level Claude Code skill that generates **agent-neutral** AGENTS.md-based
constraint systems. When invoked, it walks the user through a 7-question wizard
and writes a complete methodology-aware AGENTS.md plus the supporting directory
scaffold, check scripts, and templates into whatever project it is invoked in.
Output aligns with the [harness-engineering](https://github.com/deusyu/harness-engineering)
paradigm and works with any [agents.md](https://agents.md)-compatible AI agent
(Claude Code, opencode, Codex CLI, Cursor, Gemini CLI, etc.).

## When to invoke

Trigger the skill when the user asks to:

- "set up AGENTS.md" / "create an AGENTS.md for this repo"
- "configure TDD / SDD / hybrid constraints"
- "add a harness loop to this project"
- "scaffold a constraint system"
- "make this run until done"

Or when an existing project lacks `.claude/skills/`-style discipline and the user
wants deterministic, methodology-locked development.

## Quick start

In any project root, ask Claude:

> Use the harness-loop skill to set up AGENTS.md for this repo.

Claude will ask 7 questions, then generate the constraint system. Full question
list lives in [`wizard/questions.md`](./wizard/questions.md); branching logic in
[`wizard/decision-tree.md`](./wizard/decision-tree.md).

## The 7 wizard questions

| # | Question | Decides |
|---|---|---|
| 1 | 项目类型 (project_type) | Mission one-liner + default Q4 check set |
| 2 | 方法论 (methodology: TDD / SDD / BDD / DDD / RDD / Plain / Hybrid) | Which `methodologies/*.md` block + scaffolding dir to emit |
| 3 | 项目语言/技术栈 (language) | Which `tests-<lang>/` scaffold + `check-tests.sh` body |
| 4 | 验证机制 (verification mechanisms, multi-select) | Which `check-*.sh` scripts to emit |
| 5 | 卡死阈值 (stuck threshold) | `check-stuck.sh` comparison value (only if Q4 includes 卡死检测) |
| 6 | 学习档案 (learning archive) | Whether `concepts/01-06*.md` are emitted |
| 7 | 严格程度 (strictness) | strict vs advisory exit-code behavior |

Full option lists for each question are in `wizard/questions.md`.

## Generated output overview

After the wizard, the target project gains an `AGENTS.md` at its root plus a
structured scaffold:

```
<target-project>/
├── AGENTS.md                       # ≤100 lines, the constraint entry point
├── TASKS.md                        # source of truth for in-progress work
├── state/
│   ├── iteration.md                # loop state
│   ├── entropy-log.md              # entropy ledger
│   └── AGENTS.md                   # state/ conventions
├── scripts/
│   ├── check-promise.sh            # C1 completion signal
│   ├── check-tests.sh              # C2 external verification (test+lint+typecheck)
│   ├── check-consistency.sh        # C5 consistency (C1+C2+C6)
│   ├── check-entropy.sh            # C4 entropy scan
│   ├── check-stuck.sh              # C3 stuck-loop detector (optional)
│   ├── check-architecture.sh       # C7 layered dependency check (optional)
│   └── AGENTS.md                   # scripts/ conventions
├── docs/
│   ├── specs/                      # spec-first artifacts (SDD / hybrid)
│   ├── domain/                     # ubiquitous-language definitions (if DDD)
│   └── AGENTS.md                   # docs/ conventions
├── features/                       # Gherkin feature files (if BDD)
├── tests/                          # test-first artifacts (if TDD)
├── concepts/                       # 6 concept notes (optional learning archive)
├── .githooks/pre-commit            # local enforcement
├── .github/workflows/consistency.yml  # multi-gate CI
├── README.md                       # agent usage appendix
└── .gitignore                      # language-specific ignores
```

**No agent-specific config is generated.** The skill is agent-neutral: any
agents.md-compatible tool reads `AGENTS.md` directly. Configure tool-specific
settings (model selection, sandboxing, permission whitelists) out-of-band.

The skill's own internal layout (templates, wizard, examples) lives in
`.claude/skills/harness-loop/` and is described in [`AGENTS.md`](./AGENTS.md).

## 3-phase rollout

This skill's output supports the harness-engineering 3-phase rollout
(see [`docs/phase-roadmap.md`](./docs/phase-roadmap.md) in any generated project
for the full version):

- **Phase 1 — 信息层 (1-2 days):** AGENTS.md + `docs/` structure + coding
  conventions. Agent output becomes consistent across iterations.
- **Phase 2 — 约束层 (3-5 days):** layered architecture lint + CI multi-gate
  (type/lint/test/coverage/architecture/file-size/consistency). Code quality
  becomes controllable.
- **Phase 3 — 自动化层 (1-2 weeks):** git worktree isolation, scheduled
  doc-gardening agent, observability hooks. Manual review load drops sharply.

Don't try to roll out all three at once. Phase 1 already brings a significant
reliability lift; Phase 2 is the inflection point; Phase 3 is icing.

## Extension guide

### Add a methodology

1. Create `templates/methodologies/<name>.md` describing the loop (red/green,
   spec/code, etc.).
2. Add the option to Q2 in both `wizard/questions.md` and `wizard/decision-tree.md`.
3. If the methodology needs new directories, add them under
   `templates/scaffolding/methodology-dirs/`.
4. Add an example under `examples/<lang>-<methodology>/`.

### Add a language

1. Create `templates/scaffolding/methodology-dirs/tests-<lang>/`.
2. Mirror the structure of an existing `tests-<lang>/` directory.
3. Add the option to Q3 in `wizard/questions.md` and `wizard/decision-tree.md`.

### Add a check layer

1. Create `templates/checks/check-<name>.sh.tmpl`.
2. Add the option to Q4 in `wizard/questions.md` and `wizard/decision-tree.md`.

See [`AGENTS.md`](./AGENTS.md) §3 for the full editing table.

## Verification

The skill ships three verification layers:

- **L1 — skill self-check**: `bash .claude/skills/harness-loop/scripts/check-skill.sh`
  validates that this skill is internally consistent (templates present, wizard
  files in sync, no sample exceeds the 100-line rule).
- **L2 — example regression check**: `bash .claude/skills/harness-loop/scripts/check-examples.sh`
  regenerates each `examples/<name>/` from its `answers.json` via the
  non-interactive runner (`scripts/run-with-answers.sh`) and diffs against the
  committed snapshot. Catches drift between the renderer and the snapshots.
- **L3 — bootstrap self-check**: `bash .claude/skills/harness-loop/scripts/check-bootstrap.sh`
  generates a fresh `java-tdd` project via the runner and exercises the
  generated project's own check scripts, git hook, CI workflow, and AGENTS.md
  shape.

L2 and L3 depend on `scripts/run-with-answers.sh` (a thin bash wrapper around
`run-with-answers.py`) — a non-interactive renderer that reads an `answers.json`
and writes a complete project layout. To run the renderer manually:

```bash
bash .claude/skills/harness-loop/scripts/run-with-answers.sh \
  .claude/skills/harness-loop/examples/java-tdd/answers.json /tmp/output
```

Run L1 before committing any change to this skill (see `AGENTS.md` §5). Run L2
and L3 to catch regressions in the renderer or drift in the example snapshots.

## References

- Design spec: [`docs/superpowers/specs/2026-06-27-harness-loop-skill-design.md`](../../../docs/superpowers/specs/2026-06-27-harness-loop-skill-design.md)
- Implementation plan: [`docs/superpowers/plans/2026-06-27-harness-loop-skill.md`](../../../docs/superpowers/plans/2026-06-27-harness-loop-skill.md)
- Paradigm: [harness-engineering](https://github.com/deusyu/harness-engineering)
- Best-practices guide: [Harness Engineering 最佳实践](https://www.cnblogs.com/informatics/p/19812585)
