# knowledge-map

A project-level Claude Code skill that builds an **agent-first business knowledge
base** from a code repo + its [deepwiki](https://deepwiki.com) page. When invoked,
it fuses deepwiki's conceptual skeleton + narrative with [codegraph](https://github.com/coder/codegraph)-verified
code anchors + call-paths, then runs L1-L4 drift checks (orphans / blindspots).
Output is a `KNOWLEDGE.md` map index plus per-domain knowledge files, a `drift.md`
report, and `.meta/` provenance. Aligned with the [harness-loop](../harness-loop/)
sibling skill's map-not-manual conventions.

## When to invoke

Trigger the skill when the user says any of:

- "梳理业务知识地图" / "build a business knowledge map"
- "建知识库" / "建业务知识库" / "build a knowledge base"
- "codegraph + deepwiki" / "fuse deepwiki and codegraph"
- "让 agent 看懂这个大仓" / "make the agent understand this repo"
- "business knowledge map" / "build knowledge base from deepwiki"

Or when an existing repo lacks an agent-readable business map and the user wants
verified (not hallucinated) anchors between narrative and code.

## Quick start

Point the skill at a repo + its deepwiki page. Worked example: Apache Lucene.

> Use the knowledge-map skill to build a business knowledge map for
> `D:/project/lucene-main/lucene-main/lucene` — its deepwiki page is
> `https://deepwiki.com/apache/lucene`. Map the `core` and `queryparser`
> subsystems at medium depth, strict mode.

Claude will ask 7 questions, harvest deepwiki + verify anchors via codegraph,
then render the knowledge base. Full question list lives in
[`wizard/questions.md`](./wizard/questions.md); the live harvest contract in
[`wizard/harvest-pipeline.md`](./wizard/harvest-pipeline.md).

## The 7 wizard questions

| # | Question | Decides |
|---|---|---|
| 1 | 目标仓路径 (target repo path) | Where anchors resolve + where KB is written |
| 2 | deepwiki URL | Source of conceptual skeleton + narrative |
| 3 | codegraph projectPath | Graph used for anchor verification + drift analysis |
| 4 | 输出目录 (output dir, default `<repo>/docs/knowledge/`) | Where KNOWLEDGE.md + domains/ + drift.md land |
| 5 | 映射哪些顶层子系统 (multiSelect, runtime-populated from H1) | Which `domains/<subsystem>.md` files are generated |
| 6 | 深度 (shallow / medium / deep) | Whether concept clusters get own files (deep) or sections (medium) |
| 7 | 严格度 (advisory / strict) | Whether drift fails L4 or is reported as advisory only |

Full option lists for each question are in [`wizard/questions.md`](./wizard/questions.md).
Q5's options are populated dynamically from harvest step H1 (deepwiki root parse),
so they cannot be listed statically — the agent fetches the subsystem list first.

## Generated output overview

After the wizard, the chosen output dir (default `<repo>/docs/knowledge/`) holds:

```
<output-dir>/
├── KNOWLEDGE.md                  # ≤100-line map index (entry point)
├── domains/                      # per-subsystem knowledge files
│   ├── core.md                   # narrative + verified anchors + per-domain drift
│   └── queryparser.md            # only subsystems selected in Q5
├── drift.md                      # L4 drift report: orphans (deepwiki, no anchor) + blindspots (code, no narrative)
├── scripts/                      # in-target L1/L3/L4 checks (copied from templates/checks/)
│   ├── check-knowledge.sh        # L1 structural check (KNOWLEDGE.md shape, line count)
│   ├── check-anchors.sh          # L3 anchor liveness via codegraph (every anchor resolves)
│   └── check-drift.sh            # L4 drift re-run (orphans + blindspots within thresholds)
└── .meta/                        # provenance + render inputs
    ├── sources.json              # deepwiki pages fetched + timestamps + ETags
    ├── anchors.json              # code anchors + symbol IDs + verification status
    ├── harvest-data.json         # full harvest manifest (reproducibility)
    └── fragments/                # render-input markdown fragments (one per template placeholder)
```

The skill's own internal layout (wizard, templates, scripts, examples) lives in
`.claude/skills/knowledge-map/` and is documented in [`AGENTS.md`](./AGENTS.md).

## The two-stage model

Generation is split into **harvest** (live, agent-driven) and **render**
(deterministic, shell-driven). Harvest fetches deepwiki pages, verifies every
code anchor against codegraph, computes drift, and writes structured
`.meta/fragments/*` + a `manifest.tsv` + `harvest-data.json`. Render then
substitutes those fragments into `templates/*.tmpl` to emit `KNOWLEDGE.md`,
`domains/*.md`, and `drift.md`. The split exists so L2 verification can re-render
the committed fragments deterministically without re-fetching deepwiki or
re-querying codegraph — making the regression check hermetic and CI-safe.

## Verification

The skill ships four verification layers:

- **L1 — structural check** (`scripts/check-knowledge.sh` in target): KNOWLEDGE.md
  is ≤100 lines, every domain file exists, `.meta/` provenance is present.
- **L2 — render regression**: re-run `scripts/render-kb.sh` against committed
  `.meta/fragments/` and diff against committed KB files. Catches renderer drift.
  Hermetic — no network, no codegraph.
- **L3 — anchor liveness** (`scripts/check-anchors.sh`): every anchor in
  `domains/*.md` resolves to a live codegraph symbol. Requires codegraph.
- **L4 — drift report** (`scripts/check-drift.sh`): recompute orphans + blindspots;
  fail (strict, Q7) or warn (advisory) if above threshold. Requires codegraph.

CI runs L1 (`scripts/check-skill.sh`) + L2 (`scripts/check-examples.sh`) — hermetic,
no codegraph. Local dev additionally runs L3 (`scripts/check-anchors.sh`) + L4
(`scripts/check-drift.sh`); L3/L4 require the `codegraph` CLI + a populated
`.codegraph/` index at the path from Q3.

## Extension guide

### Add a domain section

1. Add a placeholder row to `templates/domain-knowledge.md.tmpl`.
2. Add a matching fragment filename to `.meta/` `manifest.tsv` (harvest step H5a).
3. Add a harvest extraction step in `wizard/harvest-pipeline.md` if the section
   needs a new data source.

### Add a check layer

1. Create `templates/checks/check-<name>.sh.tmpl`.
2. Register it in the harvest pipeline so it is copied into the target's
   `scripts/` and (if it surfaces drift) wired into `drift.md`.

### Add a new repo type

1. Add a deepwiki fetch adapter if the repo host is not GitHub (deepwiki URL shape
   may differ).
2. Confirm codegraph indexing works for the language (most do).
3. Add an example under `examples/<repo>/` with a committed `answers.json` +
   expected KB snapshot for L2 regression.

See [`AGENTS.md`](./AGENTS.md) §4 for the full editing table.

## References

- Design spec: [`docs/superpowers/specs/2026-06-28-knowledge-map-skill-design.md`](../../../docs/superpowers/specs/2026-06-28-knowledge-map-skill-design.md)
- Implementation plan: [`docs/superpowers/plans/2026-06-28-knowledge-map-skill.md`](../../../docs/superpowers/plans/2026-06-28-knowledge-map-skill.md)
- deepwiki: <https://deepwiki.com>
- codegraph: <https://github.com/coder/codegraph>
- Sibling skill: [`harness-loop`](../harness-loop/README.md)
