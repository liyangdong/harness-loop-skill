# Harvest Pipeline (H1-H5)

> The live, agent-driven extraction that turns deepwiki + codegraph into render
> fragments. Non-deterministic by nature (live sources) — that's why its output is
> committed as fragments and re-rendered deterministically by `scripts/render-kb.sh`.
> This file is the playbook the executing agent follows at harvest time. It is the
> skill's intellectual core: be concrete and complete.

## Conventions

- Use `webReader` (MCP) to fetch deepwiki pages as markdown.
- Use `codegraph_explore` (MCP, with `projectPath`) OR shell `codegraph explore "<symbols>"`
  to verify anchors. Both return verbatim source + call-path + blast-radius caller count.
- Every extracted citation has shape `<repo-relative-path>:<line>` or
  `<path>:<line>-<line>`. Normalize deepwiki's `(path:line)` / `path:line` variants to
  this shape on parse.
- Write all harvest output under `<output>/.meta/`. Nothing else under `<output>/` is
  written by harvest; the renderer (H5b) writes `KNOWLEDGE.md` / `domains/` / `drift.md`.
- Timestamps: obtain from the host (do NOT call `Date.now()` inside tooling). Record the
  value once in `sources.json.generatedAt` and reuse it for `fragments/regen-timestamp.txt`
  so a single harvest has a single timestamp.
- Repo-relative paths are resolved against Q1 (`repo_path`); codegraph queries are scoped
  to Q3 (`projectPath`).

## H1 — Fetch deepwiki root, parse subsystem skeleton

