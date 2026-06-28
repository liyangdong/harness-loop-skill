# AGENTS.md — knowledge-map skill

> Conventions for editing this skill. Agents working inside
> `.claude/skills/knowledge-map/` MUST follow this file. It mirrors the ≤100-line
> rule this skill imposes on its generated KNOWLEDGE.md (dogfood, see §6).

## 1. Skill purpose

This skill builds agent-first business knowledge bases from a code repo + its
deepwiki page. deepwiki supplies the conceptual skeleton + narrative; codegraph
supplies verified code anchors + call-paths + drift detection. Output: KNOWLEDGE.md
map index + per-domain knowledge files + drift.md + .meta/ provenance.

## 2. Map-not-manual

- `SKILL.md` stays ≤100 lines: triggers, entry points, pointers only.
- All prose detail lives in `wizard/` (questions, decision-tree, harvest-pipeline).
- All renderable content lives in `templates/` (knowledge-index, domain, drift, meta).
- This AGENTS.md stays ≤100 lines and is the single source of truth for *how to edit the skill*.

## 3. Two-stage model (critical)

- **Harvest** (live, agent): `wizard/harvest-pipeline.md` → `.meta/fragments/*` + `manifest.tsv` + `harvest-data.json`.
- **Render** (deterministic): `scripts/render-kb.sh` substitutes fragments into templates → KNOWLEDGE.md + domains/*.md + drift.md.
- L2 verification re-renders from committed fragments; never re-harvests.

## 4. Editing rules

| Change | Where to edit |
|---|---|
| Add a check layer | New `templates/checks/check-*.sh.tmpl` + row in harvest fragments if surfaced |
| Change render output | `templates/*.tmpl` (shell) OR `.meta/fragments/*` (content) — keep manifest in sync |
| Add a wizard question | `wizard/questions.md` + `wizard/decision-tree.md` together |
| Tune harvest extraction | `wizard/harvest-pipeline.md` only |
| Add a new KB section | New placeholder in a `.tmpl` + matching fragment in manifest + harvest step |

## 5. Self-verification

Before committing any change to this skill, run:

```bash
bash .claude/skills/knowledge-map/scripts/check-skill.sh
```

Do not commit on a failing check.

## 6. Dogfood

This file follows the same ≤100-line rule it imposes on generated KNOWLEDGE.md.
If you must exceed it, split detail into `wizard/` or `templates/` and leave a pointer.
