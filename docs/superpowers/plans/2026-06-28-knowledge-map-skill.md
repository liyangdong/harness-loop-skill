# Knowledge-Map Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a project-level skill `knowledge-map` that, via a 7-question wizard + a deepwiki/codegraph harvest pipeline, generates an agent-first business knowledge base (map index + per-domain knowledge files + drift report) for any repo that has a deepwiki page, with Lucene as the worked L2 baseline.

**Architecture:** Skill = wizard logic + harvest playbook + deterministic renderer + progressive template library. SKILL.md is a thin ≤100-line index pointing to `wizard/` (logic), `templates/` (content), and `scripts/` (verification). Two-stage generation: (1) **harvest** — an agent playbook fetches deepwiki + verifies anchors via codegraph, emitting markdown fragments + structured `.meta/`; (2) **render** — `render-kb.sh` deterministically substitutes fragments into templates to emit the KB. This split makes L2 (render+diff) a real automated test with no external dependencies.

**Tech Stack:** Markdown + Bash (Git Bash on Windows) + JSON (anchors/sources/fragments manifest). Templates use `{{PLACEHOLDER}}` Mustache-style substitution. codegraph (`codegraph explore` shell) + webReader as harvest-time data sources. jq NOT required — rendering uses pure sed/cat over a TSV manifest.

**Spec:** `docs/superpowers/specs/2026-06-28-knowledge-map-skill-design.md`

---

## File Structure

