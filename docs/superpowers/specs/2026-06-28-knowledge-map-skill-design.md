# Knowledge-Map Skill 设计文档

- **日期**：2026-06-28
- **状态**：Draft（待用户审阅）
- **作者**：Claude（经与用户交互式 brainstorming 产出）
- **落地路径**：`.claude/skills/knowledge-map/`
- **示例基线**：`.claude/skills/knowledge-map/examples/lucene/`（目标仓 `D:\project\lucene-main\lucene-main\lucene` + deepwiki `https://deepwiki.com/apache/lucene`）

---

## 1. 问题陈述

### 1.1 背景

agent 接手一个陌生的大型代码仓时，最痛的不是"代码在哪"，而是"业务上这仓分几块、每块在干什么、概念之间怎么串起来"。现状的两个信息源各有缺陷：

- **代码本身**（经 codegraph）极其精确——符号、调用路径、blast radius 都在——但没有业务语义层。agent 知道 `IndexWriter.addDocument` 调了谁，不知道它在"索引流水线"这个业务概念里扮演什么角色。
- **deepwiki**（人类策展的概念结构）有业务语义层——子系统分类、概念簇、叙述——但它的 `file:line` 引用可能漂移（代码改了 deepwiki 没跟上），且不暴露调用图。

两源分离时，agent 要么陷入纯符号导航（丢失业务意图），要么盲信 deepwiki（被过时引用误导）。

### 1.2 目标

构建一个 **项目级 skill `knowledge-map`**，与 `harness-loop` 平级。给定 **一个代码仓 + 它的 deepwiki 页**，生成一份 **agent 优先** 的业务知识库：

- **融合**：deepwiki 提供概念骨架与业务叙述；codegraph 提供可验证的代码锚点 + 调用路径 + 漂移检测。
- **产出**：`KNOWLEDGE.md`（≤100 行地图索引）+ 按业务领域拆分的知识文件 + 漂移报告 + 溯源元数据 + L1-L4 检查脚本。
- **可复用**：任意 repo + deepwiki URL 都能跑；lucene 作为首个 L2 基线 example。
- **运行时**：复用 webReader（抓 deepwiki）与 codegraph（验锚点），**不重新实现爬虫或代码索引**。

### 1.3 非目标

- ❌ 不自建爬虫 / 不实现代码索引（复用 webReader + codegraph）
- ❌ 不内嵌 LLM 调用逻辑（由宿主 agent 驱动）
- ❌ 不做人类排版精美的文档站（首要消费者是 agent）
- ❌ 不做 i18n（中文为主，术语 / 代码标识保留英文）
- ❌ 不打包为 marketplace plugin
- ❌ 不取代 harness-loop（两者职责正交：本 skill 产"业务知识地图"，harness-loop 产"agent 约束系统"）

---

## 2. 关键设计决策（已与用户确认）

| # | 决策点 | 选择 | 理由 |
|---|---|---|---|
| D1 | 知识库首要消费者 | **Agent 优先** | 每个业务概念必须锚定到 codegraph 可验证的代码符号；人类可读是副产品 |
| D2 | 两源融合模式 | **deepwiki 骨架 + codegraph 锚点** | deepwiki 出概念拓扑与叙述；codegraph 出代码现实 + 调用路径 + 漂移检测。分工明确 |
| D3 | KB 磁盘形态 | **地图索引 + 按领域拆分文件** | 对齐 harness-loop 的 map-not-manual + 渐进披露；拓扑：模块级顶层 / 概念簇二级 / 每节点锥定到代码 |
| D4 | 验证机制 | **L1-L4 全套含漂移检测** | 漂移检测是护城河：暴露 orphan（说了但代码找不到）与 blindspot（代码有但没说） |
| D5 | 实现路线 | **交互向导 + 模板库 + 全套检查**（A） | 与 harness-loop 同构；lucene 成为正经 L2 基线 |

---

## 3. 数据源验证（设计前已实测）

### 3.1 deepwiki（webReader 可抓）

`https://deepwiki.com/apache/lucene` 返回结构化 markdown：

