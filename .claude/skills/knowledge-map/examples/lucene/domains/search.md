---
domain: Search System
deepwiki: https://deepwiki.com/apache/lucene/3-search-system
status: verified
---

# Search System

## 业务说明

搜索系统对已索引段执行查询并返回结果。入口 `IndexSearcher` 是线程安全的协调器：先重写查询（`Query.rewrite`）、与缓存层交互（`QueryCache`/`QueryCachingPolicy`），再通过 `TaskExecutor` 在 `LeafSlice[]` 上并发执行。每个段独立搜索，结果由 `Collector` 收集并合并为最终 `TopDocs`。默认相似度为 BM25。

## 核心概念簇

### IndexSearcher 协调器
中央类，对 `IndexReader` 执行查询。可单线程或带 `Executor` 多线程构造。核心 API：`search(Query,int)` → TopDocs、`search(Query,int,Sort)` → TopFieldDocs、`search(Query,CollectorManager)`、`searchAfter` 分页、`count(Query)`。负责查询重写、缓存、并发、打分与结果收集。

### 查询重写与 Weight/Scorer
查询执行前先迭代重写以简化/优化形式（嵌套结构展开、过滤器合并、冗余消除），子句数受 `maxClauseCount`（默认 1024）限制。重写后由 `Weight` 封装打分准备状态；`ScorerSupplier` 延迟昂贵的 scorer 构造并提供 cost 估算；`BulkScorer` 处理批量打分。

### 并发执行（LeafSlice + TaskExecutor）
段（`LeafReaderContext`）被划分为 `LeafSlice`，每片含若干叶子分区（约 250000 文档/片、5 段/片上限）。`TaskExecutor` 管理各片上的并行任务：提交 N-1 次以避免死锁、至少一个任务在调用线程上运行、任务异常时取消其余。每片独立 collector，完成后合并。

### 查询缓存系统
`LRUQueryCache` 缓存 `(segment, query)` → `DocIdSet`，LRU 淘汰、分区降低锁竞争、精确 RAM 计费、按段缓存（`RoaringDocIdSet`/`BitDocIdSet`）。默认策略 `UsageTrackingQueryCachingPolicy` 按使用频率与 cost 决定缓存，跳过廉价查询（`TermQuery`、`MatchAllDocsQuery`）。

## 代码锚点

| 概念 | 符号 | 位置:行 | 状态 | callPath |
| --- | --- | --- | --- | --- |
| IndexSearcher 协调器 | `IndexSearcher` | core/src/java/org/apache/lucene/search/IndexSearcher.java:77 | ✅ | search→rewrite→createWeight→scorer；构造时初始化 TaskExecutor |
| 读访问段 | `IndexReader` | core/src/java/org/apache/lucene/index/IndexReader.java | ✅ | IndexSearcher→IndexReader→leaves()→LeafReaderContext |
| 读访问段 | `LeafReader` | core/src/java/org/apache/lucene/index/LeafReader.java:49 | ✅ | IndexReader→LeafReader（单段原子读）；terms/postings/docValues |
| 查询类型 | `Query` | core/src/java/org/apache/lucene/search/Query.java | ✅ | IndexSearcher.rewrite→Query.rewrite；TermQuery/BooleanQuery/PhraseQuery |
| Weight/Scorer | `Weight` | core/src/java/org/apache/lucene/search/Weight.java | ✅ | IndexSearcher.createWeight→Weight.scorer→Scorer |
| Weight/Scorer | `Scorer` | core/src/java/org/apache/lucene/search/Scorer.java | ✅ | Weight.scorer→Scorer.iterator→DocIdSetIterator |
| 结果收集 | `Collector` | core/src/java/org/apache/lucene/search/Collector.java | ✅ | IndexSearcher.search→LeafCollector→Collector；TopDocsCollector |
| 查询缓存 | `LRUQueryCache` | core/src/java/org/apache/lucene/search/LRUQueryCache.java:86 | ✅ | IndexSearcher→QueryCache.doCache→LRUQueryCache caches DocIdSet |
| 并发执行 | `TaskExecutor` | core/src/java/org/apache/lucene/search/TaskExecutor.java:47 | ✅ | IndexSearcher→TaskExecutor.invokeAll→slice tasks；62 callers |
| 结果合并 | `TopDocs` | core/src/java/org/apache/lucene/search/TopDocs.java:27 | ✅ | TopDocs.merge→shard merge；341 callers |

## 漂移标记

- orphan：无
- blindspot：无（本领域 Core Classes 均被概念簇覆盖；高中心度的 `TopDocs`(341)、`TaskExecutor`(62) 均已引用）

## 交叉链接

- → index-data-structures.md（搜索读取 LeafReader/CodecReader 暴露的 Terms、PostingsEnum、DocValues、PointValues、向量值）
- → indexing.md（IndexSearcher 依赖 IndexReader，而 IndexReader 由 IndexWriter 的段产出 / NRT getReader 提供）
