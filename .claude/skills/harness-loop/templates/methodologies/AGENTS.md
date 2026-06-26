# AGENTS.md — templates/methodologies/

> Conventions for the six methodology fragments (TDD/SDD/BDD/DDD/RDD/Plain). The
> wizard substitutes the selected fragment into root `AGENTS.md`'s `## 工作循环`
> section via the `{{METHODOLOGY_BLOCK}}` placeholder. See `decision-tree.md` Q2.

## 1. Purpose

Each file in this directory is a standalone markdown fragment, ready to be
concatenated into a generated root `AGENTS.md` as the "工作循环" section. No
frontmatter, no wrapper, no surrounding prose — the file's body IS the content.

## 2. File shape

- Filename: `<lowercase-name>.md` (e.g. `tdd.md`, `sdd.md`, `plain.md`).
- First line is `## 工作循环: <DisplayName>` (level-2 heading, ready for injection).
- Body is 50-100 lines including the heading.
- Sections in fixed order:
  1. 1-2 sentence definition (no heading).
  2. `### Workflow` — 5-7 numbered steps.
  3. `### Acceptance criteria` — 3-5 mechanically checkable items (`- [ ]`).
  4. `### Required artifacts` — 1-3 files/dirs this methodology expects.
  5. `### Anti-patterns` — 3-4 real failure modes with brief explanation.

## 3. Acceptance criteria rules

Every `- [ ]` item under Acceptance criteria MUST be checkable by a script or
by inspection against a file path — not by judgment. "Tests pass" is OK because
`check-tests.sh` exits non-zero. "Code is clean" is NOT OK because no script
can decide it. If you cannot write a `check-*.sh` that fails on a violation,
reword the criterion or move it to Anti-patterns.

## 4. Required artifacts rules

- Every artifact path must match the scaffolding directory created by
  `decision-tree.md` Q2 for that methodology.
- If the methodology needs no scaffolding (Plain), list the project's
  `AGENTS.md` itself as the artifact, with a one-line "see project conventions"
  note.
- Use the same path the generator writes to (e.g. `tests/`, `docs/specs/`),
  not a methodology-internal name.

## 5. Anti-patterns rules

Each anti-pattern is a real failure mode the agent is likely to hit, written
as: what the agent did, why it is wrong, what to do instead. No slogans. No
"be careful with X" — say what "careful" means concretely.

## 6. Plain is special

`plain.md` does NOT enforce a methodology. It exists so projects that pick Q2 =
Plain still get a `## 工作循环` section — one that says "follow AGENTS.md rules,
run check-tests.sh". Do not invent workflow steps for Plain; defer to the
project's own conventions.

## 7. Hybrid composition

When the user picks Q2 = Hybrid, the wizard concatenates the selected fragments
in priority order SDD > TDD > BDD > DDD > RDD (per `decision-tree.md` §Hybrid).
Each fragment must remain readable when stacked above another — no "see above"
pointers that break when reordered, no duplicate level-2 headings.

## 8. Editing rules

- Methodologies change rarely. When you edit one, verify the Required
  artifacts section still matches the scaffolding directory created by the
  generator.
- Do not add a 7th methodology without updating `questions.md` Q2 options,
  `decision-tree.md` Q2 table, and the Hybrid priority order together.
- Keep wording agent-readable: real file paths, real script names, no
  metaphor-only explanation.
