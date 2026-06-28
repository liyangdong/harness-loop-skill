# examples/

This directory holds L2 diff baselines for the knowledge-map skill: committed
render fragments + the rendered output they produce. The L2 check
(`scripts/check-examples.sh`) re-renders each example's fragments via
`scripts/render-kb.sh` and diffs the result byte-for-byte against the committed
rendered output. Same fragments + same templates → identical bytes.

## lucene/ — the canonical baseline

`examples/lucene/` is the canonical L2 baseline. It is the skill's integration
test: it exercises the full harvest → render → check loop against a real,
codegraph-indexed repo (Apache Lucene) with a real deepwiki page.

Layout (per `wizard/summary-format.md`):

- `answers.json` — the Q1-Q7 snapshot that produced this example (provenance +
  reproducibility). Re-running harvest with these answers should reproduce the
  `.meta/` content (modulo live drift).
- `.meta/` — harvest output: `harvest-data.json`, `sources.json`, `anchors.json`,
  `fragments/` (manifest.tsv + 6 global + 3 drift + 8×5 domain fragments).
- `KNOWLEDGE.md`, `drift.md`, `domains/<id>.md` — the rendered output (the L2
  snapshot that `check-examples.sh` diffs against).

## Refreshing after external drift

The committed baseline reflects deepwiki + code at one point in time. When
external sources drift (deepwiki rewrites a page, Lucene refactors a cited
symbol), re-run the harvest with the same `answers.json` and commit the updated
fragments + re-rendered output in ONE "snapshot refresh" commit (per spec §8.2),
so the L2 diff stays green and the change is reviewable as a unit. Do not mix a
snapshot refresh with unrelated changes.
