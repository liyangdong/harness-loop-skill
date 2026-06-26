# docs/

Documentation hub. Project-level docs live here; methodology-specific
subdirectories have their own AGENTS.md files (progressive disclosure).

## 本目录约定

- `README.md` (or `index.md`) — project overview, if it lives in `docs/`
  rather than at repo root. Per RDD methodology, README is written first
  and is the single source for "what is this project".
- Methodology-specific subdirs (each carries its own `AGENTS.md`):
  - `docs/specs/` — SDD specs (see `docs/specs/AGENTS.md` if generated).
  - `docs/domain/` — DDD domain models (see `docs/domain/AGENTS.md`).
  - `docs/features/` — BDD feature files (see `docs/features/AGENTS.md`).
- `concepts/` — learning archive (if Q7 = 生成). The 6 concept files are
  a self-teaching scaffold for new contributors and other agents. Read
  them when you need the *why* behind a constraint, not the *what*.
- Top-level `.md` files for cross-cutting docs (architecture, ADR index,
  glossary) are fine here. One topic per file.

## 写作约定

- **ASCII diagrams encouraged** for architecture, data flow, entity
  relationships. ASCII diffs cleanly in review, is searchable, and
  renders identically on every platform. Link out to checked-in `.svg`
  or `.png` only when ASCII genuinely cannot express the structure.
- **One H1 per file.** Subsections use `##`, `###`. No jumping between
  top-level titles mid-file.
- **Prose stays prose; rules become checks.** If a doc paragraph starts
  describing a rule that *must* hold, move it to `scripts/check-*.sh`
  instead (Concept 03). Docs explain intent; scripts enforce it.
- **Link, don't duplicate.** If a section in `docs/foo.md` would
  duplicate content in `AGENTS.md` or another doc, link to it. Two copies
  drift; one copy with a pointer does not.

## 与根 AGENTS.md 的关系

继承根 AGENTS.md 的 6 大概念（特别是 Concept 02: Map, Not Manual 和 Concept
05: Throughput Merges）。本文件只补充本目录特有规则。

## 验证

- `scripts/check-consistency.sh` — C6 verifies `docs/AGENTS.md` exists;
  C1 may cross-check declared doc counts against actual files if the
  README mentions a number.