- **子系统分类**：`## Major Subsystems` 下 Indexing System / Search System / Index Data Structures / Analysis System / Build and Release System
- **二级概念页链接**：每子系统段尾 "See detailed documentation: X"（即二级节点）
- **核心类引用**：每段列 Core Classes，带 `file:line` 引用，如 `IndexWriter ... (lucene/core/src/java/org/apache/lucene/index/IndexWriter.java197-198)`
- **Sources 行**：叙述段尾 `Sources: <file>:<line> <file>:<line> ...`
- **业务叙述**：Key Concepts / Key Characteristics 等段落

→ 提取器按 `## Major Subsystems` / "See detailed documentation:" / `Sources:` 三个模式解析即可。

### 3.2 codegraph（projectPath 可查）

对 lucene 以 `codegraph_explore` (projectPath=`...lucene`) 查询 `IndexWriter DocumentsWriter ... addDocument` 实测：

- 返回符号的 **verbatim 源码**（带行号，等价于 Read）
- 返回 **调用路径** + **blast radius**（谁依赖它）
- 暴露 **动态分派跳点**（如 `addDocument` 运行时分派到 924 个 `LuceneTestCase` 实现——grep 跟不到的边）

→ L3 锚点解析、L4 漂移检测（blindspot 需入度/中心度，可由 blast radius caller 数近似）技术上可行。

---

## 4. 架构总览

### 4.1 Skill 形态

- **位置**：`.claude/skills/knowledge-map/`（项目级，与 harness-loop 平级）
- **形态**：交互式向导（7 题）+ 模板库 + harvest playbook（deepwiki+codegraph 提取）+ L1-L4 检查
- **触发**（SKILL.md description）：用户表达"梳理业务知识地图"、"建知识库"、"codegraph + deepwiki 建索引"、"让 agent 看懂这个大仓"、"business knowledge map" 等意图时

### 4.2 高层流程

```
用户说"给这个仓建业务知识地图" → skill 触发
  → AskUserQuestion Q1-Q4（仓 / deepwiki URL / projectPath / 输出目录）
  → 抓 deepwiki 根页 → 解析子系统列表
  → AskUserQuestion Q5（multiSelect，运行时填充：映射哪些子系统）+ Q6 深度 + Q7 严格度
  → 对每个选中子系统：抓 deep-dive 页 → 提取概念簇/引用/叙述
  → 对每条引用：codegraph 验证 → 锚点状态 + 调用路径
  → 漂移分析（orphan / blindspot）
  → 套模板拼装 → 写 KNOWLEDGE.md + domains/ + drift.md + .meta/
  → 打印配置摘要 + 等待 Y/n
```

### 4.3 核心约束

- **agent 优先**：每个概念节点都有可验证的代码锚点；无锚点的概念进 drift.md 标 orphan
- **deepwiki 为骨架、codegraph 为现实**：拓扑来自 deepwiki，锚点真伪由 codegraph 裁定，二者冲突时记录为漂移
- **零外部构建依赖**：复用 webReader + codegraph，不自建爬虫/索引
- **Windows-friendly**：检查脚本默认 bash（Git Bash），避免 PowerShell 强依赖
- **幂等**：重跑覆盖 `KNOWLEDGE.md` / `domains/*.md` / `drift.md`；保留用户手改段（用 `<!-- user -->` 标记区）

---

## 5. 向导问题流（7 题）

skill 触发后用 7 个 AskUserQuestion 收集决策。前 4 题先问（决定抓取目标），抓完 deepwiki 根页后再问 Q5-Q7（Q5 选项来自抓取结果）。

### Q1. 目标仓路径

- 自由文本，如 `D:/project/lucene-main/lucene-main/lucene`
- 决定 codegraph 查询基准与输出相对根

### Q2. deepwiki URL

- 自由文本，如 `https://deepwiki.com/apache/lucene`
- 决定概念骨架来源

### Q3. codegraph projectPath

- 自由文本，默认 = Q1 仓根
- 需存在 `.codegraph/`；不存在则提示先建索引或 L3/L4 转 advisory

### Q4. 输出目录

