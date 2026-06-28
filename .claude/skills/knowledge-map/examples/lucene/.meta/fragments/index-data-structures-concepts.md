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
