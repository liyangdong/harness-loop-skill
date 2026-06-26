# Wizard doesn't generate state/, scripts/, docs/ AGENTS.md by default

## Summary

The harness-loop wizard currently generates subdir `AGENTS.md` files only for methodology-specific directories (e.g., `docs/specs/AGENTS.md` for SDD, `tests/AGENTS.md` for TDD). But the C6 check expects `state/`, `scripts/`, and `docs/` to also have AGENTS.md files (they're universally expected in any harness-loop project). This causes C6 to flag false positives on freshly-generated projects.

## How to reproduce

1. Invoke the harness-loop skill on any new project
2. After generation completes, run `bash scripts/check-consistency.sh`
3. Observe: C6 reports missing AGENTS.md in `state/`, `scripts/`, `docs/`

## Workaround

Manually create `state/AGENTS.md`, `scripts/AGENTS.md`, `docs/AGENTS.md` after running the wizard. The dogfood (commit `0824420`) did this manually.

## Suggested fix

Update `wizard/decision-tree.md` to add an "always-generated" set of subdir AGENTS.md files, separate from the methodology-specific ones:

| Always generated | Path | Content |
|---|---|---|
| (all projects) | `state/AGENTS.md` | state file purposes + read/write rules |
| (all projects) | `scripts/AGENTS.md` | check script conventions + how to add new checks |
| (all projects with docs/) | `docs/AGENTS.md` | documentation conventions |

Add corresponding templates under `templates/scaffolding/always-dirs/`:
- `state-agents.md.tmpl`
- `scripts-agents.md.tmpl`
- `docs-agents.md.tmpl`

Update the wizard flow (SKILL.md step 6) to always emit these regardless of Q2 answer.

## Acceptance criteria

- [ ] 3 new templates in `templates/scaffolding/always-dirs/`
- [ ] Decision-tree updated with always-generated section
- [ ] SKILL.md step 6 mentions always-generated AGENTS.md files
- [ ] All 3 example snapshots regenerated to include these files
- [ ] C6 passes on freshly-generated projects without manual intervention
- [ ] Existing dogfood project on this repo: state/AGENTS.md, scripts/AGENTS.md, docs/AGENTS.md tracked in git (currently they exist but as one-offs)

## Priority

Medium — every harness-loop user hits this on first run.

## Found by

Dogfood of the skill on its own host project (commit `0824420`).
