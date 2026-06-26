# AGENTS.md — templates/scaffolding/

> Conventions for every file under `templates/scaffolding/`. These templates
> render into the project-state files a generated project ships with on day one:
> `TASKS.md`, `state/iteration.md`, `state/entropy-log.md`, project-root
> patches (gitignore, opencode-config, readme-section), and the always-generated
> subdir AGENTS.md files.

## 1. Purpose

Scaffolding templates render into **state files**, not runtime code. The agent
reads and rewrites them every iteration. A bad scaffolding file (wrong shape,
stray TODO, missing column) breaks the loop on iteration 1, before any real
work begins. Get them exactly right.

## 2. File naming

- `<name>.tmpl` — mandatory suffix; generators glob `*.tmpl` only.
- Rendered filename = template name with `.tmpl` stripped. Examples:
  `tasks-md.tmpl` → `TASKS.md`; `state-iteration.tmpl` → `state/iteration.md`;
  `state-entropy.tmpl` → `state/entropy-log.md`.
- `-` in `state-iteration` becomes `/` when rendering into a subdir;
  `wizard/summary-format.md` documents the path map.

## 3. Placeholder convention

- All placeholders use `{{UPPER_SNAKE_CASE}}` matching the substitution map in
  `wizard/decision-tree.md`. Every placeholder used here MUST have a row.
- Common placeholders: `{{PROJECT_NAME}}`, `{{MAX_ITERATIONS}}`,
  `{{TIMESTAMP}}`, `{{PROGRESS_SIG}}`, `{{LAST_ACTION}}`,
  `{{CURRENT_EPIC_DESCRIPTION}}`, `{{SUBTASK_1..3}}`.
- Each `.tmpl` documents consumed placeholders in a header comment
  (`<!-- ... -->` for markdown, `#` for shell/json).
- **Placeholder-free `.tmpl` files are allowed** when content is project-
  agnostic (see `always-dirs/` below). Declare `Placeholders consumed: (none)`.
  These trigger an S3 warning in `check-skill.sh` (L1); the warning is
  intentional and documented, not a bug.

## 4. Subdirectory layout

`scaffolding/` has three regions:

- **Top-level `*.tmpl`** — root-level state files (`tasks-md.tmpl`,
  `state-iteration.tmpl`, `state-entropy.tmpl`) plus project-root patches
  (`gitignore.tmpl`, `opencode-config.json.tmpl`, `readme-section.tmpl`).
- **`methodology-dirs/`** — one subdir per methodology (SDD, TDD, BDD, DDD,
  RDD) and per-language test tree (`tests-java/`, `tests-python/`, etc.).
  Whole subdir copied into the project when Q2/Q3 selects it. May contain
  non-`.tmpl` files (e.g., `pom.xml.tmpl` + `src/...`).
- **`always-dirs/`** — subdir AGENTS.md templates rendered for **every**
  project regardless of answers. Three files: `state-agents.md.tmpl` →
  `state/AGENTS.md`, `scripts-agents.md.tmpl` → `scripts/AGENTS.md`,
  `docs-agents.md.tmpl` → `docs/AGENTS.md`. Documented in
  `wizard/decision-tree.md` §"Always-generated subdir AGENTS.md".

## 5. Commit-ready output

Rendered scaffolding files land in the user's first commit. Therefore:

- No `TODO`, `FIXME`, `XXX`, `???` markers — these trip `check-entropy.sh`.
- No placeholder left unsubstituted; use the documented fallback (e.g.
  `(fill in current epic)`), not the bare `{{TOKEN}}`.
- Initial state must be sensible: empty tables with headers, `(initially
  empty)` notes where the agent will append, iteration counter at 1.

## 6. Markdown shape

- One `H1` per file. Tables use GitHub pipe syntax with a separator row.
- YAML front matter (where used, e.g. `state-iteration.tmpl`) is minimal:
  only keys the loop or check scripts actually read.

## 7. Hard limits

- No scaffolding template exceeds **80 lines**. If one grows, split the
  concern into a second state file rather than padding.
- One concern per file: `iteration.md` = loop progress, `entropy-log.md` =
  pattern drift. Do not merge them.
- Subdir AGENTS.md files (under `always-dirs/` or `methodology-dirs/`) are
  bounded by the global 100-line AGENTS.md limit enforced in `check-skill.sh`
  S4 — leave headroom.

## 8. Self-verification

```bash
# Substitute every placeholder with its default; verify none remain.
sed -e 's/{{PROJECT_NAME}}/demo/g' \
    -e 's/{{MAX_ITERATIONS}}/30/g' \
    -e 's/{{TIMESTAMP}}/1970-01-01T00:00:00+00:00/g' \
    -e 's/{{PROGRESS_SIG}}/initial/g' \
    -e 's/{{LAST_ACTION}}/loop bootstrap/g' \
    -e 's/{{CURRENT_EPIC_DESCRIPTION}}/(fill in current epic)/g' \
    -e 's/{{SUBTASK_1}}/- [ ] (define subtask 1)/g' \
    -e 's/{{SUBTASK_2}}/- [ ] (define subtask 2)/g' \
    -e 's/{{SUBTASK_3}}/- [ ] (define subtask 3)/g' \
    templates/scaffolding/<file>.tmpl > /tmp/out.md
grep -c '{{' /tmp/out.md  # 0 for placeholder-using templates
```

Non-zero `grep` for a placeholder-using template = misspelled/missing
placeholder. Placeholder-free templates (declared `(none)`) print `0` trivially.
