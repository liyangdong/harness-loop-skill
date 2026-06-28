---
name: harness-loop
description: Use when the user wants to set up an agent harness, build a constraint system for AI agents on a repo, generate AGENTS.md, or make long-running agent tasks execute predictably. Triggers include "搭 harness", "建 loop", "约束 agent", "生成 AGENTS.md", "make this run until done", "set up agent constraints", "build harness", "set up loop". Agent-neutral — works with Claude Code, opencode, Codex CLI, Cursor, Gemini CLI, or any agents.md-compatible tool.
---

# Harness-Loop Skill

Generate a project-wide constraint system (AGENTS.md + mechanical checks + scaffolding) that makes any agents.md-compatible AI agent execute long tasks predictably. Aligned with deusyu/harness-engineering paradigm.

## When to invoke

User says any of:
- "搭个 harness" / "build a harness" / "set up a loop"
- "约束 agent 行为" / "constrain agent behavior"
- "生成 AGENTS.md" / "generate AGENTS.md"
- "让任务自动跑" / "make this run until done"
- "设置 agent 约束" / "set up agent constraints"

## What it produces

A constraint system in the project root:
- `AGENTS.md` (~100-line navigation entry)
- Subdirectory `AGENTS.md` files (progressive disclosure)
- `scripts/check-*.sh` (mechanical enforcement, C1-C7 layers)
- `.githooks/pre-commit` + `.github/workflows/consistency.yml` (multi-gate CI)
- `TASKS.md`, `state/iteration.md`, `state/entropy-log.md`
- Methodology-specific scaffolding (`tests/`, `docs/specs/`, etc.)
- `README.md` appendage + `.gitignore` patch

The skill is **agent-neutral**. It does not generate tool-specific config files
(no `.opencode/`, no `.cursor/`, no `.codex/`). Any agents.md-compatible tool
reads `AGENTS.md` directly and follows the constraints expressed there + in the
generated check scripts.

## 7-step flow

1. Read `wizard/questions.md` and ask all 7 questions via AskUserQuestion (one message, parallel calls allowed for independent questions)
2. Read `wizard/decision-tree.md` to map answers → template paths
3. Read each selected template file
4. Read `templates/strict-mode.md` to determine exit-code behavior
5. Assemble root `AGENTS.md` using `templates/agents-root.md.tmpl` + selected concept/methodology blocks
6. Write subdir `AGENTS.md` files. Two groups, both required:
   - **Always-generated** (regardless of answers): render the three templates under
     `templates/scaffolding/always-dirs/` into `state/AGENTS.md`, `scripts/AGENTS.md`,
     and `docs/AGENTS.md`. These hold project-agnostic conventions and avoid C6
     false positives on day one.
   - **Methodology-specific** (per Q2): render `templates/agents-subdir.md.tmpl`
     once per methodology dir generated in step 7 (e.g., `docs/specs/AGENTS.md` for
     SDD, `tests/AGENTS.md` for TDD). These hold methodology-scoped rules.
7. Write `scripts/`, `.githooks/`, `.github/workflows/`, scaffolding/, `TASKS.md`, `state/`, `README.md` patch, `.gitignore` patch

After step 7, print `wizard/summary-format.md` rendered with answers; wait for `Y/n`
confirmation. Only write files after `Y`. (The "print summary and confirm" step is
not counted in the 7-step flow because it gates step 7 — files are not written
before confirmation.)

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
- DO NOT generate agent-specific config files (`.opencode/`, `.cursor/`, etc.). The harness is agent-neutral and depends only on the universal `AGENTS.md` contract.
- DO NOT generate files the user didn't select (Q4 multiSelect drives check script generation)
- DO NOT skip the confirmation step (the summary-printing gate before file writes)

## Extension

See `README.md` "Extension Guide" section. New methodologies/checks/languages follow the same progressive-loading pattern.
