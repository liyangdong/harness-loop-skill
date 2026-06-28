> 注：本域路径相对于 lucene git 仓根（repo root），而非 projectPath 子目录 `lucene/`——这些文件位于仓根上一层。

| 概念 | 符号 | 位置:行 | 状态 | callPath |
| --- | --- | --- | --- | --- |
| 构建配置 | `settings.gradle` | settings.gradle:51 | ✅ | Gradle 根项目→include 模块（core/analysis/queries/...） |
| 依赖管理 | `libs.versions.toml` | gradle/libs.versions.toml | ✅ | 各模块 build.gradle→libs.versions.toml（版本目录） |
| 发布流程 | `dev-tools/scripts/` | dev-tools/scripts/buildAndPushRelease.py | ✅ | releaseWizard→buildAndPushRelease→addVersion |
