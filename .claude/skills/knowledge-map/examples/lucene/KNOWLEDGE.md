# lucene — 业务知识地图

Apache Lucene 是高性能、全功能的全文搜索引擎库（纯 Java）。它本身不是完整应用，而是提供构建搜索应用的 API 和核心组件。架构以**段（segment）为基础**：数据存入不可变段，后台周期性合并。两条主线：**索引（IndexWriter）**把文档写入可搜索数据结构，**搜索（IndexSearcher）**查询这些结构。

## 地图拓扑

- **Indexing System** → domains/indexing.md — 4 concept clusters, 7 anchors (7✅)
- **Search System** → domains/search.md — 4 concept clusters, 10 anchors (10✅)
- **Index Data Structures** → domains/index-data-structures.md — 6 concept clusters, 8 anchors (8✅)
- **Analysis System** → domains/analysis.md — 3 concept clusters, 7 anchors (7✅)
- **Build and Release System** → domains/build-release.md — 4 concept clusters, 3 anchors (3✅)

## 两大入口

- **索引入口**：`core/src/java/org/apache/lucene/index/IndexWriter.java` → `IndexWriter`（线程安全的写入主入口，协调文档摄取、段管理、合并）
- **搜索入口**：`core/src/java/org/apache/lucene/search/IndexSearcher.java` → `IndexSearcher`（线程安全的查询执行器，跨段并行搜索、缓存、收集结果）

## 整体漂移

- orphan（deepwiki 有但代码找不到）：0
- blindspot（代码有但 deepwiki 没说）：1（见 `drift.md`）

所有 5 个领域的代码锚点均经 codegraph 验证为 RESOLVED（Lucene 的 deepwiki 与代码高度同步）。唯一盲点为 `MergeTrigger`（高中心度，未被概念簇引用）。

（详见 `drift.md`；`✅` = 锚点经 codegraph 验证，`❓` = 未验证）

## 模块组织

| 模块类别 | 关键模块 | 用途 |
| --- | --- | --- |
| **核心** | `lucene:core`, `lucene:core.tests` | 基础索引与搜索 API |
| **分析** | `lucene:analysis:common`, `lucene:analysis:icu` | 文本处理与语言支持 |
| **专用** | `lucene:spatial3d`, `lucene:queries` | 领域特定功能 |
| **工具** | `lucene:luke`, `lucene:demo` | GUI 工具与示例 |
| **基础设施** | `lucene:test-framework`, `lucene:backward-codecs` | 开发与兼容性 |

## 再生

本知识库由 `knowledge-map` skill 的 harvest 流程（H1-H5）生成。再生步骤：

1. 确保目标仓库 `D:/project/lucene-main/lucene-main/lucene` 已被 codegraph 索引（存在 `.codegraph/`）。
2. 用 `answers.json` 中的 Q1-Q7 重跑 harvest：`knowledge-map` skill → harvest。
3. 或仅重新渲染（不重新抓取）：`bash scripts/render-kb.sh .meta/fragments <output>`。

时间戳：见 `.meta/fragments/regen-timestamp.txt`（`2026-06-28`）。外部漂移（deepwiki/代码变更）后，重跑 harvest 并在单个"快照刷新"提交中更新 fragments + 渲染输出。