- 自由文本，默认 `<repo>/docs/knowledge/`
- example 模式下走 `.claude/skills/knowledge-map/examples/lucene/`

### Q5. 映射哪些顶层子系统（multiSelect）

- 选项**运行时由 deepwiki 根页解析填充**（lucene：Indexing / Search / Index Data Structures / Analysis / Build & Release，默认全选）
- 决定生成几个 domain 文件

### Q6. 深度

- **shallow**：仅模块文件，概念簇作为段内小节
- **medium（默认）**：模块文件 + 每概念簇带锚点表
- **deep**：每概念簇各自成独立文件（更细的渐进披露）

### Q7. 严格度

- **strict**：L4 新漂移阻断（与上次基线比）
- **advisory（默认）**：仅警告写 drift.md，不阻断

### 配置摘要 + 确认

所有问题答完后，skill 打印摘要（仓 / deepwiki / projectPath / 输出 / 选中子系统 / 深度 / 严格度 / 预计锚点数），等待 `Y/n`，确认后才落盘。

---

## 6. Harvest Pipeline（核心数据流）

> 落地为 `wizard/harvest-pipeline.md` 的 playbook，由宿主 agent 执行（非脚本）。

### 步骤 H1：抓 deepwiki 根页

- `webReader(url)` 取 markdown
- 解析 `## Major Subsystems`（或等价标题）→ 子系统列表
- 解析每个子系统的 "See detailed documentation: X" → 二级概念页 URL
- 解析每段 `Sources: file:line ...` → 候选锚点

### 步骤 H2：抓选中子系统的 deep-dive 页

- 对 Q5 选中的每个子系统，`webReader(subsystem-url)` 取其概念簇 + Core Classes 引用 + 叙述

### 步骤 H3：codegraph 验证每条引用

- 对每个候选锚点 `file:line` 或 `file:line-range`：
  - `codegraph_explore("<symbol>", {projectPath})` 或 shell `codegraph explore "<symbol>"`
  - **RESOLVED**：符号在位，补调用路径 + blast radius（caller 数）
  - **STALE**：文件存在但行号/签名已变（符号仍可解析但定位漂移）
  - **MISSING**：文件或符号不存在

### 步骤 H4：漂移分析（L4 输入）

- **orphan**：deepwiki 概念簇引用的全部锚点都 MISSING/STALE → 该概念"说了但代码找不到"
- **blindspot**：codegraph 报告高 caller 数（入度）的符号，未被任何 deepwiki 概念簇引用 → "代码有但没说"
  - blindspot 的符号候选来源：对选中子系统的 Core Classes 做一遍 codegraph blast-radius 查询，取 caller 数 Top-N 且未被引用者

### 步骤 H5：组装与落盘

- 写 `.meta/sources.json`（deepwiki URLs + projectPath + 生成时间戳，时间戳由宿主提供，skill 内不调 Date.now）
- 写 `.meta/anchors.json`（全部锚点 + 状态 + 调用路径摘要）——供 L3/L4 增量复检
- 套 `domain-knowledge.md.tmpl` 写每个 domain 文件
- 套 `drift-report.md.tmpl` 写 drift.md
- 套 `knowledge-index.md.tmpl` 写 KNOWLEDGE.md（≤100 行）

---

## 7. 生成产物结构

```
<output-dir>/                       # 默认 <repo>/docs/knowledge/
├── KNOWLEDGE.md                    # ≤100 行地图索引（map-mode 入口）
├── domains/
│   ├── indexing.md                 # 每子系统一个
│   ├── search.md
│   ├── analysis.md
│   ├── index-data-structures.md
│   └── build-release.md
├── drift.md                        # L4 漂移报告：orphans + blindspots
└── .meta/
    ├── sources.json                # 溯源：deepwiki URL + projectPath + 时间戳
    └── anchors.json                # 全部锚点 + 状态（供 L3/L4 增量复检）
```

### 7.1 KNOWLEDGE.md 布局（≤100 行）

