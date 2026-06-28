# AGENTS.md — wizard/

> Conventions for editing the wizard directory. This directory holds the *logic* of the
> 7-question interactive flow and the live harvest playbook. Template *content* lives in
> `templates/`; the deterministic renderer lives in `scripts/`. Edit one and you usually
> need to edit the other.

## 1. Purpose

`wizard/` defines the 7-question AskUserQuestion sequence that collects every decision
needed to build the knowledge base, plus the H1-H5 playbook that turns deepwiki +
codegraph into render fragments. The wizard is the single source of truth for "what gets
asked, in what order, and what the agent does at harvest time".

Files in this directory:
- `questions.md` — the 7 questions, each in a self-contained block
- `decision-tree.md` — answers → harvest/render behavior (kept in sync with `questions.md`)
- `harvest-pipeline.md` — the H1-H5 deepwiki+codegraph extraction playbook (the skill's core)
- `summary-format.md` — the post-question summary printed before writing files

## 2. Standalone-readable

`questions.md` MUST be readable as a standalone script. A fresh agent that opens only
this file must be able to execute all 7 questions without reading any other file. Do
not split a single question's spec across multiple files; do not link out for option
wording.

## 3. Q5 options are runtime-populated, NOT hardcoded

Q5 (映射哪些顶层子系统) is multiSelect, but its option list is built at runtime from the
subsystems parsed out of the deepwiki root page by harvest step H1. Do NOT hardcode the
lucene subsystem list into `questions.md` — lucene is only the example baseline. The Q5
block in `questions.md` describes the *option-shape contract* (label = subsystem name,
description = one-line purpose) and points to H1 as the source of the option list. If H1
fails to parse `## Major Subsystems`, Q5 falls back to a single free-text "manual
subsystem list" option.

## 4. Hard limits

- **Max 7 questions** — cognitive load limit. If a new decision is needed, fold it into
  an existing question's branch or into a `decision-tree.md` default rather than adding Q8.
- Each question block MUST include all of: question text, header, type (free-text /
  single-select / multiSelect), options or answer shape, dependencies (when to skip),
  recommended default.
- Free-text questions (Q1-Q4) use AskUserQuestion with a typed free-text answer (a path,
  URL, or directory). Do not fake free-text with an "Other" escape hatch the way
  harness-loop does for Q5 — knowledge-map's path/URL inputs are genuinely free-form.

## 5. Editing rules

| Change | Required edits |
|---|---|
| Add an option to an existing question | `questions.md` + `decision-tree.md` |
| Change recommended default | `questions.md` only |
| Add a brand-new question | NOT ALLOWED — already at the 7-question cap. Refactor instead. |
| Tweak Chinese wording | `questions.md` only (keep meaning stable, sync spec) |
| Change skip / dependency logic | `questions.md` dependencies field + `decision-tree.md` |
| Tune harvest extraction | `harvest-pipeline.md` only |
| Add a render fragment | `harvest-pipeline.md` H5a + `decision-tree.md` (depth/shape) + matching `templates/*.tmpl` placeholder |

Any change to `questions.md` that adds/removes an option or changes a dependency MUST
also update `decision-tree.md` in the same commit.

## 6. Ordering and dependencies

Q1-Q4 are always asked first (repo / deepwiki URL / projectPath / output dir). Then H1
runs (fetch deepwiki root, parse subsystems). Then Q5-Q7 are asked, with Q5's option list
populated from H1's parse. Keep this shape; the two-phase ask in SKILL.md step 1-3
assumes it — Q5 cannot be asked before H1 has produced the subsystem list.
