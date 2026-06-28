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
