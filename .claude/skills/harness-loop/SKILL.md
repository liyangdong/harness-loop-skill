---
name: harness-loop
description: Use when the user wants to set up an agent harness, build a constraint system for AI agents on a repo, generate AGENTS.md, or make long-running agent tasks execute predictably. Triggers include "搭 harness", "建 loop", "约束 agent", "生成 AGENTS.md", "make this run until done", "set up opencode constraints", "build harness", "set up loop".
---

# Harness-Loop Skill

Generate a project-wide constraint system (AGENTS.md + mechanical checks + scaffolding) that makes opencode (or any agents.md-compatible tool) execute long tasks predictably. Aligned with deusyu/harness-engineering paradigm.

## When to invoke

User says any of:
- "搭个 harness" / "build a harness" / "set up a loop"
- "约束 agent 行为" / "constrain agent behavior"
- "生成 AGENTS.md" / "generate AGENTS.md"
- "让任务自动跑" / "make this run until done"
- "设置 opencode 约束" / "set up opencode constraints"

## What it produces

A constraint system in the project root:
- `AGENTS.md` (~100-line navigation entry)
- Subdirectory `AGENTS.md` files (progressive disclosure)
- `scripts/check-*.sh` (mechanical enforcement, C1-C6 layers)
- `.githooks/pre-commit` + `.github/workflows/consistency.yml` (double-gate)
- `TASKS.md`, `state/iteration.md`, `state/entropy-log.md`
- `.opencode/config.json`
- Methodology-specific scaffolding (`tests/`, `docs/specs/`, etc.)
- `README.md` appendage + `.gitignore` patch

## 8-step flow

1. Read `wizard/questions.md` and ask all 8 questions via AskUserQuestion (one message, parallel calls allowed for independent questions)
2. Read `wizard/decision-tree.md` to map answers → template paths
3. Read each selected template file
4. Read `templates/strict-mode.md` to determine exit-code behavior
5. Assemble root `AGENTS.md` using `templates/agents-root.md.tmpl` + selected concept/methodology blocks
6. Write subdir `AGENTS.md` files per Q2 methodology using `templates/agents-subdir.md.tmpl`
7. Write `scripts/`, `.githooks/`, `.github/workflows/`, scaffolding/, `.opencode/`, `TASKS.md`, `state/`, `README.md` patch, `.gitignore` patch
8. Print `wizard/summary-format.md` rendered with answers; wait for `Y/n` confirmation. Only write files after `Y`.

## Progressive loading

- Only templates explicitly selected by user answers are read
- Unselected methodologies/checks/languages are never loaded into context
- 6 concepts + Ralph tenets always loaded (root AGENTS.md invariant)

## Templates index

- `templates/AGENTS.md` — templates/ conventions
- `templates/methodologies/AGENTS.md` — methodology writing rules
- `templates/concepts/AGENTS.md` — concept block format
- `templates/checks/AGENTS.md` — check script conventions
- `templates/scaffolding/AGENTS.md` — scaffolding file purposes

## Anti-patterns

- DO NOT inline template content into SKILL.md (violates map-not-manual)
- DO NOT hardcode model IDs or commands in SKILL.md (use templates + Q6 input)
- DO NOT generate files the user didn't select (Q4 multiSelect drives check script generation)
- DO NOT skip the confirmation step (step 8)

## Extension

See `README.md` "Extension Guide" section. New methodologies/checks/languages follow the same progressive-loading pattern.
