# 漂移报告

> regenerated: 2026-06-28
> orphan = deepwiki 有概念但代码锚点全失效（说了但找不到）
> blindspot = 高中心度代码符号未被 deepwiki 覆盖（代码有但没说）

## Orphans（deepwiki 说了但代码找不到）

| 概念 | 领域 | 原因 |
| --- | --- | --- |
| （无） | — | — |

所有概念簇的代码锚点均经 codegraph 验证为 RESOLVED，无孤儿。

## Blindspots（代码有但 deepwiki 没说）

| 符号 | 位置 | caller 数 | 建议领域 |
| --- | --- | --- | --- |
| `MergeTrigger` | core/src/java/org/apache/lucene/index/MergeTrigger.java:23 | 98 | indexing |

`MergeTrigger` 是合并触发的枚举类型（FULL_FLUSH / EXPLICIT / MERGE_FINISHED / CLOSING / COMMIT），被 `ConcurrentMergeScheduler`、`MergePolicy`、`FilterMergePolicy` 等广泛引用，但 deepwiki 的概念簇未单独覆盖它。其余高中心度类（`SegmentMerger`、`TieredMergePolicy`、`BufferedUpdates`、`ConcurrentMergeScheduler`）均已被索引/搜索概念簇引用，不算盲点。

## 处理建议

- orphan: 核对 deepwiki 引用的行号是否过期，或该概念是否已重构；更新锚点或从 deepwiki 侧订正
- blindspot: 评估是否应在对应 domain 补一段说明，或确认它是实现细节无需文档化