All paths relative to project root (`D:\project\harness+loop\`). Skill lands at `.claude/skills/knowledge-map/`.

```
.claude/skills/knowledge-map/
├── SKILL.md                           # Entry index (≤100 lines)
├── README.md                          # User docs for the skill
├── AGENTS.md                          # Skill's own constraints (dogfood, ≤100 lines)
├── wizard/
│   ├── AGENTS.md                      # wizard/ conventions
│   ├── questions.md                   # 7-question script
│   ├── decision-tree.md               # answers → depth/strictness/output paths
│   ├── harvest-pipeline.md            # H1-H5 deepwiki+codegraph playbook (the core)
│   └── summary-format.md              # config summary format
├── templates/
│   ├── AGENTS.md                      # templates/ conventions + fragment model
│   ├── knowledge-index.md.tmpl        # KNOWLEDGE.md shell (≤100 rendered lines)
│   ├── domain-knowledge.md.tmpl       # per-domain knowledge file shell
│   ├── drift-report.md.tmpl           # drift.md shell
│   ├── meta-sources.json.tmpl         # .meta/sources.json shell
│   ├── meta-anchors.json.tmpl         # .meta/anchors.json shell
│   └── checks/
│       ├── AGENTS.md
│       ├── check-knowledge.sh.tmpl    # in-target L1 static check
│       ├── check-anchors.sh.tmpl      # in-target L3 anchor resolution
│       └── check-drift.sh.tmpl        # in-target L4 drift detection
├── scripts/                           # skill's own verification + renderer
│   ├── render-kb.sh                   # deterministic renderer (the L2 engine)
│   ├── check-skill.sh                 # L1: skill self static check
│   ├── check-examples.sh              # L2: render fragments → diff vs example
│   ├── check-anchors.sh               # L3: wraps codegraph on example anchors
│   └── check-drift.sh                 # L4: orphan/blindspot recompute on example
└── examples/
    ├── AGENTS.md
    └── lucene/                        # L2 diff baseline
        ├── answers.json               # Q1-Q7 answer snapshot
        ├── KNOWLEDGE.md               # rendered (committed)
        ├── domains/{indexing,search,analysis,index-data-structures,build-release}.md
        ├── drift.md                   # rendered (committed)
        └── .meta/
            ├── sources.json
            ├── anchors.json
            ├── harvest-data.json      # structured provenance (for L3/L4)
            └── fragments/             # markdown fragments + manifest.tsv (render input)
```

**Responsibility split:**
- `SKILL.md` = the only file the agent reads on invocation; everything else loads on demand
- `wizard/` = logic (what to ask, how to harvest, how to map answers)
- `templates/` = content (what to render)
- `scripts/render-kb.sh` = deterministic harvest-output → KB renderer (no external deps)
- `scripts/check-*.sh` = self-verification of the skill itself (L1-L4)
- `examples/lucene/` = regression baseline (committed fragments + rendered output)

---

## Two-Stage Generation Model (lock this in before Task 7)

The spec's §6 H5 ("assemble") is concretized as two stages so L2 is mechanically testable:

**Stage 1 — Harvest (live, agent-driven, non-deterministic):** the `wizard/harvest-pipeline.md` playbook fetches deepwiki, verifies anchors via codegraph, and writes:
- `.meta/fragments/*.md` and `*.txt` — one pre-rendered markdown fragment per variable section
- `.meta/fragments/manifest.tsv` — TSV mapping `(scope, [id], placeholder) → fragment-path`
- `.meta/harvest-data.json` — structured provenance (domains, concepts, anchors with status/callPath/callerCount, drift) — consumed by L3/L4
- `.meta/sources.json`, `.meta/anchors.json` — also written directly by harvest

**Stage 2 — Render (deterministic, `render-kb.sh`, no external deps):** reads `manifest.tsv`, substitutes each fragment into the matching template placeholder via `sed`, writes:
- `KNOWLEDGE.md` from `knowledge-index.md.tmpl` (global placeholders)
- `domains/<id>.md` from `domain-knowledge.md.tmpl` per domain (domain-scoped placeholders)
- `drift.md` from `drift-report.md.tmpl` (drift placeholders)

**L2 = run `render-kb.sh` on the example's committed `.meta/fragments/` → `diff` vs committed rendered output.** Same fragments + same templates → identical bytes. External deepwiki/code drift shows up as fragment changes (handled by spec §8.2 snapshot-refresh), not as render nondeterminism.

### Fragment manifest format (`manifest.tsv`)

Tab-separated, one row per placeholder. `#` lines are comments.

```
# scope	id	<placeholder-tabs vary by scope>
global		MISSION	fragments/overview-mission.md
global		TOPOLOGY	fragments/knowledge-topology.md
global		DRIFT_SUMMARY	fragments/drift-summary.md
global		ENTRY_POINTS	fragments/entry-points.md
global		PROJECT_STRUCTURE	fragments/overview-structure.md
global		REGEN_NOTE	fragments/regen-note.md
drift		REGEN_TIMESTAMP	fragments/regen-timestamp.txt
drift		ORPHANS_TABLE	fragments/orphans-table.md
drift		BLINDSPOTS_TABLE	fragments/blindspots-table.md
domain	indexing	DOMAIN_NAME	fragments/indexing-name.txt
domain	indexing	DEEPWIKI_URL	fragments/indexing-url.txt
domain	indexing	STATUS	fragments/indexing-status.txt
domain	indexing	NARRATIVE	fragments/indexing-narrative.md
domain	indexing	CONCEPTS	fragments/indexing-concepts.md
domain	indexing	ANCHORS_TABLE	fragments/indexing-anchors.md
domain	indexing	DOMAIN_DRIFT	fragments/indexing-drift.md
domain	indexing	CROSS_LINKS	fragments/indexing-crosslinks.md
```

Field counts per scope:
- `global`: `global` `\t` `` (empty id) `\t` `PLACEHOLDER` `\t` `path` → 4 columns
- `drift`: same shape as global → 4 columns
- `domain`: `domain` `\t` `<id>` `\t` `PLACEHOLDER` `\t` `path` → 4 columns

So every row is 4 tab-separated columns: `scope \t id \t placeholder \t path`. (`id` is empty for global/drift.)

---

## Conventions Used Throughout

- **Template placeholders:** `{{VARIABLE}}` — rendered by `render-kb.sh` via `sed` substitution from manifest fragments
- **Strict mode flag:** all `check-*.sh.tmpl` read `{{STRICT_MODE}}` → `strict` = exit 1 on failure; `advisory` = warn + exit 0
- **Lint error format:** every check emits `❌ <check-id> <message>` + `   修复: <fix instruction>` (harness-engineering requirement)
- **Line counts:** `SKILL.md` and subdir `AGENTS.md` files stay ≤100 lines (S4 check); `KNOWLEDGE.md` rendered output ≤100 lines (S1 check)
- **Paths:** all check scripts resolve paths relative to the KB output dir (or skill dir for skill self-checks)

---

## Phase 1: Foundation

### Task 1: Directory scaffold + skill AGENTS.md

**Files:**
- Create: `.claude/skills/knowledge-map/AGENTS.md`
- Create: `.claude/skills/knowledge-map/README.md`

- [ ] **Step 1: Create directory tree**

```bash
cd "D:/project/harness+loop"
mkdir -p .claude/skills/knowledge-map/{wizard,templates/checks,scripts,examples/lucene/{domains,.meta/fragments}}
```

Verify: `find .claude/skills/knowledge-map -type d | wc -l` should output `8`.

- [ ] **Step 2: Write `.claude/skills/knowledge-map/AGENTS.md`**

Content (≤100 lines): the skill's own conventions. Write this exact body:

```markdown
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
```

- [ ] **Step 3: Write `.claude/skills/knowledge-map/README.md`**

Content (~120 lines): skill documentation for human readers. Sections:
1. **What it does** (2-3 sentences): "Given a code repo + its deepwiki page, generates an agent-first business knowledge base: deepwiki skeleton + codegraph-verified anchors + L1-L4 drift checks."
2. **When to invoke** (trigger keywords: "梳理业务知识地图", "建知识库", "codegraph + deepwiki", "让 agent 看懂这个大仓")
3. **Quick start** (example: invoke on lucene)
4. **The 7 wizard questions** (summary table — point to `wizard/questions.md`)
5. **Generated output overview** (file tree from spec §7)
6. **The two-stage model** (harvest → render, one paragraph)
7. **Verification** (how to run L1/L2/L3/L4; note CI=L1+L2, local=L1-L4)
8. **Extension guide** (how to add a domain section, a check layer, a new repo type)
9. **References** (link to spec, deepwiki, codegraph, harness-loop sibling skill)

Write the actual prose for each section. Do NOT leave section headers empty.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/knowledge-map/AGENTS.md .claude/skills/knowledge-map/README.md
git commit -m "feat(skill): scaffold knowledge-map skill directory + metadata"
```

---

### Task 2: SKILL.md (entry index ≤100 lines)

**Files:**
- Create: `.claude/skills/knowledge-map/SKILL.md`

- [ ] **Step 1: Write SKILL.md with frontmatter + ≤100-line body**

```markdown
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
```

- [ ] **Step 2: Verify frontmatter parses**

Run: `head -4 .claude/skills/knowledge-map/SKILL.md`
Expected: line 1 `---`, line 2 `name: knowledge-map`, line 3 starts with `description:`, line 4 `---`.

- [ ] **Step 3: Verify line count ≤100**

Run: `wc -l .claude/skills/knowledge-map/SKILL.md`
Expected: ≤100.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/knowledge-map/SKILL.md
git commit -m "feat(skill): add SKILL.md entry index"
```

---

## Phase 2: Wizard

### Task 3: wizard/AGENTS.md + wizard/questions.md

**Files:**
- Create: `.claude/skills/knowledge-map/wizard/AGENTS.md`
- Create: `.claude/skills/knowledge-map/wizard/questions.md`

- [ ] **Step 1: Write `wizard/AGENTS.md`**

Content (~45 lines): conventions for the wizard/ directory.
- Purpose: defines the 7-question AskUserQuestion sequence + the harvest playbook
- Rule: `questions.md` must be readable as a standalone script
- Rule: Q5 options are populated at runtime from H1 (deepwiki root) — not hardcoded
- Rule: any new question must also update `decision-tree.md`
- Rule: max 7 questions (cognitive load limit)
- Rule: free-text questions (Q1-Q4) use AskUserQuestion with a typed free-text answer

Write the actual prose for each rule.

- [ ] **Step 2: Write `wizard/questions.md`**

Content (~200 lines): the 7 questions, each formatted as an AskUserQuestion spec. Write all 7 in this format per question:

```markdown
## Q1: 目标仓路径 (repo_path)

**Type:** free-text
**AskUserQuestion call:**
- question: "目标代码仓的本地路径是什么？（codegraph 应已建索引）"
- header: "仓路径"
- free-text answer, e.g. `D:/project/lucene-main/lucene-main/lucene`

**Dependencies:** none (always asked first)
**Used by:** H1 (output root), H3 (codegraph projectPath default)
```

Write all 7 (Q1-Q7) with full specs. Use spec §5 as the source:

- **Q1 目标仓路径** (free-text) — e.g. `D:/project/lucene-main/lucene-main/lucene`
- **Q2 deepwiki URL** (free-text) — e.g. `https://deepwiki.com/apache/lucene`
- **Q3 codegraph projectPath** (free-text, default = Q1) — must have `.codegraph/`
- **Q4 输出目录** (free-text, default `<repo>/docs/knowledge/`) — example mode: skill's `examples/lucene/`
- **Q5 映射哪些顶层子系统** (multiSelect) — options populated at runtime from H1 parsed subsystem list; default all selected
- **Q6 深度** (single-select) — shallow / medium(recommended) / deep
- **Q7 严格度** (single-select) — advisory(recommended) / strict

For Q5, explicitly note: "Ask Q5 ONLY after H1 has run. Build the option list from the subsystems parsed out of the deepwiki root page. If H1 fails to parse, fall back to a single free-text option 'manual subsystem list'."

- [ ] **Step 3: Verify all 7 questions are present**

Run: `grep -c "^## Q[0-9]" .claude/skills/knowledge-map/wizard/questions.md`
Expected: `7`.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/knowledge-map/wizard/AGENTS.md .claude/skills/knowledge-map/wizard/questions.md
git commit -m "feat(wizard): add questions.md and wizard conventions"
```

---

### Task 4: wizard/decision-tree.md + wizard/summary-format.md

**Files:**
- Create: `.claude/skills/knowledge-map/wizard/decision-tree.md`
- Create: `.claude/skills/knowledge-map/wizard/summary-format.md`

- [ ] **Step 1: Write `wizard/decision-tree.md`**

Content (~120 lines): maps answers to harvest/render behavior. Structure:

```markdown
# Decision Tree: answers → behavior

## Q5 → domains harvested + rendered

Each selected subsystem becomes one domain. Domain id = kebab-case of subsystem name:
- "Indexing System" → `indexing`
- "Search System" → `search`
- "Index Data Structures" → `index-data-structures`
- "Analysis System" → `analysis`
- "Build and Release System" → `build-release`

For each: H2 fetches deepwiki `<root>/<id-slug>`, H3 verifies its anchors, H5 writes
`domains/<id>.md` + matching `.meta/fragments/<id>-*`.

## Q6 → render shape

| Q6 answer | Domain file shape |
|---|---|
| shallow | domains/<id>.md has narrative + anchor list as a flat section |
| medium | domains/<id>.md has narrative + per-concept-cluster sections each with anchor table |
| deep | each concept cluster becomes its own domains/<id>/<cluster>.md (sub-dir) |

Default: medium. Fragment count scales with depth.

## Q7 → check script strictness

| Q7 answer | {{STRICT_MODE}} in check-*.sh.tmpl |
|---|---|
| strict | "strict" (set -e semantics, exit 1 on failure) |
| advisory | "advisory" (warn + exit 0) |

## Q3 → codegraph availability

| Condition | Behavior |
|---|---|
| `.codegraph/` exists at projectPath | H3 verifies anchors; L3/L4 enabled |
| `.codegraph/` missing | H3 marks all anchors UNVERIFIED; warn user to index; L3/L4 skip with warning |

## Q4 → output location

| Mode | Output dir |
|---|---|
| real run | `<Q4>` (default `<repo>/docs/knowledge/`) |
| example/baseline | `.claude/skills/knowledge-map/examples/<repo-name>/` |
```

- [ ] **Step 2: Write `wizard/summary-format.md`**

Content (~50 lines): the config summary printed before writing files.

```markdown
# Config Summary Format

After collecting Q1-Q7 and running H1 (so subsystem count is known), render this
and print to the user. Wait for Y/n before any writes.

## Template

```
📋 即将生成业务知识库：

**目标仓**: {{Q1}}
**deepwiki**: {{Q2}}
**codegraph projectPath**: {{Q3}}
**输出目录**: {{Q4}}
**映射子系统**: {{Q5_list}} ({{count}} 个 domain)
**深度**: {{Q6}}
**严格度**: {{Q7}}
**预计锚点数**: {{anchor_count_estimate}}

**将创建的文件**:
- KNOWLEDGE.md
- domains/<id>.md × {{count}}
- drift.md
- .meta/{sources,anchors,harvest-data}.json + .meta/fragments/*
- scripts/check-knowledge.sh + check-anchors.sh + check-drift.sh (in-target)

继续？(Y/n)
```

## Rules

- Subsystem list + count come from H1 (already run)
- After Y: run H2-H5 + render
- After n: abort without writing anything
```

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/knowledge-map/wizard/decision-tree.md .claude/skills/knowledge-map/wizard/summary-format.md
git commit -m "feat(wizard): add decision tree and summary format"
```

---

### Task 5: wizard/harvest-pipeline.md (the core playbook)

**Files:**
- Create: `.claude/skills/knowledge-map/wizard/harvest-pipeline.md`

- [ ] **Step 1: Write `wizard/harvest-pipeline.md`**

Content (~220 lines): the H1-H5 playbook the executing agent follows at harvest time. Write full prose for each step. This is the skill's intellectual core — be concrete and complete.

```markdown
# Harvest Pipeline (H1-H5)

> The live, agent-driven extraction that turns deepwiki + codegraph into render
> fragments. Non-deterministic by nature (live sources) — that's why its output is
> committed as fragments and re-rendered deterministically by `scripts/render-kb.sh`.

## Conventions

- Use `webReader` (MCP) to fetch deepwiki pages as markdown
- Use `codegraph_explore` (MCP, with `projectPath`) OR shell `codegraph explore "<symbols>"` to verify anchors
- Every extracted citation has shape `<repo-relative-path>:<line>` or `<path>:<line>-<line>`
- Write all harvest output under `<output>/.meta/`
- Timestamps: obtain from the host (do NOT call Date.now inside tooling); record once in `sources.json.generatedAt` and `fragments/regen-timestamp.txt`

## H1 — Fetch deepwiki root, parse subsystem skeleton

1. `webReader({{Q2}})` → root markdown
2. Parse the subsystem taxonomy:
   - Find `## Major Subsystems` (or nearest equivalent H2)
   - Under it, each `### <Name>` is a top-level subsystem
   - For each, capture the "See detailed documentation: <Name>" link → subsystem deep-dive URL
3. Parse per-subsystem Core Classes with their `(path:line)` citations
4. Parse the repo Overview mission + Project Structure table
5. Output to `.meta/harvest-data.json`:
   - `overview.mission`, `overview.projectStructure`
   - `domains[].{id,name,deepwikiUrl,coreClasses:[{symbol,location,citedLine}]}`
6. **Return the subsystem list to the wizard** — this populates Q5 options.

If the `## Major Subsystems` heading is absent: set a parse-failure flag, surface a
single free-text Q5 fallback ("manual subsystem list"), and let the user type domain names.

## H2 — Fetch each selected subsystem's deep-dive page

For each subsystem in Q5's selection:
1. `webReader(<subsystem deep-dive URL>)` → markdown
2. Parse concept clusters (the H3/H4 subsections under the subsystem)
3. For each concept cluster, capture its narrative + its `Sources: path:line ...` citations
4. Append to `harvest-data.json` under `domains[].concepts[].{name,description,citations}`

## H3 — Verify every citation via codegraph

For each citation `(symbol, location, citedLine)` collected in H1/H2:
1. Query `codegraph explore "<symbol>"` with `projectPath={{Q3}}`
2. Classify the anchor:
   - **RESOLVED**: the symbol exists; record its current file + the call-path summary codegraph returns + callerCount (blast-radius caller count)
   - **STALE**: the file exists but the symbol's line has shifted (symbol resolvable, citedLine drifts beyond the symbol's body)
   - **MISSING**: file or symbol not found in the index
   - **UNVERIFIED**: `.codegraph/` missing → record as-is, status UNVERIFIED
3. Write to `harvest-data.json`: `domains[].anchors[].{concept,symbol,location,citedLine,status,callPath,callerCount}`

Aggregate every anchor (all domains) into `.meta/anchors.json` (flat array) for L3/L4.

## H4 — Drift analysis

Recompute from `harvest-data.json`:

- **orphans**: concept clusters whose citations are ALL (MISSING|STALE|UNVERIFIED) → "deepwiki says it but code can't confirm". Record `{concept, domain, reason}`.
- **blindspots**: for each selected subsystem's Core Classes, take codegraph blast-radius callerCount; symbols with high callerCount (> threshold, default 20) that are NOT cited by any deepwiki concept cluster → "code has it but deepwiki didn't cover it". Record `{symbol, location, callerCount, suggestedDomain}`.

Write `harvest-data.json.drift.{orphans[], blindspots[]}`.

## H5a — Write render fragments + manifest

Convert `harvest-data.json` into pre-rendered markdown fragments under `.meta/fragments/`
and a `manifest.tsv` (format: 4 tab-separated columns `scope \t id \t placeholder \t path`).

Write ONE fragment file per variable section:
- Global: `overview-mission.md`, `overview-structure.md`, `knowledge-topology.md` (the domain→concept→file map), `drift-summary.md`, `entry-points.md`, `regen-note.md`
- Drift: `regen-timestamp.txt`, `orphans-table.md`, `blindspots-table.md`
- Per domain `<id>`: `<id>-name.txt`, `<id>-url.txt`, `<id>-status.txt` (verified|partial|drifted, derived from anchor statuses), `<id>-narrative.md`, `<id>-concepts.md`, `<id>-anchors.md` (the anchor table markdown), `<id>-drift.md` (this domain's orphan/blindspot lines), `<id>-crosslinks.md`

Write `manifest.tsv` enumerating every fragment with its scope+id+placeholder (see plan "Fragment manifest format").

Also write `.meta/sources.json` (repo/deepwikiRoot/projectPath/generatedAt/depth/strict) and finalize `.meta/anchors.json`.

## H5b — Render

Run the deterministic renderer:

```bash
bash <skill>/scripts/render-kb.sh <output>/.meta/fragments <output>
```

This emits `KNOWLEDGE.md`, `domains/<id>.md` (per Q5 subsystem), `drift.md` from the templates + fragments.

## Fragment rendering rules (must match render-kb.sh exactly)

- Anchor table row format: `| <concept> | <symbol> | <location>:<line> | <status-emoji> | <callPath> |`
  - status-emoji: RESOLVED→✅, STALE→⚠️, MISSING→❌, UNVERVED→❓
- Domain status derivation: all anchors RESOLVED → `verified`; any STALE → `partial`; any MISSING/orphan → `drifted`
- Topology line per domain: `- **<name>** → domains/<id>.md — <cluster-count> concept clusters, <anchor-count> anchors (<resolved-count>✅)`
- Cross-links: a domain links to other domains whose Core Classes appear in its callPath
```

- [ ] **Step 2: Verify H1-H5 sections present**

Run: `grep -c "^## H[0-9]" .claude/skills/knowledge-map/wizard/harvest-pipeline.md`
Expected: `5` (H1, H2, H3, H4, H5a, H5b count as H5 — accept ≥5; H5a/H5b are `###` under H5, so `^## H` matches H1-H5 = 5).

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/knowledge-map/wizard/harvest-pipeline.md
git commit -m "feat(wizard): add H1-H5 harvest pipeline playbook"
```

---

## Phase 3: Templates

### Task 6: templates/AGENTS.md + knowledge-index.md.tmpl + domain-knowledge.md.tmpl

**Files:**
- Create: `.claude/skills/knowledge-map/templates/AGENTS.md`
- Create: `.claude/skills/knowledge-map/templates/knowledge-index.md.tmpl`
- Create: `.claude/skills/knowledge-map/templates/domain-knowledge.md.tmpl`

- [ ] **Step 1: Write `templates/AGENTS.md`**

Content (~60 lines): conventions for templates/ + the fragment model.
- All `.tmpl` files contain `{{PLACEHOLDER}}` tokens replaced by `render-kb.sh` from manifest fragments
- Placeholders map 1:1 to fragment files via `manifest.tsv`
- Global placeholders: `{{MISSION}} {{PROJECT_STRUCTURE}} {{TOPOLOGY}} {{DRIFT_SUMMARY}} {{ENTRY_POINTS}} {{REGEN_NOTE}}`
- Domain placeholders (rendered per domain): `{{DOMAIN_NAME}} {{DEEPWIKI_URL}} {{STATUS}} {{NARRATIVE}} {{CONCEPTS}} {{ANCHORS_TABLE}} {{DOMAIN_DRIFT}} {{CROSS_LINKS}}`
- Drift placeholders: `{{REGEN_TIMESTAMP}} {{ORPHANS_TABLE}} {{BLINDSPOTS_TABLE}}`
- `knowledge-index.md.tmpl` renders to ≤100 lines (fragments must be terse)
- No template exceeds 60 lines of shell (fragments carry the content)

Write the actual prose for each rule.

- [ ] **Step 2: Write `knowledge-index.md.tmpl`**

```markdown
# {{REPO_NAME}} — 业务知识地图

{{MISSION}}

## 地图拓扑

{{TOPOLOGY}}

## 两大入口

{{ENTRY_POINTS}}

## 整体漂移

{{DRIFT_SUMMARY}}

（详见 `drift.md`；`✅` = 锚点经 codegraph 验证，`❓` = 未验证）

## 模块组织

{{PROJECT_STRUCTURE}}

## 再生

{{REGEN_NOTE}}
```

Note: `{{REPO_NAME}}` is a static placeholder substituted by `render-kb.sh` from `sources.json` repo basename (not a fragment — see Task 9 render logic). The index must render ≤100 lines; fragments stay terse.

- [ ] **Step 3: Write `domain-knowledge.md.tmpl`**

```markdown
---
domain: {{DOMAIN_NAME}}
deepwiki: {{DEEPWIKI_URL}}
status: {{STATUS}}
---

# {{DOMAIN_NAME}}

## 业务说明

{{NARRATIVE}}

## 核心概念簇

{{CONCEPTS}}

## 代码锚点

{{ANCHORS_TABLE}}

## 漂移标记

{{DOMAIN_DRIFT}}

## 交叉链接

{{CROSS_LINKS}}
```

- [ ] **Step 4: Verify placeholders match manifest vocabulary**

Run: `grep -oE '{{[A-Z_]+}}' .claude/skills/knowledge-map/templates/*.tmpl | sort -u`
Expected: every placeholder listed in `templates/AGENTS.md` §placeholder vocabulary appears.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/knowledge-map/templates/AGENTS.md .claude/skills/knowledge-map/templates/knowledge-index.md.tmpl .claude/skills/knowledge-map/templates/domain-knowledge.md.tmpl
git commit -m "feat(templates): add AGENTS, knowledge-index, domain-knowledge templates"
```

---

### Task 7: drift-report.md.tmpl + meta-sources.json.tmpl + meta-anchors.json.tmpl

**Files:**
- Create: `.claude/skills/knowledge-map/templates/drift-report.md.tmpl`
- Create: `.claude/skills/knowledge-map/templates/meta-sources.json.tmpl`
- Create: `.claude/skills/knowledge-map/templates/meta-anchors.json.tmpl`

- [ ] **Step 1: Write `drift-report.md.tmpl`**

```markdown
# 漂移报告

> regenerated: {{REGEN_TIMESTAMP}}
> orphan = deepwiki 有概念但代码锚点全失效（说了但找不到）
> blindspot = 高中心度代码符号未被 deepwiki 覆盖（代码有但没说）

## Orphans（deepwiki 说了但代码找不到）

{{ORPHANS_TABLE}}

## Blindspots（代码有但 deepwiki 没说）

{{BLINDSPOTS_TABLE}}

## 处理建议

- orphan: 核对 deepwiki 引用的行号是否过期，或该概念是否已重构；更新锚点或从 deepwiki 侧订正
- blindspot: 评估是否应在对应 domain 补一段说明，或确认它是实现细节无需文档化
```

- [ ] **Step 2: Write `meta-sources.json.tmpl`**

```json
{
  "repo": "{{REPO_PATH}}",
  "repoName": "{{REPO_NAME}}",
  "deepwikiRoot": "{{DEEPWIKI_ROOT}}",
  "projectPath": "{{PROJECT_PATH}}",
  "generatedAt": "{{GENERATED_AT}}",
  "depth": "{{DEPTH}}",
  "strict": "{{STRICT_MODE}}",
  "domains": [{{DOMAIN_IDS}}]
}
```

Note: `{{REPO_PATH}} {{REPO_NAME}} {{DEEPWIKI_ROOT}} {{PROJECT_PATH}} {{GENERATED_AT}} {{DEPTH}} {{STRICT_MODE}} {{DOMAIN_IDS}}` are static placeholders substituted by `render-kb.sh` from `sources.json` (which H5a writes directly, not as a fragment — sources.json IS the source of these values).

- [ ] **Step 3: Write `meta-anchors.json.tmpl`**

```json
{
  "projectPath": "{{PROJECT_PATH}}",
  "generatedAt": "{{GENERATED_AT}}",
  "anchors": [{{ANCHORS_ARRAY}}]
}
```

Note: `{{ANCHORS_ARRAY}}` is substituted by `render-kb.sh` from the committed `harvest-data.json` anchors (flattened). In practice H5a writes `anchors.json` directly (it's structured JSON, not prose), so this template is a reference shell — `render-kb.sh` copies H5a's `anchors.json` verbatim. Document this in `templates/AGENTS.md`: "meta-anchors.json.tmpl and meta-sources.json.tmpl are reference shells; H5a writes the actual .meta/anchors.json and .meta/sources.json directly. render-kb.sh does NOT regenerate them."

- [ ] **Step 4: Update `templates/AGENTS.md` with the meta exception**

Add a line to the conventions written in Task 6: "`.meta/sources.json` and `.meta/anchors.json` are written directly by H5a (structured JSON), not rendered from templates. The `.tmpl` files in templates/ are reference shells documenting their shape."

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/knowledge-map/templates/drift-report.md.tmpl .claude/skills/knowledge-map/templates/meta-sources.json.tmpl .claude/skills/knowledge-map/templates/meta-anchors.json.tmpl .claude/skills/knowledge-map/templates/AGENTS.md
git commit -m "feat(templates): add drift-report and meta reference shells"
```

---

### Task 8: templates/checks/AGENTS.md + in-target check script templates

**Files:**
- Create: `.claude/skills/knowledge-map/templates/checks/AGENTS.md`
- Create: `.claude/skills/knowledge-map/templates/checks/check-knowledge.sh.tmpl`
- Create: `.claude/skills/knowledge-map/templates/checks/check-anchors.sh.tmpl`
- Create: `.claude/skills/knowledge-map/templates/checks/check-drift.sh.tmpl`

- [ ] **Step 1: Write `templates/checks/AGENTS.md`**

Content (~50 lines): conventions for the in-target check scripts.
- Every `check-*.sh.tmpl` starts with `#!/usr/bin/env bash` and `set -uo pipefail` (no `-e`)
- Strict mode branched via `{{STRICT_MODE}}`
- Error format: `❌ <check-id> <message>\n   修复: <fix instruction>`
- Success format: `✅ <check-id> passed`
- These scripts are COPIED (not rendered from fragments) into the target repo's `scripts/` — only `{{STRICT_MODE}}` is substituted at copy time
- L3/L4 require codegraph (`codegraph explore`); they warn-and-skip if `.codegraph/` is absent

Write the actual prose.

- [ ] **Step 2: Write `check-knowledge.sh.tmpl`** (in-target L1)

```bash
#!/usr/bin/env bash
# L1: static checks on a generated knowledge base.
# Runs in the KB output dir. Generated by knowledge-map skill (strict={{STRICT_MODE}}).

set -uo pipefail

STRICT="{{STRICT_MODE}}"
FAIL=0

# K1: KNOWLEDGE.md exists and is a markdown index
if [[ ! -f KNOWLEDGE.md ]]; then
  echo "❌ K1: KNOWLEDGE.md missing"
  echo "   修复: 重新运行 knowledge-map skill 生成知识库"
  FAIL=$((FAIL+1))
elif ! head -1 KNOWLEDGE.md | grep -qE '^# .+ — 业务知识地图$'; then
  echo "❌ K1: KNOWLEDGE.md first line must be '# <repo> — 业务知识地图'"
  echo "   修复: 检查 knowledge-index.md.tmpl 渲染是否正确"
  FAIL=$((FAIL+1))
else
  echo "✅ K1: KNOWLEDGE.md present and well-formed"
fi

# K2: KNOWLEDGE.md ≤ 100 lines
LINES=$(wc -l < KNOWLEDGE.md)
if [[ "$LINES" -gt 100 ]]; then
  echo "❌ K2: KNOWLEDGE.md is $LINES lines (max 100)"
  echo "   修复: 精简 .meta/fragments/overview-*.md / knowledge-topology.md 等片段"
  FAIL=$((FAIL+1))
else
  echo "✅ K2: KNOWLEDGE.md is $LINES lines (≤100)"
fi

# K3: every domain file has valid frontmatter (domain/deepwiki/status)
for f in domains/*.md; do
  [[ -e "$f" ]] || continue
  if ! grep -q '^domain:' "$f" || ! grep -q '^deepwiki:' "$f" || ! grep -q '^status:' "$f"; then
    echo "❌ K3: $f missing frontmatter (domain/deepwiki/status)"
    echo "   修复: 检查 domain-knowledge.md.tmpl 渲染"
    FAIL=$((FAIL+1))
  fi
done
echo "✅ K3: all domain files have frontmatter"

# K4: internal markdown links resolve (domains/*.md, drift.md)
for link in $(grep -oE '\(domains/[^)]+\.md\)|\(drift\.md\)' KNOWLEDGE.md domains/*.md 2>/dev/null | tr -d '()'); do
  if [[ ! -f "$link" ]]; then
    echo "❌ K4: broken link target: $link"
    echo "   修复: 补齐缺失文件或修正链接"
    FAIL=$((FAIL+1))
  fi
done
echo "✅ K4: internal links resolve"

# K5: no leftover template placeholders
if grep -rE '\{\{[A-Z_]+\}\}' . --include='*.md' 2>/dev/null | grep -q .; then
  echo "❌ K5: unresolved {{PLACEHOLDER}} in rendered markdown:"
  grep -rE '\{\{[A-Z_]+\}\}' . --include='*.md' | head -5
  echo "   修复: 补齐缺失的 fragment 或修正 render-kb.sh"
  FAIL=$((FAIL+1))
else
  echo "✅ K5: no leftover placeholders"
fi

if [[ "$FAIL" -gt 0 ]]; then
  if [[ "$STRICT" == "strict" ]]; then
    echo "🛑 L1: $FAIL failures (strict mode)"
    exit 1
  else
    echo "⚠️  L1: $FAIL failures (advisory mode, not blocking)"
    exit 0
  fi
fi
echo "✅ L1: all static checks passed"
exit 0
```

- [ ] **Step 3: Write `check-anchors.sh.tmpl`** (in-target L3)

```bash
#!/usr/bin/env bash
# L3: verify every anchor in .meta/anchors.json resolves via codegraph.
# Requires codegraph + .codegraph/ index. Generated by knowledge-map skill (strict={{STRICT_MODE}}).

set -uo pipefail

STRICT="{{STRICT_MODE}}"
PROJECT_PATH="${CODEGRAPH_PROJECT_PATH:-.}"
ANCHORS=".meta/anchors.json"

if ! command -v codegraph &>/dev/null; then
  echo "⚠️  L3: codegraph CLI not found — skipping anchor verification"
  echo "   安装 codegraph 后重跑，或设 CODEGRAPH_PROJECT_PATH 指向已建索引的目录"
  exit 0
fi

if [[ ! -f "$ANCHORS" ]]; then
  echo "❌ L3: $ANCHORS not found"
  echo "   修复: 重新运行 knowledge-map skill 生成 .meta/anchors.json"
  [[ "$STRICT" == "strict" ]] && exit 1 || exit 0
fi

FAIL=0
RESOLVED=0; STALE=0; MISSING=0
# Read symbols (one per line) from anchors.json; assumes jq-style extraction via grep fallback
SYMBOLS=$(grep -oE '"symbol"[[:space:]]*:[[:space:]]*"[^"]+"' "$ANCHORS" | sed -E 's/.*"symbol"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' | sort -u)

for sym in $SYMBOLS; do
  if codegraph explore "$sym" --project "$PROJECT_PATH" >/dev/null 2>&1; then
    RESOLVED=$((RESOLVED+1))
  else
    echo "❌ L3: anchor not resolved: $sym"
    echo "   修复: codegraph 重建索引，或更新 .meta/anchors.json 中该锚点"
    MISSING=$((MISSING+1))
    FAIL=$((FAIL+1))
  fi
done

echo "L3 summary: $RESOLVED resolved, $STALE stale, $MISSING missing"

if [[ "$FAIL" -gt 0 ]]; then
  if [[ "$STRICT" == "strict" ]]; then
    echo "🛑 L3: $FAIL unresolved anchors (strict mode)"
    exit 1
  else
    echo "⚠️  L3: $FAIL unresolved anchors (advisory mode)"
    exit 0
  fi
fi
echo "✅ L3: all anchors resolved"
exit 0
```

- [ ] **Step 4: Write `check-drift.sh.tmpl`** (in-target L4)

```bash
#!/usr/bin/env bash
# L4: recompute orphan/blindspot drift from harvest-data.json + codegraph centrality.
# Requires codegraph for blindspot recompute. Generated by knowledge-map skill (strict={{STRICT_MODE}}).

set -uo pipefail

STRICT="{{STRICT_MODE}}"
DATA=".meta/harvest-data.json"

if [[ ! -f "$DATA" ]]; then
  echo "❌ L4: $DATA not found"
  echo "   修复: 重新运行 knowledge-map skill"
  [[ "$STRICT" == "strict" ]] && exit 1 || exit 0
fi

FAIL=0

# L4a: orphans are deterministic from harvest-data.json (no codegraph needed)
ORPHANS=$(grep -oE '"orphans"[[:space:]]*:[[:space:]]*\[' "$DATA" >/dev/null && \
  grep -oE '"concept"[[:space:]]*:[[:space:]]*"[^"]+"' "$DATA" | wc -l)
echo "ℹ️  L4a: orphan concept entries present in harvest-data.json"

# L4b: blindspots need codegraph centrality (re-query). If codegraph missing, warn-skip.
if command -v codegraph &>/dev/null; then
  echo "✅ L4b: codegraph available — blindspot recompute enabled (manual review of drift.md vs recompute)"
else
  echo "⚠️  L4b: codegraph CLI missing — skipping blindspot recompute; trust committed drift.md"
fi

# L4c: NEW drift = committed drift.md orphan/blindspot count differs from recomputed.
# Compare committed drift.md line counts as a cheap signal.
if [[ -f drift.md ]]; then
  echo "ℹ️  L4c: committed drift.md present — compare against fresh harvest to detect new drift"
  echo "   运行 knowledge-map skill 重新 harvest，diff drift.md；新增 orphan/blindspot 即新漂移"
fi

if [[ "$FAIL" -gt 0 ]]; then
  if [[ "$STRICT" == "strict" ]]; then exit 1; else exit 0; fi
fi
echo "✅ L4: drift check complete (see drift.md for details)"
exit 0
```

- [ ] **Step 5: Verify all three templates parse as valid bash after substitution**

```bash
cd .claude/skills/knowledge-map/templates/checks/
for f in check-knowledge check-anchors check-drift; do
  sed 's/{{STRICT_MODE}}/advisory/g' "${f}.sh.tmpl" > "/tmp/${f}.sh"
  bash -n "/tmp/${f}.sh" && echo "$f: OK" || echo "$f: FAIL"
done
```
Expected: each prints `OK`.

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/knowledge-map/templates/checks/
git commit -m "feat(checks): add in-target L1/L3/L4 check script templates"
```

---

## Phase 4: Skill verification scripts + renderer

### Task 9: scripts/render-kb.sh (the deterministic L2 engine)

**Files:**
- Create: `.claude/skills/knowledge-map/scripts/render-kb.sh`

- [ ] **Step 1: Write `render-kb.sh`**

Pure bash + sed, no jq. Reads `manifest.tsv` from the fragments dir, substitutes each fragment into the matching template. Also handles static placeholders from `sources.json` (repo basename etc.).

```bash
#!/usr/bin/env bash
# render-kb.sh — deterministic renderer: fragments + templates → knowledge base.
# Usage: render-kb.sh <fragments-dir> <output-dir> [<templates-dir>]
# <fragments-dir> contains manifest.tsv + fragments/* (harvest output).
# <output-dir> receives KNOWLEDGE.md, domains/*.md, drift.md.
# <templates-dir> defaults to this script's ../templates/.

set -uo pipefail

FRAG_DIR="${1:?usage: render-kb.sh <fragments-dir> <output-dir> [templates-dir]}"
OUT_DIR="${2:?usage: render-kb.sh <fragments-dir> <output-dir> [templates-dir]}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPL_DIR="${3:-$SCRIPT_DIR/../templates}"
MANIFEST="$FRAG_DIR/manifest.tsv"

if [[ ! -f "$MANIFEST" ]]; then
  echo "❌ render: manifest not found: $MANIFEST" >&2
  exit 1
fi

mkdir -p "$OUT_DIR/domains"

# --- helpers ---------------------------------------------------------------

# substitute_fragment <template-string-on-stdin> <placeholder> <fragment-path>
# Replaces ALL occurrences of {{placeholder}} with the fragment file's content.
# Uses awk to avoid sed EOL/meta issues with multiline replacement.
substitute() {
  local placeholder="$1" fragpath="$2"
  local marker_open="{{${placeholder}}}"
  # awk-based multiline replacement
  awk -v open="$marker_open" -v file="$fragpath" '
    BEGIN {
      if (file != "") {
        content = ""
        while ((getline line < file) > 0) {
          content = (content == "" ? line : content "\n" line)
        }
        close(file)
      }
    }
    {
      while (index($0, open) > 0) {
        sub(open, content, $0)
      }
      print
    }
  '
}

# --- load static placeholders from sources.json ----------------------------
# sources.json is written by H5a. Extract scalar string values via grep.
SOURCES="$FRAG_DIR/../sources.json"
get_src() { # get_src <key>
  [[ -f "$SOURCES" ]] || { echo ""; return; }
  grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$SOURCES" \
    | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/'
}

REPO_NAME="$(get_src repoName)"
[[ -z "$REPO_NAME" ]] && REPO_NAME="repo"

# --- 1. render KNOWLEDGE.md (global placeholders + REPO_NAME) ---------------
echo "▶ rendering KNOWLEDGE.md"
TMP=$(mktemp)
cp "$TMPL_DIR/knowledge-index.md.tmpl" "$TMP"
# static REPO_NAME
awk -v r="$REPO_NAME" '{ gsub(/\{\{REPO_NAME\}\}/, r); print }' "$TMP" > "$TMP.2"; mv "$TMP.2" "$TMP"
# global fragment placeholders
while IFS=$'\t' read -r scope id placeholder path; do
  [[ "$scope" == "global" ]] || continue
  [[ -z "$placeholder" ]] && continue
  substitute "$placeholder" "$FRAG_DIR/$path" < "$TMP" > "$TMP.2"; mv "$TMP.2" "$TMP"
done < "$MANIFEST"
mv "$TMP" "$OUT_DIR/KNOWLEDGE.md"

# --- 2. render drift.md -----------------------------------------------------
echo "▶ rendering drift.md"
TMP=$(mktemp)
cp "$TMPL_DIR/drift-report.md.tmpl" "$TMP"
while IFS=$'\t' read -r scope id placeholder path; do
  [[ "$scope" == "drift" ]] || continue
  [[ -z "$placeholder" ]] && continue
  substitute "$placeholder" "$FRAG_DIR/$path" < "$TMP" > "$TMP.2"; mv "$TMP.2" "$TMP"
done < "$MANIFEST"
mv "$TMP" "$OUT_DIR/drift.md"

# --- 3. render domains/<id>.md (per domain) --------------------------------
# Collect unique domain ids
DOMAIN_IDS=$(awk -F'\t' '$1=="domain" && $2!="" {print $2}' "$MANIFEST" | sort -u)
for did in $DOMAIN_IDS; do
  echo "▶ rendering domains/$did.md"
  TMP=$(mktemp)
  cp "$TMPL_DIR/domain-knowledge.md.tmpl" "$TMP"
  while IFS=$'\t' read -r scope id placeholder path; do
    [[ "$scope" == "domain" && "$id" == "$did" ]] || continue
    [[ -z "$placeholder" ]] && continue
    substitute "$placeholder" "$FRAG_DIR/$path" < "$TMP" > "$TMP.2"; mv "$TMP.2" "$TMP"
  done < "$MANIFEST"
  mv "$TMP" "$OUT_DIR/domains/$did.md"
done

# --- 4. copy .meta (sources.json, anchors.json, harvest-data.json) ---------
for metafile in sources.json anchors.json harvest-data.json; do
  if [[ -f "$FRAG_DIR/../$metafile" ]]; then
    mkdir -p "$OUT_DIR/.meta"
    cp "$FRAG_DIR/../$metafile" "$OUT_DIR/.meta/$metafile"
  fi
done

echo "✅ render complete → $OUT_DIR"
exit 0
```

- [ ] **Step 2: Make executable and syntax-check**

```bash
chmod +x .claude/skills/knowledge-map/scripts/render-kb.sh
bash -n .claude/skills/knowledge-map/scripts/render-kb.sh && echo "render-kb.sh: syntax OK" || echo "FAIL"
```
Expected: `render-kb.sh: syntax OK`.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/knowledge-map/scripts/render-kb.sh
git commit -m "feat(scripts): add deterministic render-kb.sh renderer (L2 engine)"
```

---

### Task 10: scripts/check-skill.sh (L1 skill self-check)

**Files:**
- Create: `.claude/skills/knowledge-map/scripts/check-skill.sh`

- [ ] **Step 1: Write `check-skill.sh`**

```bash
#!/usr/bin/env bash
# L1: Static checks for the knowledge-map skill itself.
# Verifies SKILL.md frontmatter, template placeholder consistency, line counts, subdir AGENTS.md.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

FAIL=0

# S1: SKILL.md frontmatter
if ! head -1 SKILL.md | grep -q '^---$'; then
  echo "❌ S1: SKILL.md missing frontmatter opening ---"; FAIL=$((FAIL+1))
fi
if ! head -10 SKILL.md | grep -q '^name: knowledge-map$'; then
  echo "❌ S1: SKILL.md missing 'name: knowledge-map'"; FAIL=$((FAIL+1))
fi
if ! head -10 SKILL.md | grep -qE '^description: .+$'; then
  echo "❌ S1: SKILL.md missing description"; FAIL=$((FAIL+1))
fi
echo "✅ S1: SKILL.md frontmatter valid"

# S2: SKILL.md ≤ 100 lines
LINES=$(wc -l < SKILL.md)
if [[ "$LINES" -gt 100 ]]; then
  echo "❌ S2: SKILL.md is $LINES lines (max 100)"; FAIL=$((FAIL+1))
else
  echo "✅ S2: SKILL.md is $LINES lines"
fi

# S3: every .tmpl uses at least one {{PLACEHOLDER}} (except meta reference shells)
while IFS= read -r f; do
  base=$(basename "$f")
  # meta-*.tmpl are reference shells; skip the placeholder requirement
  [[ "$base" == meta-*.tmpl ]] && continue
  if ! grep -qE '\{\{[A-Z_]+\}\}' "$f"; then
    echo "⚠️  S3: $f has no {{PLACEHOLDER}} — should it be a plain file?"
  fi
done < <(find templates -name '*.tmpl' -type f)
echo "✅ S3: template placeholder scan complete"

# S4: subdir AGENTS.md ≤ 100 lines (excluding examples/)
LONG=0
while IFS= read -r f; do
  l=$(wc -l < "$f")
  if [[ "$l" -gt 100 ]]; then
    echo "❌ S4: $f is $l lines (max 100)"; LONG=$((LONG+1)); FAIL=$((FAIL+1))
  fi
done < <(find . -name AGENTS.md -not -path './examples/*')
echo "✅ S4: AGENTS.md line counts checked"

# S5: render-kb.sh + check-*.sh exist and parse as valid bash
for s in scripts/render-kb.sh scripts/check-skill.sh scripts/check-examples.sh scripts/check-anchors.sh scripts/check-drift.sh; do
  if [[ ! -f "$s" ]]; then
    echo "❌ S5: missing $s"; FAIL=$((FAIL+1))
  elif ! bash -n "$s" 2>/dev/null; then
    echo "❌ S5: $s has bash syntax error"; FAIL=$((FAIL+1))
  fi
done
echo "✅ S5: skill scripts present and parse"

# S6: in-target check templates parse as valid bash after {{STRICT_MODE}} substitution
for t in templates/checks/check-knowledge.sh.tmpl templates/checks/check-anchors.sh.tmpl templates/checks/check-drift.sh.tmpl; do
  [[ -f "$t" ]] || { echo "⚠️  S6: $t not yet present"; continue; }
  if ! sed 's/{{STRICT_MODE}}/advisory/g' "$t" | bash -n 2>/dev/null; then
    echo "❌ S6: $t does not parse as bash after substitution"; FAIL=$((FAIL+1))
  fi
done
echo "✅ S6: in-target check templates parse"

if [[ "$FAIL" -gt 0 ]]; then
  echo "🛑 L1: $FAIL failures"; exit 1
fi
echo "✅ L1: all static checks passed"
exit 0
```

- [ ] **Step 2: Make executable and run**

```bash
chmod +x .claude/skills/knowledge-map/scripts/check-skill.sh
bash .claude/skills/knowledge-map/scripts/check-skill.sh
```
Expected: any failures are "not yet present" warnings for scripts not yet written (check-examples/anchors/drift come in Tasks 11-12). Fix until only expected-absent warnings remain, then proceed; the final green run happens after Task 12.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/knowledge-map/scripts/check-skill.sh
git commit -m "feat(scripts): add L1 static check for skill self-verification"
```

---

### Task 11: scripts/check-anchors.sh + scripts/check-drift.sh (skill's L3/L4)

**Files:**
- Create: `.claude/skills/knowledge-map/scripts/check-anchors.sh`
- Create: `.claude/skills/knowledge-map/scripts/check-drift.sh`

These are the skill's OWN L3/L4 that run against the committed `examples/lucene/` baseline (analogous to harness-loop's check-examples). They differ from the in-target templates (Task 8) — these point at the example dir.

- [ ] **Step 1: Write `check-anchors.sh`** (skill's L3 on the example)

```bash
#!/usr/bin/env bash
# L3 (skill self-check): verify every anchor in examples/lucene/.meta/anchors.json
# resolves via codegraph. Requires codegraph + the lucene .codegraph index.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE="$SKILL_DIR/examples/lucene"
ANCHORS="$EXAMPLE/.meta/anchors.json"
PROJECT_PATH="${LUCENE_PROJECT_PATH:-D:/project/lucene-main/lucene-main/lucene}"

if [[ ! -f "$ANCHORS" ]]; then
  echo "⚠️  L3: $ANCHORS not found — build the lucene example first (Task 14)"
  exit 0
fi

if ! command -v codegraph &>/dev/null; then
  echo "⚠️  L3: codegraph CLI not found — skipping (run locally where codegraph is installed)"
  exit 0
fi

FAIL=0; RESOLVED=0; MISSING=0
SYMBOLS=$(grep -oE '"symbol"[[:space:]]*:[[:space:]]*"[^"]+"' "$ANCHORS" \
  | sed -E 's/.*"symbol"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' | sort -u)

for sym in $SYMBOLS; do
  if codegraph explore "$sym" --project "$PROJECT_PATH" >/dev/null 2>&1; then
    RESOLVED=$((RESOLVED+1))
  else
    echo "❌ L3: example anchor not resolved: $sym"
    echo "   修复: 重建 lucene codegraph 索引，或更新 examples/lucene/.meta/anchors.json"
    MISSING=$((MISSING+1)); FAIL=$((FAIL+1))
  fi
done

echo "L3 summary: $RESOLVED resolved, $MISSING missing (of unique symbols)"
if [[ "$FAIL" -gt 0 ]]; then echo "🛑 L3: $FAIL failures"; exit 1; fi
echo "✅ L3: all example anchors resolved"
exit 0
```

- [ ] **Step 2: Write `check-drift.sh`** (skill's L4 on the example)

```bash
#!/usr/bin/env bash
# L4 (skill self-check): verify examples/lucene/drift.md is present and its
# orphan/blindspot entries are non-empty where harvest-data.json indicates drift.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE="$SKILL_DIR/examples/lucene"

FAIL=0

if [[ ! -f "$EXAMPLE/drift.md" ]]; then
  echo "❌ L4: examples/lucene/drift.md missing — build the example first (Task 15)"
  FAIL=$((FAIL+1))
else
  echo "✅ L4: drift.md present"
fi

if [[ ! -f "$EXAMPLE/.meta/harvest-data.json" ]]; then
  echo "❌ L4: examples/lucene/.meta/harvest-data.json missing"
  FAIL=$((FAIL+1))
else
  # L4a: orphan count in harvest-data.json should be reflected in drift.md
  echo "ℹ️  L4: harvest-data.json present — orphan/blindspot entries committed in drift.md"
  # sanity: drift.md mentions both sections
  grep -q '## Orphans' "$EXAMPLE/drift.md" || { echo "❌ L4: drift.md missing Orphans section"; FAIL=$((FAIL+1)); }
  grep -q '## Blindspots' "$EXAMPLE/drift.md" || { echo "❌ L4: drift.md missing Blindspots section"; FAIL=$((FAIL+1)); }
fi

if [[ "$FAIL" -gt 0 ]]; then echo "🛑 L4: $FAIL failures"; exit 1; fi
echo "✅ L4: drift report consistent"
exit 0
```

- [ ] **Step 3: Verify both parse**

```bash
bash -n .claude/skills/knowledge-map/scripts/check-anchors.sh && echo "anchors: OK"
bash -n .claude/skills/knowledge-map/scripts/check-drift.sh && echo "drift: OK"
```
Expected: both `OK`.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/knowledge-map/scripts/check-anchors.sh .claude/skills/knowledge-map/scripts/check-drift.sh
git commit -m "feat(scripts): add L3/L4 skill self-checks against lucene example"
```

---

### Task 12: scripts/check-examples.sh (L2 render+diff)

**Files:**
- Create: `.claude/skills/knowledge-map/scripts/check-examples.sh`

- [ ] **Step 1: Write `check-examples.sh`**

```bash
#!/usr/bin/env bash
# L2: deterministic render+diff against examples/lucene/.
# Re-renders the example KB from its committed .meta/fragments/ via render-kb.sh,
# then diffs vs the committed rendered output. Same fragments + same templates → identical bytes.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE="$SKILL_DIR/examples/lucene"
FRAG="$EXAMPLE/.meta/fragments"

FAIL=0

if [[ ! -f "$FRAG/manifest.tsv" ]]; then
  echo "⚠️  L2: examples/lucene/.meta/fragments/manifest.tsv not found — build the example first (Tasks 13-15)"
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "▶ L2: re-rendering lucene example from committed fragments into $tmp"
if ! bash "$SKILL_DIR/scripts/render-kb.sh" "$FRAG" "$tmp" "$SKILL_DIR/templates"; then
  echo "❌ L2: render-kb.sh failed"
  FAIL=$((FAIL+1))
else
  # diff rendered output vs committed (exclude .meta — render copies it verbatim, but
  # harvest-data.json timestamp may differ; diff the markdown only)
  for f in KNOWLEDGE.md drift.md; do
    if ! diff -q "$EXAMPLE/$f" "$tmp/$f" >/dev/null 2>&1; then
      echo "❌ L2: $f differs from snapshot:"
      diff "$EXAMPLE/$f" "$tmp/$f" | head -40
      FAIL=$((FAIL+1))
    else
      echo "✅ L2: $f matches snapshot"
    fi
  done
  # diff each committed domain vs rendered
  for ex_domain in "$EXAMPLE"/domains/*.md; do
    [[ -e "$ex_domain" ]] || continue
    name=$(basename "$ex_domain")
    if ! diff -q "$ex_domain" "$tmp/domains/$name" >/dev/null 2>&1; then
      echo "❌ L2: domains/$name differs from snapshot:"
      diff "$ex_domain" "$tmp/domains/$name" | head -40
      FAIL=$((FAIL+1))
    else
      echo "✅ L2: domains/$name matches snapshot"
    fi
  done
fi

if [[ "$FAIL" -gt 0 ]]; then echo "🛑 L2: $FAIL failures"; exit 1; fi
echo "✅ L2: example renders cleanly from fragments"
exit 0
```

- [ ] **Step 2: Verify parse + run (will skip until example built)**

```bash
bash -n .claude/skills/knowledge-map/scripts/check-examples.sh && echo "examples: syntax OK"
bash .claude/skills/knowledge-map/scripts/check-examples.sh
```
Expected: syntax `OK`; run prints the "build the example first" warning and exits 0 (example not built yet).

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/knowledge-map/scripts/check-examples.sh
git commit -m "feat(scripts): add L2 render+diff example check"
```

---

## Phase 5: Lucene example (L2 baseline + integration test)

> This phase proves the skill works end-to-end against the real Lucene repo. It is the integration test. The executing agent performs the live harvest (fetch deepwiki + query codegraph) and commits both the fragments (harvest output) and the rendered KB (render output). After this, L2 re-renders fragments deterministically.

### Task 13: examples/AGENTS.md + examples/lucene/answers.json

**Files:**
- Create: `.claude/skills/knowledge-map/examples/AGENTS.md`
- Create: `.claude/skills/knowledge-map/examples/lucene/answers.json`

- [ ] **Step 1: Write `examples/AGENTS.md`**

Content (~40 lines): purpose of examples/ + the lucene baseline contract.
- examples/ holds L2 diff baselines (committed fragments + rendered output)
- examples/lucene/ is the canonical baseline; L2 re-renders its fragments and diffs
- To refresh after external drift (deepwiki/code change): re-run harvest, commit updated fragments + re-rendered output in one "snapshot refresh" commit (spec §8.2)
- answers.json records the Q1-Q7 snapshot that produced this example

Write the actual prose.

- [ ] **Step 2: Write `examples/lucene/answers.json`**

```json
{
  "Q1_repo_path": "D:/project/lucene-main/lucene-main/lucene",
  "Q2_deepwiki_url": "https://deepwiki.com/apache/lucene",
  "Q3_project_path": "D:/project/lucene-main/lucene-main/lucene",
  "Q4_output_dir": ".claude/skills/knowledge-map/examples/lucene",
  "Q5_subsystems": ["indexing", "search", "index-data-structures", "analysis", "build-release"],
  "Q6_depth": "medium",
  "Q7_strict": "advisory"
}
```

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/knowledge-map/examples/AGENTS.md .claude/skills/knowledge-map/examples/lucene/answers.json
git commit -m "feat(examples): add examples conventions + lucene answers.json"
```

---

### Task 14: Harvest lucene → fragments + harvest-data.json (H1-H5a)

**Files:**
- Create: `.claude/skills/knowledge-map/examples/lucene/.meta/harvest-data.json`
- Create: `.claude/skills/knowledge-map/examples/lucene/.meta/sources.json`
- Create: `.claude/skills/knowledge-map/examples/lucene/.meta/anchors.json`
- Create: `.claude/skills/knowledge-map/examples/lucene/.meta/fragments/manifest.tsv`
- Create: `.claude/skills/knowledge-map/examples/lucene/.meta/fragments/*.md` (per the manifest)

This task executes the `wizard/harvest-pipeline.md` playbook (H1-H5a) against real Lucene. The agent performs live fetches + codegraph queries and records the results.

- [ ] **Step 1: H1 — fetch deepwiki root, parse subsystems**

Fetch `https://deepwiki.com/apache/lucene` via webReader. From the markdown (already known to contain `## Major Subsystems` with Indexing/Search/Index Data Structures/Analysis + Build and Release), record into `harvest-data.json`:
- `overview.mission`: the "What is Apache Lucene" summary (1-3 lines)
- `overview.projectStructure`: the "Module Organization" table as markdown
- `domains[]`: one entry per Q5 subsystem with `{id, name, deepwikiUrl, coreClasses[]}`

deepwiki subsystem deep-dive URLs follow the pattern `https://deepwiki.com/apache/lucene/<id>` (e.g. `.../lucene/indexing`). Record each.

- [ ] **Step 2: H2 — fetch each subsystem deep-dive, parse concept clusters**

For each of the 5 subsystems, fetch its deep-dive page. Parse concept clusters (H3/H4 subsections) + their `Sources: path:line` citations. Append `domains[].concepts[].{name, description, citations[]}` to `harvest-data.json`.

Known lucene subsystems + representative anchors (verify each via codegraph in H3):
- **indexing**: IndexWriter, DocumentsWriter, DocumentsWriterPerThread, DocumentsWriterFlushControl, MergePolicy, MergeScheduler
- **search**: IndexSearcher, IndexReader, LeafReader, Query, Weight, Scorer, Collector, LRUQueryCache
- **index-data-structures**: BKDWriter (+ Inverted Index, DocValues, Stored Fields, Term Vectors, Vector Fields concepts)
- **analysis**: Analyzer, Tokenizer, TokenFilter, CharFilter
- **build-release**: settings.gradle, gradle/libs.versions.toml, dev-tools/scripts/

- [ ] **Step 3: H3 — verify every citation via codegraph**

For each anchor symbol, run `codegraph_explore "<symbol>"` with `projectPath=D:/project/lucene-main/lucene-main/lucene`. Record status (RESOLVED/STALE/MISSING), callPath (the call-flow summary codegraph returns), callerCount (blast-radius caller count). Write `domains[].anchors[]` and aggregate into `.meta/anchors.json`.

For IndexWriter/DocumentsWriter/DocumentsWriterPerThread the anchors are already confirmed RESOLVED (verified during design — see spec §3.2). For symbols deepwiki cites by file:line without a clean symbol name, derive the symbol from the file path's class name and verify.

- [ ] **Step 4: H4 — drift analysis**

Compute from `harvest-data.json`:
- **orphans**: concept clusters with all-MISSING/STALE anchors. (For lucene most clusters resolve; record any that don't.)
- **blindspots**: high-callerCount Core Classes not cited by any deepwiki concept. Query codegraph blast-radius for each subsystem's Core Classes; record symbols with callerCount > 20 not already covered. (e.g., check whether `SegmentMerger`, `BufferedUpdates`, `MergeTrigger` appear — if high-centrality and uncovered, record as blindspot.)

Write `harvest-data.json.drift.{orphans[], blindspots[]}`.

- [ ] **Step 5: H5a — write fragments + manifest + sources.json + anchors.json**

Following `wizard/harvest-pipeline.md` H5a, write under `examples/lucene/.meta/fragments/`:
- Global: `overview-mission.md`, `overview-structure.md`, `knowledge-topology.md`, `drift-summary.md`, `entry-points.md`, `regen-note.md`
- Drift: `regen-timestamp.txt` (ISO timestamp from host), `orphans-table.md`, `blindspots-table.md`
- Per domain `<id>` (5 domains): `<id>-name.txt`, `<id>-url.txt`, `<id>-status.txt`, `<id>-narrative.md`, `<id>-concepts.md`, `<id>-anchors.md`, `<id>-drift.md`, `<id>-crosslinks.md`

Write `manifest.tsv` with all rows (4 tab-separated columns each: scope, id, placeholder, path) — every fragment gets a row. Follow the format in the plan's "Fragment manifest format" section.

Write `sources.json`:
```json
{
  "repo": "D:/project/lucene-main/lucene-main/lucene",
  "repoName": "lucene",
  "deepwikiRoot": "https://deepwiki.com/apache/lucene",
  "projectPath": "D:/project/lucene-main/lucene-main/lucene",
  "generatedAt": "<ISO timestamp from host>",
  "depth": "medium",
  "strict": "advisory",
  "domains": ["indexing", "search", "index-data-structures", "analysis", "build-release"]
}
```
Write `anchors.json` (flat array of all anchors across domains).

- [ ] **Step 6: Verify harvest output is complete**

```bash
cd "D:/project/harness+loop/.claude/skills/knowledge-map/examples/lucene/.meta"
test -f harvest-data.json && echo "harvest-data OK" || echo "MISSING harvest-data"
test -f sources.json && echo "sources OK" || echo "MISSING sources"
test -f anchors.json && echo "anchors OK" || echo "MISSING anchors"
test -f fragments/manifest.tsv && echo "manifest OK" || echo "MISSING manifest"
# count fragment files: 6 global + 3 drift + 8×5 domains = 49
find fragments -type f ! -name manifest.tsv | wc -l
```
Expected: `49` fragment files (adjust count note if depth/cluster parsing yields slightly different; the manifest must list exactly the files that exist).

- [ ] **Step 7: Commit**

```bash
git add .claude/skills/knowledge-map/examples/lucene/.meta/
git commit -m "feat(examples): harvest lucene → fragments + harvest-data (H1-H5a)"
```

---

### Task 15: Render lucene KB → KNOWLEDGE.md + domains/*.md + drift.md (H5b + L2)

**Files:**
- Create: `.claude/skills/knowledge-map/examples/lucene/KNOWLEDGE.md`
- Create: `.claude/skills/knowledge-map/examples/lucene/domains/indexing.md`
- Create: `.claude/skills/knowledge-map/examples/lucene/domains/search.md`
- Create: `.claude/skills/knowledge-map/examples/lucene/domains/index-data-structures.md`
- Create: `.claude/skills/knowledge-map/examples/lucene/domains/analysis.md`
- Create: `.claude/skills/knowledge-map/examples/lucene/domains/build-release.md`
- Create: `.claude/skills/knowledge-map/examples/lucene/drift.md`

- [ ] **Step 1: Run the renderer on the committed fragments**

```bash
cd "D:/project/harness+loop"
bash .claude/skills/knowledge-map/scripts/render-kb.sh \
  .claude/skills/knowledge-map/examples/lucene/.meta/fragments \
  .claude/skills/knowledge-map/examples/lucene \
  .claude/skills/knowledge-map/templates
```
Expected: prints `▶ rendering KNOWLEDGE.md / drift.md / domains/<id>.md` × 5, then `✅ render complete`.

- [ ] **Step 2: Verify all rendered files exist + have no leftover placeholders**

```bash
cd .claude/skills/knowledge-map/examples/lucene
test -f KNOWLEDGE.md && test -f drift.md && ls domains/*.md | wc -l
# expect 5 domain files
grep -rE '\{\{[A-Z_]+\}\}' KNOWLEDGE.md domains/*.md drift.md && echo "❌ leftover placeholders" || echo "✅ no leftovers"
wc -l KNOWLEDGE.md   # must be ≤100
```
Expected: `5` domain files; `✅ no leftovers`; `KNOWLEDGE.md` ≤100 lines.

- [ ] **Step 3: Run L2 (render+diff) — must be clean**

```bash
bash .claude/skills/knowledge-map/scripts/check-examples.sh
```
Expected: `✅ L2: <file> matches snapshot` for KNOWLEDGE.md, drift.md, and each domain; final `✅ L2: example renders cleanly from fragments`.

If any diff appears, the fragments and rendered output disagree — fix the fragments (not the rendered output; the rendered output is derived) and re-run render + L2 until clean.

- [ ] **Step 4: Run L1 on the rendered example**

```bash
cd .claude/skills/knowledge-map/examples/lucene
sed 's/{{STRICT_MODE}}/advisory/g' ../../templates/checks/check-knowledge.sh.tmpl > /tmp/check-knowledge.sh
bash /tmp/check-knowledge.sh
```
Expected: `✅ L1: all static checks passed` (K1-K5 all pass against the rendered example).

- [ ] **Step 5: Commit**

```bash
cd "D:/project/harness+loop"
git add .claude/skills/knowledge-map/examples/lucene/KNOWLEDGE.md \
        .claude/skills/knowledge-map/examples/lucene/drift.md \
        .claude/skills/knowledge-map/examples/lucene/domains/
git commit -m "feat(examples): render lucene KB (KNOWLEDGE.md + 5 domains + drift.md)"
```

---

## Phase 6: Final verification

### Task 16: Full L1-L4 green pass

**Files:**
- Verify-only (no new files)

- [ ] **Step 1: Run skill L1 (check-skill.sh)**

```bash
bash .claude/skills/knowledge-map/scripts/check-skill.sh
```
Expected: `✅ L1: all static checks passed`. Fix any S1-S6 failures (e.g., a subdir AGENTS.md over 100 lines).

- [ ] **Step 2: Run L2 (check-examples.sh)**

```bash
bash .claude/skills/knowledge-map/scripts/check-examples.sh
```
Expected: `✅ L2: example renders cleanly from fragments`.

- [ ] **Step 3: Run L3 (check-anchors.sh) — requires codegraph**

```bash
bash .claude/skills/knowledge-map/scripts/check-anchors.sh
```
Expected: `✅ L3: all example anchors resolved` (or, if codegraph CLI invocation differs on this host, the documented skip-warning — then manually confirm via `codegraph_explore` that ≥1 anchor per domain resolves).

- [ ] **Step 4: Run L4 (check-drift.sh)**

```bash
bash .claude/skills/knowledge-map/scripts/check-drift.sh
```
Expected: `✅ L4: drift report consistent`.

- [ ] **Step 5: Run the repo's own consistency check (this repo is strict)**

```bash
cd "D:/project/harness+loop"
bash scripts/check-consistency.sh
```
Expected: exit 0. If it complains about the new skill dir, follow its `修复:` instructions (the skill lives under `.claude/` which the repo's C-checks may or may not cover; adjust if needed).

- [ ] **Step 6: Commit any fixes**

```bash
git add -A .claude/skills/knowledge-map/
git commit -m "test(skill): L1-L4 green for knowledge-map skill" || echo "nothing to commit"
```

---

### Task 17: Manual end-to-end sanity + README polish + done

**Files:**
- Modify: `.claude/skills/knowledge-map/README.md` (finalize)
- Verify-only otherwise

- [ ] **Step 1: Manual end-to-end — simulate a fresh invocation**

Without using the committed example, simulate the skill on ONE lucene subsystem (e.g. `search`) to confirm the playbook is followable by a fresh agent:
1. Read SKILL.md → it points to wizard/questions.md
2. Mentally answer Q1-Q4 (lucene paths)
3. Run H1 manually: fetch deepwiki root, confirm `## Major Subsystems` parses
4. Pick `search` only, run H2-H4 on it, confirm anchors resolve via `codegraph_explore`
5. Confirm the fragment + render steps produce a `domains/search.md` matching the committed one

If the fresh walk produces a `search.md` differing from the committed baseline only in non-semantic ways (timestamp), the skill is sound. If it diverges semantically, fix the playbook (`harvest-pipeline.md`).

- [ ] **Step 2: Finalize README.md**

Ensure `.claude/skills/knowledge-map/README.md` has no `TODO`/`TBD`, every section has prose, and the "Verification" section documents: CI runs L1+L2 (`check-skill.sh`, `check-examples.sh`); local runs L1-L4 (add `check-anchors.sh`, `check-drift.sh`); L3/L4 need codegraph.

- [ ] **Step 3: Final full check sweep**

```bash
bash .claude/skills/knowledge-map/scripts/check-skill.sh && \
bash .claude/skills/knowledge-map/scripts/check-examples.sh && \
echo "ALL GREEN"
```
Expected: `ALL GREEN`.

- [ ] **Step 4: Commit + update TASKS.md**

```bash
cd "D:/project/harness+loop"
git add .claude/skills/knowledge-map/README.md TASKS.md
# Append to TASKS.md Done section: "[x] knowledge-map skill: agent-first KB from deepwiki+codegraph (lucene baseline)"
git commit -m "docs(skill): finalize knowledge-map README; mark skill done in TASKS"
```

---

## Self-Review Checklist

After writing this plan, the following checks pass:

**1. Spec coverage:**
- §1 Problem (agent can't navigate large repo by business concept) → solved by whole skill
- §2 D1 agent-first → anchor tables in domain template (Task 6); status emojis
- §2 D2 deepwiki-skeleton + codegraph-anchors → H1-H3 in harvest-pipeline (Task 5)
- §2 D3 map-index + domain files → knowledge-index.md.tmpl + domain-knowledge.md.tmpl (Task 6)
- §2 D4 L1-L4 drift → check templates (Task 8) + skill checks (Tasks 10-12); orphan/blindspot in H4 (Task 5)
- §3 data source verification → consumed in Task 14 (real lucene harvest)
- §4 architecture → SKILL.md (Task 2) + AGENTS.md (Task 1)
- §5 7-question wizard → questions.md (Task 3) + decision-tree.md (Task 4)
- §6 H1-H5 harvest pipeline → harvest-pipeline.md (Task 5) + executed (Task 14)
- §7 generated structure + templates → Tasks 6-8
- §7.2 domain file template → domain-knowledge.md.tmpl (Task 6)
- §7.4 anchors.json → meta-anchors.json.tmpl (Task 7) + written in Task 14
- §8 L1-L4 + §8.1 CI=L1+L2/local=L1-L4 + §8.2 snapshot determinism → check scripts (Tasks 10-12) + check-examples render+diff (Task 12); §8.2 contract documented in examples/AGENTS.md (Task 13)
- §9 skill internal structure → all tasks collectively build the structure
- §10 open questions → handled: deepwiki structure (H1 parse-failure fallback Q5 in Task 3/5); codegraph CI availability (L3/L4 local-only, Task 8 AGENTS); blindspot centrality (callerCount heuristic, Task 5 H4); STALE threshold (symbol-body rule, Task 5 H3); lucene pollution (example under skill dir, Task 13)

**2. Placeholder scan:**
- No "TBD/TODO/FIXME" in plan steps (README finalize in Task 17 explicitly checks for them)
- All code blocks contain actual code/content
- Template `{{PLACEHOLDER}}` tokens inside templates are correct (they ARE the content), not plan placeholders
- Tasks depending on live sources (Task 14 harvest) give concrete URLs + symbol lists + codegraph invocation

**3. Type/placeholder consistency:**
- Global placeholders `{MISSION, PROJECT_STRUCTURE, TOPOLOGY, DRIFT_SUMMARY, ENTRY_POINTS, REGEN_NOTE}` consistent across `templates/AGENTS.md` (Task 6), `knowledge-index.md.tmpl` (Task 6), `render-kb.sh` (Task 9), manifest (Task 14)
- Domain placeholders `{DOMAIN_NAME, DEEPWIKI_URL, STATUS, NARRATIVE, CONCEPTS, ANCHORS_TABLE, DOMAIN_DRIFT, CROSS_LINKS}` consistent across `domain-knowledge.md.tmpl`, `templates/AGENTS.md`, `render-kb.sh`, per-domain fragments
- Drift placeholders `{REGEN_TIMESTAMP, ORPHANS_TABLE, BLINDSPOTS_TABLE}` consistent across `drift-report.md.tmpl`, `render-kb.sh`, manifest
- `{{STRICT_MODE}}` consistent across all `check-*.sh.tmpl` and substituted at copy/render time
- `{{REPO_NAME}}` handled specially in `render-kb.sh` (from sources.json, not a fragment) — documented in Task 9 + templates/AGENTS.md
- Manifest 4-column shape consistent across "Fragment manifest format" section, `render-kb.sh` parsing, and Task 14 generation

**4. Scope:**
- 17 tasks, each 2-10 minutes (harvest task 14 is the longest — live fetches)
- Single coherent skill; no sub-project decomposition needed
- Two-stage harvest/render model makes L2 mechanically testable (the key plan-level refinement over the spec)

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-28-knowledge-map-skill.md`. Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration
2. **Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
