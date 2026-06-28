# wizard/questions.md — the 7-question AskUserQuestion script

> This file is the standalone script for the knowledge-map wizard. Read top to bottom.
> The flow is two-phase: ask Q1-Q4 → run harvest step H1 (fetch deepwiki root, parse
> subsystems) → ask Q5-Q7 (Q5 options come from H1's parse). Each block contains
> everything needed to call AskUserQuestion. Answers feed `decision-tree.md` and
> `harvest-pipeline.md`.

---

## Q1: 目标仓路径 (repo_path)

**Type:** free-text
**AskUserQuestion call:**
- question: "目标代码仓的本地路径是什么？（codegraph 应已建索引）"
- header: "仓路径"
- answer shape: a path, e.g. `D:/project/lucene-main/lucene-main/lucene`

**Dependencies:** none (always asked first)
**Recommended default:** none — user must supply
**Used by:** H1 (resolves repo-relative citation paths), H3 (codegraph projectPath default), `sources.json.repo`

---

## Q2: deepwiki URL (deepwiki_url)

**Type:** free-text
**AskUserQuestion call:**
- question: "该仓的 deepwiki 页面 URL 是什么？（提供概念骨架与业务叙述）"
- header: "deepwiki"
- answer shape: a URL, e.g. `https://deepwiki.com/apache/lucene`

**Dependencies:** none (asked with Q1-Q4 in the first phase)
**Recommended default:** none — user must supply
**Used by:** H1 (fetches this URL as the root page), H2 (derives per-subsystem deep-dive URLs under it), `sources.json.deepwikiRoot`

---

## Q3: codegraph projectPath (project_path)

**Type:** free-text
**AskUserQuestion call:**
- question: "codegraph 索引所在的 projectPath？（默认同 Q1 仓根；该目录下应存在 .codegraph/）"
- header: "projectPath"
- answer shape: a path, e.g. `D:/project/lucene-main/lucene-main/lucene`

**Dependencies:** default value = Q1 answer
**Recommended default:** `<Q1>` (the repo root)
**Precondition:** the path MUST contain a `.codegraph/` directory. If it is missing, warn
the user: "未找到 .codegraph/ 索引。建议先用 codegraph 对该仓建索引；否则 H3 会把所有锚点
标记为 UNVERIFIED，L3/L4 检查会跳过。" Let the user proceed anyway (degraded mode) or
cancel to go index first.
**Used by:** H3 (every `codegraph explore` call passes this as projectPath), H4 (blindspot
blast-radius queries), `sources.json.projectPath`. See `decision-tree.md` §"Q3 → codegraph
availability" for the missing-index degraded path.

---

## Q4: 输出目录 (output_dir)

**Type:** free-text
**AskUserQuestion call:**
- question: "知识库生成到哪个目录？（默认 <repo>/docs/knowledge/；做示例基线则用 skill 内 examples/<repo-name>/）"
- header: "输出目录"
- answer shape: a path, e.g. `D:/project/lucene-main/lucene-main/lucene/docs/knowledge/` or
  `.claude/skills/knowledge-map/examples/lucene/`

**Dependencies:** default value = `<Q1>/docs/knowledge/`
**Recommended default:** `<Q1>/docs/knowledge/`
**Used by:** every harvest write (`.meta/` lands under here) and every render write
(`KNOWLEDGE.md`, `domains/`, `drift.md` land here). See `decision-tree.md` §"Q4 → output
location" for real-run vs example-baseline modes.

---

## ▶ Run harvest step H1 now

After Q1-Q4 are collected, execute `harvest-pipeline.md` H1: `webReader({{Q2}})`, parse
`## Major Subsystems` into a subsystem list with deep-dive URLs + Core Classes, write the
overview + domains skeleton to `.meta/harvest-data.json`, and **return the subsystem list
to the wizard**. That list populates Q5's options below. Do NOT ask Q5 before H1 returns.

---

## Q5: 映射哪些顶层子系统 (subsystems)

**Type:** multiSelect
**AskUserQuestion call:**
- question: "映射哪些顶层子系统为独立的 domain 文件？（多选；运行时由 H1 解析的子系统列表填充）"
- header: "子系统"
- multiSelect: true
- options: **POPULATED AT RUNTIME from H1** — one option per parsed subsystem:
  - label: `<subsystem name>` (e.g. `Indexing System`)
  - description: `<one-line purpose captured from the deepwiki root page>`

**Dependencies:** ONLY asked after H1 has returned the parsed subsystem list. The option
list is built programmatically; it is NOT hardcoded in this file.
**Recommended default:** ALL options selected (map every top-level subsystem).
**Used by:** drives domain count and which deep-dive pages H2 fetches. Each selected
subsystem becomes one `domains/<id>.md`. See `decision-tree.md` §"Q5 → domains harvested +
rendered" for the subsystem-name → kebab-case id mapping.

> **Fallback if H1 fails to parse:** if H1 could not find a `## Major Subsystems` heading
> (or equivalent), surface a single free-text option instead:
> - label: `manual subsystem list`, description: `H1 未能从 deepwiki 解析子系统列表；手动输入要映射的领域名（逗号分隔）`
>
> If the user picks this, follow up with a plain-text request for comma-separated domain
> names and use them verbatim as both subsystem name and domain id (kebab-cased).

---

## Q6: 深度 (depth)

**Type:** single-select
**AskUserQuestion call:**
- question: "知识文件的深度？决定 domain 文件的拆分粒度与锚点表密度。"
- header: "深度"
- multiSelect: false
- options:
  - label: "shallow", description: "每个 domain 一个文件：叙述 + 锚点列表作为扁平段落。锚点最少、文件最薄。"
  - label: "medium", description: "每个 domain 一个文件：叙述 + 每个概念簇各带一张锚点表。平衡可读性与覆盖。默认推荐。"
  - label: "deep", description: "每个概念簇各自成独立文件 domains/<id>/<cluster>.md（子目录）。最细的渐进披露，锚点最多。"
- recommended default: "medium"

**Dependencies:** always asked (in the Q5-Q7 second phase)
**Used by:** controls H5a fragment shape and the domain file structure rendered by H5b.
See `decision-tree.md` §"Q6 → render shape". Fragment count scales with depth (deep
produces per-cluster files; shallow collapses to one section per domain).

---

## Q7: 严格度 (strict)

**Type:** single-select
**AskUserQuestion call:**
- question: "in-target 检查脚本的严格度？advisory 仅警告写 drift.md，strict 会因新漂移阻断。"
- header: "严格度"
- multiSelect: false
- options:
  - label: "advisory", description: "L4 新漂移只写 drift.md 并 stderr 警告，exit 0 不阻断。默认推荐，适合试运行。"
  - label: "strict", description: "L4 检测到相对上次基线的新漂移即 exit 1 阻断 commit/merge。最大化机械化约束。"
- recommended default: "advisory"

**Dependencies:** always asked; this is the final question
**Used by:** substituted into every `templates/checks/check-*.sh.tmpl` as `{{STRICT_MODE}}`
at copy time, controlling exit codes of the in-target L1/L3/L4 scripts. See
`decision-tree.md` §"Q7 → check script strictness".

---

## Post-question step

After Q7 is answered, render `wizard/summary-format.md` with all 7 answers (Q5 expanded
to the selected subsystem list; `{{count}}` = selected subsystem count = `len(Q5 selection)`,
NOT the full H1-parsed count — the summary reflects what will actually be generated) and
print the configuration summary. Wait for explicit `Y` confirmation before any writes
(SKILL.md step 5 — the Y/n gate precedes ALL writes, including H2-H5 and render). On `n`
or abort, discard all collected answers and exit cleanly without writing anything.
