---
domain: Indexing System
deepwiki: https://deepwiki.com/apache/lucene/2-indexing-system
status: verified
---

# Indexing System

## 业务说明

索引系统把应用文档转换成持久化、可搜索的段，是 Lucene 最关键的系统。它在多线程、内存缓冲的环境下协调文档摄取、字段分析、并发、内存管理与段生命周期。核心能力：线程安全的并发文档/更新处理、可配置 flush 阈值的内存写缓冲、表示操作顺序的序列号、非阻塞的 pending deletes/updates 协调、以及包含后台合并的自动段管理。

## 核心概念簇

### IndexWriter 协调入口
客户端线程安全的索引 API 入口：addDocument / updateDocument / deleteDocuments / commit / flush / forceMerge / close。每次修改返回序列号保证串行化顺序。内部委托 `DocumentsWriter` 处理摄取管线，`MergeScheduler` 处理后台合并。

### DocumentsWriter 与每线程写入器（DWPT）
`DocumentsWriter` 编排多个 `DocumentsWriterPerThread`（DWPT）实例，DWPT 在线程本地缓冲文档并通过 `IndexingChain` 处理分析后的字段。`DocumentsWriterPerThreadPool` 池化并回收 DWPT，`DocumentsWriterFlushControl` 管理内存阈值并触发 flush。

### 内存管理与 Flush 控制
基于 RAM 用量（`ramBufferSizeMB` 默认 16MB）或文档数（`maxBufferedDocs`）的缓冲写。每个 DWPT 通过 `Accountable` 上报 RAM；超过阈值时 flush 策略触发刷写。`ramPerThreadHardLimitMB`（默认 1945MB）是单 DWPT 硬限以防 OOM。FlushControl 维护 `activeBytes` / `flushBytes` 计数器；当 flush 落后于索引时 stall control 阻塞索引线程以防内存耗尽。

### 段合并策略与调度
`MergePolicy` 决定合并哪些段（默认 `TieredMergePolicy`），`MergeScheduler` 执行合并（默认 `ConcurrentMergeScheduler`）。后台合并把小段聚合成大段，不阻塞搜索。`DocumentsWriterFlushQueue` 与 `MergeScheduler` 按配置策略异步协调后台 flush 与合并。

## 代码锚点

| 概念 | 符号 | 位置:行 | 状态 | callPath |
| --- | --- | --- | --- | --- |
| IndexWriter 协调入口 | `IndexWriter` | core/src/java/org/apache/lucene/index/IndexWriter.java:198 | ✅ | addDocument→DocumentsWriter→DWPT；2222 callers |
| DocumentsWriter 与 DWPT | `DocumentsWriter` | core/src/java/org/apache/lucene/index/DocumentsWriter.java:81 | ✅ | IndexWriter→DocumentsWriter→DWPT；implements Accountable |
| DocumentsWriter 与 DWPT | `DocumentsWriterPerThread` | core/src/java/org/apache/lucene/index/DocumentsWriterPerThread.java:52 | ✅ | DocumentsWriter→DWPT→IndexingChain；42 callers |
| 内存管理 | `DocumentsWriterFlushControl` | core/src/java/org/apache/lucene/index/DocumentsWriterFlushControl.java:44 | ✅ | DocumentsWriter→FlushControl→DWPT；12 callers |
| 段合并策略 | `MergePolicy` | core/src/java/org/apache/lucene/index/MergePolicy.java:71 | ✅ | IndexWriter→maybeMerge→MergePolicy.findMerges |
| 段合并调度 | `MergeScheduler` | core/src/java/org/apache/lucene/index/ConcurrentMergeScheduler.java:120 | ✅ | IndexWriter→MergeScheduler.merge→MergeThread |
| IndexWriter 协调入口 | `IndexingChain` | core/src/java/org/apache/lucene/index/IndexingChain.java | ✅ | DWPT→IndexingChain.processDocument；implements Accountable |

## 漂移标记

- orphan：无（所有概念簇锚点均 RESOLVED）
- blindspot：`MergeTrigger`（core/src/java/org/apache/lucene/index/MergeTrigger.java:23，98 callers）—— 合并触发枚举，未被 deepwiki 概念簇单独覆盖（见 drift.md）

## 交叉链接

- → index-data-structures.md（DWPT flush 产出段，段由 CodecReader/SegmentReader 读取；合并由 SegmentMerger 操作索引数据结构）
- → search.md（IndexWriter 通过 getReader 提供 NRT 视图给 IndexSearcher/LeafReader）
