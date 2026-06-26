# harness-loop

A project-level Claude Code skill that generates AGENTS.md-based constraint systems. When
invoked, it walks the user through an 8-question wizard and writes a complete
methodology-aware AGENTS.md plus the supporting directory scaffold, check scripts, and
templates into whatever project it is invoked in. Output aligns with the
[harness-engineering](https://github.com/deusyu/harness-engineering) paradigm.

## When to invoke

Trigger the skill when the user asks to:

- "set up AGENTS.md" / "create an AGENTS.md for this repo"
- "configure TDD / SDD / hybrid constraints"
- "add a harness loop to this project"
- "scaffold a constraint system"

Or when an existing project lacks `.claude/skills/`-style discipline and the user wants
deterministic, methodology-locked development.

## Quick start

In any project root, ask Claude:

> Use the harness-loop skill to set up AGENTS.md for this repo.

Claude will ask 8 questions, then generate the constraint system. Full question list lives
in [`wizard/questions.md`](./wizard/questions.md); branching logic in
[`wizard/decision-tree.md`](./wizard/decision-tree.md).

## The 8 wizard questions

| # | Question | Decides |
|---|---|---|
| 1 | What kind of project is this? | Language + runtime defaults |
| 2 | Primary language / stack | Which `tests-<lang>/` scaffold to emit |
| 3 | Development methodology (TDD / SDD / hybrid) | Which `methodologies/*.md` to load |
| 4 | Test framework | Test command + directory layout |
| 5 | Domain concepts (DDD?) | Whether `domain/` + concept files are emitted |
| 6 | Behavior specs (BDD / Gherkin?) | Whether `features/` is emitted |
| 7 | Which check layers? (type / lint / format / test / build) | Which `checks/*.sh.tmpl` to emit |
| 8 | Source of truth priority (docs-first? readme-first?) | Whether `readme-first/` overrides defaults |

Full option lists for each question are in `wizard/questions.md`.

## Generated output overview

After the wizard, the target project gains an `AGENTS.md` at its root plus a structured
`docs/` tree:

```
<target-project>/
├── AGENTS.md                       # ≤100 lines, the constraint entry point
├── docs/
│   ├── specs/                      # spec-first artifacts (SDD / hybrid)
│   ├── features/                   # Gherkin feature files (if BDD)
│   ├── domain/                     # ubiquitous-language definitions (if DDD)
│   ├── tests/                      # test-first artifacts (TDD)
│   └── readme-first/               # readme-first artifacts (if Q8 = readme)
└── .claude/
    └── checks/                     # generated check-*.sh scripts
```

The skill's own internal layout (templates, wizard, examples) lives in
`.claude/skills/harness-loop/` and is described in [`AGENTS.md`](./AGENTS.md).

## Extension guide

### Add a methodology

1. Create `templates/methodologies/<name>.md` describing the loop (red/green, spec/code,
   etc.).
2. Add the option to Q3 in both `wizard/questions.md` and `wizard/decision-tree.md`.
3. If the methodology needs new directories, add them under
   `templates/scaffolding/methodology-dirs/`.
4. Add an example under `examples/<lang>-<methodology>/`.

### Add a language

1. Create `templates/scaffolding/methodology-dirs/tests-<lang>/`.
2. Mirror the structure of an existing `tests-<lang>/` directory.
3. Add the option to Q2 in `wizard/questions.md` and `wizard/decision-tree.md`.

### Add a check layer

1. Create `templates/checks/check-<name>.sh.tmpl`.
2. Add the option to Q7 in `wizard/questions.md` and `wizard/decision-tree.md`.

See [`AGENTS.md`](./AGENTS.md) §3 for the full editing table.

## Verification

The skill ships three verification layers:

- **L1 — skill self-check**: `bash .claude/skills/harness-loop/scripts/check-skill.sh`
  validates that this skill is internally consistent (templates present, wizard files in
  sync, no sample exceeds the 100-line rule).
- **L2 — example regression check**: `bash .claude/skills/harness-loop/scripts/check-examples.sh`
  regenerates each `examples/<name>/` from its `answers.json` via the non-interactive
  runner (`scripts/run-with-answers.sh`) and diffs against the committed snapshot.
  Catches drift between the renderer and the snapshots.
- **L3 — bootstrap self-check**: `bash .claude/skills/harness-loop/scripts/check-bootstrap.sh`
  generates a fresh `java-tdd` project via the runner and exercises the generated
  project's own check scripts, git hook, CI workflow, and AGENTS.md shape.

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
