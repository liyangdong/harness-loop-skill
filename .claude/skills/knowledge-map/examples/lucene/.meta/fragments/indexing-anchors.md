| 概念 | 符号 | 位置:行 | 状态 | callPath |
| --- | --- | --- | --- | --- |
| IndexWriter 协调入口 | `IndexWriter` | core/src/java/org/apache/lucene/index/IndexWriter.java:198 | ✅ | addDocument→DocumentsWriter→DWPT；2222 callers |
| DocumentsWriter 与 DWPT | `DocumentsWriter` | core/src/java/org/apache/lucene/index/DocumentsWriter.java:81 | ✅ | IndexWriter→DocumentsWriter→DWPT；implements Accountable |
| DocumentsWriter 与 DWPT | `DocumentsWriterPerThread` | core/src/java/org/apache/lucene/index/DocumentsWriterPerThread.java:52 | ✅ | DocumentsWriter→DWPT→IndexingChain；42 callers |
| 内存管理 | `DocumentsWriterFlushControl` | core/src/java/org/apache/lucene/index/DocumentsWriterFlushControl.java:44 | ✅ | DocumentsWriter→FlushControl→DWPT；12 callers |
| 段合并策略 | `MergePolicy` | core/src/java/org/apache/lucene/index/MergePolicy.java:71 | ✅ | IndexWriter→maybeMerge→MergePolicy.findMerges |
| 段合并调度 | `MergeScheduler` | core/src/java/org/apache/lucene/index/ConcurrentMergeScheduler.java:120 | ✅ | IndexWriter→MergeScheduler.merge→MergeThread |
| IndexWriter 协调入口 | `IndexingChain` | core/src/java/org/apache/lucene/index/IndexingChain.java | ✅ | DWPT→IndexingChain.processDocument；implements Accountable |
