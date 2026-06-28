| 概念 | 符号 | 位置:行 | 状态 | callPath |
| --- | --- | --- | --- | --- |
| 段与 Reader 架构 | `LeafReader` | core/src/java/org/apache/lucene/index/LeafReader.java:49 | ✅ | IndexReader→LeafReader（单段）；terms/postings/docValues/norms |
| 段与 Reader 架构 | `CodecReader` | core/src/java/org/apache/lucene/index/CodecReader.java:32 | ✅ | LeafReader→CodecReader→SegmentReader；164 callers |
| 段与 Reader 架构 | `SegmentReader` | core/src/java/org/apache/lucene/index/SegmentReader.java | ✅ | CodecReader→SegmentReader（读单段文件） |
| 段元数据 | `SegmentInfos` | core/src/java/org/apache/lucene/index/SegmentInfos.java:169 | ✅ | IndexWriter→SegmentInfos（segments_N）；counter/version |
| 段元数据 | `SegmentInfo` | core/src/java/org/apache/lucene/index/SegmentInfo.java:185 | ✅ | SegmentCommitInfo→SegmentInfo（name/maxDoc/codec） |
| BKD 树 | `BKDWriter` | core/src/java/org/apache/lucene/util/bkd/BKDWriter.java | ✅ | IndexingChain→BKDWriter.write→PointValues |
| BKD 树 | `PointValues` | core/src/java/org/apache/lucene/index/PointValues.java | ✅ | CodecReader.getPointValues→PointValues/PointTree |
| 向量与 HNSW | `HnswGraph` | core/src/java/org/apache/lucene/util/hnsw/HnswGraph.java | ✅ | KnnVectorsReader→HnswGraph（ANN 导航） |
| 校验完整性 | `CheckIndex` | core/src/java/org/apache/lucene/index/CheckIndex.java:103 | ✅ | CheckIndex→testFieldInfos/testPostings/testDocValues；Status |
