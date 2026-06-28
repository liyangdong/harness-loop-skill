# AGENTS.md — templates/concepts/

> Conventions for the six concept fragments injected into every generated project's
> root `AGENTS.md`. These are the philosophical core of the harness; they change rarely.

## 1. Purpose

Each file in this directory is a standalone markdown fragment, ready to be concatenated
into a generated root `AGENTS.md` between the project header and the methodology block.
No frontmatter, no wrapper, no surrounding prose — the file's body IS the content.

## 2. File shape

- Filename: `NN-<kebab-name>.md` where `NN` is the canonical order (01-06).
- First line is `## N. <Concept Name>` (level-2 heading, ready for injection).
- Body is 30-80 lines including the heading.
- Sections in order: short definition, `### Why it matters`, `### How to apply`,
  `### Anti-patterns`, `### References`.
- "Why it matters" is 2-3 paragraphs (the problem the concept solves).
- "How to apply" is a 3-5 item concrete checklist.
- "Anti-patterns" is 2-3 examples of what NOT to do.

## 3. Editing rules

- Concepts are stable. Edit rarely; when you do, bump nothing else — they are
  append-only fragments.
- Do not add a 7th concept without a design discussion. Six is the cap that keeps root
  `AGENTS.md` under its line budget.
- Keep wording agent-readable: concrete examples, real file paths, no metaphor-only
  explanation.
- Cross-reference other concepts by number (`see Concept 03`), not by link, so the
  injected output stays self-contained.

## 4. Injection contract

The generator concatenates `01-` through `06-` in order, then appends
`templates/ralph-tenets.md`. The result is the "Concepts" section of root `AGENTS.md`.
Do not introduce a separator file or wrapping heading — each fragment owns its own `##`.

## 5. Line budget

Sum of all six concept files plus `ralph-tenets.md` should keep root `AGENTS.md` under
its ~100-line ceiling when combined with header and pointer sections. If total concept
length grows past that, split detail into per-concept `docs/concepts/NN-*.md` files in
the generated project and leave a one-line pointer in root.
