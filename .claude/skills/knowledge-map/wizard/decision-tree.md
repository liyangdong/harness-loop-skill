# Decision Tree: answers → harvest/render behavior

> Map from each wizard answer (Q1-Q7) to the concrete harvest behavior, render shape,
> and output paths. Keep this file in sync with `questions.md` — any option added/removed
> there MUST be reflected here in the same commit (per `wizard/AGENTS.md` §5).
>
> All `<output>` paths are relative to the Q4 output dir. All `.meta/` paths are relative
> to `<output>/.meta/`. Domain ids are kebab-case of the deepwiki subsystem name.

---

## Q5 → domains harvested + rendered

Each selected subsystem becomes one domain. Domain id = kebab-case of the subsystem name
(strip "System" suffix when it's purely generic, lowercase, hyphenate spaces):

- "Indexing System" → `indexing`
- "Search System" → `search`
- "Index Data Structures" → `index-data-structures`
- "Analysis System" → `analysis`
- "Build and Release System" → `build-release`

For each selected subsystem:
1. **H2** fetches the deepwiki deep-dive page at `<Q2>/<id-slug>` (e.g.
   `https://deepwiki.com/apache/lucene/indexing`), parses concept clusters + `Sources:`
   citations.
2. **H3** verifies every citation via `codegraph explore` against Q3's projectPath.
3. **H5a** writes `domains/<id>.md` render fragments under `.meta/fragments/<id>-*`
   (name, url, status, narrative, concepts, anchors, drift, crosslinks).
4. **H5b** renders `domains/<id>.md` from `domain-knowledge.md.tmpl` + those fragments.

Domain count = `len(Q5 selection)`. This is the single biggest cost driver — each
unselected subsystem skips a deepwiki fetch, a codegraph verify pass, and 8 fragment
writes.

---

## Q6 → render shape

Controls how H5a groups fragments and how H5b renders the domain file. Default: `medium`.

| Q6 answer | Domain file shape | Fragment impact |
|---|---|---|
| shallow | `domains/<id>.md` has narrative + a single flat anchor list section (no per-cluster breakdown) | Fewest fragments: `<id>-anchors.md` is one flat table; `<id>-concepts.md` is a one-line-per-cluster bullet list |
| medium | `domains/<id>.md` has narrative + one section per concept cluster, each with its own anchor table | `<id>-concepts.md` carries cluster subsections; `<id>-anchors.md` groups rows by cluster |
| deep | Each concept cluster becomes its own `domains/<id>/<cluster>.md` sub-file (finest progressive disclosure) | Per-cluster fragment sets under `.meta/fragments/<id>/<cluster>-*`; manifest gains one row per cluster |

**Deep mode manifest scope:** the manifest `scope` column stays `domain` (unchanged from
shallow/medium); the `id` column carries `<id>/<cluster>` for deep-mode cluster rows, and
the renderer writes `domains/<id>/<cluster>.md` (vs `domains/<id>.md` for the domain-level
row). I.e. deep mode adds cluster rows to the same `domain` scope, it does NOT introduce a
compound `domain/<id>/<cluster>` scope value.

Fragment count scales with depth: shallow ≈ 8 per domain, medium ≈ 8 per domain (richer
content), deep ≈ 8 × cluster-count per domain. The `knowledge-topology.md` global
fragment also changes shape — deep lists cluster-level files; shallow/medium list
domain-level files.

---

## Q7 → check script strictness

| Q7 answer | `{{STRICT_MODE}}` in `check-*.sh.tmpl` | Behavior in generated in-target scripts |
|---|---|---|
| strict | `strict` | `set -e`-style semantics: any check failure exits 1; pre-commit blocks the commit; L4 new-drift blocks merge |
| advisory | `advisory` | Failures print `⚠️` to stderr and exit 0; pre-commit allows commit; L4 new-drift writes drift.md but does not block |

Substituted into every `templates/checks/check-*.sh.tmpl` at copy time (the scripts are
copied into the target repo's `scripts/`, not rendered from fragments). The
`check-knowledge.sh` (L1), `check-anchors.sh` (L3), and `check-drift.sh` (L4) all read
this flag.

---

## Q3 → codegraph availability

| Condition | Behavior |
|---|---|
| `.codegraph/` exists at projectPath | H3 verifies every anchor (RESOLVED/STALE/MISSING); H4 computes blindspots from blast-radius callerCount; in-target L3/L4 enabled |
| `.codegraph/` missing at projectPath | H3 marks every anchor `UNVERIFIED` (records symbol/location as-is, no verification); domain status becomes `unverified` (NOT `drifted` — drift requires a MISSING/STALE anchor, UNVERIFIED alone is absence-of-verification); H4 blindspot step skipped (no callerCount available) and `all-unverified` orphan clusters are recorded but do NOT force the domain to `drifted`; in-target L3/L4 print a skip-warning and exit 0. Warn the user at Q3 time to index first. |

The degraded path still produces a usable KB — the conceptual skeleton (H1/H2) is
unaffected, only anchor verification and drift analysis degrade. The user can re-run
harvest later after indexing to populate RESOLVED statuses.

---

## Q4 → output location

| Mode | Output dir | Notes |
|---|---|---|
| real run | `<Q4>` (default `<repo>/docs/knowledge/`) | Writes into the target repo. Idempotent: overwrites generated sections, preserves `<!-- user -->` blocks, backs up existing files to `.bak` on first generation. |
| example/baseline | `.claude/skills/knowledge-map/examples/<repo-name>/` | Used when building the L2 diff baseline (e.g. `examples/lucene/`). Same file layout; the committed fragments + rendered output become the L2 snapshot. |

Both modes write the same file set (see `summary-format.md`). The only difference is the
directory root and whether the result is committed as a regression baseline.

---

## Q1 / Q2 → harvest sources

Q1 and Q2 are not decision branches — they are the harvest sources:
- **Q1 (repo_path)**: every citation is resolved repo-relative to this path; it is also
  the default for Q3's projectPath.
- **Q2 (deepwiki_url)**: H1 fetches this as the root page; H2 derives per-subsystem
  deep-dive URLs as `<Q2>/<id-slug>`.

Both are recorded verbatim in `.meta/sources.json` for provenance and re-harvest.

---

## Output path computation

Given an answer set (Q1-Q7) and the H1-parsed subsystem list filtered by Q5, the set of
files written into `<Q4>` is:

**Always written (harvest + render):**
- `.meta/harvest-data.json` (H1-H4 structured provenance)
- `.meta/sources.json` (H5a: repo/deepwikiRoot/projectPath/generatedAt/depth/strict)
- `.meta/anchors.json` (H5a: flat anchor array for L3/L4)
- `.meta/fragments/manifest.tsv` (H5a: 4-column scope/id/placeholder/path)
- `.meta/fragments/*.md` + `*.txt` (H5a: global + drift + per-domain fragments)
- `KNOWLEDGE.md` (H5b render, ≤100 lines)
- `drift.md` (H5b render)
- `domains/<id>.md` × `len(Q5)` (H5b render; `domains/<id>/<cluster>.md` if Q6=deep)
- `scripts/check-knowledge.sh` + `check-anchors.sh` + `check-drift.sh` (in-target L1/L3/L4, copied with `{{STRICT_MODE}}` = Q7)

`summary-format.md` enumerates exactly this set (with `{{count}}` = `len(Q5)`) before the
user confirms.
