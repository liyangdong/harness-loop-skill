# AGENTS.md — templates/

> Conventions for every file under `templates/`. These are the renderable
> content shells for the knowledge base; the renderer (`scripts/render-kb.sh`)
> substitutes `{{PLACEHOLDER}}` tokens from `.meta/fragments/` and writes the
> final markdown into the target repo. Keep them clean and parametrized.

## 1. Purpose

`templates/` holds the KB content shells (`.tmpl`) that the knowledge-map skill
renders into a target repo's knowledge base. Templates are **source** for
generation, not documentation about generation. The actual prose content lives
in `.meta/fragments/` (written by the wizard/harvest); templates only provide
section ordering, headings, and frontmatter shape.

## 2. File naming

- `<name>.md.tmpl` — markdown with `{{PLACEHOLDER}}` tokens, substituted at render.
- `<name>.json.tmpl` — JSON with placeholders (reference shells only — see §5).
- `<name>.sh.tmpl` — shell script with `{{STRICT_MODE}}` substituted at copy time
  (under `checks/`; these are COPIED into the target repo, not rendered from fragments).
- `AGENTS.md` (this file, and subdir ones) — plain `.md`, no placeholders.

## 3. Placeholder convention

- All placeholders use `{{UPPER_SNAKE_CASE}}`.
- Every placeholder maps 1:1 to a fragment file via `.meta/manifest.tsv` (4-col:
  `scope`, `id`, `placeholder`, `path`). The renderer reads manifest rows in order
  and substitutes the placeholder with the fragment's content.
- Templates must produce valid output even when a placeholder substitutes to the
  empty string (missing fragment) — section headings still render, the body is
  just empty. Never let a missing fragment break the document shape.

### Placeholder vocabulary

- **Global** (rendered once into `KNOWLEDGE.md`):
  `{{REPO_NAME}}` (static, from `.meta/sources.json` repoName — NOT a fragment),
  `{{MISSION}}`, `{{PROJECT_STRUCTURE}}`, `{{TOPOLOGY}}`, `{{DRIFT_SUMMARY}}`,
  `{{ENTRY_POINTS}}`, `{{REGEN_NOTE}}`.
- **Domain** (rendered once per domain into `domains/<name>.md`):
  `{{DOMAIN_NAME}}`, `{{DEEPWIKI_URL}}`, `{{STATUS}}`, `{{NARRATIVE}}`,
  `{{CONCEPTS}}`, `{{ANCHORS_TABLE}}`, `{{DOMAIN_DRIFT}}`, `{{CROSS_LINKS}}`.
- **Drift** (rendered once into `drift.md`):
  `{{REGEN_TIMESTAMP}}`, `{{ORPHANS_TABLE}}`, `{{BLINDSPOTS_TABLE}}`.
- **Check scripts** (under `checks/`, substituted at COPY time not render time):
  `{{STRICT_MODE}}` only.

## 4. Hard limits

- `knowledge-index.md.tmpl` renders to **≤100 lines** — the rendered `KNOWLEDGE.md`
  MUST stay under 100 lines. Fragments feeding it (overview, topology, entry-points,
  drift-summary, project-structure) must stay terse; verbose prose belongs in
  `domains/*.md`, not in the index.
- No template file exceeds **200 lines**. If one grows past 200, split it into
  multiple fragments loaded in order by the renderer.
- Domain files: no fixed cap, but aim for scannable (50-150 lines typical).

## 5. The meta exception

`.meta/sources.json` and `.meta/anchors.json` are written **directly** by harvest
step H5a (structured JSON output), NOT rendered from templates. The
`meta-sources.json.tmpl` and `meta-anchors.json.tmpl` files here are **reference
shells only** — they document the shape of H5a's output for readers and for tests.
`render-kb.sh` does NOT regenerate them: it copies H5a's output verbatim into
`.meta/`. Do not add `{{PLACEHOLDER}}` tokens to them expecting render-time
substitution; their placeholders exist purely to mark shape, not for the renderer.

## 6. Subdir AGENTS.md

`checks/` has its own `AGENTS.md` describing in-target check script conventions
(strict-mode branching, output format, codegraph dependency). Read it before
editing files under `checks/`. Do not duplicate those rules here.

## 7. Map-not-manual (dogfood)

This file is the index for `templates/`. Detail lives in `checks/AGENTS.md`. If
you find yourself writing template-specific rules here, move them to the relevant
subdir `AGENTS.md` instead. Placeholder vocabulary is the one cross-cutting
concern that belongs here (§3).
