本知识库由 `knowledge-map` skill 的 harvest 流程（H1-H5）生成。再生步骤：

1. 确保目标仓库 `D:/project/lucene-main/lucene-main/lucene` 已被 codegraph 索引（存在 `.codegraph/`）。
2. 用 `answers.json` 中的 Q1-Q7 重跑 harvest：`knowledge-map` skill → harvest。
3. 或仅重新渲染（不重新抓取）：`bash scripts/render-kb.sh .meta/fragments <output>`。

时间戳：见 `.meta/fragments/regen-timestamp.txt`（`2026-06-28`）。外部漂移（deepwiki/代码变更）后，重跑 harvest 并在单个"快照刷新"提交中更新 fragments + 渲染输出。