```
1. 仓使命（1-3 行，来自 deepwiki Overview）
2. 地图拓扑：顶层子系统 → 二级概念簇 → 各自指向 domains/<name>.md
3. 整体漂移摘要（orphan/blindspot 计数 + 指向 drift.md）
4. 两大入口索引（IndexWriter / IndexSearcher 的 file:symbol 一行指针）
5. 模块组织表（来自 deepwiki Project Structure）
6. 再生说明（指向 .meta/ + skill）
```

### 7.2 domain 文件模板（`domain-knowledge.md.tmpl`）

```markdown
---
domain: <子系统名>
deepwiki: <deep-dive URL>
status: verified | partial | drifted   # 由锚点状态聚合
---

# <子系统名>

## 业务说明              ← deepwiki 叙述（Overview + Key Concepts）

## 核心概念簇            ← 二级节点
### <概念簇 1>
<说明 + 设计意图>

## 代码锚点              ← codegraph 验证
| 概念 | 符号 | 位置 | 状态 | 调用路径 |
|---|---|---|---|---|
| 索引入口 | IndexWriter | core/.../IndexWriter.java:197 | ✅ | addDocument→DocumentsWriter→DWPT |

## 漂移标记              ← L4
- ⚠ orphan: "<概念>" 被引用但无 RESOLVED 锚点
- ⚠ blindspot: 高中心度 `SegmentMerger` 未被 deepwiki 覆盖

## 交叉链接
- → search.md（本模块写的 segment 由 IndexSearcher 读）
- → index-data-structures.md
```

### 7.3 drift.md 模板

- **Orphans**：表（概念簇│deepwiki 来源│锚点状态│建议处理）
- **Blindspots**：表（符号│位置│caller 数│建议是否补进哪个 domain）
- 顶部一行 `regenerated: <时间戳>`（宿主写入）

### 7.4 .meta/anchors.json 结构

```json
{
  "projectPath": "...",
  "anchors": [
    {"concept": "索引流水线入口", "symbol": "IndexWriter",
     "location": "core/src/java/org/apache/lucene/index/IndexWriter.java",
     "citedLine": 197, "status": "RESOLVED",
     "callPath": "addDocument→DocumentsWriter→DocumentsWriterPerThread",
     "callerCount": 42}
  ]
}
```

### 7.5 幂等性

- **覆盖**：`KNOWLEDGE.md` / `domains/*.md` 的生成段 / `drift.md` / `.meta/*.json`
- **保留**：用户在 `<!-- user -->` 标记段内手写的内容
- **首次**：检测同名文件先备份 `.bak` 再覆盖

---

## 8. L1-L4 验证方案

| 层 | 脚本（skill 自身） | 检查内容 | strict 失败 | advisory |
|---|---|---|---|---|
| **L1 静态** | `scripts/check-skill.sh` | KNOWLEDGE.md≤100行 / 每个 domain 文件 frontmatter 合法(domain/deepwiki/status) / 内部 markdown 链接全可解析 / 无 `{{...}}` 占位符残留 | 阻断 | 警告 |
| **L2 基线 diff** | `scripts/check-examples.sh` | 用 `examples/lucene/answers.json` 重生成 → diff 已提交的 `examples/lucene/` → 零差异 | 阻断 | 阻断 |
| **L3 锚点解析** | `scripts/check-anchors.sh` | 读 example 的 `.meta/anchors.json`，逐条 `codegraph explore` 验证符号在位；报 RESOLVED/STALE/MISSING 计数 | 阻断 | 警告 |
| **L4 漂移检测** | `scripts/check-drift.sh` | 重算 orphan/blindspot，与上次基线比，新漂移写 drift.md | 阻断 | 警告 |

### 8.1 codegraph 依赖与执行环境

- L3/L4 需要 `.codegraph/` 索引 + `codegraph` CLI（shell：`codegraph explore "<symbol>"`）
- **默认约定**：
  - **CI（GitHub Actions）只跑 L1 + L2**——不需 codegraph，可纯文本复现，保证 example 不漂
  - **本地 pre-commit 跑全 L1-L4**——需本地有 codegraph 索引
