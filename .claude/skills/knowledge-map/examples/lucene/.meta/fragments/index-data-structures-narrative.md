Lucene 索引由多种专用数据结构组成，每种针对不同查询模式与数据类型优化，全部组织为不可变段并通过分层 reader 架构访问。`SegmentInfos`（segments_N 文件）维护所有段元数据；每段由 `SegmentCommitInfo` 描述并引用 `SegmentInfo` 与编码数据文件。`CheckIndex` 工具提供对所有结构的完整性校验。
