| 符号 | 位置 | caller 数 | 建议领域 |
| --- | --- | --- | --- |
| `MergeTrigger` | core/src/java/org/apache/lucene/index/MergeTrigger.java:23 | 98 | indexing |

`MergeTrigger` 是合并触发的枚举类型（FULL_FLUSH / EXPLICIT / MERGE_FINISHED / CLOSING / COMMIT），被 `ConcurrentMergeScheduler`、`MergePolicy`、`FilterMergePolicy` 等广泛引用，但 deepwiki 的概念簇未单独覆盖它。其余高中心度类（`SegmentMerger`、`TieredMergePolicy`、`BufferedUpdates`、`ConcurrentMergeScheduler`）均已被索引/搜索概念簇引用，不算盲点。
