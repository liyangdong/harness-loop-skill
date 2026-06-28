---
domain: Index Data Structures
deepwiki: https://deepwiki.com/apache/lucene/4-index-data-structures
status: verified
---

# Index Data Structures

## 业务说明

Lucene 索引由多种专用数据结构组成，每种针对不同查询模式与数据类型优化，全部组织为不可变段并通过分层 reader 架构访问。`SegmentInfos`（segments_N 文件）维护所有段元数据；每段由 `SegmentCommitInfo` 描述并引用 `SegmentInfo` 与编码数据文件。`CheckIndex` 工具提供对所有结构的完整性校验。

## 核心概念簇

### 倒排索引（Terms 与 Postings）
术语到文档的映射，含位置与频率。`Terms` 是字段术语访问点，`TermsEnum` 按序迭代术语，`PostingsEnum` 迭代含某术语的文档（频率+位置）。这是全文检索的基础结构。

### DocValues（列式存储）
面向列的字段值存储，优化排序、分面、聚合。类型：`NumericDocValues`（每文档单 long）、`BinaryDocValues`（每文档字节数组）、`SortedDocValues`（序号+字典）、`SortedNumericDocValues`、`SortedSetDocValues`。`DocValuesSkipper` 支持跳过不匹配文档范围。

### BKD 树与点值（PointValues）
多维数值/空间索引，支持高效多维范围查询。`PointValues` 为入口，`PointTree` 提供层次遍历，`IntersectVisitor` 为访问者模式。`BKDWriter` 负责写入。

### 向量值与 HNSW 图
高维向量存储（`FloatVectorValues` / `ByteVectorValues`），HNSW 图提供近似最近邻搜索（`HnswGraph`）。支持 KNN 相似度查询。

### 段与 Reader 架构
`SegmentReader` 从段文件读取；`CodecReader` 暴露 codec 级 API（`FieldsProducer`、`DocValuesProducer` 等）；`LeafReader` 是单段原子读抽象（`IndexReader` 子类）。`ParallelLeafReader`、`FilterLeafReader`、`SortingCodecReader` 是包装实现。

### 校验与完整性
`CheckIndex` 全面校验索引各组件（段、stored fields、term vectors、doc values、point values、向量、norms、postings），`checkIntegrity()` 校验校验和，`Status` 报告每段健康。支持多线程并行段校验。

## 代码锚点

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

## 漂移标记

- orphan：无
- blindspot：无（`CodecReader`(164 callers)、`SegmentInfos` 等高中心度符号均被概念簇覆盖）

## 交叉链接

- → indexing.md（这些数据结构由 IndexWriter/DWPT/IndexingChain 在 flush 时产出；合并由 SegmentMerger 聚合）
- → search.md（搜索通过 LeafReader/CodecReader 读取这些结构：Terms/PostingsEnum/DocValues/PointValues/向量）
