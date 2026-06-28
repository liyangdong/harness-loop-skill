### IndexWriter 协调入口
客户端线程安全的索引 API 入口：addDocument / updateDocument / deleteDocuments / commit / flush / forceMerge / close。每次修改返回序列号保证串行化顺序。内部委托 `DocumentsWriter` 处理摄取管线，`MergeScheduler` 处理后台合并。

### DocumentsWriter 与每线程写入器（DWPT）
`DocumentsWriter` 编排多个 `DocumentsWriterPerThread`（DWPT）实例，DWPT 在线程本地缓冲文档并通过 `IndexingChain` 处理分析后的字段。`DocumentsWriterPerThreadPool` 池化并回收 DWPT，`DocumentsWriterFlushControl` 管理内存阈值并触发 flush。

### 内存管理与 Flush 控制
基于 RAM 用量（`ramBufferSizeMB` 默认 16MB）或文档数（`maxBufferedDocs`）的缓冲写。每个 DWPT 通过 `Accountable` 上报 RAM；超过阈值时 flush 策略触发刷写。`ramPerThreadHardLimitMB`（默认 1945MB）是单 DWPT 硬限以防 OOM。FlushControl 维护 `activeBytes` / `flushBytes` 计数器；当 flush 落后于索引时 stall control 阻塞索引线程以防内存耗尽。

### 段合并策略与调度
`MergePolicy` 决定合并哪些段（默认 `TieredMergePolicy`），`MergeScheduler` 执行合并（默认 `ConcurrentMergeScheduler`）。后台合并把小段聚合成大段，不阻塞搜索。`DocumentsWriterFlushQueue` 与 `MergeScheduler` 按配置策略异步协调后台 flush 与合并。
