# AGENTS.md — wizard/

> Conventions for editing the wizard directory. This directory holds the *logic* of the
> 8-question interactive flow (questions + decision tree + summary format). Template
> *content* lives in `templates/`. Edit one and you usually need to edit the other.

## 1. Purpose

`wizard/` defines the 8-question AskUserQuestion sequence that collects every decision
needed to generate the constraint system. The flow is the single source of truth for
"what gets asked and in what order".

Files in this directory:
- `questions.md` — the 8 questions, each in a self-contained block
- `decision-tree.md` — answers → template path mapping (kept in sync with `questions.md`)
- `summary-format.md` — the post-question summary printed before writing files

## 2. Standalone-readable

`questions.md` MUST be readable as a standalone script. A fresh agent that opens only
this file must be able to execute all 8 questions without reading any other file. Do
not split a single question's spec across multiple files; do not link out for option
wording.

## 3. Hard limits

- **Max 8 questions** — cognitive load limit. If a new decision is needed, fold it into
  an existing question's branch or into `decision-tree.md` defaults rather than adding Q9.
- Each question block MUST include all of: question text, header, multiSelect flag,
  options (label + description), dependencies (when to skip), recommended default.

## 4. Editing rules

| Change | Required edits |
|---|---|
| Add an option to an existing question | `questions.md` + `decision-tree.md` |
| Change recommended default | `questions.md` only |
| Add a brand-new question | NOT ALLOWED — already at the 8-question cap. Refactor instead. |
| Tweak Chinese wording | `questions.md` only (keep meaning stable, sync spec) |
| Change skip logic | `questions.md` dependencies field + `decision-tree.md` |

Any change to `questions.md` that adds/removes an option or changes a dependency MUST
also update `decision-tree.md` in the same commit.

## 5. Question format

Every question in `questions.md` follows the exact block shape:

```
## Q<n>: <title> (<snake_case_key>)

**AskUserQuestion call:**
- question: "<Chinese question text>"
- header: "<short header ≤12 chars>"
- multiSelect: <true|false>
- options:
  - label: "<label>", description: "<description>"
  ...
- recommended default: "<label>"

**Dependencies:** <always asked, or conditional on previous answer>
**Branch:** <what to skip or change based on answer>
```

Free-text questions (Q5, Q6) use the options list as "common defaults + Other" rather
than a true free-text field — see those blocks for the pattern.

## 6. Ordering and dependencies

Q1-Q4 are always asked. Q5 is conditional on Q4. Q6-Q8 are always asked. Keep this
shape; the parallel-call optimization in SKILL.md step 1 assumes it.
