### IndexSearcher 协调器
中央类，对 `IndexReader` 执行查询。可单线程或带 `Executor` 多线程构造。核心 API：`search(Query,int)` → TopDocs、`search(Query,int,Sort)` → TopFieldDocs、`search(Query,CollectorManager)`、`searchAfter` 分页、`count(Query)`。负责查询重写、缓存、并发、打分与结果收集。

### 查询重写与 Weight/Scorer
查询执行前先迭代重写以简化/优化形式（嵌套结构展开、过滤器合并、冗余消除），子句数受 `maxClauseCount`（默认 1024）限制。重写后由 `Weight` 封装打分准备状态；`ScorerSupplier` 延迟昂贵的 scorer 构造并提供 cost 估算；`BulkScorer` 处理批量打分。

### 并发执行（LeafSlice + TaskExecutor）
段（`LeafReaderContext`）被划分为 `LeafSlice`，每片含若干叶子分区（约 250000 文档/片、5 段/片上限）。`TaskExecutor` 管理各片上的并行任务：提交 N-1 次以避免死锁、至少一个任务在调用线程上运行、任务异常时取消其余。每片独立 collector，完成后合并。

### 查询缓存系统
`LRUQueryCache` 缓存 `(segment, query)` → `DocIdSet`，LRU 淘汰、分区降低锁竞争、精确 RAM 计费、按段缓存（`RoaringDocIdSet`/`BitDocIdSet`）。默认策略 `UsageTrackingQueryCachingPolicy` 按使用频率与 cost 决定缓存，跳过廉价查询（`TermQuery`、`MatchAllDocsQuery`）。
