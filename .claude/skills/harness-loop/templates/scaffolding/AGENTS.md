# AGENTS.md — templates/scaffolding/

> Conventions for every file under `templates/scaffolding/`. These templates
> render into the project-state files a generated project ships with on day one:
> `TASKS.md`, `state/iteration.md`, `state/entropy-log.md`, plus project-root
> files (gitignore, opencode-config, readme-section) covered by sibling tasks.

## 1. Purpose

Scaffolding templates render into **state files**, not runtime code. The agent
reads and rewrites them every iteration. A bad scaffolding file (wrong shape,
stray TODO, missing column) breaks the loop on iteration 1, before any real
work begins. Get them exactly right.

## 2. File naming

- `<name>.tmpl` — every file in this dir. The `.tmpl` suffix is mandatory;
  generators glob `templates/scaffolding/*.tmpl` and refuse anything else.
- Rendered filename = template filename with `.tmpl` stripped. Examples:
  - `tasks-md.tmpl` → `TASKS.md` (at repo root)
  - `state-iteration.tmpl` → `state/iteration.md`
  - `state-entropy.tmpl` → `state/entropy-log.md`
- The `-` in `state-iteration` becomes `/` plus the basename when rendering
  into a subdir; the wizard's `summary-format.md` documents the path map.

## 3. Placeholder convention

- All placeholders use `{{UPPER_SNAKE_CASE}}` matching the substitution map in
  `wizard/decision-tree.md`. Every placeholder used here MUST have a row in
  that map (source, default, consumers).
- Common placeholders in this dir: `{{PROJECT_NAME}}`, `{{MAX_ITERATIONS}}`,
  `{{TIMESTAMP}}`, `{{PROGRESS_SIG}}`, `{{LAST_ACTION}}`,
  `{{CURRENT_EPIC_DESCRIPTION}}`, `{{SUBTASK_1}}`, `{{SUBTASK_2}}`,
  `{{SUBTASK_3}}`.
- Each `.tmpl` file documents which placeholders it consumes in a comment at
  the top of the file (HTML comment `<!-- ... -->` for markdown targets, `#`
  for shell/json targets). The comment lists one placeholder per line with a
  one-word source hint.

## 4. Commit-ready output

Rendered scaffolding files land in the user's first commit. Therefore:

- No `TODO`, `FIXME`, `XXX`, or `???` markers — these trip `check-entropy.sh`.
- No placeholder left unsubstituted. If a value is unknown at generation time,
  substitute the documented fallback (e.g. `(fill in current epic)`), not the
  bare `{{TOKEN}}`.
- Initial state must be sensible: empty tables with headers, `(initially
  empty)` notes where the agent will append, iteration counter starting at 1.

## 5. Markdown shape

- One `H1` per file (the file's title).
- Tables use GitHub-flavored pipe syntax with a header separator row.
- YAML front matter (where used, e.g. `state-iteration.tmpl`) is minimal:
  only keys the loop or check scripts actually read. Add a key here only if a
  check script template already grep's for it.

## 6. Hard limits

- No scaffolding template exceeds **80 lines**. State files must stay
  scannable in one screen; if one grows, split the concern into a second
  state file rather than padding.
- One concern per file: `iteration.md` = loop progress, `entropy-log.md` =
  pattern drift. Do not merge them.

## 7. Self-verification

Before committing a new or edited `scaffolding/*.tmpl`:

```bash
# Substitute every placeholder with its default and check markdown validity.
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
grep -c '{{' /tmp/out.md  # must print 0
```

If `grep` prints anything but `0`, a placeholder is missing from the
substitution map or misspelled. Fix before committing.