- 检查脚本统一行为：strict 失败 exit 1 阻断，advisory 失败 exit 0 仅 stderr 警告
- 报错内嵌修复指令（harness-engineering 要求）：如 `❌ L3 MISSING: IndexWriter.java:197 符号未解析；修复：codegraph 重建索引或更新该锚点位置`

### 8.2 L2 快照的确定性契约

- harvest 依赖**活的** deepwiki（网络）+ **活的** codegraph，二者会随时间漂移，因此 L2 的"零 diff"不可能跨时间永久成立（本仓 issue 004 已记录同类"snapshot drift"问题）。
- **契约**：`examples/lucene/` 的提交快照（`answers.json` + `anchors.json` + 产物）是 L2 的真相。L2 检测的是 **skill 逻辑回归**（同样输入→同样输出），而非外部源漂移。
- 当 deepwiki 或代码确实变化导致 L2 出 diff：判定为**外部漂移**→有意识地更新快照并提交（一次"快照刷新"PR），而非 skill bug。刷新时同步更新 `.meta/sources.json` 的时间戳。
- 为降低抖动：L2 重生成时若 `anchors.json` 标记的 status 大面积从 RESOLVED 翻成 MISSING，先报"疑似 codegraph 索引过期"提示重建，而非直接判 skill 回归。

### 8.3 完成标准（skill 自身开发的"完成"门槛）

- [ ] L1 通过：skill 静态检查绿
- [ ] L2 通过：lucene example 重生成零 diff
- [ ] L3 通过：lucene example 每条锚点经 codegraph 解析（RESOLVED）
- [ ] L4 通过：lucene drift.md 生成、orphan/blindspot 枚举完整
- [ ] 手动实跑：对 lucene 跑一遍 skill，得到可用 agent 优先 KB
- [ ] README.md 写完（用法 + 扩展指南）

---

## 9. Skill 内部结构（dogfood map-not-manual）

```
.claude/skills/knowledge-map/
├── SKILL.md                    # ≤100 行：description + 触发 + 流程索引
├── README.md                   # skill 文档（怎么用、怎么扩展）
├── AGENTS.md                   # skill 自身编辑约定（dogfood，≤100 行）
│
├── wizard/                     # 向导逻辑
│   ├── AGENTS.md
│   ├── questions.md            # 7 题完整脚本
│   ├── decision-tree.md        # 答案 → 模板/深度路径
│   ├── harvest-pipeline.md     # H1-H5 deepwiki+codegraph 提取 playbook
│   └── summary-format.md       # 配置摘要格式
│
├── templates/                  # 渐进式加载的模板库
│   ├── AGENTS.md
│   ├── knowledge-index.md.tmpl          # KNOWLEDGE.md 拼装壳
│   ├── domain-knowledge.md.tmpl         # 每领域知识文件壳
│   ├── drift-report.md.tmpl             # 漂移报告壳
│   ├── meta-sources.json.tmpl
│   ├── meta-anchors.json.tmpl
│   └── checks/
│       ├── AGENTS.md
│       ├── check-knowledge.sh.tmpl      # L1（产到目标仓）
│       ├── check-anchors.sh.tmpl        # L3
│       └── check-drift.sh.tmpl          # L4
│
├── scripts/                    # skill 自身的校验
│   ├── check-skill.sh          # L1 静态校验 skill 自身
│   ├── check-examples.sh       # L2 端到端 diff（lucene）
│   ├── check-anchors.sh        # L3（封装 codegraph）
│   └── check-drift.sh          # L4
│
└── examples/                   # 端到端基线
    ├── AGENTS.md
    └── lucene/                 # ← L2 diff 基线
        ├── answers.json        # Q1-Q7 的答案快照
        ├── KNOWLEDGE.md
        ├── domains/
        │   ├── indexing.md
        │   ├── search.md
        │   ├── analysis.md
        │   ├── index-data-structures.md
        │   └── build-release.md
        ├── drift.md
        └── .meta/
            ├── sources.json
            └── anchors.json
```

### 9.1 SKILL.md 的 ≤100 行结构

