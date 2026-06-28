# Config Summary Format

After collecting Q1-Q7 and running H1 (so the subsystem count is known), render this
template with the answers substituted in, and print it to the user. **Wait for `Y/n`
before any writes** (per SKILL.md step 5 — the Y/n gate precedes ALL writes, including
H2-H5 and render). Only proceed on explicit `Y`; on `n` or any other reply, discard all
collected answers and exit cleanly without writing anything.

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

## Field rendering rules

- **`{{Q1}}`** — verbatim repo path (e.g. `D:/project/lucene-main/lucene-main/lucene`).
- **`{{Q2}}`** — verbatim deepwiki URL (e.g. `https://deepwiki.com/apache/lucene`).
- **`{{Q3}}`** — verbatim projectPath; note if `.codegraph/` was missing (append
  ` (⚠️ 无 .codegraph/ 索引，锚点将标记 UNVERIFIED)`).
- **`{{Q4}}`** — verbatim output dir.
- **`{{Q5_list}}`** — selected subsystem names joined with `、` (e.g.
  `Indexing System、Search System、Analysis System`).
- **`{{count}}`** — `len(Q5 selection)` (= number of domain files that will be rendered).
- **`{{Q6}}`** — `shallow` / `medium` / `deep`.
- **`{{Q7}}`** — `advisory` / `strict`.
- **`{{anchor_count_estimate}}`** — sum of citations collected in H1 across selected
  subsystems' Core Classes (a lower bound; H2 may add more from concept clusters). Display
  as `~N`.

## Rules

- The subsystem list + count come from H1 (already run before this summary is rendered).
  Do not render the summary until H1 has returned.
- The file list is the same regardless of Q6 depth — depth changes fragment richness and
  (for deep) adds per-cluster sub-files, but the top-level shape stays as listed. If
  Q6=deep, optionally append ` (deep 模式：概念簇拆为 domains/<id>/<cluster>.md 子文件)`.
- **After `Y`**: run H2-H5a (harvest) + H5b (render). Existing files at `<Q4>` are backed
  up to `<path>.bak` on first generation; `<!-- user -->` blocks are preserved on
  re-runs.
- **After `n`**: abort without writing anything. Print `已取消，未写入任何文件。` and exit.
- **Any other reply**: re-print the prompt with `(请回答 Y 或 n)`. Do not abort; the user
  may have mistyped.
