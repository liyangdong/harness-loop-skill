---
name: knowledge-map
description: Use when the user wants to build a business/domain knowledge map or knowledge base for a code repository by fusing deepwiki's conceptual structure with codegraph's verified code anchors. Triggers include "梳理业务知识地图", "建知识库", "建业务知识库", "codegraph + deepwiki 建索引", "让 agent 看懂这个大仓", "business knowledge map", "build knowledge base from deepwiki".
---

# Knowledge-Map Skill

Generate an agent-first business knowledge base from a code repo + its deepwiki
page. deepwiki supplies the conceptual skeleton + narrative; codegraph supplies
verified code anchors + call-paths + drift detection (orphans/blindspots). Aligned
with the harness-loop sibling skill's map-not-manual conventions.

## When to invoke

User says any of:
- "梳理业务知识地图" / "build a business knowledge map"
- "建知识库" / "build a knowledge base"
- "codegraph + deepwiki 建索引" / "fuse deepwiki and codegraph"
- "让 agent 看懂这个大仓" / "make the agent understand this repo"

## What it produces

A knowledge base at the chosen output dir (default `<repo>/docs/knowledge/`):
- `KNOWLEDGE.md` (≤100-line map index)
- `domains/<subsystem>.md` (per-domain knowledge: narrative + anchors + drift)
- `drift.md` (L4 drift report: orphans + blindspots)
- `.meta/{sources,anchors,harvest-data}.json` + `.meta/fragments/` (provenance + render input)
- in-target `scripts/check-knowledge.sh` + `check-anchors.sh` + `check-drift.sh` (L1/L3/L4)

## Two-stage flow

1. **Harvest** (live): read `wizard/harvest-pipeline.md` — fetch deepwiki, verify anchors via codegraph, write `.meta/fragments/*` + `manifest.tsv` + `harvest-data.json`
2. **Render** (deterministic): run `scripts/render-kb.sh <fragments-dir> <output-dir>` — substitutes fragments into `templates/*.tmpl` → KB files

## 7-step flow

1. Read `wizard/questions.md`, ask Q1-Q4 (repo / deepwiki URL / projectPath / output dir)
2. Harvest step H1: fetch deepwiki root, parse subsystem list
3. Ask Q5 (multiSelect, populated from H1) + Q6 (depth) + Q7 (strictness)
4. Harvest steps H2-H4: per selected subsystem — fetch deep-dive, verify anchors via codegraph, drift analysis
5. Harvest step H5a: write `.meta/fragments/*` + `manifest.tsv` + `harvest-data.json` + `sources.json` + `anchors.json`
6. Render step H5b: run `scripts/render-kb.sh` to emit KNOWLEDGE.md + domains/*.md + drift.md
7. Print `wizard/summary-format.md` summary; wait for `Y/n`. Only write after `Y`.

## Progressive loading

- Only deepwiki subsystems the user selected (Q5) are fetched
- Depth (Q6) controls whether concept clusters get own files (deep) or sections (medium)

## Templates index

- `templates/knowledge-index.md.tmpl` — KNOWLEDGE.md shell
- `templates/domain-knowledge.md.tmpl` — per-domain file shell
- `templates/drift-report.md.tmpl` — drift.md shell
- `templates/checks/*.sh.tmpl` — in-target L1/L3/L4 check scripts

## Anti-patterns

- DO NOT inline template content into SKILL.md (violates map-not-manual)
- DO NOT re-harvest during L2 — L2 renders committed fragments only
- DO NOT skip the Y/n confirmation before writing
- DO NOT generate domains the user didn't select (Q5 drives domain count)
