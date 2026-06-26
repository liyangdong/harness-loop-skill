# AGENTS.md — templates/

> Conventions for every file under `templates/`. These templates are concatenated,
> substituted, and written into generated projects. Keep them clean and parametrized.

## 1. Purpose

`templates/` holds every reusable artifact the wizard injects into a generated project:
concept fragments, methodology blocks, check scripts, scaffolding files. Templates are
**source** for generation, not documentation about generation.

## 2. File naming

- `<name>.md` — plain markdown fragment, no substitution (e.g. concept files).
- `<name>.md.tmpl` — markdown with `{{PLACEHOLDER}}` tokens, substituted at generation.
- `<name>.sh.tmpl` — shell script with `{{PLACEHOLDER}}` tokens.
- `<name>.tmpl` — any other format with placeholders.
- Subdir `AGENTS.md` files are plain `.md` (no placeholders) — they describe the subdir.

## 3. Placeholder convention

- All placeholders use `{{UPPER_SNAKE_CASE}}` matching a key from `wizard/questions.md`.
- Every placeholder used in a template MUST have a default in `decision-tree.md`.
- Templates must produce valid output even when a placeholder is substituted with the
  empty string — guard with shell conditionals or markdown conditionals.
- The only placeholder allowed in `concepts/` and `ralph-tenets.md` is none — those
  fragments are project-agnostic and substituted nowhere.

## 4. Subdir AGENTS.md

Each subdir (`concepts/`, `methodologies/`, `checks/`, `scaffolding/`) has its own
`AGENTS.md` describing that subdir's writing rules. Read the relevant one before
editing files in that subdir. Do not duplicate rules here — point to them.

## 5. Hard limits

- No template file exceeds **200 lines**. If one grows past 200, split it:
  - Prose: split into multiple fragments loaded in order.
  - Shell: factor shared logic into a sourced `lib.sh.tmpl`.
- Concept files: 30-80 lines each (see `concepts/AGENTS.md`).
- Root `AGENTS.md` template assembly stays under 100 lines after substitution.

## 6. Check script templates

Every `check-*.sh.tmpl` MUST:

- Branch on `{{STRICT_MODE}}` per `strict-mode.md`.
- Print fix instructions to stderr on failure (file path, line, what's wrong, how to
  fix).
- Be runnable standalone: `bash check-foo.sh` exits non-zero on failure, zero on pass.
- Compose in the pre-commit hook, not internally.

## 7. Self-verification

Before committing template changes, run:

```bash
bash .claude/skills/harness-loop/scripts/check-skill.sh
```

This checks line limits, placeholder coverage, and that every subdir has the required
`AGENTS.md`. Do not commit on failure.

## 8. Map-not-manual (dogfood)

This file is the index for `templates/`. Detail lives in subdir `AGENTS.md` files.
If you find yourself writing template-specific rules here, move them to the relevant
subdir `AGENTS.md` instead.