```markdown
---
name: knowledge-map
description: <触发条件：梳理业务知识地图 / 建知识库 / codegraph+deepwiki 建索引>
---

# Knowledge-Map Skill

## 何时触发
<触发关键词列表>

## 7 步流程
1. 读 wizard/questions.md 问 Q1-Q4
2. 抓 deepwiki 根页（wizard/harvest-pipeline.md H1）
3. 问 Q5(multiSelect,运行时填充)/Q6/Q7
4. 对选中子系统跑 H2-H4（抓页→验锚点→漂移分析）
5. 套 templates/ 拼装（H5）
6. 写 KNOWLEDGE.md + domains/ + drift.md + .meta/
7. 打印摘要 + Y/n 确认

## 渐进式加载
- 只抓用户选中的子系统页（Q5）
- 深度（Q6）决定是否把概念簇拆成独立文件

## 模板索引 / 反模式 / 扩展
（指针，不堆细节）
```

### 9.2 关键设计决策

1. **SKILL.md 不写模板内容**：所有片段在 `templates/` 下独立维护（避免巨型指令文件）
2. **wizard 与 templates 分离**：wizard 是"逻辑/流程"，templates 是"内容"。改问题流不动模板，改模板不动流程
3. **harvest-pipeline.md 是 playbook 而非脚本**：deepwiki 结构因仓而异，由 agent 灵活解析；脚本只负责可机械化的 L1-L4
4. **examples/lucene/ 是 L2 测试基线**：skill 自我验证时 diff 生成结果 vs examples/
5. **dogfood**：skill 自身遵守 ≤100 行 + map-not-manual，改 skill 也走同一套约定

---

## 10. 待实现时确认的开放问题

1. **deepwiki 页面结构因仓而异**：lucene 已验证三模式（`## Major Subsystems` / "See detailed documentation:" / `Sources:`）。其他仓可能不同——harvest-pipeline 需降级路径（标记"无法提取子系统列表"，让用户手填 Q5 选项）。
2. **codegraph CLI 在 CI 的可用性**：当前假设本地有 `codegraph` 命令。CI 无索引时只跑 L1/L2。需确认 `codegraph explore` shell 命令的确切用法与退出码（实现时验证）。
3. **blindspot 的中心度度量**：当前用 codegraph blast-radius 的 caller 数近似。是否需要更精确的图中心度（实现时按效果定）。
4. **deepwiki 引用行号漂移粒度**：deepwiki 给的是行号或行号区间；codegraph 解析按符号而非行号，行号漂移归为 STALE（符号在、行号偏）。STALE 的阈值（行号偏多少仍算 RESOLVED）实现时定，默认同函数体内即 RESOLVED。
5. **lucene 仓污染**：lucene 是外部只读大仓；example 基线落在 skill 内 `examples/lucene/`，默认输出目录可配置，不污染 lucene 仓本身。

---

## 11. 参考资料

- `https://deepwiki.com/apache/lucene` — deepwiki 概念结构来源（已实测可抓）
- codegraph（`.codegraph/` + `codegraph_explore` MCP / `codegraph explore` shell）— 代码现实 + 调用图来源（已实测可查）
- 本仓 `.claude/skills/harness-loop/` — 同构参考 skill
- `docs/superpowers/specs/2026-06-27-harness-loop-skill-design.md` — 前序 skill 的设计文档（本 spec 沿用其结构与约定）

---

## 附录 A：术语表

| 术语 | 含义 |
|---|---|
| 业务知识地图 | 业务概念拓扑（子系统→概念簇）+ 每节点锥定到代码的索引 |
| 锚点 (anchor) | deepwiki 引用的 `file:line`，经 codegraph 验证后的状态记录 |
| RESOLVED / STALE / MISSING | 锚点三态：符号在位 / 文件变行号偏 / 找不到 |
| orphan | deepwiki 有概念簇但锚点全失效（说了但代码找不到） |
| blindspot | 高中心度代码符号未被 deepwiki 覆盖（代码有但没说） |
| harvest pipeline | H1-H5：抓 deepwiki → 验 codegraph → 漂移分析 → 组装的提取流水线 |
| map-mode | ≤100 行索引入口，细节渐进披露（对齐 harness-loop 概念 2） |
