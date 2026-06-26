# AGENTS.md — examples/

> Three full snapshots of repos that the harness-loop skill would generate.
> Each example is a frozen regression baseline: when `scripts/check-skill.sh`
> or `scripts/check-examples.sh` changes, regenerating the example and
> diffing against the committed copy surfaces template regressions before
> they hit a real user.

## 1. Layout

Each example lives under `examples/<name>/` and is a complete tree — the same
files a generated user repo would contain on day one:

- `AGENTS.md` (root, ~100 lines)
- `TASKS.md`, `state/iteration.md`, `state/entropy-log.md`
- `scripts/check-tests.sh`, `scripts/check-consistency.sh`
- `.githooks/pre-commit`, `.github/workflows/consistency.yml`
- `.opencode/config.json`
- Methodology-specific subdir (e.g. `tests/` for TDD/Java, `docs/specs/` for SDD)
- `concepts/01-…md` through `concepts/06-…md` (verbatim copies)
- `answers.json` — the answer set that produced this snapshot

## 2. The three examples

| Example | Q2 method | Q3 lang | Q7 mode | Q8 strict | Purpose |
|---|---|---|---|---|---|
| `java-tdd` | TDD | Java | 生成 | strict | TDD + Maven/JUnit5 baseline. Used as the canonical "happy path" example. |
| `java-sdd` | SDD | Java | 生成 | strict | Spec-Driven: emits `docs/specs/` first, then code. |
| `java-hybrid` | hybrid | Java | 生成 | advisory | Multi-methodology project that mixes TDD + DDD and uses advisory mode. |

## 3. How examples differ

- **java-tdd** is single-methodology, single test tree, strict. It is the
  smallest example and the first to regenerate when a template changes.
- **java-sdd** adds `docs/specs/` (per SDD scaffolding) and proves the
  generator handles spec-first workflows.
- **java-hybrid** proves the generator composes multiple methodologies and
  handles the advisory-strict branch correctly.

If a template change touches only TDD paths, regenerate `java-tdd` and
diff. If it touches scaffolding layouts shared across methodologies,
regenerate all three.

## 4. Regeneration

Run `bash scripts/check-examples.sh` to verify each example is consistent
(no leftover `{{...}}` placeholders, expected file counts, valid bash/JSON).
If `run-with-answers.sh` exists, regenerate via:

```bash
bash scripts/run-with-answers.sh examples/java-tdd/answers.json /tmp/out
diff -r examples/java-tdd /tmp/out
```

Any diff is a regression. Either update the template or update the snapshot
after review.

## 5. What examples are NOT

- They are not working user projects. `mvn -q test` will fail because there
  is no production code — only a placeholder `FirstTest` that proves the
  build is wired correctly.
- They are not edited by humans. Any change to an example must come from
  template regeneration, never a manual edit.
- They are not consumed by the skill at runtime. The skill reads templates;
  these examples exist only for verification.