1. `webReader({{Q2}})` → root markdown.
2. Parse the subsystem taxonomy:
   - Find the `## Major Subsystems` heading (or the nearest equivalent H2 — some repos
     use `## Architecture`, `## Components`, `## Modules`). If none is found, set a
     parse-failure flag (see fallback below).
   - Under it, each `### <Name>` (or `- **<Name>**` list item) is a top-level subsystem.
   - For each subsystem, capture the "See detailed documentation: <Name>" link (or the
     subsystem name's slug) → subsystem deep-dive URL. Derive as `<Q2>/<id-slug>`
     when an explicit link is absent.
3. Parse per-subsystem Core Classes with their `(path:line)` citations. Each citation
   becomes a candidate anchor: `{symbol, location, citedLine}`.
4. Parse the repo Overview mission (1-3 lines) + Project Structure table (markdown).
5. Output to `.meta/harvest-data.json`:
   - `overview.mission`, `overview.projectStructure`
   - `domains[].{id, name, deepwikiUrl, coreClasses:[{symbol, location, citedLine}]}`
     — one domain per parsed subsystem.
6. **Return the subsystem list to the wizard.** This is what populates Q5's options
   (label = subsystem name, description = one-line purpose from the root page). Do NOT
   ask Q5 until this return completes.

If the `## Major Subsystems` heading is absent (parse-failure flag set): surface a single
free-text Q5 fallback ("manual subsystem list") and let the user type domain names
(comma-separated). Use those names verbatim as both subsystem name and domain id
(kebab-cased); `deepwikiUrl` and `coreClasses` stay empty for H2/H3 to fill (or remain
empty if the user is supplying the structure manually).

## H2 — Fetch each selected subsystem's deep-dive page

For each subsystem in Q5's selection:

1. `webReader(<subsystem deep-dive URL>)` → markdown.
2. Parse concept clusters — the H3/H4 subsections under the subsystem page. Each
   `### <Cluster>` (or `## <Cluster>` if the deep-dive page uses H2 for clusters) is one
   concept cluster.
3. For each concept cluster, capture:
   - Its narrative (the prose body — Key Concepts / Key Characteristics / design intent).
   - Its `Sources: path:line ...` citations (the trailing Sources line(s) on the section).
     Each becomes a candidate anchor tied to this cluster.
4. Append to `harvest-data.json` under
   `domains[].concepts[].{name, description, citations:[{symbol, location, citedLine}]}`.

If a subsystem deep-dive page fails to fetch (404, network), record the domain with an
empty `concepts[]` and a `fetchError` field; H4 will flag it as an orphan cluster so the
user sees the gap.

## H3 — Verify every citation via codegraph

For each citation `(symbol, location, citedLine)` collected in H1 (Core Classes) and H2
(concept cluster Sources):

1. Query `codegraph explore "<symbol>"` with `projectPath={{Q3}}` (MCP tool) or
   `codegraph explore "<symbol>" --project "{{Q3}}"` (shell).
2. Classify the anchor into one of four statuses:
   - **RESOLVED** — the symbol exists in the index. Record its current file + the
     call-path summary codegraph returns + `callerCount` (the blast-radius caller count
     codegraph reports). The citedLine may differ from the current line; that's fine as
     long as it falls within the symbol's body (see STALE below).
   - **STALE** — the symbol is resolvable, but `citedLine` has drifted beyond the
     symbol's current body (e.g., the method moved or grew). Record the current
     location + callPath + callerCount as for RESOLVED, but flag the drift.
   - **MISSING** — the file or symbol is not found in the index. Record `location` and
     `citedLine` as-is; leave `callPath` and `callerCount` empty.
   - **UNVERIFIED** — `.codegraph/` is missing at projectPath. Record every citation
     as-is with status `UNVERIFIED`; do not attempt codegraph queries. Surface a single
     warning to the user once (not per-anchor).
3. Write to `harvest-data.json`:
   `domains[].anchors[].{concept, symbol, location, citedLine, status, callPath, callerCount}`.
   The `concept` field ties the anchor back to the concept cluster (or "Core Class" for
   H1-sourced anchors).

Aggregate every anchor (all domains, flat) into `.meta/anchors.json` as a single array.
This is the L3/L4 re-check surface: L3 re-runs codegraph on each entry; L4 diffs statuses
against the prior baseline.

## H4 — Drift analysis

Recompute from `harvest-data.json` (no new network/codegraph calls beyond what H3 already
made, except the blindspot blast-radius query which may need extra lookups):

- **orphans** — concept clusters whose citations are ALL (`MISSING` | `STALE` |
  `UNVERIFIED`). Semantically: "deepwiki says it but code can't confirm it." For each,
  record `{concept, domain, reason}` where `reason` is one of `all-missing`,
  `all-stale`, `all-unverified`, or `fetch-error` (the H2 fetch failed).
- **blindspots** — for each selected subsystem's Core Classes, take the codegraph
  blast-radius `callerCount` (from H3). Symbols with high `callerCount` (> threshold,
  default `20`) that are NOT cited by any deepwiki concept cluster → "code has it but
  deepwiki didn't cover it." For each, record
  `{symbol, location, callerCount, suggestedDomain}`. The `suggestedDomain` is the
  subsystem whose Core Classes list the symbol belongs to (i.e., where it would
  naturally be documented).

  If `.codegraph/` is missing (Q3 degraded path), skip the blindspot step entirely and
  record an empty `blindspots[]` with a note in `sources.json`.

Write `harvest-data.json.drift.{orphans[], blindspots[]}`. These feed the
`drift-summary.md` global fragment and the per-domain `<id>-drift.md` fragments in H5a.

## H5a — Write render fragments + manifest

Convert `harvest-data.json` into pre-rendered markdown fragments under
`.meta/fragments/` and a `manifest.tsv`. The manifest is the contract between harvest
(non-deterministic) and render (deterministic): every fragment gets exactly one row.

**Manifest format** — 4 tab-separated columns per row:
`scope \t id \t placeholder \t path`. `id` is empty for `global`/`drift` scope rows; for
`domain` scope rows it is the domain id. `#` lines are comments.

Write ONE fragment file per variable section:

- **Global** (`scope=global`, `id=<empty>`):
  - `overview-mission.md` → placeholder `MISSION` (the 1-3 line repo mission)
  - `overview-structure.md` → `PROJECT_STRUCTURE` (the Module Organization table)
  - `knowledge-topology.md` → `TOPOLOGY` (the domain → concept-cluster → file map; one
    line per domain — see "Fragment rendering rules" below)
  - `drift-summary.md` → `DRIFT_SUMMARY` (orphan/blindspot counts + pointer to drift.md)
  - `entry-points.md` → `ENTRY_POINTS` (the two main entry symbols as `file:symbol`
    one-liners)
  - `regen-note.md` → `REGEN_NOTE` (how to regenerate: skill + render-kb.sh)
- **Drift** (`scope=drift`, `id=<empty>`):
  - `regen-timestamp.txt` → `REGEN_TIMESTAMP` (the host-supplied ISO timestamp)
  - `orphans-table.md` → `ORPHANS_TABLE` (markdown table: concept | domain | reason)
  - `blindspots-table.md` → `BLINDSPOTS_TABLE` (markdown table: symbol | location |
    callerCount | suggestedDomain)
- **Per domain `<id>`** (`scope=domain`, `id=<domain-id>`):
  - `<id>-name.txt` → `DOMAIN_NAME` (subsystem display name)
  - `<id>-url.txt` → `DEEPWIKI_URL`
  - `<id>-status.txt` → `STATUS` (`verified` | `partial` | `drifted`, derived from anchor
    statuses — see rules below)
  - `<id>-narrative.md` → `NARRATIVE` (the subsystem's business description from H1/H2)
  - `<id>-concepts.md` → `CONCEPTS` (the concept cluster subsections; shape scales with Q6)
  - `<id>-anchors.md` → `ANCHORS_TABLE` (the anchor table markdown — see row format below)
  - `<id>-drift.md` → `DOMAIN_DRIFT` (this domain's orphan + blindspot lines)
  - `<id>-crosslinks.md` → `CROSS_LINKS` (links to other domains — see rule below)

Write `manifest.tsv` enumerating every fragment with its `scope \t id \t placeholder \t path`.
Every row's `path` is relative to `.meta/fragments/`.

Also write:
- `.meta/sources.json` — `{repo, repoName, deepwikiRoot, projectPath, generatedAt, depth,
  strict, domains:[<id>...]}`. `repoName` is the basename of `repo`. `generatedAt` is the
  host timestamp (same value as `regen-timestamp.txt`). `depth` = Q6, `strict` = Q7,
  `domains` = the selected Q5 ids in order.
- `.meta/anchors.json` — finalize the flat anchor array from H3.

## H5b — Render

Run the deterministic renderer:

```bash
bash <skill>/scripts/render-kb.sh <output>/.meta/fragments <output>
```

This reads `manifest.tsv`, substitutes each fragment into the matching template via `sed`,
and emits `KNOWLEDGE.md`, `domains/<id>.md` (one per Q5 subsystem), and `drift.md` from
`templates/*.tmpl` + the fragments. The renderer has no external dependencies — same
fragments + same templates always produce identical bytes (the L2 contract).

## Fragment rendering rules (must match render-kb.sh exactly)

These rules govern how `harvest-data.json` fields become fragment bytes. The renderer
trusts the fragments verbatim, so harvest MUST format them correctly here.

- **Anchor table row format** (one row per anchor in `<id>-anchors.md`):
  `| <concept> | <symbol> | <location>:<line> | <status-emoji> | <callPath> |`
  - status-emoji mapping: `RESOLVED` → `✅`, `STALE` → `⚠️`, `MISSING` → `❌`,
    `UNVERIFIED` → `❓`.
  - `<callPath>` is the short call-flow summary codegraph returned (e.g.
    `addDocument→DocumentsWriter→DWPT`); empty for MISSING/UNVERIFIED.
  - Group rows by concept cluster when Q6=medium; flatten to a single table when Q6=shallow.
- **Domain status derivation** (`<id>-status.txt`, derived from that domain's anchors):
  - all anchors `RESOLVED` → `verified`
  - any `STALE` (and no `MISSING`/orphan) → `partial`
  - any `MISSING` or any orphan concept in this domain → `drifted`
  - all `UNVERIFIED` → `verified` with a caveat (treat as verified-shape since codegraph
    wasn't available; the caveat surfaces in `DRIFT_SUMMARY`).
  - **Precedence for UNVERIFIED (no-`.codegraph/` degraded mode):** when the cause is
    UNVERIFIED (absence of verification, not confirmed drift), status is `unverified` —
    distinct from `drifted`. An all-UNVERIFIED domain is `unverified`, NOT `drifted`, and
    an orphan cluster caused solely by UNVERIFIED anchors is NOT a drift orphan (record it
    but don't force the domain to `drifted`). **Drift (`drifted`) requires at least one
    MISSING or STALE anchor.** This invariant resolves the apparent contradiction between
    the `all-UNVERIFIED → verified` rule above (which now reads as `unverified`) and H4's
    `any orphan → drifted`: an orphan whose reason is `all-unverified` does NOT trigger
    `drifted`, only `all-missing` / `all-stale` orphans do.
- **Topology line per domain** (in `knowledge-topology.md`):
  `- **<name>** → domains/<id>.md — <cluster-count> concept clusters, <anchor-count>
  anchors (<resolved-count>✅)`
  - `<cluster-count>` = number of concept clusters parsed for this domain in H2.
  - `<anchor-count>` = total anchors for this domain (H1 Core Classes + H2 cluster
    citations).
  - `<resolved-count>` = anchors with status `RESOLVED`.
- **Cross-links** (in `<id>-crosslinks.md`): a domain links to every OTHER selected
  domain whose Core Classes appear in this domain's anchor `callPath` summaries. Rationale:
  if domain A's call paths reference domain B's Core Classes, A depends on B and should
  point to it. Format: `- → <other-id>.md（<one-line dependency reason>）`.
- **Drift tables** (`orphans-table.md`, `blindspots-table.md`): standard markdown tables
  with headers `| 概念 | 领域 | 原因 |` and `| 符号 | 位置 | caller 数 | 建议领域 |`
  respectively. Empty array → a single `(none)` row.
- **Global fragments stay terse** — `KNOWLEDGE.md` must render to ≤100 lines. Mission ≤3
  lines, topology one line per domain, drift-summary one line per count + pointer.
